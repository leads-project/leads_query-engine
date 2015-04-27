=================================
Backup pcp to swift container
=================================

(TODO: create salt for that, currently implemented in fabric_metrics.py)

**Notice**: default it will upload only pcp files from the last 24 hours.

1. Put the script *copy_pcp_to_swift.sh* to /home/ubuntu/metrics/backup 

2. In /home/ubuntu/metrics/backup, run:

   ::

     virtualenv openstack_cli
     source openstack_cli/bin/activate
     pip install -r requirements.txt
    
3. Setup Openstack ENV variables (as in *openrc*) and run
  
   ::
     
     bash copy_pcp_to_swift.sh
     
