#!/bin/bash

REGION="us-east-1"
CLUSTER_NAME="roadmap-cluster"
SERVICE_NAME="roadmap-service"
REPO_NAME="roadmap"

echo "Iniciando limpieza automatizada de recursos de AWS..."

# 1. Bajar el conteo de tareas a 0 para detener los contenedores en Fargate
echo "Deteniendo tareas del servicio (Estableciendo deseado a 0)..."
aws ecs update-service \
    --cluster "$CLUSTER_NAME" \
    --service "$SERVICE_NAME" \
    --desired-count 0 \
    --region "$REGION" > /dev/null

echo "Esperando 15 segundos para que las tareas comiencen a apagarse..."
sleep 15

# 2. Borrar el servicio de ECS forzadamente
echo "Eliminando el servicio ECS ($SERVICE_NAME)..."
aws ecs delete-service \
    --cluster "$CLUSTER_NAME" \
    --service "$SERVICE_NAME" \
    --force \
    --region "$REGION" > /dev/null

# 3. Borrar el Clúster de ECS
echo "Eliminando el clúster ECS ($CLUSTER_NAME)..."
aws ecs delete-cluster \
    --cluster "$CLUSTER_NAME" \
    --region "$REGION" > /dev/null

# 4. Eliminar el repositorio de Amazon ECR junto con todas sus imágenes
echo "Eliminando el repositorio ECR ($REPO_NAME) y sus imágenes..."
aws ecr delete-repository \
    --repository-name "$REPO_NAME" \
    --force \
    --region "$REGION" > /dev/null

# 5. Eliminar el ALB y el Target Group (CRÍTICO para evitar cobros)
echo "Buscando y eliminando el Balanceador de Carga (ALB)..."
ALB_ARN=$(aws elbv2 describe-load-balancers --names roadmap-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null)

if [ -n "$ALB_ARN" ] && [ "$ALB_ARN" != "None" ]; then
    aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" --region "$REGION"
    echo "Esperando 10 segundos a que el ALB se destruya..."
    sleep 10
fi

echo "Buscando y eliminando el Target Group..."
TG_ARN=$(aws elbv2 describe-target-groups --names roadmap-tg --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)

if [ -n "$TG_ARN" ] && [ "$TG_ARN" != "None" ]; then
    aws elbv2 delete-target-group --target-group-arn "$TG_ARN" --region "$REGION"
fi

echo "========================================="
echo "Verificando clústeres activos (Evidencia para el lab):"
aws ecs list-clusters --region "$REGION"

echo "¡Limpieza completada con éxito! Tu entorno está limpio."