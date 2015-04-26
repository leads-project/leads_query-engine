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

1. (RECOMMENDED, **skip 2 and 3**) Install all python-based tools globally: 
   
   ::

     sudo pip install -r requirements

2. create a virtualenv (you need to have *virtualenv* and *virtualenvwrapper* installed)

   ::

     make dev_virtual_create

     # you might need to install additional libraries,
     # such as libssl-dev (ubuntu)
     make dev_virtual_install_packages

3. Activate the virtualenv:
   
   ::

     $(make dev_virtualenv_printname)

4. Generate the configuration files with you *OS_USER* and *OS_PASSWORD*
   
   ::

     # source the openstack configuration file
     source openrc

     make deploy_saltstack_generate_config

Prepare micro-cloud
-----------------------

Most probably, it is done already.

1. Import the shared project ssh key (if it is not there):

   ::

     # import openrc of the target ucloud
     import openrc

     make deploy_import_leads_deploy_ssh_key

2. Create basic groups (for saltstack, yarn, and ispn communication)

   ::

     # import openrc of the target ucloud
     import openrc
     
     make deploy_create_salt_security_group
     make deploy_create_yarn_security_group
     make deploy_create_ispn_security_group   


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

    # get all info about saltmaster
    sudo salt-cloud -c salt  -m salt/leads_saltmaster.map --query

Prepare salt-master
---------------------

Most probably, it is done already.

TODO: move the salt master to git-based back-end. Use hostname for the salt master.

1. Create a salt-master:

   ::
    
     sudo salt-cloud -c salt  -m salt/leads_saltmaster.map
     # OR without map file
     sudo salt-cloud -c salt  -p saltmaster_hamm5 leads-saltmaster -l debug
     
2. Ssh to salt-master (use *--query* subcommand of *salt-cloud* to get the IP)
   
   ::

     sudo salt-cloud -c salt  -m salt/leads_saltmaster.map --query

3. Check whether all minion keys are accepted
   
   ::

     sudo salt-key -L

     # accept the minion key
     sudo salt-key -a <minion_name>

4. Copy content of *salt/salt_master/srv_salt* to /srv/salt/
  
   ::

     mkdir -p /srv/salt
     cp -R salt/salt_master/srv_salt/* /srv/salt

5. Copy content of *salt/salt_master/srv_pillar* to /srv/pillar/

   ::

     mkdir -p /srv/pillar
     cp -R salt/salt_master/srv_pillar/* /srv/pillar

Create VMs
------------------------

0. Check the status of Query-Engine nodes (with *--query* postfix):
   
   ::

     sudo salt-cloud -c salt -m salt/leads_query-engine.map --query

1. Create nodes 3 nodes for Query Engine:
 
   ::

     sudo salt-cloud -c salt -m salt/leads_query-engine.map
 
2. Create 3 nodes for *YARN* (crawling with unicrawl)

   ::

     sudo salt-cloud -c salt -m salt/leads_yarn.map   

3. Create nodes for *Infinispan* cluster (will be merged with 2):
   
   ::

     sudo salt-cloud -c salt  -m salt/leads_infinispan.map

Provision
--------------

1. Login to the leads-saltmaster, to get IP run:

   ::

     sudo salt-cloud -c salt  -m salt/leads_saltmaster.map --query

2. Check if *OS_PASSWORD* is set in */srv/pillar/leads/openstack.sls*

3. Check whether all minion keys are accepted:

   ::

     sudo salt-key -L

4. Check if saltmaster is connected to nodes:

   ::

     sudo salt '*' test.ping
  
5. Provision the nodes for *query_engine* with infinityspan:
   
   ::

     salt 'leads-qe1' state.highstate -l debug
     salt 'leads-qe2' state.highstate -l debug
     salt 'leads-qe3' state.highstate -l debug

6. Provision the nodes for *YARN* and Unicrawler:
   
   :: 

     salt 'leads-yarn*' state.highstate -l debug
     
     
Generate ssh_config
-------------------------

You might want to have a *ssh_config* generated from salt map files. Use the following command:

::

  make generate_ssh_config
  
Notice: it will delete the existing *ssh_config* in the project main directory and create new one.

YARN missing steps (in migration to salt)
------------------------------------------------

On you workstation with fabric, after completing provisioning with salt. We need to setup the ssh (master can login to slaves). Fabric lets us to start and stop hadoop cluster.

1. Generate ssh_config, see Section *Generate ssh_config*

2. Enable ssh between master and slaves:

   ::
  
     fab -H leads-yarn-hamm6-1,leads-yarn-hamm6-2,leads-yarn-hamm6-3\
       do_passwordless_access_to_slaves    --ssh-config-path=ssh_config
  
  Manual: login on leads-yarn-hamm6-1 and add fingerprints of the nodes.

3. Manual fix: after loggin on yarn nodes:

   ::
    
     sudo chown ubuntu:ubuntu * -R

4. With fabric, you can start and stop YARN, also you can format hdfs

   :: 
   
     fab -H leads-yarn-hamm6-1,leads-yarn-hamm6-2,leads-yarn-hamm6-3\
        hadoop_format   --ssh-config-path=ssh_config
     
   ::
   
     fab -H leads-yarn-hamm6-1,leads-yarn-hamm6-2,leads-yarn-hamm6-3\
       start_hadoop_service   --ssh-config-path=ssh_config
  
5. Simple testing:
    
   - run example application:
  
     ::
    
       fab -H leads-yarn-1  hadoop_run_example_application_pi
        --ssh-config-path=ssh_config

   - connect to the console:
    
     ::

       ssh  -L 8088:<private ip>:8088 \
            -L 8042:<private ip>:8042 \
            -L 50070:127.0.0.1:50070 \
            -L 50075:127.0.0.1:50075 leads-yarn-1 \
            -i ~/.ssh/leads_cluster
            -F ssh_config

   -  connect with your web browser to *http://127.0.0.1:8088/cluster/nodes*


Unicrawler
--------------

1. Skip this point, if you have still a valid tempurl:

   ::

    # import archive to swift

    # adapt TARGET_SWIFT_OBJECT in Makefile if needed

    # create temp_url for the Unicrawler archive:
    export MY_SECRET_KEY=$(openssl rand -hex 16)
    # save this key

    make get_swift_tempurl_unicrawl_archive SWIFT_TEMPURL_KEY=${MY_SECRET_KEY}

2. Put the temp_url in *salt/salt_master/srv_salt/leads/unicrawl.cls*. Skip this point, if you have still a valid tempurl.

3. Provision the node (see in /srv/salt/top.sls which node to provision --- now it is the YARN master)
   
4. Setup Unicrawler (prepare hadoop fs):
   
   ::

     fab -H leads-yarn-1 setup_unicrawler \
     --ssh-config ssh_config -f fabfile_unicrawl.py

5. Start Unicrawler:

   ::

     fab -H leads-yarn-1 start_unicrawler \
     --ssh-config ssh_config -f fabfile_unicrawl.py

Infinispan (in migration to salt)
---------------------------------------

1. Skip this point, if you have still a valid tempurl. We use the object store (swift) to deliver packages during installation. To generate tempurl:
  
   ::

     make get_swift_tempurl_ispn_archive SWIFT_TEMPURL_KEY=${MY_SECRET_KEY}

2. Fill the missing IPs in ssh_config_tmp and save it to ssh_config.

3. Check whether you can connect to ispn server:
   
   ::

     ssh leads-ispn-1 -F ssh_config


4. Provision (still with fabfile):
   
   ::

     fab -H leads-ispn-1,leads-ispn-2 install_infinispan \
     --ssh-config ssh_config -f fabfile_ispn.py

5. start the cluster:
   
   ::
   
     fab -H leads-ispn-1,leads-ispn-2 start_infinispan_service \
     --ssh-config ssh_config -f fabfile_ispn.py

6. Check whether the nodes work in cluster:
   
   ::

     ssh leads-ispn-1 -F ssh_config

     grep jgroups ~/infinispan/standalone/log/console.log | grep ispn-1 | grep ispn-2

   You should see:

   ::

     14:47:00,627 INFO  [org.infinispan.remoting.transport.jgroups.JGroupsTransport] 
     (Incoming-1,shared=tcp) 
     ISPN000094: Received new cluster view for channel 26001: [leads-ispn-1/26001|1] 
     (2) [leads-ispn-1/26001, leads-ispn-2/26001]

Monitoring and evaluation
===========================

We install pcp (http://pcp.io/docs/pcpintro.html) on all nodes with salt (see *salt/salt_master/srv_stalt/monitoring/*).

Basic commands
-------------------

Please read first `pcpguide <http://www.pcp.io/pcp.git/man/html/guide.html>`_, it provides a simple guideline on how to use pcp.

 From  `pcpintro <http://pcp.io/docs/pcpintro.html>`_ and `pcpbook <http://pcp.io/books/PCP_UAG/html-single/#LE13618-PARENT>`_:

- *pmstat* - high level overview
- *pminfo* - get all supported probes 
- *pmval* - observe the value of a given probe, e.g.:

  ::

    pmval mem.freemem
    # or grabbing values remotely
    pval mem.freemen -h 10.105.0.44

- *pmcollect* - Statistics collection tool with good coverage of a number of Linux kernel subsystem

  ::

    #<--------CPU--------><----------Disks-----------><----------Network---------->
    #cpu sys inter  ctxsw KBRead  Reads KBWrit Writes KBIn  PktIn  KBOut  PktOut
    36  22   606    572     0      0      0      0    2     24      2     22
    34  16   547    447     0      0     28      2    0      2      0      1 

Vector - adhoc monitoring for DEV
------------------------------------------

Additional on some nodes (see *salt/salt_master/srv_salt/top.sls*), you have *vector* (https://github.com/Netflix/vector/) installed. Please use port forwarding to access it. Below, you have an example for *leads-saltmaster*:

::

  ssh -L 8080:127.0.0.1:8080  -L 44323:127.0.0.1:44323 -F ssh_config leads-saltmaster

Now, open your browser and type *127.0.0.1*. You should a set of graphs for basic metrics. It is very good way to watch over experiments. 

Useful info
==================

Security (network) groups 
------------------------------------

You can add a node to a security group with nova commands:

::

  nova add-secgroup leads-yarn-1 internal_ispn

In this example, we add *leads-yarn-1* to security group *internal_ispn*.


Limitations
==============

- [CLUSTER] still some nodes have to be added to  security groups manually (e.g., nodes that need to connect to YARN and ISPN)
- [YARN] you need manually login to YARN master and add YARN slaves ssh fingerprints

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
