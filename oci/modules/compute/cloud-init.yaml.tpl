#cloud-config
runcmd:
  - mkfs.ext4 ${device_name}
  - mkdir -p ${mount_point}
  - mount ${device_name} ${mount_point}
  - echo "${device_name} ${mount_point} ext4 defaults,nofail 0 2" >> /etc/fstab