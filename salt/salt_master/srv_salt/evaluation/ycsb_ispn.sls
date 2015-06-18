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



