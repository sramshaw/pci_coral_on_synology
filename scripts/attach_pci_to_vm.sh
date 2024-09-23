#!/bin/bash
set -x  # Enable debug mode
exec >> /var/log/virsh_attach_results.log 2>&1

VENDOR="$1"
PRODUCT="$2"
VM_NAME="$3"
EXTRA_MODEPROB_PARAMS="$4"

VM_ID=`virsh list --title | tail -n +3 | grep $VM_NAME | awk '{print $1}'`
ADDRESSES=($(lspci |grep $VENDOR:$PRODUCT | awk '{print $1}'))
modprobe -r vfio_pci
for ADDRESS in "${ADDRESSES[@]}"; do  echo "0000:$ADDRESS" > /sys/bus/pci/devices/0000:$ADDRESS/driver/unbind ; done
modprobe vfio_pci ids=$VENDOR:$PRODUCT $EXTRA_MODEPROB_PARAMS
echo $VENDOR $PRODUCT > /sys/bus/pci/drivers/vfio-pci/new_id
for ADDRESS in "${ADDRESSES[@]}"
do
  DOMAIN=0x0000
  FUNC=`echo $ADDRESS | awk -F[.:] '{print $3}' | echo 0x$(</dev/stdin)`
  SLOT=`echo $ADDRESS | awk -F[.:] '{print $2}' | echo 0x$(</dev/stdin)`
  BUS=` echo $ADDRESS | awk -F[.:] '{print $1}' | echo 0x$(</dev/stdin)`
  sed -e "s/\[DOMAIN\]/$DOMAIN/"  -e "s/\[BUS\]/$BUS/" -e "s/\[SLOT\]/$SLOT/" -e "s/\[FUNC\]/$FUNC/" /usr/local/libvirt/vm_template.xml > /usr/local/libvirt/$ADDRESS.xml
  virsh attach-device $VM_ID /usr/local/libvirt/$ADDRESS.xml --current
  cat /usr/local/libvirt/$ADDRESS.xml
done
echo "----- results ------"  >> /var/log/virsh_attach_results.log
virsh qemu-monitor-command $VM_ID --hmp info pci >> /var/log/virsh_attach_results.log
