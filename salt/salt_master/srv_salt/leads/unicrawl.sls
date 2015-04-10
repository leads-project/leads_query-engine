/home/ubuntu/unicrawl.tgz:
  archive.extracted:
   - name: /home/ubuntu
   - source: https://object-hamm5.cloudandheat.com:8080/v1/AUTH_73e8d4d1688f4e1f86926d4cb897091f/unicrawl/nutch.tgz?temp_url_sig=6e84ac2c4498c1e232f06781534f5abc90e0d0f3&temp_url_expires=1431265574
   - source_hash: sha256=4eb401d04abdab46ddf8d55424573a6a11bc4d8d7985b13f9b5b3ee68f02ab3d
   - archive_format: tar
   - tar_options: z
   - mode: 644
   - user: ubuntu
   - group: ubuntu
   - if_missing: /home/ubuntu/nutch
