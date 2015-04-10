from fabric.contrib.files import exists, append, contains
from fabric.contrib import files
from fabric.api import run, env, sudo, local, cd, settings, get
from fabric.api import hide, parallel, roles, hosts, serial
from fabric.context_managers import shell_env
from fabric.utils import error
import os

env.forward_agent = True
env.use_ssh_config = True

ispn_master_node_ip = "10.105.0.40"
ispn_master_node = "leads-ispn-1"
ispn_slave_node_ips = ["10.105.0.39"]
ispn_slave_nodes = ["leads-ispn-2"]

env.roledefs = {
    'masters': [ispn_master_node],
    'slaves': ispn_slave_nodes
}


ispn_hosts_file = {
    "10.105.0.40": "leads-ispn-1",
    "10.105.0.39": "leads-ispn-2"
}

cluster_private_ips = list(["10.105.0.39"])
cluster_private_ips.append(ispn_master_node_ip)

infinispan_package_url = ('https://object-hamm5.cloudandheat.com:8080/v1/'
                          'AUTH_73e8d4d1688f4e1f86926d4cb897091f'
                          '/infinispan/infinispan-server-7.0.1-SNAPSHOT-NEW.tgz'
                          '?temp_url_sig=2ffa2de83ee31a452bf5e7109936f733e9ab94ab'
                          '&temp_url_expires=1431266040')


@parallel
def install_infinispan():
    """
    """
    _install_jdk()

    if not exists("infinispan.tgz"):
        run("wget '" + infinispan_package_url+"' -O infinispan.tgz")
        run("echo '" + infinispan_package_url+"' > infinispan.INFO")
    if not exists("infinispan"):
        run("tar zxvf infinispan.tgz")
    content = _get_infinispan_config(cluster_private_ips)
    tmp_file = _save_tmp_infinispan_config_file(content)
    _upload_with_scp(
        tmp_file,
        "infinispan/standalone/configuration/infinispan-config.xml"
        )
    _install_initd_script()
    _prepare_etc_host(ispn_hosts_file)


def _install_jdk():
    if not _is_package_installed("openjdk-7-jdk"):
        sudo("sudo apt-get update")
        sudo("sudo apt-get install -yyf openjdk-7-jdk")


def _is_package_installed(pkg_name):
    """ref: superuser.com/questions/427318/#comment490784_427339"""
    cmd_f = 'dpkg-query -l "%s" | grep -q ^.i'
    cmd = cmd_f % (pkg_name)
    with settings(warn_only=True):
        result = run(cmd)
    return result.succeeded


def _get_infinispan_config(private_ips):
    """
    """
    with open("files/templates/infinispan-config_template.xml", "r") as f:
        infinispan_config_template = f.read()

    config = infinispan_config_template.replace("@NODE_IP@", env.host)

    ps = [p_i + "[55200]" for p_i in private_ips]
    config = config.replace("@TCPPING.initial_hosts@", ",".join(ps))
    return config


def _save_tmp_infinispan_config_file(content):
    tmp_file_name = "tmp_" + env.host + "infinispan-config.xml"
    with open(tmp_file_name, "w") as f:
        f.write(content)
    return tmp_file_name


def _install_initd_script():
    _upload_with_scp(
        "files/templates/infinispan-server_template.sh",
        "infinispan/infinispan-server.sh"
        )
    sudo("cp ~/infinispan/infinispan-server.sh /etc/init.d/infinispan-server")
    sudo("chmod 755 /etc/init.d/infinispan-server")
    sudo("chown root:root /etc/init.d/infinispan-server")
    sudo("sudo update-rc.d infinispan-server defaults")
    sudo("sudo update-rc.d infinispan-server enable")


def _prepare_etc_host(ip_to_hosts):
    for ip, hn in ip_to_hosts.iteritems():
        entry = "{0} {1}".format(ip, hn)
        if not files.contains('/etc/hosts', entry):
            files.append('/etc/hosts', entry, use_sudo=True)


def _upload_with_scp(what, where):
    with hide('running', 'stdout'):
        local("scp -F {0} {1} {2}:{3}".format(env.ssh_config_path, what, env.host_string, where))


@parallel
def start_infinispan_service():
    sudo("sudo service infinispan-server start", pty=True)


@parallel
def stop_infinispan_service():
    sudo("sudo service infinispan-server stop", pty=True)
