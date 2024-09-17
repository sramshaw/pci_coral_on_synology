#!/bin/bash
echo "Custom Script running as $(whoami)" >> /var/log/custom_script.log
mkdir -p /etc/libvirt/hooks/
cp /usr/local/libvirt/qemu /etc/libvirt/hooks/qemu
echo "libvirt hooks are setup\n Custom script for libvirt ended" >> /var/log/custom_script.log
