# Allstar Related Utilities and Files

## Pushover Notification Support for ASL3

The `pushover_notify.sh` script is used to send a [Pushover](https://pushover.net/) notification when your [AllStarLink](https://allstarlink.org/) node has a new connection or when a connection drops. This can happen if another node connects/disconnects from your node ***or*** you connect/disconnect from another node.

This script has been tested with ASL3 on Raspberry Pi. It is invoked as follows:

```
usage: pushover_notify.sh [CONNECT|DISCONNECT] MyNodeNumber TheirNodeNumber
```

**For a script with much richer and more detailed messages**, check out [this script](https://github.com/hamassassin/AmateurRadio/tree/main/AllStarLink/Notifications) by [N1SK](https://github.com/hamassassin). It provides lots of good info and links in the notifications. Since I mostly view notifications on my watch, I opted for shorter messages.

### Prerequisites:

1. You'll need to create a free [Pushover](https://pushover.net/) account, and
   you'll need to create an application key. You will use your app key and user
   token below.
   
   **NOTE** that as 2025-06-25 there is a one-time $5 charge per platform to
   receive pushover notifications. There is no charge to send up to
   10,000 notifications/month.
2. Create a file named `pushover.ini` with your user key app token.
   Example content of `pushover.ini`:
   
   ```
       APP_TOKEN="MY_APP_TOKEN_HERE"
       USER_KEY="MY_USER_KEY_HERE"
   ```
3. This script relies on `jq` (JSON processor). Be sure it is installed:
   ```
       sudo apt install jq
   ```
   
### Installing the files:
1. Place `pushover_notify.sh` and `pushover.ini` (the file you created earlier) into
   `/etc/asterisk/scripts`
2. Give them the correct ownership and permissions:

   ```
       sudo chown root:asterisk /etc/asterisk/scripts/pushover_notify.sh
       sudo chmod 750 /etc/asterisk/scripts/pushover_notify.sh
       sudo chown root:asterisk /etc/asterisk/scripts/pushover.ini
       sudo chmod 640 /etc/asterisk/scripts/pushover.ini
   ```
   
### Preparing your ASL3 installation
1. You'll need to update your `/etc/asterisk/rpt.conf` file with the following
   lines. Look for the references to `connpgm` & `discpgm` which are commented
   out, and add these lines there:
   
   ```
       connpgm=/etc/asterisk/scripts/pushover_notify.sh CONNECT
       discpgm=/etc/asterisk/scripts/pushover_notify.sh DISCONNECT
   ```
   
2. Restart asterisk:
   
   ```
       sudo systemctl restart asterisk
   ```

### Testing
1. You can test the script manually with the commands:

   ```
       sudo /etc/asterisk/scripts/pushover_notify.sh CONNECTED 65237 60216
       sudo /etc/asterisk/scripts/pushover_notify.sh DISCONNECTED 65237 60216
   ```
   The node numbers aren't important for this test. They are just examples.
2. Try it live. After restarting asterisk, connect to a node, then disconnect.
   You should get two Pushover notifications - one for each action.
