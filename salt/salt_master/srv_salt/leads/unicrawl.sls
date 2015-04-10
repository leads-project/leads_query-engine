/home/ubuntu/unicrawl.tgz:
  archive.extracted:
   - name: /home/ubuntu
   - source: https://object-hamm5.cloudandheat.com:8080/v1/AUTH_73e8d4d1688f4e1f86926d4cb897091f/unicrawl/nutch.tgz?temp_url_sig=946fd821178d00842628c5c53b37d6e627c80975&temp_url_expires=1431242894
   - source_hash: sha256=4eb401d04abdab46ddf8d55424573a6a11bc4d8d7985b13f9b5b3ee68f02ab3d
   - archive_format: tar
   - tar_options: z
   - mode: 644
   - user: ubuntu
   - group: ubuntu
   - if_missing: /home/ubuntu/nutch
