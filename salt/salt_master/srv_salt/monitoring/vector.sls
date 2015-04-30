https://github.com/Netflix/vector.git:
    git.latest:
        - user: ubuntu
        - group: ubuntu
        - rev: stable
        - target: /home/ubuntu/vector

nodejs:
    pkg.installed

nodejs-legacy:
    pkg.installed

npm:
    pkg.installed

bower:
    npm.installed:
        - require:
            - pkg: npm

install_vector:
    cmd.run:
        - user: ubuntu
        - group: ubuntu
        - cwd: /home/ubuntu/vector
        - names:
            - bower install
