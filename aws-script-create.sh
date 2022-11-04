#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Deploying web app to AWS"

npm run build > /dev/null 2>&1

echo "Creating a key pair..."
aws ec2 create-key-pair --key-name LabKeyPair --query 'KeyMaterial' --output text > LabKeyPair.pem
chmod 400 LabKeyPair.pem
printf "${GREEN}Done.${NC}\n"

echo "Key pair fingerprint: "
aws ec2 describe-key-pairs --key-name LabKeyPair

echo "Creating security group..."

vpc_id=$(aws ec2 describe-vpcs --output json | jq '.["Vpcs"][0].VpcId')
group_id=$(aws ec2 create-security-group --group-name lab-sg-group --description "Security group for lab 2" --vpc-id "${vpc_id//\"}" | jq '.GroupId')
printf "${GREEN}Done.${NC}\n"

echo "Vpc id: "$vpc_id
echo
echo "Group id: "$group_id
echo

echo "Adding permission to the security group..."

aws ec2 authorize-security-group-ingress --group-id "${group_id//\"}" --protocol tcp --port 3389 --cidr 0.0.0.0/0
printf "${GREEN}Done.${NC}\n"
echo "Adding permission for ssh connection..."
aws ec2 authorize-security-group-ingress --group-id "${group_id//\"}" --protocol tcp --port 22 --cidr 0.0.0.0/0
printf "${GREEN}Done.${NC}\n"
echo "Adding permission for port 3000..."
aws ec2 authorize-security-group-ingress --group-id "${group_id//\"}" --protocol tcp --port 3000 --cidr 0.0.0.0/0
printf "${GREEN}Done.${NC}\n"

subnet_id=$(aws ec2 describe-subnets --output json | jq '.["Subnets"][1].SubnetId')

echo "Subnet id: "$subnet_id

echo "Creating instance 1..."
instance1_id=$(aws ec2 run-instances --image-id ami-09d3b3274b6c5d4aa --count 1 --instance-type t2.micro --key-name LabKeyPair --security-group-ids "${group_id//\"}" --subnet-id "${subnet_id//\"}" | jq '.["Instances"][0].InstanceId')

echo "Instance 1 id: "$instance1_id

echo "Creating instance 2..."
instance2_id=$(aws ec2 run-instances --image-id ami-09d3b3274b6c5d4aa --count 1 --instance-type t2.micro --key-name LabKeyPair --security-group-ids "${group_id//\"}" --subnet-id "${subnet_id//\"}" | jq '.["Instances"][0].InstanceId')

echo "Instance 2 id: "$instance2_id

echo "Creating instance 3..."
instance3_id=$(aws ec2 run-instances --image-id ami-09d3b3274b6c5d4aa --count 1 --instance-type t2.micro --key-name LabKeyPair --security-group-ids "${group_id//\"}" --subnet-id "${subnet_id//\"}" | jq '.["Instances"][0].InstanceId')

echo "Instance 3 id: "$instance3_id

echo "Waiting for the instances configuration..."

sleep 80

dns_instance1=$(aws --region us-east-1 ec2 describe-instances --instance-ids "${instance1_id//\"}" --output json | jq '.["Reservations"][0]["Instances"][0].PublicDnsName')
dns_instance2=$(aws --region us-east-1 ec2 describe-instances --instance-ids "${instance2_id//\"}" --output json | jq '.["Reservations"][0]["Instances"][0].PublicDnsName')
dns_instance3=$(aws --region us-east-1 ec2 describe-instances --instance-ids "${instance3_id//\"}" --output json | jq '.["Reservations"][0]["Instances"][0].PublicDnsName')

echo
echo "Instance 1 dns: "$dns_instance1
echo
echo "Instance 2 dns: "$dns_instance2
echo
echo "Instance 3 dns: "$dns_instance3
echo


echo "Copying build folder to all instances"
scp -r -o StrictHostKeyChecking=no -i "LabKeyPair.pem" build/ ec2-user@"${dns_instance1//\"}":/home/ec2-user
scp -r -o StrictHostKeyChecking=no -i "LabKeyPair.pem" build/ ec2-user@"${dns_instance2//\"}":/home/ec2-user
scp -r -o StrictHostKeyChecking=no -i "LabKeyPair.pem" build/ ec2-user@"${dns_instance3//\"}":/home/ec2-user


echo "Installing npm in the instances..."

ssh -i "LabKeyPair.pem" ec2-user@"${dns_instance1//\"}" 'curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.0/install.sh | bash'
ssh -i "LabKeyPair.pem" ec2-user@"${dns_instance1//\"}" '. ~/.nvm/nvm.sh'
ssh -i "LabKeyPair.pem" ec2-user@"${dns_instance1//\"}" 'nvm install 15.0.0'
ssh -i "LabKeyPair.pem" ec2-user@"${dns_instance1//\"}" 'npm install -g serve'

ssh -i "LabKeyPair.pem" ec2-user@"${dns_instance2//\"}" 'curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.0/install.sh | bash'
ssh -i "LabKeyPair.pem" ec2-user@"${dns_instance2//\"}" '. ~/.nvm/nvm.sh'
ssh -i "LabKeyPair.pem" ec2-user@"${dns_instance2//\"}" 'nvm install 15.0.0'
ssh -i "LabKeyPair.pem" ec2-user@"${dns_instance2//\"}" 'npm install -g serve'

ssh -i "LabKeyPair.pem" ec2-user@"${dns_instance3//\"}" 'curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.0/install.sh | bash'
ssh -i "LabKeyPair.pem" ec2-user@"${dns_instance3//\"}" '. ~/.nvm/nvm.sh'
ssh -i "LabKeyPair.pem" ec2-user@"${dns_instance3//\"}" 'nvm install 15.0.0'
ssh -i "LabKeyPair.pem" ec2-user@"${dns_instance3//\"}" 'npm install -g serve'


echo "Running the web app in the instances..."

ssh -i "LabKeyPair.pem" ec2-user@"${dns_instance1//\"}" 'serve -s build > /dev/null 2>&1 &'
ssh -i "LabKeyPair.pem" ec2-user@"${dns_instance2//\"}" 'serve -s build > /dev/null 2>&1 &'
ssh -i "LabKeyPair.pem" ec2-user@"${dns_instance3//\"}" 'serve -s build > /dev/null 2>&1 &'

port=":3000"

echo
echo "You can access to instance 1 through: ""${dns_instance1//\"}"$port
echo "You can access to instance 2 through: ""${dns_instance2//\"}"$port
echo "You can access to instance 3 through: ""${dns_instance3//\"}"$port
echo
echo

printf "If you want to ${RED}delete${NC} instances, security group and the key, ${YELLOW}please write delete${NC}, otherwise nothing will be deleted: "
read var

if [ $var = "delete" ]; then
printf "${RED}Everything will be deleted, This will take a few minutes${NC}\n"
echo "Deleting instances..."
aws ec2 terminate-instances --instance-ids "${instance1_id//\"}" "${instance2_id//\"}" "${instance3_id//\"}"
echo "Waiting for instances to be eliminated..."
sleep 240
echo "Deleting security group..."
aws ec2 delete-security-group --group-id "${group_id//\"}"
sleep 10
echo "Deleting keys..."
aws ec2 delete-key-pair --key-name LabKeyPair
exit 0
else
printf "${YELLOW}Nothing will be deleted${NC}"
exit 0
fi