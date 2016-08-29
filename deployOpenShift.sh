#!/bin/bash

echo $(date) " - Starting Script"

set -e

SUDOUSER=$1
PASSWORD=$2
PRIVATEKEY=$3
MASTER=$4
MASTERPUBLICIPHOSTNAME=$5
MASTERPUBLICIPADDRESS=$6
NODEPREFIX=$7
NODECOUNT=$8
ROUTING=$9

DOMAIN=$( awk 'NR==2' /etc/resolv.conf | awk '{ print $2 }' )

# Generate private keys for use by Ansible
echo $(date) " - Generating Private keys for use by Ansible for OpenShift Installation"

echo "Generating keys"

runuser -l $SUDOUSER -c "echo \"$PRIVATEKEY\" > ~/.ssh/id_rsa"
runuser -l $SUDOUSER -c "chmod 600 ~/.ssh/id_rsa*"

echo "Configuring SSH ControlPath to use shorter path name"

sed -i -e "s/^# control_path = %(directory)s\/%%h-%%r/control_path = %(directory)s\/%%h-%%r/" /etc/ansible/ansible.cfg
sed -i -e "s/^#host_key_checking = False/host_key_checking = False/" /etc/ansible/ansible.cfg
sed -i -e "s/^#pty=False/pty=False/" /etc/ansible/ansible.cfg

# Create Ansible Hosts File
echo $(date) " - Create Ansible Hosts file"

cat > /etc/ansible/hosts <<EOF
# Create an OSEv3 group that contains the masters and nodes groups
[OSEv3:children]
masters
nodes

# Set variables common for all OSEv3 hosts
[OSEv3:vars]
ansible_ssh_user=$SUDOUSER
#ansible_sudo=true
ansible_become=yes
deployment_type=openshift-enterprise
docker_udev_workaround=True
# containerized=true
openshift_use_dnsmasq=no
openshift_master_default_subdomain=$ROUTING

openshift_master_cluster_public_hostname=$MASTERPUBLICIPHOSTNAME
openshift_master_cluster_public_vip=$MASTERPUBLICIPADDRESS

# Enable HTPasswdPasswordIdentityProvider
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/htpasswd'}]

# host group for masters
[masters]
$MASTER.$DOMAIN

# host group for nodes
[nodes]
$MASTER.$DOMAIN openshift_node_labels="{'region': 'infra', 'zone': 'default'}" openshift_schedulable=true
EOF

for (( c=0; c<$NODECOUNT; c++ ))
do
  echo "$NODEPREFIX-$c.$DOMAIN" >> /etc/ansible/hosts
done


# Initiating installation of OpenShift Enterprise using Ansible Playbook
echo $(date) " - Installing OpenShift Enterprise via Ansible Playbook"

runuser -l $SUDOUSER -c "ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/byo/config.yml"

echo $(date) " - Modifying sudoers"

sed -i -e "s/Defaults    requiretty/# Defaults    requiretty/" /etc/sudoers
sed -i -e '/Defaults    env_keep += "LC_TIME LC_ALL LANGUAGE LINGUAS _XKB_CHARSET XAUTHORITY"/aDefaults    env_keep += "PATH"' /etc/sudoers

echo $(date) "- Deploying Registry"

# runuser -l $SUDOUSER -c "sudo oadm registry --config=/etc/origin/master/admin.kubeconfig --credentials=/etc/origin/master/openshift-registry.kubeconfig"

# runuser -l $SUDOUSER -c "sudo oadm registry --config=/etc/origin/master/admin.kubeconfig --service-account=registry --images='registry.access.redhat.com/openshift3/ose-${component}:${version}'"

# Deploying Router

echo $(date) "- Deploying Router"

runuser -l $SUDOUSER -c "sudo oadm router osrouter --replicas=$NODECOUNT --credentials=/etc/origin/master/openshift-router.kubeconfig --service-account=router"

echo $(date) "- Re-enabling requiretty"

sed -i -e "s/# Defaults    requiretty/Defaults    requiretty/" /etc/sudoers

# Adding user to OpenShift authentication file
echo $(date) "- Adding OpenShift user"

mkdir -p /etc/origin/master
htpasswd -cb /etc/origin/master/htpasswd $SUDOUSER $PASSWORD

echo $(date) " - Script complete"
