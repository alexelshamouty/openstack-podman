# openstack-podman
This repository contains ussuri version of OpenStack running in containers in usermode


** Keystone
First you need to spin up a mariadb container or a VM or whatever you like.
Create a DB/User and GRANT the keystone user access to that DB

Once done, configure keystone.conf to use that database in the [database] section ( and do your thing in keystone.conf but this is the minimum you need to do)

Next step would be to bootstrap the DB and create the needed fernet keys and credentials:
```
docker run -it --rm --network host -v $(pwd)/fernet-keys:/etc/keystone/fernet-keys -v $(pwd)/credential-keys:/etc/keystone/credential-keys aelshamouty/keystone-binary /bin/bash /bootstrap.sh
```
Make sure that fernet-keys and credental-keys are world-writeable ON YOUR machine. Or figure something else out :P 

Last step would be to create two containers for admin and public keystone containers:
```
docker create -d --network host -v $(pwd)/fernet-keys:/etc/keystone/fernet-keys -v $(pwd)/credential-keys:/etc/keystone/credential-keys --name keystone-admin aelshamouty/keystone-binary /usr/bin/keystone-wsgi-admin --port 35357
docker create -d --network host -v $(pwd)/fernet-keys:/etc/keystone/fernet-keys -v $(pwd)/credential-keys:/etc/keystone/credential-keys --name keystone-public aelshamouty/keystone-binary /usr/bin/keystone-wsgi-public --port 5000
```
Done? All ok? Ok, you can now generate systemd files for your services ( or reuse the ones in the repo but just change the ID of the containers in them otherwise they won't work )

```
podman generate systemd keystone-public --files
podman generate systemd keystone-admin --files
```

Done? All good? Copy those files to your local systemd path for your own user, every distro has it's own stuff so figure yours out.

Start the services like this:

```
systemctl --user enable container-keystone-public.service
systemctl --user enable container-keystone-admin.service

systemctl --user start container-keystone-public.service
systemctl --user start container-keystone-admin.service

systemctl --user start container-keystone-public.service
systemctl --user start container-keystone-admin.service
```

Source the openrc file and use your openstack cli to query keystone :) 
```
source openrc
openstack endpoint list --debug #Just so you can make sure that all is good 
```
