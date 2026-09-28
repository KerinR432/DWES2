# 🌐 CÓMO ES UNA URL

Una **URL (Uniform Resource Locator)** es la dirección que permite localizar un recurso dentro de una red, como una página web, un archivo o un recurso de una aplicación.

Una URL puede dividirse en varias partes:

| Parte          | Ejemplo                                | Significado                                                     |
| -------------- | -------------------------------------- | --------------------------------------------------------------- |
| **Protocolo**  | `https://`                             | Indica el protocolo utilizado para comunicarnos con el recurso. |
| **Host**       | `ejemplo.com`                          | Identifica el servidor o destino al que queremos acceder.       |
| **Puerto**     | `:443`                                 | Indica el puerto utilizado para establecer la conexión.         |
| **Ruta**       | `/ruta/pagina`                         | Indica el recurso concreto que queremos solicitar.              |
| **Parámetros** | `?parametro1=valor1&parametro2=valor2` | Permiten enviar información adicional al servidor.              |
| **Fragmento**  | `#seccion`                             | Identifica una sección concreta dentro del recurso.             |

## 🧩 Ejemplo completo

```text
https://ejemplo.com:443/ruta/pagina?parametro1=valor1&parametro2=valor2#seccion
```

Podemos descomponerlo de la siguiente manera:

```text
https://
   │
   └── Protocolo

ejemplo.com
   │
   └── Host

:443
   │
   └── Puerto

/ruta/pagina
   │
   └── Ruta

?parametro1=valor1&parametro2=valor2
   │
   └── Parámetros

#seccion
   │
   └── Fragmento
```

> 💡 **Idea clave:** una URL indica **dónde está un recurso y cómo acceder a él**.

---

# 🔐 HTTP VS. HTTPS

## ⚠️ HTTP

* Utiliza normalmente el **puerto 80**.
* La comunicación se realiza **sin cifrado**.
* La información puede ser interceptada si no existe otra capa de protección.

```text
HTTP → puerto 80 → sin cifrado
```

## 🔒 HTTPS

* Utiliza normalmente el **puerto 443**.
* Protege la comunicación mediante **TLS**.
* Proporciona **cifrado**, autenticación del servidor e integridad de los datos.

```text
HTTPS → puerto 443 → TLS → comunicación cifrada
```

> ⚠️ **Nota:** SSL es el nombre de una tecnología anterior. Actualmente se utiliza **TLS (Transport Layer Security)**. Por tanto, es más correcto hablar de **HTTPS sobre TLS** que de HTTPS sobre SSL.

### 🧪 Ejemplo con `curl`

```bash
curl https://ejemplo.com
```

`curl` permite realizar una petición HTTP/HTTPS desde la terminal y mostrar la respuesta obtenida.

---

# 🖥️ ¿QUÉ HEMOS APRENDIDO?

## 📄 Páginas estáticas y dinámicas

Una **página estática** es aquella cuyo contenido se encuentra preparado previamente y que, normalmente, el servidor puede enviar directamente al cliente sin tener que ejecutar código para generar el contenido en cada petición.

Ejemplos habituales:

* HTML
* CSS
* Imágenes
* JavaScript estático

Una **página dinámica**, en cambio, puede requerir que el servidor **ejecute código** para generar el contenido que posteriormente enviará al cliente.

```text
PÁGINA ESTÁTICA

Cliente
   │
   │ Solicitud
   ▼
Servidor
   │
   │ Fichero ya preparado
   ▼
Cliente
```

```text
PÁGINA DINÁMICA

Cliente
   │
   │ Solicitud
   ▼
Servidor
   │
   │ Ejecuta código
   ▼
Genera contenido
   │
   ▼
Cliente
```

---

# ⚡ PÁGINAS ESTÁTICAS VS. DINÁMICAS

| Característica               | Página estática       | Página dinámica                  |
| ---------------------------- | --------------------- | -------------------------------- |
| Generación del contenido     | Previamente preparado | Puede generarse en cada petición |
| Procesamiento en el servidor | Bajo                  | Mayor                            |
| Velocidad                    | Generalmente alta     | Puede ser menor                  |
| Complejidad                  | Baja                  | Mayor                            |
| Uso de bases de datos        | No es necesario       | Puede ser necesario              |
| Personalización              | Limitada              | Puede adaptarse al usuario       |
| Ejemplo                      | HTML, CSS, imágenes   | PHP, Python, Java, etc.          |

> 🚀 Una página estática suele ser más rápida porque el servidor puede limitarse a entregar los recursos ya preparados. Una página dinámica necesita realizar procesamiento adicional cuando debe generar contenido.

### ⏱️ Comparación de tiempos

En clase se han utilizado ejemplos de tiempos de respuesta para comparar ambos modelos. Estos valores dependen mucho de la implementación, el hardware, la red y la carga del servidor, por lo que deben entenderse como **ejemplos orientativos**, no como valores universales.

```text
Página estática
     ↓
Fichero preparado → enviar → cliente

Página dinámica
     ↓
Petición → ejecutar código → generar contenido → enviar → cliente
```

---

# 🔄 CONTENIDO DINÁMICO GENERADO PERIÓDICAMENTE

Una página no tiene por qué ser exclusivamente estática o dinámica en todo momento.

Por ejemplo, si necesitamos mostrar la **hora actual**, podemos generar periódicamente un fichero HTML mediante un script:

```text
Script
   │
   │ Cada cierto tiempo
   ▼
Genera HTML
   │
   ▼
Fichero estático actualizado
   │
   ▼
Servidor web
   │
   ▼
Cliente
```

De esta forma, el servidor no tiene que ejecutar el código en **cada petición**.

Esto puede ser útil cuando el contenido cambia con poca frecuencia y queremos mantener las ventajas de servir archivos estáticos.

---

# 🧮 `visitas.sh` Y CONCURRENCIA

Cuando varios usuarios realizan peticiones al mismo tiempo, pueden producirse problemas de **concurrencia** si diferentes procesos intentan modificar simultáneamente un mismo recurso.

Por ejemplo, imaginemos un contador de visitas:

```text
Visitas actuales = 100
```

Dos peticiones llegan prácticamente al mismo tiempo:

```text
Petición A → lee 100
Petición B → lee 100

Petición A → suma 1 → 101
Petición B → suma 1 → 101
```

El resultado esperado sería:

```text
102 visitas
```

pero el resultado obtenido podría ser:

```text
101 visitas
```

Esto ocurre porque ambas peticiones han leído el mismo valor antes de modificarlo.

## 🔒 `visitas-sin-lock`

El problema de un contador **sin mecanismo de bloqueo** es que, cuando se reciben muchas peticiones simultáneamente, varias operaciones pueden solaparse.

Esto puede provocar:

* Pérdida de incrementos.
* Datos incorrectos.
* Condiciones de carrera.
* Resultados diferentes dependiendo del momento en que se ejecuten los procesos.

```text
           ┌─── Petición A ───┐
           │                  │
100 ───────┼──────────────────┼──→ 101
           │                  │
           └─── Petición B ───┘
```

> 🧠 **Idea clave:** cuando varias ejecuciones acceden y modifican un recurso compartido, necesitamos controlar la concurrencia. Los mecanismos de bloqueo (`lock`) permiten evitar determinadas condiciones de carrera.

---

# 🧑‍💻 EJECUCIÓN EN EL CLIENTE VS. SERVIDOR

Es importante distinguir dónde se ejecuta cada parte del código.

## 🌐 JavaScript en el cliente

Un código JavaScript ejecutado en el navegador normalmente se ejecuta **en el lado del cliente**.

```text
Servidor
   │
   │ Envía JavaScript
   ▼
Navegador
   │
   │ Ejecuta JS
   ▼
Usuario
```

Esto significa que el procesamiento realizado por ese código ocurre principalmente en el dispositivo del usuario.

## 🖥️ Código ejecutado en el servidor

Cuando el código se ejecuta en el servidor:

```text
Cliente
   │
   │ Petición
   ▼
Servidor
   │
   │ Ejecuta código
   ▼
Respuesta
   │
   ▼
Cliente
```

El usuario recibe el **resultado de la ejecución**, no necesariamente el código que se ha utilizado para generarlo.

> 💡 **Idea clave:**
> **Cliente → ejecuta código en el navegador.**
> **Servidor → ejecuta código antes de enviar la respuesta.**

---

# 🧰 SIGUIENTE PRÁCTICA

En la siguiente práctica veremos diferentes tecnologías utilizadas para ejecutar código en el lado del servidor.

## ⚙️ CGI

**CGI (Common Gateway Interface)** permite que un servidor web ejecute programas o scripts y utilice su salida como respuesta HTTP.

Históricamente se ha utilizado con diferentes lenguajes, aunque actualmente existen tecnologías y arquitecturas más modernas y eficientes.

El directorio `cgi-bin` se utiliza tradicionalmente para almacenar scripts CGI.

```text
Cliente
   │
   │ HTTP
   ▼
Servidor web
   │
   │ CGI
   ▼
Script
   │
   │ Resultado
   ▼
Servidor web
   │
   │ HTTP
   ▼
Cliente
```

---

# 🧑‍💻 LENGUAJES Y TECNOLOGÍAS DEL LADO DEL SERVIDOR

Existen diferentes lenguajes y frameworks que permiten desarrollar aplicaciones web dinámicas.

## 🐘 PHP

**PHP** es un lenguaje ampliamente utilizado para desarrollar aplicaciones web del lado del servidor.

```text
Cliente
   │
   │ HTTP
   ▼
Servidor PHP
   │
   │ Ejecuta PHP
   ▼
HTML generado
   │
   ▼
Cliente
```

En la práctica veremos cómo **activar PHP y comprobar su funcionamiento**.

---

## ☕ Java

**Java** también se utiliza para desarrollar aplicaciones web.

Entre las tecnologías relacionadas encontramos:

* **Servlets** → componentes Java que pueden procesar peticiones HTTP en un servidor.
* **JSP (JavaServer Pages)** → tecnología que permite generar contenido web dinámico integrando contenido HTML con código Java.

---

## 🐍 Python

Python también se utiliza para desarrollar aplicaciones web.

Cuenta con numerosos frameworks, entre ellos:

* **Django**
* **Flask**
* **FastAPI**

---

## 💎 Ruby

**Ruby** es otro lenguaje utilizado en el desarrollo web.

Uno de sus frameworks más conocidos es:

* **Ruby on Rails**

---

## 🐹 Go

**Go (Golang)** también puede utilizarse para crear servidores y aplicaciones web.

Su biblioteca estándar incluye herramientas para trabajar directamente con HTTP.

---

## 🪟 .NET

En el ecosistema de Microsoft encontramos **.NET**, una plataforma utilizada para desarrollar aplicaciones web y otro tipo de software.

Una de las tecnologías principales para aplicaciones web es:

* **ASP.NET**
* **ASP.NET Core**

---

# 🧠 MAPA GENERAL

```text
                 DESARROLLO WEB
                       │
          ┌────────────┴────────────┐
          │                         │
       CLIENTE                    SERVIDOR
          │                         │
          │                         ├── PHP
          │                         ├── Java
          │                         │    ├── Servlets
          │                         │    └── JSP
          │                         ├── Python
          │                         │    └── Django
          │                         ├── Ruby
          │                         ├── Go
          │                         └── .NET
          │
          └── JavaScript
```

---

# 📅 DÍA

En esta sesión hemos profundizado en el funcionamiento de las **URLs**, la diferencia entre **HTTP y HTTPS** y los conceptos de **páginas estáticas y dinámicas**.

También hemos visto la diferencia entre ejecutar código en el **cliente** y ejecutarlo en el **servidor**, además de introducir el problema de la **concurrencia** mediante el ejemplo de un contador de visitas.

Finalmente, hemos introducido diferentes tecnologías para el desarrollo web del lado del servidor, como **PHP, Java, Python, Ruby, Go y .NET**, que veremos con mayor profundidad en las siguientes prácticas.

---

## 🔑 CONCEPTOS PARA RECORDAR

> **URL** → identifica dónde se encuentra un recurso y cómo acceder a él.
>
> **HTTP** → protocolo de comunicación web, normalmente asociado al puerto `80`.
>
> **HTTPS** → HTTP protegido mediante TLS, normalmente asociado al puerto `443`.
>
> **Página estática** → contenido previamente preparado que puede servirse directamente.
>
> **Página dinámica** → contenido que puede generarse mediante procesamiento en el servidor.
>
> **Cliente** → realiza peticiones y puede ejecutar código en el navegador.
>
> **Servidor** → recibe peticiones, procesa información y genera respuestas.
>
> **CGI** → interfaz tradicional para ejecutar programas mediante un servidor web.
>
> **Concurrencia** → varias ejecuciones pueden acceder simultáneamente a un mismo recurso, provocando condiciones de carrera si no se controlan.
