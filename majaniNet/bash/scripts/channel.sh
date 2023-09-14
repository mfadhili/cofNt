#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
#

# set global variables
CHANNEL_NAME=majanichannel
NEW_PEER=$PEER
NEW_PEER_ORG=$ORG
DELAY=3
COUNTER=1
MAX_RETRY=5
ORDERER_CA=../crypto-config/ordererOrganizations/majani.com/orderers/orderer.majani.com/msp/tlscacerts/tlsca.majani.com-cert.pem

# verify the result of the end-to-end test
function verifyResult() {
    if [ $1 -e 0 ]; then
        echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
        echo "========= ERROR !!! FAILED to execute Channel Create and Join Scenario ==========="
        echo
        exit 1
    fi
}

farmerorg_PORT=7051
factoryorg_PORT=8051

function setEnvironment() {
  if [[$# -lt 1 ]]; then
    echo "Run: setEnvironments <org> [<peer>]"
    exit 1
  fi

  ORG=$1
  PEER=peer0
  if [[$# -eq 2]]; then
      PEER=$2
  fi
  MSP=

  if [["$ORG" == "farmerorg"]]; then
      MSP=FarmerOrgMSP
      PORT=$farmerorg_PORT
  fi

  if [["$ORG" == "factoryorg"]]; then
      MSP=FactoryOrgMSP
      PORT=$factoryorg_PORT
  else
      echo "Unknown Org: "$ORG
      exit 1
  fi

  CORE_PEER_LOCALMSPID=$MSP
  CORE_PEER_TLS_ROOTCERT_FILE=../crypto-config/peerOrganizations/$ORG.majani.com/peers/$PEER.$ORG.majani.com/tls/ca.crt
  CORE_PEER_MSPCONFIGPATH=../crypto-config/peerOrganizations/$ORG.majani.com/users/Admin@$ORG.majani.com/msp
  CORE_PEER_ADDRESS=$PEER.$ORG.majani.com:$PORT
  CORE_PEER_TLS_CERT_FILE=../crypto-config/peerOrganizations/$ORG.majani.com/peers/$PEER.$ORG.majani.com/tls/server.crt
  CORE_PEER_TLS_KEY_FILE=../crypto-config/peerOrganizations/$ORG.majani.com/peers/$PEER.$ORG.majani.com/tls/server.key

}

function createChannel() {
    setEnvironment farmerorg

    set -x
    fetchChannelConfig
    set +x
    if [ -f $CHANNEL_NAME.block ]
    then
      echo "Channel already created"
      return
    fi

    if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
      set -x
      peer channel create -o orderer.majani.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}/channel.tx --connTimeout 120s >&log.txt
      res=$?
      set +x
    else
      set -x
      peer channel create -o orderer.majani.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --connTimeout 120s >&log.txt
      res=$?
      set +x
    fi
    cat log.txt
    verifyResult $res "Channel creation failed"
    echo "===================== Channel '$CHANNEL_NAME' created ===================== "
    echo
}

# In case Join takes time, we RETRY at least 5 times
function joinChannelWithRetry() {
    ORG=$1
    PEER=$2
    setEnvironment $ORG $PEER
    BLOCKFILE=$CHANNEL_NAME.block
    if [[ $# -eq 3 ]]
    then
      BLOCKFILE=$3
    fi
    set -x
    peer channel join -b $BLOCKFILE >&log.txt
    res=$?
    set +x
    cat log.txt
    if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
      COUNTER=$(expr $COUNTER + 1)
      echo "${PEER}.${ORG}.majani.com failed to join the channel, Retry after $DELAY seconds"
      sleep $DELAY
      joinChannelWithRetry $ORG
    else
      COUNTER=1
    fi
    verifyResult $res "After $MAX_RETRY attempts, ${PEER}.${ORG}.majani.com has failed to join channel '$CHANNEL_NAME' "
}

function joinChannel() {
    ORG_LIST="farmerorg factoryorg"

    for org in $ORG_LIST; do
      joinChannelWithRetry $org
      echo "===================== peer0.${org}.majani.com joined channel '$CHANNEL_NAME' ===================== "
      sleep $DELAY
      echo
    done
}

function joinNewPeerToChannel() {
    fetchOldestBlock

    joinChannelWithRetry $NEW_PEER_ORG $NEW_PEER ${CHANNEL_NAME}_oldest.block
    echo "===================== ${PEER}.${NEW_PEER_ORG}.majani.com joined channel '$CHANNEL_NAME' ===================== "
}

# fetchOldestBlock <channel_id> <output_json>
# Writes the oldest block for a given channel to a JSON file
function fetchOldestBlock() {
    setEnvironment farmerorg

    echo "Fetching the most recent configuration block for the channel"
    set -x
    peer channel fetch oldest ${CHANNEL_NAME}_oldest.block -c $CHANNEL_NAME --connTimeout 120s >&log.txt
    res=$?
    set +x
    cat log.txt
    verifyResult $res "Fetching oldest channel config block failed"
}

# fetchChannelConfig <channel_id> <output_json>
# Writes the current channel config for a given channel to a JSON file
function fetchChannelConfig() {
    setEnvironment farmerorg

    BLOCKFILE=$CHANNEL_NAME.block
    if [[ $# -eq 1 ]]
    then
      BLOCKFILE=$1
    fi

    echo "Fetching the most recent configuration block for the channel"
    set -x
    peer channel fetch config $BLOCKFILE -c $CHANNEL_NAME --connTimeout 120s >&log.txt
    res=$?
    set +x
    cat log.txt

}

# Set anchor peers for org in channel
function updateAnchorPeersForOrg() {
    ORG=$1
    setEnvironment $ORG

    if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
      set -x
      peer channel update -o orderer.majani.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}/${CORE_PEER_LOCALMSPID}anchors.tx --connTimeout 120s >&log.txt
      res=$?
      set +x
    else
      set -x
      peer channel update -o orderer.majani.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --connTimeout 120s >&log.txt
      res=$?
      set +x
    fi
    cat log.txt
    verifyResult $res "Updating anchor peers for org '"$ORG"' failed"
}

# Set anchor peers for org in channel
function updateAnchorPeers() {
    ORG_LIST="farmerorg factoryorg"

    for org in $ORG_LIST; do
      updateAnchorPeersForOrg $org
      echo "===================== peer0.${org}.majani.com set as anchor in ${org} in channel '$CHANNEL_NAME' ===================== "
      sleep $DELAY
      echo
    done
}

# signConfigTxAsPeerOrg <org> <update-tx-protobuf>
# Set the peerOrg admin of an org and signing the config update
function signConfigtxAsPeerOrg() {
    ORG=$1
    UPDATE_TX=$2
    setEnvironment $ORG

    set -x
    peer channel signconfigtx -f $UPDATE_TX >&log.txt
    res=$?

    set +x
    cat log.txt
    verifyResult $res "Updating anchor peers for org '"$ORG"' failed"
}

# TODO updateChannelConfiguration
# Upgrade channel configuration
function updateChannelConfiguration() {
   echo "TODO updateChannelConfiguration"
}

# TODO updateAnchorPeerForNewOrg
# Update anchor peer for new organization by pushing a channel configuration update
function updateAnchorPeerForNewOrg() {
    echo "TODO updateAnchorPeerForNewOrg"
}

#############
# NAVIGATION
#############

if [[ $# -ne 1 ]]
then
  echo "Run: channel.sh [create|join|fetch|anchor|joinnewpeer|update|anchorneworg]"
  exit 1
fi

echo $1

if [ "$1" == "create" ]; then
    ## Create channel
    echo "Creating channel..."
    createChannel
    echo "========= Channel creation completed =========== "
elif [ "$1" == "join" ]; then
    ## Join all the peers to the channel
    echo "Having all peers join the channel..."
    joinChannel
    echo "========= Channel join completed =========== "
elif [ "$1" == "fetch"  ]; then
    ## Fetch channel config block
    echo "Fetch the channel configuration block..."
    fetchChannelConfig
    echo "========= Channel configuration fetched =========== "
elif [ "$1" == "anchor"  ]; then
    ## Set anchor peers
    echo "Set anchor peers..."
    updateAnchorPeers
    echo "========= Channel configuration updated with anchor peers =========== "
elif [ "$1" == "update" ]; then
    ## Update the channel configuration to add a new organization
    echo "Updating the channel configuration to add ExportingEntityOrg..."
    updateChannelConfiguration
    echo "========= Channel update completed =========== "
elif [ "$1" == "anchorneworg" ]; then
    ## Set anchor peer for new org
    echo "Set anchor peer for new org..."
    updateAnchorPeerForNewOrg
    echo "========= Channel configuration updated with anchor peer for new org =========== "
else
     echo "Unsupported channel operation: "$1
fi

echo

exit 0





