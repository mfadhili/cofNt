The function `generateConfig` creates the necessary configuration files for a Hyperledger Fabric network. It takes two arguments:

* `DEV_MODE`: A boolean value that indicates whether the network is being deployed in development mode.
* `ORDERER_MODE`: A string value that specifies the mode of the ordering service. The possible values are "solo", "kafka", and "raft".

The function first checks if the `devmode` folder exists. If it does, the function changes to that directory and sets the `FABRIC_CFG_PATH` environment variable to the current working directory. This ensures that the Fabric binaries can find the configuration files.

Next, the function calls the `generateCerts` function to create the credentials for the network nodes. If the `ORDERER_MODE` is "prod", the function also calls the `generateCertsForRaftOrderingNodes` function to create the credentials for the raft ordering nodes.

Finally, the function calls the `generateChannelArtifacts` function to create the channel artifacts. These artifacts are used to join the nodes to the channels in the network.

The function returns the value of the `PUSHED` variable. This variable is set to `true` if the function changed to the `devmode` folder and then changed back. This is useful for scripts that need to preserve the current working directory.

Here is an example of how the `generateConfig` function can be used:

```shell
generateConfig DEV_MODE=true ORDERER_MODE="raft"
```

This will create the configuration files for a Hyperledger Fabric network in development mode with a raft ordering service. 

# devmode
The conditional statement `if [ "$DEV_MODE" = true -a -d "devmode" ]` checks two conditions:

1. The environment variable `DEV_MODE` is set to the value `true`.
2. The directory `devmode` exists.

If both of these conditions are met, the statement executes the commands that are indented below it.

The `DEV_MODE` environment variable is typically set by the user when they are running the script. The `devmode` directory is where the configuration files for the Hyperledger Fabric network are stored.

If the `DEV_MODE` environment variable is not set or the `devmode` directory does not exist, the statement does not execute any commands.

Here is an explanation of each part of the conditional statement:

* `[ "$DEV_MODE" = true ]`: This checks if the value of the environment variable `DEV_MODE` is equal to the string `true`.
* `-a`: This is the logical AND operator. It means that both conditions must be met for the statement to execute.
* `-d "devmode"`: This checks if the directory `devmode` exists.

I hope this explanation is helpful! Let me know if you have any other questions.

# res
The variable `$res` is set to the return code of the last command that was executed. In the case of the `generateCerts()` function, the last command that is executed is the `cryptogen generate` command. The return code of this command is 0 if the command was successful, and a non-zero value if the command failed.

So, the value of `$res` will be 0 if the `generateCerts()` function was successful, and a non-zero value if the function failed.

In the example you provided, the `cryptogen generate` command was successful, so the value of `$res` will be 0.

You can use the value of `$res` to check if the `generateCerts()` function was successful. For example, you could use the following code:

```
if [ $res -ne 0 ]; then
  echo "Failed to generate certificates..."
  exit 1
fi
```

This code will check if the value of `$res` is not equal to 0. If it is not, the code will print an error message and exit.

I hope this helps! Let me know if you have any other questions.