# 👨‍💻 PRESENTACIONES DE COMPAÑEROS

En esta sesión hemos visto diferentes tecnologías y lenguajes utilizados para el **desarrollo web**, especialmente en el lado del servidor.

---

# 💎 RUBY

Ruby es un **lenguaje de programación interpretado**, muy utilizado históricamente para el desarrollo web mediante frameworks como **Ruby on Rails**.

## 🧩 Conceptos principales

### MVC

Ruby on Rails utiliza el patrón arquitectónico **MVC (Model-View-Controller)**, que permite separar una aplicación en diferentes responsabilidades:

```text
MVC
│
├── Model
│   └── Datos y lógica relacionada con ellos
│
├── View
│   └── Interfaz y presentación
│
└── Controller
    └── Recibe peticiones y coordina la aplicación
```

La separación en capas facilita el mantenimiento y organización del software.

---

## 🗄️ ORM

**ORM (Object-Relational Mapping)** permite trabajar con una base de datos mediante objetos del lenguaje de programación, en lugar de tener que escribir directamente todas las consultas SQL.

```text
Código
  │
  ▼
Objetos
  │
  ▼
ORM
  │
  ▼
Base de datos
```

Esto permite abstraer parte de la comunicación con la base de datos.

---

## 🔄 Middleware

Un **middleware** es un componente que se ejecuta durante el procesamiento de una petición y puede actuar entre el cliente y la aplicación.

Puede utilizarse, por ejemplo, para:

* Autenticación.
* Registro de peticiones.
* Control de acceso.
* Modificación de peticiones o respuestas.
* Gestión de errores.

```text
Cliente
   │
   ▼
Middleware
   │
   ▼
Aplicación
   │
   ▼
Respuesta
```

---

## 📦 Dependencias

Las aplicaciones suelen depender de diferentes **librerías y paquetes externos**.

Existen herramientas que permiten:

* Descargar dependencias.
* Gestionar versiones.
* Comprobar compatibilidades.
* Actualizar paquetes.
* Mantener un registro de las dependencias del proyecto.

En Ruby se utiliza principalmente **RubyGems** y **Bundler** para la gestión de paquetes y dependencias.

---

## 🛠️ Desarrollo vs. Producción

Es importante diferenciar los entornos:

| Desarrollo                                    | Producción                                          |
| --------------------------------------------- | --------------------------------------------------- |
| Se escribe y prueba el código                 | Se ejecuta la aplicación para los usuarios          |
| Se utilizan IDEs y herramientas de desarrollo | Se utilizan servidores y herramientas de despliegue |
| Se realizan pruebas y depuración              | Se priorizan estabilidad, seguridad y rendimiento   |
| Puede utilizarse `debug`                      | Normalmente se desactiva la depuración              |

---

# 🐘 PHP

**PHP** es un lenguaje de programación utilizado principalmente para desarrollar aplicaciones del lado del servidor.

El servidor ejecuta el código PHP y genera una respuesta que posteriormente se envía al cliente.

```text
Cliente
   │
   │ Petición HTTP
   ▼
Servidor web
   │
   ▼
PHP
   │
   │ Ejecuta el código
   ▼
Respuesta
   │
   ▼
Cliente
```

## 🧰 Herramientas

Para desarrollar con PHP podemos utilizar:

* **Visual Studio Code**
* **PhpStorm**
* Otros editores o IDEs compatibles con PHP.

### PhpStorm

**PhpStorm** es un IDE especializado en desarrollo con PHP.

Puede proporcionar herramientas para:

* Autocompletado.
* Depuración.
* Gestión de proyectos.
* Integración con frameworks.
* Gestión de dependencias.

---

## 📦 Composer

PHP utiliza **Composer** como sistema de gestión de dependencias.

Permite:

* Instalar librerías.
* Gestionar versiones.
* Resolver dependencias.
* Mantener las dependencias del proyecto.

```text
Proyecto PHP
     │
     ▼
 Composer
     │
     ├── Librería A
     ├── Librería B
     └── Librería C
```

---

## 🐳 Entornos de desarrollo

PHP puede ejecutarse en diferentes entornos.

Algunas opciones habituales son:

* **Docker**
* **XAMPP**
* Apache
* Nginx

Además, PHP puede utilizar diferentes sistemas gestores de bases de datos, como **MySQL** o **MariaDB**.

---

## ⚙️ Ejecución de PHP

Para ejecutar una aplicación PHP mediante una arquitectura tradicional necesitamos:

1. Un cliente que realice una petición.
2. Un servidor web, como Apache o Nginx.
3. Un entorno capaz de ejecutar PHP.
4. El código PHP.
5. Una respuesta que pueda enviarse al cliente.

```text
Navegador
    │
    │ HTTP
    ▼
Apache / Nginx
    │
    ▼
PHP
    │
    │ Ejecuta código
    ▼
HTML / JSON
    │
    ▼
Navegador
```

---

## 📝 Sintaxis básica

Un bloque de código PHP se escribe utilizando las etiquetas:

```php
<?php

echo "Hola, mundo";

?>
```

Actualmente es habitual omitir `?>` cuando el archivo contiene únicamente código PHP.

---

## 🌐 Frameworks

PHP dispone de numerosos frameworks.

Uno de los más conocidos es **Laravel**, que proporciona herramientas para desarrollar aplicaciones web estructuradas.

Ejemplo de una ruta en Laravel:

```php
// routes/web.php

Route::get('/', function () {
    return view('welcome');
});
```

Esta ruta indica que, cuando se recibe una petición `GET` a `/`, Laravel devuelve la vista `welcome`.

---

## 🌍 Ejemplos de proyectos que utilizan PHP

PHP ha tenido una presencia muy importante en la Web.

Algunos proyectos y sitios conocidos que han utilizado PHP en diferentes etapas son:

* **Facebook**
* **Wikipedia**
* **WordPress**
* **Tumblr**
* **Yahoo!**

---

# 🧑‍🏫 RECALCADO DEL PROFESOR

Una diferencia importante entre **JavaScript ejecutado en el navegador** y **PHP ejecutado en el servidor** es dónde se procesa el código.

### JavaScript del lado del cliente

```text
Servidor
   │
   │ Envía HTML + JavaScript
   ▼
Navegador
   │
   ▼
Ejecuta JavaScript
```

El código JavaScript enviado al navegador puede ser visible para el usuario.

### PHP del lado del servidor

```text
Navegador
   │
   │ Petición
   ▼
Servidor
   │
   ▼
PHP
   │
   │ Ejecuta código
   ▼
Respuesta
   │
   ▼
Navegador
```

El navegador recibe la **respuesta generada**, pero no necesita recibir el código PHP utilizado para generarla.

> 💡 **Idea clave:** PHP se ejecuta en el servidor; JavaScript puede ejecutarse en el navegador.

---

## ⚠️ CGI

**CGI (Common Gateway Interface)** es una tecnología tradicional que permite ejecutar programas mediante un servidor web.

Su utilización para aplicaciones web modernas puede presentar problemas de **rendimiento y escalabilidad**, ya que el modelo tradicional puede implicar crear procesos para atender las peticiones.

PHP dispone de mecanismos de ejecución más adecuados para aplicaciones web modernas, como **PHP-FPM**.

---

# 🐍 PYTHON

Python es un lenguaje de programación ampliamente utilizado en desarrollo web, automatización, ciencia de datos, inteligencia artificial y otros campos.

Para desarrollo web existen diferentes frameworks y herramientas.

---

# 1. 🍶 FLASK

**Flask** es un framework web ligero para Python.

Es especialmente útil para crear:

* Aplicaciones web pequeñas y medianas.
* APIs.
* Prototipos.
* Servicios web.

## 🛠️ Herramientas

Algunos IDEs y editores utilizados para Python son:

* **PyCharm**
* **Visual Studio Code**

Flask puede instalarse como dependencia mediante `pip`.

---

## 📝 Ejemplo con Flask

```python
from flask import Flask

app = Flask(__name__)


@app.route("/")
def home():
    return "¡Hola, mundo con Flask!"


if __name__ == "__main__":
    app.run(debug=True)
```

### 🔍 Funcionamiento

```text
Cliente
   │
   │ GET /
   ▼
Flask
   │
   ▼
home()
   │
   ▼
"¡Hola, mundo con Flask!"
   │
   ▼
Cliente
```

La función `home()` se ejecuta cuando se recibe una petición `GET` a la ruta `/`.

---

# 2. ⚡ FASTAPI

**FastAPI** es un framework moderno de Python orientado especialmente al desarrollo de **APIs**.

Entre sus características destacan:

* Validación automática de datos.
* Generación automática de documentación.
* Uso de anotaciones de tipos de Python.
* Soporte para programación asíncrona.
* Buen rendimiento.

FastAPI se utiliza habitualmente junto con un servidor ASGI como **Uvicorn**.

---

## 📦 Dependencias

Para utilizar FastAPI necesitamos instalar sus dependencias correspondientes.

Una aplicación puede ejecutarse, por ejemplo, mediante:

```text
FastAPI
   │
   ▼
Uvicorn
   │
   ▼
Servidor ASGI
```

La versión de Python compatible depende de la versión de FastAPI utilizada; por tanto, conviene comprobar siempre los requisitos de la versión concreta del proyecto.

---

## 📝 Ejemplo con FastAPI

```python
from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def leer_raiz():
    return {"mensaje": "¡Hola, mundo!"}


@app.get("/items/{item_id}")
def leer_item(item_id: int, q: str | None = None):
    return {"item_id": item_id, "q": q}
```

### 🔍 Funcionamiento

La ruta:

```text
GET /
```

devuelve:

```json
{
  "mensaje": "¡Hola, mundo!"
}
```

Mientras que:

```text
GET /items/10
```

puede devolver:

```json
{
  "item_id": 10,
  "q": null
}
```

FastAPI utiliza las anotaciones de tipos para ayudar a validar los parámetros.

---

# 3. 🦄 DJANGO

**Django** es un framework web de alto nivel para Python.

Está especialmente orientado a aplicaciones completas que necesitan muchas funcionalidades integradas.

Incluye herramientas para:

* Gestión de usuarios.
* Autenticación.
* Seguridad.
* Bases de datos.
* Administración.
* Formularios.
* Gestión de URLs.
* Plantillas.
* ORM.

Es habitual utilizar Django en aplicaciones grandes y proyectos que requieren una estructura definida.

---

## 🧩 Arquitectura

Django utiliza una arquitectura basada en el patrón **MVT (Model-View-Template)**:

```text
MVT
│
├── Model
│   └── Datos y acceso a la base de datos
│
├── View
│   └── Lógica que procesa las peticiones
│
└── Template
    └── Presentación de los datos
```

---

## 🌐 Usos habituales

Django puede utilizarse para desarrollar:

* Redes sociales.
* Plataformas de contenido.
* Noticias.
* Tiendas online.
* Aplicaciones empresariales.
* APIs y servicios web.

---

## 📝 Ejemplo de modelo Django

```python
from django.db import models


class Articulo(models.Model):
    titulo = models.CharField(max_length=100)
    contenido = models.TextField()
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.titulo
```

Este modelo representa un **artículo** almacenado en la base de datos.

Contiene:

| Campo            | Tipo            | Función                             |
| ---------------- | --------------- | ----------------------------------- |
| `titulo`         | `CharField`     | Almacena un texto corto.            |
| `contenido`      | `TextField`     | Almacena texto más extenso.         |
| `fecha_creacion` | `DateTimeField` | Guarda la fecha y hora de creación. |

---

# #️⃣ C# Y .NET

**C#** es un lenguaje de programación desarrollado por Microsoft.

Se caracteriza, entre otras cosas, por:

* Tipado estático.
* Programación orientada a objetos.
* Amplio sistema de tipos.
* Herramientas de desarrollo avanzadas.
* Integración con el ecosistema .NET.

---

# 🪟 .NET Y ASP.NET CORE

**.NET** es una plataforma de desarrollo multiplataforma de Microsoft.

Para el desarrollo web se utiliza principalmente **ASP.NET Core**.

```text
C#
 │
 ▼
.NET
 │
 ▼
ASP.NET Core
 │
 ▼
Aplicación web
```

---

## 🧰 Requisitos y herramientas

Para desarrollar aplicaciones con .NET normalmente necesitamos:

* **.NET SDK**
* Un sistema operativo compatible.
* Un editor o IDE.
* Herramientas de línea de comandos (**CLI**) de .NET.

---

## 🖥️ Servidor web

ASP.NET Core puede ejecutarse utilizando **Kestrel**, que es el servidor web multiplataforma integrado en ASP.NET Core.

También puede utilizarse detrás de un servidor proxy inverso como:

* Nginx
* Apache
* IIS

Una arquitectura habitual sería:

```text
Usuario
   │
   │ HTTP / HTTPS
   ▼
Nginx / Apache / IIS
   │
   ▼
Kestrel
   │
   ▼
ASP.NET Core
   │
   ▼
Respuesta
```

---

# 🧑‍💻 IDEs

Para desarrollar con C# y .NET podemos utilizar diferentes herramientas.

## Visual Studio

**Visual Studio** es el IDE principal de Microsoft para el desarrollo con C# y .NET.

Ofrece numerosas herramientas para proyectos grandes, como:

* Depuración.
* Autocompletado.
* Gestión de proyectos.
* Diseñadores.
* Herramientas de pruebas.
* Integración con Git.
* Diagnóstico y análisis de código.

## Visual Studio Code

**Visual Studio Code** es un editor más ligero y extensible.

Mediante extensiones puede utilizarse para desarrollar aplicaciones en C# y .NET.

```text
Visual Studio
   │
   └── IDE completo

Visual Studio Code
   │
   └── Editor extensible
```

---

# 📝 Ejemplo básico de ASP.NET Core

Una aplicación mínima puede comenzar con una estructura similar a:

```csharp
var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

app.MapGet("/", () => "¡Hola, mundo!");

app.Run();
```

El flujo básico es:

```text
Petición HTTP
      │
      ▼
ASP.NET Core
      │
      ▼
MapGet("/")
      │
      ▼
"¡Hola, mundo!"
      │
      ▼
Respuesta HTTP
```

---

# 🌍 EJEMPLOS DE USO DE C# Y .NET

.NET y C# se utilizan en numerosos tipos de aplicaciones y servicios.

Algunos ejemplos conocidos son:

* **Stack Overflow**
* **Microsoft**
* **GoDaddy**
* **MarketWatch**

> ⚠️ El uso de una tecnología puede variar entre diferentes servicios, componentes y etapas de un proyecto. Que una empresa utilice .NET no significa necesariamente que toda su infraestructura esté desarrollada con esta tecnología.

---

# 🧠 COMPARATIVA GENERAL

| Tecnología           | Lenguaje | Framework / Plataforma | Uso habitual               |
| -------------------- | -------- | ---------------------- | -------------------------- |
| 💎 **Ruby**          | Ruby     | Ruby on Rails          | Aplicaciones web           |
| 🐘 **PHP**           | PHP      | Laravel, Symfony, etc. | Aplicaciones web           |
| 🍶 **Flask**         | Python   | Flask                  | Web y APIs                 |
| ⚡ **FastAPI**        | Python   | FastAPI                | APIs y servicios web       |
| 🦄 **Django**        | Python   | Django                 | Aplicaciones web completas |
| #️⃣ **ASP.NET Core** | C#       | .NET                   | Aplicaciones web y APIs    |

---

# 🔗 RELACIÓN ENTRE LAS TECNOLOGÍAS

Aunque los lenguajes y frameworks sean diferentes, el concepto general es muy parecido:

```text
                         CLIENTE
                            │
                            │ HTTP / HTTPS
                            ▼
                     SERVIDOR WEB
                            │
             ┌──────────────┼──────────────┐
             │              │              │
             ▼              ▼              ▼
           PHP            Python           C#
             │              │              │
          Laravel     Flask / Django   ASP.NET Core
             │              │              │
             └──────────────┼──────────────┘
                            │
                            ▼
                       BASE DE DATOS
```

La tecnología cambia, pero el concepto fundamental sigue siendo:

**petición → procesamiento → respuesta**.

---

# 📌 CONCEPTOS CLAVE

> **Ruby** → lenguaje utilizado, entre otros ámbitos, en desarrollo web con Ruby on Rails.
>
> **MVC** → patrón que separa modelo, vista y controlador.
>
> **ORM** → permite trabajar con bases de datos mediante objetos.
>
> **Middleware** → componente que interviene durante el procesamiento de una petición.
>
> **Composer** → gestor de dependencias de PHP.
>
> **Flask** → framework web ligero de Python.
>
> **FastAPI** → framework de Python orientado especialmente a APIs.
>
> **Django** → framework completo de Python para aplicaciones web.
>
> **C#** → lenguaje de programación del ecosistema .NET.
>
> **.NET** → plataforma de desarrollo de Microsoft.
>
> **ASP.NET Core** → framework para desarrollar aplicaciones web y APIs con .NET.
>
> **Kestrel** → servidor web utilizado por ASP.NET Core.

---

**Relacionado:** [[bitacora-dia-cinco]]
