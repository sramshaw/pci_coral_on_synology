# pci_coral_on_synology
mechanism to have PCI Coral TPU available to a VM running on Synology DSM 

## Introduction
This is aimed at using a Coral TPU over PCI or PCIe on a Synology NAS inside a VM running frigate.
I am not aware of a way to reliably install drivers on the host Linux OS, and also it seems that there are benefits in installing Home Assistant and Frigate together on a VM, so the direction for now is to use the TPU from a VM.

Synology 's hypervisor, VMM, does not allow directly for PCI passthrough.
VMM is based on libvirt/qemu/kvm and has a simple functional UI in the DSM portal.
I simply expanded VMM enough to avoid a dedicated machine to run the Coral TPU. While I could have gone with the USB Coral, I find it obnoxiously more expensive at double the price, and want to maybe one day use a double Coral TPU. So I am going with the M.2 B+M keyed Coral.
I do have a mPCI Coral TPU I could play with but I would lose the 10GB ethernet I have on the single PCI slot in my NAS. Maybe later if priorities change.

## Target hardware
This should apply to any Synology NAS with DSM7+ that allows for VM + AMD-Vi or Intel equivalent, and has a PCI slot or M.2 M keyed slot.

My hardware is the DS1621+ NAS , with the V1500B Ryzen processor.
My DSM version: DSM 7.2.1-69057 Update 4

One of the best way to check that the system is able is to run the following as root under ssh:

```virt-host-validate```

### Results on DS1621+:

<!--- first line below needed to start table, also use md Latex expression for green colored PASS -->
|||
|---|---|
|  QEMU: Checking for hardware virtualization                                 | $${\color{green}PASS}$$ |
|  QEMU: Checking if device /dev/kvm exists                                   | $${\color{green}PASS}$$ |
|  QEMU: Checking if device /dev/kvm is accessible                            | $${\color{green}PASS}$$ |
|  QEMU: Checking if device /dev/vhost-net exists                             | $${\color{green}PASS}$$ |
|  QEMU: Checking if device /dev/net/tun exists                               | $${\color{green}PASS}$$ |
|  QEMU: Checking for cgroup 'cpu' controller support                         | $${\color{green}PASS}$$ |
|  (...)                     |  |
|  QEMU: Checking for cgroup 'blkio' controller support                       | $${\color{green}PASS}$$ |
|  QEMU: Checking for device assignment IOMMU support                         | $${\color{green}PASS}$$ |
|  QEMU: Checking if IOMMU is enabled by kernel                               | $${\color{green}PASS}$$ |
|  QEMU: Checking for secure guest support                                    | $${\color{orange}WARN}$$ |

## Approach
In order to modify the NAS 's VM behavior, I used ssh access to the NAS.
From my readings, IOMMU  and vfio-pci driver are required for passthrough to work.
After I created a VM, I saw in the pkg-libvirtd service 's init script running on on the host, that kvm_amd is brought up, so is vfio-pci. This can be observed with ```lsmod |grep "vfio\|kvm\|iommu"```

```
sh-4.4# lsmod | grep "vfio\|kvm\|iommu"
vfio_pci               28971  2
vfio_virqfd             2293  1 vfio_pci
vfio_iommu_type1        8325  1
vfio                   15175  7 vfio_iommu_type1,vfio_pci
kvm_amd                53565  3
kvm                   434147  1 kvm_amd
irqbypass               2808  9 kvm,vfio_pci
```

The PCI passthrough allows to reassign a device from the host (Synology's linux) to a VM.
As a Linux virtualization amateur, I did not know what part of the system to tweak. My exploration evolved into a workable solution for me and I hope many Synology users.

Here is what I learned:
- using qemu monitor would require an exposed monitor in the qemu call creating the VM, which is out of reach within VMM logic
- using virsh to engage libvirt, which turns out to be the best way, means that the device gets hotplugged into the VM.
  - this can be a problem with GPU, which may need to be ready at boot time
  - frankly I would not mind rebooting the VM after hotplug if it is all that's needed.
  - this ended up working for both an ethernet PCI card and a PCI Coral TPU
  - hooks on libvirt are unfortunately not allowing changes to the VM definition
  - running virsh within a hook is a recipe for deadlock
    - as a result running a detached script triggered by a targeted VM's "started" event (via hook) is the best way to go
  - note that the only hook that is observed by libvirt is /etc/libvirt/hook/qemu AFAIK , alternate locations in /usr seemed unused 

Where to put logic to change the VM?
  - files edited/added in /etc/libvirt tend to disappear after reboot, and content is not ready by the time boot scripts are detected and run in /usr/local/etc/rc.d
  - it seems interesting to add the hook setup as part of pkg-libvirtd starting, which prepares /etc/libvirt/hooks/qemu. 
  - the scripts for service pkg-libvirtd start/stop are persisted as is, so a good way in
  - files in /usr/local seem to be persistent, so I use a sub directory "libvirt" to hold the files needed


## Status

I first experimented on my 10G ethernet, see the script attaching_Intel82599ES.sh , which aims a VM 'detector'. At this point qemu does not look for it anymore.
Indeed I have now successfully wired the M.2 B+M key Coral TPU to the "frigate_VM" VM.

Coral TPU info: vendor=0x1ac1 device=0x089a.

Installation:
- if not done yet, install package DSM -> Package Center -> Git Server
- in ssh on NAS host , git clone this repo
  - adapt VM_NAME, VENDOR and PRODUCT in attach_\*.sh to hot plug the PCI device(s) you need, here Coral TPU
  - adapt TARGET_VM in qemu
- deploy to the actual /usr/local/libvirt folder using the script
  ``` sudo ./deploy.sh```
- (done once) modify  /var/packages/Virtualization/conf/systemd/insert_libvirtd_ko.sh so that it calls /usr/local/libvirt/my_hook_setup.sh

Results of the hack:
- when the NAS boots, it brings up the VM which then receives the hotplugged M.2 Coral TPU.
- the TPU is functional as observed when frigate is installed within the VM, be it on a container.
- the PCI passthrough works the first time the VM starts !
  - observe the effect on both the host (look for use of driver vfio-pci) and the VM (driver apex) by using the command ```lspci -k```
- good enough for now as it will be used for a VM that runs all the time

## References 
useful readings:
- https://www.ibm.com/docs/en/linux-on-systems?topic=through-pci especially step 2.b
- https://libvirt.org/hooks.html for a description of the calls to the hook
- https://serverfault.com/questions/765232/virsh-qemu-kvm-editing-xml-has-no-effect the hooks cannot be used to change the VM definition
- https://prefetch.net/articles/linuxpci.html to get a sense of the PCI address scheme, and the vendor product numbers.
- https://www.makerfabs.com/dual-edge-tpu-adapter-m2-2280-b-m-key.html , M.2 B+M key adapter for M.2 A+E key dual TPU Coral 
