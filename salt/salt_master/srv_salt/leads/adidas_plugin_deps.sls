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
