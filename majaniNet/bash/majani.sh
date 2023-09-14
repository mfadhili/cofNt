#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
#

# This script will orchestrate a sample end-to-end execution of the Hyperledger Fabric network
#
# The end-to-end verification provisions a sample Fabric network consisting of two organisations,
# each maintaining two peers, and a "solo" ordering service
#
# This verification makes use of two fundamental tools,
# which are necessary to create a functioning transactional network with
# digital signature validation and access control
#     * cryptogen - generates the x509 certificates used to identify and authenticate the various components in the network
#     * configtxgen - generates the requisite configuration artifacts for orderer bootstrap and channel creation
#
#  Each tool consumes a configuration yaml file,
#  within which we specify the topology of our network (cryptogen)
#  and the location of our certificates for various configuration operations (configtxgen).
#
#  Once the tools have been successfully run, we are able to launch our network.
#
# Prepending $PWD/../bin to PATH to ensure we are picking up the correct binaries.
# This may be commented out to resolve installed version of tools if desired
#

export PATH=$/../bin/:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}

# The default is standing up a full network
DEV_MODE=false

# print usage message
function printHelp() {
    echo "print usage message"
}

# Verify if channel name is given
function verifyChannelName() {
    if [ "$CHANNEL_NAME" == "" ]; then
        echo "Channel name must be specified for this action"
        exit 1
    fi
}

# Verify if contract name is given
function verifyContractName() {
    echo "Verify if contract name is given"
}

# Verify Number of orgs
function verifyNumOrgsInChannel() {
    echo "Verify Number of orgs "
}

# Verify Contract func
function verifyContractFunc() {
    echo "Verify the Contract function"
}

# Verify Organization
function verifyOrganization() {
    echo "Verify organization specified"
}

# Keep pushd silent.
pushd () {
  command pushd "$@" > /dev/null
}

# Keep popd silent ( from not printing on console)
popd () {
  command popd "$@" > /dev/null
}

# Ask user for confirmation to proceed
function askProceed() {
    read -p "Continue? [Y/n] " ans

    case $ans in
    y|Y|"")
      echo "proceeding ..."
      ;;
    n|N)
      echo "exiting ..."
      exit 1
      ;;
    * )
      echo "invalid response"
      askProceed
    esac
}

# Remove unwanted/ leftover images
function removeUnwantedImages() {
    DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[o-9]-" | awk '{print $3}')

    if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" ]; then
      echo "----- No images available for deletion"
    else
      docker rmi -f $DOCKER_IMAGE_IDS
    fi
}

# Do some basic sanity checks on versions of fabric, binaries/images available.
function checkPrereqs() {
    # Note, we check configtxlator externally because it does not require a config file, and peer in the
      # docker image because of FAB-8551 that makes configtxlator return 'development version' in docker
    LOCAL_VERSION=$(configtxlator version | sed -ne 's/ Version: //p')
    DOCKER_IMAGE_VERSION=$(docker run --platform $PLATFORM --rm hyperledger/fabric-tools:$IMAGE_TAG peer version | sed -ne 's/ Version: //p' | head -1)

    echo "LOCAL_VERSION=$LOCAL_VERSION"
    echo "DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION"

    IMAGE_MAJOR_VERSION=${DOCKER_IMAGE_VERSION:0:3}
    ## ERROR .5.3
    if [ "$IMAGE_MAJOR_VERSION" != "$FABRIC_VERSION" ]; then
        echo "=========================== VERSION ERROR ==========================="
        echo "  Expected peer image version ${FABRIC_VERSION}.x"
        echo "  Found peer image version ${DOCKER_IMAGE_VERSION}"
        echo "  Build or download Fabric images ${FABRIC_VERSION}.x"
        echo "  Use the 'release-${FABRIC_VERSION}' branch of Fabric for building from source"
        echo "====================================================================="
        exit 1
    fi

    if [ "$LOCAL_VERSION" != "$DOCKER_IMAGE_VERSION" ] ; then
      echo "=================== WARNING ==================="
      echo "  Local fabric binaries and docker images are  "
      echo "  out of sync. This may cause problems.       "
      echo "==============================================="
    fi
}

# Generate network config files
function generateConfig() {
    PUSHED=false
    # CHeck if we are already in the 'devmode' folder
    if [ $"DEV_MODE" = true -a -d "devmode" ]; then
        pushd ./devmode
        export FABRIC_CFG_PATH=${PWD}
        PUSHED=true
    fi

    # Create network nodes credentials if not exist
    generateCerts

    # Create credentials for multiple Raft ordering nodes only if they don't currently exist
    if [ "$ORDERER_MODE" = "prod" ]
    then
      generateCertsForRaftOrderingNodes
    fi

   # We will overwrite channel artifacts if they already exist
    generateChannelArtifacts
    if [ "$PUSHED" = true ] ; then
      popd
      export FABRIC_CFG_PATH=${PWD}
    fi

}

# Use the cryptogen tool to generate the cryptographic material (x509 certs)n
function generateCerts() {
    which cryptogen
    if [ "$?" -ne 0 ]; then
        echo "cryptogen tool not found. exiting"
        exit 1
    fi
    echo "##########################################################"
    echo "##### Generate certificates using cryptogen tool #########"
    echo "##########################################################"

    if [ -d "crypto-config" ]; then
        echo "'crypto-config' folder already exists. "
        echo "Run 'rm -rt crypto-config' to delete the existing credentials or "
        echo  "'./majani.sh -cleanall' to delete all existing artifacts if you wish to start from a clean slate."
    fi

    set -x
    cryptogen generate --config=./crypto-config.yaml
    res=$?

    set -x
    if [ $res -ne 0 ]; then
        echo "Failed to generate certificates..."
        exit 1
    fi

    echo
}

# TODO generateCertsForRaftOrderingNodes
function generateCertsForRaftOrderingNodes() {

    echo "TODO generateCertsForRaftOrderingNodes"
}

# TODO generateCertsForNewPeer
function generateCertsForRaftOrderingNodes() {
    echo "TODO generateCertsForNewPeer"
}

# TODO generateCertsForNewOrg
function generateCertsForNewOrg() {
    echo "TODO generateCertsForNewOrg"
}

# configtxgen tool is used to create artifacts
function generateChannelArtifacts() {
    which configtxgen
    if [ "$?" -ne 0 ]; then
      echo "configtxgen tool not found. exiting"
      exit 1
    fi

    mkdir -p channel-artifacts/${CHANNEL_NAME}

    PROFILE=TwoOrgsOrdererGenesis
    SYS_CHANNEL=majani-sys-channel
    CHANNEL_PROFILE=TwoOrgsMajaniChannel
    CHANNEL_NAME=majanichannel

    # Overwrite genesis block if it exists
    echo "###########################################################"
    echo "#########  Generating Orderer Genesis block  ##############"
    echo "###########################################################"
    set -x
    # configtxgen -profile TwoOrgsOrdererGenesis -channelID majani-sys-channel -configPath ./ -outputBlock ./channel-artifacts/genesis.block
    configtxgen -profile $PROFILE -channelID $SYS_CHANNEL -outputBlock ./channel-artifacts/genesis.block
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "Failed to generate orderer genesis block..."
        exit 1
    fi
    echo

    echo "###################################################################"
    echo "###  Generating channel configuration transaction  'channel.tx' ###"
    echo "###################################################################"
    set -x
    # configtxgen -profile TwoOrgsMajaniChannel -outputCreateChannelTx ./channel-artifacts/majanichannel/channel.tx -channelID majanichannel -configPath ./
    configtxgen -profile $CHANNEL_PROFILE -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}/channel.tx -channelID $CHANNEL_NAME
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate channel configuration transaction..."
      exit 1
    fi
    echo

    echo "#####################################################################"
    echo "#######   Generating anchor peer update for FarmerOrg    ##########"
    echo "#####################################################################"
    set -x
    # configtxgen -profile TwoOrgsMajaniChannel -outputAnchorPeersUpdate ./channel-artifacts/majanichannel/FarmerOrgMSPanchors.tx -channelID majanichannel -asOrg FarmerOrg -configPath ./
    configtxgen -profile $CHANNEL_PROFILE -outputAnchorPeersUpdate ./channel-artifacts/${CHANNEL_NAME}/FarmerOrgMSPanchors.tx -asOrg FarmerOrg -channelID $CHANNEL_NAME
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate anchor peer update for FarmerOrg..."
      exit 1
    fi

    echo "#####################################################################"
    echo "#######   Generating anchor peer update for FactoryOrg    ##########"
    echo "#####################################################################"
    set -x
    # configtxgen -profile TwoOrgsMajaniChannel -outputAnchorPeersUpdate ./channel-artifacts/majanichannel/FactoryOrgMSPanchors.tx -channelID majanichannel -asOrg FactoryOrg -configPath ./
    configtxgen -profile $CHANNEL_PROFILE -outputAnchorPeersUpdate ./channel-artifacts/${CHANNEL_NAME}/FactoryOrgMSPanchors.tx -asOrg FactoryOrg -channelID $CHANNEL_NAME
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate anchor peer update for FactoryOrg..."
      exit 1
    fi
    echo
}

# TODO generateChannelConfigForNewOrg
function generateChannelConfigForNewOrg() {
    echo "TODO generateChannelConfigForNewOrg"
}

# Generate the needed certificates, the genesis block and start the network.
function networkUp() {
    checkPrereqs

   # Generate artifacts if they don't exist
   if [ ! -d "crypto-config" -o ! -f "channel-artifacts/genesis.block" -o ! -f "docker-compose-e2e.yaml" ]; then
     echo "Network artifacts or configuration missing. Run './majani.sh generate -c <channel_name>' to recreate them."
     exit 1
   fi

   # Create folder for docker network logs
   LOG_DIR=$(dirname $LOG_FILE)
   if [ ! -d $LOG_DIR ]
   then
     mkdir -p $LOG_DIR
   fi

   COMPOSE_FILE_DB=
   NUM_CONTAINERS=0

   # Irrelevant for dev mode
   if [ "$DB_TYPE" = "couchdb" -a "$DEV_MODE" != true ]
     then
       COMPOSE_FILE_DB="-f "$COMPOSE_FILE_COUCHDB
       NUM_CONTAINERS=3
  fi

  # compose network if prod
  if [ "$ORDERER_MODE" = "prod" ]
  then
    docker-compose -f $COMPOSE_FILE_RAFT $COMPOSE_FILE_DB up >$LOG_FILE 2>&1 &
    NUM_CONTAINERS=$(($NUM_CONTAINERS + 13))
  else
    docker-compose -f $COMPOSE_FILE $COMPOSE_FILE_DB up >$LOG_FILE 2>&1 &
    NUM_CONTAINERS=$(($NUM_CONTAINERS + 9))
  fi

  # REMOVED restore folder if on dev mode, still used

  # error handling
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to start network"
    exit 1
  fi

  sleep 2
  NETWORK_CONTAINERS=$(docker ps -a | grep "hyperledger/\|couchdb" | wc -l)
  echo "Network containers start"

  # REMOVED Below check assumes there are no container running other than in our network
}

# TODO newPeerUp
# Start the container for the new peer.
function newPeerUp() {
    echo " TODO newPeerUp"
}

# TODO newOrgNetworkUp
# Start the network components for the new org.
function newOrgNetworkUp() {
    echo "TODO newOrgNetworkUp"
}

# TODO checkAndStartCliContainer
# Check if CLI container is running, and start it if it isn't
function checkAndStartCliContainer() {
    echo "TODO checkAndStartCliContainer "
}

# Create a channel using the generated genesis block.
function createChannel() {
    checkPrereqs
    CHANNEL_NAME=majanichannel
    # check presence of channel transaction file
    if [ ! -f "channel-artifacts/"${CHANNEL_NAME}"/channel.tx" ]; then
      echo "ERROR !!!! No 'channel.tx' found in folder 'channel-artifacts/"${CHANNEL_NAME}"'"
      echo "ERROR !!!! Run './majani.sh generate -c "$CHANNEL_NAME"' to create this transaction file"
      exit 1
    fi

    # Create folder for docker network logs
    LOG_DIR=$(dirname $LOG_FILE_CREATE)
    if [ ! -d $LOG_DIR ]
    then
      mkdir -p $LOG_DIR
    fi

    # Check if the cli container is already running
    checkAndStartCliContainer

    # Create the channel
    #docker exec -e CHANNEL_NAME=$CHANNEL_NAME $CONTAINER_CLI scripts/channel.sh create >>$LOG_FILE_CLI 2>&1
    # Create and join channel
    ./scripts/channel.sh  create majanichannel >>$LOG_FILE_CREATE 2>&1

    if [ $? -ne 0 ]; then
      echo "ERROR !!!! Unable to create channel"
      echo "ERROR !!!! See "$LOG_FILE_CREATE" for details"
      exit 1
    fi
    echo "Channel "$CHANNEL_NAME" created"
}

# TODO joinPeersToChannel
# Join peers to the channel with the given name.
function joinPeersToChannel() {
    echo "TODO joinPeersToChannel"
}

# TODO joinNewPeerToChannel
function joinNewPeerToChannel() {
    echo "TODO joinNewPeerToChannel"
}

# TODO joinNewOrgPeerToChannel
function joinNewOrgPeerToChannel() {
    echo "TODO joinNewOrgPeerToChannel"
}

# TODO fetchChannelConfig
function fetchChannelConfig() {
    echo "fetchChannelConfig"
}

# TODO updateAnchorPeers
function updateAnchorPeers() {
    echo "TODO updateAnchorPeers"
}

# TODO updateNewOrgAnchorPeer
function updateNewOrgAnchorPeer() {
    echo "TODO updateNewOrgAnchorPeer"
}

# TODO updateChannel
function updateChannel() {
    echo "TODO updateChannel"
}
# TODO installContract
function installContract() {
    echo "TODO installContract"
}

# TODO initContract
function initContract() {
    echo "TODO initContract"
}

# TODO upgradeContract
function upgradeContract() {
    echo "TODO upgradeContract"
}

# TODO invokeContract
function invokeContract() {
    echo "TODO invokeContract"
}

# TODO queryContract
function queryContract() {
    echo "TODO queryContract"
}

# TODO upgradeNetwork
function upgradeNetwork() {
    echo "TODO upgradeNetwork"
}

# TODO networkDown
function networkDown() {
    echo "TODO networkDown"
}

# TODO newPeerDown
function newPeerDown() {
    echo "TODO newPeerDown"
}

# TODO newOrgNetworkDown
function newOrgNetworkDown() {
    echo "TODO newOrgNetworkDown"
}

# TODO cleanDynamicIdentities
function cleanDynamicIdentities() {
    echo "TODO cleanDynamicIdentities"
}

# TODO networkClean
function networkClean() {
    echo "TODO networkClean"
}

# TODO networkCleanAll
function networkCleanAll() {
    echo "TODO networkCleanAll"
}

# TODO startRestServers
function startRestServers() {
    echo "TODO startRestServers"
}

# TODO stopRestServers
function stopRestServers() {
    echo "TODO stopRestServers"
}


# use this as the default docker-compose yaml definition
CHANNEL_NAME_DEV_MODE=majani-dev-channel
COMPOSE_FILE=docker-compose-e2e.yaml
#COMPOSE_FILE_NEW_PEER=docker-compose-another-importer-peer.yaml
#COMPOSE_FILE_NEW_ORG=docker-compose-exportingEntityOrg.yaml
COMPOSE_FILE_RAFT=docker-compose-raft-orderer.yaml
COMPOSE_FILE_CLI=docker-compose-cli.yaml
COMPOSE_FILE_REST=docker-compose-rest.yaml
COMPOSE_FILE_COUCHDB=docker-compose-couchdb.yaml
# default container names
CONTAINER_CLI=majani_cli
FABRIC_VERSION="2.5"
# default log file
LOG_FILE="logs/network.log"
LOG_FILE_NEW_PEER="logs/network-newpeer.log"
LOG_FILE_NEW_ORG="logs/network-neworg.log"
LOG_FILE_CLI="logs/network-cli.log"
LOG_FILE_REST="logs/network-rest.log"
ORDERER_MODE=test
CONTRACT_ARGS=
DB_TYPE=couchdb
RETAIN_VOLUMES=false

# Parse commandline args
MODE=$1;shift

# Determine whether starting, stopping, restarting or generating for announce
if [ "$MODE" == "up" ]; then
  EXPMODE="Starting network"
elif [ "$MODE" == "down" ]; then
  EXPMODE="Stopping network"
elif [ "$MODE" == "restart" ]; then
  EXPMODE="Restarting network"
elif [ "$MODE" == "reset" ]; then
  EXPMODE="Cleaning temporary user credentials and chaincode containers"
elif [ "$MODE" == "clean" ]; then
  EXPMODE="Cleaning network and channel configurations"
elif [ "$MODE" == "cleanall" ]; then
  EXPMODE="Cleaning network, channel configurations, and crypto artifacts"
elif [ "$MODE" == "generate" ]; then
  EXPMODE="Generating certs and genesis block"
elif [ "$MODE" == "createchannel" ]; then
  EXPMODE="Creating channel through ordering service using channel transaction"
elif [ "$MODE" == "joinchannel" ]; then
  EXPMODE="Joining peers to channel"
elif [ "$MODE" == "fetchconfig" ]; then
  EXPMODE="Fetching latest channel configuration block"
elif [ "$MODE" == "updateanchorpeers" ]; then
  EXPMODE="Updating anchor peers for orgs"
elif [ "$MODE" == "updatechannel" ]; then
  EXPMODE="Updating channel configuration through ordering service to add a new org"
elif [ "$MODE" == "installcontract" ]; then
  EXPMODE="Installing contract on channel"
elif [ "$MODE" == "initcontract" ]; then
  EXPMODE="Initializing contract on channel"
elif [ "$MODE" == "upgradecontract" ]; then
  EXPMODE="Upgrading contract on channel after addition of new org"
elif [ "$MODE" == "invokecontract" ]; then
  EXPMODE="Invoking contract on channel"
elif [ "$MODE" == "querycontract" ]; then
  EXPMODE="Querying contract on channel"
elif [ "$MODE" == "upgrade" ]; then
  EXPMODE="Upgrading the network"
elif [ "$MODE" == "createnewpeer" ]; then
  EXPMODE="Generating certs for new peer"
elif [ "$MODE" == "startnewpeer" ]; then
  EXPMODE="Starting new peer"
elif [ "$MODE" == "stopnewpeer" ]; then
  EXPMODE="Stopping new peer"
elif [ "$MODE" == "joinnewpeer" ]; then
  EXPMODE="Joining new peer to existing channels"
elif [ "$MODE" == "createneworg" ]; then
  EXPMODE="Generating certs and configuration for new org"
elif [ "$MODE" == "startneworg" ]; then
  EXPMODE="Starting peer and CA for new org"
elif [ "$MODE" == "stopneworg" ]; then
  EXPMODE="Stopping peer and CA for new org"
elif [ "$MODE" == "joinneworg" ]; then
  EXPMODE="Joining peer of new org to existing channels"
elif [ "$MODE" == "updateneworganchorpeer" ]; then
  EXPMODE="Updating anchor peer for new org"
elif [ "$MODE" == "startrest" ]; then
  EXPMODE="Starting REST servers"
elif [ "$MODE" == "stoprest" ]; then
  EXPMODE="Stopping REST servers"
else
  printHelp
  exit 1
fi

# Parse the command-line options
while getopts "h?c:p:f:g:l:b:o:d:t:a:m:s:r" opt; do
  case "$opt" in
    h|\?)
      printHelp
      exit 0
    ;;
    c)  CHANNEL_NAME=$OPTARG
    ;;
    p)  CONTRACT_NAME=$OPTARG
    ;;
    f)  COMPOSE_FILE=$OPTARG
    ;;
    g)  ORGANIZATION=$OPTARG
    ;;
    l)  LOG_FILE=$OPTARG
    ;;
    b)  BLOCK_FILE=$OPTARG
    ;;
    o)  NUM_ORGS_IN_CHANNEL=$OPTARG
    ;;
    d)  DEV_MODE=$OPTARG
    ;;
    t)  CONTRACT_FUNC=$OPTARG
    ;;
    a)  CONTRACT_ARGS=$OPTARG
    ;;
    m)  ORDERER_MODE=$OPTARG
    ;;
    s)  DB_TYPE=$OPTARG
    ;;
    r)  RETAIN_VOLUMES=true
    ;;
  esac
done

#
if [ "$BLOCK_FILE" == "" ]
then
  BLOCK_FILE=$CHANNEL_NAME.block
fi

# Load default environment variables
source .env

################
#NAVIGATIONS
################

#Create the network using docker compose
if [ "${MODE}" == "up" ]; then
  echo "${EXPMODE}"
  networkUp
elif [ "${MODE}" == "down" ]; then ## Clear the network
  echo "${EXPMODE}"
  networkDown
elif [ "${MODE}" == "generate" ]; then ## Generate Artifacts
  if [ "$DEV_MODE" = "true" ] ; then
    CHANNEL_NAME=$CHANNEL_NAME_DEV_MODE
  else
    verifyChannelName
    verifyNumOrgsInChannel
  fi
  echo "${EXPMODE} for channel '${CHANNEL_NAME}'"
  generateConfig
elif [ "${MODE}" == "restart" ]; then ## Restart the network
  echo "${EXPMODE}"
  networkDown
  networkUp
elif [ "${MODE}" == "reset" ]; then ## Delete chaincode containers and dynamically created user credentials while keeping network artifacts
  echo "${EXPMODE}"
  cleanDynamicIdentities
  removeUnwantedImages
elif [ "${MODE}" == "clean" ]; then ## Delete network artifacts, chaincode containers, contract images, and dynamically created user credentials
  echo "${EXPMODE}"
  networkClean
elif [ "${MODE}" == "cleanall" ]; then ## Delete network artifacts, chaincode containers, contract images, statically and dynamically created user credentials
  echo "${EXPMODE}"
  networkCleanAll
elif [ "${MODE}" == "createchannel" ]; then ## Create a channel with the given name
  verifyChannelName
  echo "${EXPMODE} for channel '${CHANNEL_NAME}'"
  createChannel
elif [ "${MODE}" == "joinchannel" ]; then ## Join all orgs' peers to a channel with the given name
  verifyChannelName
  verifyNumOrgsInChannel
  echo "${EXPMODE} for channel '${CHANNEL_NAME}'"
  joinPeersToChannel
elif [ "${MODE}" == "fetchconfig" ]; then ## Fetch latest configuration block of channel with the given name
  verifyChannelName
  echo "${EXPMODE} for channel '${CHANNEL_NAME}'"
  fetchChannelConfig
elif [ "${MODE}" == "updateanchorpeers" ]; then ## Update anchor peers of orgs in channel with the given name
  verifyChannelName
  verifyNumOrgsInChannel
  echo "${EXPMODE} for channel '${CHANNEL_NAME}'"
  updateAnchorPeers
elif [ "${MODE}" == "updatechannel" ]; then ## Update a channel with the given name to add a new org
  verifyChannelName
  verifyNumOrgsInChannel
  echo "${EXPMODE} for channel '${CHANNEL_NAME}'"
  updateChannel
elif [ "${MODE}" == "installcontract" ]; then ## Install contract on channel
  verifyChannelName
  verifyNumOrgsInChannel
  verifyContractName
  echo "${EXPMODE} for contract '${CONTRACT_NAME}' on channel '${CHANNEL_NAME}'"
  installContract
elif [ "${MODE}" == "initcontract" ]; then ## Initialize contract ledger state using designated function and arguments
  verifyChannelName
  verifyContractName
  verifyContractFunc
  echo "${EXPMODE} for contract '${CONTRACT_NAME}' on channel '${CHANNEL_NAME}'"
  initContract
elif [ "${MODE}" == "upgradecontract" ]; then ## Upgrade contract code after addition of new org
  verifyChannelName
  verifyNumOrgsInChannel
  verifyContractName
  verifyContractFunc
  echo "${EXPMODE} for contract '${CONTRACT_NAME}' on channel '${CHANNEL_NAME}'"
  upgradeContract
elif [ "${MODE}" == "invokecontract" ]; then ## Invoke contract transaction
  verifyChannelName
  verifyContractName
  verifyContractFunc
  verifyOrganization
  echo "${EXPMODE} for contract '${CONTRACT_NAME}' on channel '${CHANNEL_NAME}' using organization '${ORGANIZATION}'"
  invokeContract
elif [ "${MODE}" == "querycontract" ]; then ## Query contract function
  verifyChannelName
  verifyContractName
  verifyContractFunc
  verifyOrganization
  echo "${EXPMODE} for contract '${CONTRACT_NAME}' on channel '${CHANNEL_NAME}' using organization '${ORGANIZATION}'"
  queryContract
elif [ "${MODE}" == "upgrade" ]; then ## Upgrade the network from one version to another (new Fabric and Fabric-CA versions specified in .env)
  echo "${EXPMODE}"
  upgradeNetwork
elif [ "${MODE}" == "createnewpeer" ]; then ## Create crypto artifacts for new peer
  echo "${EXPMODE}"
  generateCertsForNewPeer
elif [ "${MODE}" == "startnewpeer" ]; then ## Start new peer
  echo "${EXPMODE}"
  newPeerUp
elif [ "${MODE}" == "stopnewpeer" ]; then ## Start new peer
  echo "${EXPMODE}"
  newPeerDown
elif [ "${MODE}" == "joinnewpeer" ]; then ## Join new peer to channel
  verifyChannelName
  echo "${EXPMODE} for channel '${CHANNEL_NAME}'"
  joinNewPeerToChannel
elif [ "${MODE}" == "createneworg" ]; then ## Generate artifacts for new org
  verifyChannelName
  echo "${EXPMODE} for channel '${CHANNEL_NAME}'"
  generateCertsForNewOrg
  generateChannelConfigForNewOrg
elif [ "${MODE}" == "startneworg" ]; then ## Start the network components for the new org
  echo "${EXPMODE}"
  newOrgNetworkUp
elif [ "${MODE}" == "stopneworg" ]; then ## Stop the network components for the new org
  echo "${EXPMODE}"
  newOrgNetworkDown
elif [ "${MODE}" == "joinneworg" ]; then ## Join peer of new org to channel
  verifyChannelName
  echo "${EXPMODE} for channel '${CHANNEL_NAME}'"
  joinNewOrgPeerToChannel
elif [ "$MODE" == "updateneworganchorpeer" ]; then ## Update anchor peer for new org on channel
  verifyChannelName
  echo "${EXPMODE} for channel '${CHANNEL_NAME}'"
  updateNewOrgAnchorPeer
elif [ "${MODE}" == "startrest" ]; then ## Start rest servers
  echo "${EXPMODE}"
  startRestServers
elif [ "${MODE}" == "stoprest" ]; then ## Stop rest servers
  echo "${EXPMODE}"
  stopRestServers
else
  printHelp
  exit 1
fi













