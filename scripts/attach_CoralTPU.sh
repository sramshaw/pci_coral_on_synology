#!/bin/bash
 
# this is for the Intel 82599ES 10Gbps SFI/SFP+
# https://linux-hardware.org/?id=pci:8086-10fb-8086-000c

VENDOR="1ac1"
PRODUCT="089a"
VM_NAME="detector"
/usr/local/libvirt/attach_pci_to_vm.sh $VENDOR $PRODUCT $VM_NAME
