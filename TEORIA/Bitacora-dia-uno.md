# 🌐 SERVIDOR DE DESARROLLO WEB

## 📚 Contenido de la sesión

Durante esta sesión veremos:

1. **Presentación del módulo**
2. **Repaso de programación**
3. **Preparación de `D1-UD1`**

También estudiaremos qué ocurre en un **servidor web**, el contexto general de la **Web**, sus principales tecnologías y las **bases de datos** que intervienen en las aplicaciones web.

---

# 🔄 REPASO DE PROGRAMACIÓN

## Acceso concurrente

Los ficheros pueden presentar problemas relacionados con el **acceso concurrente**, especialmente cuando varios procesos o hilos intentan acceder o modificar un mismo recurso simultáneamente.

> ⚠️ Es importante tener en cuenta la concurrencia cuando trabajamos con recursos compartidos.

## Programación funcional

La **programación funcional** es un paradigma de programación basado, entre otros conceptos, en el uso de **funciones** para transformar datos.

Un ejemplo sería encadenar diferentes operaciones sobre una colección:

```javascript
alumno.sort().filter()
```

En este caso:

* `sort()` → ordena los elementos.
* `filter()` → filtra los elementos según una condición.
* Las operaciones pueden encadenarse para realizar varias transformaciones sobre los datos.

---

# 🛠️ PREPARACIÓN PRÁCTICA D1-UD1

## 🌍 ¿Qué es la Web?

**World Wide Web (WWW)**, también conocida simplemente como **Web**, es un sistema de información que permite acceder a recursos y documentos interconectados mediante Internet.

La Web surgió **después de Internet** y se apoya en la infraestructura y los protocolos de comunicación que ya existían.

### Internet vs. Web

Es importante diferenciar ambos conceptos:

* **Internet** → infraestructura y red mundial que conecta dispositivos y redes entre sí.
* **Web (WWW)** → uno de los servicios que funciona sobre Internet y que permite acceder a páginas, aplicaciones y recursos mediante tecnologías web.

La comunicación en Internet se sustenta, entre otros elementos, en:

* **Direcciones IP**, que permiten identificar dispositivos dentro de una red.
* **TCP/IP**, conjunto de protocolos fundamentales para la comunicación entre dispositivos.
* **HTTP/HTTPS**, protocolos utilizados principalmente para la comunicación entre clientes y servidores web.

---

## 🔗 Los hipervínculos

Uno de los conceptos fundamentales de la Web son los **hipervínculos**.

Los hipervínculos permiten conectar diferentes recursos entre sí. Gracias a ellos, un usuario puede navegar de un documento o página a otra simplemente siguiendo un enlace.

Esta idea de documentos interconectados es una de las bases fundamentales de la **World Wide Web**.

### Ejemplo

```html
<a href="https://ejemplo.com">Visitar página</a>
```

En este ejemplo, el elemento `<a>` crea un **enlace (hipervínculo)** hacia otro recurso.

---

## 🧩 Tecnologías y conceptos que veremos

Para comprender cómo funciona el desarrollo web, será necesario estudiar diferentes tecnologías y conceptos:

* 🌐 **Web y World Wide Web**
* 🖥️ **Clientes y servidores**
* 📡 **Protocolos de comunicación**
* 🔗 **HTTP y HTTPS**
* 🧭 **URLs y navegación**
* 🧱 **HTML, CSS y JavaScript**
* 🗄️ **Bases de datos**
* ⚙️ **Servidores web**
* 🔄 **Comunicación cliente-servidor**
* 🔐 **Seguridad y autenticación**

> 💡 **Idea clave:** una aplicación web no es únicamente una página que vemos en el navegador. Detrás de ella existe una comunicación entre diferentes componentes, como el cliente, el servidor, los protocolos de red y, en muchos casos, una base de datos.
