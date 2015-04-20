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

/home/ubuntu/nutch/conf/gora.properties:
   file:
      - managed
      - source: salt://leads/unicrawl-files/gora.properties.template
      - user: ubuntu
      - group: ubuntu
      - mode: 644
      - template: jinja
      - defaults:
         ispn_conn_string: {% for n in pillar['ispn']['nodes'] %}{{n['private_ip']}}:11222|{% endfor %}

Comment-out source in /home/ubuntu/nutch/bin/dnutch:
   file.replace:
      - name: /home/ubuntu/nutch/bin/dnutch
      - pattern: source "/mnt/cdrom/context.sh"
      - repl: "   "

Replace NUTCH_HOME in /home/ubuntu/nutch/bin/dnutch:
   file.replace:
      - name: /home/ubuntu/nutch/bin/dnutch
      - pattern: export NUTCH_DIR="/opt/nutch"
      - repl: export NUTCH_DIR="/home/ubuntu/nutch"

zip necessary to modify nutch.jar:
    pkg.installed:
        - pkgs:
            - zip

Add gora.properties to nutch.jar:
  cmd.run:
   - user: ubuntu
   - group: ubuntu
   - names:
      - cd /home/ubuntu/nutch/lib; zip -d nutch-2.2.jar gora.properties;
      - cd /home/ubuntu/nutch; cp conf/gora.properties lib/
      - cd /home/ubuntu/nutch/lib; zip -u nutch-2.2.jar gora.properties; rm gora.properties



