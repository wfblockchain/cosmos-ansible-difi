
## Quick Explanation

we run the node.yml file in playbook command, which includes the node role, which redirects to the roles/node/main.yml file

main.yml file imports tasks from the other files like base.yml, config.yml, docker_setup.yml, etc

base.yml 
    - clone the repo modified
    - some modifications in conditions of tasks which ask chain_version
    - Change in install task such that path is set 
    - commented some conflicting and unnecessary tasks
    - Give Permissions and Initialize chain task added

config.yml, faucet.yml, join.yml, 
    - changed the permissions(become : yes)

docker_setup.yml (can be changed to multi-node_setup.yml)
    - Install docke, docker compose
    - Initialize and Setup the multinode files like genesis, config, etc.
    - Deploy containers using docker compose


docker_compose.yml in cosmos-ansible-difi folder
    - The docker-compose file to deploy the containers for nodes of validators


