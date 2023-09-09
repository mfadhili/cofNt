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
    echo "Verify if channel name is given"
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