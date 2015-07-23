__author__ = "Wojciech Barczynski"
__email__ = "wojciech.barczynski@cloudandheat.com"

import yaml
import sys


def print_warn(instance_name, instance_dsc):
    print "[WARN] The instance {0} seems to not be UP, salt-cloud returns: {1}".format(
        instance_name,
        instance_dsc)


def print_warn_no_pub_ip(instance_name, instance_dsc):
    print "[WARN] The instance {0} seems to not have public IP, salt-cloud returns: {1}".format(
        instance_name,
        instance_dsc)


def append_to(target_file, lines):
    with open(target_file, 'a') as f:
        for l in lines:
            f.write(l)
            f.write("\n")


content = sys.argv[1]
y = yaml.load(content)

identity_file = '~/.ssh/leads_cluster'
target_file = 'ssh_config'

lines = []

for pr in y:
    deployment = y[pr]['openstack']
    for m in deployment:
        vm = deployment[m]
        print vm
        print m
        if vm == 'Absent':
                lines.append("# VM @ {0}".format(pr))
                lines.append("# Host {0}".format(m))
                lines.append("# Absent VM")
                print_warn(m, vm)
        elif vm['state'] != 'RUNNING':
                lines.append("# VM @ {0}".format(pr))
                lines.append("# Host {0}".format(m))
                lines.append("# VM in state: {0}".format(vm['state']))
                print_warn(m, vm)
        elif "public_ips" in vm:
            if len(vm["public_ips"]) > 0:
                lines.append("# VM @ {0}".format(pr))
                lines.append("Host {0}".format(m))
                lines.append("    # PrivateIP {0}".format(vm["private_ips"][0]))
                lines.append("    HostName {0}".format(vm["public_ips"][0]))
                lines.append("    User ubuntu")
                lines.append("    IdentityFile {0}".format(identity_file))
            else:
                priv_ip = vm["private_ips"][0]
                target_inst = pr[4:]
                lines.append("# VM @ {0}".format(pr))
                lines.append("Host {0}".format(m))
                lines.append("    # PrivateIP {0}".format(priv_ip))
                lines.append("    ProxyCommand ssh forward@ssh.{0}.cloudandheat.com nc -q0 {1} 22".format(
                        target_inst, priv_ip))
                lines.append("    User ubuntu")
                lines.append("    IdentityFile {0}".format(identity_file))
                print_warn_no_pub_ip(m, vm)
            lines.append("")
            lines.append("")
        else:
            print_warn(m, vm)


append_to(target_file, lines)
