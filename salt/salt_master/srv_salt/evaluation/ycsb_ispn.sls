git-core:
    pkg.installed

https://github.com/otrack/Leads-infinispan.git:
    git.latest:
       - rev: master
       - target: /home/ubuntu/leads-infinispan

/home/ubuntu/leads-infinispan:
  file.directory:
    - user: ubuntu
    - group: ubuntu
    - recurse:
      - user
      - group

{{pillar['ycsb.git']}}:
    git.latest:
        - rev: build_only_for_cassandra_and_infinispan
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

Install leads-infinispan:
    cmd.run:
        - user: ubuntu
        - group: ubuntu
        - cwd: /home/ubuntu/leads-infinispan
        - env:
           - 'M2_HOME': /usr/lib/apache-maven/
        - names:
           - /usr/lib/apache-maven/bin/mvn install -Dskip.tests
    require:
        - git: https://github.com/otrack/Leads-infinispan.git

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
        - git: {{pillar['ycsb.git']}}
        - cmd.run: Install leads-infinispan
 

