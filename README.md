# README #

This repository is for Managing a AWS EKS service image platform. The goal being that you will be able to provide a directory of a self contained docker app and this repo will:
 - build the docker image
 - create an AWS ECR with lifecycle permissions
 - push the result image to an AWS ECR
 - cleanup local disk space after image is pushed
 - Create EKS cluster using the AWS ECR as the docker image source for the cluster
 - create bastion server to manage cluster upgrades, deployments, extensions, etc
 - delete all AWS infrastructure

### Prerequisites for the playbook ###
A linux environment like ubuntu, debian or redhat with admin access
You will need enough disk space in this environment to store your docker image files which can be quite large, in some cases ~2GB +
python3.9.5 or later
  ex. `sudo apt-get install python3.9`
  PATH for /usr/bin/python3 assumes /usr/bin/python 
pip3 installed with the above python
  ex. `curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3.9 get-pip.py`
virtualenv pip package
  ex. `sudo pip3 install virtualenv`
jq bash json parser
  ex. `sudo apt-get install jq`
AWS admin permissions and credentials setup in the default location
  - AWS Route 53 public zone. This can be purchased from AWS or transferred in to Route53 to delegate.  This guide here may advise how to have the zone setup prior to this script run:
    https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingHostedZone.html

Make copy of the template file in directory manage_eks_services/template.yml and change to the relevant values needed for your configuration.  The template file contains definitions of needed vars and thier use.

BE sure NOT to make changes to ANY values that are NOT true/false between runs of this script or the script will not be able to cleanup properly. Example, changing the "eks_service_name" bewtween runs will no longer manage the previous "eks_service_name" and the OLD service will be added to the cluster rather than replaced.

Add your complete docker file directory with a valid Dockerfile in directory /docker_apps.  Please use dashes in directory name NOT underscores for consistency.

Any run of the script without all needed args will display help message like:
    `usage: ./manage_eks_server [-h] build_images -m manage_eks_service
    ./manage_eks_server: error: the following arguments are required: -m/--manage_eks_service`

One click build and deploy:
 ./manage_eks_server create_eks_infra -m <manage_eks_service_config>"
this command combined with the some config values will build container, install infrastructure and deploy eks server. Ensure the following values are, "true" in your config.
  create_ecr: true
  ecr_push: true
  eks_service_deploy: true

Build Docker Image
  ./manage_eks_server build_images -m <manage_eks_service_config>"

This will build and optionally deply a docker image to an ECR repo.  Please ensure the following values are defined as true:
  create_ecr: true
  ecr_push: true

Install EKS Cluster
  ./manage_eks_server create_eks_infra -m <manage_eks_service_config>"

This will install EKS and optionall deploy a docker image and eks service. If you'd like to install EKS infrastrcutre only please ensure that the following config values are false:
  create_ecr: false
  ecr_push: false
  eks_service_deploy: false


Deploy EKS Service
 ./manage_eks_server create_eks_service -m <manage_eks_service_config>"

This will deploy a service to an existing EKS cluster.  The command "create_eks_infra" should be run before this to ensure that cluster exists before deploy.

Delete EKS Service or Namespace
  ./manage_eks_server delete_eks_service -m <manage_eks_service_config>"

This will delete an EKS service and leave EKS cluster infrastruture untouched.

Delete EKS Cluster and All infrastructure
  ./manage_eks_server delete_eks_infra -m <manage_eks_service_config>"

This will delete ALL EKS service and leave EKS cluster infrastruture untouched. Unsure the following config values are set to false to als delete AWS ECR and local docker images:
  create_ecr: false
  ecr_push: false
  eks_service_deploy: false
  clean_local_docker_image: true


Tech Debt:
 - make ALL calls to helm locked to versions to ensure consistent installs between environments
 - make bastion an AMI with baked in requiremnts to also ensure consistent installs between environments
 - turn hardcoded INT values into variables for greater control
 - CloudWatch Log groups are NOT deleted with this.  As a best practice your data retention policy should be separate and there is value and viewing logs long after infrastrutre is deleted.  Be sure to delete these in cloudwatch when ready though cost for these logs are minimal.
