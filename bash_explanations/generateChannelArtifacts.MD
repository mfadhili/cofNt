# Comments
The `configtxgen tool is used to create four artifacts: orderer **bootstrap
block**, fabric **channel configuration transaction**, and an **anchor
peer transaction** - one for each Peer Org.

The orderer block is the genesis block for the ordering service, and the
channel transaction file is broadcast to the orderer at channel creation
time.  The anchor peer transactions, as the name might suggest, specify each
Org's anchor peer on this channel.

Configtxgen consumes a file - ``configtx.yaml`` - that contains the definitions
for the sample network. This file also contains two additional specifications that are worth
noting.  Firstly, we specify the anchor peers for each Peer Org
(``peer0.exporterorg.trade.com`` & ``peer0.importerorg.trade.com``).  Secondly, we point to
the location of the MSP directory for each member, in turn allowing us to store the
root certificates for each Org in the orderer genesis block.  This is a critical
concept. Now any network entity communicating with the ordering service can have
its digital signature verified.

This function will generate the crypto material and our four configuration
artifacts, and subsequently output these files into the ``channel-artifacts/<channel_name>``
folder.

If you receive the following warning, it can be safely ignored:

`[bccsp] GetDefault -> WARN 001 Before using BCCSP, please call InitFactories(). Falling back to bootBCCSP.`

You can ignore the logs regarding intermediate certs, we are not using them in
this crypto implementation.

Generate orderer genesis block, channel configuration transaction and
anchor peer update transactions

# Code explanation
The function `generateChannelArtifacts()` creates the genesis block and channel configuration transaction for a Hyperledger Fabric network. It takes the following parameters:

* `CHANNEL_NAME`: The name of the channel to be created.
* `DEV_MODE`: A boolean flag that indicates whether to use the development mode configuration.
* `NUM_ORGS_IN_CHANNEL`: The number of organizations that will be participating in the channel.
* `ORDERER_MODE`: The mode of the orderer, either "dev" or "prod".
* `FABRIC_CFG_PATH`: The path to the Fabric configuration directory.

The function first checks to see if the `configtxgen` tool is available. If it is not, the function exits.

Next, the function creates a directory for the channel artifacts. The name of the directory is `channel-artifacts/${CHANNEL_NAME}`.

The function then determines the profile to use for generating the genesis block and channel configuration transaction. The profile depends on the development mode flag, the number of organizations in the channel, and the orderer mode.

The function then generates the genesis block for the system channel. The system channel is a special channel that is used to bootstrap the network. The genesis block contains the configuration for the system channel, as well as the identities of the organizations that will be participating in the network.

The function then generates the channel configuration transaction for the specified channel. The channel configuration transaction contains the configuration for the channel, such as the channel name, the ordering service, and the organizations that will be participating in the channel.

If the development mode flag is not set, the function then generates the anchor peer updates for each organization that will be participating in the channel. The anchor peer updates are used to tell the orderers which peers are authorized to join the channel.

The function finally outputs the generated artifacts to the `channel-artifacts` directory.

The `generateChannelArtifacts()` function is a useful tool for creating the genesis block and channel configuration transaction for a Hyperledger Fabric network. It can be used to quickly and easily get a network up and running.