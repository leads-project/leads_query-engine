Import netflix k1ey:
    cmd.run:
        - names:
            - curl 'https://bintray.com/user/downloadSubjectPublicKey?username=netflixoss' | sudo apt-key add -

Netflix ubuntu repo:
  pkgrepo.managed:
    - humanname: Netflix ubuntu
    - name: deb https://dl.bintray.com/netflixoss/ubuntu trusty  main
    - dist: trusty
    - require_in:
      - pkg: Install new pcp

Install new pcp:
    pkg.latest:
        - refresh: True
        - pkgs:
            - pcp
            - pcp-webapi

Setup and restart pm_:
    cmd.run:
        - user: ubuntu
        - names: 
             - sudo update-rc.d pmcd defaults
             - sudo update-rc.d pmlogger defaults
             - sudo service pmcd restart
             - sudo service pmlogger restart 

