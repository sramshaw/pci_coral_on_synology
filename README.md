# pci_coral_on_synology
mechanism to have PCI Coral TPU available to a VM running on Synology DSM 

This is based on an attempt to use Coral TPM on PCI or PCIe.
Synology 's hypervisor, VMM, does not allow directly for PCI passthrough.
VMM is based on libvirt/qemu/kvm and has a simple functional UI in the DSM portal.

In the case of those who will have an AMD processor like the V1500B I have in my DS1621+ NAS, libvirt in fact sets up what is needed to set the passthrough.

Current version of DSM I am working on: DSM 7.2.1-69057 Update 4

From my readings, IOMMU  and vfio-pci driver are required for passthrough to work.
After I created a VM, I saw in the pkg-libvirt service 's init script running on on the host, that kvm_amd is brought up, so is vfio-pci. This can be observed with ```lsmod |grep "vfio\|kvm\|iommu"```

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
There are many ways one could think of changing the device list on the VM. My exploration considered:
- using qemu monitor, however it would require an exposed monitor in the qemu call creating the VM, which is out of reach within VMM logic
- using virsh to engage libvirt, which turns out to be the best way, but means that the device gets hotplugged into the VM.
  - this can be a problem with GPU, which may need to be ready at boot time
  - frankly I would not mind rebooting the VM if it is all that's needed.
  - but in the case of an ethernet PCI card, this was not necessary
  - I hope that it will be the same for the Coral TPU
- when to add the PCI device to the VM?
  - at VM boot, it would require intercepting the VMM logic
  - hooks on libvirt are unfortunately not allowing changes to the VM definition
  - running virsh within a hook is a recipe for deadlock
  - as a result it is likely that running a detached script triggered by a 'started' event intercepted by a hook is the best way to go
- where to put logic to setup the hook
  - note that the only hook that is observed is /etc/libvirt/hook/qemu AFAIK , alternate location in /usr seemed unused 
  - files in /etc/libvirt tend to disappear after reboot
  - files in /usr/local seem to be persistant, so I will use a subdir libvirt to hold the files needed
  - the scripts for service pkg-libvirtd can be edited to setup the hook 

As I am waiting for the M.2 B+M key Coral TPU to arrive by mail, I am instead attaching my 10G ethernet card to the VM as a training exercise.


useful readings:
- https://www.ibm.com/docs/en/linux-on-systems?topic=through-pci especially step 2.b
- https://libvirt.org/hooks.html for a description of the calls to the hook
- https://prefetch.net/articles/linuxpci.html to get a sense of the PCI address scheme, and the vendor product numbers.
