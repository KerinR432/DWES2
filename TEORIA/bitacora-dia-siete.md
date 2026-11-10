<div class="cover">
<h1>Bitácora de desarrollo</h1>
<p>SPRING BOOT · PRIMEROS ENDPOINTS Y FORMULARIOS</p>
<p class="serial">DÍA 7 // GUÍA DE CAMPO · DESARROLLO WEB</p>
</div>

## Índice

1. [Objetivo de la sesión](#objetivo-de-la-sesión)
2. [Qué es Spring Boot y cómo se crea el proyecto](#qué-es-spring-boot-y-cómo-se-crea-el-proyecto)
3. [Anatomía del proyecto](#anatomía-del-proyecto)
4. [Primer endpoint: `GET /hello`](#primer-endpoint-get-hello)
5. [GET y POST: dos verbos, dos trabajos](#get-y-post-dos-verbos-dos-trabajos)
6. [Formulario HTML y `POST`](#formulario-html-y-post)
7. [El recorrido completo de una petición](#el-recorrido-completo-de-una-petición)
8. [Errores que cometí (y cómo diagnosticarlos)](#errores-que-cometí-y-cómo-diagnosticarlos)
9. [Comparación con las bitácoras anteriores](#comparación-con-las-bitácoras-anteriores)
10. [Chuleta de código](#chuleta-de-código)
11. [Pendientes y preguntas](#pendientes-y-preguntas)

---

## Objetivo de la sesión

> En esta sesión hice una primera prueba con **Spring Boot**: creé un endpoint `GET` para saludar y trabajé el envío de un formulario mediante `POST`.

Los objetivos concretos eran:

- Entender qué aporta Spring Boot frente a un servidor Java «a mano».
- Arrancar una aplicación con servidor integrado.
- Publicar un primer endpoint y comprobar la respuesta en el navegador.
- Recibir datos de un formulario y devolver una respuesta elaborada con ellos.
- Diferenciar de una vez por todas `GET` y `POST`.

> 💡 **Idea clave del día:** un endpoint es una **ruta + un método HTTP + una función Java** que devuelve una respuesta. Todo lo demás (servidor, puerto, serialización) lo pone Spring Boot.

---

## Qué es Spring Boot y cómo se crea el proyecto

**Spring** es un ecosistema de librerías para Java. **Spring Boot** es la capa que lo hace arrancable sin configuración manual: trae un servidor embebido, autoconfigura lo necesario y empaqueta la aplicación como un `.jar` ejecutable.

Sin Spring Boot habría que:

- Instalar y configurar un servidor (Tomcat, Jetty…).
- Declarar servlets y mapeos.
- Gestionar dependencias y versiones a mano.
- Desplegar un `.war`.

Con Spring Boot basta con un `main` y una anotación.

### Crear el proyecto

Se puede generar desde **[start.spring.io](https://start.spring.io)** o desde IntelliJ IDEA. Los datos que usé:

| Campo | Valor |
| --- | --- |
| Proyecto | Gradle (o Maven) |
| Lenguaje | Java |
| Versión | Java 21 |
| Spring Boot | 4.1.x |
| Dependencia | Spring Web (`spring-boot-starter-webmvc`) |

> ⚠️ **Corrección respecto a mis apuntes originales:** allí anoté que usé **Maven**. El proyecto que quedó en el repositorio (`PROYECTOS/demo`) está creado con **Gradle** (Gradle 9.7.1, Spring Boot 4.1.1). El flujo de trabajo es idéntico; solo cambian los comandos. En esta bitácora dejo los dos.

### Maven vs Gradle

| Aspecto | Maven | Gradle |
| --- | --- | --- |
| Fichero de configuración | `pom.xml` | `build.gradle` |
| Arrancar en desarrollo | `./mvnw spring-boot:run` | `./gradlew bootRun` |
| Compilar y empaquetar | `./mvnw package` | `./gradlew build` |
| Ejecutar tests | `./mvnw test` | `./gradlew test` |
| Generar el `.jar` | `target/*.jar` | `build/libs/*.jar` |

Ambos usan el **Maven Wrapper** o el **Gradle Wrapper** (`mvnw` / `gradlew`), que evitan tener que instalar la herramienta a mano.

### La dependencia

```groovy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-webmvc'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    testImplementation 'org.springframework.boot:spring-boot-starter-webmvc-test'
    testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
}
```

- **`spring-boot-starter-webmvc`** trae Spring MVC y el servidor Tomcat embebido. En versiones anteriores el starter clásico era `spring-boot-starter-web`; en este proyecto aparece con el nombre `webmvc`.
- **`spring-boot-devtools`** permite recargar la aplicación al cambiar el código (hot reload), como vimos en el día 5.
- La dependencia de test sirve para comprobar que el contexto de Spring arranca.

---

## Anatomía del proyecto

```text
demo/
├── build.gradle
├── settings.gradle
├── gradlew
└── src/
    ├── main/
    │   ├── java/com/example/demo/
    │   │   └── DemoApplication.java
    │   └── resources/
    │       ├── application.properties
    │       └── static/
    │           └── index.html
    └── test/java/com/example/demo/
        └── DemoApplicationTests.java
```

| Elemento | Para qué sirve |
| --- | --- |
| `src/main/java` | Código Java de la aplicación |
| `src/main/resources` | Recursos: configuración y ficheros estáticos |
| `src/main/resources/static` | HTML, CSS, JS e imágenes servidos tal cual |
| `src/main/resources/templates` | Plantillas (Thymeleaf, etc.) — se verá más adelante |
| `application.properties` | Configuración (nombre, puerto, etc.) |
| `src/test/java` | Pruebas automáticas |

### El arranque

```java
package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
```

`@SpringBootApplication` agrupa tres cosas:

| Anotación interna | Qué hace |
| --- | --- |
| `@SpringBootConfiguration` | Marca la clase como configuración |
| `@EnableAutoConfiguration` | Configura automáticamente lo que detecta en el classpath |
| `@ComponentScan` | Busca `@Component`, `@Controller`, `@Service`… en el paquete y subpaquetes |

Por eso el paquete `com.example.demo` importa: todo lo que se cree **debajo** de él será detectado.

Al ejecutar `./gradlew bootRun`:

```text
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::                (v4.1.1)

Tomcat started on port 8080 (http)
Started DemoApplication in 1.2 seconds
```

La aplicación queda escuchando en **`http://localhost:8080`**. El puerto se cambia en `application.properties`:

```properties
server.port=8080
spring.application.name=demo
```

---

## Primer endpoint: `GET /hello`

El primer endpoint de la práctica:

```java
package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }

    @GetMapping("/hello")
    public String hello(
            @RequestParam(value = "name", defaultValue = "World") String name) {
        return String.format("Hello %s", name);
    }
}
```

### Qué hace cada anotación

| Anotación | Función |
| --- | --- |
| `@SpringBootApplication` | Arranca y configura la aplicación |
| `@RestController` | Marca la clase como controlador y escribe lo que devuelve directamente en el cuerpo de la respuesta |
| `@GetMapping("/hello")` | Asocia una petición `GET /hello` a ese método |
| `@RequestParam` | Toma un parámetro de la URL (`?name=...`) y lo pasa al argumento |

`@RestController` equivale a `@Controller` + `@ResponseBody`. Es decir: **lo que devuelve el método es el cuerpo de la respuesta**, no el nombre de una plantilla.

> 📌 En el repositorio, la versión actual de `DemoApplication` conserva el `@PostMapping` del formulario pero ya no tiene el `@GetMapping("/hello")`. El código de arriba es el que se trabajó en clase; sirve para entender el primer endpoint antes de pasar al formulario.

### Probar el endpoint

Al visitar `/hello` sin parámetros, `name` no llega y se usa el valor por defecto `World`:

**Petición a `/hello`:**

![URL de /hello](imagenes/springboot1.png)

**Respuesta:**

![Respuesta Hello World](imagenes/springboot2.png)

Si añado `?name=ruvik`, Spring recibe ese valor y lo incluye en el saludo:

**Petición a `/hello?name=ruvik`:**

![URL de /hello con el parámetro name](imagenes/springboot3.png)

**Respuesta:**

![Respuesta Hello ruvik](imagenes/springboot4.png)

### La petición por dentro

```http
GET /hello?name=ruvik HTTP/1.1
Host: localhost:8080
Accept: text/html
```

```http
HTTP/1.1 200 OK
Content-Type: text/plain;charset=UTF-8

Hello ruvik
```

También se puede probar sin navegador:

```bash
curl "http://localhost:8080/hello"
# Hello World

curl "http://localhost:8080/hello?name=ruvik"
# Hello ruvik
```

### Detalles de `@RequestParam`

```java
@RequestParam(value = "name", defaultValue = "World") String name
```

| Atributo | Qué hace |
| --- | --- |
| `value` / `name` | Nombre del parámetro en la URL |
| `required` | Si es obligatorio (por defecto `true`) |
| `defaultValue` | Valor si no llega el parámetro |

- Si se pone `defaultValue`, el parámetro deja de ser obligatorio.
- Si es obligatorio y no llega, Spring responde **`400 Bad Request`**.
- Si la ruta no existe, responde **`404 Not Found`**.
- Si la ruta existe pero el método HTTP no coincide, responde **`405 Method Not Allowed`**.

> 🔗 Esto enlaza con el **día 2**: una petición HTTP tiene línea de petición, cabeceras, línea en blanco y cuerpo. Aquí Spring se encarga de leerlos por nosotros.

---

## GET y POST: dos verbos, dos trabajos

Al principio confundí sus funciones. Se usan en el mismo flujo, pero **no son intercambiables**:

| | `GET` | `POST` |
| --- | --- | --- |
| Para qué sirve | **Pedir** un recurso | **Enviar** datos para que se procesen |
| Dónde van los datos | En la URL (`?clave=valor`) | En el cuerpo de la petición |
| Visible en la barra | Sí | No |
| Se puede guardar en favoritos | Sí | No |
| Longitud | Limitada por la URL | Mucho mayor |
| Idempotente | Sí (repetir no cambia nada) | No (repetir puede duplicar) |
| Ejemplo | Ver el formulario | Enviar el formulario |

En un formulario típico se usan **los dos**:

```text
GET  /formulario   ──►  el servidor devuelve el HTML del formulario
POST /formulario   ──►  el servidor recibe los datos y responde con el resultado
```

> ⚠️ **Error de principiante:** poner `method="GET"` en un formulario que envía datos. Los datos acaban en la URL, se ven, se pueden modificar y tienen límite de tamaño. Para enviar información se usa `POST`.

---

## Formulario HTML y `POST`

### Dónde se guarda el HTML

Para servir un HTML **estático** con Spring Web, el archivo se guarda en:

```text
src/main/resources/static/
```

y se abre directamente en la URL correspondiente. Por ejemplo:

| Archivo | URL |
| --- | --- |
| `static/index.html` | `/` o `/index.html` |
| `static/formulario.html` | `/formulario.html` |

No hace falta crear un `@GetMapping` que devuelva la ruta del archivo: Spring Boot sirve automáticamente lo que hay en `static/`.

> 📌 En clase lo llamé `formulario.html`; en el repositorio quedó como `index.html`. La diferencia es solo el nombre y la URL con la que se abre.

### El formulario

```html
<!DOCTYPE html>
<html lang="es">
<body>
    <form method="POST" action="/formulario">
        <label for="nombre">Nombre:</label>
        <input type="text" name="nombre" id="nombre">
        <button type="submit">Enviar</button>
    </form>
</body>
</html>
```

Tres atributos son críticos:

| Atributo | Valor | Por qué |
| --- | --- | --- |
| `method` | `POST` | Los datos viajan en el cuerpo |
| `action` | `/formulario` | **Debe coincidir** con la ruta del `@PostMapping` |
| `name` | `nombre` | **Debe coincidir** con el nombre que espera `@RequestParam` |

### El controlador

```java
@PostMapping("/formulario")
public String procesarDatos(@RequestParam("nombre") String nombre) {
    if (!nombre.isBlank()) {
        return String.format("Hola %s", nombre);
    }
    return "Hola mundo";
}
```

Recorrido:

```text
<form action="/formulario" method="POST">
        │
        │  nombre=Ruvik
        ▼
@PostMapping("/formulario")
        │
        │  @RequestParam("nombre") → "Ruvik"
        ▼
   "Hola Ruvik"
        │
        ▼
   cuerpo de la respuesta HTTP
```

### `isEmpty()` vs `isBlank()`

En el proyecto del repositorio aparece:

```java
if (!nombre.isEmpty()) { ... }
```

`isEmpty()` solo comprueba que la cadena tenga longitud 0. Si el usuario escribe **solo espacios**, `"   ".isEmpty()` es `false` y el programa respondería `Hola    `.

Lo correcto es:

```java
if (!nombre.isBlank()) { ... }
```

`isBlank()` considera vacía una cadena con solo espacios, tabuladores o saltos de línea. Es la opción que dejé en la versión corregida.

### `enctype`: el detalle del formulario del repo

El `index.html` del repositorio tiene:

```html
<form method="POST" action="/formulario" enctype="multipart/form-data">
```

`multipart/form-data` se usa para **subir archivos**. Para texto normal, el valor por defecto (`application/x-www-form-urlencoded`) es suficiente y más sencillo. En este caso funciona porque Spring Boot registra un resolutor de multipart, pero es innecesario.

| `enctype` | Cuándo usarlo |
| --- | --- |
| `application/x-www-form-urlencoded` | Formularios de texto (por defecto) |
| `multipart/form-data` | Cuando hay `<input type="file">` |
| `text/plain` | Casos muy concretos; casi nunca |

### `@RestController` y los textos

Con `@RestController`, devolver `"Hola Ruvik"` **no** busca una plantilla llamada `Hola Ruvik`: escribe ese texto tal cual en la respuesta. Eso explica por qué en esta práctica no hizo falta Thymeleaf.

Para devolver una página HTML se necesitará más adelante `@Controller` + plantillas (día 10).

### Probar el POST sin navegador

```bash
curl -X POST -d "nombre=Ruvik" http://localhost:8080/formulario
# Hola Ruvik
```

En el navegador se puede comprobar en **DevTools → Network → formulario → Payload/Form Data**, donde aparece `nombre: Ruvik`.

---

## El recorrido completo de una petición

```text
Navegador
   │
   │ 1. GET /formulario.html
   ▼
Tomcat embebido
   │
   │ 2. sirve el archivo de static/
   ▼
Navegador (pinta el formulario)
   │
   │ 3. POST /formulario  (nombre=Ruvik)
   ▼
DispatcherServlet de Spring MVC
   │
   │ 4. busca el método con @PostMapping("/formulario")
   ▼
DemoApplication.procesarDatos()
   │
   │ 5. @RequestParam extrae "nombre"
   ▼
"Hello Ruvik"
   │
   │ 6. @RestController escribe el texto en el cuerpo
   ▼
Navegador (muestra el resultado)
```

| Paso | Responsable |
| --- | --- |
| Servir el HTML estático | Spring Boot (`static/`) |
| Escuchar en el puerto | Tomcat embebido |
| Enrutar la petición | `DispatcherServlet` + `@GetMapping` / `@PostMapping` |
| Leer parámetros | `@RequestParam` |
| Escribir la respuesta | `@RestController` (`@ResponseBody`) |

---

## Errores que cometí (y cómo diagnosticarlos)

| Síntoma | Causa probable | Solución |
| --- | --- | --- |
| `404 Not Found` | La ruta de `action` no coincide con la del `@PostMapping`, o el HTML no está en `static/` | Revisar ambas rutas y la carpeta |
| `405 Method Not Allowed` | El formulario envía `GET` pero el método es `@PostMapping` (o al revés) | Igualar `method` y anotación |
| `400 Bad Request` | Falta un `@RequestParam` obligatorio | Añadir `required = false` o `defaultValue` |
| El parámetro llega `null` | El `name` del input no coincide con el de `@RequestParam` | Igualar los nombres |
| Se ve el texto `"formulario"` en pantalla | Un `@RestController` devolviendo el nombre de una plantilla | Usar `@Controller` + Thymeleaf |
| `Port 8080 was already in use` | Otra aplicación usa el puerto | Cambiar `server.port` o cerrar el proceso |
| El navegador descarga o muestra el HTML raro | Ruta o extensión incorrecta | Abrir la URL exacta (`/index.html`) |
| `./mvnw` no existe | El proyecto es Gradle | Usar `./gradlew` |

### El error que más me costó

El primer intento del formulario falló porque la ruta de `action` **no coincidía** con la del `@PostMapping`. El navegador enviaba la petición a una dirección y Spring esperaba otra, así que respondía `404`.

> ✅ **Regla de oro:** `action` del formulario = ruta del `@PostMapping`; `name` del input = nombre del `@RequestParam`; `method` del formulario = tipo de `@...Mapping`.

### Otras observaciones de la práctica

- Puse `@RestController` en la **misma clase** que `@SpringBootApplication`. Funciona para un ejemplo, pero lo limpio es separar el arranque y el controlador en clases distintas.
- Usé `System.out.println("Procesando proceso de datos")` para depurar. En un proyecto real se usa un **logger** (`LoggerFactory.getLogger(...)`) y no se deja código de depuración.
- El comentario `// EL PRIMERO GET DE TODO EL MUNDO DE SPRINGBOOT` quedó en el código, pero el método que hay debajo es un `POST`. Conviene mantener los comentarios sincronizados con lo que hace el código.

---

## Comparación con las bitácoras anteriores

### Línea temporal

| Día | Qué se aprendió | Relación con hoy |
| --- | --- | --- |
| **2** | HTTP: petición, cabeceras, métodos, `curl`, `nc` | Hoy se ve HTTP «por dentro» desde Spring |
| **5** | Hot reload, Servlet, JSP, MVC, HTTP sin estado | Base conceptual de lo que hace Spring Boot |
| **6** | Backend Java, servidores, Spring, POJO, CRUD | Spring Boot es la capa que arranca todo |
| **7** | Primer endpoint y formulario `POST` | **Sesión de hoy** |
| **9** | MVC aplicado a Spring Boot | `@Controller`, `Model`, `DispatcherServlet` |
| **10** | Thymeleaf, `Model`, `th:text`, `th:each` | Sustituye al texto plano de hoy |
| **11** | Lombok y `@ModelAttribute` | Forma cómoda de recibir objetos |
| **12** | `redirect` y `@ModelAttribute` vs `@RequestParam` | Mejora del `POST` de hoy |
| **14** | Cookies, sesiones y carrito | El estado ya no viaja en el formulario |

### Qué cambia respecto al día 6

El día 6 fue **teoría de backend**: servidores, Spring, MVC, POJO. Hoy se pasa a la práctica:

```text
Día 6:  ¿qué es Spring?          →  conceptos
Día 7:  ¿cómo arranco Spring?    →  proyecto real + endpoints
```

### Qué se mantiene y qué se aprende después

| Concepto | Día 7 | Evolución posterior |
| --- | --- | --- |
| Respuesta | Texto plano (`@RestController`) | HTML con Thymeleaf (día 10) |
| Datos del formulario | `@RequestParam` | `@ModelAttribute` con un objeto (días 11–12) |
| Navegación | Misma URL | `redirect:` tras el `POST` (día 12) |
| Estado | Nada guardado | Sesión con `HttpSession` (día 14) |
| Controlador | `@RestController` | `@Controller` + `Model` (día 10) |

> 🧠 **Conclusión:** el día 7 es la base de todo lo demás. Si no queda claro cómo viaja una petición desde el formulario hasta el método Java, los días 10–14 se vuelven magia. Con esta práctica, ya no lo son.

---

## Chuleta de código

```java
// Arranque
@SpringBootApplication
public class DemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
```

```java
// Endpoint GET con parámetro opcional
@GetMapping("/hello")
public String hello(
        @RequestParam(value = "name", defaultValue = "World") String name) {
    return String.format("Hello %s", name);
}
```

```java
// Endpoint POST que recibe un campo de formulario
@PostMapping("/formulario")
public String procesarDatos(@RequestParam("nombre") String nombre) {
    if (!nombre.isBlank()) {
        return String.format("Hola %s", nombre);
    }
    return "Hola mundo";
}
```

```html
<!-- Formulario mínimo -->
<form method="POST" action="/formulario">
    <label for="nombre">Nombre:</label>
    <input type="text" name="nombre" id="nombre">
    <button type="submit">Enviar</button>
</form>
```

```properties
# application.properties
server.port=8080
spring.application.name=demo
```

```bash
# Arrancar y probar
./gradlew bootRun                 # Gradle
./mvnw spring-boot:run            # Maven

curl "http://localhost:8080/hello?name=ruvik"
curl -X POST -d "nombre=Ruvik" http://localhost:8080/formulario
```

### Anotaciones de un vistazo

| Anotación | Para qué |
| --- | --- |
| `@SpringBootApplication` | Arrancar y autoconfigurar |
| `@RestController` | Controlador que devuelve el cuerpo de la respuesta |
| `@Controller` | Controlador que devuelve el nombre de una plantilla |
| `@GetMapping` | Asocia `GET` a un método |
| `@PostMapping` | Asocia `POST` a un método |
| `@RequestParam` | Lee un parámetro de la URL o del formulario |
| `@PathVariable` | Lee un trozo de la ruta (`/producto/{id}`) |

---

## Pendientes y preguntas

- [ ] Separar `DemoApplication` del controlador en dos clases.
- [ ] Volver a probar el `POST` cambiando el `action` a propósito y comprobar el `404`.
- [ ] Probar qué pasa si se quita `name="nombre"` del input.
- [ ] Cambiar `isEmpty()` por `isBlank()` y probar con espacios.
- [ ] Quitar `enctype="multipart/form-data"` y comprobar que sigue funcionando.
- [ ] Ver la petición y la respuesta en **DevTools → Network**.
- [ ] Cambiar `server.port` y comprobar que la app arranca en otro puerto.
- [ ] Repetir el endpoint `/hello` usando `@Controller` + una plantilla Thymeleaf (día 10).
- [ ] ¿Qué diferencia hay entre `@RequestParam` y `@PathVariable`?
- [ ] ¿Por qué `@RestController` no busca plantillas?

---

**Relacionado:** [[bitacpra-dia-seis]] · [[bitacora-dia-cinco]] · [[bitacora-dia-nueve]] · [[bitacora-dia-diez]] · [[bitacora-dia-doce]]

**Proyecto:** `PROYECTOS/demo`

**TODO LO VISTO CONVERGE AHÍ:** [[D1 -UD2]]
