# CLAW (Cloud Layer Analysis Workstation)

This document provides an outline on how to create a AWS (Amazon Web Services) AMI (Amazon Machine Image) or Azure VM for use by an organization's security team or DFIR (Digital Forensics & Incident Response) personnel.  


This document outlines using `packer` with AWS & Azure to generate a custom AMI / VM for incident response. 

## Why?

When an incident occurs in AWS, Azure or another service provider, the ideal response to that incident should occur within that same infrastructure.  By conducting investigations within the service provider's infrastructure, analysts will benefit from increased transfer speeds of any potential evidence as well as ensuring evidence is collected and stored in a protected environment without having to download gigabytes or terabytes of data (.e.g machine images, memory dumps, logs, etc.) to local infrastructure.

## Benefits

By creating (and having on hand) a base AMI / VM to conduct incident investigations,  your incident response team(s) will gain the following benefits:

* A faster overall response time when incidents occur
* A dedicated, standardized, reproducible, and redeployable environment for conducting investigations 
* Evidence contamination protection through deployment of a fresh environment for each investigation
* A true cloud-centric posture: collection, processing, and storage of evidence from cloud resources using cloud resources


## Requirements

This tool relies on `packer` to generate a custom AMI / VM template that can be used to deploy when an incident occurs.  

### AWS

In order to generate a base AMI for AWS based cloud investigations, you must have the following tools and requirements met before proceeding:

* Packer - 1.4.1
* aws-cli/1.16.109 Python/3.7.3 Darwin/18.6.0 botocore/1.12.171

Additionally, you will need the following from your AWS account.  These will be used in our variable file:

* aws_access_key
* aws_secret_key


> We are using the `ubuntu-xenial-16.04-amd64-server` base AMI from the Amazon Marketplace and installing `sift-cli-linux` as an example. Details are provided on how you would install additional tools/products when generating this AMI

### Access

In order to create an AMI, you must have access permissions to both setup and build an EC2 (Elastic Compute Cloud) instance as well as access to EBS (Elastic Block Store).  

You will, in addition to these permissions, need a AWS API Access Key and AWS API Secret Key to generate a AMI using the AWS CLI.

### Azure

In order to generate a base VM template for Azure based cloud investigations, you must have the following tools and requirements met before proceeding.

* Packer (1.4.1+)
* azure-cli (2.0.75+)

Additionally, you will need have permissions to register an application manually within Azure Active Directory or follow these steps using `az` cli. These will be used in our variable file:

#### Login to Azure

```bash
az login
```

#### Create a resource group

```bash
az group create -n dfirResourceGroup -l eastus
```

#### Create a service principal account

```bash
az ad sp create-for-rbac --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"

# Keep track of the outputted values for the client_id, client_secret, and tenant_id
```

#### Retrieve your subscription ID

```bash
az account show --query "{ subscription_id: id }"
```


## Usage

To use this tool, please download or clone the repository:

```bash
git clone git@github.com:swimlane/CLAW.git
```


Next, cd in to the projects directory.

```bash
cd CLAW
```

### AWS 

If you are wanting to generate an AMI in AWS then `cd` into the `aws` sub-folder.

```bash
cd aws
```

Now that we are in the directory, we need to copy or edit the `vars-template.json` file and add our keys.  `vars-template.json` should look like the following:

```json
{
    "aws_access_key": "XXXXXXXXXXXXXXXX",
    "aws_secret_key": "xxxRb1skqQ3YSxxx0JhsxxxxCyqadxxxxxCCIFMN",
    "vpc_region": "us-east-1",
    "source_ami_name": "Ubuntu Desktop 16.04LTS-180627-180802 (HVM EBS x86_64)-*",
    "source_ami_owner_id": "679593333241",
    "instance_type": "t2.micro",
    "ssh_username": "ubuntu"
}
```

You will add your `aws_access_key`, `aws_secret_key`, and `vpc_region`.  Additionally, you can change the source AMI information as well as the instance type and ssh username.

> Please reference the [details](#details) section below or the official [packer](https://www.packer.io/) for more information about packer works


After saving your values in your `vars-template.json` then run the following:

```
packer build -debug -var-file=vars-template.json aws.json
```

That's it!  It should create a EC2 instance, install our dependencies from the `provisioners` sub-folder and then capture a new AMI for future deployments.

### Azure

If you are wanting to generate an VM template in Azure then `cd` into the `azure` sub-folder.

```bash
cd azure
```

Now that we are in the directory, we need to copy or edit the `vars-template.json` file and add our keys. The `vars-template.json` should look like the following:

> Please see the [Login to Azure](#login-to-azure) section above to learn how to generate these keys using a service principal account (recommended)

```json
{
    "azure_subscription_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx",
    "azure_client_id": "7876e9a8-xxxx-xxxx-xxxx-993a50dd5d31",
    "azure_tenant_id": "c6161d00-xxxx-xxxx-xxxx-26702571ff46",
    "azure_client_secret": "e579c46f-xxxx-xxxx-xxxx-e2fac1f44fce",
    "azure_resource_group_name": "dfirResourceGroup"
}
```

You will add your `azure_subscription_id`, `azure_client_id`, `azure_client_secret`, and `azure_tenant_id`.  Additionally, you can change the azure resource group name that you want to use as well. 

> Please reference the [details](#details) section below or the official [packer](https://www.packer.io/) for more information about packer works


After saving your values in your `vars-template.json` then run the following:

```
packer build -var-file=vars-template.json azure.json
```

That's it!  It should create a VM instance, install our dependencies from the `provisioners` sub-folder and then capture a new VM for future deployments.


## Details

Now that you have a understanding of how to create this new AMI, let's breakdown what is going on and how you can modify this project to build your own unique AMI for DFIR in AWS.


The `aws.json` / `azure.json` file are `packer` definition files that will generate and create our custom AMI / VM.  It has the following sections:

* variables
* builders
* provisioners
* post-processors

### Variables

The `variable` section is our input variables to connect to AWS or Azure via their API.  In the usage section above we run:

```bash
# AWS build
packer build -debug -var-file=vars-template.json aws.json

# Azure build
packer build --debug -var-file-=vars-template.json azure.json
```

We are telling `packer` to build (debug logging enabled with the `-debug` switch) and providing a `-var-file` that contains our variables, which match the variables section within either our `aws.json` or `azure.json` packer definition file.  These variables are:

### AWS Variable Template

```json
{
    "aws_access_key": "XXXXXXXXXXXXXXXX",
    "aws_secret_key": "xxxRb1skqQ3YSxxx0JhsxxxxCyqadxxxxxCCIFMN",
    "vpc_region": "us-east-1",
    "source_ami_name": "Ubuntu Desktop 16.04LTS-180627-180802 (HVM EBS x86_64)-*",
    "source_ami_owner_id": "679593333241",
    "instance_type": "t2.micro",
    "ssh_username": "ubuntu"
}
```

### Azure Variable Template

```json
{
    "azure_subscription_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx",
    "azure_client_id": "7876e9a8-xxxx-xxxx-xxxx-993a50dd5d31",
    "azure_tenant_id": "c6161d00-xxxx-xxxx-xxxx-26702571ff46",
    "azure_client_secret": "e579c46f-xxxx-xxxx-xxxx-e2fac1f44fce",
    "azure_resource_group_name": "dfirResourceGroup"
}
```
### Identify resource images

There are a few different ways to find the appropriate AMI / VM to use as your base template image, but that is out of the scope of this project.  To find out more information on how to identify a AMI image name, review these articles:

* https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/finding-an-ami.html
* https://blog.gruntwork.io/locating-aws-ami-owner-id-and-image-name-for-packer-builds-7616fe46b49a

To learn how to identify a base template in Azure, review this article:

* https://vincentlauzon.com/2018/01/10/finding-a-vm-image-reference-publisher-sku/


### Builders

The `builders` section is where the magic happens.  In `builders` we are specifying a type of `amazon-ebs` (AWS) and `azure-arm` (Azure) (this is the build type for packer).  To see what other types of packer `builders` are available please review their documentation [here](https://www.packer.io/docs/builders/index.html).

The `builders` section is basically where we use the inputs from our variables to setup a new EC2 / VM instance that we then customize with the `provisioners` section

### Provisioners

The `provisioners` section is where custom code or scripts will be used inside of the newly created EC2 / VM instance.  In this project I am providing several sample scripts in the `provisioners` folder. 

* [desktop.sh](provisioners/desktop.sh) - `desktop.sh` adds desktop features to Ubuntu Server 16.04 which is required for the `sift-cli-linux` toolkit.  This is only used by the Azure provisioner.
* [s3.sh](provisioners/s3.sh) - `s3.sh` is still a poc and needs work but the plan is to add a `s3` bucket (and azure storage blob) to the VM to capture and process evidence
* [sift.sh](provisioners/sift.sh) - `sift.sh` installs all the `sift-cli-linux` tools on our template AMI / VM.  

You can install any additional tools by doing the following:

* Modify an existing provisioner script or copy one and edit to fit your needs/requirements (pull requests are always welcome!)
* Add additional `provisioners` in either the `aws.json` or `azure.json` packer definition file(s)

If we take a look at the `sift.sh` script we see that we have defined a function called `main` and then we call `main` at the end of the file:

> Included is a apt_wait function as well that is used to determine if `apt`, `dpk`, or `unattended/upgrade` is running locking files before continuing.  If you know of a better way to prevent this please add an issue or create a pull request!

```bash
.....
main() {

    apt_wait

    wget -O - https://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
    echo "downloaded saltstack"
    echo "deb http://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest xenial main" | sudo tee /etc/apt/sources.list.d/saltstack.list
    echo "adding saltstack to source list"
    apt_wait
    echo "updating apt-get"
    sudo apt-get -y update

    apt_wait
    echo "installing salt-minion"
    sudo apt-get -y install salt-minion || delete_lock 'salt-minion'
    apt_wait
    echo "stopping salt-minion"
    sudo service salt-minion stop
    apt_wait
    # Snag the binaries - https://github.com/sans-dfir/sift-cli
    echo "downloading sift cli"
    sudo curl -Lo /usr/local/bin/sift https://github.com/sans-dfir/sift-cli/releases/download/v1.7.1/sift-cli-linux
    echo "chmod sift cli"
    sudo chmod +x /usr/local/bin/sift

    apt_wait
    # Install SIFT
    echo "installing sift"
    sudo sift install --mode=packages-only
}

main
```

We are using `curl` to download (`-L` is used to follow any redirects) `sift-cli-linux` and outputting it to a file in our local user directory.  Next we `mv` the downloaded file to `/usr/local/bin/` and name it `sift`. Then we change permissions on the file, with finally installing it. Pretty straight forward.

### Additional Provisioners / Tools

If you wanted to add additional tools or installation/configuration steps you can do so by copying or modifying any of the shell scripts in the provisioners folder.  If you added a new script you must reference them in your packer definition file under the `provisioners` section in your desired packer configuration file.

Currently the `provisioners` section looks like this for `AWS`:

```json
 "provisioners": [
        {
          "type": "shell",
          "script": "../provisioners/sift.sh"
        },
        {
            "type": "shell",
            "script": "../provisioners/s3.sh"
          }
    ],
```

Currently the `provisioners` section looks like this for `Azure`:

```json
 "provisioners": [
        {
            "type": "shell",
            "script": "../provisioners/desktop.sh"
        },
        {
            "type": "shell",
            "script": "../provisioners/sift.sh"
        }
    ],
```

There are many different provisioners that can be used besides `shell`.  For example, you could use PowerShell or Chef, plus others.  Check out packers documentation [here](https://www.packer.io/docs/provisioners/index.html) for more information about `provisioners`.
