<link rel="stylesheet" href="../css/diselpunk.css">

<div class="cover">
<p class="serial">CUADERNO DE PRÁCTICAS // DESARROLLO WEB EN ENTORNO SERVIDOR</p>

# D1 · UD2<br>SPRING BOOT

<p class="subtitle"><strong>De un proyecto vacío a una API REST</strong></p>
<p>Kerin Aguilera</p>
<p class="serial">JAVA 21 · SPRING BOOT 4 · GRADLE · OCTUBRE 2026</p>
</div>

<div class="toc">
<p class="toc-title">ÍNDICE DE RUTA</p>
<ol>
<li><a href="#objetivo">Objetivo de la práctica</a></li>
<li><a href="#primer-intento">Primer intento: proyecto sin dependencias</a></li>
<li><a href="#segundo-intento">Segundo intento: una aplicación web</a>
<ul>
<li><a href="#gradle">Configuración de Gradle</a></li>
<li><a href="#rutas">Rutas y parámetros</a></li>
<li><a href="#formularios">Página estática y formularios</a></li>
<li><a href="#empaquetado">Spring Initializr y empaquetado</a></li>
<li><a href="#puerto">Configuración del puerto</a></li>
<li><a href="#json">Objetos y respuestas JSON</a></li>
<li><a href="#request-body">Lectura del cuerpo de una petición</a></li>
<li><a href="#controlador-final">El controlador al terminar la práctica</a></li>
</ul>
</li>
<li><a href="#resumen">Resumen de conceptos</a></li>
<li><a href="#repaso">Preguntas de repaso</a></li>
<li><a href="#conclusion">Conclusión</a></li>
<li><a href="#recursos">Recursos</a></li>
</ol>
</div>

<a id="objetivo"></a>

## Objetivo de la práctica

Esta práctica reconstruye desde cero el proyecto de la unidad anterior: empiezo con un proyecto Spring Boot recién generado y lo convierto, paso a paso, en una pequeña API REST capaz de responder texto, servir una página estática, procesar un formulario y devolver objetos en JSON.

El recorrido tiene dos partes. Primero genero el proyecto **sin ninguna dependencia** para comprobar qué ocurre exactamente al arrancarlo. Después repito la generación añadiendo **Spring Web**, que es lo que convierte la aplicación en un servidor HTTP real. A partir de ahí voy añadiendo rutas, parámetros, formularios, JSON y, por último, empaquetado y configuración de puerto.

Es la base sobre la que se apoyan el resto de prácticas de la unidad: D2 (plantillas Thymeleaf y validaciones), D3 (formularios encadenados) y D4 (parámetros, codificación e internacionalización).

<div class="spec">

| Pieza | Detalle |
|---|---|
| Lenguaje | Java 21 (toolchain de Gradle) |
| Framework | Spring Boot 4.1.1 |
| Empaquetado | Gradle (DSL de Groovy) → `UD1-UD2-0.0.1-SNAPSHOT.jar` |
| Servidor | Tomcat embebido, puerto 8080 |
| Dependencias | Spring Web MVC · DevTools · WebMvc Test |

</div>

<a id="primer-intento"></a>

## Primer intento: proyecto sin dependencias

La práctica comienza creando un proyecto Spring Boot sin dependencias adicionales. En Spring Initializr, el único cambio respecto a la configuración por defecto es seleccionar Java 21.

![Selección de Java 21 en Spring Initializr](img%20-%20documents/D1-UD2.1.png)

En el siguiente paso dejo vacía la lista de dependencias.

![Selector de dependencias de Spring Boot vacío](img%20-%20documents/UD1%20-%20UD2.2.png)

El proyecto generado incluye una clase de entrada muy sencilla:

```java
package ruvik.proyectoud1ud2;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ProyectoUd1Ud2Application {

    public static void main(String[] args) {
        SpringApplication.run(ProyectoUd1Ud2Application.class, args);
    }
}
```

La estructura inicial queda así:

![Estructura del proyecto generado](img%20-%20documents/UD1-UD2.3.png)

Al ejecutar la aplicación, el proceso termina poco después de arrancar, y lo hace sin errores. La razón es que no hay ningún componente que mantenga la JVM viva: sin una dependencia web, Spring Boot no levanta un servidor HTTP escuchando peticiones. El contexto se inicia y el programa simplemente finaliza. Es, en la práctica, una aplicación de consola que se apaga sola.

![Salida de la ejecución en la terminal](img%20-%20documents/UD1-UD2.4.png)

Por eso, al intentar añadir las anotaciones web del [inicio rápido de Spring](https://spring.io/quickstart), el proyecto ni siquiera compila: faltan las clases de Spring MVC en el classpath. La aplicación base arranca, pero todavía no puede atender peticiones web.

![Errores al intentar usar las anotaciones web](img%20-%20documents/UD1-UD2.5.png)

> **Lo que demuestra esta primera prueba:** crear una aplicación Spring Boot y convertirla en una aplicación web son cosas distintas. El primer paso lo hace Initializr; el segundo lo hacen las dependencias.

<a id="segundo-intento"></a>

## Segundo intento: una aplicación web

Creo otro proyecto con la misma configuración y esta vez marco la dependencia **Spring Web**, que incorpora lo necesario para escribir controladores y atender peticiones HTTP.

![Creación del proyecto con Spring Web](img%20-%20documents/D1-UD2.6.png)

Ahora la aplicación ya no termina: se queda en ejecución. En los registros se observa que Spring Boot arranca un **Tomcat embebido** en el puerto 8080:

```text
:: Spring Boot :: (v4.1.1)

Tomcat initialized with port 8080 (http)
Starting service [Tomcat]
```

Este detalle es importante: el servidor viene **dentro de la propia aplicación**, no hace falta instalar Tomcat aparte.

Al visitar `http://localhost:8080/` aparece un error 404 con la página de error por defecto de Spring Boot, porque todavía no existe ninguna ruta mapeada en la raíz.

![Respuesta al visitar la raíz sin controlador asignado](img%20-%20documents/D1-UD2.78.png)

El controlador de ejemplo responde en `/hello`:

```java
@GetMapping("/hello")
public String hello(@RequestParam(value = "name", defaultValue = "World") String name) {
    return String.format("Hello, %s!", name);
}
```

La ruta `http://localhost:8080/hello` devuelve el saludo por defecto.

![Respuesta de la ruta hello](img%20-%20documents/D1-UD2.8.png)

El parámetro `name` permite personalizarlo: `http://localhost:8080/hello?name=ruvik`.

![Respuesta de hello con el nombre Ruvik](img%20-%20documents/D1-UD2.9.png)

<a id="gradle"></a>

### Configuración de Gradle

El archivo `build.gradle` declara los plugins, la versión de Java y las dependencias del proyecto.

![Configuración de Gradle](img%20-%20documents/D1-UD2.10.png)

Los plugins identifican Java, Spring Boot y la gestión de dependencias:

```gradle
plugins {
    id 'java'
    id 'org.springframework.boot' version '4.1.1'
    id 'io.spring.dependency-management' version '1.1.7'
}
```

La configuración del proyecto especifica Java 21 y Maven Central como repositorio:

```gradle
group = 'Ruvik'
version = '0.0.1-SNAPSHOT'
description = 'UD1-UD2'

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

repositories {
    mavenCentral()
}
```

Las dependencias principales son Spring MVC, DevTools y las herramientas de prueba:

```gradle
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-webmvc'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    testImplementation 'org.springframework.boot:spring-boot-starter-webmvc-test'
    testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
}
```

La clave está en el concepto de **starter**: `spring-boot-starter-webmvc` no es una dependencia aislada, sino un paquete que arrastra Spring MVC, el Tomcat embebido y el conversor JSON (Jackson) que utilizaré más adelante.

Respecto a los ámbitos: `implementation` incorpora dependencias necesarias en la aplicación; `developmentOnly` se reserva para el desarrollo (DevTools, con su reinicio automático), y `testImplementation` solo está disponible en las pruebas.

> Esta es mi interpretación de la configuración que estoy viendo. La finalidad exacta de cada dependencia puede variar según el proyecto.

<a id="rutas"></a>

### Rutas y parámetros

También podemos traducir la ruta y el parámetro al español. Con `@RestController`, el valor devuelto por el método se escribe directamente en la respuesta HTTP:

```java
package ruvik.ud1ud2;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class Ud1Ud2Application {

    public static void main(String[] args) {
        SpringApplication.run(Ud1Ud2Application.class, args);
    }

    @GetMapping("/hola")
    public String hello(@RequestParam(value = "nombre", defaultValue = "Mundo") String name) {
        return String.format("Hola, %s!", name);
    }
}
```

`http://localhost:8080/hola` utiliza el valor predeterminado; `http://localhost:8080/hola?nombre=ruvik` utiliza el que enviamos en la URL.

![Respuesta de hola sin parámetro](img%20-%20documents/D1-UD2.11.png)

![Respuesta de hola con el parámetro nombre](img%20-%20documents/D1-UD2.12.png)

Durante la prueba también se incluyó HTML en la cadena de respuesta:

```java
return String.format("Hola, <b>%s!</b>", name);
```

El navegador muestra el saludo en negrita porque la respuesta viaja con el tipo `text/html`. El formato concreto de la respuesta depende del controlador y del tipo de contenido enviado.

![Saludo con texto en negrita](img%20-%20documents/D1-UD2.13.png)

![Cabeceras de la respuesta](img%20-%20documents/D1-UD2.14.png)

<a id="formularios"></a>

### Página estática y formularios

Spring MVC sirve automáticamente el contenido estático de `src/main/resources/static/`: un archivo llamado `index.html` colocado ahí responde en la raíz `/`.

En el proyecto, esa página está maquetada como un terminal industrial con CSS propio (tipografía de máquina, remaches, rejilla de fondo), pero lo relevante para el servidor es solo el formulario: `action="/mostrar"`, `method="post"` y el campo `nombre`:

```html
<form action="/mostrar" method="post">
    <label for="nombre">Identificación</label>
    <input type="text" id="nombre" name="nombre"
           placeholder="Introduzca su nombre..." required>
    <button type="submit">ENVIAR DATOS</button>
</form>
```

El controlador recibe el parámetro por POST y construye la respuesta:

```java
@PostMapping("/mostrar")
public String mostrar(@RequestParam(value = "nombre", defaultValue = "Mundo") String name) {
    return String.format("Hola, <b>%s!</b>", name);
}
```

![Formulario servido desde la página estática](img%20-%20documents/D1-UD2.15.png)

![Respuesta enviada por el formulario](img%20-%20documents/D1-UD2.16.png)

Aquí empieza a importar la diferencia entre `@Controller` y `@RestController` al devolver una cadena:

| | `@Controller` | `@RestController` |
|---|---|---|
| Un método devuelve `"saludos"` | Spring lo interpreta como nombre de vista | Se escribe tal cual en el cuerpo de la respuesta |
| Cómo se escribe en el cuerpo | Solo con `@ResponseBody` en el método | Siempre (equivale a `@Controller` + `@ResponseBody`) |
| Uso típico | Aplicaciones con plantillas, como las de D2 | APIs REST que devuelven texto o JSON |

Para comprobarlo, probé la variante clásica en el propio proyecto: la clase anotada con `@Controller` y el método `/mostrar` rescatado con `@ResponseBody`:

```java
@PostMapping("/mostrar")
@ResponseBody
public String mostrar(@RequestParam(value = "nombre", defaultValue = "Mundo") String name) {
    return String.format("Hola, <b>%s!</b>", name);
}
```

Sin `@ResponseBody`, Spring habría intentado resolver la cadena devuelta como nombre de vista y la petición habría terminado en error. Al final dejé `@RestController` en la clase, que es el estado final del repositorio.

<a id="empaquetado"></a>

### Spring Initializr y empaquetado

Spring Initializr simplifica la creación del proyecto: permite seleccionar lenguaje, versión y dependencias, y genera una estructura inicial lista para desarrollar.

En IntelliJ, la tarea `bootJar` genera el archivo ejecutable:

![Ubicación de la tarea BootJar en IntelliJ](img%20-%20documents/D1-UD2.17.png)

En el panel de Gradle, la ruta es `Tasks > build > bootJar` (también se puede lanzar desde la terminal con `./gradlew bootJar`). El archivo generado queda en `build/libs` y se ejecuta así:

```bash
java -jar build/libs/UD1-UD2-0.0.1-SNAPSHOT.jar
```

![Ejecución del archivo JAR](img%20-%20documents/D1-UD2.18.png)

El resultado es un JAR "gordo" (*fat jar*): dentro van las clases de la aplicación **y también el servidor Tomcat**, por lo que el archivo se ejecuta en cualquier máquina con Java 21 sin instalar nada más.

<a id="puerto"></a>

### Configuración del puerto

El puerto del servidor se cambia en `src/main/resources/application.properties`, por ejemplo:

```properties
server.port=80
```

![Configuración del puerto 80](img%20-%20documents/D1-UD2.19.png)

<div class="warning">

En Linux y otros sistemas tipo Unix, los puertos por debajo de 1024 son **privilegiados**: enlazarlos requiere permisos especiales. Una aplicación ejecutada como usuario normal puede quedarse sin permiso para usar el 80. Para desarrollo local conviene un puerto no privilegiado, como el 8080.

</div>

![Error al intentar usar el puerto 80](img%20-%20documents/D1-UD2.20.png)

Tras comprobar el error, dejé la aplicación en el 8080 para seguir desarrollando.

<a id="json"></a>

### Objetos y respuestas JSON

Al devolver un objeto Java desde un controlador REST, Spring lo serializa como JSON en cuanto hay un conversor compatible en el proyecto (Jackson llega con Spring Web).

Primero, el POJO `Contacto` (paquete `ruvik.ud1ud2.Entity`), reducido a lo que realmente necesita esta práctica:

```java
package ruvik.ud1ud2.Entity;

public class Contacto {
    private String nombre;
    private String apellido;

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getApellido() { return apellido; }
    public void setApellido(String apellido) { this.apellido = apellido; }
}
```

Y la ruta que construye un contacto a partir de dos parámetros:

```java
@GetMapping("/contacto")
public Contacto contacto(
        @RequestParam(value = "nombre", defaultValue = "Benjamin") String nombre,
        @RequestParam(value = "apellido", defaultValue = "Carmine") String apellido) {

    Contacto contacto = new Contacto();
    contacto.setNombre(nombre);
    contacto.setApellido(apellido);
    return contacto;
}
```

La respuesta ya no es HTML, sino JSON con cabecera `Content-Type: application/json`:

![Objeto Contacto devuelto como JSON](img%20-%20documents/D1-UD2.21.png)

![Tipo de contenido de la respuesta JSON](img%20-%20documents/D1-UD2.22.png)

No hubo que escribir ningún código de conversión: Jackson recorre los getters del POJO y construye el JSON automáticamente.

<a id="request-body"></a>

### Lectura del cuerpo de una petición

Para recibir un objeto enviado en el cuerpo de una petición POST se utiliza `@RequestBody`. El ejemplo devuelve el objeto recibido:

```java
@PostMapping("/formulario")
public Contacto formulario(@RequestBody Contacto contacto) {
    return contacto;
}
```

En Bruno se envía un cuerpo JSON que Spring convierte en un objeto `Contacto`:

![Petición POST enviada desde Bruno](img%20-%20documents/D1-UD2.23.png)

![Cabeceras devueltas por la petición](img%20-%20documents/D1-UD2.24.png)

`@RestController` y `@ResponseBody` escriben directamente el resultado en la respuesta. Si además se necesita controlar el estado HTTP o las cabeceras, la herramienta adecuada es `ResponseEntity`:

```java
@PostMapping("/formulario")
public ResponseEntity<Contacto> formulario(@RequestBody Contacto contacto) {
    return ResponseEntity
            .status(HttpStatus.CREATED)
            .header("X-Practica", "D1-UD2")
            .body(contacto);
}
```

<a id="controlador-final"></a>

### El controlador al terminar la práctica

Este es el estado final del controlador en el repositorio, con las cuatro rutas funcionando sobre la misma clase:

```java
package ruvik.ud1ud2;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;
import ruvik.ud1ud2.Entity.Contacto;

@SpringBootApplication
@RestController
public class Ud1Ud2Application {

    public static void main(String[] args) {
        SpringApplication.run(Ud1Ud2Application.class, args);
    }

    @GetMapping("/hola")
    public String hello(@RequestParam(value = "nombre", defaultValue = "Mundo") String name) {
        return String.format("Hola, <b> %s!</b>", name);
    }

    @PostMapping("/mostrar")
    public String mostrar(@RequestParam(value = "nombre", defaultValue = "Mundo") String name) {
        return String.format("Hola, <b> %s!</b>", name);
    }

    @PostMapping("/formulario")
    public Contacto formulario(@RequestBody(required = false) Contacto contacto) {
        Contacto contacto1 = contacto;
        System.out.println("Si funciono, creo...");
        System.out.println(contacto1);
        return contacto1;
    }

    @GetMapping("/contacto")
    public Contacto contacto(
            @RequestParam(value = "nombre", defaultValue = "Benjamin") String nombre,
            @RequestParam(value = "apellido", defaultValue = "Carmine") String apellido) {

        Contacto contacto = new Contacto();
        contacto.setNombre(nombre);
        contacto.setApellido(apellido);
        return contacto;
    }
}
```

Dos detalles de este código merecen comentario:

- `@RequestBody(required = false)`: si la petición llega sin cuerpo, Spring pasa `null` en lugar de rechazarla con un error 400.
- Los `System.out.println` son huellas de las pruebas con Bruno: los dejé para comprobar en consola que el objeto llegaba bien deserializado antes de devolverlo.

<a id="resumen"></a>

## Resumen de conceptos

| Elemento | Dónde se aplica | Qué hace |
|---|---|---|
| `@SpringBootApplication` | Clase principal | Activa la autoconfiguración y el escaneo de componentes |
| `@RestController` | Clase controladora | Equivale a `@Controller` + `@ResponseBody`; cada método escribe su valor en la respuesta |
| `@Controller` | Clase controladora | El `String` devuelto se interpreta como nombre de vista |
| `@ResponseBody` | Método | Escribe el valor devuelto directamente en el cuerpo HTTP |
| `@GetMapping("/ruta")` | Método | Atiende peticiones GET en esa ruta |
| `@PostMapping("/ruta")` | Método | Atiende peticiones POST en esa ruta |
| `@RequestParam` | Parámetro | Lee un parámetro de la query o del formulario; admite `defaultValue` |
| `@RequestBody` | Parámetro | Convierte el cuerpo de la petición (JSON) en un objeto Java |
| `static/index.html` | Recursos estáticos | Se sirve automáticamente en la ruta raíz `/` |
| `server.port` | `application.properties` | Cambia el puerto del servidor embebido |
| `bootJar` | Tarea de Gradle | Genera el JAR ejecutable con el Tomcat dentro |

Ideas clave que me llevo de la práctica:

- Sin una dependencia web, la aplicación arranca y termina: no hay servidor HTTP que la mantenga viva. La elección de dependencias **define las capacidades** del proyecto.
- El Tomcat viene **embebido**: el JAR lleva el servidor dentro y se ejecuta con `java -jar` sin instalar nada.
- La elección de anotaciones define el comportamiento: `@Controller` devuelva vistas, `@RestController` devuelva datos.
- Jackson convierte POJO ↔ JSON de forma automática a través de los getters; no hay que escribir la serialización a mano.
- Los puertos por debajo de 1024 están reservados en sistemas Unix: en desarrollo, mejor un puerto alto como el 8080.

<a id="repaso"></a>

## Preguntas de repaso

1. ¿Qué le falta a un proyecto Spring Boot generado sin dependencias para quedarse escuchando peticiones, y por qué? *(Primer intento)*
2. ¿Qué aporta exactamente la dependencia Spring Web? ¿Qué servidor arranca y en qué puerto? *(Segundo intento)*
3. ¿Qué es un *starter* en Gradle/Maven y qué arrastra `spring-boot-starter-webmvc`? *(Configuración de Gradle)*
4. ¿Qué diferencia hay entre `@Controller` y `@RestController` cuando un método devuelve un `String`? *(Página estática y formularios)*
5. ¿Para qué sirve `@ResponseBody`? ¿Y `ResponseEntity`, qué añade sobre él? *(Página estática y formularios / Request body)*
6. ¿Cómo se recibe un parámetro de la URL y cómo un objeto JSON enviado en el cuerpo de un POST? *(Rutas y parámetros / Request body)*
7. ¿Dónde se coloca `index.html` para que se sirva solo en la raíz? ¿Qué atributos del formulario determinan a qué ruta y con qué método se envía? *(Página estática y formularios)*
8. ¿Qué tarea de Gradle genera el JAR, cómo se ejecuta y qué lleva dentro para poder ejecutarse sin servidor instalado? *(Empaquetado)*
9. ¿Por qué falla el arranque con `server.port=80` en Linux como usuario normal? ¿Qué puerto conviene usar? *(Configuración del puerto)*
10. ¿Cómo consigue Spring convertir un POJO en JSON sin que escribamos código de conversión? *(Objetos y respuestas JSON)*

<a id="conclusion"></a>

## Conclusión

Volver a trabajar estos conceptos me permitió avanzar con más rapidez que la primera vez: ya entendía mejor por qué se necesitan ciertas dependencias y cómo se conectan las rutas con las respuestas. Todavía me sentía algo oxidado con los POJOs, pero pude completar las pruebas con más soltura que en la unidad anterior.

La idea principal que me llevo es que **Spring Boot facilita el arranque, pero las dependencias y las anotaciones elegidas determinan cómo se comporta la aplicación**: si mantiene un servidor web activo, cómo recibe los datos (parámetro de URL, formulario o cuerpo JSON) y cómo construye cada respuesta (texto, HTML u objeto serializado).

Con esta base, las siguientes prácticas pueden centrarse en lo nuevo: plantillas con Thymeleaf y validaciones (D2), estado entre pasos de un formulario (D3) y codificación de parámetros e internacionalización (D4).

<a id="recursos"></a>

## Recursos

- [Repositorio del proyecto en GitHub](https://github.com/KerinR432/DWES2)
- [Spring Initializr](https://start.spring.io/)
- [Inicio rápido de Spring](https://spring.io/quickstart)
- Bruno, como cliente REST para las pruebas de `/formulario`
- Stack Overflow y Gemini como apoyo puntual para interpretar la configuración de Gradle

<div class="endmark">
FIN DE LA TRANSMISIÓN // D1 · UD2
</div>
