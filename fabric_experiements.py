from fabric.contrib.files import exists, append, contains
from fabric.contrib import files
from fabric.api import run, env, sudo, local, cd, settings, get
from fabric.api import hide, parallel, roles, hosts, serial
from fabric.context_managers import shell_env
from fabric import utils
import time
import os


env.forward_agent = True
env.use_ssh_config = True


YCSB_BINARY = "YCSB_PS.tar.gz"
YCSB_DIR = YCSB_BINARY[:7]
REMOTE_FILE = "/home/ubuntu/{0}".format(YCSB_BINARY)


def ycsb_install():
    if not exists(REMOTE_FILE):
        utils.puts("Uploading {0}".format(YCSB_BINARY))
        _upload_with_scp(YCSB_BINARY, REMOTE_FILE)
    else:
        utils.puts("{0} is already on the host".format(YCSB_BINARY))

    if not exists(YCSB_DIR):
        run("tar -xzf {0}".format(YCSB_BINARY))


def ycsb_remove():
    if exists(REMOTE_FILE):
        run("rm -f {0}".format(REMOTE_FILE))
    if exists(YCSB_DIR):
        run("rm -rf {0}".format(YCSB_DIR))


def _upload_with_scp(what, where):
    with hide('running', 'stdout'):
        local("scp -F {0} {1} {2}:{3}".format(env.ssh_config_path, what, env.host_string, where))


def ycsb_load_workloads_local():
    local("mkdir -p evaluation/ycsb")
    exp_time = time.strftime("%Y%m%d-%H%M%S")
    for wl in ["workloada", "workloadb"]:
        _exec_load(wl, exp_time)


YCSB_RECORDCOUNT = 100000


def _exec_load(workload, result_file_postfix):
    with cd("/home/ubuntu/YCSB_PS"):
        ispn_ip = run("hostname -I")
        ispn_hn = run("hostname")
        utils.puts("Load ycsb workload data to infinispan at {0}".format(ispn_ip))
        result_file_name = "{0}-{1}-load-{2}.data".format(ispn_hn, workload, result_file_postfix)

        with hide('running', 'stdout', 'stderr'):
            out = run("LEADS_YCSB_CACHE_NAME=clustered ./bin/ycsb load infinispan -P workloads/{1} -p host={0} -threads 10 -s -p recordcount={3} 2>&1 | tee -a {2}".format( 
                      ispn_ip,
                      workload,
                      result_file_name,
                      YCSB_RECORDCOUNT))
            _print_results_to_console(out)
            pwd = run("pwd")
            _download_results_file(pwd, result_file_name, "evaluation/ycsb")


def ycsb_run_workloads_local():
    exp_time = time.strftime("%Y%m%d-%H%M%S")
    local("mkdir -p evaluation/ycsb")

    for wl in ["workloada", "workloadb"]:
        _run_workload(wl, exp_time)


def _run_workload(workload, result_file_postfix):
    with cd("/home/ubuntu/YCSB_PS"):
        ispn_ip = run("hostname -I")
        ispn_hn = run("hostname")
        utils.puts("Run ycsb against infinispan at {0}".format(ispn_ip))

        result_file_name = "{0}-{1}-run-{2}.data".format(ispn_hn, workload, result_file_postfix)
        with hide('running', 'stdout', 'stderr'):
            out = run("LEADS_YCSB_CACHE_NAME=clustered ./bin/ycsb run infinispan -P workloads/{1} -p host={0} -threads 10 -s 2>&1 | tee -a {2}".format(
                      ispn_ip,
                      workload,
                      result_file_name), combine_stderr=True)
            _print_results_to_console(out)
            pwd = run("pwd")
            _download_results_file(pwd, result_file_name, "evaluation/ycsb")


def _print_results_to_console(out):
    line_num = 0
    for l in out.splitlines():
        if 1 < line_num and line_num < 17:
            utils.puts(l)
        elif line_num > 13:
            break
        line_num = line_num + 1


def _download_results_file(r_dir, result_file, local_dir):
    with hide('running', 'stdout'):
        local("scp -F {0} {1}:{2}/{4} {3}/{4}".format(
            env.ssh_config_path,
            env.host_string,
            r_dir,
            local_dir,
            result_file))
