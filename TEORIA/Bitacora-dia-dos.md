# 🌐 HTTP

HTTP (**HyperText Transfer Protocol**) es el protocolo utilizado principalmente para la comunicación entre **clientes** y **servidores web**.

```text
                    HTTP
                      │
              ┌───────┴───────┐
              │               │
           CLIENTE          SERVIDOR
              │               │
              └───────HTTP────┘
```

## 🖥️ El servidor

El **servidor** escucha las peticiones HTTP de los clientes y las procesa.

Los puertos habituales son:

* **Puerto 80** → HTTP
* **Puerto 443** → HTTPS

El servidor recibe una petición, la interpreta y devuelve una respuesta al cliente.

## 💻 El cliente

El **cliente** es el dispositivo o aplicación que realiza la petición al servidor.

Por ejemplo, cuando un usuario introduce una dirección web en el navegador:

```text
Cliente (navegador)
        │
        │  Petición HTTP
        ▼
Servidor web
        │
        │  Respuesta HTTP
        ▼
Cliente (navegador)
```

El navegador recibe la respuesta del servidor y **renderiza** el contenido para mostrárselo al usuario.

---

# 🐳 COMANDOS UTILIZADOS

## Docker

### `docker ps -a`

Muestra todos los contenedores Docker, independientemente de su estado:

* Contenedores en ejecución.
* Contenedores detenidos.
* Contenedores que han finalizado.
* Contenedores que presentan errores.

```bash
docker ps -a
```

---

### `docker start <nombre_contenedor>`

Inicia un contenedor que se encuentra detenido.

```bash
docker start nombre_contenedor
```

---

### `docker stop <nombre_contenedor>`

Detiene un contenedor que se encuentra en ejecución.

```bash
docker stop nombre_contenedor
```

---

### `docker restart <nombre_contenedor>`

Reinicia un contenedor.

```bash
docker restart nombre_contenedor
```

---

### `docker exec -ti <nombre_contenedor> /bin/bash`

Permite entrar directamente en un contenedor y abrir una terminal `bash`.

```bash
docker exec -ti apache-dwes /bin/bash
```

Una vez dentro del contenedor podemos ejecutar comandos como si estuviéramos trabajando directamente en su sistema.

---

# 🔌 Netcat (`nc`)

`nc` (**Netcat**) es una herramienta que permite establecer conexiones de red mediante la terminal. Puede utilizarse para crear conexiones TCP, escuchar puertos y realizar pruebas de comunicación.

## Escuchar en un puerto

```bash
nc -4l 8000
```

Este comando hace que `nc` escuche conexiones IPv4 en el **puerto 8000**.

Puede utilizarse para crear un pequeño servidor de pruebas que espere conexiones.

---

## Conectarse a un puerto

```bash
nc -4t localhost 8000
```

Permite conectarse mediante IPv4 al puerto `8000` de `localhost`.

Esto puede utilizarse para establecer una comunicación entre dos terminales, incluso para crear un pequeño **chat** entre dos máquinas conectadas a la red.

---

## Realizar una petición HTTP manual

```bash
nc -4tC www.google.es 80
```

Permite establecer una conexión TCP con el puerto **80** de `www.google.es`.

Una vez establecida la conexión, podemos escribir manualmente una petición HTTP, por ejemplo:

```http
GET / HTTP/1.1
Host: www.google.es

```

La línea en blanco final es importante porque indica el final de las cabeceras de la petición.

---

# 🌐 `curl`

`curl` es una herramienta de línea de comandos que permite realizar peticiones a servidores y consultar recursos mediante diferentes protocolos.

```bash
curl http://www.google.es/
```

En este caso, `curl` realiza una petición HTTP al servidor indicado y muestra la respuesta en la terminal.

---

# ⚙️ Módulos de Apache

### `a2enmod cgi`

Activa el módulo **CGI** de Apache.

```bash
a2enmod cgi
```

CGI (**Common Gateway Interface**) permite que un servidor web ejecute programas o scripts para generar contenido dinámico.

---

### `exit`

Permite salir de una sesión de terminal o del contenedor en el que nos encontramos.

```bash
exit
```

---

# 📡 DESCOMPONER UNA CONEXIÓN HTTP

Una petición HTTP está formada por diferentes partes.

Ejemplo:

```http
GET / HTTP/1.1
Host: localhost:8000
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:152.0) Gecko/20100101 Firefox/152.0

```

Podemos dividirla en:

1. **Línea de petición**
2. **Cabeceras**
3. **Línea en blanco**
4. **Cuerpo** *(cuando existe)*

---

## 1. Línea de petición

```http
GET / HTTP/1.1
```

Esta es la **línea de petición**.

Está formada por:

```text
GET     /       HTTP/1.1
│       │          │
│       │          └── Versión de HTTP
│       └───────────── Recurso solicitado
└───────────────────── Método HTTP
```

### `GET`

Indica que el cliente quiere **obtener un recurso**.

### `/`

Representa el recurso solicitado. En este caso, `/` hace referencia a la raíz del servidor.

### `HTTP/1.1`

Indica la versión del protocolo HTTP utilizada.

---

## 2. Cabeceras

Por ejemplo:

```http
Host: localhost:8000
```

La cabecera `Host` indica el **servidor y puerto** al que se dirige la petición.

Otro ejemplo:

```http
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:152.0) Gecko/20100101 Firefox/152.0
```

La cabecera `User-Agent` proporciona información sobre el **cliente que realiza la petición**, normalmente el navegador y algunos datos sobre su plataforma.

> 💡 Las cabeceras proporcionan información adicional necesaria para que el servidor pueda interpretar correctamente la petición.

---

## 3. Línea en blanco

Después de las cabeceras existe una **línea en blanco**:

```http
GET / HTTP/1.1
Host: localhost:8000
User-Agent: Mozilla/5.0

```

Esta línea indica que han terminado las cabeceras.

Si la petición contiene un cuerpo, este aparecerá después de esta línea.

---

## 4. Cuerpo

Una petición HTTP **puede tener un cuerpo**, aunque no todas las peticiones lo utilizan.

Por ejemplo, una petición `POST` puede enviar información al servidor:

```http
POST /login HTTP/1.1
Host: localhost:8000
Content-Type: application/x-www-form-urlencoded
Content-Length: 27

usuario=Ruvik&password=123
```

En este caso:

```text
Petición
   │
   ├── Línea de petición
   │
   ├── Cabeceras
   │
   ├── Línea en blanco
   │
   └── Cuerpo
```

---

# 🧪 D1 - UD1 — «Rompiendo el hielo»

La práctica realizada hoy ha sido la primera práctica del año:

> **D1 - UD1: «Rompiendo el hielo»**

El objetivo principal ha sido comenzar a familiarizarnos con las **peticiones HTTP** y comprender qué información contienen.

Durante la práctica hemos trabajado principalmente con:

* Peticiones HTTP.
* Cabeceras HTTP.
* Métodos HTTP.
* Conexiones mediante `nc`.
* Servidores Apache.
* Scripts en un servidor web.
* Ejecución de scripts mediante CGI.
* Contenedores Docker.

---

## 🔍 Análisis de las cabeceras

Hemos observado las diferentes cabeceras que aparecen en una petición HTTP y hemos analizado qué información proporciona cada una.

Por ejemplo:

```http
Host: localhost:8000
```

Permite identificar el servidor al que se dirige la petición.

Y:

```http
User-Agent: Mozilla/5.0 ...
```

Permite conocer información sobre el cliente que está realizando la petición.

La idea principal ha sido **desglosar una petición HTTP y comprender qué significa cada una de sus partes**.

---

# 🐚 Scripts y Apache

También hemos visto cómo trabajar con **scripts desde la terminal** y cómo funcionan los scripts ejecutados por un servidor **Apache**.

Para ello:

1. Hemos iniciado un servidor Apache.
2. Hemos configurado el módulo necesario.
3. Hemos trabajado con scripts.
4. Hemos ejecutado los scripts a través del servidor.
5. Hemos observado la respuesta generada.

Esto permite comprender mejor la relación entre:

```text
Cliente
   │
   │ HTTP
   ▼
Apache
   │
   │ Ejecuta script
   ▼
Script / CGI
   │
   │ Genera respuesta
   ▼
Apache
   │
   │ HTTP
   ▼
Cliente
```

---

# 📝 RESUMEN DEL DÍA

Hoy ha sido una sesión relativamente tranquila y ha servido principalmente como **primera toma de contacto con el desarrollo web y HTTP**.

Hemos realizado la primera práctica del curso, **D1 - UD1 «Rompiendo el hielo»**, centrada principalmente en comprender las peticiones HTTP y analizar las cabeceras que contienen.

También hemos trabajado desde la terminal con `nc`, hemos visto cómo funcionan los **scripts en un servidor Apache** y hemos puesto en funcionamiento un servidor Apache para poder ejecutarlos.

### 🧠 Conceptos clave

```text
HTTP
├── Cliente
├── Servidor
├── Petición
│   ├── Línea de petición
│   ├── Cabeceras
│   ├── Línea en blanco
│   └── Cuerpo
│
└── Respuesta
```

> 💡 **Idea fundamental del día:** para comprender el desarrollo web es importante entender qué ocurre realmente detrás del navegador. Una página web comienza, en esencia, con una comunicación entre un **cliente y un servidor** mediante protocolos como HTTP.

---

**Relacionado:** [[Bitacora-dia-tres]]
:::
