# Wordpress deployment with terraform and ansible

# Prerrequisites

Before executing the deploy, make sure you have the following packages installed on your working directory:
	- terraform
	- ansible
	- pip and boto3 botocore
	- You should have the AWS CLI configurated with your credentials
	- you will also need a pair of keys public and private to connect by ssh to the EC2 instances

# Execution steps

	- Once you are done with the prerequisites, you can execute the deploy.sh file with the following command:
 
		$./deploy.sh

# Description of the deployment

This proyect integrates ansible and terraform in the following way:

	- It first creates the infraestructure in aws using terraform:
		- Creates an VPC and 2 public subnets
		- Creates 2 EC2s, one for the webserver and other for the database
		- Configures the segurity groups needed

	- Then, ansible configurates the instances previously created:
		- Installs the dynamic inventory to use terraform
		- Installs and configures Apache, PHP, Mariadb and mysql
		- Creates a database and a user 

