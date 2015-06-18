gitfs_remotes:
    - https://github.com/saltstack-formulas/maven-formula.git

adidas system deps:
    pkg.installed:
              - git-core

git://github.com/brianfrankcooper/YCSB.git:
    git.latest:
        - rev: master
        - target: /tmp/ycsb

maven:
    """
    """



