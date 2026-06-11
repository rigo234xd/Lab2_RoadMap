# Despliegue Escalable en AWS ECS Fargate - Laboratorio 2

![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Bash](https://img.shields.io/badge/GNU%20Bash-4EAA25.svg?style=for-the-badge&logo=GNU-Bash&logoColor=white)

Bienvenido al repositorio de infraestructura y despliegue del MVP para nuestra Startup. Este proyecto automatiza la creación de una arquitectura en alta disponibilidad usando **Amazon ECS sobre Fargate**, un **Application Load Balancer (ALB)** y **Amazon ECR**, gestionado enteramente mediante **AWS CLI**.

## Estructura del Proyecto

El proyecto sigue el principio de separación de responsabilidades:

- **`sitio-web/`**: Contiene el código fuente de la aplicación (HTML, CSS, JS) y su respectivo `Dockerfile` optimizado.
- **`infraestructura/`**: Contiene los scripts de Bash (`deploy.sh` y `cleanup.sh`) para el aprovisionamiento y destrucción de la infraestructura en la nube de AWS.

## Requisitos Previos

Antes de ejecutar el despliegue, asegúrate de tener:

1.  **Docker Desktop** abierto y ejecutándose en tu equipo.
2.  **AWS CLI** instalado y configurado (`aws configure`) con credenciales activas.
3.  **Terminal Bash** (Git Bash, WSL en Windows, o nativa en Linux/Mac).
4.  **Importante (Rol IAM):** Este script asume que la cuenta de AWS ya posee el rol `ecsTaskExecutionRole` activo. Si despliegas en una **cuenta personal nueva**, debes crear este rol previamente para que Fargate tenga permisos de descargar la imagen desde ECR. _(En cuentas de AWS Academy este rol suele venir por defecto)_.
5.  **Numero de cuenta** una vez creado el repositorio de amazon, debemos poner el numero de cuenta en deploy.sh.

## Guía de Despliegue

Sigue estos pasos para levantar la infraestructura completa:

1. **Clona este repositorio** y navega a la carpeta de infraestructura:
   ```bash
   cd infraestructura
   ```
2. **Otorga permisos de ejecución**, solo es necesario hacerlo una vez
   ```bash
   chmod +x deploy.sh cleanup.sh
   ```
3. **Ejecutar script de despliegue**
   ```bash
   ./deploy.sh
   ```
4. **Limpiamos lo creado**
   ```bash
   ./deploy.sh
   ```
