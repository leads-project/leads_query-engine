https://github.com/Netflix/vector.git:
    git.latest:
        - user: ubuntu
        - group: ubuntu
        - rev: master
        - target: /home/ubuntu/vector

bower deps:
    pkg.installed:
        - pkgs:
            - npm

bower:
  npm.installed:
    - user: ubuntu
    - require:
      - pkg: npm


install_vector:
    cmd.run:
        - user: ubuntu
        - group: ubuntu
        -cwd: /home/ubuntu/vector
        - names:
            - bower install
