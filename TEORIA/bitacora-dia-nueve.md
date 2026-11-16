# DÍA NUEVE — FAMILIARIZARSE CON SPRING BOOT Y REPASAR LA UD2

## Índice

1. [Resumen de la sesión](#resumen-de-la-sesión)
2. [Repaso D1-UD2: del proyecto vacío al JAR](#repaso-d1-ud2-del-proyecto-vacío-al-jar)
3. [Sanear las entradas (sanitize inputs)](#sanear-las-entradas-sanitize-inputs)
4. [Ejecutar en el puerto 80](#ejecutar-en-el-puerto-80)
5. [Ejercicios de la UD2](#ejercicios-de-la-ud2)
6. [Teoría: Spring MVC](#teoría-spring-mvc)
7. [El recorrido de una petición en MVC](#el-recorrido-de-una-petición-en-mvc)
8. [MVC no es solo tres letras](#mvc-no-es-solo-tres-letras)
9. [Errores y detalles detectados](#errores-y-detalles-detectados)
10. [Comparación con las bitácoras anteriores](#comparación-con-las-bitácoras-anteriores)
11. [Chuleta de código](#chuleta-de-código)
12. [Pendientes y preguntas](#pendientes-y-preguntas)

---

## Resumen de la sesión

El día 9 es una sesión de **consolidación**: no aparece un concepto completamente nuevo, sino que se repasa lo construido en la UD1–UD2 y se pone orden antes de entrar de lleno en las plantillas.

La libreta original de este día era muy breve. Decía, literalmente:

> «El concepto de *sanize inpust* en el jar con administrador si puedes ejecutar el proyecto de Springboot y ejecutarlo al **puerto 80**».

Esa frase mezcla **dos temas distintos** que conviene separar:

1. **Sanear las entradas** (*sanitize inputs*): no confiar nunca en lo que llega del cliente.
2. **Empaquetar y ejecutar** la aplicación como JAR, y qué implica usar el **puerto 80**.

Además, en la sesión se repasó **Spring MVC** con una idea muy simple:

```text
M → POJO
V → plantillas [ HTML, CSS, JS ]
C → Business Logic
```

Lo que vimos:

- Por qué un proyecto Spring Boot **sin dependencia web** arranca y se apaga.
- Cómo se genera un **JAR ejecutable** y cómo se lanza con `java -jar`.
- Qué significa **sanear** una entrada y por qué no basta con validar en el navegador.
- Por qué el **puerto 80** falla si no se tienen permisos.
- El mapa de **ejercicios de la UD2**.
- La separación **Modelo / Vista / Controlador** y sus límites.

> 💡 **Idea clave del día:** Spring Boot pone la infraestructura, pero **las dependencias y las anotaciones deciden qué hace la aplicación**. Un JAR que arranca no es automáticamente seguro: la seguridad y la validación se escriben en el código.

---

## Repaso D1-UD2: del proyecto vacío al JAR

### Primer intento: sin dependencias

Un proyecto Spring Boot recién creado, sin dependencias adicionales, compila y arranca… pero **termina casi inmediatamente**. No hay servidor HTTP que se quede escuchando.

```text
Proyecto sin dependencia web
        │
        ▼
SpringApplication.run(...)
        │
        ▼
Arranca, ejecuta y termina
        │
        ▼
No hay Tomcat, no hay puerto, no hay peticiones
```

Al intentar usar `@RestController` o `@GetMapping` sin la dependencia web, el proyecto **no compila**: faltan las clases de Spring MVC.

| Situación | ¿Arranca? | ¿Atiende peticiones? | Motivo |
| --- | --- | --- | --- |
| Sin dependencia web | ✅ Sí | ❌ No | No hay servidor embebido |
| Con `spring-boot-starter-webmvc` | ✅ Sí | ✅ Sí | Trae Spring MVC y Tomcat |

### Segundo intento: con dependencia web

```groovy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-webmvc'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    testImplementation 'org.springframework.boot:spring-boot-starter-webmvc-test'
    testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
}
```

Al arrancar, los registros muestran algo así:

```text
:: Spring Boot :: (v4.1.1)
Tomcat initialized with port 8080 (http)
Starting service [Tomcat]
```

Ahora la aplicación **se queda viva** y responde en `http://localhost:8080/`.

> 🔗 Esto conecta con el [día 7](bitacora-dia-siete.md): un endpoint es una **ruta + un verbo HTTP + un método Java**. Spring Boot pone el servidor; nosotros ponemos la ruta.

### Generar el JAR ejecutable

En Gradle, la tarea `bootJar` empaqueta la aplicación con sus dependencias dentro:

```bash
./gradlew build
```

En Windows:

```powershell
.\gradlew.bat build
```

El resultado queda en:

```text
build/libs/nombre-del-proyecto-0.0.1-SNAPSHOT.jar
```

Y se ejecuta con:

```bash
java -jar build/libs/nombre-del-proyecto-0.0.1-SNAPSHOT.jar
```

| Comando | Qué hace | Cuándo usarlo |
| --- | --- | --- |
| `./gradlew bootRun` | Arranca en desarrollo | Mientras programamos |
| `./gradlew build` | Compila, prueba y genera el JAR | Antes de entregar o desplegar |
| `java -jar ...jar` | Ejecuta el JAR ya construido | Para probar el artefacto final |
| `./gradlew test` | Ejecuta solo las pruebas | Para comprobar que nada se rompe |

> ⚠️ El JAR contiene las **clases compiladas** y las dependencias, no el código fuente. Aun así se puede descompilar: **no metas contraseñas ni claves** en el código ni en `application.properties` de un proyecto que se publique.

---

## Sanear las entradas (sanitize inputs)

**Sanear** una entrada significa **limpiar y validar** lo que llega del exterior antes de usarlo. El cliente puede enviar cualquier cosa: un formulario no es una garantía, porque se puede modificar con las DevTools, con `curl` o con Postman/Bruno.

### La regla de oro

```text
Nunca confíes en el cliente.
Valida y sanea siempre en el servidor.
```

La validación en HTML (`required`, `type="number"`, `maxlength`) solo mejora la experiencia de usuario. **No es seguridad**: se puede saltar.

### Riesgos habituales

| Riesgo | Ejemplo | Defensa |
| --- | --- | --- |
| **XSS** | `<script>alert('xss')</script>` como nombre | Escapar la salida (`th:text`, no `th:utext`) |
| **Inyección SQL** | `' OR 1=1 --` en un campo | Consultas parametrizadas / JPA |
| **Path traversal** | `../../etc/passwd` en un nombre de fichero | Validar y normalizar rutas |
| **Command injection** | `; rm -rf /` en un comando | No concatenar entradas en `Runtime.exec` |
| **Mass assignment** | Enviar campos que no toca el formulario | Usar DTOs y listas blancas |
| **CSRF** | Enviar un formulario desde otra web | Token CSRF / Spring Security |

### Validación en el servidor

Spring integra **Jakarta Bean Validation**. Se anotan los campos del POJO:

```java
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public class FormularioPersona {

    @NotBlank
    @Size(min = 2, max = 30)
    private String nombre;

    @NotNull
    @Min(18)
    private Integer edad;

    // getters y setters
}
```

Y el controlador comprueba el resultado con `@Valid` + `BindingResult`:

```java
@PostMapping("/")
public String verificar(
        @Valid @ModelAttribute("persona") FormularioPersona persona,
        BindingResult resultado) {

    if (resultado.hasErrors()) {
        return "formulario";       // vuelve al formulario con los errores
    }
    return "redirect:/resultado";  // datos válidos
}
```

En la plantilla se muestran los errores:

```html
<td th:if="${#fields.hasErrors('nombre')}" th:errors="*{nombre}">Error</td>
<td th:if="${#fields.hasErrors('edad')}" th:errors="*{edad}">Error</td>
```

### Escapar la salida

Thymeleaf escapa el HTML por defecto con `th:text`:

```html
<!-- Seguro: el HTML se muestra como texto -->
<p th:text="${nombre}"></p>

<!-- Peligroso: interpreta el HTML recibido -->
<p th:utext="${nombre}"></p>
```

Si un usuario envía `<script>alert('xss')</script>`:

| Atributo | Resultado |
| --- | --- |
| `th:text` | Se ve el texto `<script>…</script>` |
| `th:utext` | El navegador ejecuta el script ⚠️ |

> 🧠 **Sanear no es solo «quitar símbolos».** Es validar el formato, limitar la longitud, escapar según el contexto y usar APIs seguras (consultas parametrizadas, rutas normalizadas, etc.).

---

## Ejecutar en el puerto 80

Por defecto, Spring Boot usa el puerto **8080**. Se puede cambiar en `application.properties`:

```properties
server.port=80
```

O al arrancar el JAR:

```bash
java -jar aplicacion.jar --server.port=80
```

### ¿Por qué falla?

En Linux y otros sistemas tipo Unix, los puertos **menores de 1024** son privilegiados. Un usuario normal no puede enlazarse a ellos. En Windows, puede requerir permisos de administrador o chocar con otro servicio que ya use el puerto.

```text
Puerto 8080  →  usuario normal    →  ✅ funciona
Puerto 80    →  usuario normal    →  ❌ Permission denied
Puerto 80    →  administrador     →  ✅ funciona (pero no es lo ideal)
```

### Opciones

| Opción | Ventaja | Inconveniente |
| --- | --- | --- |
| Ejecutar como administrador / `sudo` | Funciona rápido | La app corre con demasiados privilegios |
| Usar el 8080 | Sencillo y seguro | Hay que escribir `:8080` en la URL |
| Proxy inverso (Nginx, Apache) | El 80 lo gestiona el proxy; la app sigue en 8080 | Requiere configurar el proxy |
| `setcap` en Linux | Permite enlazar al 80 sin ser root | Hay que aplicarlo al binario de Java |

La opción recomendada en producción es un **proxy inverso**: el servidor web escucha en el 80/443 y reenvía a la aplicación en el 8080. Así la app **no necesita privilegios**.

```text
Navegador
   │  http://midominio.com
   ▼
Nginx (puerto 80)
   │  proxy_pass http://localhost:8080
   ▼
Spring Boot (puerto 8080)
```

> ⚠️ **Error frecuente en Windows:** aunque abras la terminal como administrador, el puerto 80 puede estar ocupado por IIS, Skype u otro servicio. Comprueba con:
>
> ```powershell
> netstat -ano | findstr :80
> ```

---

## Ejercicios de la UD2

> 📌 **Nota:** en la libreta original esta sección quedó vacía. Aquí queda el **mapa de lo que cubre la UD2** y lo que conviene comprobar en cada práctica, sin inventar ejercicios que no estén en la documentación.

| Práctica | Qué trabaja | Dónde está documentada |
| --- | --- | --- |
| **D1-UD2** | Proyecto vacío → API REST: dependencias, `GET`/`POST`, JSON, JAR y puerto | `TEORIA/documentanción - profe/D1 -UD2.md` |
| **D3-UD2** | Formularios encadenados: `@ModelAttribute`, `th:object`, `th:field`, campos ocultos y `redirect` | `PROYECTOS/D3-UD2/D3-UD2.md` |
| **D4-UD2** | `GET` vs `POST`, *query string*, codificación e internacionalización (i18n) | `TEORIA/documentanción - profe/D4-UD2.md` |
| **UD1-UD2** | Práctica integradora de las dos unidades | `TEORIA/documentanción - profe/UD1-UD2.md` |

### Qué comprobar en cada una

**D1-UD2**

- [ ] El proyecto sin dependencia web arranca y termina.
- [ ] Con `spring-boot-starter-webmvc` aparece Tomcat en el 8080.
- [ ] `GET /hola?nombre=Ruvik` devuelve el saludo personalizado.
- [ ] Un objeto devuelto por un `@RestController` se serializa como JSON.
- [ ] `./gradlew build` genera el JAR en `build/libs`.
- [ ] `java -jar ...` arranca la aplicación fuera del IDE.

**D3-UD2**

- [ ] Los datos se conservan entre pasos con campos ocultos.
- [ ] `th:object` y `th:field` enlazan el formulario con el POJO.
- [ ] El parámetro `contador` decide qué vista se muestra.
- [ ] `redirect:` evita reenviar el `POST` al recargar.
- [ ] Volver atrás no pierde la información.

**D4-UD2**

- [ ] En `POST`, los datos viajan en el cuerpo; en `GET`, en la URL.
- [ ] La ruta del formulario coincide con el `@PostMapping`.
- [ ] Los parámetros de la URL se codifican correctamente.
- [ ] `messages.properties` y `messages_en.properties` cambian el idioma.
- [ ] Funciona con `?lang=en` y con la cabecera `Accept-Language`.

**UD1-UD2**

- [ ] Integra formularios, POJOs, validación y vistas.
- [ ] El flujo completo se puede recorrer sin errores.
- [ ] Las rutas y los verbos HTTP coinciden.

---

## Teoría: Spring MVC

**MVC** (*Model–View–Controller*) es un **patrón de arquitectura** que separa tres responsabilidades. No es exclusivo de Spring: nació en Smalltalk y se usa en muchísimos frameworks.

```text
                 ┌──────────────────┐
                 │     CLIENTE      │
                 └────────┬─────────┘
                          │ HTTP
                          ▼
                 ┌──────────────────┐
                 │   CONTROLLER     │
                 │  recibe y decide │
                 └────┬────────┬────┘
                      │        │
            actualiza │        │ elige
                      ▼        ▼
               ┌──────────┐ ┌──────────┐
               │  MODEL   │ │   VIEW   │
               │  datos   │ │  HTML    │
               └──────────┘ └──────────┘
```

### Las tres piezas

| Capa | Qué es | En nuestros proyectos | Ejemplo |
| --- | --- | --- | --- |
| **Modelo** | Los datos y su estado | POJOs como `FormularioPersona`, `TusDatos`, `Producto` | `nombre`, `edad` |
| **Vista** | La presentación | Plantillas Thymeleaf, CSS, JS | `hola.html` |
| **Controlador** | Coordina la petición | Clases con `@Controller` | `ControllerPlantilla` |

### Ejemplo real: `HolaMundoConPlantilla`

```java
@Controller
public class ControllerPlantilla {

    @GetMapping("/saludo")
    public String index(
            @RequestParam(name = "nombre", defaultValue = "mundo cruel") String nombre,
            Model modelo) {

        modelo.addAttribute("mensaje", nombre);  // M: dato para la vista
        return "hola";                           // V: nombre de la plantilla
    }
}
```

| Pieza | Dónde está |
| --- | --- |
| **M** | `mensaje` dentro del `Model` |
| **V** | `src/main/resources/templates/hola.html` |
| **C** | `ControllerPlantilla.index()` |

La plantilla solo lee el dato:

```html
<h1 th:text="|Hola ${mensaje}|"></h1>
```

> 🔗 Esto es exactamente lo que se desarrolla en el [día 10](bitacora-dia-diez.md). El día 9 deja la teoría; el día 10 la pone en práctica.

### Las anotaciones de Spring MVC

| Anotación | Para qué sirve |
| --- | --- |
| `@Controller` | Marca una clase como controlador de vistas |
| `@RestController` | Controlador que escribe la respuesta directamente (`@ResponseBody`) |
| `@RequestMapping` | Prefijo o mapeo general de rutas |
| `@GetMapping` | Atiende peticiones `GET` |
| `@PostMapping` | Atiende peticiones `POST` |
| `@RequestParam` | Recoge un parámetro de la URL o del formulario |
| `@PathVariable` | Recoge un valor de la propia ruta (`/producto/{id}`) |
| `@ModelAttribute` | Enlaza los datos de la petición con un objeto |
| `@RequestBody` | Recibe el cuerpo de la petición (normalmente JSON) |
| `@ResponseBody` | Escribe el valor devuelto en el cuerpo de la respuesta |

---

## El recorrido de una petición en MVC

```text
Navegador
   │  GET /saludo?nombre=Ruvik
   ▼
Tomcat (servidor embebido)
   │
   ▼
DispatcherServlet
   │  busca qué método atiende /saludo
   ▼
ControllerPlantilla.index()
   │  nombre = "Ruvik"
   │  modelo.addAttribute("mensaje", "Ruvik")
   │  return "hola"
   ▼
ViewResolver
   │  classpath:/templates/ + hola + .html
   ▼
templates/hola.html
   │  Thymeleaf sustituye ${mensaje}
   ▼
HTML final  ──►  Navegador
```

| Pieza | Responsabilidad |
| --- | --- |
| **Tomcat** | Recibe la conexión HTTP |
| **DispatcherServlet** | Reparte la petición al controlador adecuado |
| **HandlerMapping** | Sabe qué método corresponde a cada ruta |
| **Controlador** | Ejecuta la lógica, valida y llena el `Model` |
| **ViewResolver** | Traduce el nombre lógico a una plantilla real |
| **Thymeleaf** | Genera el HTML final |

> 💡 El controlador **no escribe HTML**: elige una vista y le pasa datos. Esa separación es la que permite cambiar la presentación sin tocar la lógica.

---

## MVC no es solo tres letras

MVC es la **capa de presentación**. En una aplicación real suele haber más capas detrás:

```text
Petición HTTP
     │
     ▼
┌─────────────┐
│ CONTROLLER  │  recibe, valida y elige la vista
└──────┬──────┘
       ▼
┌─────────────┐
│   SERVICE   │  reglas de negocio
└──────┬──────┘
       ▼
┌─────────────┐
│ REPOSITORY  │  acceso a datos
└──────┬──────┘
       ▼
┌─────────────┐
│ BASE DATOS  │
└─────────────┘
```

Por eso, decir «C → Business Logic» es una **simplificación útil al principio**, pero conviene matizarla: el controlador **coordina**; la lógica de negocio compleja va en **servicios**.

### Mitos y realidades

| Idea habitual | Realidad |
| --- | --- |
| «El modelo es una clase» | El modelo es el **conjunto de datos**; puede ser un POJO, una lista o un `Map` |
| «El controlador tiene toda la lógica» | El controlador coordina; la lógica va en servicios |
| «La vista es solo HTML» | También puede ser JSON, XML, PDF… |
| «MVC es de Spring» | Es un patrón; Spring solo lo implementa |
| «Un POJO es el modelo entero» | Un POJO es un objeto Java sencillo; el modelo puede estar formado por varios |

> 🧠 **POJO** significa *Plain Old Java Object*: una clase Java normal, con atributos, getters y setters, sin heredar de frameworks. Es la forma habitual de representar el modelo.

---

## Errores y detalles detectados

### 1. «sanize inpust» → *sanitize inputs*

La expresión correcta es **sanitize inputs** (o «sanear entradas»). No es un concepto de Spring Boot: es una práctica de **seguridad** aplicable a cualquier aplicación web.

### 2. Sanear y ejecutar en el puerto 80 son cosas distintas

La frase original las mezclaba. Sanear es **validar y escapar datos**; el puerto 80 es **permisos del sistema operativo**. No tienen relación entre sí.

### 3. «Bussines Logic» → *Business Logic*

Typo menor, pero conviene corregirlo: *business logic* = lógica de negocio.

### 4. `pojo` → `POJO`

Es un acrónimo: *Plain Old Java Object*. Se escribe en mayúsculas.

### 5. El JAR no es seguro por sí solo

Empaquetar la aplicación no la protege. La seguridad está en el **código**: validar, escapar, usar consultas parametrizadas y no confiar en el cliente.

### 6. Ejecutar como administrador no es la solución

Funciona para una prueba, pero da **demasiados privilegios** a la aplicación. En producción se usa un proxy inverso o un puerto no privilegiado.

### 7. `M → POJO` es una simplificación

Un POJO es un tipo de objeto, no todo el modelo. El modelo es el **conjunto de datos** que la vista necesita, y puede incluir varios POJOs, listas o valores sueltos.

### 8. `C → Business Logic` también es una simplificación

En aplicaciones pequeñas el controlador puede contener algo de lógica, pero lo sano es **delegar** en servicios. Si el controlador crece demasiado, se vuelve difícil de mantener y de probar.

### 9. La validación del navegador no es suficiente

`required`, `type="number"` o `maxlength` mejoran la experiencia, pero se pueden saltar. La validación **siempre** debe repetirse en el servidor.

### 10. El proyecto sin dependencia web no está «roto»

Arranca y termina porque **no tiene servidor**. No es un error de Spring Boot: es que falta `spring-boot-starter-webmvc`.

---

## Comparación con las bitácoras anteriores

### Línea temporal

| Día | Qué se aprendió | Proyecto |
| --- | --- | --- |
| **1** | Servidores de desarrollo web | — |
| **2** | El protocolo HTTP | — |
| **3** | Anatomía de una URL | — |
| **4** | Presentaciones de compañeros | — |
| **5** | Conceptos de las presentaciones (CLI y más) | — |
| **6** | Backend Java: sockets, servlets, hilos, MVC, Spring Boot | — |
| **7** | Primer endpoint `GET`, formulario `POST`, `@RequestParam` | `demo` |
| **8** | Familiarización con Spring Boot | `demo` |
| **9** | Repaso D1-UD2, JAR, puerto 80, saneamiento y teoría MVC | — |
| **10** | `@Controller`, plantillas Thymeleaf, `Model`, `AtomicInteger` | `contadorVisita`, `HolaMundoConPlantilla` |
| **11** | Lombok (`@Data`), `@ModelAttribute` y el nombre del objeto | `demoFormulario` |
| **12** | `redirect` no envía datos, `@ModelAttribute` vs `@RequestParam` | `PracticandoFormulario` |
| **13** | *(bitácora vacía — pendiente)* | — |
| **14** | HTTP sin estado, cookies, sesiones, `HttpSession`, carrito | `Carrito-compra-gemini` |

### Qué aporta cada día a lo de hoy

```text
Días 1-3   servidores, HTTP y URL ──►  entender qué es una petición
   │
Día 6      servlets, hilos y MVC  ──►  base teórica del backend
   │
Día 7      Spring Boot + endpoints ──►  primer proyecto que responde
   │
Día 9      repaso + JAR + puerto  ──►  consolidar y empaquetar
   │
Día 10     plantillas + Model     ──►  la V y la M en acción
   │
Día 11     @ModelAttribute        ──►  POJOs en formularios
   │
Día 12     redirect               ──►  flujo entre vistas
   │
Día 13     HttpSession            ──►  estado por usuario
```

### Antes y después del día 9

| Aspecto | Día 7 | Día 9 |
| --- | --- | --- |
| Objetivo | Publicar un endpoint | Entender el ciclo completo |
| Proyecto | Arranca desde el IDE | Se empaqueta como JAR |
| Servidor | Tomcat en 8080 | Se prueba el puerto 80 y sus límites |
| Datos | `@RequestParam` | Se plantea validar y sanear |
| Arquitectura | Se usa MVC sin nombrarlo | Se nombra y se separan responsabilidades |
| Seguridad | No se trata | Se introduce el saneamiento de entradas |

### Lo que se mantiene

- **Spring Boot + Gradle** siguen siendo la base.
- **`@GetMapping` / `@PostMapping`** siguen mapeando rutas.
- **Tomcat embebido** sigue siendo el servidor.
- **MVC** ya estaba ahí; el día 9 solo le pone nombre.
- **`./gradlew bootRun`** sigue siendo el comando de desarrollo.

### Lo que cambia de verdad

1. **Se piensa en el artefacto final**: el JAR y su ejecución fuera del IDE.
2. **Aparece la seguridad básica**: no confiar en el cliente.
3. **Se entiende el puerto como recurso del sistema**, no como configuración mágica.
4. **MVC deja de ser una sigla** y se convierte en un mapa de responsabilidades.
5. **Se prepara el terreno para las plantillas** del día 10.

> 🧠 **Conclusión:** el día 9 no añade una funcionalidad nueva, sino **criterio**. Saber por qué arranca (o no) un proyecto, cómo se empaqueta, qué se valida y quién hace qué dentro de MVC es lo que permite dejar de copiar código y empezar a entenderlo.

---

## Chuleta de código

```bash
# Desarrollo
./gradlew bootRun

# Compilar, probar y generar el JAR
./gradlew build

# Ejecutar el JAR
java -jar build/libs/mi-proyecto-0.0.1-SNAPSHOT.jar

# Cambiar el puerto al vuelo
java -jar mi-proyecto.jar --server.port=8081
```

```properties
# application.properties
server.port=8080
# server.port=80   ← requiere permisos en Linux/macOS
```

```groovy
// Dependencia mínima para una aplicación web
implementation 'org.springframework.boot:spring-boot-starter-webmvc'
```

```java
// Validación en el servidor
public class FormularioPersona {

    @NotBlank
    @Size(min = 2, max = 30)
    private String nombre;

    @NotNull
    @Min(18)
    private Integer edad;
}
```

```java
// Controlador con validación
@PostMapping("/")
public String verificar(
        @Valid @ModelAttribute("persona") FormularioPersona persona,
        BindingResult resultado) {

    if (resultado.hasErrors()) {
        return "formulario";
    }
    return "redirect:/resultado";
}
```

```html
<!-- Salida segura: escapa el HTML -->
<p th:text="${nombre}"></p>

<!-- Salida peligrosa: interpreta el HTML -->
<p th:utext="${nombre}"></p>

<!-- Mostrar errores de validación -->
<td th:if="${#fields.hasErrors('nombre')}" th:errors="*{nombre}">Error</td>
```

```java
// MVC en tres líneas
@Controller
public class ControllerPlantilla {
    @GetMapping("/saludo")
    public String index(@RequestParam(defaultValue = "mundo") String nombre, Model modelo) {
        modelo.addAttribute("mensaje", nombre); // M
        return "hola";                          // V
    }
}
```

```text
templates/  →  vistas que renderiza el controlador
static/     →  CSS, JS, imágenes y HTML estático
```

---

## Pendientes y preguntas

- [ ] Buscar un ejemplo concreto de **XSS** y comprobar la diferencia entre `th:text` y `th:utext`.
- [ ] Validar un formulario con `@Valid` + `BindingResult` y mostrar los errores en la plantilla.
- [ ] Generar el JAR con `./gradlew build` y ejecutarlo con `java -jar`.
- [ ] Probar `server.port=80` y documentar el error exacto.
- [ ] Comprobar qué proceso ocupa el puerto 80 en Windows con `netstat -ano | findstr :80`.
- [ ] Explicar por qué el proyecto sin dependencia web se apaga solo.
- [ ] Dibujar el recorrido de una petición MVC sin mirar los apuntes.
- [ ] Completar el mapa de ejercicios de la UD2 con las prácticas D3-UD2 y D4-UD2.
- [ ] Rellenar la **bitácora del día 13**, que está vacía.
- [ ] ¿Por qué es mejor un proxy inverso que ejecutar Spring Boot como administrador?
- [ ] ¿Qué diferencia hay entre validar en el navegador y validar en el servidor?

---

**Relacionado:** [[bitacora-dia-siete]] · [[bitacpra-dia-seis]] · [[bitacora-dia-diez]] · [[bitacora-dia-once]] · [[bitacora-dia-doce]] · [[bitacora-dia-trece]]

**Documentación:** `TEORIA/documentanción - profe/D1 -UD2.md` · `PROYECTOS/D3-UD2/D3-UD2.md` · `TEORIA/documentanción - profe/D4-UD2.md`

**TODO LO VISTO CONVERGE AHÍ:** [[D1 -UD2]]
