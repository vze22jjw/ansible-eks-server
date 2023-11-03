# README #

This repository is for managing a AWS EKS service platform. The goal being that you will be able to provide a directory of a self contained docker app and this repo will:
 - build the docker image
 - create an AWS ECR with lifecycle permissions
 - push the result image to an AWS ECR
 - cleanup local disk space after image is pushed
 - Create EKS cluster using the AWS ECR as the docker image source for the cluster
 - create bastion server to manage cluster upgrades, deployments, extensions, etc
 - delete all AWS infrastructure

### Prerequisites for the playbook
* A linux environment like ubuntu, debian or redhat with admin access
* docker - ensure that the docker daemon is running for your OS distribution. Please check documentation for installing for your host system.
  ```
  https://docs.docker.com/engine/install/
  ```
* Disk Space - docker image files which can be quite large, in some cases ~2GB +
* python3.9.5 or later
  ```
  sudo apt-get install python3.9
  PATH for /usr/bin/python3 assumes /usr/bin/python
  ``` 
* pip3 installed with the above python
  ```
  curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3.9 get-pip.py
  ```
* virtualenv pip package
  ```
  sudo pip3 install virtualenv
  ```
* jq - bash json parser
  ```
  sudo apt-get install jq
  ```
* AWS admin permissions and credentials setup in the default location
  - AWS Route 53 public zone. This can be purchased from AWS or transferred in to Route53 to delegate.  This guide here may advise how to have the zone setup prior to this script run.
    https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingHostedZone.html

### Local Setup and Deploy
1. Make copy of the template file in directory manage_eks_services/template.yml and change the relevant values needed for your configuration.  The template file contains definitions of needed vars and thier use.

    * Be sure NOT to make changes to ANY values that are NOT ```true/false``` between runs of this script or the script will not be able to manage or cleanup properly. 
    * Example, changing the ```eks_service_name``` bewtween runs will no longer manage the previous ```eks_service_name``` and the OLD service will be added to the cluster rather than replaced.

2. Add your complete docker file directory with a valid Dockerfile in directory ```./docker_apps/my-docker-dirname```.  Please use dashes in directory name NOT underscores for consistency.

3. Add your own microservice deploymnt files that is the SAME name as the above ```./docker_apps/my-docker-dirname ``` in the directory ```./microservices/my-docker-dirname```. Please use dashes in directory name NOT underscores for consistency. These files should be named:
    * alb-ingress.manifest.yaml --- this is external DNS name and loadbalancer that service would be reached on.
    * deploy.manifest.yaml --- this is the k8s deployment and should define where the image should be downloaded from.
    * service.manifest.yaml --- this is the k8s service definition.
  
  * Please see directory ```./microservices/node-http-api``` for examples of how your service should be configured.  

4. Any run of the script without all needed args will display help message like:

    ```
    usage: ./manage_eks_server [-h] build_images -m manage_eks_service
    ./manage_eks_server: error: the following arguments are required: -m/--manage_eks_service
    ```

5. Output of script provides status and error if any via standard ouput

### One click build and deploy
 `./manage_eks_server create_eks_infra -m <manage_eks_service_config>" `
  
  - This command combined with the some config values will build container, install infrastructure and deploy eks service. Ensure the following values are, ```"true"``` in your config.  This install can take up to 40 minutes.
    - create_ecr: true
    - ecr_push: true
    - eks_service_deploy: true

### Other Commands Usage
##### Build Docker Image
  `./manage_eks_server build_images -m <manage_eks_service_config>"`

  - This will build and optionally push a docker image to an ECR repo.  Please ensure the following values are defined as true:
    - create_ecr: true
    - ecr_push: true

##### Install EKS Cluster
  `./manage_eks_server create_eks_infra -m <manage_eks_service_config>"`

  - This will install EKS and optionall deploy a docker image and eks service. If you'd like to install EKS infrastrcutre only please ensure that the following config values are false:
    - create_ecr: false
    - ecr_push: false
    - eks_service_deploy: false

##### Deploy EKS Service
 `./manage_eks_server create_eks_service -m <manage_eks_service_config>"`

  - This will deploy a service to an existing EKS cluster.  The command ```"create_eks_infra"``` should be run before this to ensure that cluster exists before deploy.

##### Delete EKS Service or Namespace
  `./manage_eks_server delete_eks_service -m <manage_eks_service_config>"`

  - This will delete an EKS service and leave EKS cluster infrastruture untouched. You must confirm deletion via command prompt.

##### Delete EKS Cluster and All infrastructure
  `./manage_eks_server delete_eks_infra -m <manage_eks_service_config>"`

  - This will delete ALL AWS services. You must confirm deletion via command prompt. Ensure the following config values are set to the following to also delete AWS ECR and local docker images:
    - create_ecr: false
    - ecr_push: false
    - eks_service_deploy: false
    - keep_local_docker_image: false
    - eks_delete_logs: true 

### Tech Debt:
 - make ALL calls to helm locked to versions to ensure consistent installs between environments
 - make bastion an AMI with baked in requiremnts to also ensure consistent installs between environments
 - bastion host should use internal DNS rather than IP stored locally.
 - Security Groups shold be locked down to users desired IP or behind Corporate VPN
 - Route 53 alb alias A record related to cluster are not deleted
 - turn hardcoded integer values into variables for greater control
 - CloudWatch Log groups can be deleted with this.  As a best practice your data retention policy should be separate and there is value and viewing logs long after infrastrutre is deleted.  Be sure to delete these in cloudwatch when ready though cost for storage of these logs are minimal. Cost for ingestion of these logs are not.  Perhaps try to minimize logging or consider another logging solution.
 - EFS storage templates should be consildated into one with a jinja loop

### Troubleshooting
  - If you encounter erros during the script run, re-running the same command usually works.  Ansible will keep infrastructure in the desired state based on the command run and will skip already configured items.
  - You may have need to check logs for the cluster they are exported in CloudWatch log groups. Depending on you cluster name you can find them with names:
    - "/aws/containerinsights/{{ eks_clustername }}/application"
    - "/aws/containerinsights/{{ eks_clustername }}/dataplane"  
    - "/aws/containerinsights/{{ eks_clustername }}/host"
    - "/aws/eks/{{ eks_clustername }}/cluster"

  - There are some states that AWS Cloudformation can no longer be updated.  Some of these states can be found at url:
    -  https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/troubleshooting.html#troubleshooting-errors-nested-stacks-are-stuck

