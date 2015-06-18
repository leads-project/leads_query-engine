git-core:
    pkg.installed

https://github.com/brianfrankcooper/YCSB.git:
    git.latest:
        - rev: master
        - target: /home/ubuntu/ycsb

/home/ubuntu/ycsb:
  file.directory:
    - user: ubuntu
    - group: ubuntu
    - recurse:
      - user
      - group

include:
   - maven

# {% for unnecessary_module in ['cassandra', 'hbase', 'hypertable', 'accumulo', 'dynamodb', 'elasticsearch', 'gemfire', 'mongodb', 'orientdb', 'redis', 'voldemort', 'couchbase', 'tarantool'] %}
# do_not_build_{{unnecessary_module}}:
#  file.replace:
#    - name: /home/ubuntu/ycsb/pom.xml
#    - pattern: '<module>{{unnecessary_module}}</module>'
#    - repl: ' '
# {% endfor %}

Building ycsb:
    cmd.run:
        - user: ubuntu
        - group: ubuntu
        - cwd: /home/ubuntu/ycsb
        - env:
           - 'M2_HOME': /usr/lib/apache-maven/
        - names:
           - /usr/lib/apache-maven/bin/mvn package  -Dskip.tests
    require:
        - git: https://github.com/brianfrankcooper/YCSB.git

 

