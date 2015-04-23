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
        - target: /tmp/jzmq

Building jzmq:
    cmd.run:
        - user: ubuntu
        - cwd: /tmp/jzmq
        - names:
          - sudo bash -c "./autogen.sh ; ./configure;  make ; make install"
        - require:
          - git: https://github.com/zeromq/jzmq.git

ldconfig:
    cmd.run:
        - names:
          - sudo ldconfig

/home/ubuntu/.adidas:
    file.directory:    
        - user: ubuntu
        - group: ubuntu
        - mode: 755
        - makedirs: True

/home/ubuntu/.adidas/resources:
    archive.extracted:
        - name: /home/ubuntu/.adidas/
        - user: ubuntu
        - group: ubuntu
        - source: https://object-hamm5.cloudandheat.com:8080/v1/AUTH_73e8d4d1688f4e1f86926d4cb897091f/adidas/adidas-processing-plugin-resources.tar.gz?temp_url_sig=87ba56f7b2c17471c6b1ca5611dc1cbbb70b4574&temp_url_expires=1432116293
        - source_hash: sha256=f016a91d010efac36aebb667d45a7ee4e7251690d9692ae2520c00b244077b9d
        - tar_options: z
        - archive_format: tar
        - if_missing: /home/ubuntu/.adidas/resources

https://github.com/vagvaz/leads-query-processor/:
    git.present:
        - depth: 1
        - rev: adi
        - target: /home/ubuntu/.adidas/leads-query-processor
      
/etc/environment:
    file.append:
        - text:
            - LEADS_ADIDAS_RESOURCES=/home/ubuntu/.adidas/resources
            - LEADS_ADIDAS_PROPERTIES=/home/ubuntu/.adidas/leads-query-processor/plugins/src/main/java/eu/leads/datastore
            - LEADS_ADIDAS_PYTHON=/home/ubuntu/.adidas/leads-query-processor/nqe/system-plugins/adidas-processing-plugin/src/main/python/
            - LEADS_ADIDAS_LOGS=/home/ubuntu/.adidas/logs




