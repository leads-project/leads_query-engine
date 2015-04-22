pcp:
    pkg.installed

Setup and restart pm_:
    cmd.run:
        - user: ubuntu
        - names: 
             - sudo update-rc.d pmcd defaults
             - sudo update-rc.d pmlogger defaults
             - sudo service pmcd restart
             - sudo service pmlogger restart 

