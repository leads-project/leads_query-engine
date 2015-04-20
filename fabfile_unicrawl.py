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
hadoop_name_node = "localhost"


def setup_unicrawler():
    nutch_home = nutch_home_dir
    hadoop_home = hadoop_home_dir
    with cd(nutch_home):
        with shell_env(JAVA_HOME='/usr/lib/jvm/java-7-openjdk-amd64',
                       YARN_HOME=hadoop_home):
            run("export PATH=$PATH:${YARN_HOME}/bin; ./bin/setup.sh")


def perform_inject():
    _run_unicrawler_with("--inject")


def _run_unicrawler_with(option):
    nutch_home = nutch_home_dir
    hadoop_home = hadoop_home_dir

    with cd(nutch_home):
        with shell_env(JAVA_HOME='/usr/lib/jvm/java-7-openjdk-amd64',
                       YARN_HOME=hadoop_home,
                       HDFS_NAMENODE=hadoop_name_node,
                       NUTCH_DIR=nutch_home):
            run("export PATH=$PATH:${YARN_HOME}/bin; bash -uex ./bin/dnutch " + option)


def start_unicrawler():
    number_of_rounds = "1"
    _run_unicrawler_with(number_of_rounds)

# ./bin/nutch readdb -dump ~/tmp/dump
