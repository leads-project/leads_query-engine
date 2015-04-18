/home/ubuntu/setup_leads.sh:
  file:
   - managed
   - user: ubuntu
   - group: ubuntu
   - source: https://raw.githubusercontent.com/skarab7/leads_query-engine/develop/src/setup_leads.sh 
   - source_hash: sha256=e6c19273fe0da045ebf7fdfc6b5019393763042100304bb2a21c02e3806310d7
   - mode: 744

/home/ubuntu/requirements.txt:
  file:
   - managed
   - user: ubuntu
   - group: ubuntu
   - source: https://raw.githubusercontent.com/skarab7/leads_query-engine/develop/tools/openstack_cli/requirements.txt
   - source_hash: sha256=6fc23071422e11e2c5096e76a52ac91a7fe8688e6650cdeae3118a314cc7cb15  
   - mode: 644 

Execute setup_leads:
  cmd.run:
   - user: ubuntu
   - env:
      - 'OS_AUTH_URL': {{ pillar['os.auth_url'] }}
      - 'OS_TENANT_ID': {{ pillar['os.tenant_id'] }}
      - 'OS_TENANT_NAME': {{ pillar['os.tenant_name'] }}
      - 'OS_USERNAME': {{ pillar['os.username'] }}
      - 'OS_PASSWORD': {{ pillar['os.password'] }}
      - 'LEADS_QUERY_ENGINE_CONTAINER_NAME': 'query_engine'
      - 'LEADS_QUERY_ENGINE_START': 'Y'
      - 'LEADS_QUERY_ENGINE_HADOOP_FS': {{pillar['yarn']['masters'][0]['private_ip']}}
      - 'LEADS_QUERY_ENGINE_UCLOUD_NAME': {{ pillar['ucloud'] }}
   - names:
     - cd /home/ubuntu; virtualenv openstack_cli; . openstack_cli/bin/activate; pip install -r requirements.txt
     - cd /home/ubuntu; . openstack_cli/bin/activate; bash setup_leads.sh
