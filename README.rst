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

Prepare micro-cloud
-----------------------

1. Import the shared project ssh key:

  ::

    make deploy_create_salt_security_group


2. Create basic groups (for saltstack communication)
   
  ::

    make deploy_import_leads_deploy_ssh_key

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
    sudo salt-cloud -c salt  -p saltmaster_hamm5 leads-saltmaster -l debug

Setup cluster
------------------------

1. Create a salt-master:

  ::
    
    sudo salt-cloud -c salt  -p saltmaster_hamm5 leads-saltmaster -l debug

2. Create nodes 3 nodes:
 
  ::

    sudo salt-cloud -c salt -m salt/leads_query-engine.map
 
3. Create 3 nodes for *YARN* (crawling with unicrawl)

  ::

     sudo salt-cloud -c salt -m salt/leads_yarn.map   

Prepare salt-master
---------------------

TODO: move the salt master to git-based back-end. Use hostname for the salt master.

1. Ssh to salt-master (use *--query* subcommand of *salt-cloud* to get the IP)

2. Check whether all minion keys are accepted
   
   ::

      sudo salt-key -L
      sudo salt-key -a <minion_name>

3. Copy content of *salt/salt_master/srv_salt* to /srv/salt/
  
  ::

    mkdir -p /srv/salt
    cp -R salt/salt_master/srv_salt/* /srv/salt

Provision
--------------

1. Login to the leads-saltmaster

2. Copy the content of salt/salt_master/srv_salt to /srv/salt

3. Setup *OS_PASSWORD* in */srv/salt/salt/leads/setup_script.sls*
  
4. Provision the nodes for *query_engine* with infinityspan:
   
  ::

    salt 'leads-qe1' state.highstate -l debug
    salt 'leads-qe2' state.highstate -l debug
    salt 'leads-qe3' state.highstate -l debug

5. Provision the nodes for *YARN* and Unicrawler:
   
  :: 

     salt 'leads-yarn*' state.highstate -l debug

YARN (in migration to salt)
-------------------------------

On you workstation with fabric, after completing provisioning with salt.

1. Fill the missing IPs in ssh_config_tmp and save it to ssh_config.

2. Provision the nodes. Install and configure YARN on the nodes pre-provision by salt:

  ::

    fab -H leads-yarn-1,leads-yarn-2,leads-yarn-2 \
         prepare_hadoop --ssh-config-path=ssh_config

3. With fabric, you can start and stop YARN, also you can format hdfs
  
4. Simple testing:
    
  - run example application:
  
    ::
    
      fab -H leads-yarn-1  hadoop_run_example_application_pi
        --ssh-config-path=ssh_config

  - connect to the console:
    
    ::

      ssh  -L  8088:<private ip>:8088 -L 50075:127.0.0.1:50075 leads-yarn-1 \
         -i ~/.ssh/leads_cluster
         -F ssh_config
  -  connect with your web browser to *http://127.0.0.1:8088/cluster/nodes*

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
