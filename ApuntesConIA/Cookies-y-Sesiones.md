# Cookies y Sesiones en Java / Spring Boot
### Apuntes para migrar de formularios encadenados a sesiones

> Basado en los apuntes del profesor (`PDFPROFESOR/Cookies y Session.pdf` y `Sesiones.pdf`) ampliados con explicaciones prácticas.

---

## Índice
1. [El problema: HTTP es "sin estado"](#1-el-problema-http-es-sin-estado)
2. [Cookies (lo más usado y directo)](#2-cookies)
3. [Sesión (datos grandes / seguros)](#3-sesión)
4. [Comparativa rápida](#4-comparativa-rápida)
5. [Curiosidades / casos menos usados](#5-curiosidades--casos-menos-usados)
6. [Cookies en Spring Boot (controlador)](#2-cookies)
7. [La anotación `@SuppressWarnings`](#6-la-anotación-suppresswarnings)
8. [Resumen para migrar tu proyecto](#8-resumen-para-migrar-tu-proyecto)

---

## 1. El problema: HTTP es "sin estado"

HTTP no recuerda nada entre peticiones. Cada petición es independiente: el servidor recibe la petición, responde y **se olvida del cliente**. Por eso necesitamos mecanismos para "recordar" al usuario entre clics. Las dos soluciones principales son **cookies** y **sesiones**.

---

## 2. Cookies

Una cookie es un pequeño trozo de información en formato **clave = valor** que el servidor envía al navegador en la cabecera `Set-Cookie` de la respuesta HTTP. El navegador la guarda y la devuelve en la cabecera `Cookie` de las peticiones siguientes al mismo dominio.

### Atributos importantes de una cookie
- **Nombre**: cómo se identifica.
- **Valor**: el dato a almacenar.
- **Fecha de expiración**: cuándo caduca (si no se pone, es de sesión y se borra al cerrar el navegador).
- **Dominio y ruta**: a qué aplicación pertenece / dónde se envía.

### Ejemplo real (bershka.es)
- `BershkaGenderCategory` → género del cliente.
- `JSESSIONID` → identificador de la sesión en el servidor.
- `BSKGeoStore` → país de la tienda.

### En Spring Boot / Java (Servlet API)

```java
// Crear y enviar una cookie
Cookie cookie = new Cookie("usuario", "kerin");
cookie.setMaxAge(60 * 60 * 24); // 1 día (segundos)
cookie.setPath("/");
response.addCookie(cookie);

// Leer cookies
Cookie[] cookies = request.getCookies();
if (cookies != null) {
    for (Cookie c : cookies) {
        if (c.getName().equals("usuario")) {
            String valor = c.getValue();
        }
    }
}
```

> ⚠️ Las cookies viajan en cada petición HTTP. Si guardas muchos datos, el tamaño de las peticiones crece (límite ~8 KB). Por eso para datos grandes se usa **sesión**.

### Cookies en Spring Boot (controlador)

Ejemplo completo de un controlador que guarda y lee una cookie de preferencia (por ejemplo, el idioma o el tema elegido por el usuario).

```java
@Controller
public class ControladorCookie {

    // Mostrar página leyendo la cookie "tema"
    @GetMapping("/tema")
    public String mostrarTema(Model model, HttpServletRequest request) {
        String tema = "claro"; // valor por defecto
        Cookie[] cookies = request.getCookies();
        if (cookies != null) {
            for (Cookie c : cookies) {
                if (c.getName().equals("tema")) {
                    tema = c.getValue();
                }
            }
        }
        model.addAttribute("temaActual", tema);
        return "tema";
    }

    // Guardar la preferencia en una cookie
    @PostMapping("/cambiarTema")
    public String cambiarTema(@RequestParam("tema") String tema, HttpServletResponse response) {
        Cookie cookie = new Cookie("tema", tema);
        cookie.setMaxAge(60 * 60 * 24 * 30); // 30 días
        cookie.setPath("/");                 // disponible en toda la app
        // cookie.setHttpOnly(true);          // recomendado: no accesible desde JS
        // cookie.setSecure(true);            // recomendado: solo HTTPS
        response.addCookie(cookie);
        return "redirect:/tema";
    }

    // Borrar la cookie (poner maxAge a 0)
    @PostMapping("/borrarTema")
    public String borrarTema(HttpServletResponse response) {
        Cookie cookie = new Cookie("tema", "");
        cookie.setMaxAge(0);                // expira inmediatamente
        cookie.setPath("/");
        response.addCookie(cookie);
        return "redirect:/tema";
    }
}
```

#### Métodos de `Cookie` más usados
| Método | Uso |
|---|---|
| `new Cookie(nombre, valor)` | Crear la cookie |
| `cookie.setMaxAge(segundos)` | Tiempo de vida (`0` = borrar, `-1` = sesión) |
| `cookie.setPath("/")` | Ruta donde se envía |
| `cookie.setDomain("...")` | Dominio (opcional) |
| `cookie.setHttpOnly(true)` | No accesible desde JavaScript (seguridad) |
| `cookie.setSecure(true)` | Solo se envía por HTTPS |
| `response.addCookie(cookie)` | Enviarla al navegador |
| `request.getCookies()` | Leer las cookies recibidas |

#### Plantilla Thymeleaf de ejemplo (`tema.html`)
```html
<!DOCTYPE html>
<html lang="es" xmlns:th="http://www.thymeleaf.org">
<head><meta charset="UTF-8"><title>Tema</title></head>
<body>
  <p>Tema actual: <span th:text="${temaActual}">claro</span></p>

  <form th:action="@{/cambiarTema}" method="post">
    <select name="tema">
      <option value="claro">Claro</option>
      <option value="oscuro">Oscuro</option>
    </select>
    <button type="submit">Guardar preferencia</button>
  </form>

  <form th:action="@{/borrarTema}" method="post">
    <button type="submit">Borrar cookie</button>
  </form>
</body>
</html>
```

> 💡 **Diferencia clave con la sesión:** aquí el dato (`tema`) viaja en la cookie y se guarda en el navegador. Con sesión, el dato queda en el servidor y solo viaja el `JSESSIONID`.

---

## 3. Sesión

La sesión se almacena **en el servidor** (un `HashMap` clave-valor por usuario). Para saber qué `HashMap` pertenece a cada usuario, se crea una cookie llamada **`JSESSIONID`** que contiene el identificador de la sesión. Es decir: la sesión usa una cookie "por debajo", pero tú no la gestionas a mano.

### Flujo
1. El usuario hace su primera petición → el servidor crea un objeto sesión con un `HashMap` vacío y genera un `JSESSIONID`.
2. La respuesta lleva `Set-Cookie: JSESSIONID=...`.
3. En peticiones siguientes, el navegador envía esa cookie → el servidor recupera el `HashMap` correspondiente.
4. Puedes guardar objetos ahí con `setAttribute` y leerlos con `getAttribute`.

### En Java (Servlet API)

```java
// Obtener/crear sesión (true = la crea si no existe)
HttpSession session = request.getSession(true);

// Guardar un atributo
session.setAttribute("MY_SESSION_MESSAGES", listaMensajes);

// Leer un atributo
List<String> messages = (List<String>) session.getAttribute("MY_SESSION_MESSAGES");

// Listar nombres de atributos
Enumeration<String> nombres = session.getAttributeNames();

// Invalidar (cerrar sesión / logout)
session.invalidate();
```

### En Spring Boot (controlador, como en los apuntes)

```java
@Controller
public class ControladorSession {

    @GetMapping("/session")
    public String process(Model model, HttpSession session) {
        @SuppressWarnings("unchecked")
        List<String> messages = (List<String>) session.getAttribute("MY_SESSION_MESSAGES");
        if (messages == null) messages = new ArrayList<>();
        model.addAttribute("sessionMessages", messages);
        return "session";
    }

    @PostMapping("/persistMessage")
    public String persistMessage(@RequestParam("msg") String msg, HttpServletRequest request) {
        @SuppressWarnings("unchecked")
        List<String> messages = (List<String>) request.getSession().getAttribute("MY_SESSION_MESSAGES");
        if (messages == null) {
            messages = new ArrayList<>();
            request.getSession().setAttribute("MY_SESSION_MESSAGES", messages);
        }
        messages.add(msg);
        request.getSession().setAttribute("MY_SESSION_MESSAGES", messages);
        return "redirect:/session";
    }

    @PostMapping("/destroy")
    public String destroySession(HttpServletRequest request) {
        request.getSession().invalidate();
        return "redirect:/session";
    }
}
```

### Métodos de `HttpSession` más útiles

| Método | Uso |
|---|---|
| `request.getSession()` / `getSession(true)` | Recuperar o crear sesión |
| `session.setAttribute(nombre, objeto)` | Guardar un objeto |
| `session.getAttribute(nombre)` | Leer un objeto |
| `session.getAttributeNames()` | Listado de nombres de atributos |
| `session.getId()` | Identificador de la sesión |
| `session.getCreationTime()` | Fecha de creación (ms desde epoch) |
| `session.getLastAccessedTime()` | Último acceso (ms desde epoch) |
| `session.invalidate()` | Invalidar sesión (logout) |

### Configuración en Spring Boot (`application.properties`)

```properties
server.port=9090
spring.session.store-type=jdbc          # guardar sesión en BD
spring.session.jdbc.initialize-schema=always
spring.session.timeout=900              # 15 minutos (segundos)
spring.thymeleaf.cache=false
```

Y las dependencias en `pom.xml`:

```xml
<dependency>
  <groupId>org.springframework.session</groupId>
  <artifactId>spring-session-core</artifactId>
</dependency>
<dependency>
  <groupId>org.springframework.session</groupId>
  <artifactId>spring-session-jdbc</artifactId>
</dependency>
```

Si usas BD, la sesión se guarda en bytes en una tabla (no se puede leer a ojo).

---

## 4. Comparativa rápida

| | Cookies | Sesión |
|---|---|---|
| Dónde se guarda | Cliente (navegador) | Servidor |
| Qué se guarda | Solo texto (clave-valor) | Objetos Java |
| Seguridad | Visible al usuario | Más seguro (solo el ID viaja) |
| Tamaño | Limitado (~8 KB por petición) | Sin límite práctico |
| Vida | Hasta expiración o cierre | Hasta `invalidate()` o timeout |

**Regla práctica:** datos pequeños y no sensibles → cookie. Datos de usuario, carrito, login → sesión.

---

## 5. Curiosidades / casos menos usados

### a) Campos hidden (formularios encadenados)
Antes de cookies/sesiones, se pasaba el estado en campos `<input type="hidden" name="idSesion" value="17"/>` dentro de formularios. Es lo que tú tenías antes. Sigue existiendo pero es tedioso y visible en el código fuente / URL (con GET).

### b) Reescritura de URL (fallback sin cookies)
Si el cliente no acepta cookies, el servidor añade el ID de sesión a la URL:
```
http://servidor/ruta/archivo.html;jsessionid=123
```
Es visible, rastreable y tedioso (hay que codificar todas las URLs). En Spring/JEE se puede deshabilitar:
```xml
<Context disableURLRewriting="true"> </Context>
```
Y se puede deshabilitar el uso de cookies:
```xml
<Context cookies="false"> </Context>
```

### c) Timeout de sesión
El servidor invalida la sesión si pasan X segundos sin peticiones (por defecto ~30 min en Tomcat, configurable). También se puede invalidar manualmente con `invalidate()`.

### d) No se detecta el cierre del navegador
HTTP no avisa cuando el usuario cierra la pestaña. Por eso las sesiones expiran por inactividad, no por "logout" automático.

### e) Sesión por usuario
Cada usuario tiene su propio `HashMap`; la información **no se comparte** entre usuarios.

---

## 6. La anotación `@SuppressWarnings`

`@SuppressWarnings` es una anotación de Java (no de Spring) que le dice al compilador: **"no me muestres las advertencias (warnings) de este tipo"**. No cambia el comportamiento del código, solo silencia avisos del compilador/IDE.

### Sintaxis
```java
@SuppressWarnings("unchecked")
@SuppressWarnings({"unchecked", "deprecation"})
@SuppressWarnings("all")
```

### ¿Por qué aparece en los ejemplos de sesión?
Cuando lees un atributo de la sesión, `getAttribute` devuelve un `Object`. Para usarlo como `List<String>` hay que hacer un cast:

```java
List<String> messages = (List<String>) session.getAttribute("MY_SESSION_MESSAGES");
```

Ese cast no se puede comprobar en tiempo de compilación (el compilador no sabe qué hay dentro de la sesión), así que genera el warning:

> *"Type safety: Unchecked cast from Object to List<String>"*

La anotación `@SuppressWarnings("unchecked")` silencia ese aviso. Se pone **justo encima del elemento afectado** (variable, método o clase):

```java
@SuppressWarnings("unchecked")
List<String> messages = (List<String>) session.getAttribute("MY_SESSION_MESSAGES");
```

O sobre todo el método:

```java
@GetMapping("/session")
@SuppressWarnings("unchecked")
public String process(Model model, HttpSession session) { ... }
```

### Valores comunes
| Valor | Silencia |
|---|---|
| `"unchecked"` | Casts no comprobados, genéricos sin tipo |
| `"deprecation"` | Uso de métodos/clases obsoletos (`@Deprecated`) |
| `"unused"` | Variables/métodos/imports no usados |
| `"rawtypes"` | Uso de tipos crudos (sin genéricos), ej. `List` en vez de `List<String>` |
| `"null"` / `"potentialnullpointerexception"` | Posibles `NullPointerException` (depende del IDE) |
| `"all"` | Todas las advertencias (no recomendado) |

### Buenas prácticas
- Úsala **lo más local posible**: sobre la variable o el bloque, no sobre toda la clase.
- No la uses para ocultar problemas reales; si puedes evitar el cast (por ejemplo, encapsulando el acceso a la sesión en un helper tipado), mejor.
- En Spring Boot es habitual verla en controladores que leen de sesión o de `request` por el cast de `Object` a un tipo concreto.

### Ejemplo completo con y sin anotación

```java
// Sin anotación → el IDE marca warning en la línea del cast
List<String> messages = (List<String>) session.getAttribute("MY_SESSION_MESSAGES");

// Con anotación → sin warning
@SuppressWarnings("unchecked")
List<String> messages = (List<String>) session.getAttribute("MY_SESSION_MESSAGES");
```

---

## 8. Resumen para migrar tu proyecto

1. En el controlador, recibe `HttpSession session` (o `HttpServletRequest request`).
2. Guarda el estado con `session.setAttribute("clave", objeto)` en vez de pasar hidden fields.
3. Lee con `session.getAttribute("clave")`.
4. Para "cerrar sesión" / resetear, usa `session.invalidate()`.
5. Si necesitas persistencia entre reinicios del servidor, configura `spring.session.store-type=jdbc`.
6. Las cookies (`JSESSIONID`) las gestiona el contenedor (Tomcat) automáticamente; tú no las tocas salvo que quieras cookies propias (preferencias, idioma, etc.).
7. Para cookies propias: `new Cookie(...)`, `response.addCookie(...)`, `request.getCookies()`.