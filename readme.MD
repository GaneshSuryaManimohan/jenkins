# Jenkins Plugins

* **AnsiColor** --> This plugin interprets ANSI escape sequences in your build output and displays them as colored text in the Jenkins console. 

*  **Pipeline: Stage View** --> a user interface feature that provides a visual, real-time representation of the different stages in a Jenkins Pipeline

*  **Pipeline Utility Steps** --> provides a collection of small, cross-platform utility steps to simplify common tasks like file manipulation, archive handling, and data parsing within your Jenkins Pipeline.

* **Nexus Artifact Uploader** --> designed specifically for uploading build artifacts (like JAR, WAR, or ZIP files) to a Sonatype Nexus repository

* **Jenkins Rebuild Plugin** --> allows users to re-run a completed job, optionally modifying the build parameters before execution.

#### Increasing DiskSpace for Jenkins Agent 

* Sometimes, we see disk space running out for Jenkins Agent
    - Disk space is below threshold of 1.00 GiB. Only 901.96 MiB out of 960.00 MiB left on /home/ec2-user/jenkins-agent.

* Increase the disk at the platform level:
  If this is EC2 (most likely):

  1. Go to EC2 → Volumes
  2. Increase the root EBS volume (example: 20 GB → 50 GB)
  3. Wait until status = optimizing or completed

* lsblk --> You should see the disk larger, but LVM still unchanged.

* pvs  --> Identify the PV

* sudo growpart /dev/nvme0n1 4 --> Growing the partition. 4 is the partition 

* sudo pvresize /dev/nvme0n1p4  --> Resize the Physical Volume

* sudo lvextend -L +20G /dev/RootVG/homeVol --> Extend /home logically

* sudo xfs_growfs /home

* df -h /home