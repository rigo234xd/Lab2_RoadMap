#!/bin/bash

$REGION = "us-east-1"
$ACCOUNT_ID = "TU_NUMERO_DE_CUENTA_AQUI"
$REPO_NAME = "roadmap"
$IMAGE_TAG = "1.0"
$FULL_IMAGE_NAME = "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}"

echo "================================================="
echo "1. CREANDO INFRAESTRUCTURA DE RED (VPC, Subredes)"
echo "================================================="
$VPC_ID = (aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text).Trim()
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames '{"Value":true}'

$IGW_ID = (aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text).Trim()
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID

$SUBNET_1 = (aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone ${REGION}a --query 'Subnet.SubnetId' --output text).Trim()
$SUBNET_2 = (aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone ${REGION}b --query 'Subnet.SubnetId' --output text).Trim()

$RT_ID = (aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text).Trim()
aws ec2 create-route --route-table-id $RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID | Out-Null
aws ec2 associate-route-table --subnet-id $SUBNET_1 --route-table-id $RT_ID | Out-Null
aws ec2 associate-route-table --subnet-id $SUBNET_2 --route-table-id $RT_ID | Out-Null

$SG_ID = (aws ec2 create-security-group --group-name roadmap-sg --description "SG para ALB y Fargate" --vpc-id $VPC_ID --query 'GroupId' --output text).Trim()
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 | Out-Null

echo "================================================="
echo "2. CREANDO LOAD BALANCER Y TARGET GROUP"
echo "================================================="
$TG_ARN = (aws elbv2 create-target-group --name roadmap-tg --protocol HTTP --port 80 --vpc-id $VPC_ID --target-type ip --query 'TargetGroups[0].TargetGroupArn' --output text).Trim()

$ALB_ARN = (aws elbv2 create-load-balancer --name roadmap-alb --subnets $SUBNET_1 $SUBNET_2 --security-groups $SG_ID --query 'LoadBalancers[0].LoadBalancerArn' --output text).Trim()

aws elbv2 create-listener --load-balancer-arn $ALB_ARN --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$TG_ARN | Out-Null

echo "================================================="
echo "3. CONSTRUYENDO Y SUBIENDO IMAGEN A ECR"
echo "================================================="
# Intenta crear el repositorio (si ya existe, ignorará el error)
aws ecr create-repository --repository-name $REPO_NAME 2>$null

docker build -t ${REPO_NAME}:${IMAGE_TAG} .
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com
docker tag ${REPO_NAME}:${IMAGE_TAG} $FULL_IMAGE_NAME
docker push $FULL_IMAGE_NAME

echo "================================================="
echo "4. CONFIGURANDO Y DESPLEGANDO EN FARGATE"
echo "================================================="
# Generar archivo task-def.json dinámicamente
$TASK_DEF = @"
{
    "family": "roadmap-task",
    "networkMode": "awsvpc",
    "containerDefinitions": [
        {
            "name": "roadmap-container",
            "image": "$FULL_IMAGE_NAME",
            "portMappings": [{"containerPort": 80, "hostPort": 80, "protocol": "tcp"}],
            "essential": true
        }
    ],
    "requiresCompatibilities": ["FARGATE"],
    "cpu": "256",
    "memory": "512",
    "executionRoleArn": "arn:aws:iam::${ACCOUNT_ID}:role/ecsTaskExecutionRole"
}
"@
$TASK_DEF | Out-File -FilePath task-def.json -Encoding utf8

aws ecs register-task-definition --cli-input-json file://task-def.json | Out-Null

aws ecs create-cluster --cluster-name roadmap-cluster | Out-Null

Start-Sleep -Seconds 10 # Pequeña pausa para asegurar que el ALB esté listo

aws ecs create-service `
    --cluster roadmap-cluster `
    --service-name roadmap-service `
    --task-definition roadmap-task `
    --desired-count 2 `
    --launch-type FARGATE `
    --network-configuration "awsvpcConfiguration={subnets=['$SUBNET_1','$SUBNET_2'],securityGroups=['$SG_ID'],assignPublicIp='ENABLED'}" `
    --load-balancers "targetGroupArn=$TG_ARN,containerName=roadmap-container,containerPort=80" | Out-Null

echo "DESPLIEGUE FINALIZADO."
$ALB_DNS = (aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --query 'LoadBalancers[0].DNSName' --output text).Trim()
echo "En un par de minutos, tu app estará disponible en: http://$ALB_DNS"