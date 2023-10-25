# README #

This repository is for Managing a AWS EKS service image platform. The goal being that you will be able to provide a directory of a self contained docker app and this repo will:
 - build the docker image
 - Create an AWS ECR with lifecycle permissions
 - push the result image to an AWS ECR
 - cleanup local disk space after image is pushed
 - Create EKS cluster using the AWS ECR as the docker image source for the cluster
 - create admin server to manage cluster upgrades and deployments

### Prerequisites for the playbook ###
A linux environment like ubuntu, debian or redhat with admin access
You will need enough disk space in this environment to store your docker image files which can be quite large, in some cases ~2GB +
python3.9.5 or later
  Ex. `apt get install python3.9`
  PATH for /usr/bin/python3 assumes /usr/bin/python 
pip3 installed with the above python
  Ex. `curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3.9 get-pip.py`
virtualenv pip package
  Ex. `sudo pip3 install virtualenv`
AWS admin permissions and credentials setup in the default location

Make copy of the template file in directory manage_eks_services/template.yml and change to the relevant values needed for your configuration.  The template file contains definitions of needed vars and thier use

Add your complete docker file directory with a valid Dockerfile in directory /docker_apps.  Please use dashes in directory name NOT underscores for consistency.

Any run of the script with all needed args will display help message like:
    `usage: ./manage_eks_server [-h] build_images -m manage_eks_service
    ./manage_eks_server: error: the following arguments are required: -m/--manage_eks_service`

TODOs
Only working command is:
  `usage: ./manage_eks_server [-h] build_images -m manage_eks_service
    ./manage_eks_server: error: the following arguments are required: -m/--manage_eks_service`

  tagging AWS ECR repoistories

