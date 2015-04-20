adidas system deps:
    pkg.installed:
        - pkgs:
            - build-essential
            - python-pip
            - python-dev
            - python-setuptools
            - python-numpy
            - python-scipy
            - libatlas-dev
            - libatlas3gf-base
            - libzmq3-dev
            - libxslt1-dev
            - libxslt1.1
            - libxml2-dev
            - libxml2
            - libssl-dev

Setup alternatives:
    cmd.run:
        - user: ubuntu
        - group: ubuntu
        - names:
            - sudo update-alternatives --set libblas.so.3  /usr/lib/atlas-base/atlas/libblas.so.3
            - sudo update-alternatives --set liblapack.so.3 /usr/lib/atlas-base/atlas/liblapack.so.3

scikit-learn:
    pip.installed:
        - name: scikit-learn
    

requests:
    pip.installed:
        - name: requests

lxml:
    pip.installed:
        - name: lxml

BeautifulSoup:
    pip.installed:
        - name: BeautifulSoup

Pyzmq:
    pip.installed:
        - name:  pyzmq

Building jzmq deps:
    pkg.installed:
        - pkgs:
          - pkg-config
          - libtool
          - uuid-dev
          - autoconf
          - git-core

https://github.com/zeromq/jzmq.git:
    git.latest:
        - rev: master
        - target: /tmp/zmq

Building jzmq:
    cmd.run:
        - user: ubuntu
        - names:
          - ./configure
          - make
          - sudo make install

ldconfig:
    cmd.rum:
        - names:
          - sudo ldconfig

/home/ubuntu/.adidas:
    file.directory:    
        - user: ubuntu
        - group: ubuntu
        - mode: 755
        - makedirs: True

/home/ubuntu/.adidas/english.all.3class.distsim.crf.ser.gz:
    file:
        - managed
        - user: ubuntu
        - group: ubuntu
        - source: https://object-hamm5.cloudandheat.com:8080/v1/AUTH_73e8d4d1688f4e1f86926d4cb897091f/adidas/english.all.3class.distsim.crf.ser.gz?temp_url_sig=cc20f8b8564cf2e8693693efc556a668fd0b8d88&temp_url_expires=1431725537
        - source_hash: sha256=122d5348a57de0e0e828e188dbd01975313759778a4dbbfd00df0a84dd77e34f
        - mode: 644


