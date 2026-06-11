#!/bin/bash

REGION="us-east-1"
ACCOUNT_ID="NUMERO_DE_CUENTA"
REPO_NAME="roadmap"
IMAGE_TAG="1.0"
FULL_IMAGE_NAME="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}"

echo "1. Creando infraestructura de RED (VPC, Subredes)"

VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames '{"Value":true}'

IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --vpc-id "$VPC_ID" --internet-gateway-id "$IGW_ID"

SUBNET_1=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.1.0/24 --availability-zone "${REGION}a" --query 'Subnet.SubnetId' --output text)
SUBNET_2=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.2.0/24 --availability-zone "${REGION}b" --query 'Subnet.SubnetId' --output text)

RT_ID=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id "$RT_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" > /dev/null
aws ec2 associate-route-table --subnet-id "$SUBNET_1" --route-table-id "$RT_ID" > /dev/null
aws ec2 associate-route-table --subnet-id "$SUBNET_2" --route-table-id "$RT_ID" > /dev/null

SG_ID=$(aws ec2 create-security-group --group-name roadmap-sg --description "SG para ALB y Fargate" --vpc-id "$VPC_ID" --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0 > /dev/null

echo "2. Creando load balancer y target group"

TG_ARN=$(aws elbv2 create-target-group --name roadmap-tg --protocol HTTP --port 80 --vpc-id "$VPC_ID" --target-type ip --query 'TargetGroups[0].TargetGroupArn' --output text)

ALB_ARN=$(aws elbv2 create-load-balancer --name roadmap-alb --subnets "$SUBNET_1" "$SUBNET_2" --security-groups "$SG_ID" --query 'LoadBalancers[0].LoadBalancerArn' --output text)

aws elbv2 create-listener --load-balancer-arn "$ALB_ARN" --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn="$TG_ARN" > /dev/null

echo "3. Construyendo y subiendo imagen a ECR"

# Intenta crear el repositorio (si ya existe, ignorará el error)
aws ecr create-repository --repository-name "$REPO_NAME" 2> /dev/null

docker build -t "${REPO_NAME}:${IMAGE_TAG}" -f ../sitio-web/Dockerfile ..
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
docker tag "${REPO_NAME}:${IMAGE_TAG}" "$FULL_IMAGE_NAME"
docker push "$FULL_IMAGE_NAME"

echo "4. Configurando y desplegando en FARGATE"

# Generar archivo task-def.json dinámicamente usando "Here-Doc" de Bash
cat <<EOF > task-def.json
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
EOF

aws ecs register-task-definition --cli-input-json file://task-def.json > /dev/null

aws ecs create-cluster --cluster-name roadmap-cluster > /dev/null

echo "Esperando 10 segundos para asegurar que el ALB esté listo..."
sleep 10

aws ecs create-service \
    --cluster roadmap-cluster \
    --service-name roadmap-service \
    --task-definition roadmap-task \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_1,$SUBNET_2],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
    --load-balancers "targetGroupArn=$TG_ARN,containerName=roadmap-container,containerPort=80" > /dev/null

echo "DESPLIEGUE FINALIZADO."
ALB_DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns "$ALB_ARN" --query 'LoadBalancers[0].DNSName' --output text)
echo "En un par de minutos, tu app estará disponible en: http://$ALB_DNS"