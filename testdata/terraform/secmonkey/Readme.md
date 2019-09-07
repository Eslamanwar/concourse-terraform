# Prerequisite
- A Route53 zone ID
- An EC2 SSH key pair to use to login into the Security Monkey's instances (even though SSH is disabled. Session Manager is used instead)
- An AMI with Security Monkey already installed (this can be achieved by the packer template in the packer-ansible directory)

Building the AMI

- type bash build-ami.sh inside the packer-ansible directory after chmod +x build-ami.sh

# How to run 
- cd deploy
- $ export AWS_PROFILE=secmonkey	// where AWS_PROFILE is the awscli profile with the right credentials
- $ make

# Design
![alt text](https://github.com/Eslamanwar/concourse-terraform/blob/master/testdata/terraform/secmonkey/secmonkey.jpg?raw=true)

