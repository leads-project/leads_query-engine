ucloud: dresden2
yarn:
  masters:
   - hostname: leads-yarn-dresden2-1
     private_ip: 10.102.0.30
  slaves:
   - hostname: leads-yarn-dresden2-2
     private_ip: 10.102.0.42 
   - hostname: leads-yarn-dresden2-3
     private_ip: 10.102.0.43
ispn:
  - nodes: 10.106.0.33
