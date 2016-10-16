################################ Author : Sarang Salunke ###################################
echo
echo
echo " ################################################################################################## "
echo " Starting the Week-7 AWS code to deploy instances in cloud with load balancer and autoscaling group"
echo " ################################################################################################## "
echo
#### input parameters 

timestamp="Sarang`date +'%d%m%y-%H%M'`"
ami_id=$1
key_name=$2
security_group=$3
launch_config=$4
count=$5

#### control variables
r_id=0
sec_grp_ckh=0
wait_chk=0
key_name_chk=0
launch_config_chk=0
count_chk=0


## checking for numeric and valid count parameter
if ! [[ "$count" =~ ^[0-9]+$ ]]
then
echo "Error in number of arguments ..... Exiting execution "
echo "The instance count should be an interger .... Exiting execution !!!! "
echo "Usage Syntax: create_env.sh <ami-id> <key_name> <security_group> <launch_configuration> <count>"
exit 0
else
count_chk=1
fi



##Searching for the user passed Key pair name in the system
aws ec2 describe-key-pairs --query "KeyPairs[].KeyName"|grep -iw "$key_name"
if [ $? -eq 0 ]
then
key_name_ckh=1
echo "Key Name $key_name found"
#break
else
echo "Key Name $key_name not found .... Exiting execution !!!!"
echo "Usage Syntax: create_env.sh <ami-id> <key_name> <security_group> <launch_configuration> <count>"
exit 0
fi


##for i in `aws ec2 describe-security-groups --query "SecurityGroups[].GroupId"` 
##do  

##Searching for the user passed security group in the system
aws ec2 describe-security-groups --query "SecurityGroups[].GroupId"|grep -iw "$security_group"

if [ $? -eq 0 ] 
then 
sec_grp_ckh=1 
echo "Security group with id $security_group found"
#break
else
echo "Security group with $security_group not found .... Exiting execution !!!!"
echo "Usage Syntax: create_env.sh <ami-id> <key_name> <security_group> <launch_configuration> <count>"
exit 0
fi

##Searching for the launch configuration name in the system
aws autoscaling describe-launch-configurations --query 'LaunchConfigurations[].LaunchConfigurationName'|grep -iw "$launch_config"
if [ $? -eq 0 ]
then
echo "Use a new launch configuration name .... $launch_config is already present... Executing execution"
echo "Usage Syntax: create_env.sh <ami-id> <key_name> <security_group> <launch_configuration> <count>"
exit 0
#break
else
launch_config_chk=1
fi



##done
#echo "sec_grp_ckh is $sec_grp_ckh"
## checking for ideal condition of valid inputs to execute the runinstances command
if [[ $key_name_ckh -eq 1 &&  $sec_grp_ckh -eq 1 && $count_chk -eq 1 && $launch_config_chk -eq 1 ]]
then
echo
echo "Building instances in cloud for you ...." 
echo "-------------------------------------------------------------------"
##aws ec2 run-instances --image-id ami-06b94666 --key-name $key_name --security-group-ids $security_group --instance-type t2.micro --count $count --client-token $timestamp --user-data file://installenv.sh --placement AvailabilityZone='us-west-2a' > /tmp/a

aws ec2 run-instances --image-id $ami_id --key-name $key_name --security-group-ids $security_group --instance-type t2.micro --count $count --client-token $timestamp --user-data file://installenv.sh --placement AvailabilityZone='us-west-2a' > /tmp/a
else
echo "Problem in input parameters .... Exiting execution ...."
echo "Usage Syntax: create_env.sh <ami-id> <key_name> <security_group> <launch_configuration> <count>"
exit 0
fi


##Reading the temporary file to grep Reservation id
r_id_string=`more /tmp/a|head -1|awk '{print $2}'`

echo
echo "Reservation ID is $r_id_string "

##logic implemented to read the current reservation id
for i in `aws ec2 describe-instances --query "Reservations[].ReservationId"`
do
if [ $i == $r_id_string ]
then
#echo $r_id
break
else
r_id=`expr $r_id + 1`
fi
done

#echo "r_id is now $r_id"

echo "Instances are starting now .... Please be patient ...."
echo

for (( i=0;i<$count;i++ ))
do
id=`aws ec2 describe-instances --query 'Reservations['$r_id'].Instances['$i'].InstanceId'`
state=`aws ec2 describe-instances --query 'Reservations['$r_id'].Instances['$i'].State.Name'`
echo "$id $state"
##Waiting for the instance state to come in running state
while [ $state != "running" ]
do
echo "Waiting for instance with id $id to start ...."
sleep 3
state=`aws ec2 describe-instances --query 'Reservations['$r_id'].Instances['$i'].State.Name'`
done

echo "Instance with id $id is running"
wait_chk=`expr $wait_chk + 1`

if [ $wait_chk -eq 2 ]
then
echo " All your $count instances are started and are running now "
fi
done

############################## Creating Load Balancer ##############################################
echo 
echo " Creating load balancer  "
echo " --------------------------------------------------"
echo " Enter a name for load balancer [Avoid using _ in the name] "
read load_bal_name

aws elb describe-load-balancers --query 'LoadBalancerDescriptions[].LoadBalancerName'|grep -iw "$load_bal_name"
if [ $? -eq 0 ]
then
echo "Load balancer $load_bal_name is already present .... Please select a new name next time. Exiting execution."
exit 0
else
echo "Creating Load balancer $load_bal_name"
fi



######Searching for subnet id in us-west-2a region
subnet_id=`aws ec2 describe-subnets |grep -i us-west-2a |awk '{print $8}'|head -1`
if [ $? -eq 0 ]
then
echo "subnet id $subnet_id will serve in us-west-2a region" 
else
echo "Unable to get a subnet in us-west-2a region ....Provision one and restart the script. Exiting execution !!!!"
exit 0
fi


aws elb create-load-balancer --load-balancer-name $load_bal_name --listeners Protocol=Http,LoadBalancerPort=80,InstanceProtocol=Http,InstancePort=80 --security-groups $security_group --subnets $subnet_id

if [ $? -eq 0 ]
then
echo " Load Balancer completed successfully "
else
echo " Error creating load balancer .... Exiting execution !!!! "
exit 0
fi


echo
echo " Registering your instances now with load balancer .... Please be patient"
echo
instance_ids=`aws ec2 describe-instances --query "Reservations[$r_id].Instances[].InstanceId"` 

aws elb register-instances-with-load-balancer --load-balancer $load_bal_name --instances $instance_ids
if [ $? -eq 0 ]
then
echo "Instances are registered with your $load_bal_name load balancer " 
echo
else
echo "Error registering instances with the load balancer ... Exiting execution"
fi

############################## Creating Auto Scaling Group Launch Configuration ##############################################
echo "Creating Launch Configuration for you .... "
echo "-------------------------------------------------------------"

echo

#######For week-7 assignment requirement
##echo "Enter launch configuration name [Avoid using _ in the name] "
##read launch_config_name

#aws autoscaling create-launch-configuration --launch-configuration-name $launch_config_name --image-id ami-06b94666 --key-name $key_name --instance-type t2.micro --security-groups $security_group --user-data file://installenv.sh


aws autoscaling create-launch-configuration --launch-configuration-name $launch_config --image-id $ami_id --key-name $key_name --instance-type t2.micro --user-data file://installenv.sh

if [ $? -eq 0 ]
then 
echo " Launch configuration $launch_config completed successfully "
echo
else
echo " Error creating launch configuration "
exit 0
fi

echo "Creating Auto Scaling Group for you .... "
echo "-------------------------------------------------------------"


echo
echo "Enter auto scaling group name [Avoid using _ in the name] "
read auto_scale_grp_name

aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[].AutoScalingGroupName'|grep -iw "$auto_scale_grp_name"
if [ $? -eq 0 ]
then
echo "A group named $auto_scale_grp_name is already present .... Please select a new name next time. Exiting execution."
exit 0
else
echo "Creating autoscaling group $auto_scale_grp_name"
fi


aws autoscaling create-auto-scaling-group --auto-scaling-group-name $auto_scale_grp_name --launch-configuration $launch_config --availability-zone us-west-2a --load-balancer-name $load_bal_name --max-size 5 --min-size 1 --desired-capacity 3

if [ $? -eq 0 ]
then
echo "Auto Scaling group is created and configured successfully"
else
echo " Error creating launch configuration "
exit 0
fi
echo
echo "Waiting for instances under load balaner to come in service .... Please be patient"
echo "-------------------------------------------------------------------------------------"
inst_count=`aws elb describe-instance-health --load-balancer-name $load_bal_name --query 'InstanceStates[].State'|xargs -n1|wc -l`

for (( i=0;i<$inst_count;i++ ))
        do
        inst_id=`aws elb describe-instance-health --load-balancer-name $load_bal_name --query 'InstanceStates['$i'].InstanceId'`
        state=`aws elb describe-instance-health --load-balancer-name $load_bal_name --query 'InstanceStates['$i'].State'`
        echo "$inst_id state is $state"
        while [ $state != "InService" ]
        do
        echo "instance state is in $state ..."
        sleep 3
        state=`aws elb describe-instance-health --load-balancer-name $load_bal_name --query 'InstanceStates['$i'].State'`
        done
        done

echo "All instances are now InService state"


echo

lb_dns_id=0
for i in `aws elb describe-load-balancers --query 'LoadBalancerDescriptions[].LoadBalancerName'`
do
if [ $i == "$load_bal_name" ]
then
echo $a
else
lb_dns_id=`expr $lb_dns_id + 1`
fi
done

dns_name=`aws elb describe-load-balancers --query 'LoadBalancerDescriptions['$lb_dns_id'].DNSName'`
echo

echo "****************************************************************************************************"
echo
echo " Enter $dns_name in the browser to view the website "
echo

echo "****************************************************************************************************"

echo


echo " ########################################################################################################### "
echo " Successfully completed the Week-7 deployment of instances in cloud with load balancer and autoscaling group"
echo " ########################################################################################################### "
echo
echo
