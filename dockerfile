FROM nginx:1.27-alpine
COPY sitio-web/ /usr/share/nginx/html/
EXPOSE 80