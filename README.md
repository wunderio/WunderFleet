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

### Ping all machines

This pings all machines in the inventory
```
$ ./provision.sh -i environments/upcloud playbooks/ping.yml
```

### Install updates for yum packages like nginx, mariadb and openssl

This updates many installed packages and restarts the related services
```
$ ./provision.sh -i environments/upcloud playbooks/update-packages.yml
```

**Note:** You should add more services into the included list:
```yml
upgradeable_packages:
  - package: nginx
    service: nginx
  - package: MariaDB-server
    service: mysql
  - package: openssl 
    service: sshd
```

### Update UpCloud firewall rules

This updates the default upcloud firewall rules for all machines:
```
$ ./provision.sh -i environments/upcloud playbooks/update-firewalls.yml
```

**Notes:**
* This doesn't alter the web ports in any way, You should enable them separately inside the project configs.
* This doesn't remove any custom firewall rules you have added into the the project configs.
* The list of all allowed ssh ports come from private repo: [WunderSecrets](https://github.com/wunderio/wundersecrets).
* The default security rules come from [WunderMachina upcloud-firewall role](https://github.com/wunderio/WunderMachina/blob/master/playbook/roles/upcloud-firewall/defaults/main.yml) from variable `upcloud_default_firewall_rules`.

## Notes
* `root` user is used to access the servers
* Initial inventory loading takes few minutes so just wait for a moment.

## License
MIT