# WunderFleet

This project can be used to update all of our UpCloud servers simultaneously.

It uses UpCloud dynamic inventory from [upcloud-ansible](https://github.com/UpCloudLtd/upcloud-ansible/blob/master/inventory/upcloud.py).

## Setup

The `provision.sh` doesn't act like the one in WunderTools. This just makes sure that that virtualenv is used and WunderSecrets and WunderMachina is installed.

All flags are then passed into `ansible-playbook` command.

### UpCloud specific settings

You need to provide your UpCloud credentials as environmental variables:

```
export UPCLOUD_API_USER='upcloud-username' UPCLOUD_API_PASSWD='password-for-upcloud-user'
```

## Usage examples

## Ping all machines

This pings all machines in the inventory
```
$ ./provision.sh -i environments/upcloud playbooks/ping.yml
```

## Notes
* `root` user is used to access the servers
* Initial inventory loading takes few minutes so just wait for a moment.

## License
MIT