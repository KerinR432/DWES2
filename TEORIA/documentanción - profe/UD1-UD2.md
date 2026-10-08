<div class="cover">
<p class="serial">CUADERNO DE PRÁCTICAS // DESARROLLO WEB</p>

# UD1 · UD2<br>SPRING BOOT

<p><strong>De un proyecto vacío a una API REST</strong></p>
<p>Kerin Aguilera</p>
<p class="serial">JAVA 21 · SPRING BOOT · OCTUBRE 2026</p>
</div>

## Índice

- [Primer intento: proyecto sin dependencias](#primer-intento)
- [Segundo intento: una aplicación web](#segundo-intento)
    - [Configuración de Gradle](#gradle)
    - [Rutas y parámetros](#rutas)
    - [Página estática y formularios](#formularios)
    - [Spring Initializr y empaquetado](#empaquetado)
    - [Configuración del puerto](#puerto)
    - [Objetos y respuestas JSON](#json)
    - [Lectura del cuerpo de una petición](#request-body)
- [Conclusión](#conclusion)

<a id="primer-intento"></a>

## 1. Primer intento: proyecto sin dependencias

La práctica comienza creando un proyecto Spring Boot sin dependencias adicionales. En Spring Initializr, el único cambio respecto a la configuración inicial es seleccionar Java 21.

![Selección de Java 21 en Spring Initializr](img%20-%20documents/D1-UD2.1.png)

En el siguiente paso dejamos vacía la lista de dependencias.

![Selector de dependencias de Spring Boot](img%20-%20documents/UD1%20-%20UD2.2.png)

El proyecto generado incluye una clase de entrada sencilla:

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

Al ejecutar esta aplicación, el proceso termina poco después de iniciarse. Sin una dependencia web, Spring Boot no levanta un servidor HTTP que mantenga la aplicación escuchando peticiones.

![Salida de la ejecución en la terminal](img%20-%20documents/UD1-UD2.4.png)

Por eso, al intentar utilizar anotaciones web del [inicio rápido de Spring](https://spring.io/quickstart), faltan las clases necesarias para compilar. La aplicación base arranca, pero todavía no puede atender peticiones web.

![Errores al intentar usar las anotaciones web](img%20-%20documents/UD1-UD2.5.png)

> La primera prueba deja clara la diferencia entre crear una aplicación Spring Boot y añadirle las capacidades necesarias para convertirla en una aplicación web.

<a id="segundo-intento"></a>

## 2. Segundo intento: una aplicación web

Creamos otro proyecto con la misma configuración y añadimos la dependencia **Spring Web**. Esta incorpora lo necesario para crear controladores y atender peticiones HTTP.

![Creación del proyecto con Spring Web](img%20-%20documents/D1-UD2.6.png)

Ahora la aplicación permanece en ejecución. En los registros se observa que Spring Boot inicia Tomcat en el puerto 8080:

```text
:: Spring Boot :: (v4.1.1)

Tomcat initialized with port 8080 (http)
Starting service [Tomcat]
```

Al visitar `http://localhost:8080/` aparece un error porque todavía no hemos definido una ruta para la raíz.

![Respuesta al visitar la ruta raíz sin un controlador asignado](img%20-%20documents/D1-UD2.78.png)

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

El archivo de Gradle declara los plugins, la versión de Java y las dependencias del proyecto.

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

`implementation` incorpora dependencias necesarias en la aplicación; `developmentOnly` se reserva para el desarrollo, y `testImplementation` para las pruebas.

> Esta es mi interpretación de la configuración que estoy viendo. La finalidad de cada dependencia puede variar según el proyecto.

<a id="rutas"></a>

### Rutas y parámetros

También podemos traducir la ruta y el parámetro al español. Con `@RestController`, el valor devuelto por el método se escribe directamente en la respuesta HTTP.

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

El navegador muestra el saludo en negrita. El formato concreto de la respuesta depende del controlador y del tipo de contenido enviado.

![Saludo con texto en negrita](img%20-%20documents/D1-UD2.13.png)

![Cabeceras de la respuesta](img%20-%20documents/D1-UD2.14.png)

<a id="formularios"></a>

### Página estática y formularios

Una página llamada `index.html`, ubicada en los recursos estáticos de la aplicación, se puede servir en `/`. Este formulario envía el nombre al servidor mediante una petición POST:

```html
<html>
    <body>
        <form action="/mostrar" method="post">
            <label for="nombre">Nombre:</label>
            <input id="nombre" type="text" name="nombre">
            <button type="submit">Enviar</button>
        </form>
    </body>
</html>
```

El controlador recibe el parámetro y construye la respuesta:

```java
@PostMapping("/mostrar")
public String mostrar(@RequestParam(value = "nombre", defaultValue = "Mundo") String name) {
    return String.format("Hola, <b>%s!</b>", name);
}
```

![Formulario de la pagina estatica](img%20-%20documents/D1-UD2.15.png)

![Respuesta enviada por el formulario](img%20-%20documents/D1-UD2.16.png)

La diferencia entre `@Controller` y `@RestController` importa al devolver una cadena. En un `@Controller`, Spring interpreta normalmente la cadena como el nombre de una vista. `@ResponseBody` indica que debe escribirse en el cuerpo de la respuesta; `@RestController` aplica ese comportamiento a todos los métodos del controlador.

```java
@PostMapping("/mostrar")
@ResponseBody
public String mostrar(@RequestParam(value = "nombre", defaultValue = "Mundo") String name) {
    return String.format("Hola, <b>%s!</b>", name);
}
```

<a id="empaquetado"></a>

### Spring Initializr y empaquetado

Spring Initializr simplifica la creación del proyecto: permite seleccionar lenguaje, versión y dependencias, y genera una estructura inicial lista para desarrollar.

En IntelliJ, la tarea `BootJar` genera el archivo ejecutable:

![Ubicacion de la tarea BootJar en IntelliJ](img%20-%20documents/D1-UD2.17.png)

En el panel de Gradle, la ruta es `Tasks > build > BootJar`. El archivo generado queda en `build/libs`. Se puede ejecutar desde una terminal así:

```bash
java -jar build/libs/nombre-del-proyecto.jar
```

![Ejecucion del archivo JAR](img%20-%20documents/D1-UD2.18.png)

<a id="puerto"></a>

### Configuración del puerto

El puerto del servidor se puede cambiar en `application.properties`, por ejemplo con `server.port=80`.

![Configuracion del puerto 80](img%20-%20documents/D1-UD2.19.png)

En Linux y otros sistemas tipo Unix, los puertos inferiores a 1024 suelen requerir permisos especiales. Por eso, una aplicación ejecutada como usuario normal puede no tener permiso para enlazarse al puerto 80. Para desarrollo local conviene usar un puerto no privilegiado, como el 8080.

![Error al intentar usar el puerto 80](img%20-%20documents/D1-UD2.20.png)

<a id="json"></a>

### Objetos y respuestas JSON

Al devolver un objeto Java desde un controlador REST, Spring lo serializa como JSON si hay un conversor compatible disponible en el proyecto. En este ejemplo, se crea un `Contacto` a partir de dos parámetros:

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

La respuesta se representa como JSON en el navegador:

![Objeto Contacto devuelto como JSON](img%20-%20documents/D1-UD2.21.png)

![Tipo de contenido de la respuesta JSON](img%20-%20documents/D1-UD2.22.png)

<a id="request-body"></a>

### Lectura del cuerpo de una petición

Para recibir un objeto enviado en el cuerpo de una petición POST, se puede usar `@RequestBody`. El ejemplo devuelve el objeto recibido:

```java
@PostMapping("/formulario")
public Contacto formulario(@RequestBody Contacto contacto) {
    return contacto;
}
```

En Bruno, se envía un cuerpo JSON que Spring convierte en un objeto `Contacto`:

![Peticion POST enviada desde Bruno](img%20-%20documents/D1-UD2.23.png)

![Cabeceras devueltas por la peticion](img%20-%20documents/D1-UD2.24.png)

`@RestController` y `@ResponseBody` permiten escribir directamente el resultado en la respuesta. Si se necesita controlar también el estado HTTP o las cabeceras, `ResponseEntity` ofrece esas opciones.

<a id="conclusion"></a>

## 3. Conclusión

Volver a trabajar estos conceptos me permitió avanzar con más rapidez: ya entendía mejor por qué se necesitan ciertas dependencias y cómo se conectan las rutas con las respuestas. Todavía me sentía algo oxidado con los POJOs, pero pude completar las pruebas con más soltura que la primera vez.

La idea principal que me llevo es que Spring Boot facilita el arranque, pero las dependencias y las anotaciones elegidas determinan cómo se comporta la aplicación: si mantiene un servidor web activo, cómo recibe datos y cómo construye cada respuesta.
