git://git.pcp.io/pcp:
    git.latest:
        - rev: master
        - target: /tmp/pcp

install_pcp:
    cmd.run:
        - user: ubuntu
        - group: ubuntu
        - cwd: /tmp/pcp
        - names:
            - ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var
            - make
            - sudo make install
        - watch:
            - git: git://git.pcp.io/pcp
