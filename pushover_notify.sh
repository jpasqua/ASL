#!/bin/bash
#
# This script is used to send a Pushover (https://pushover.net/) notification
# when your AllStarLink node (https://allstarlink.org/) connects or disconnects
# from another node.
#
# usage: pushover_notify.sh [CONNECT|DISCONNECT] MyNodeNumber TheirNodeNumber
#
# Prerequisites:
# 1. You'll need to create a free Pushover account and create an application
#    key. You will use your app key and user token below.
# 2. Create a file named pushover.ini with your user key app token.
#    Example content of pushover.ini:
#        APP_TOKEN="MY_APP_TOKEN_HERE"
#        USER_KEY="MY_USER_KEY_HERE"
# 3. This script relies on jq(JSON processor). Be sure it is installed:
#        sudo apt install jq
#
# Installing the files:
# 1. Place both this script and the pushover.ini file you created into
#    /etc/asterisk/scripts.
# 2. Give them the correct ownership and permissions:
#        sudo chown root:asterisk /etc/asterisk/scripts/pushover_notify.sh
#        sudo chmod 750 /etc/asterisk/scripts/pushover_notify.sh
#        sudo chown root:asterisk /etc/asterisk/scripts/pushover.ini
#        sudo chmod 640 /etc/asterisk/scripts/pushover.ini
#
# Preparing your ASL3 installation
# 1. You'll need to update your /etc/asterisk/rpt.conf file with the following
#    lines. Look for the references to connpgm & discpgm which are commented
#    out, and add these lines there:
#        connpgm=/etc/asterisk/scripts/pushover_notify.sh CONNECT
#        discpgm=/etc/asterisk/scripts/pushover_notify.sh DISCONNECT
# 2. Restart asterisk:
#        sudo systemctl restart asterisk
#
# Testing
# 1. You can test the script manually with the commands:
#        sudo /etc/asterisk/scripts/pushover_notify.sh CONNECTED 65237 60216
#        sudo /etc/asterisk/scripts/pushover_notify.sh DISCONNECTED 65237 60216
#    The node numbers aren't important for this test. They are just examples.
# 2. Try it live. After restarting asterisk, connect to a node, then disconnect
#    You should get two Pushover notifications - one for each action.
#

CONNECT_TYPE="$1"
MY_NODE="$2"
THEIR_NODE="$3"

# Read credentials from Pushover.ini 
CRED_FILE="/etc/asterisk/scripts/pushover.ini"

if [ -f "$CRED_FILE" ]; then
    source "$CRED_FILE"
else
    echo "Error: Credentials file $CRED_FILE not found."
    exit 1
fi

# Sanity check that variables loaded
if [ -z "$APP_TOKEN" ] || [ -z "$USER_KEY" ]; then
    echo "Error: APP_TOKEN or USER_KEY not set in $CRED_FILE"
    exit 1
fi

# Query the AllStarLink stats API for information about a specific node.
# Extract the node's callsign (User_ID) and location from the JSON response.
# The callsign & location are separated by a pipe symbol ('|') for easy parsing.
# Split the result into two separate variables: 'callsign' & 'callsignLocation'
result=$(
  curl -sX GET "https://stats.allstarlink.org/api/stats/${THEIR_NODE}" |
    jq -r '.node.server.User_ID + "|" + .node.server.Location'
)
callsign=$(echo "$result" | cut -d '|' -f 1)
callsignLocation=$(echo "$result" | cut -d '|' -f 2)

# Use  https://call3.n0agi.com/ API to look up the name for the given callsign.
# The callsign is appended to the URL followed by /json/ to get JSON output.
# Extract the 'First' and 'Last' fields and concatenate them with a space.
callsignName=$(
  curl -sX GET "https://call3.n0agi.com/${callsign}/json/" |
    jq -r '.First + " " + .Last'
)

# Create the message that we're going to send via Pushover:
if [ "$CONNECT_TYPE" == "CONNECTED" ]; then
    MESSAGE="Node ${THEIR_NODE}: ${callsign} [${callsignName} from ${callsignLocation}] is connected to your AllStar node ${MY_NODE}."
else
    MESSAGE="Node ${THEIR_NODE}: ${callsign} [${callsignName} from ${callsignLocation}] is disconnected from your AllStar node ${MY_NODE}."
fi


# Finally, let's send the notification
curl -s \
    -F "token=${APP_TOKEN}" \
    -F "user=${USER_KEY}" \
    -F "message=${MESSAGE}" \
    https://api.pushover.net/1/messages.json
