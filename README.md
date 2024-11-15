# nginx-proxy

# NOTES

* se asume que los servidores de backend se encuentran arriba y disponibles
* el folder de letscrypt es almacenado en /mnt/data, se debería montar un volmen en esa ruta en caso de querer persistir info
* config nginx debe estar definida en archivo nginx.conf, debe ser copiada a folder /devops/, dentro del container, el archivo es puesto en /etc/nginx/conf.d/
* se deben usar las siguentes opciones para referenciar los archivos asociados a ssl:
    * ssl_certificate /etc/letsencrypt/live/proxy/fullchain.pem;
    * ssl_certificate_key /etc/letsencrypt/live/proxy/privkey.pem;

# EXAMPLES

Archivo `Dockerfile` para construir la imagen del proxy:

```
FROM  i2btech/nginx-proxy:latest

COPY nginx.conf /devops/nginx.conf
```

El contenido del archivo `nginx.conf` debería ser similar a este, se utiliza para exponer los servicios através del proxy:
```
server {
    listen 80;
    server_name demo-proxy.i2btech.com;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl http2;
    server_name demo-proxy.i2btech.com;

    root /var/www/html;

    ssl_certificate /etc/letsencrypt/live/proxy/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/proxy/privkey.pem;

    location / {
        proxy_set_header HOST $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_pass http://172.17.0.1:8080/;
    }
}
```
