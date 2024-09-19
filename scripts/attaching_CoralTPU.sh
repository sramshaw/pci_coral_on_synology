#!/bin/bash
 
# this is for the Coral TPU
# https://coral.ai/docs/m2/get-started/#2a-on-linux
# https://www.reddit.com/r/VFIO/comments/l5awg0/using_google_coral_mpcie_tpu_in_qemu_vm/?rdt=33296

VENDOR="1ac1"
PRODUCT="089a"
VM_NAME="detector"
/usr/local/libvirt/attach_pci_to_vm.sh $VENDOR $PRODUCT $VM_NAME  #disable_idle_d3=1
