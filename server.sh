#!/bin/bash
set -e

# Add Jenkins repository
cat <<EOF > /etc/yum.repos.d/jenkins.repo
[jenkins]
name=Jenkins-stable
enabled=1
type=rpm-md
baseurl=https://pkg.jenkins.io/rpm-stable
gpgkey=https://pkg.jenkins.io/rpm-stable/repodata/repomd.xml.key
gpgcheck=1
repo_gpgcheck=1
EOF

# Install Java 21 and fontconfig
yum install -y fontconfig java-21-openjdk

# Install Jenkins
yum install -y jenkins

# Reload systemd and start Jenkins
systemctl daemon-reexec
systemctl enable jenkins
systemctl start jenkins
