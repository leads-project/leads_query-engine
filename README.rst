================================
Leads distributed query engine
================================

The project goal is to provide an easy way to setup a cluster for FP7 EU LEADS project (http://www.leads-project.eu). 
This project focuses on the query engine. 

More details: TODO put link to a publication.


How to use it 
===============

Basic setup
----------------

1. create a virtualenv (you need to have *virtualenvwrapper* installed)

  ::

    make dev_virtual_create
    make dev_virtual_install_packages

2. Activate the virtualenv:
   
  ::

    $(make dev_virtualenv_printname)

3. Generate the configuration files with you *OS_USER* and *OS_PASSWORD*
   
  ::

    # source the openstack configuration file
    source openrc

    make deploy_saltstack_generate_config

Basic functionality
------------------------------


- list available uclouds:

  :: 

    make list_ucloud

- list available images in uclouds:
  
  ::

    make list_images TARGET_UCLOUD=cah-hamm5

- you can use all the *salt-cloud* functionality, such as creating nodes, you need just to specify the config location:
  
  ::

    # creating new leads cluster salt-master
    sudo salt-cloud -c salt  -p saltmaster_hamm5 leads_saltmaster -l debug

Setup Cluster
------------------------

1. Create a salt-master:

  ::
    
    sudo salt-cloud -c salt  -p saltmaster_hamm5 leads_saltmaster -l debug

2. Create nodes 3 nodes (**Notice**: will be replace by map file):
 
  ::

    sudo salt-cloud -c salt -m salt/leads_query-engine.map
   



Development
================

Dependences
---------------

Testing in Virtualbox:

- VirtualBox (https://www.virtualbox.org/ )
- Vagrant (https://www.vagrantup.com/) 

Cluster management:

- virtualenv 
- virtualenvwrapper 
 
All the additional dependences, you will find in requirements.txt.

Testing
------------

Creating a node locally on dev machine:

::

  vagrant up

Resources
=================

- Cloud&Heat Cloud manuals: https://www.cloudandheat.com/en/support.html
