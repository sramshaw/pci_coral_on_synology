    #!/bin/bash
    v1="$1"  #ex: 2 for /volume2
    l1="$2"  #ex: 1 for 1st SCSI disk
    v2="$3"  #ex: 3 for /volume3
    l2="$4"  #ex: 2 for 2nd SCSI disk
    # real basepath
    #basepath="/volume"
    # test basepath
    basepath="/volume1/homes/sylvain_admin/NAS/pci_coral_on_synology/swap_disks/originals/vol"
    vol1="/volume$v1/@iSCSI/LUN"
    vol2="/volume$v2/@iSCSI/LUN"
    guid1=`cat $vol1/iscsi_lun_acl.conf |grep lun_uuid | sed "${l1}q;d" | sed 's/lun_uuid=//'`
    guid2=`cat $vol2/iscsi_lun_acl.conf |grep lun_uuid | sed "${l2}q;d" | sed 's/lun_uuid=//'`
    rename $vol1/VDISK_BLUN/$guid1  $vol1/VDISK_BLUN/$guid2
    rename $vol2/VDISK_BLUN/$guid2  $vol2/VDISK_BLUN/$guid1
    find -name "$vol1/*.conf" -exec sed "s/${guid1}/${guid2}/" {} \;
    find -name "$vol2/*.conf" -exec sed "s/${guid2}/${guid1}/" {} \;
