base:
  'leads-yarn-*':
    - leads.yarn
  'leads-qe*':
    - leads.openstack
  'leads-qe1':
    - ucloud.hamm5 
  'leads-qe2':
    - ucloud.hamm6
  'leads-yarn-hamm6-*':
    - ucloud.hamm6
  'leads-yarn-[0-9]+':
    - ucloud.hamm5
