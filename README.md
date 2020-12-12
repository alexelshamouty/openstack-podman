# openstack-podman
This repository contains ussuri version of OpenStack running in containers in usermode


** Keystone
First you need to spin up a mariadb container or a VM or whatever you like.
Create a DB/User and GRANT the keystone user access to that DB

Once done, configure keystone.conf to use that database in the [database] section ( and do your thing in keystone.conf but this is the minimum you need to do)

Then you need to start a new rabbitmq container ( you don't actually need to do that for keystone but it would be a good idea to start doing this now anyway )

```
docker create --name rabbitmq-server --network host kolla/centos-binary-rabbitmq:ussuri rabbitmq-server
podman generate systemd rabbitmq-server > container-rabbitmq-server.service
# copy your container-rabbitmq-server.service to your systemd user directory, enable it and start it then execute the following
 docker exec -it rabbitmq-server rabbitmqctl add_user cinder cinder
 docker exec -it rabbitmq-server rabbitmqctl add_user keystone keystone
 docker exec -it rabbitmq-server rabbitmqctl add_user nova nova
 docker exec -it rabbitmq-server rabbitmqctl add_user glance glance
 docker exec -it rabbitmq-server rabbitmqctl add_user neutron neutron

```

Configure your keystone.config with something like that:
```
rabbit://keystone:keystone@127.0.0.1:15672//
```

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


# Glance

You have to have mariadb docker started and running by now, change the name mariadb below to the same name of your container and run those commands

```
 docker exec -it mariadb mysql -u root -p -Nse 'create database glance;'
 docker exec -it mariadb mysql -u root -p -Nse "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'glance';"
```


Now we need a user for glance it self and a place where this user has an admin role on, this is typically the 'service' project.
This is basically a keystone project, we will be using this project accross all services so it makes sense that we call it service;

This will create a user
```
 openstack user create --domain default --password glance glance
```
This will create a project called service
```
openstack project create service
```

This will add the user glance as an admin to the service project
```
openstack role add --project service --user glance admin
```

Now we will add an image service entity to OpenStack:

```
openstack service create --name glance image
```

And now we wil use that service entity to add endpoints to THAT service, you need 3 endpoints, admin for admin, public and internal:
Those endpoints provides differen APIs(usually) or middleswares for different purposes.


```
openstack endpoint create --region dev image public http://localhost:9292
openstack endpoint create --region dev image public http://localhost:9292
openstack endpoint create --region dev image public http://localhost:9292
```

Now you can build your docker image like before with keystone.

Once you are done with that, use that image and bootstrap your glance-api

```
docker run -it --rm --network host aelshamouty/glance-binary glance-manage db_sync
```

Now you can go ahead and create a container for your glance-api
```
docker create --name glance-api --network host aelshamouty/glance-binary:latest /usr/bin/glance-api --config-file /etc/glance/glance-api.conf
podman generate systemd glance-api > container-glance-api.service
```

Move the service to your local user systemd, enable, start.


Now try your image service:

```
openstack image list --debug
```
