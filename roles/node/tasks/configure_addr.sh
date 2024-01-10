#!/bin/bash

VALIDATOR_FILES_PATH="/home/difi/docker"
DOCKER_IMAGE_ID="difi-image"


# get_peer_addr() {
#     if [ $2 = "validator1" ];
#     then
#         PEER_ADDRESS="$1@validator2:26656"
#         $PEER_ADDRESS
#     else
#         PEER_ADDRESS="$1@validator1:26656"
#         $PEER_ADDRESS
#     fi;
# }



retrieve_peerNodeID() {
    if [ $1 = "validator1" ];
    then
        sudo docker run --rm -i -v ${VALIDATOR_FILES_PATH}/validator2:/difi/.difi \
        ${DOCKER_IMAGE_ID} \
        tendermint show-node-id
    else
        sudo docker run --rm -i -v ${VALIDATOR_FILES_PATH}/validator1:/difi/.difi \
        ${DOCKER_IMAGE_ID} \
        tendermint show-node-id
    fi;
}

# $1 - node id
# $2 - node name
# $3 - config_path
change_config() {
    # sed -n '/persistent_peers = /p' $3
    # PEER_ADDR=(get_peer_addr $1 $2)

    if [ $2 = "validator1" ];
    then
        PEER_ADDR="$1@validator2:26656"
    else
        PEER_ADDR="$1@validator1:26656"
    fi;

    echo $PEER_ADDR
    
    sed -i "/^persistent_peers = /s/=.*/= \"$PEER_ADDR\"/" $3

    sed -i "s/addr_book_strict = .*/addr_book_strict = false/" $3

    sed -i "s/pex = .*/pex = false/" $3
}   

update_peer_addr() {
    # Retrieve node ID
    PEER_ID=$(retrieve_peerNodeID $1)

    echo "$1 PEER NODE ID"
    echo $PEER_ID

    # Set config.toml file path
    CONFIG_TOML_PATH=${VALIDATOR_FILES_PATH}/$1/config/config.toml

    # if [ $1 = "validator1" ];
    # then
    #     CONFIG_TOML_PATH=${VALIDATOR_FILES_PATH}/validator2/config/config.toml
    # else
    #     CONFIG_TOML_PATH=${VALIDATOR_FILES_PATH}/validator1/config/config.toml
    # fi;
    
    # echo $CONFIG_TOML_PATH

    change_config $PEER_ID $1 $CONFIG_TOML_PATH
    # sed -n '/$PATTERN/p' $CONFIG_TOML_PATH

}

update_peer_addr validator1
update_peer_addr validator2
