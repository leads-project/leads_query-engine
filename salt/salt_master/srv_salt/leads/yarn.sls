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
