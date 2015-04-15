__author__ = "Wojciech Barczynski"
__email__ = "wojciech.barczynski@cloudandheat.com"

import yaml
import sys


def print_warn(instance_name, instance_dsc):
    print "[WARN] The instance {0} seems to not be UP, salt-cloud returns: {1}".format(
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
        if "public_ips" in vm:

            lines.append("# VM @ {0}".format(pr))
            lines.append("Host {0}".format(m))
            lines.append("    HostName {0}".format(vm["public_ips"][0]))
            lines.append("    User ubuntu")
            lines.append("    IdentityFile {0}".format(identity_file))
            lines.append("")
            lines.append("")
        else:
            print_warn(m, vm)


append_to(target_file, lines)
