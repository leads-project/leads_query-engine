/home/ubuntu/hadoop-2.5.2.tar.gz:
  file:
    - managed
    - user: ubuntu
    - group: ubuntu
    - source: https://archive.apache.org/dist/hadoop/core/hadoop-2.5.2/hadoop-2.5.2.tar.gz
    - source_hash: sha256=0bdb4850a3825208fc97fd869fb2a4e5b7ad1b49f153d21b75c2da1ad5016b43
    - mode: 644
/home/ubuntu/hadoop:
  archive.extracted:
    - name: /home/ubuntu/
    - source: /home/ubuntu/hadoop-2.5.2.tar.gz
    - source_hash: sha256=0bdb4850a3825208fc97fd869fb2a4e5b7ad1b49f153d21b75c2da1ad5016b43
    - tar_options: z
    - archive_format: tar
    - if_missing: /home/ubuntu/hadoop-2.5.2 
    - user: ubuntu
    - group: ubuntu
/home/ubuntu/hadoop-2.5.2/etc/hadoop/hadoop-env.sh:
  file.replace:
   - user: ubuntu
   - group: ubuntu 
   - pattern: \#export HADOOP_HEAPSIZE=
   - repl: export HADOOP_HEAPSIZE=1000
/home/ubuntu/hadoop-2.5.2/etc/hadoop/mapred-site.xml:
  file:
    - managed
    - source: salt://leads/yarn-files/mapred-site.xml.template
    - user: ubuntu
    - group: ubuntu
    - mode: 644
    - template: jinja
    - defaults:
        yarn_master_node: {{pillar['yarn']['masters'][0]['private_ip']}}
        yarn_map_task: 8
        yarn_reduce_task: 6
        yarn_hadoop_home: /home/ubuntu/hadoop-2.5.2
/home/ubuntu/hadoop-2.5.2/etc/hadoop/core-site.xml:
  file:
    - managed
    - source: salt://leads/yarn-files/core-site.xml.template
    - user: ubuntu
    - group: ubuntu
    - mode: 644
    - template: jinja
    - defaults:
        yarn_master_node: {{pillar['yarn']['masters'][0]['private_ip']}}
        yarn_hadoop_home: /home/ubuntu/hadoop-2.5.2
/home/ubuntu/hadoop-2.5.2/etc/hadoop/yarn-site.xml:
  file:
    - managed
    - source: salt://leads/yarn-files/yarn-site.xml.template
    - user: ubuntu
    - group: ubuntu
    - mode: 644
    - template: jinja
    - defaults:
        yarn_master_node: {{pillar['yarn']['masters'][0]['private_ip']}}
/home/ubuntu/hadoop-2.5.2/etc/hadoop/hdfs-site.xml:
  file:
    - managed
    - source: salt://leads/yarn-files/hdfs-site.xml.template
    - user: ubuntu
    - group: ubuntu
    - mode: 644
    - template: jinja
    - defaults:
        yarn_hadoop_home: /home/ubuntu/hadoop-2.5.2
        yarn_hdfs_replica: 1
        yarn_hdfs_xcieversmax: 10096
/home/ubuntu/hadoop-2.5.2/etc/hadoop/slaves:
  file:
    - managed
    - user: ubuntu
    - group: ubuntu
    - mode: 644
    - contents: {% for slave in pillar['yarn']['slaves'] %}
                {{slave.hostname}}
                {% endfor %}
/home/ubuntu/hadoop-2.5.2/etc/hadoop/masters:
  file:
    - managed
    - user: ubuntu
    - group: ubuntu
    - mode: 644
    - contents: {% for m in pillar['yarn']['masters'] %}
                {{m.hostname}}
                {% endfor %}
/etc/hosts:
  file.append:
    - user: root
    - group: root
    - mode: 644
    - text: {% for m in pillar['yarn']['masters'] %}
            {{m.private_ip}} {{m.hostname}}
            {% endfor %}{% for slave in pillar['yarn']['slaves'] %}
            {{slave.private_ip}} {{slave.hostname}}
            {% endfor %} 
         

