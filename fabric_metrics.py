from fabric.api import run, env, sudo, local, cd
from fabric.api import hide, shell_env
import os

env.forward_agent = True
env.use_ssh_config = True

backup_tool_dir = "/home/ubuntu/metrics/backup"
backup_pcp_from_last_n_days = 2


def install_pcp_backup_script():

    run("mkdir -p {0}".format(backup_tool_dir))

    for f in ["requirements.txt", "copy_pcp_to_swift.sh"]:
        local_f = "tools/metrics/backup/{}".format(f)
        remote_f = "{0}/{1}".format(backup_tool_dir, f)
        _upload_with_scp(local_f, remote_f)

    _prepare_virtualenv(backup_tool_dir)


def _prepare_virtualenv(backup_dir):
    with cd(backup_dir):
        cmd = ["virtualenv openstack_cli",
               "source openstack_cli/bin/activate",
               "pip install -r requirements.txt"]

        run(";".join(cmd))


def _upload_with_scp(what, where):
    with hide('running', 'stdout'):
        local("scp -F {0} {1} {2}:{3}".format(env.ssh_config_path, what, env.host_string, where))


def run_pcp_backup_script():

    container_user = os.environ["OS_USERNAME"]
    container_tenant = os.environ["OS_TENANT_NAME"]
    container_password = os.environ["OS_PASSWORD"]
    container_url = os.environ["OS_AUTH_URL"]

    prefix = "source openstack_cli/bin/activate"
    backup_cmd = "bash copy_pcp_to_swift.sh"

    with shell_env(OS_USERNAME=container_user,
                   OS_TENANT_NAME=container_tenant,
                   OS_PASSWORD=container_password,
                   OS_AUTH_URL=container_url):
        with cd(backup_tool_dir):
            run("{0} ; {1}".format(prefix, backup_cmd))
