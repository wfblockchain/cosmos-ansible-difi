# Quick Explanation

## Node Deployment Process

1. **Playbook Execution:**

   - The deployment process is initiated by running the `node.yml` playbook:

     ```bash
     ansible-playbook node.yml -i examples/inventory-difi.yml -e 'target=SERVER_IP_OR_DOMAIN ansible_user=[username] git_username=[git_username] git_pass=[git_personalAccessToken]'
     ```

2. **Inventory File:**
    - ***Location:*** `examples/inventory-difi.yml`
    - ***Purpose:***
        - Defines variables for the difi Git repository and other configurations.
        - Specifies target hosts for Ansible playbooks.

3. **Role Inclusion:**

   - The `node.yml` playbook includes the `node` role, which executes tasks defined in `roles/node/main.yml`.

4. **Task Organization:**

   - `main.yml` imports tasks from other YAML files:

     - **base.yml:**
       - Clones the repository (with modifications)
       - Handles conditional tasks based on `chain_version`
       - Sets installation paths
       - Comments out conflicting tasks
       - Grants permissions and initializes the chain
     - **config.yml, faucet.yml, join.yml:**
       - Adjust permissions (using `become: yes`)
     - **docker_setup.yml (or multi-node_setup.yml):**
       - Installs Docker and Docker Compose
       - Initializes multi-node files (genesis, config, etc.)
       - Modify the config files
       - Deploys containers using Docker Compose

5. **Docker Compose:**

   - `docker_compose.yml` (located in the `cosmos-ansible-difi` folder) defines container configurations for validator nodes.

## Key Points

- The `target` variable in the playbook command specifies the host server where ansble is running. e.g., localhost
- Provide appropriate values for `ansible_user`, `git_username`, and `git_pass`.
<!-- - Consider renaming `docker_setup.yml` to `multi-node_setup.yml` for clarity. -->

<!-- ## Additional Notes

- [Add any further details or explanations as needed.] -->






<!-- ### Misc

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


The command for deployment of containers: 
    ansible-playbook node.yml -i examples/inventory-difi.yml -e 'target=SERVER_IP_OR_DOMAIN ansible_user=[username] git_username=[git_username] git_pass=[git_personalAccessToken]'

 -->
