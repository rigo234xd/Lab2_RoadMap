#!/bin/bash


REGION="us-east-1"
CLUSTER_NAME="roadmap-cluster"
SERVICE_NAME="roadmap-service"
REPO_NAME="roadmap"

echo "🧹 Iniciando limpieza automatizada de recursos de AWS..."

# 1. Bajar el conteo de tareas a 0 para detener los contenedores en Fargate
echo "Deteniendo tareas del servicio (Estableciendo deseado a 0)..."
aws ecs update-service \
    --cluster "$CLUSTER_NAME" \
    --service "$SERVICE_NAME" \
    --desired-count 0 \
    --region "$REGION" > /dev/null

echo "Esperando unos segundos para que las tareas comiencen a apagarse..."
sleep 10

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

echo "Verificando que no queden clústeres activos..."
aws ecs list-clusters --region "$REGION"

echo "¡Limpieza completada con éxito! Tu entorno está listo para volver a lanzar deploy.sh."