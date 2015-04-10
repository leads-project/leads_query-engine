from fabric.contrib.files import exists, append, contains
from fabric.contrib import files
from fabric.api import run, env, sudo, local, cd, settings, get
from fabric.api import hide, parallel, roles, hosts, serial
from fabric.context_managers import shell_env
from fabric.utils import error
import os

from prettytable import PrettyTable


env.forward_agent = True
env.use_ssh_config = True

# infinispan - 54200 and 55200
# hadoop - 9000 and 9001 and 50070 (NameNode) and 8088 (resourcemanager)
# cluster_port_communication = ['22', '9000', '9001', '50070',
#                              '8088', '19888', '10020']

hadoop_master_node_ip = "10.105.0.46"
hadoop_master_node = "leads-yarn-1"
hadoop_slave_node_ips = ["10.105.0.51", "10.105.0.47"]
hadoop_slave_nodes = ["leads-yarn-2", "leads-yarn-3"]

env.roledefs = {
    'masters': [hadoop_master_node],
    'slaves': hadoop_slave_nodes
}

hadoop_hosts_file = {
    "10.105.0.46": "leads-yarn-1",
    "10.105.0.51": "leads-yarn-2",
    "10.105.0.47": "leads-yarn-3"
}

hadoop_home_dir = "/home/ubuntu/{0}".format("hadoop-2.5.2")


# fabric roles works only on env.host
# for us it is simplier to use env.host_string
def roles_host_string_based(*args):
    supported_roles = args

    def new_decorator(func):
        def func_wrapper(*args, **kwargs):
            for role in supported_roles:
                role_hosts = [r[1] for r in env.roledefs.items() if r[0] == role][0]
                if env.host_string in role_hosts:
                    func(*args, **kwargs)
        return func_wrapper
    return new_decorator


@roles_host_string_based('masters', 'slaves')
@parallel
def prepare_hadoop():
    hadoop_home = hadoop_home_dir
    _hadoop_configure(hadoop_home)


def _hadoop_configure(hadoop_home):
    _hadoop_change_map_red_site(hadoop_home, hadoop_master_node)
    _hadoop_change_core_site(hadoop_home, hadoop_master_node_ip)
    _hadoop_change_yarn_site(hadoop_home, hadoop_master_node)
    _hadoop_change_HDFS_site(hadoop_home, hadoop_master_node)
    _hadoop_change_masters(hadoop_home, hadoop_master_node)
    _hadoop_change_slaves(hadoop_home, env.roledefs['slaves'])
    _hadoop_prepare_etc_host(hadoop_hosts_file)


@roles_host_string_based('masters', 'slaves')
def _hadoop_change_map_red_site(hadoop_home, master, map_task='8', reduce_task='6'):
    """
    Based on input from Le Quoc Do - SE Group TU Dresden contribution
    """
    before = '<configuration>'
    after = """
<configuration>
    <property>
        <name>mapred.job.tracker</name>
        <value>{0}:9001</value>
    </property>

    <property>
        <name>mapred.map.tasks</name>
        <value>{1}</value>
    </property>

    <property>
        <name>mapred.reduce.tasks</name>
        <value>{2}</value>
    </property>

    <property>
        <name>mapred.system.dir</name>
        <value>{3}/hdfs/mapreduce/system</value>
    </property>

    <property>
        <name>mapred.local.dir</name>
        <value>{3}/hdfs/mapreduce/local</value>
    </property>

    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    """.format(master, map_task, reduce_task,  hadoop_home)

    with cd(hadoop_home + '/etc/hadoop/'):
        run('cp mapred-site.xml.template mapred-site.xml')
        filename = 'mapred-site.xml'
        files.sed(filename, before, after.replace("\n", "\\n"), limit='')


@roles_host_string_based('masters', 'slaves')
def _hadoop_change_core_site(hadoop_home, master_ip):
    """
    Based on input from Le Quoc Do - SE Group TU Dresden contribution
    """
    content = """
<configuration>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>{0}/hdfs</value>
    </property>
    <!-- property>
        <name>fs.defaultFS</name>
        <value>hdfs://{1}:8020</value>
    </property -->

    <property>
        <name>fs.default.name</name>
        <value>hdfs://{1}:8020</value>
    </property>

    <property>
        <name>mapred.job.tracker</name>
        <value>{1}:9001</value>
    </property>
</configuration>""".format(hadoop_home, master_ip)

    filename = 'core-site.xml'
    with cd(hadoop_home + '/etc/hadoop/'):
        run("rm -f {0}; touch {0}".format(filename))
        files.append(filename, content)


@roles_host_string_based('masters', 'slaves')
def _hadoop_change_yarn_site(hadoop_home, master):
    filename = 'yarn-site.xml'

    content = """
<configuration>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>{0}</value>
        <description>The hostname of the ResourceManager</description>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
</configuration>""".format(master)

    with cd(hadoop_home + '/etc/hadoop/'):
        run("rm -f {0}; touch {0}".format(filename))
        files.append(filename, content)


@roles_host_string_based('masters', 'slaves')
def _hadoop_change_HDFS_site(hadoop_home, master, replica='1', xcieversmax='10096'):
    """
    Based on input from Le Quoc Do - SE Group TU Dresden contribution
    """
    filename = 'hdfs-site.xml'
    content = """
<configuration>
    <property>
        <name>dfs.name.dir</name>
        <value>file://{0}/hdfs/name</value>
    </property>
    <property>
        <name>dfs.data.dir</name>
        <value>file://{0}/hdfs/data</value>
    </property>

    <property>
        <name>dfs.replication</name>
        <value>{1}</value>
    </property>

    <property>
        <name>dfs.datanode.max.xcievers</name>
        <value>{2}</value>
    </property>
</configuration>
""".format(hadoop_home, replica,  xcieversmax)

    with cd(hadoop_home + '/etc/hadoop/'):
        run("rm -f {0}; touch {0}".format(filename))
        files.append(filename, content)


@roles_host_string_based('masters', 'slaves')
def _hadoop_change_masters(hadoop_home, master):
    """
    Le Quoc Do - SE Group TU Dresden contribution
    """
    filename = 'masters'

    with cd(hadoop_home + '/etc/hadoop'):
        run("rm -f masters; touch masters")
        files.append(filename, master)


@roles_host_string_based('masters', 'slaves')
def _hadoop_change_slaves(hadoop_home, slaves):
    """
    Le Quoc Do - SE Group TU Dresden contribution
    """
    filename = 'slaves'
    before = 'localhost'
    after = ''
    for slave in slaves:
        after = after + slave + '\\n'
    with cd(hadoop_home + '/etc/hadoop'):
        files.sed(filename, before, after, limit='')


@roles_host_string_based('masters', 'slaves')
def _hadoop_prepare_etc_host(ip_to_hosts):
    for ip, hn in ip_to_hosts.iteritems():
        entry = "{0} {1}".format(ip, hn)
        if not files.contains('/etc/hosts', entry):
            files.append('/etc/hosts', entry, use_sudo=True)


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
