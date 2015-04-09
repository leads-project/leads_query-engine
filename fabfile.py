from fabric.contrib.files import exists, append, contains
from fabric.contrib import files
from fabric.api import run, env, sudo, local, cd, settings
from fabric.api import hide, parallel, roles, hosts, serial
from fabric.context_managers import shell_env
from fabric.utils import error
import os

from prettytable import PrettyTable


env.forward_agent = True
env.use_ssh_config = True

# infinispan - 54200 and 55200
# hadoop - 9000 and 9001 and 50070 (NameNode) and 8088 (resourcemanager)
# cluster_port_communication = ['54200', '55200', '22', '9000', '9001', '50070',
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

    hadoop_home = "/home/ubuntu/{0}".format("hadoop-2.5.2")
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
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://{1}:9000</value>
    </property>

    <property>
        <name>fs.default.name</name>
        <value>hdfs://{1}:9000</value>
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
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
</configuration>"""

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
def start_hadoop_service():
    """
    Hadoop: start service
    """
    _hadoop_command_namenode("start")
    _hadoop_command_datanode("start")
    _hadoop_command_resource_mgmt("start")
    _hadoop_command_node_manager("start")


def _command_hadoop_service(command):
    hadoop_home = _get_hadoop_home()
    with cd(hadoop_home):
            run("./sbin/{0}-yarn.sh".format(action))


@roles_host_string_based('masters')
def _hadoop_command_namenode(action):
    _execute_hadoop_command('$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR'
                            ' --script hdfs ' + action + ' namenode')


def _execute_hadoop_command(cmd):
    hadoop_home = _get_hadoop_home()

    with shell_env(JAVA_HOME='/usr/lib/jvm/java-7-openjdk-amd64',
                   HADOOP_PREFIX=hadoop_home,
                   HADOOP_CONF_DIR=hadoop_home + "/etc/hadoop",
                   HADOOP_YARN_HOME=hadoop_home):
        run(cmd)


@roles_host_string_based('masters')
def _hadoop_command_datanode(action):
    _execute_hadoop_command('$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR'
                            ' --script hdfs ' + action + ' datanode')


@roles_host_string_based('masters')
def _hadoop_command_resource_mgmt(action):
    _execute_hadoop_command('$HADOOP_YARN_HOME/sbin/yarn-daemon.sh'
                            ' --config $HADOOP_CONF_DIR ' + action + ' resourcemanager')


@roles_host_string_based('masters', 'slaves')
def _hadoop_command_node_manager(action):
    _execute_hadoop_command('$HADOOP_YARN_HOME/sbin/yarn-daemon.sh'
                            ' --config $HADOOP_CONF_DIR ' + action + ' nodemanager')


@serial
def stop_hadoop_service():
    """
    Hadoop: stop service
    """
    _hadoop_command_namenode("stop")
    _hadoop_command_datanode("stop")
    _hadoop_command_resource_mgmt("stop")
    _hadoop_command_node_manager("stop")


@roles_host_string_based('masters')
def hadoop_format():
    hadoop_home = _get_hadoop_home()

    with settings(warn_only=True):
        with cd(hadoop_home):
            with shell_env(JAVA_HOME='/usr/lib/jvm/java-7-openjdk-amd64',
                           HADOOP_PREFIX=hadoop_home):
                run('echo "Y" | bin/hdfs namenode -format')
                run('bin/hdfs datanode -regular')


def show_running_leads_clusters():
    """
    """
    x = PrettyTable(["Cluster name", "Node name", "Node UUID"])
    for inst in os_conn.list_nodes():
        md = os_conn.ex_get_metadata(inst)
        if "leads_cluster_name" in md:
            row = []
            row.append(md["leads_cluster_name"])
            row.append(inst.name)
            row.append(inst.id)
            x.add_row(row)
    print x
