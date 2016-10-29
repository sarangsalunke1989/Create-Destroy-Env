################################ Author : Sarang Salunke ###################################

echo " ################################################################################################## "
echo "              Starting the Week-8 AWS code to deploy Relational Database RDS instance               "
echo " ################################################################################################## "
echo


#timestamp="Sarang`date +'%d%m%y-%H%M'`"

db_inst_name=$1
security_group=$2

db_inst_index=0

user_name="sarang"
password="sarang321"

if [ "$#" -ne 2 ]
then
echo "Please enter correct number of inputs .... Exiting execution"
echo " Usage Syntax: create-app-env.sh <db_instance_name> <security_group> "
exit 0
fi


aws ec2 describe-security-groups --query "SecurityGroups[].GroupId"|grep -iw "$security_group" > /dev/null
if [ $? -eq 0 ]
then
#sec_grp_ckh=1
echo "Security group with id $security_group found"
else
echo "Security group with $security_group not found .... Exiting execution !!!!"
echo " Usage Syntax: create-app-env.sh <db_instance_name> <security_group> "
exit 0
fi


db_inst_name_chk=`aws rds describe-db-instances --query "DBInstances[].DBInstanceIdentifier"|xargs |grep -iw "$db_inst_name"`
if [ $? -eq 0 ] 
then
echo "Database Instance name already exits .... Select a unique name .... Exiting execution "
exit 0
fi


echo "Building database for you ... Please be patient"

aws rds create-db-instance --db-instance-identifier $db_inst_name --allocated-storage 20 --db-instance-class db.m1.small --engine mysql --vpc-security-group-ids $security_group --master-username $user_name --master-user-password $password > /tmp/b

if [ $? -eq 0 ]
then

for i in `aws rds describe-db-instances --query "DBInstances[].DBInstanceIdentifier"`
do
if [ $i == $db_inst_name ]
then
break
else
db_inst_index=`expr $db_inst_index + 1`
fi
done

#echo $db_inst_index

state=`aws rds describe-db-instances --query "DBInstances[$db_inst_index].DBInstanceStatus"`

while [ $state != "available" ]
do
echo -ne "."
state=`aws rds describe-db-instances --query "DBInstances[$db_inst_index].DBInstanceStatus"`
sleep 2
done
echo
echo -E "Database is created successfully"

echo

end_point=`aws rds describe-db-instances --query "DBInstances[$db_inst_index].Endpoint.Address"`

echo "****************************************************************************************************"
echo
echo "The End Point address : $end_point"
echo "User Name : $user_name"
echo "Password : $password"
echo
echo "****************************************************************************************************"
echo
else
echo "Error creating the RDS instance .... Exiting execution"
exit 0
fi

echo " ########################################################################################################### "
echo "    Successfully completed deploying the the Week-8 AWS code to deploy Relational Database RDS instance      "
echo " ########################################################################################################### "
