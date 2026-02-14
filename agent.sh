#!/bin/bash
set -e
yum install -y fontconfig java-21-openjdk
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
yum -y install terraform
dnf module disable nodejs -y
dnf module enable nodejs:20 -y
dnf install nodejs -y
dnf install zip unzip -y
cat <<EOT>> /tmp/resize.sh
#!/bin/bash
sudo growpart /dev/nvme0n1 4
sudo pvresize /dev/nvme0n1p4
sudo lvextend -L +8G /dev/RootVG/homeVol
sudo xfs_growfs /home

EOT