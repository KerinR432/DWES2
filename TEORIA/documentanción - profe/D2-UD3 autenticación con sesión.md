<link rel="stylesheet" href="../css/guia-galactica.css">

<div class="cover">
<p class="serial">CUADERNO DE PRÁCTICAS // DESARROLLO WEB EN ENTORNO SERVIDOR</p>

# D2 · UD3<br>SPRING BOOT

<p class="subtitle">Autenticación con sesiones y BCrypt</p>
<p>Kerin Aguilera</p>
<p class="serial">JAVA 21 · SPRING BOOT 4 · THYMELEAF · SPRING SECURITY CRYPTO · OCTUBRE 2026</p>
</div>

<div class="toc">
<p class="toc-title">ÍNDICE DE RUTA</p>
<ol>
<li><a href="#objetivo">Objetivo de la práctica</a></li>
<li><a href="#problema">El problema: proteger rutas y recordar al usuario</a></li>
<li><a href="#proyecto">Proyecto asociado: `seguridad`</a></li>
<li><a href="#pojo">El POJO: `Usuario`</a></li>
<li><a href="#controlador">El controlador: lista de usuarios y BCrypt</a>
<ul>
<li><a href="#usuarios-validos">Usuarios válidos y contraseñas hasheadas</a></li>
<li><a href="#proteccion">Protección de rutas con `HttpSession`</a></li>
<li><a href="#login">Login: procesar credenciales</a></li>
<li><a href="#logout">Logout: invalidar la sesión</a></li>
</ul>
</li>
<li><a href="#plantillas">Plantillas Thymeleaf</a></li>
<li><a href="#funcionamiento">En funcionamiento</a></li>
<li><a href="#bcrypt">BCrypt: por qué y cómo</a></li>
<li><a href="#detalles">Detalles y decisiones de diseño</a></li>
<li><a href="#resumen">Resumen de conceptos</a></li>
<li><a href="#repaso">Preguntas de repaso</a></li>
<li><a href="#conclusion">Conclusión</a></li>
<li><a href="#recursos">Recursos</a></li>
</ol>
</div>

<a id="objetivo"></a>

## Objetivo de la práctica

En D1 aprendimos a responder texto y JSON, y en D2 (UD2) a servir plantillas Thymeleaf con un objeto en el modelo. En D3 (UD2) vimos cómo sobreviven los datos entre pasos de un formulario mediante campos ocultos. Aquí el salto es de concepto: **proteger una aplicación** para que solo entren los usuarios autenticados, y que el servidor **recuerde** quién ha iniciado sesión entre peticiones.

La práctica construye una aplicación mínima con tres páginas protegidas (`/`, `/pagina1`, `/pagina2`), un formulario de login (`/login`) y un endpoint de logout (`/logout`). La identidad del usuario se guarda en la **sesión HTTP**, y las contraseñas se comparan con **BCrypt** en lugar de texto plano.

El recorrido tiene tres partes. Primero se monta el flujo con una lista de usuarios en memoria y comparación directa. Después se añade BCrypt para hashear las contraseñas. Por último se revisan los detalles de diseño: `@SessionAttributes`, `SessionStatus` y la protección de rutas.

Es la base sobre la que se apoyan el resto de prácticas con estado de usuario: carritos, roles y, más adelante, Spring Security completo.

<div class="spec">

| Pieza | Detalle |
|---|---|
| Proyecto | `seguridad` (`PROYECTOS/seguridad`) |
| Plantillas | `login`, `inicio`, `pagina1`, `pagina2` (Thymeleaf) |
| Novedad | `spring-security-crypto` (BCrypt) y `@SessionAttributes` |
| Conceptos clave | `HttpSession` · `@SessionAttributes` · `SessionStatus` · `BCryptPasswordEncoder` · protección de rutas |
| Usuarios de prueba | `admin` / `1234` · `ruvik` / `b432` |

</div>

<a id="problema"></a>

## El problema: proteger rutas y recordar al usuario

Hasta ahora cada petición era independiente: el servidor recibía datos, respondía y se olvidaba. Para una aplicación con login eso no sirve: si el usuario se autentica en `/login`, el servidor tiene que **recordar** esa identidad cuando visite `/pagina1` o `/pagina2` minutos después.

La estrategia de esta práctica es la que vimos en los apuntes de cookies y sesiones:

1. El usuario envía sus credenciales por POST a `/login`.
2. El servidor valida usuario y contraseña.
3. Si son correctas, guarda un objeto `Usuario` en la **sesión HTTP** (`HttpSession`), identificada por la cookie `JSESSIONID`.
4. Cada ruta protegida comprueba si existe ese objeto en sesión; si no existe, redirige a `/login`.
5. Al hacer logout, se invalida la sesión y el usuario vuelve a la pantalla de login.

La identidad **viaja en el servidor**, no en el navegador: el navegador solo guarda el `JSESSIONID`. Por eso es más seguro que pasar el usuario por campos ocultos o por la URL.

<a id="proyecto"></a>

## Proyecto asociado: `seguridad`

El código de esta práctica vive en `PROYECTOS/seguridad`. Es un proyecto Spring Boot 4.1.2 con Thymeleaf y la dependencia `spring-security-crypto` (solo la parte de cifrado, sin el stack completo de Spring Security). La estructura relevante:

```
seguridad/
├── src/main/java/Ruvik/UD3/seguridad/
│   ├── SeguridadApplication.java
│   ├── Controller/
│   │   └── WebController.java
│   └── Entity/
│       └── Usuario.java
├── src/main/resources/
│   ├── application.properties
│   └── templates/
│       ├── login.html
│       ├── inicio.html
│       ├── pagina1.html
│       └── pagina2.html
└── build.gradle
```

El `build.gradle` declara Java 21, Spring Boot 4.1.2, Thymeleaf, WebMVC y la librería de cifrado:

```gradle
plugins {
    id 'java'
    id 'org.springframework.boot' version '4.1.2'
    id 'io.spring.dependency-management' version '1.1.7'
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-thymeleaf'
    implementation 'org.springframework.boot:spring-boot-starter-webmvc'
    testImplementation 'org.springframework.boot:spring-boot-starter-thymeleaf-test'
    testImplementation 'org.springframework.boot:spring-boot-starter-webmvc-test'
    testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
    implementation 'org.springframework.security:spring-security-crypto'
}
```

> La clave está en `spring-security-crypto`: aporta `BCryptPasswordEncoder` sin arrastrar el resto de Spring Security (filtros, configuración de seguridad, etc.). Para una práctica didáctica es suficiente; en producción se suele usar Spring Security completo.

<a id="pojo"></a>

## El POJO: `Usuario`

El objeto que representa al usuario autenticado es mínimo: nombre y contraseña. La contraseña del formulario viaja en texto plano hasta el servidor; allí se compara con el hash guardado.

```java
package Ruvik.UD3.seguridad.Entity;

public class Usuario {
    private String nombre;
    private String contraseña;

    public Usuario() {
    }

    public Usuario(String nombre, String contraseña) {
        this.nombre = nombre;
        this.contraseña = contraseña;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getContraseña() {
        return contraseña;
    }

    public void setContraseña(String contraseña) {
        this.contraseña = contraseña;
    }
}
```

Detalle importante: el campo se llama `contraseña` (con ñ). Thymeleaf enlaza el input con `th:field="*{contraseña}"` y Spring busca el getter/setter correspondiente. Funciona, pero es una fuente de problemas si la codificación del archivo no es UTF-8. En un proyecto real conviene usar `password` en inglés para evitar sorpresas.

![POJO Usuario de la práctica](img%20-%20documents/D2-UD3.4.png)

<a id="controlador"></a>

## El controlador: lista de usuarios y BCrypt

El controlador concentra toda la lógica: la lista de usuarios válidos, la protección de rutas, el login y el logout.

```java
package Ruvik.UD3.seguridad.Controller;

import Ruvik.UD3.seguridad.Entity.Usuario;
import jakarta.servlet.http.HttpSession;
import org.springframework.boot.web.server.servlet.Session;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.support.SessionStatus;

import java.util.HashMap;
import java.util.Map;

@Controller
@SessionAttributes("usuario")
public class WebController {
    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    private final Map<String, String> usuariosValidos;

    public WebController() {
        usuariosValidos = new HashMap<>();
        usuariosValidos.put("admin", passwordEncoder.encode("1234"));
        usuariosValidos.put("ruvik", passwordEncoder.encode("b432"));
    }

    @GetMapping("/")
    public String rutaInicio(HttpSession session) {
        Usuario user = (Usuario) session.getAttribute("usuario");
        System.out.println("Estoy dentro de inicio");
        if (user == null) {
            System.out.println("No existe usuario");
            return "redirect:/login";
        }
        return "inicio";
    }

    @GetMapping("/pagina1")
    public String pagina1(HttpSession session) {
        Usuario user = (Usuario) session.getAttribute("usuario");
        System.out.println("Estoy dentro de pagina 1");
        if (user == null) {
            System.out.println("No existe usuario");
            return "redirect:/login";
        }
        return "pagina1";
    }

    @GetMapping("/pagina2")
    public String pagina2(HttpSession session) {
        Usuario user = (Usuario) session.getAttribute("usuario");
        System.out.println("Estoy dentro de pagina 2");
        if (user == null) {
            System.out.println("No existe usuario");
            return "redirect:/login";
        }
        return "pagina2";
    }

    @GetMapping("/login")
    public String login(HttpSession sesion, Model modelo) {
        System.out.println("Estoy dentro de login");
        if (sesion.getAttribute("usuario") != null) {
            System.out.println("existe nombre");
            return "redirect:/";
        }
        modelo.addAttribute("usuario", new Usuario());
        return "login";
    }

    @PostMapping("/login")
    public String procesarLogin(@ModelAttribute Usuario usuarioForm, HttpSession sesion, Model modelo) {
        System.out.println("el usuario es: " + usuarioForm.getNombre());
        System.out.printf("El valido usuario es: " + usuariosValidos.get("admin"));
        System.out.println("La contraseña usuario es: " + usuarioForm.getContraseña());
        System.out.printf("La contraseña valida " + usuariosValidos.get("1234"));
        if (usuariosValidos.containsKey(usuarioForm.getNombre())
                && passwordEncoder.matches(usuarioForm.getContraseña(),
                        usuariosValidos.get(usuarioForm.getNombre()))) {
            sesion.setAttribute("usuario", usuarioForm);
            return "redirect:/";
        }
        modelo.addAttribute("error", "Usuario o contraseña son incorrectos");
        return "login";
    }

    @GetMapping("/logout")
    public String logout(HttpSession sesion, SessionStatus status, Model modelo) {
        status.setComplete();
        sesion.invalidate();
        return "redirect:/login";
    }
}
```

<a id="usuarios-validos"></a>

### Usuarios válidos y contraseñas hasheadas

En el constructor se crea un `HashMap<String, String>` cuyas claves son los nombres de usuario y cuyos valores son **el hash BCrypt** de la contraseña. No se guarda la contraseña en claro en ningún sitio:

```java
usuariosValidos = new HashMap<>();
usuariosValidos.put("admin", passwordEncoder.encode("1234"));
usuariosValidos.put("ruvik", passwordEncoder.encode("b432"));
```

`passwordEncoder.encode(...)` genera un hash distinto en cada ejecución (por el *salt* aleatorio), así que dos hashes del mismo texto no coinciden entre sí. Por eso **no se compara con `equals`**, sino con `matches`.

![Lista de usuarios válidos y BCrypt](img%20-%20documents/D2-UD3.9.png)

<a id="proteccion"></a>

### Protección de rutas con `HttpSession`

Las tres rutas protegidas (`/`, `/pagina1`, `/pagina2`) siguen el mismo patrón: recuperar el `Usuario` de la sesión y, si es `null`, redirigir a `/login`:

```java
@GetMapping("/pagina1")
public String pagina1(HttpSession session) {
    Usuario user = (Usuario) session.getAttribute("usuario");
    if (user == null) {
        return "redirect:/login";
    }
    return "pagina1";
}
```

Es la protección manual más sencilla: sin frameworks de seguridad, basta con comprobar el atributo en sesión. El coste es que hay que repetir el chequeo en cada método (o extraerlo a un interceptor, que sería el siguiente paso).

> El cast `(Usuario) session.getAttribute(...)` devuelve `Object`, así que el compilador avisa de cast no comprobado. En una versión más limpia se encapsularía el acceso a la sesión en un helper tipado, o se usaría `@SessionAttributes` (ver la sección de detalles).

<a id="login"></a>

### Login: procesar credenciales

El GET `/login` prepara un `Usuario` vacío en el modelo para que Thymeleaf pueda enlazar el formulario. Si ya hay sesión, redirige a la portada:

```java
@GetMapping("/login")
public String login(HttpSession sesion, Model modelo) {
    if (sesion.getAttribute("usuario") != null) {
        return "redirect:/";
    }
    modelo.addAttribute("usuario", new Usuario());
    return "login";
}
```

El POST `/login` recibe el formulario como `@ModelAttribute Usuario`, busca el usuario en el mapa y compara la contraseña con BCrypt:

```java
@PostMapping("/login")
public String procesarLogin(@ModelAttribute Usuario usuarioForm, HttpSession sesion, Model modelo) {
    if (usuariosValidos.containsKey(usuarioForm.getNombre())
            && passwordEncoder.matches(usuarioForm.getContraseña(),
                    usuariosValidos.get(usuarioForm.getNombre()))) {
        sesion.setAttribute("usuario", usuarioForm);
        return "redirect:/";
    }
    modelo.addAttribute("error", "Usuario o contraseña son incorrectos");
    return "login";
}
```

Si las credenciales son válidas, guarda el `Usuario` del formulario en sesión y redirige a `/`. Si no, añade un mensaje de error al modelo y vuelve a mostrar `login.html`.

![Procesado de login con BCrypt](img%20-%20documents/D2-UD3.10.png)

<a id="logout"></a>

### Logout: invalidar la sesión

Cerrar sesión tiene dos pasos: avisar a Spring de que el atributo de sesión gestionado por `@SessionAttributes` ya no es válido, e invalidar la `HttpSession` completa:

```java
@GetMapping("/logout")
public String logout(HttpSession sesion, SessionStatus status, Model modelo) {
    status.setComplete();
    sesion.invalidate();
    return "redirect:/login";
}
```

- `status.setComplete()` le dice a Spring que el atributo `usuario` (declarado en `@SessionAttributes`) deja de mantenerse en la sesión de modelo.
- `sesion.invalidate()` borra la `HttpSession` del servidor y caduca la cookie `JSESSIONID`.

Tras eso, cualquier ruta protegida encontrará `session.getAttribute("usuario") == null` y redirigirá a `/login`.

![Deslogueo: invalidación de sesión](img%20-%20documents/D2-UD3.3.png)

<a id="plantillas"></a>

## Plantillas Thymeleaf

### `login.html`

Formulario que enlaza con el objeto `usuario` del modelo. Muestra el error si existe:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>LOGIN</title>
</head>
<body>
    <form action="/login" th:object="${usuario}" th:action="@{/login}" method="post">
        <label>Introduce nombre de usuario</label>
        <input type="text" th:field="*{nombre}"/>
        <p th:if="${error}" th:text="${error}"></p>
        <label>Introduce password</label>
        <input type="password" th:field="*{contraseña}"/>
        <button type="submit">Enviar</button>
    </form>
</body>
</html>
```

`th:object="${usuario}"` vincula el formulario al objeto del modelo y `th:field="*{nombre}"` genera el `name` y el `value` del input. El `<p th:if="${error}">` solo se renderiza si el controlador añadió el atributo `error`.

### `inicio.html`, `pagina1.html`, `pagina2.html`

Las tres páginas protegidas muestran el nombre del usuario autenticado leyendo `${usuario.nombre}` del modelo (que Spring repone desde la sesión gracias a `@SessionAttributes`) y ofrecen navegación entre ellas y un enlace de logout:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>INICIO</title>
</head>
<body>
    <h1>BIENVENIDO <span th:text="${usuario.nombre}"></span>, estás en Inicio</h1>
    <nav>
        <a th:href="@{/pagina1}">Ir a Página 1</a>
        <a th:href="@{/pagina2}">Ir a Página 2</a>
        <a th:href="@{/logout}">Cerrar sesión</a>
    </nav>
</body>
</html>
```

`pagina1.html` y `pagina2.html` son análogas, cambiando el título y los enlaces de navegación. En todas ellas el nombre se toma de `${usuario.nombre}`, sin tener que volver a consultarlo en el controlador.

<a id="funcionamiento"></a>

## En funcionamiento

Al principio se mete un dato erróneo (usuario o contraseña incorrectos): el servidor devuelve el formulario de login con el mensaje de error.

![Login con credenciales incorrectas](img%20-%20documents/D2-UD3.5.png)

Metemos los datos correctos (`admin` / `1234` o `ruvik` / `b432`): el servidor valida, guarda el `Usuario` en sesión y redirige a la portada.

![Login con credenciales correctas](img%20-%20documents/D2-UD3.6.png)

Pasamos por las páginas protegidas: el nombre se mantiene entre navegaciones porque la identidad vive en la sesión del servidor.

![Navegación por las páginas protegidas](img%20-%20documents/D2-UD3.7.png)

Cerramos la sesión con el enlace de logout: la `HttpSession` se invalida y el navegador vuelve a `/login`.

![Cierre de sesión](img%20-%20documents/D2-UD3.8.png)

El flujo básico de autenticación (lista de usuarios en memoria, comparación directa) se ve así:

![Flujo básico de autenticación con sesiones](img%20-%20documents/D2-UD3.1.png)

Y el controlador que procesa el login, antes de añadir BCrypt, tenía este aspecto:

![Controlador de login procesando datos](img%20-%20documents/D2-UD3.2.png)

<a id="bcrypt"></a>

## BCrypt: por qué y cómo

Guardar contraseñas en texto plano (o compararlas con `equals`) es un error grave: si alguien accede a la base de datos o al código, obtiene todas las contraseñas. BCrypt resuelve dos problemas:

1. **No es reversible**: a partir del hash no se puede recuperar la contraseña original.
2. **Incluye salt aleatorio**: dos hashes del mismo texto son distintos, así que no se pueden comparar tablas de hashes precalculados (*rainbow tables*).

En el proyecto se añade la dependencia `spring-security-crypto` y se cambian dos cosas en el código:

- En el constructor, las contraseñas se guardan **hasheadas**:
  ```java
  usuariosValidos.put("admin", passwordEncoder.encode("1234"));
  usuariosValidos.put("ruvik", passwordEncoder.encode("b432"));
  ```

- En el login, ya no se compara el texto plano, sino el hash:
  ```java
  passwordEncoder.matches(usuarioForm.getContraseña(), usuariosValidos.get(usuarioForm.getNombre()))
  ```

`matches(textoPlano, hash)` recalcula internamente el hash del texto plano usando el salt que va incrustado en el hash guardado y compara. Si coinciden, la contraseña es correcta.

> BCrypt es deliberadamente lento (coste configurable) para dificultar ataques por fuerza bruta. Para una práctica con dos usuarios en memoria no se nota; en producción se ajusta el factor de coste según la carga.

<a id="detalles"></a>

## Detalles y decisiones de diseño

### `@SessionAttributes` vs `HttpSession` manual

El controlador declara `@SessionAttributes("usuario")` **y** usa `sesion.setAttribute("usuario", ...)` a mano. Las dos cosas conviven en este ejemplo, pero conviene entender la diferencia:

- `@SessionAttributes("usuario")` le dice a Spring: "el atributo de modelo llamado `usuario` debe persistirse en la sesión entre peticiones". Spring lo gestiona automáticamente y lo repone en el modelo al renderizar.
- `sesion.setAttribute(...)` es la API estándar de Servlets: tú controlas cuándo se guarda y cuándo se borra.

Mezclarlas funciona porque Spring sincroniza el atributo de modelo con la sesión, pero en un proyecto real es mejor elegir una sola estrategia. Para login/autenticación, `HttpSession` manual suele ser más claro; `@SessionAttributes` brilla cuando el estado es parte del flujo de un formulario (como en D3).

### `SessionStatus.setComplete()`

Cuando se usa `@SessionAttributes`, Spring mantiene el atributo en una sesión de modelo interna. `status.setComplete()` avisa de que ese estado ya no debe conservarse. Combinado con `sesion.invalidate()`, garantiza que no queda rastro del usuario.

### Protección manual vs Spring Security

La protección de rutas aquí es un `if (user == null) return "redirect:/login"` repetido en cada método. Funciona para una práctica, pero no escala: cada nueva ruta protegida exige recordar el chequeo. Spring Security resuelve esto con filtros y reglas declarativas (`http.authorizeHttpRequests(...)`), pero su configuración queda fuera del alcance de esta unidad.

### Huellas de depuración

El controlador incluye varios `System.out.println` (trazas de "Estoy dentro de...", "el usuario es...", etc.). Son útiles mientras se desarrolla para ver el flujo en la consola, pero en un proyecto real conviene sustituirlos por un logger (`slf4j`) y eliminarlos del código final.

### Import no utilizado

La línea `import org.springframework.boot.web.server.servlet.Session;` no se usa en el controlador. Es un resto de pruebas; se puede eliminar sin afectar al funcionamiento.

<a id="resumen"></a>

## Resumen de conceptos

| Elemento | Qué hace |
|---|---|
| `HttpSession` | Objeto de sesión del servidor, identificado por la cookie `JSESSIONID` |
| `session.getAttribute("usuario")` | Recupera el usuario autenticado (o `null` si no hay sesión) |
| `session.setAttribute("usuario", obj)` | Guarda el usuario en sesión tras un login correcto |
| `session.invalidate()` | Borra la sesión del servidor (logout) |
| `@SessionAttributes("usuario")` | Persiste el atributo de modelo `usuario` entre peticiones |
| `SessionStatus.setComplete()` | Avisa a Spring de que el estado de sesión de modelo ya no se conserva |
| `BCryptPasswordEncoder` | Genera y verifica hashes BCrypt (con salt aleatorio) |
| `passwordEncoder.encode(texto)` | Genera el hash de una contraseña |
| `passwordEncoder.matches(plano, hash)` | Verifica si un texto plano coincide con un hash |
| `redirect:/login` | Redirección HTTP a la pantalla de login |
| `th:if="${error}"` | Renderiza el mensaje de error solo si existe |

Ideas clave que me llevo de la práctica:

- **HTTP no recuerda nada**: la identidad tiene que guardarse en el servidor (sesión) o viajar en cada petición.
- La sesión usa por debajo la cookie `JSESSIONID`, gestionada por el contenedor (Tomcat); tú no la creas a mano.
- **Nunca guardar contraseñas en claro**: BCrypt (o similar) es el mínimo exigible.
- `encode` y `matches` son las dos operaciones de BCrypt: una para guardar, otra para verificar.
- Proteger rutas a mano (`if (user == null)`) funciona para aprender, pero en producción se delega en Spring Security.
- Mezclar `@SessionAttributes` con `HttpSession` manual funciona, pero conviene elegir una sola estrategia.

<a id="repaso"></a>

## Preguntas de repaso

1. ¿Por qué no basta con pasar el nombre de usuario en la URL o en un campo oculto para "recordar" al usuario? *(El problema)*
2. ¿Qué objeto guarda el servidor para identificar la sesión y qué cookie viaja en el navegador? *(El problema)*
3. ¿Qué hace `session.getAttribute("usuario")` en las rutas protegidas y qué se devuelve si no hay sesión? *(Protección de rutas)*
4. ¿Por qué en el constructor se guarda `passwordEncoder.encode("1234")` en vez de `"1234"`? *(Usuarios válidos)*
5. ¿Por qué no se puede comparar dos hashes BCrypt con `equals`? ¿Qué método se usa? *(Usuarios válidos / Login)*
6. ¿Qué diferencia hay entre `@SessionAttributes("usuario")` y `sesion.setAttribute("usuario", ...)`? *(Detalles)*
7. ¿Para qué sirven `status.setComplete()` y `sesion.invalidate()` en el logout? ¿Por qué se usan los dos? *(Logout)*
8. ¿Qué aporta BCrypt frente a guardar la contraseña en texto plano o con un hash simple (MD5/SHA-1)? *(BCrypt)*
9. ¿Qué ocurre si un usuario no autenticado intenta entrar directamente a `/pagina2` por la URL? *(Protección de rutas)*
10. ¿Por qué la protección manual con `if (user == null)` no escala y qué alternativa menciona la práctica? *(Detalles)*
11. ¿Qué papel juega `th:if="${error}"` en `login.html` y cuándo se muestra? *(Plantillas)*
12. ¿Por qué conviene eliminar los `System.out.println` y el import no utilizado del controlador final? *(Detalles)*

<a id="conclusion"></a>

## Conclusión

Esta práctica me hizo ver la autenticación como un problema de **estado**: el servidor tiene que recordar quién soy entre clics, y la forma natural de hacerlo en una aplicación web tradicional es la sesión HTTP. Montar el flujo a mano (chequeo en cada ruta, login que guarda en sesión, logout que la invalida) es laborioso pero deja claro qué hace Spring Security por debajo cuando lo usas.

El segundo aprendizaje fue BCrypt: entender que un hash con salt no se compara con `equals`, sino con `matches`, y que `encode` produce un valor distinto cada vez aunque la contraseña sea la misma. Ese detalle, que al principio parece un bug, es en realidad la protección contra tablas de hashes precalculados.

Con D1 (respuestas directas), D2 (plantillas y objetos), D3 (estado entre pasos) y esta práctica (autenticación), el recorrido de la unidad queda cerrado: ya tengo una aplicación web pequeña que identifica al usuario, protege sus rutas y gestiona su sesión de principio a fin.

<a id="recursos"></a>

## Recursos

- [Repositorio del proyecto en GitHub](https://github.com/KerinR432/DWES2)
- [Documentación de Spring Security Crypto (BCryptPasswordEncoder)](https://docs.spring.io/spring-security/reference/features/authentication/password-storage.html)
- [Documentación de HttpSession (Servlet API)](https://jakarta.ee/specifications/servlet/6.0/apidocs/jakarta/servlet/http/httpsession)
- [Thymeleaf + Spring](https://www.thymeleaf.org/doc/tutorials/3.1/thymeleafspring.html)
- Stack Overflow, para el problema de mezclar `@SessionAttributes` con `HttpSession`
- Gemini, como apoyo para interpretar los mensajes de error

<div class="endmark">
FIN DEL REGISTRO DE NAVEGACIÓN // D2 · UD3
</div>