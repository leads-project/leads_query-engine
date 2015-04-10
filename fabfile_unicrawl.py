from fabric.contrib.files import exists, append, contains
from fabric.contrib import files
from fabric.api import run, env, sudo, local, cd, settings, get
from fabric.api import hide, parallel, roles, hosts, serial
from fabric.context_managers import shell_env
from fabric.utils import error
import os
from fabfile_ispn import ispn_hosts_file
from fabfile import hadoop_home_dir, hadoop_master_node_ip

env.forward_agent = True
env.use_ssh_config = True


ispn_cluster_ips = ispn_hosts_file.keys()
nutch_home_dir = "/home/ubuntu/nutch"
hadoop_name_node = hadoop_master_node_ip


@serial
def configure_unicrawler():
    conn_string = _get_gora_conn_string(ispn_cluster_ips)
    props = _generate_gora_properties(conn_string)
    _write_gora_properties(nutch_home_dir, props)


def _get_gora_conn_string(ispn_ips):
    result = [i_ip + ":11222" for i_ip in ispn_ips]
    return "|".join(result)


def _generate_gora_properties(conn_string):
    gora_properties = """
gora.datastore.default=org.apache.gora.infinipan.store.InfinispanStore
gora.datastore.connectionstring={0}
 """.format(conn_string)
    return gora_properties.strip()


def _write_gora_properties(nutch_home, content):
    filename = "gora.properties"

    with cd(nutch_home + '/conf/'):
        if not files.contains(filename, content):
            run("rm -f {0}; touch {0}".format(filename))
            files.append(filename, content)


def setup_unicrawler():
    nutch_home = nutch_home_dir
    hadoop_home = hadoop_home_dir
    with cd(nutch_home):
        with shell_env(JAVA_HOME='/usr/lib/jvm/java-7-openjdk-amd64',
                       YARN_HOME=hadoop_home):
            run("export PATH=$PATH:${YARN_HOME}/bin; ./bin/setup.sh")
    perform_inject()


def perform_inject():
    _run_unicrawler_with("--inject")


def _run_unicrawler_with(option):
    nutch_home = nutch_home_dir
    hadoop_home = hadoop_home_dir

    _patch_dnutch_script(nutch_home)

    with cd(nutch_home):
        with shell_env(JAVA_HOME='/usr/lib/jvm/java-7-openjdk-amd64',
                       YARN_HOME=hadoop_home,
                       HDFS_NAMENODE=hadoop_name_node,
                       NUTCH_DIR=nutch_home):
            run("export PATH=$PATH:${YARN_HOME}/bin; bash -uex ./bin/dnutch {0}".format(option))


def start_unicrawler():
    _run_unicrawler_with("")


def _patch_dnutch_script(nutch_home):
    filename = "bin/dnutch"
    with cd(nutch_home):
        files.comment(filename, 'source "/mnt/cdrom/context.sh"')
        files.comment(filename, 'export NUTCH_DIR="/opt/nutch"')
