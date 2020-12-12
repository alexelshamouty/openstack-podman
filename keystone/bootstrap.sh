#!/bin/bash

echo "Bootstraping keystone db"
keystone-manage db_sync
echo "Creating fernet tokens and credentials"
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
echo "Bootstraping keystone"
keystone-manage bootstrap --bootstrap-password admin \
    --bootstrap-admin-url http://localhost:35357/v3/ \
    --bootstrap-internal-url http://localhost:5000/v3/ \
    --bootstrap-public-url http://localhost:5000/v3/ \
    --bootstrap-region-id dev

/bin/bash 
