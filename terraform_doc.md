
//Initialising terraform project
#cd <location having terraform file>
#terraform init (will download provider plugin based on entry in .tf file)

//Creating first AWS resource (refer docs for syntax at https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc)

provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "my_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "JavaHomeVpc"
  }
}

output "my_cidr" {
  value = "${aws_vpc.my_vpc.cidr_block}"
}



//Command to execute terraform scripts in current directory (above script creates a vpc in our AWS management console)
#terraform apply

//terraform apply is idempotent command

**In order to store state files remotely, we can use "terraform S3 backend" module:
=>Stores the state as a given key(ex: terraform.tfstate) in a given bucket on Amazon S3. This backend also supports state locking and consistency checking via Dynamo DB, which can be enabled by setting the dynamodb_table field to an existing DynamoDB table name. A single DynamoDB table can be used to lock multiple remote state files.

terraform {
  backend "s3" {
    bucket = "javabucket123"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

//while adding terraform backend run below command (ensure that bucket named "javabucket123" is already present in s3 as state file should be present in bucket before running terraform apply which could have created resource)
#terraform init

//now terraform.tfstate from local machine will get deleted and is moved to s3 bucket which will be our reference henceforth.having state file in s3 bucket is useful when multiple developers are working on configuring terraform for applications. Enable versioning for this state file in s3.


//Locking remote state file: must when multiple developers applying changes to this file otherwise we may get inconsistent state file.

DynamoDB is used for state locking consistency. It acquires the lock on state file when one developer is applying changes and releases it only when the changes are done.
"dynamodb_table" - (Optional) Name of DynamoDB Table to use for state locking and consistency. The table must have a primary key named "LockID" with type of string. If not configured, state locking will be disabled.Create this DynamoDB table with LockID key in AWS console before applying .tf file.


terraform {
  backend "s3" {
    bucket         = "javabucket123"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "Java-home-table"
  }
}


after adding "dynamodb_table" run below commands:
#terraform init
#terraform apply

=================================================================================================================================================================

TERRAFORM VARIABLES:-

variable "vpc_cidr" {
  description = "choose value for cidr"
  default     = "10.20.0.0/16"
  type = "string"
}

//to use this variable:
cidr_block = "${var.vpc_cidr}"

//To change varaible value at runtime
#terraform apply -var "<VARIABLE>=<VALUE>" -auto-approve

//To pass value to many variables at runtime:
define the variables in ".tfvars" file

ex: dev.tfvars
---------------------
vpc_cidr=10.30.0.0/16


//now the command to apply will be
#terraform apply -var-file=dev.tfvars


// way to define variables as array
variable "availability_zone_names" {
  type    = list(string)
  default = ["us-west-1a"]
}


=====================================================================================================================================

TERRAFORM WORKSPACE: same configuration files can be used to deploy in different environments like dev,UAT,prod
//To list available workspaces
#terraform workspace list

//To create new terraform workspace
#terraform workspace new <name-of-new-workspace>

ex: terraform workspace new dev
At this stage separate state files will get created for different env in s3 bucket

//To select particular namespace and provision resource for it:
#terraform workspace select dev
#terraform apply

//To give tag specific to current workspace:
    Env  = "${terraform.workspace}"
	
======================================================================================================================================

TERRAFORM USING LOOPS: we can create n instances of a resource by mentioning (count = N ) as shown below:

resource "aws_vpc" "my_vpc" {
  count            = 3
  cidr_block       = "${var.vpc_cidr}"
  instance_tenancy = "default"

  tags = {
    Name = "JavaHomeVpc"
    Env  = "${terraform.workspace}"
  }
}

======================================================================================================================================

TERRAFORM CONDITIONS- CREATING RESOURCES CONDITIONALLY:

resource "aws_vpc" "my_vpc" {
  count            = "${terraform.workspace == "dev" ? 0:1}"
  cidr_block       = "${var.vpc_cidr}"
  instance_tenancy = "default"

  tags = {
    Name = "JavaHomeVpc"
    Env  = "${terraform.workspace}"
  }
}

=====================================================================================================================================

//Terrafrom local variables:
locals.tf
----------

locals {
  vpc_name = "${terraform.workspace == "dev" ? "javadevvpc" : "javaprodvpc"}"
}

resource "aws_vpc" "my_vpc" {
  count            = "${terraform.workspace == "dev" ? 1 : 0}"
  cidr_block       = "${var.vpc_cidr}"
  instance_tenancy = "default"

  tags = {
    Name = "${local.vpc_name}"
    Env  = "${terraform.workspace}"
  }
}

=====================================================================================================================================

TERRAFORM Public SUBNET:

resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.my_app.id}"
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "PublicSubnet"
  }
}

variable "vpc_cidr" {
  description = "choose value for cidr"
  default     = "10.20.0.0/16"
  type        = string
}

variable "region" {
  default = "us-east-1"
  type    = string

}



DATA SOURCE TERRAFORM: used to fetch data from outside the terraform(like new AMI, availability zones etc)

#DATA source to fetch availability zones

data "aws_availability_zones" "azs" {

}
--------------------------------------------------------------------------------------------------------------------------------------
#cidrsubnet function -used to created subnet out of a CIDR block
cidrsubnet("Prefix",new-bits,subnet-number)

ex: cidrsubnet("172.16.0.0/12",4,2) = 172.18.0.0/16



=========================================================================================================================================
Code TO create public subnets in a VPC:
========================================================================================================================================
provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "azs" {

}

variable "vpc_cidr" {
  description = "choose value for cidr"
  default     = "10.20.0.0/16"
  type        = string
}

variable "region" {
  default = "us-east-1"
  type    = string

}

resource "aws_vpc" "my_app" {
  cidr_block       = "${var.vpc_cidr}"
  instance_tenancy = "default"

  tags = {
    Name = "JavaHomeVpc"
    Env  = "${terraform.workspace}"
  }
}

locals {
  az_names = "${data.aws_availability_zones.azs.names}"
}

resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.my_app.id}"
  count      = "${length(local.az_names)}"
  cidr_block = "${cidrsubnet(var.vpc_cidr, 8, count.index)}"
  #to count total aws_availability_zone

  availability_zone = "${local.az_names[count.index]}"

  tags = {
    Name = "PublicSubnet-${count.index + 1}"
  }
}

==========================================================================================================================================








