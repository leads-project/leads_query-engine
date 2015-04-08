/root/setup_leads.sh:
  file:
   - managed
   - user: root
   - group: root
   - source: https://raw.githubusercontent.com/skarab7/leads_query-engine/develop/src/setup_leads.sh 
   - source_hash: sha256=acd07b31b2bab01f271cc2c24a5a2006e0de1a23810d60ac5f454a37c1e98b63 
   - mode: 744 
Execute setup_leads:
  cmd.run:
   - names:
     - bash /root/setup_leads.sh
