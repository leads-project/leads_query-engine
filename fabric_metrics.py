from fabric.api import run, env, sudo, local, cd
from fabric.api import hide, shell_env
import os

env.forward_agent = True
env.use_ssh_config = True

backup_tool_dir = "/home/ubuntu/metrics/backup"
tcpflow_output_dir = "/home/ubuntu/metrics/tcpflow/final_experiment_NUMBER"

# use -1, -2, empty - means the default value -1 is used
backup_pcp_mtime_value = "-3"


def install_metrics_backup_script():

    run("sudo apt-get install python-virtualenv python-pip python-dev libffi-dev libssl-dev -qq")
    run("mkdir -p {0}".format(backup_tool_dir))

    for f in ["requirements.txt", "copy_pcp_to_swift.sh",
              "copy_tcpflow_to_swift.sh"]:
        local_f = "tools/metrics/backup/{}".format(f)
        remote_f = "{0}/{1}".format(backup_tool_dir, f)
        _upload_with_scp(local_f, remote_f)

    _prepare_virtualenv(backup_tool_dir)


def _prepare_virtualenv(backup_dir):
    with cd(backup_dir):
        cmd = ["virtualenv openstack_cli",
               "source openstack_cli/bin/activate",
               "pip install -U -r requirements.txt"]

        run(";".join(cmd))


def _upload_with_scp(what, where):
    with hide('running', 'stdout'):
        local("scp -F {0} {1} {2}:{3}".format(env.ssh_config_path, what, env.host_string, where))


def run_pcp_backup_script():
    backup_cmd = "./copy_pcp_to_swift.sh"
    _execute_swift_backup_cmd(backup_cmd)


def _execute_swift_backup_cmd(cmd):
    prefix = "source openstack_cli/bin/activate"

    container_user = os.environ["OS_USERNAME"]
    container_tenant = os.environ["OS_TENANT_NAME"]
    container_password = os.environ["OS_PASSWORD"]
    container_url = os.environ["OS_AUTH_URL"]

    with shell_env(OS_USERNAME=container_user,
                   OS_TENANT_NAME=container_tenant,
                   OS_PASSWORD=container_password,
                   OS_AUTH_URL=container_url,
                   PCP_FILES_MTIME=backup_pcp_mtime_value):
        with cd(backup_tool_dir):
            run("chmod +x {0}".format(cmd))
            run("bash -c '{0} ; {1}'".format(prefix, cmd))


def install_tcpflow():
    sudo("sudo apt-get install tcpflow -qq")


def start_tcpflow():
    run("mkdir -p {}".format(tcpflow_output_dir))
    cmd = "tcpflow -i eth0 -FT"
    with cd(tcpflow_output_dir):
        run("sudo -b nohup {0}".format(cmd))


def stop_tcpflow():
    """
    """
    sudo("pkill -15 -f '^tcpflow -i eth0'")


def run_tcpflow_backup():
    """
    """
    backup_cmd = "./copy_tcpflow_to_swift.sh"
    _execute_swift_backup_cmd(backup_cmd)
