/root/setup_leads.sh:
  file:
   - managed
   - user: root
   - group: root
   - source: https://raw.githubusercontent.com/skarab7/leads_query-engine/develop/src/setup_leads.sh 
   - source_hash: sha256=acd07b31b2bab01f271cc2c24a5a2006e0de1a23810d60ac5f454a37c1e98b63 
   - mode: 744

/root/requirements.txt:
  file:
   - managed
   - user: root
   - group: root
   - source: https://raw.githubusercontent.com/skarab7/leads_query-engine/develop/tools/openstack_cli/requirements.txt
   - source_hash: sha256=6fc23071422e11e2c5096e76a52ac91a7fe8688e6650cdeae3118a314cc7cb15  
   - mode: 644 

Execute setup_leads:
  cmd.run:
   - env:
      - 'OS_AUTH_URL': 'https://identity-hamm5.cloudandheat.com:5000/v2.0'
      - 'OS_TENANT_ID': '73e8d4d1688f4e1f86926d4cb897091f'
      - 'OS_TENANT_NAME': 'LEADS'
      - 'OS_USERNAME': 'leads' 
      - 'OS_PASSWORD': ''
      - 'LEADS_QUERY_ENGINE_CONTAINER_NAME': 'query_engine'
      - 'LEADS_QUERY_ENGINE_START': 'Y'
   - names:
     - virtualenv openstack_cli; source openstack_cli/bin/activate; pip install -r /root//requirements.txt
     - source openstack_cli/bin/activate; bash /root/setup_leads.sh
