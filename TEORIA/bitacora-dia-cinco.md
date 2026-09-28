# 📚 CONCEPTOS DE LAS PRESENTACIONES

## 🖥️ CLI

**CLI (Command-Line Interface)** significa **interfaz de línea de comandos**.

Permite interactuar con un sistema mediante comandos escritos en una terminal, en lugar de utilizar una interfaz gráfica.

```text
Usuario
   │
   │ Comando
   ▼
Terminal / CLI
   │
   ▼
Sistema operativo / Aplicación
```

Ejemplos:

```bash
ls
cd proyecto
npm install
git status
```

---

## 🔄 Hot Reload

**Hot Reload** es una característica de algunas herramientas de desarrollo que permite aplicar cambios en el código mientras la aplicación está ejecutándose, sin necesidad de reiniciarla completamente.

Esto agiliza el desarrollo porque podemos modificar el código y observar los cambios casi inmediatamente.

```text
Modificar código
      │
      ▼
Hot Reload
      │
      ▼
Aplicación actualizada
```

> 💡 **Idea clave:** Hot Reload permite reducir el tiempo entre realizar un cambio y comprobar su resultado.

---

# ☕ CONTINUACIÓN DE LAS PRESENTACIONES DE COMPAÑEROS

# ♨️ JAVA

Java es un lenguaje de programación ampliamente utilizado en el desarrollo de aplicaciones empresariales y aplicaciones web.

En el desarrollo web basado en Java existen diferentes tecnologías y especificaciones.

---

## 🧩 Java Servlets y JSP

### Java Servlet

Un **Servlet** es un componente Java que se ejecuta en el servidor y permite procesar peticiones HTTP.

Su función principal puede resumirse como:

```text
Petición HTTP
      │
      ▼
Servlet
      │
      ├── Procesamiento
      ├── Lógica de aplicación
      └── Acceso a datos
      │
      ▼
Respuesta HTTP
```

Los Servlets pueden recibir peticiones como:

```text
GET
POST
PUT
DELETE
```

y generar una respuesta para el cliente.

---

### JSP

**JSP (Jakarta Server Pages)** es una tecnología que permite generar contenido dinámico para páginas web.

Permite combinar:

* HTML.
* Expresiones.
* Datos dinámicos.
* Elementos relacionados con Java.

Su objetivo principal está relacionado con la **presentación de información**.

```text
Servlet
   │
   │ Datos
   ▼
JSP
   │
   │ HTML generado
   ▼
Navegador
```

> 💡 Tradicionalmente, los Servlets se han asociado con la lógica de procesamiento y JSP con la presentación. En arquitecturas modernas existen otras alternativas para separar estas responsabilidades.

---

## 📦 Dependencias en Java

Los proyectos Java suelen utilizar gestores de dependencias y construcción como:

* **Maven**
* **Gradle**

Estas herramientas permiten:

* Descargar librerías.
* Gestionar versiones.
* Resolver dependencias.
* Compilar el proyecto.
* Ejecutar tareas automatizadas.
* Gestionar el ciclo de construcción.

---

## 🧰 JDK

Para desarrollar aplicaciones Java necesitamos un **JDK (Java Development Kit)**.

El JDK incluye las herramientas necesarias para desarrollar y compilar aplicaciones Java.

```text
JDK
├── Compilador
├── Herramientas de desarrollo
├── Bibliotecas
└── Entorno necesario para desarrollar Java
```

---

# 🖼️ JAKARTA SERVER FACES

**Jakarta Server Faces (JSF)** es una tecnología de Jakarta EE orientada al desarrollo de **interfaces de usuario web**.

Permite desarrollar interfaces basadas en componentes reutilizables.

Puede trabajar con tecnologías de presentación como:

* XHTML.
* HTML.
* CSS.
* JavaScript.

Una aplicación JSF utiliza páginas Facelets para definir las vistas.

```text
Java
  │
  ▼
Jakarta Server Faces
  │
  ▼
Facelets / XHTML
  │
  ▼
HTML + CSS + JavaScript
  │
  ▼
Navegador
```

---

# 🏢 J2EE / JAKARTA EE

**J2EE** fue el nombre utilizado históricamente para la plataforma empresarial de Java.

Posteriormente evolucionó a:

* Java EE
* Jakarta EE

> ⚠️ **Importante:** J2EE/Java EE/Jakarta EE **no son lenguajes de programación**. Son plataformas y especificaciones orientadas al desarrollo de aplicaciones empresariales.

Jakarta EE incluye especificaciones para diferentes necesidades, como:

* Aplicaciones web.
* APIs.
* Persistencia.
* Inyección de dependencias.
* Seguridad.
* Transacciones.
* Comunicación entre componentes.

Los proyectos pueden utilizar herramientas como **Maven** o **Gradle** para gestionar su construcción y dependencias.

---

# 🧩 EJB

**EJB (Enterprise JavaBeans)** es una tecnología de componentes del lado del servidor utilizada históricamente en aplicaciones empresariales Java.

Los EJB proporcionan servicios que permiten evitar implementar desde cero determinadas funcionalidades complejas.

Entre sus características se encuentran:

* Gestión de transacciones.
* Seguridad.
* Gestión de concurrencia.
* Inyección de dependencias.
* Ejecución controlada por el servidor.

Su configuración puede apoyarse en **anotaciones**.

---

## 🛠️ IDEs utilizados con Java

Algunos de los IDEs más utilizados para desarrollar aplicaciones Java son:

* **IntelliJ IDEA**
* **Eclipse**
* **Visual Studio Code** con extensiones adecuadas.

---

# 🆆 GENERADORES DE SITIOS ESTÁTICOS

Los **generadores de sitios estáticos (SSG, Static Site Generators)** permiten crear páginas web generando previamente los archivos que posteriormente serán servidos al usuario.

En lugar de generar la página dinámicamente en cada petición, el contenido se genera durante el proceso de construcción.

```text
Contenido
   │
   ▼
Generador estático
   │
   ▼
Archivos HTML / CSS / JS
   │
   ▼
Servidor web
   │
   ▼
Usuario
```

## ⚡ Ventajas

Al no necesitar ejecutar código del servidor para generar cada página:

* El consumo de recursos puede ser bajo.
* Las páginas pueden servirse rápidamente.
* La arquitectura puede ser sencilla.
* No es necesario utilizar una base de datos para el contenido estático.
* Pueden desplegarse fácilmente en muchos servicios de hosting.

---

## 🧑‍💻 Desarrollo

No existe un IDE obligatorio para trabajar con generadores de sitios estáticos.

Algunos editores habituales son:

* **Visual Studio Code**
* **WebStorm**
* **Sublime Text**

El resultado final suele estar compuesto por archivos estáticos:

```text
proyecto/
├── index.html
├── css/
│   └── style.css
├── js/
│   └── script.js
└── images/
```

> 💡 **Idea clave:** el generador hace el trabajo de producir los archivos antes de que el usuario realice la petición.

---

# 🌐 HTTP Y EL ESTADO

HTTP es un protocolo **stateless (sin estado)**.

Esto significa que, por sí misma, una petición HTTP no mantiene automáticamente información sobre las peticiones anteriores.

Por ejemplo:

```text
Petición 1 → Servidor
Petición 2 → Servidor
Petición 3 → Servidor
```

El servidor no obtiene automáticamente de HTTP la información necesaria para saber que las tres peticiones pertenecen al mismo usuario.

Sin embargo, existen mecanismos que permiten mantener el estado de una sesión, como:

* Cookies.
* Sesiones.
* Tokens.
* Cabeceras HTTP.
* Almacenamiento del lado del cliente.

```text
HTTP
 │
 └── Stateless
       │
       ├── Cookies
       ├── Sesiones
       └── Tokens
             ↓
       Permiten mantener
       información de estado
```

---

# 🐹 LENGUAJE GO

**Go (Golang)** es un lenguaje de programación de código abierto desarrollado originalmente por ingenieros de Google.

Fue presentado públicamente en **2009**.

Se caracteriza por:

* Ser compilado.
* Tener tipado estático.
* Gestión automática de memoria mediante recolector de basura.
* Soporte integrado para concurrencia.
* Sintaxis relativamente sencilla.
* Buen rendimiento.

---

## ⚙️ Concurrencia

Una de las características destacadas de Go es su soporte para la concurrencia mediante **goroutines** y **channels**.

```text
Programa
   │
   ├── Goroutine 1
   │
   ├── Goroutine 2
   │
   └── Goroutine 3
```

Esto facilita la creación de aplicaciones capaces de realizar múltiples tareas concurrentemente.

---

## 🛠️ Herramientas

Para desarrollar con Go necesitamos instalar el **Go SDK**.

También podemos utilizar:

* Visual Studio Code.
* Extensiones para Go.
* Git.
* Otros IDEs compatibles.

Los requisitos concretos dependen de la versión de Go y del sistema operativo utilizado.

---

# 🟢 NODE.JS

**Node.js** es un entorno de ejecución que permite ejecutar **JavaScript fuera del navegador**, especialmente en el lado del servidor.

Está basado en el motor **V8 de Google Chrome**.

```text
JavaScript
     │
     ▼
  Node.js
     │
     ▼
Servidor
```

Esto permite utilizar JavaScript para desarrollar:

* APIs.
* Servidores web.
* Aplicaciones en tiempo real.
* Herramientas de línea de comandos.
* Servicios backend.
* Aplicaciones que utilizan TypeScript.

---

## 📦 npm

Node.js se utiliza habitualmente junto con **npm (Node Package Manager)** para gestionar paquetes y dependencias.

```bash
npm install
```

Este comando permite instalar las dependencias definidas en el proyecto.

También podemos utilizar:

```bash
npm install nombre-paquete
```

para instalar un paquete concreto.

---

## 🔄 Comunicación en tiempo real

Node.js resulta especialmente útil para aplicaciones que necesitan gestionar muchas conexiones simultáneas y comunicación en tiempo real.

Por ejemplo:

* Chats.
* Aplicaciones colaborativas.
* Juegos online.
* Sistemas de notificaciones.
* Servicios de streaming de datos.

Puede trabajar con tecnologías como **WebSockets** para mantener una comunicación bidireccional entre cliente y servidor.

```text
Cliente ◄──────────────► Servidor Node.js
          conexión
          persistente
```

---

## 🎥 Streaming y procesamiento por fragmentos

En aplicaciones de streaming, los datos pueden procesarse y transmitirse progresivamente en lugar de esperar a tener todo el archivo disponible.

Los datos pueden dividirse en **chunks (fragmentos)**:

```text
Archivo
   │
   ├── Chunk 1
   ├── Chunk 2
   ├── Chunk 3
   ├── Chunk 4
   └── ...
```

Esto permite comenzar a procesar o reproducir información antes de haber recibido el archivo completo.

> 💡 **Importante:** Node.js puede utilizarse para servicios relacionados con streaming, pero el funcionamiento de una plataforma de vídeo completa depende de muchas otras tecnologías y componentes.

---

## 🌍 Empresas que utilizan Node.js

Node.js ha sido utilizado por empresas y plataformas como:

* PayPal.
* Netflix.
* LinkedIn.
* Reddit.
* eBay.

El uso concreto puede variar entre servicios y componentes de cada plataforma.

---

# 🪶 APACHE

**Apache HTTP Server**, también conocido como **Apache httpd**, es uno de los servidores web más conocidos y utilizados históricamente.

Antes de Apache existieron otros servidores web, como el servidor del **NCSA (National Center for Supercomputing Applications)**.

Apache evolucionó a partir de los primeros servidores web y se convirtió en uno de los servidores HTTP más importantes de Internet.

```text
Navegador
    │
    │ HTTP / HTTPS
    ▼
Apache HTTP Server
    │
    ▼
Contenido / Aplicación
    │
    ▼
Respuesta
```

---

# 🧩 MVC

**MVC (Model-View-Controller)** es un patrón arquitectónico que separa una aplicación en tres responsabilidades principales:

```text
              ┌─────────────┐
              │     MVC     │
              └──────┬──────┘
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
     MODEL        VIEW       CONTROLLER
        │            │            │
        ▼            ▼            ▼
      Datos      Interfaz      Lógica
        │        HTML/CSS/JS       │
        │                          │
        └───────────┬──────────────┘
                    ▼
                 Usuario
```

## 🗄️ Model — Modelo

El **Modelo** representa los datos y la lógica relacionada con ellos.

Puede comunicarse con una base de datos.

```text
Modelo
  │
  ▼
Base de datos
```

---

## 🎨 View — Vista

La **Vista** se encarga de presentar la información al usuario.

Puede utilizar tecnologías como:

* HTML.
* CSS.
* JavaScript.

```text
Datos
  │
  ▼
Vista
  │
  ▼
Usuario
```

---

## ⚙️ Controller — Controlador

El **Controlador** recibe las peticiones del usuario y coordina la lógica necesaria para obtener una respuesta.

```text
Usuario
   │
   │ Petición
   ▼
Controller
   │
   ├──────► Model ──────► Base de datos
   │
   ▼
View
   │
   ▼
Usuario
```

### 🧠 Resumen MVC

| Componente     | Responsabilidad                                   |
| -------------- | ------------------------------------------------- |
| **Model**      | Gestiona datos y lógica relacionada con ellos.    |
| **View**       | Presenta la información al usuario.               |
| **Controller** | Gestiona las peticiones y coordina la aplicación. |

> 💡 **Idea clave:** MVC busca separar las responsabilidades de una aplicación para facilitar su organización, mantenimiento y evolución.

---

# 🔑 CONCEPTOS CLAVE PARA RECORDAR

> **CLI** → interfaz de línea de comandos.
>
> **Hot Reload** → permite aplicar cambios durante el desarrollo sin reiniciar completamente la aplicación.
>
> **Servlet** → componente Java del lado del servidor que procesa peticiones.
>
> **JSP** → tecnología Java orientada a generar contenido web dinámico.
>
> **Jakarta EE** → plataforma de especificaciones para aplicaciones empresariales Java.
>
> **EJB** → componentes empresariales del lado del servidor dentro del ecosistema Jakarta EE.
>
> **SSG** → generador que produce archivos estáticos antes de servirlos.
>
> **HTTP Stateless** → HTTP no mantiene estado de una petición a otra por sí mismo.
>
> **Go** → lenguaje compilado y tipado estáticamente con soporte para concurrencia.
>
> **Node.js** → entorno que permite ejecutar JavaScript fuera del navegador.
>
> **npm** → gestor de paquetes utilizado habitualmente con Node.js.
>
> **Apache httpd** → servidor HTTP de código abierto.
>
> **MVC** → patrón que separa modelo, vista y controlador.

---

**Relacionado:** [[bitacora-dia-cuatro]]
