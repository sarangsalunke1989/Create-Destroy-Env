################################ Author : Sarang Salunke ###################################

echo " ################################################################################################## "
echo " Starting the Week-5 AWS code to delete instances load balancer and autoscaling group in cloud "
echo " ################################################################################################## "
echo



auto_char_count=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[].AutoScalingGroupName'|wc -m`
count=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[].AutoScalingGroupName'|xargs -n1|wc -l`

echo "Looking for AutoScaling Groups ...."
echo "----------------------------------------------------------"
if [[ $auto_char_count == 0 ]]
then
echo " No Autoscaling Groups found "
else
echo "$count Autoscaling groups present"
	for (( i=0;i<$count;i++ ))
	do
	##echo "`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[0].AutoScalingGroupName'`"
	##echo "`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[0].Instances[].InstanceId'`"

auto_scaling_group=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[0].AutoScalingGroupName'|xargs`
instances=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[0].Instances[].InstanceId'|xargs`
instances_count=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[0].Instances[].InstanceId'|xargs -n1|wc -l`
instance_char_count=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[0].Instances[].InstanceId'|wc -m`

		if [ $instance_char_count -ne 0 ]
		then
			echo "Scaling Group: $auto_scaling_group"
			echo "Instances: $instances"

aws autoscaling update-auto-scaling-group --auto-scaling-group-name $auto_scaling_group --min-size 0
aws autoscaling detach-instances --instance-ids $instances --auto-scaling-group-name $auto_scaling_group --should-decrement-desired-capacity
inst_cnt=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[0].Instances[].LifecycleState'|xargs -n1|wc -l`

		for (( j=0;j<$inst_cnt;j++ ))
			do
	echo "inst id `aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[0].Instances['$j'].InstanceId'`"
	state=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[0].Instances['$j'].LifecycleState'`
	echo " state is $state"
				while [ $state != "None" ]
				do
	echo "instance state is in $state ..."
	sleep 3
	state=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[0].Instances['$j'].LifecycleState'`
				done
			done

		else
echo "No instances were found in autoscaling group"
		fi

echo "Deleting Auto Scaling group $auto_scaling_group"

aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $auto_scaling_group
if [ $? -eq 0 ]
then
sleep 7
auto_scale_del_state=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[0].Status'`
echo "Auto Sacling group state is $auto_scale_del_state"
 	while [ "$auto_scale_del_state" != "None" ]	
	do
	echo "Waiting for the autoscaling group to be deleted ...."
	auto_scale_del_state=`aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[0].Status'`
	sleep 1
	done


echo "Auto Scaling Group $auto_scaling_group is deleted successfully "
else
echo "Error deleting Auto Scaling Group $auto_scaling_group ...Exiting execution"
exit 0
fi 


	done
fi


echo
echo "Deleting launch configuration .... "
echo "-------------------------------------------------------------------"

launch_char_conf_cnt=`aws autoscaling describe-launch-configurations --query 'LaunchConfigurations[].LaunchConfigurationName'|wc -m`
if [ $launch_char_conf_cnt -ne 0 ]
then

	for i in `aws autoscaling describe-launch-configurations --query 'LaunchConfigurations[].LaunchConfigurationName'|xargs`
	do
	echo $i
	aws autoscaling delete-launch-configuration --launch-configuration-name $i
		if [ $? -eq 0 ]
		then
		echo " Launch configuration $i deleted"
		else
		echo "Error deleting Launch configuration $i... Exiting execution"
		exit 0
		fi
	done
else
echo "No Launch configuration found"
fi


#####################################################################################################3

echo "Deleting Load Balancer .... Please be patient"
echo "-------------------------------------------------------------------"

load_bal_char_cnt=`aws elb describe-load-balancers --query "LoadBalancerDescriptions[].LoadBalancerName"|wc -m`
load_bal_cnt=`aws elb describe-load-balancers --query "LoadBalancerDescriptions[].LoadBalancerName"|xargs -n1|wc -l`

if [ $load_bal_char_cnt -ne 0 ]
then

for (( i=0;i<$load_bal_cnt;i++ ))
do
lb_name=`aws elb describe-load-balancers --query 'LoadBalancerDescriptions[0].LoadBalancerName'`
inst_name=`aws elb describe-load-balancers --query 'LoadBalancerDescriptions[0].Instances[].InstanceId'`
inst_count=`aws elb describe-load-balancers --query 'LoadBalancerDescriptions[0].Instances[].InstanceId'|xargs -n1|wc -l`

inst_char_count=`aws elb describe-load-balancers --query 'LoadBalancerDescriptions[0].Instances[].InstanceId'|wc -m`

if [ $inst_char_count -ne 0 ]
then
        echo "load balancer name: $lb_name"
        echo "instances attached : $inst_name"
        echo "Deregistering instances attached to $lb_name" 
	echo
        aws elb deregister-instances-from-load-balancer --load-balancer-name $lb_name --instances $inst_name

        for (( j=0;j<$inst_count;j++ ))
        do
        state=`aws elb describe-instance-health --load-balancer-name $lb_name --query 'InstanceStates['$j'].State'`
        state=`aws elb describe-instance-health --load-balancer-name $lb_name --query 'InstanceStates['$j'].State'`
        echo "state of $inst_name is $state"
        	while [ $state != "None" ]
       		do
        	echo "state now is $state"
        	sleep 3
        	state=`aws elb describe-instance-health --load-balancer-name $lb_name --query 'InstanceStates['$j'].State'`
        	done
	done
else
echo "No instances were found under the load balancer $lb_name"
fi


        aws elb delete-load-balancer --load-balancer-name $lb_name
        if [ $? -eq 0 ]
	then  
	echo "Load balancer $lb_name is deleted successfully"
        echo
	else
	echo "Error deleting load balancer $lb_name .... Exiting execution"
	fi

done
else
echo "No load balancers found"
fi

echo "Terminating instances .... Please be patient"
echo "--------------------------------------------------------"



inst_ids=`aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId'|xargs`
aws ec2 terminate-instances --instance-ids $inst_ids
if [[ $? -eq 0 ]]
then
echo "Instances $inst_ids are terminated successfully"
echo 
echo "Clean up of AWS is completed"
else
echo "Error terminating instances... Exiting execution"
fi
echo
echo " ################################################################################################################"
echo " Successfully completed the Week-5 deletion of instances in cloud along with load balancer and autoscaling group"
echo " ################################################################################################################"
