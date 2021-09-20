# Refresh configurations on server
1 `cd /home/workspace/terrestrial/configurations`

2 `git pull`

In case some terraform configuration contains new provider, it needs to be initialized using via

`docker exec -it <docker_container_id> /bin/sh`

`cd configurations/<config_name>`

`terraform init`
