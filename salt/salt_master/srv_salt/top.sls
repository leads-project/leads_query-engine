base:
  'leads-qe[12345]':
    - leads.packages
    - leads.adidas_plugin_deps
    - leads.java
    - leads.setup_script
  'leads-yarn-[123]':
    - leads.java
    - leads.yarn
  'leads-yarn-1':
    - leads.unicrawl    
  'leads-yarn-hamm6-*':
    - leads.java
    - leads.yarn
  'leads-yarn-hamm6-1':
    - leads.unicrawl
  'leads-yarn-dresden2-*':
    - leads.java
    - leads.yarn
  'leads-yarn-dresden2-1':
    - leads.unicrawl
  '*':
    - monitoring.pcp
  'leads-saltmaster':
    - monitoring.vector
  'leads-yarn-1':
    - evaluation.ycsb_ispn
  'leads-yarn-hamm6-1':
    - evaluation.ycsb_ispn
  'leads-yarn-dresden2-1':
    - evaluation.ycsb_ispn
  
