#!/bin/bash

REGION="us-east-1"
ACCOUNT_ID="NUMERO_CUENTA"
REPO_NAME="roadmap"
IMAGE_TAG="1.0"
FULL_IMAGE_NAME="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}"

SUBNET_1="subnet-xxxxxxxx"
SUBNET_2="subnet-yyyyyyyy"
SG_ID="sg-zzzzzzzz"

echo "Iniciando despliegue..."

docker build -t ${REPO_NAME}:${IMAGE_TAG} .

aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

docker tag ${REPO_NAME}:${IMAGE_TAG} ${IMAGE_NAME}
docker push ${IMAGE_NAME}

# 4. Registrar Tarea
aws ecs register-task-definition --cli-input-json file://task-def.json

aws ecs create-cluster --cluster-name roadmap-cluster
aws ecs create-service \
    --cluster roadmap-cluster \
    --service-name roadmap-service \
    --task-definition roadmap-task \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=['${SUBNET_1}','${SUBNET_2}'],securityGroups=['${SG_ID}'],assignPublicIp='ENABLED'}"

echo "Despliegue completado con éxito."