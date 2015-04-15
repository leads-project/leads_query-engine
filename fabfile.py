from fabric.contrib.files import exists, append, contains
from fabric.contrib import files
from fabric.api import run, env, sudo, local, cd, settings, get
from fabric.api import hide, parallel, roles, hosts, serial
from fabric.context_managers import shell_env
from fabric.utils import error
import os
import re

from prettytable import PrettyTable


env.forward_agent = True
env.use_ssh_config = True

env.roledefs = {
    'masters': "leads-yarn.*-1",
    'slaves': "leads-yarn.*-[23]"
}

hadoop_home_dir = "/home/ubuntu/{0}".format("hadoop-2.5.2")


# fabric roles works only on env.host
# for us it is simplier to use env.host_string
def roles_host_string_based(*args):
    supported_roles = args

    def new_decorator(func):
        def func_wrapper(*args, **kwargs):
            for role in supported_roles:
                role_rgx = [r[1] for r in env.roledefs.items() if r[0] == role][0]
                if re.match(role_rgx, env.host_string) is not None:
                    func(*args, **kwargs)
        return func_wrapper
    return new_decorator


@roles_host_string_based('masters', 'slaves')
@serial
def do_passwordless_access_to_slaves():
    _get_yarn_master_id_rsa_pub()
    _append_id_rsa_pub_to_slave()


@roles_host_string_based('masters')
def _get_yarn_master_id_rsa_pub():
    if not files.exists('~/.ssh/id_rsa'):
        run("ssh-keygen -t rsa")
    get('/home/ubuntu/.ssh/id_rsa.pub', 'tmp_yarn_master_id_rsa.pub')


@roles_host_string_based('slaves')
def _append_id_rsa_pub_to_slave():
    """
    """
    auth_keys_file = "~/.ssh/authorized_keys"

    with open('tmp_yarn_master_id_rsa.pub') as f:
        key = f.read()
        if not files.contains(auth_keys_file, key):
            files.append(auth_keys_file, key)


@roles_host_string_based('masters', 'slaves')
@serial
def start_hadoop_service():
    hadoop_home = hadoop_home_dir
    """
    Hadoop: start service
    """
    _hadoop_command_namenode(hadoop_home, "start")
    _hadoop_command_datanode(hadoop_home, "start")
    _hadoop_command_resource_mgmt(hadoop_home, "start")
    _hadoop_command_node_manager(hadoop_home, "start")


def _command_hadoop_service(hadoop_home, command):
    with cd(hadoop_home):
            run("./sbin/{0}-yarn.sh".format(command))


@roles_host_string_based('masters')
def _hadoop_command_namenode(hadoop_home, action):
    _execute_hadoop_command(hadoop_home,
                            '$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR'
                            ' --script hdfs ' + action + ' namenode')


def _execute_hadoop_command(hadoop_home, cmd):

    with shell_env(JAVA_HOME='/usr/lib/jvm/java-7-openjdk-amd64',
                   HADOOP_PREFIX=hadoop_home,
                   HADOOP_CONF_DIR=hadoop_home + "/etc/hadoop",
                   HADOOP_YARN_HOME=hadoop_home):
        run(cmd)


@roles_host_string_based('masters', 'slaves')
def _hadoop_command_datanode(hadoop_home, action):
    _execute_hadoop_command(hadoop_home,
                            '$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR'
                            ' --script hdfs ' + action + ' datanode')


@roles_host_string_based('masters')
def _hadoop_command_resource_mgmt(hadoop_home, action):
    _execute_hadoop_command(hadoop_home, '$HADOOP_YARN_HOME/sbin/yarn-daemon.sh'
                            ' --config $HADOOP_CONF_DIR ' + action + ' resourcemanager')


@roles_host_string_based('masters', 'slaves')
def _hadoop_command_node_manager(hadoop_home, action):
    _execute_hadoop_command(hadoop_home, '$HADOOP_YARN_HOME/sbin/yarn-daemon.sh'
                            ' --config $HADOOP_CONF_DIR ' + action + ' nodemanager')


@serial
def stop_hadoop_service():
    """
    Hadoop: stop service
    """
    hadoop_home = hadoop_home_dir
    _hadoop_command_namenode(hadoop_home, "stop")
    _hadoop_command_datanode(hadoop_home, "stop")
    _hadoop_command_resource_mgmt(hadoop_home, "stop")
    _hadoop_command_node_manager(hadoop_home, "stop")


@roles_host_string_based('masters')
def hadoop_format():
    hadoop_home = hadoop_home_dir

    with settings(warn_only=True):
        with cd(hadoop_home):
            with shell_env(JAVA_HOME='/usr/lib/jvm/java-7-openjdk-amd64',
                           HADOOP_PREFIX=hadoop_home):
                run('echo "Y" | bin/hdfs namenode -format')
                run('bin/hdfs datanode -regular')


@roles_host_string_based('masters')
def hadoop_run_example_application_pi():
    hadoop_home = hadoop_home_dir
    with cd(hadoop_home):
        with shell_env(JAVA_HOME='/usr/lib/jvm/java-7-openjdk-amd64'):
            run('bin/yarn jar ./share/hadoop/mapreduce/hadoop-mapreduce-examples-2.5.2.jar'
                ' pi 16 100000')


tera_size = 100000
tera_input_dir = '/tmp/tera_input'
tera_output_dir = '/tmp/tera_output'
tera_validate_dir = '/tmp/tera_validate'


@roles_host_string_based('masters')
def hadoop_example_terrasort_gen():
    hadoop_home = hadoop_home_dir
    run("rm -rf " + tera_input_dir)
    with cd(hadoop_home):
        with shell_env(JAVA_HOME='/usr/lib/jvm/java-7-openjdk-amd64'):
            run('bin/yarn jar ./share/hadoop/mapreduce/hadoop-mapreduce-examples-2.5.2.jar'
                '  teragen  ' + str(tera_size) + ' ' + tera_input_dir)


@roles_host_string_based('masters')
def hadoop_example_terrasort_run():
    hadoop_home = hadoop_home_dir
    run("rm -rf {0}".format(tera_output_dir))
    with cd(hadoop_home):
        with shell_env(JAVA_HOME='/usr/lib/jvm/java-7-openjdk-amd64'):
            run('bin/yarn jar ./share/hadoop/mapreduce/hadoop-mapreduce-examples-2.5.2.jar'
                '  terasort ' + tera_input_dir + ' ' + tera_output_dir)


@roles_host_string_based('masters')
def hadoop_example_terrasort_validate():
    hadoop_home = hadoop_home_dir
    run("rm -rf {0}".format(tera_validate_dir))
    with cd(hadoop_home):
        with shell_env(JAVA_HOME='/usr/lib/jvm/java-7-openjdk-amd64'):
            run('bin/yarn jar ./share/hadoop/mapreduce/hadoop-mapreduce-examples-2.5.2.jar'
                '  teravalidate ' + tera_output_dir + ' ' + tera_validate_dir)
