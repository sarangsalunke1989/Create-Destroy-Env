Author : Sarang Salunke

Git URL - https://github.com/sarangsalunke1989/Create-Destroy-Env.git

These scripts are used for setting up the Infrastructure of EC2 instances, Elastic Load Balancer and Auto Scaling Groups in the Amazon Cloud in the us-west-2a region.

On creation you can use the load balancer DNS name in the browser which will help you to view our IIT website.

Creating Infrastructure
---------------------------------------
Usage Syntax: create-env.sh <key_name> <security_group> <count>

eg: - ./create-env.sh Sarang_AWS_KEY sg-ae15d0d7 2

where create-env.sh - Script 
Sarang_AWS_KEY - AWS key . Can be found using  aws ec2 describe-key-pairs command
sg-ae15d0d7 - security group. Can be found using aws ec2 describe-security-groups. Make sure it has rules set to run/access http and ssh ports
count - Number of EC2 instances that you need to deploy in the cloud

During execution you will be prompted the following :-
Enter a name for load balancer - Here please enter a valid string input name avaoiding blank and '_'.
Enter launch configuration name - Here please enter a valid string input name avaoiding blank and '_'.
Enter auto scaling group name - Here please enter a valid string input name avaoiding blank and '_'.

This will create a customized named load balancer, launch configuration and auto scaling group for you. Make sure the names are unique.


Make sure you have a subnet to serve in place for the us-west-2a region else the script will fail because I look for it during execution and dynamically use that to set up the infrastructure


Destroying Infrastructure
---------------------------------------
Usage Syntax: ./destroy-env.sh

This will destroy/kill all the infrastructure of Auto scaling group, Load balancer and EC2 instances that is created in the Amazon cloud.
