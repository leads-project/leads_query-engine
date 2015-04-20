ucloud: hamm5

yarn:
  masters:
   - hostname: leads-yarn-1
     private_ip: 10.105.0.46
  slaves:
   - hostname: leads-yarn-2
     private_ip: 10.105.0.51
   - hostname: leads-yarn-3
     private_ip: 10.105.0.47

ispn:
  nodes:
   - 10.105.0.44
