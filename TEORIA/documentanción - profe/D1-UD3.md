<link rel="stylesheet" href="../css/guia-galactica.css">

<div class="cover">
<p class="serial">CUADERNO DE PRÁCTICAS // DESARROLLO WEB EN ENTORNO SERVIDOR</p>

# D1 · UD3<br>SPRING BOOT

<p class="subtitle">Sesiones y cookies: mantener el estado entre peticiones</p>
<p>Kerin Aguilera</p>
<p class="serial">JAVA 21 · SPRING BOOT 4 · THYMELEAF · NOVIEMBRE 2026</p>
</div>

<div class="toc">
<p class="toc-title">ÍNDICE DE RUTA</p>
<ol>
<li><a href="#objetivo">Objetivo de la práctica</a></li>
<li><a href="#problema">El problema de fondo: HTTP no recuerda</a>
<ul>
<li><a href="#sin-estado">Protocolo sin estado</a></li>
<li><a href="#estrategias">Las cuatro estrategias para mantener estado</a></li>
</ul>
</li>
<li><a href="#cookies">Cookies</a>
<ul>
<li><a href="#que-es-cookie">Qué es una cookie</a></li>
<li><a href="#atributos-cookie">Atributos de una cookie</a></li>
<li><a href="#cookie-spring">Cookies en Spring Boot (controlador)</a></li>
<li><a href="#metodos-cookie">Métodos de Cookie más usados</a></li>
</ul>
</li>
<li><a href="#sesiones">Sesiones</a>
<ul>
<li><a href="#que-es-sesion">Qué es una sesión y cómo funciona</a></li>
<li><a href="#jsessionid">JSESSIONID: la cookie que une al usuario con su sesión</a></li>
<li><a href="#httpsession">HttpSession y sus métodos</a></li>
<li><a href="#sesion-spring">Sesiones en Spring Boot (controlador)</a></li>
<li><a href="#configuracion">Configuración y persistencia en base de datos</a></li>
</ul>
</li>
<li><a href="#migracion">De formularios encadenados a sesiones</a>
<ul>
<li><a href="#proyecto-quizz">El proyecto Quizz (formularios encadenados)</a></li>
<li><a href="#fallo">El fallo que me obligó a repensar el flujo</a></li>
<li><a href="#equivalencia">Equivalencia: campo hidden → session.setAttribute</a></li>
</ul>
</li>
<li><a href="#comparativa">Cookies vs sesión</a></li>
<li><a href="#curiosidades">Curiosidades y casos menos usados</a></li>
<li><a href="#suppresswarnings">La anotación @SuppressWarnings</a></li>
<li><a href="#resumen">Resumen de conceptos</a></li>
<li><a href="#repaso">Preguntas de repaso</a></li>
<li><a href="#conclusion">Conclusión</a></li>
<li><a href="#recursos">Recursos</a></li>
</ol>
</div>

<a id="objetivo"></a>

## Objetivo de la práctica

En D3-UD2 construí un formulario por pasos reenviando todos los datos en campos ocultos: cada POST llevaba consigo el estado completo del objeto, porque HTTP no recuerda nada por sí solo. Era la solución más didáctica, pero también la más frágil: los datos viajan por el navegador y cualquiera puede tocarlos.

En esta práctica doy el siguiente paso: delegar el estado en el servidor. Aprendo a usar **cookies** (pequeños datos que el navegador guarda y devuelve) y **sesiones** (un `HashMap` por usuario que vive en el servidor y se identifica mediante una cookie llamada `JSESSIONID`). El resultado es un flujo más seguro, más limpio y con menos HTML que mantener.

La sesión sigue el ejemplo del profesor y lo adapta al proyecto **formularios-encadenados**, que es el mismo mini-quizz por etapas (nombre, aficiones, lugar, sexo) pero ahora sin arrastrar campos `hidden`.

<div class="spec">

| Pieza | Detalle |
|---|---|
| Proyecto base | `formularios-encadenados` (Quizz) |
| Novedad | `HttpSession` · `Cookie` · `JSESSIONID` |
| Dependencias | Spring Web MVC · Thymeleaf |
| Conceptos clave | Estado del servidor · `setAttribute` / `getAttribute` · `invalidate()` |
| Persistencia opcional | `spring-session-jdbc` (sesión en base de datos) |

</div>

<div class="note">

La idea central que me llevo: el protocolo no cambia. HTTP sigue siendo sin estado. Lo que cambia es **dónde guardamos la memoria**: antes en el formulario, ahora en el servidor.

</div>

<a id="problema"></a>

## El problema de fondo: HTTP no recuerda

<a id="sin-estado"></a>

### Protocolo sin estado

HTTP trata cada petición como una transacción independiente que no tiene relación con ninguna anterior. El servidor recibe la petición, responde y se olvida del cliente. No sabe si esa petición viene de alguien que acaba de llegar o de alguien que lleva media hora navegando.

Esto es un problema para cualquier aplicación con login, carrito de la compra o formulario por pasos: si el servidor no recuerda, ¿cómo sabe que los artículos del carrito son míos?

<a id="estrategias"></a>

### Las cuatro estrategias para mantener estado

1. **Campos ocultos (`hidden`)** — reenviar todo en cada formulario. La que usé en D3-UD2. Didáctica, pero frágil: los datos viajan por el navegador.
2. **Cookie de identificación** — el servidor manda un identificador y el cliente lo devuelve en cada petición.
3. **Sesión** — el estado vive en el servidor; el cliente solo lleva un identificador (`JSESSIONID`). Es la solución habitual.
4. **Reescritura de URL** — el identificador se añade a la URL (`;jsessionid=...`). Fallback cuando el navegador no acepta cookies.

La práctica se centra en la 3, con la 2 como mecanismo subyacente, y trata la 4 como curiosidad.

<a id="cookies"></a>

## Cookies

<a id="que-es-cookie"></a>

### Qué es una cookie

Una cookie (más exactamente *HTTP cookie*) es un pequeño trozo de información en formato **clave = valor** que el servidor envía al navegador dentro de la cabecera `Set-Cookie` de la respuesta HTTP. El navegador la guarda y la devuelve automáticamente en la cabecera `Cookie` de las peticiones siguientes al mismo dominio.

En otras palabras: es información que queda almacenada en el dispositivo del usuario y que se envía hacia y desde el servidor web en las cabeceras HTTP.

Cuando un usuario solicita una página, el servidor envía el documento, cierra la conexión y se olvida del usuario. Si el mismo usuario vuelve a solicitar otra página, sería tratado como si fuera la primera vez. Las cookies solucionan esto: el servidor "recuerda" al usuario e información asociada a él leyendo la cookie que el navegador devuelve.

<a id="atributos-cookie"></a>

### Atributos de una cookie

Una cookie tiene:

- **Nombre** — con lo que se identifica.
- **Valor** — el dato que queremos almacenar.
- **Fecha de expiración** — cuándo caduca y obliga a crearla de nuevo (si no se pone, es de sesión y se borra al cerrar el navegador).
- **Dominio** — a qué aplicación web pertenece.
- **Ruta** — dónde se envía.

Ejemplo real: al visitar `bershka.es` se envían varias cookies:

- `BershkaGenderCategory` — género del cliente, para mostrar esos artículos la próxima vez.
- `JSESSIONID` — identificador de la sesión en el servidor.
- `BSKGeoStore` — país de la tienda.

<a id="cookie-spring"></a>

### Cookies en Spring Boot (controlador)

Ejemplo completo de un controlador que guarda y lee una cookie de preferencia (por ejemplo, el tema elegido por el usuario):

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

Y la plantilla correspondiente:

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

<a id="metodos-cookie"></a>

### Métodos de Cookie más usados

| Método | Uso |
|---|---|
| `new Cookie(nombre, valor)` | Crea la cookie |
| `cookie.setMaxAge(segundos)` | Tiempo de vida (`0` = borrar, `-1` = sesión) |
| `cookie.setPath("/")` | Ruta donde se envía |
| `cookie.setDomain("...")` | Dominio (opcional) |
| `cookie.setHttpOnly(true)` | No accesible desde JavaScript (seguridad) |
| `cookie.setSecure(true)` | Solo se envía por HTTPS |
| `response.addCookie(cookie)` | Envía la cookie al navegador |
| `request.getCookies()` | Lee las cookies recibidas |

<div class="warning">

Las cookies viajan en cada petición HTTP. Si guardas muchos datos, el tamaño de las peticiones crece (límite ~8 KB). Por eso para datos grandes se usa sesión.

</div>

<a id="sesiones"></a>

## Sesiones

<a id="que-es-sesion"></a>

### Qué es una sesión y cómo funciona

La sesión se almacena en el servidor. Se trata de un `HashMap` en el que se guardan, con formato clave-valor, los datos del cliente. Para poder identificar la sesión que pertenece a cada usuario se establece una cookie denominada `JSESSIONID`, que proporciona el identificador de la sesión del usuario.

El funcionamiento es relativamente sencillo:

1. Cada vez que un usuario crea una sesión accediendo a una página, se crea un objeto a nivel de servidor con un `HashMap` vacío que permite almacenar la información relativa a ese usuario.
2. Realizado este primer paso se envía al navegador del usuario una cookie que sirve para identificarle y asociarle el `HashMap` que se acaba de construir.
3. Este `HashMap` puede ser accedido desde cualquier otra página, permitiéndonos compartir información entre ellas.

La analogía clásica: el encargado de guardar un abrigo guarda tus datos e información en una tabla, y a ti te da el ticket para saber dónde está ese abrigo. El ticket es el `JSESSIONID`; el abrigo, tus datos en el `HashMap`.

El concepto de sesión es individual de cada usuario: la información **no se comparte** entre ellos. Cada usuario dispone de su propio `HashMap`.

La sesión usa una cookie "por debajo", pero tú no la gestionas a mano. Es el contenedor (Tomcat, en Spring Boot) el que la crea y la lee.

<a id="jsessionid"></a>

### JSESSIONID: la cookie que une al usuario con su sesión

Primera petición del cliente: al invocar `HttpServletRequest.getSession()`, se crea una nueva sesión, se genera un identificador (`JSESSIONID`) y la respuesta (cabecera HTTP) contiene la cookie `Set-Cookie: JSESSIONID=...`.

Peticiones siguientes: al invocar `getSession()`, se devuelve la sesión del cliente en función del valor de la cookie `JSESSIONID`. El método `isRequestedSessionIdFromCookie()` devuelve `true`.

<a id="httpsession"></a>

### HttpSession y sus métodos

| Funcionalidad | Método |
|---|---|
| Recuperar / crear sesión | `request.getSession()` o `request.getSession(true)` |
| Añadir atributo | `session.setAttribute(atributo, objeto)` |
| Consultar atributo | `session.getAttribute(atributo)` |
| Listado de atributos | `session.getAttributeNames()` |
| Recuperar el id de la sesión | `session.getId()` |
| Fecha de creación | `session.getCreationTime()` (ms desde epoch) |
| Último acceso | `session.getLastAccessedTime()` (ms desde epoch) |
| Invalidar la sesión | `session.invalidate()` |

<a id="sesion-spring"></a>

### Sesiones en Spring Boot (controlador)

Ejemplo basado en los apuntes del profesor, adaptado a un mini-quizz por etapas. El estado se guarda en sesión en vez de en campos `hidden`:

```java
@Controller
public class ControladorSession {

    @GetMapping("/session")
    public String process(Model model, HttpSession session) {
        @SuppressWarnings("unchecked")
        List<String> messages = (List<String>) session.getAttribute("MY_SESSION_MESSAGES");
        if (messages == null) {
            messages = new ArrayList<>();
        }
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

Y la plantilla asociada:

```html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org">
<head>
<meta charset="UTF-8">
<title>Spring Boot Session Example</title>
</head>
<body>
<div>
  <form th:action="@{/persistMessage}" method="post">
    <textarea name="msg" cols="40" rows="2"></textarea>
    <br> <input type="submit" value="Save Message" />
  </form>
</div>
<div>
  <h2>Messages</h2>
  <ul th:each="message : ${sessionMessages}">
    <li th:text="${message}">msg</li>
  </ul>
</div>
<div>
  <form th:action="@{/destroy}" method="post">
    <input type="submit" value="Destroy Session" />
  </form>
</div>
</body>
</html>
```

Al utilizar el formulario se crea la cookie de sesión y se almacenan los datos en ella. El contenedor (Tomcat) gestiona el `JSESSIONID`; tú solo usas `session.setAttribute` / `getAttribute`.

<a id="configuracion"></a>

### Configuración y persistencia en base de datos

Por defecto la sesión vive en memoria del servidor. Si quieres que sobreviva a reinicios o que se comparta entre varias instancias, guárdala en base de datos.

Dependencias en `pom.xml`:

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-jdbc</artifactId>
</dependency>
<dependency>
  <groupId>org.springframework.session</groupId>
  <artifactId>spring-session-core</artifactId>
</dependency>
<dependency>
  <groupId>org.springframework.session</groupId>
  <artifactId>spring-session-jdbc</artifactId>
</dependency>
<dependency>
  <groupId>mysql</groupId>
  <artifactId>mysql-connector-java</artifactId>
</dependency>
```

Y en `application.properties`:

```properties
server.port=9090
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
spring.datasource.url=jdbc:mysql://localhost/springSession?allowPublicKeyRetrieval=true&createDatabaseIfNotExist=true&useUnicode=true&serverTimezone=UTC&useSSL=false
spring.datasource.username=root
spring.datasource.password=root
spring.datasource.initialization-mode=always
spring.h2.console.enabled=true
spring.session.store-type=jdbc
spring.session.jdbc.initialize-schema=always
spring.session.timeout=900
spring.thymeleaf.cache=false
```

Los datos de la sesión se almacenan en la base de datos en formato de bytes, por lo que no se pueden leer a ojo.

<a id="migracion"></a>

## De formularios encadenados a sesiones

<a id="proyecto-quizz"></a>

### El proyecto Quizz (formularios encadenados)

El proyecto `formularios-encadenados` divide un mini-quizz en cuatro etapas (nombre, aficiones, lugar, sexo) y un resultado final. Cada etapa reenvía los datos anteriores mediante campos ocultos:

```html
<!-- etapa2.html -->
<input type="hidden" name="numEtapa" th:value="${numEtapa}" />
<input type="hidden" name="nombre" th:value="${nombre}" />

<!-- etapa3.html -->
<input type="hidden" name="numEtapa" th:value="${numEtapa}" />
<input type="hidden" name="signo" th:value="${signo}" />
<input type="hidden" name="nombre" th:value="${nombre}" />
```

El objeto `Quizz` reúne los datos:

```java
package entity;

public class Quizz {
    private String nombre;
    private String aficciones;
    private Integer signo;
    private Integer numEtapa;

    public Quizz() { }

    public Quizz(String nombre, String aficciones, Integer signo, Integer numEtapa) {
        this.nombre = nombre;
        this.aficciones = aficciones;
        this.signo = signo;
        this.numEtapa = numEtapa;
    }

    // getters y setters...
}
```

Funciona, pero cada valor tiene que repetirse en cada plantilla, y una lista (las aficiones) obliga a generar un campo oculto por elemento con `th:each`.

Así se veía el flujo por etapas:

![Código del objeto Quizz](img%20-%20documents/codigo_D1_UD3.01.png)

![Inicialización de la sesión en el GET](img%20-%20documents/codigo_D1_UD3.02.png)

![Lógica del controlador en el POST](img%20-%20documents/codigo_D1_UD3.03.png)

La primera etapa:

![Primera etapa: código](img%20-%20documents/codigo_D1_UD3.04.png)

![Primera etapa: vista](img%20-%20documents/UD1_UD3.01.png)

La segunda etapa:

![Segunda etapa: código](img%20-%20documents/codigo_D1_UD3.05.png)

![Segunda etapa: vista](img%20-%20documents/UD1_UD3.02.png)

La tercera etapa:

![Tercera etapa: código](img%20-%20documents/codigo_D1_UD3.06.png)

![Tercera etapa: vista](img%20-%20documents/UD1_UD3.03.png)

La cuarta etapa:

![Cuarta etapa: código](img%20-%20documents/codigo_D1_UD3.07.png)

Y el resultado final:

![Resultado final](img%20-%20documents/UD1_UD3.04.png)

<a id="fallo"></a>

### El fallo que me obligó a repensar el flujo

Mi primer intento con sesión tenía un problema curioso: guardaba el objeto en la sesión así:

```java
session.setAttribute("quizz", actual);
```

El problema era que, como HTTP es sin estado, cada POST traía solo los datos del paso actual. Si guardaba la afición, el nombre llegaba `null`, porque se sobrescribía el guardado en cada petición. Los datos de los pasos anteriores se perdían.

La solución fue tener un objeto aparte, ir guardando en él los datos que recibíamos del formulario y luego guardar ese objeto en la sesión, que es la que se muestra al final. Puede que existiera otra forma, pero la que encontré en ese momento fue esa.

El controlador final quedó así:

```java
package goya.daw2.pruebas_plantillas;

import java.util.ArrayList;
import entity.Quizz;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class FormsController {

    static final String[] SIGNOS = { "", "Aries", "Tauro", "Géminis", "Cáncer", "Leo",
            "Virgo", "Libra", "Escorpio", "Sagitario", "Capricornio", "Acuario", "Piscis" };
    static final String[] AFICCIONES = { "Deportes", "Juerga", "Lectura", "Relaciones sociales" };

    @PostMapping("/")
    String procesaEtapaX(@RequestParam(name = "numEtapa") Integer numEtapa,
                         Model modelo,
                         Quizz quizz,
                         HttpSession session) {

        Quizz actual = (Quizz) session.getAttribute("quizz");
        if (actual == null) {
            actual = new Quizz();
        }

        if (quizz.getNombre() != null) {
            actual.setNombre(quizz.getNombre());
        }
        if (quizz.getSigno() != null) {
            actual.setSigno(quizz.getSigno());
        }
        if (quizz.getAficciones() != null) {
            actual.setAficciones(quizz.getAficciones());
        }

        modelo.addAttribute("signos", SIGNOS);
        modelo.addAttribute("aficciones", AFICCIONES);

        if (quizz.getSigno() != null) {
            modelo.addAttribute("signo", quizz.getSigno());
        }

        String errores = "";

        if (numEtapa == 1 && (quizz.getNombre() == null || quizz.getNombre().isBlank())) {
            errores = "Debes poner un nombre no vacío";
        } else if (numEtapa == 1 && (quizz.getNombre().length() < 3 || quizz.getNombre().length() > 10)) {
            errores = "La longitud del nombre debe estar entre 3 y 10";
        }

        if (numEtapa == 2 && (quizz.getSigno() == null || quizz.getSigno().equals(0))) {
            errores = "Debes seleccionar un signo";
        }

        if (numEtapa == 3 && (quizz.getAficciones() == null || quizz.getAficciones().isBlank())) {
            errores = "Debes elegir al menos una aficción, no seas soso/a";
        }

        if (!errores.isBlank()) {
            modelo.addAttribute("errores", errores);
            modelo.addAttribute("numEtapa", numEtapa);
            return "etapa" + numEtapa;
        }

        numEtapa++;
        modelo.addAttribute("numEtapa", numEtapa);

        session.setAttribute("quizz", actual);

        if (numEtapa == 4) {
            ArrayList<String> respuestas = new ArrayList<>();
            respuestas.add(actual.getNombre());
            respuestas.add(SIGNOS[actual.getSigno()]);
            respuestas.add(actual.getAficciones());
            modelo.addAttribute("respuestas", respuestas);
        }

        return "etapa" + numEtapa;
    }

    @GetMapping("/")
    String getEtapa0(HttpSession sesion) {
        Quizz quizz = (Quizz) sesion.getAttribute("quizz");
        return "etapa1";
    }
}
```

Y el GET inicializaba la sesión recuperando el objeto (si existía) antes de mostrar la primera etapa.

<div class="note">

Fíjate en el detalle clave: el controlador recupera `actual` de la sesión y solo sobrescribe los campos que **llegan no nulos** en el paso actual. Así los datos de los pasos anteriores sobreviven aunque el formulario del paso actual no los envíe.

</div>

<a id="equivalencia"></a>

### Equivalencia: campo hidden → session.setAttribute

Si tuvieras un flujo encadenado, cada `hidden` se sustituye así:

| Antes (formulario encadenado) | Después (con sesión) |
|---|---|
| `<input type="hidden" name="nombre" th:value="${nombre}" />` | `session.setAttribute("nombre", nombre)` en el POST del paso 1 |
| Leer en el siguiente paso con `@RequestParam("nombre")` | Leer con `(String) session.getAttribute("nombre")` |
| Repetir el `hidden` en cada etapa | Ya está en sesión; no hace falta repetir |
| Datos visibles en la URL / código fuente | Datos solo en el servidor |

Ejemplo de paso intermedio con sesión:

```java
@PostMapping("/paso2")
public String paso2(@RequestParam("signo") String signo,
                    HttpServletRequest request,
                    Model modelo) {
    HttpSession session = request.getSession();
    String nombre = (String) session.getAttribute("nombre"); // recuperado del paso 1
    session.setAttribute("signo", signo);                   // guardar el nuevo dato
    modelo.addAttribute("nombre", nombre);
    modelo.addAttribute("signo", signo);
    return "etapa3";
}
```

<a id="comparativa"></a>

## Cookies vs sesión

| | Cookies | Sesión |
|---|---|---|
| Dónde se guarda | Cliente (navegador) | Servidor |
| Qué se guarda | Solo texto (clave-valor) | Objetos Java |
| Seguridad | Visible al usuario | Más seguro (solo el ID viaja) |
| Tamaño | Limitado (~8 KB por petición) | Sin límite práctico |
| Vida | Hasta expiración o cierre | Hasta `invalidate()` o timeout |

Regla práctica: datos pequeños y no sensibles (idioma, tema) → cookie. Datos de usuario, carrito, login, formularios por pasos → sesión.

<a id="curiosidades"></a>

## Curiosidades y casos menos usados

- **Reescritura de URL (fallback sin cookies):** si el cliente no acepta cookies, el servidor añade el ID de sesión a la URL:
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
- **Timeout de sesión:** el servidor invalida la sesión si pasan X segundos sin peticiones (por defecto ~30 min en Tomcat, configurable con `spring.session.timeout`). También se puede invalidar manualmente con `invalidate()`.
- **No se detecta el cierre del navegador:** HTTP no avisa cuando el usuario cierra la pestaña. Por eso las sesiones expiran por inactividad, no por "logout" automático.
- **Sesión por usuario:** cada usuario tiene su propio `HashMap`; la información no se comparte entre usuarios. Por eso una variable `static` en el controlador es un error: se comparte entre todas las peticiones de todos los usuarios (lo vi en D3-UD2 con el contador del paso).
- **Campos hidden (formularios encadenados):** antes de cookies/sesiones, se pasaba el estado en campos `<input type="hidden" name="idSesion" value="17"/>`. Sigue existiendo pero es tedioso y visible en el código fuente / URL (con GET).

<a id="suppresswarnings"></a>

## La anotación @SuppressWarnings

`@SuppressWarnings` es una anotación de Java (no de Spring) que le dice al compilador: *"no me muestres las advertencias (warnings) de este tipo"*. No cambia el comportamiento del código, solo silencia avisos del compilador/IDE.

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

Ese cast no se puede comprobar en tiempo de compilación, así que genera el warning *"Type safety: Unchecked cast from Object to List"*. La anotación `@SuppressWarnings("unchecked")` silencia ese aviso. Se pone justo encima del elemento afectado:

```java
@SuppressWarnings("unchecked")
List<String> messages = (List<String>) session.getAttribute("MY_SESSION_MESSAGES");
```

### Valores comunes

| Valor | Silencia |
|---|---|
| `"unchecked"` | Casts no comprobados, genéricos sin tipo |
| `"deprecation"` | Uso de métodos/clases obsoletos |
| `"unused"` | Variables/métodos/imports no usados |
| `"rawtypes"` | Uso de tipos crudos (sin genéricos) |
| `"all"` | Todas las advertencias (no recomendado) |

### Buenas prácticas

- Úsala lo más local posible: sobre la variable, no sobre toda la clase.
- No la uses para ocultar problemas reales; si puedes encapsular el acceso a la sesión en un helper tipado, mejor.

<a id="resumen"></a>

## Resumen de conceptos

### Cookies

| Elemento | Qué hace |
|---|---|
| `Set-Cookie` / `Cookie` | Cabeceras HTTP por las que viaja la cookie |
| `new Cookie(nombre, valor)` | Crea la cookie |
| `cookie.setMaxAge(segundos)` | Tiempo de vida (`0` = borrar, `-1` = sesión) |
| `cookie.setPath("/")` | Ruta donde se envía |
| `cookie.setHttpOnly(true)` | No accesible desde JavaScript |
| `response.addCookie(cookie)` | Envía la cookie al navegador |
| `request.getCookies()` | Lee las cookies recibidas |

### Sesiones

| Elemento | Qué hace |
|---|---|
| `JSESSIONID` | Cookie que identifica la sesión del usuario |
| `request.getSession()` | Recupera o crea la sesión |
| `session.setAttribute(clave, objeto)` | Guarda un objeto en la sesión |
| `session.getAttribute(clave)` | Lee un objeto de la sesión |
| `session.getAttributeNames()` | Lista los nombres de atributos |
| `session.getId()` | Identificador de la sesión |
| `session.getCreationTime()` | Fecha de creación |
| `session.getLastAccessedTime()` | Último acceso |
| `session.invalidate()` | Invalida la sesión (logout) |

### Configuración

| Propiedad | Qué hace |
|---|---|
| `spring.session.store-type=jdbc` | Guarda la sesión en base de datos |
| `spring.session.jdbc.initialize-schema=always` | Crea la tabla de sesiones |
| `spring.session.timeout=900` | Timeout de sesión en segundos |

Ideas clave que me llevo de la práctica:

- HTTP sigue siendo sin estado. La sesión solo mueve la memoria del formulario al servidor.
- La cookie `JSESSIONID` la gestiona el contenedor (Tomcat) automáticamente; tú solo usas `setAttribute` / `getAttribute`.
- Los datos pequeños y no sensibles van en cookie propia; los datos de usuario y formularios por pasos van en sesión.
- Los campos `hidden` ya no son necesarios: la sesión arrastra el estado.
- Para empezar de cero: `session.invalidate()`.
- El cast `(Tipo) session.getAttribute(...)` genera warning → `@SuppressWarnings("unchecked")`.

<a id="repaso"></a>

## Preguntas de repaso

1. ¿Por qué HTTP necesita mecanismos como cookies o sesiones para recordar al usuario? *(El problema de fondo)*
2. ¿Qué cuatro estrategias existen para mantener estado entre peticiones y cuál es la habitual? *(El problema de fondo)*
3. ¿Qué es una cookie y en qué cabecera HTTP viaja? *(Cookies)*
4. ¿Qué atributos tiene una cookie y para qué sirve `maxAge`? *(Cookies)*
5. ¿Qué diferencia hay entre `setMaxAge(0)` y `setMaxAge(-1)`? *(Cookies)*
6. ¿Qué es `JSESSIONID` y quién la crea? *(Sesiones)*
7. ¿Cómo funciona el flujo de creación y recuperación de una sesión? *(Sesiones)*
8. ¿Qué métodos de `HttpSession` usarías para guardar, leer e invalidar datos? *(HttpSession)*
9. ¿Cómo se configura Spring Boot para guardar la sesión en base de datos? *(Configuración)*
10. ¿Cómo se migra un formulario encadenado (con `hidden`) a sesión? Da la equivalencia. *(Migración)*
11. ¿Por qué es un error usar una variable `static` en el controlador para el estado? *(Curiosidades)*
12. ¿Qué hace `@SuppressWarnings("unchecked")` y por qué aparece al leer de sesión? *(SuppressWarnings)*
13. ¿En qué se diferencian cookies y sesión en seguridad y tamaño? *(Comparativa)*
14. ¿Qué ocurre si el navegador no acepta cookies? ¿Y si el usuario cierra la pestaña? *(Curiosidades)*

<a id="conclusion"></a>

## Conclusión

Esta práctica me hizo tocar con las manos lo que hasta entonces había leído: que HTTP no recuerda nada y que todo lo que quieres conservar tiene que vivir en algún sitio. En D3-UD2 vivía en el formulario (campos ocultos); ahora vive en el servidor (sesión). El cambio es pequeño en código (`session.setAttribute` en vez de `<input type="hidden">`) pero grande en diseño: los datos dejan de viajar por el navegador.

También me quedo con la idea de que la sesión no es magia: por debajo usa una cookie (`JSESSIONID`), y si el navegador no la acepta hay que recurrir a la reescritura de URL. Y con que `@SuppressWarnings("unchecked")` no es un adorno: es la forma de decirle al compilador que el cast de `Object` a un tipo concreto es intencionado.

Con D1 (respuestas directas), D2 (plantillas y objetos), D3 (estado entre pasos) y esta (sesiones y cookies), el recorrido de la unidad queda completo: ya sé recibir datos, pintarlos, encadenarlos y, ahora, recordarlos.

<a id="recursos"></a>

## Recursos

- [Repositorio del proyecto en GitHub](https://github.com/KerinR432/DWES2)
- Apuntes del profesor: `Cookies y Session.pdf`
- Apuntes del profesor: `Sesiones.pdf`
- [Documentación de Spring Session](https://spring.io/projects/spring-session)
- [Documentación de Thymeleaf](https://www.thymeleaf.org/documentation.html)
- Stack Overflow y Gemini, como apoyo para el fallo del objeto que se sobrescribía en la sesión

<div class="endmark">
FIN DE LA TRANSMISIÓN // D1 · UD3
</div>