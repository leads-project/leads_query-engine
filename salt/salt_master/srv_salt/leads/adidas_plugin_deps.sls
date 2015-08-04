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
        - if_missing: /usr/local/lib/libjzmq.a

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


/home/ubuntu/.adidas/adidas-processing-plugin-resources.tar.gz:
    cmd.run:
        - cwd: /home/ubuntu/.adidas
        - user: ubuntu
        - names:
            - wget -O resources.tar.gz  https://object-hamm5.cloudandheat.com:8080/v1/AUTH_73e8d4d1688f4e1f86926d4cb897091f/adidas/adidas-processing-plugin-resources.tar.gz\?temp_url_sig\=5a9cdaca746807a1f7f9b30e230d226de9e74b42\&temp_url_expires\=1464590665
            - tar -xzf resources.tar.gz
        - require:
            - file: /home/ubuntu/.adidas

https://github.com/vagvaz/leads-query-processor/:
    git.latest:
        - user: ubuntu
        - depth: 1
        - rev: adi
        - target: /home/ubuntu/.adidas/leads-query-processor
        - require:
            - file: /home/ubuntu/.adidas

https://github.com/pskorupinski/LeadsAdidasPluginSources:
    git.latest:
        - user: ubuntu
        - rev: master
        - target: /home/ubuntu/.adidas/LeadsAdidasPluginSources
        - require:
            - file: /home/ubuntu/.adidas

/etc/environment:
    file.append:
        - text:
            - LEADS_ADIDAS_RESOURCES=/home/ubuntu/.adidas/resources
            - LEADS_ADIDAS_PROPERTIES=/home/ubuntu/.adidas/LeadsAdidasPluginSources/properties
            - LEADS_ADIDAS_PYTHON=/home/ubuntu/.adidas/LeadsAdidasPluginSources/python
            - LEADS_ADIDAS_LOGS=/home/ubuntu/.adidas/logs
        - require: 
            - git: https://github.com/pskorupinski/LeadsAdidasPluginSources

/etc/init/leads-infextraction-1.conf:
  file:
    - managed
    - source: salt://leads/adidas-files/leads-infextraction.conf.template
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
        leads_adidas_python: /home/ubuntu/.adidas/LeadsAdidasPluginSources/python
        leads_adidas_infext_listen_ip: 127.0.0.1
        leads_adidas_infext_port: 5559

leads-infextraction-1:
  service:
    - running
    - enable: True
    - reload: True
    - require: 
      - file: /etc/init/leads-infextraction-1.conf

/etc/init/leads-infextraction-2.conf:
  file:
    - managed
    - source: salt://leads/adidas-files/leads-infextraction.conf.template
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
        leads_adidas_python: /home/ubuntu/.adidas/LeadsAdidasPluginSources/python
        leads_adidas_infext_listen_ip: 127.0.0.1
        leads_adidas_infext_port: 6000

leads-infextraction-2:
  service:
    - running
    - enable: True
    - reload: True
    - require: 
      - file: /etc/init/leads-infextraction-2.conf



