#!/bin/bash
set -o nounset
set -o errexit

echo "Notice: You must run this script from project main directory"
my_dir=$(dirname "$0")

rm -f ssh_config

for f in $(find salt -name '*.map' -type f); do
   yml=$(sudo salt-cloud -c salt  -m $f --query --out yaml)
   python "$my_dir/_append_to_ssh_config.py" "$yml"
done



#sudo salt-cloud -c salt  -m salt/leads_query-engine.map  --query
#sudo salt-cloud -c salt  -m salt/leads_query-engine.map  --query
