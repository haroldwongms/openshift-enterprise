#!/bin/bash

USER=$1
PASSWORD=$2
POOL_ID=$3

# Register Host with Cloud Access Subscription

subscription-manager register --username=$USER --password=$PASSWORD
subscription-manager attach --pool=$POOL_ID

# Disable all repositories and enable only the required ones

subscription-manager repos --disable="*"

subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-ose-3.2-rpms"

# Install base packages and update system to latest packages

yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion
yum -y update

# Install Docker 1.9.1 

yum -y install docker-1.9.1
sed -i -e "s#^OPTIONS='--selinux-enabled'#OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0/16'#" /etc/sysconfig/docker

# Create thin pool logical volume for Docker

echo "DEVS=/dev/sdc" >> /etc/sysconfig/docker-storage-setup
echo "VG=docker-vg" >> /etc/sysconfig/docker-storage-setup
docker-storage-setup

# Enable and start Docker services

systemctl enable docker
systemctl start docker

