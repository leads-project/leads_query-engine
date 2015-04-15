import yaml
import sys

content = sys.argv[1]
y = yaml.load(content)

identity_file = '~/.ssh/leads_cluster'
target_file = 'ssh_config'

lines = []

for pr in y:
    deployment = y[pr]['openstack']
    for m in deployment:
        vm = deployment[m]
        lines.append("# VM @ {0}".format(pr))
        lines.append("Host {0}".format(m))
        lines.append("    HostName {0}".format(vm["public_ips"][0]))
        lines.append("    User ubuntu")
        lines.append("    IdentityFile {0}".format(identity_file))
        lines.append("")
        lines.append("")

with open(target_file, 'a') as f:
    for l in lines:
        f.write(l)
        f.write("\n")
