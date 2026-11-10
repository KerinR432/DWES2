<link rel="stylesheet" href="../css/diselpunk.css">

<div class="cover">
<p class="serial">CUADERNO DE PRÁCTICAS // DESARROLLO WEB EN ENTORNO SERVIDOR</p>

# D2 · UD2<br>SPRING BOOT

<p class="subtitle"><strong>Thymeleaf, POJOs y validación de formularios</strong></p>
<p>Kerin Aguilera</p>
<p class="serial">JAVA 21 · SPRING BOOT 4 · THYMELEAF · OCTUBRE 2026</p>
</div>

<div class="toc">
<p class="toc-title">ÍNDICE DE RUTA</p>
<ol>
<li><a href="#objetivo">Objetivo de la práctica</a></li>
<li><a href="#tutorial-1">Tutorial 1 · Controlador y plantilla</a></li>
<li><a href="#tutorial-2">Tutorial 2 · Entidades y formularios enlazados</a></li>
<li><a href="#tutorial-3">Tutorial 3 · Validación de formularios</a>
<ul>
<li><a href="#restricciones">El POJO con restricciones</a></li>
<li><a href="#controlador-validacion">El controlador con @Valid y BindingResult</a></li>
<li><a href="#fallo-validacion">Un fallo real: renombrar métodos en español</a></li>
<li><a href="#errores-plantilla">Mostrar los errores en la plantilla</a></li>
</ul>
</li>
<li><a href="#imperio">Práctica · La Fuerza del Imperio</a>
<ul>
<li><a href="#pojo-imperial">El POJO FormularioImperial</a></li>
<li><a href="#formulario-imperial">El formulario de reclutamiento</a></li>
<li><a href="#controlador-imperial">El controlador con condiciones</a></li>
<li><a href="#tucartilla">La cartilla de despliegue</a></li>
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

En D1-UD2 construí una API REST: el controlador devolvía texto o JSON y Spring lo escribía directamente en la respuesta. En esta práctica el enfoque cambia al lado **clásico** de Spring MVC: el controlador devuelve **vistas** HTML generadas con plantillas **Thymeleaf**, y la información viaja en ambas direcciones a través de **objetos Java (POJOs)**.

La sesión sigue los tres tutoriales de clase y termina con una práctica propia:

1. **Tutorial 1** — Un controlador `@Controller` que pasa un dato al modelo y una plantilla que lo pinta.
2. **Tutorial 2** — El salto a las entidades: un objeto `Saludo` enlaza los campos del formulario con el modelo.
3. **Tutorial 3** — Validación: `@Valid`, `BindingResult` y restricciones como `@NotNull` o `@Min`.
4. **Práctica** — *La Fuerza del Imperio*: un formulario completo (texto, número, casillas, desplegable y rango) con una vista final condicionada.

<div class="spec">

| Pieza | Detalle |
|---|---|
| Proyectos | `demoFormulario` · `ValidacionFormulario` · `fuerzaDelImperio` |
| Plantillas | Thymeleaf (`classpath:/templates/`) |
| Dependencias nuevas | `spring-boot-starter-thymeleaf` · `spring-boot-starter-validation` |
| Conceptos clave | `@Controller` · `Model` · `@ModelAttribute` · `@Valid` · `BindingResult` |

</div>

> La diferencia con D1 es una sola anotación: en `@RestController` el `String` devuelto **es** la respuesta; en `@Controller` el `String` devuelto es el **nombre de la plantilla** que Spring tiene que renderizar.

<a id="tutorial-1"></a>

## Tutorial 1 · Controlador y plantilla

Creamos el proyecto como siempre, esta vez marcando la dependencia **Thymeleaf** en Initializr. El primer controlador es minimalista:

```java
package ruvik.demoformulario;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class ControllerDemoFormulario {

    @GetMapping("/saludos")
    public String saludos(@RequestParam(name = "nombre", required = false, defaultValue = "Mundo") String nombre,
                          Model modelo) {
        modelo.addAttribute("nombre", nombre);
        return "saludos";
    }
}
```

La idea del ejercicio es poder pasarle un nombre por URL y que la página salude a ese nombre, o al mundo por defecto si no llega nada. Tres detalles nuevos respecto a D1:

- La clase lleva `@Controller` a secas: el valor devuelto ya no viaja al cuerpo HTTP, sino que Spring lo interpreta como el nombre de una vista.
- `Model` es el "mensajero" entre controlador y plantilla: `addAttribute("nombre", nombre)` deja el dato disponible para la vista con la clave `nombre`.
- `return "saludos"` hace que Spring busque la plantilla en `src/main/resources/templates/saludos.html`.

Y la plantilla:

```html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>SALUDOS</title>
</head>
<body>
    <p th:text="|Hola ${nombre}!|"></p>
</body>
</html>
```

`th:text` sustituye el contenido del elemento por el valor de la expresión. `${nombre}` lee la variable del modelo, y la sintaxis `|Hola ${nombre}!|` (literal + expresión entre barras) evita tener que concatenar.

![Saludo devuelto por la plantilla con el nombre recibido por URL](img%20-%20documents/practicaAle1.png)

<a id="tutorial-2"></a>

## Tutorial 2 · Entidades y formularios enlazados

Ahora damos el salto que da nombre a la sesión: los **POJOs** (objetos Java simples que guardan datos) como puente entre el formulario y el servidor.

### Primero el objeto

```java
package ruvik.demoformulario;

public class Saludo {
    private long id;
    private String contenido;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }

    public String getContenido() { return contenido; }
    public void setContenido(String contenido) { this.contenido = contenido; }
}
```

Un POJO no tiene nada de especial: propiedades privadas y sus *getters* y *setters*. Ese es todo el contrato que Spring necesita para rellenarlo.

### El controlador en dos actos

```java
package ruvik.demoformulario;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;

@Controller
public class ControllerDemoFormulario {

    @GetMapping("/saludos")
    public String formularioSaludos(Model modelo) {
        modelo.addAttribute("saludo", new Saludo());
        return "saludos";
    }

    @PostMapping("/saludos")
    public String saludosEnviado(@ModelAttribute Saludo saludo, Model modelo) {
        modelo.addAttribute("saludo", saludo);
        return "resultado";
    }
}
```

La pareja GET/POST es el patrón que se repite en todas las prácticas de la unidad:

- **GET** — prepara un `Saludo` vacío en el modelo y muestra el formulario.
- **POST** — `@ModelAttribute Saludo saludo` hace la magia: Spring crea el objeto y lo rellena con los campos que llegan de la petición. Luego lo devolvemos al modelo con la misma clave y mostramos la vista de resultado.

### El formulario

```html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>SALUDOS</title>
</head>
<body>
    <h1>Formulario</h1>
    <form action="#" th:action="@{/saludos}" th:object="${saludo}" method="post">
        <p>Id: <input type="text" th:field="*{id}" /></p>
        <p>Mensaje: <input type="text" th:field="*{contenido}" /></p>
        <p><input type="submit" value="submit" /> <input type="reset" value="reset" /></p>
    </form>
</body>
</html>
```

Aquí se concentran casi todas las etiquetas nuevas de Thymeleaf:

- `th:action="@{/saludos}"` — indica a dónde se envía el formulario. La expresión `@{...}` genera la URL relativa al contexto de la aplicación. El `action="#"` es solo un marcador para que el HTML sea válido si se abre la plantilla sin pasar por el servidor.
- `th:object="${saludo}"` — vincula el formulario completo al objeto del modelo.
- `th:field="*{id}"` — vincula ese `input` concreto con la propiedad `id` del objeto. Thymeleaf se ocupa de generar el `name`, el `id` y el `value`.

Y la diferencia que hay que memorizar para el examen: `th:object` usa **`${...}`** (busca el objeto en el modelo) pero `th:field` usa **`*{...}`** (selecciona propiedades del objeto elegido por `th:object`). Es decir: `$` mira el modelo entero; `*` mira dentro del objeto del formulario.

### El resultado

```html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Saludado</title>
</head>
<body>
    <h1>Resultado</h1>
    <p th:text="|id: ${saludo.id}|"></p>
    <p th:text="|contenido: ${saludo.contenido}|"></p>
    <a href="/saludos">Envia otro saludo</a>
</body>
</html>
```

Como el objeto llegó al modelo con la clave `saludo`, la vista resultado puede leer sus propiedades directamente con `${saludo.id}`.

![Formulario rellenado con los datos de prueba](img%20-%20documents/capturaAle2.png)

![Resultado con los datos del objeto recibido](img%20-%20documents/capturaAle3.png)

El enlace de la vista resultado nos devuelve al formulario para empezar de nuevo:

![Vuelta al formulario vacío](img%20-%20documents/capturaAle4.png)

<a id="tutorial-3"></a>

## Tutorial 3 · Validación de formularios

Después de los objetos, el siguiente nivel: que el servidor **rechace** los datos que no cumplen las reglas antes de procesarlos. Este proyecto (`ValidacionFormulario`) añade al `build.gradle` una dependencia más:

```gradle
implementation 'org.springframework.boot:spring-boot-starter-validation'
```

<a id="restricciones"></a>

### El POJO con restricciones

```java
package ruvik.validacionformulario;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public class FormularioPersona {

    @NotNull
    @Size(min = 2, max = 30)
    private String nombre;

    @NotNull
    @Min(18)
    private Integer edad;

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public Integer getEdad() { return edad; }
    public void setEdad(Integer edad) { this.edad = edad; }

    @Override
    public String toString() {
        return "FormularioPersona{nombre='" + nombre + "', edad=" + edad + '}';
    }
}
```

Las anotaciones son de **Jakarta Validation** (antes conocida como Bean Validation) y se colocan sobre las propiedades:

| Restricción | Regla que impone |
|---|---|
| `@NotNull` | El campo no puede quedarse vacío |
| `@Size(min = 2, max = 30)` | El texto debe medir entre 2 y 30 caracteres |
| `@Min(18)` | El valor numérico debe ser 18 o superior |

<a id="controlador-validacion"></a>

### El controlador con `@Valid` y `BindingResult`

```java
package ruvik.validacionformulario;

import jakarta.validation.Valid;
import org.springframework.stereotype.Controller;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Controller
public class ControladorWeb implements WebMvcConfigurer {

    @Override
    public void addViewControllers(ViewControllerRegistry registro) {
        registro.addViewController("/resultado").setViewName("resultado");
    }

    @GetMapping("/")
    public String verFornulario(@ModelAttribute("persona") FormularioPersona persona) {
        return "formulario";
    }

    @PostMapping("/")
    public String verificarInformacionPersona(@Valid @ModelAttribute("persona") FormularioPersona persona,
                                              BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            return "formulario";
        }
        return "redirect:/resultado";
    }
}
```

Concepto a concepto:

- **`@Valid`** activa la validación: antes de ejecutar el método, Spring aplica las restricciones del POJO.
- **`BindingResult`** recoge el resultado de esa validación. Es el parámetro que hay que consultar para saber si ha fallado algo. Un detalle importante: debe declararse **inmediatamente después** del parámetro con `@Valid`; si se separan, Spring lanza el error antes de entrar al método.
- **`addViewControllers`** viene de implementar `WebMvcConfigurer`: mapea una URL directamente a una vista (`/resultado` → `resultado.html`) sin necesidad de escribir un método controlador para ella.
- **`redirect:/resultado`** devuelve una redirección en vez de una vista: tras un POST correcto conviene redirigir (patrón *Post-Redirect-Get*) para que al pulsar F5 el navegador no reenvíe el formulario.

Si `bindingResult.hasErrors()` es cierto, se vuelve a la misma vista del formulario —con el objeto y sus errores ya en el modelo— para que la plantilla los muestre.

<a id="fallo-validacion"></a>

### Un fallo real: renombrar métodos en español

Mi primer intento no funcionaba: las validaciones no saltaban. El motivo fue este fragmento:

```java
// ❌ Mi primera versión (no hacía nada)
public void addVistaControlador(ViewControllerRegistry registro) {
    registro.addViewController("/resultado").setViewName("resultado");
}
```

Al traducir el método al español, **dejó de ser un *override***: `WebMvcConfigurer` declara `addViewControllers(...)`, y mi método con otro nombre era simplemente un método nuevo que Spring nunca invocaba. Por eso la vista `/resultado` no existía y el flujo se rompía. Investigando con Gemini llegué a la versión correcta: el nombre del método debe coincidir exactamente con el de la interfaz, y añadir `@Override` habría delatado el fallo al compilar.

```java
// ✔️ Versión correcta: sobrescribe el método de la interfaz
@Override
public void addViewControllers(ViewControllerRegistry registro) {
    registro.addViewController("/resultado").setViewName("resultado");
}
```

> Lección aprendida: los métodos de configuración de Spring se **sobrescriben**, no se traducen. `@Override` existe precisamente para pillarte estos fallos en compilación.

También añadí `@ModelAttribute("persona")` en los dos métodos para fijar la clave con la que el objeto viaja al modelo; así la plantilla puede referirse a `${persona}` en ambos casos, en el GET y en el POST fallido.

<a id="errores-plantilla"></a>

### Mostrar los errores en la plantilla

```html
<form action="#" th:action="@{/}" th:object="${persona}" method="post">
    <table>
        <tr>
            <td>Nombre</td>
            <td><input type="text" th:field="*{nombre}" /></td>
            <td th:if="${#fields.hasErrors('nombre')}" th:errors="*{nombre}">ERROR EN EL NOMBRE</td>
        </tr>
        <tr>
            <td>Edad</td>
            <td><input type="text" th:field="*{edad}" /></td>
            <td th:if="${#fields.hasErrors('edad')}" th:errors="*{edad}">ERROR EN LA EDAD</td>
        </tr>
        <tr>
            <td><button type="submit">Enviar</button></td>
        </tr>
    </table>
</form>
```

La pareja para pintar errores es:

- `th:if="${#fields.hasErrors('nombre')}"` — la celda solo se renderiza si ese campo tiene errores.
- `th:errors="*{nombre}"` — sustituye el contenido del elemento por los mensajes de error del campo.

Y así se comporta en el navegador. El formulario rechaza un nombre de una sola letra:

![Error de validación en el campo nombre](img%20-%20documents/capturaAle5.png)

Y también una edad por debajo del mínimo:

![Error de validación en el campo edad](img%20-%20documents/capturaAle6.png)

Con datos válidos, el POST redirige a `/resultado`:

![Formulario correcto tras superar la validación](img%20-%20documents/capturaAle7.png)

<a id="imperio"></a>

## Práctica · La Fuerza del Imperio

La práctica pedía poner en juego todo lo anterior sin el ejemplo de clase: un formulario de reclutamiento imperial (temática *Warhammer 40.000*) con **cinco tipos de control** distintos, y una vista final que cambia según los datos.

Por tiempo no pude añadir validaciones a esta práctica, pero sí todo lo demás: el POJO, el enlace completo del formulario y las condiciones en la vista de resultado. El proyecto (`fuerzaDelImperio`) ya incluye el *starter* de validación preparado para retomarlas.

<a id="pojo-imperial"></a>

### El POJO FormularioImperial

```java
package ruvik.fuerzadelimperio;

import java.util.ArrayList;

public class FormularioImperial {
    private String nombre;
    private Integer edad;
    private ArrayList<String> aficiones;
    private String ramaMilitar;
    private Integer rango;

    // Getters y setters para cada propiedad
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public Integer getEdad() { return edad; }
    public void setEdad(Integer edad) { this.edad = edad; }

    public ArrayList<String> getAficiones() { return aficiones; }
    public void setAficiones(ArrayList<String> aficiones) { this.aficiones = aficiones; }

    public String getRamaMilitar() { return ramaMilitar; }
    public void setRamaMilitar(String ramaMilitar) { this.ramaMilitar = ramaMilitar; }

    public Integer getRango() { return rango; }
    public void setRango(Integer rango) { this.rango = rango; }
}
```

Lo interesante aquí es `ArrayList<String> aficiones`: cada casilla marcada del formulario se acumula en esa lista.

<a id="formulario-imperial"></a>

### El formulario de reclutamiento

La página está maquetada con el tema imperial (pergamino, oro y rojo inquisición, estilos dentro del propio HTML), pero lo que le interesa al servidor es esto:

```html
<form action="#" th:action="@{/}" th:object="${imperial}" method="post">

    <p class="label-text">Identificación del Sujeto (Nombre):</p>
    <input type="text" th:field="*{nombre}" placeholder="Ej. Titus, Yarrick..." required />

    <p class="label-text">Ciclos Solares (Edad):</p>
    <input type="number" th:field="*{edad}" min="1" required />

    <p class="label-text">Habilidades Adicionales (Aficiones):</p>
    <div class="checkbox-group">
        <label class="checkbox-item"><input type="checkbox" th:field="*{aficiones}" value="Deporte" /> Combate Cuerpo a Cuerpo</label>
        <label class="checkbox-item"><input type="checkbox" th:field="*{aficiones}" value="Arte" /> Culto Imperial</label>
        <label class="checkbox-item"><input type="checkbox" th:field="*{aficiones}" value="Fotografia" /> Auspex / Reconocimiento</label>
    </div>

    <p class="label-text">Asignación de Destino (Rama Militar):</p>
    <select name="ramaMilitar" th:field="*{ramaMilitar}" required>
        <option value="" disabled selected>-- A la espera de órdenes del Administratum --</option>
        <option value="Astra Militarun">Astra Militarum (El Martillo del Emperador)</option>
        <option value="Ultramarines">Adeptus Astartes (Ultramarines)</option>
        <option value="Salamandras">Adeptus Astartes (Salamandras)</option>
    </select>

    <p class="label-text">Aptitud de Liderazgo (Rango):</p>
    <input type="range" th:field="*{rango}" min="1" max="10" step="1" />

    <button type="submit">Sellar Juramento</button>
</form>
```

Tres detalles que resumen lo aprendido:

- Todas las casillas comparten `th:field="*{aficiones}"`: aunque haya varias, Spring las agrupa en la lista del POJO según sus `value`.
- El `<select>` vincula el texto visible con el `value` interno; el POJO guarda el `value`.
- El `input type="range"` es un número más: se enlaza igual que un texto, con `th:field="*{rango}"`.

<a id="controlador-imperial"></a>

### El controlador con condiciones

```java
package ruvik.fuerzadelimperio;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;

@Controller
public class ControllerDelImperio {

    @GetMapping("/")
    public String mostrarFormulario(FormularioImperial imperial, Model modelo) {
        modelo.addAttribute("imperial", imperial);
        return "formulario";
    }

    @PostMapping("/")
    public String procesarFormulario(FormularioImperial imperial, Model modelo) {
        modelo.addAttribute("imperial", imperial);

        if (imperial.getEdad() > 18) {
            modelo.addAttribute("esMayor", true);
        }
        if (imperial.getRango() > 5) {
            modelo.addAttribute("esAltoRango", true);
        }
        return "tucartilla";
    }
}
```

Fíjate en el `@GetMapping`: el método recibe `FormularioImperial imperial` **sin** `new FormularioImperial()` ni anotación visible. Spring lo instancia por nosotros y lo enlaza con los campos de la petición (es el mismo comportamiento de `@ModelAttribute`, aplicado por defecto a los POJOs). Por eso basta con devolverlo al modelo tal cual.

En el POST, las dos condiciones deciden qué fragmentos verá el usuario: `esMayor` (edad superior a 18) y `esAltoRango` (rango superior a 5). Lo importante es que **solo se añaden al modelo cuando son ciertas**: en la plantilla, `th:if="${esMayor}"` renderiza el bloque únicamente si esa clave existe.

<a id="tucartilla"></a>

### La cartilla de despliegue

La vista `tucartilla.html` pasó por dos versiones: primero un listado rápido con `th:text`, y después la reestilización definitiva al tema imperial, con los datos en filas y los mensajes condicionales en cajas. Los fragmentos que importan son estos:

```html
<div class="data-row">
    <span class="data-label">Rama Asignada:</span>
    <span class="data-value" th:text="${imperial.ramaMilitar}"></span>
</div>

<div class="data-row">
    <span class="data-label">Nivel de Autoridad:</span>
    <span class="data-value" th:text="|Nivel ${imperial.rango}|"></span>
</div>

<div class="data-row">
    <span class="data-label">Especialidades Registradas:</span>
    <div th:each="aficion : ${imperial.aficiones}" th:text="|- ${aficion}|"></div>
</div>
```

`th:each` recorre la lista de aficiones y repite el elemento por cada valor. Y las dos cajas condicionales:

```html
<!-- Solo si el recluta es mayor de edad -->
<div class="message-box" th:if="${esMayor}">
    <h3 class="box-title">/// Evaluación Táctica de Supervivencia</h3>
    <p>Como ciudadano experimentado, entiendes que esto no será un paseo.
       Servir al Emperador es el mayor de los honores, pero requerirá el
       mayor de los sacrificios...</p>
</div>

<!-- Solo si el rango supera 5 -->
<div class="command-box" th:if="${esAltoRango}">
    <h3 class="box-title">/// Directiva de Alto Mando</h3>
    <ul class="planet-list">
        <li><h2>Mundo Trono: TERRA (Prioridad Secundus)</h2></li>
        <li><h2>Mundo Colmena: ARCADIA (Prioridad Extremis)</h2></li>
    </ul>
</div>
```

Primero probamos con un recluta menor de edad y de rango bajo (no aparece ninguna caja condicional):

![Formulario imperial con un recluta joven y de bajo rango](img%20-%20documents/D2-UD1.1.png)

Y la cartilla muestra solo sus datos básicos:

![Cartilla con los datos del recluta](img%20-%20documents/D1-UD2.2.png)

Al repetir la prueba con un recluta de rango alto, la directiva de alto mando y sus planetas aparecen gracias al `th:if`:

![Cartilla con la directiva de alto mando y los planetas asignados](img%20-%20documents/UD2-UD2.3.png)

<a id="resumen"></a>

## Resumen de conceptos

### Etiquetas de Thymeleaf

| Etiqueta | Qué hace |
|---|---|
| `th:text` | Sustituye el contenido del elemento por el valor de la expresión |
| `th:action="@{/ruta}"` | URL de envío del formulario, relativa al contexto (`@{...}`) |
| `th:object="${clave}"` | Vincula el formulario con el objeto del modelo |
| `th:field="*{propiedad}"` | Vincula un `input` con una propiedad; genera `name`, `id` y `value` |
| `${...}` | Lee variables del modelo (contexto general) |
| `*{...}` | Lee propiedades del objeto elegido con `th:object` (contexto del formulario) |
| `th:each` | Itera una colección repitiendo el elemento |
| `th:if` | Renderiza el elemento solo si la condición es cierta |
| `th:errors="*{campo}"` | Imprime los mensajes de error de un campo |
| `#fields.hasErrors('campo')` | Comprueba si un campo tiene errores de validación |

### Anotaciones de Spring MVC

| Elemento | Qué hace |
|---|---|
| `@Controller` | El `String` devuelto se interpreta como nombre de plantilla |
| `Model` / `addAttribute` | Lleva datos del controlador a la vista |
| `@ModelAttribute` | Crea el objeto y lo rellena con los campos de la petición |
| `@Valid` | Activa la validación de las restricciones del POJO |
| `BindingResult` | Recoge los errores de validación; va justo tras el parámetro `@Valid` |
| `WebMvcConfigurer` | Interfaz de configuración de Spring MVC |
| `addViewControllers` | Mapea una URL a una vista sin escribir método controlador |
| `redirect:` | Prefijo que responde con una redirección HTTP (patrón PRG) |

### Restricciones de validación

| Anotación | Regla |
|---|---|
| `@NotNull` | El campo no puede ser `null` |
| `@Size(min, max)` | Longitud del texto dentro del rango |
| `@Min(valor)` | Valor numérico mínimo permitido |

Ideas clave que me llevo de la práctica:

- Con `@Controller` + Thymeleaf el flujo es siempre el mismo: **GET muestra el formulario con un objeto vacío, POST recibe el objeto rellenado y decide la siguiente vista**.
- `$` y `*` no son intercambiables: `$` mira el modelo completo, `*` mira dentro del objeto del formulario.
- Las validaciones se declaran en el POJO, se activan con `@Valid` y se consultan con `BindingResult`; la plantilla las pinta con `#fields.hasErrors` y `th:errors`.
- Los métodos de `WebMvcConfigurer` se **sobrescriben**: renombrarlos rompe la configuración sin avisar.
- Las condiciones de la vista se preparan en el controlador (añadir o no la clave al modelo) y se aplican en la plantilla (`th:if`).

<a id="repaso"></a>

## Preguntas de repaso

1. ¿Qué diferencia hay entre `@Controller` y `@RestController` cuando un método devuelve un `String`? *(Tutorial 1)*
2. ¿En qué carpeta busca Spring las plantillas Thymeleaf y cómo se relaciona con el valor devuelto por el controlador? *(Tutorial 1)*
3. ¿Qué hace `th:text` y para qué sirve la sintaxis `|Hola ${nombre}!|`? *(Tutorial 1)*
4. ¿Qué papel tiene el parámetro `Model` y cómo se pasan los datos a la plantilla? *(Tutorial 1)*
5. ¿Por qué el GET del formulario mete un `new Saludo()` en el modelo y qué ocurriría si no lo hiciera? *(Tutorial 2)*
6. ¿Qué diferencia hay entre `th:object="${saludo}"` y `th:field="*{contenido}"`? ¿Y entre `${...}` y `*{...}`? *(Tutorial 2)*
7. ¿Qué hace `@ModelAttribute` en el método del POST? *(Tutorial 2)*
8. ¿Qué validaciones impone `FormularioPersona` y qué anotaciones las expresan? *(Tutorial 3)*
9. ¿Qué hacen `@Valid` y `BindingResult`, y en qué orden deben declararse? *(Tutorial 3)*
10. ¿Para qué sirve `addViewControllers` y por qué dejó de funcionar al traducir el nombre del método al español? *(Tutorial 3)*
11. ¿Cómo se muestran los errores de un campo en la plantilla Thymeleaf? *(Tutorial 3)*
12. ¿Por qué se devuelve `redirect:/resultado` en vez del nombre de la vista tras un POST correcto? *(Tutorial 3)*
13. ¿Cómo se enlazan varias casillas de verificación con una sola propiedad `ArrayList<String>` del POJO? *(Práctica imperial)*
14. ¿Qué condiciones activan `esMayor` y `esAltoRango`, y cómo consigue la cartilla que sus bloques aparezcan solo cuando toca? *(Práctica imperial)*

<a id="conclusion"></a>

## Conclusión

Muchos conceptos nuevos en una sola práctica. Las validaciones siempre se me han complicado —y el fallo del método renombrado me costó un buen rato—, pero el trabajo con objetos y modelos me gusta mucho: el POJO actúa como contrato entre lo que el usuario teclea y lo que el servidor recibe, y Thymeleaf solo necesita saber qué objeto manda en cada formulario.

Lo que peor me resulta es que las etiquetas de Thymeleaf cambian de papel según el contexto: `${...}` y `*{...}` parecen lo mismo hasta que mezclas una donde iba la otra. Con estas prácticas ya tengo la regla clara: `$` para el modelo, `*` para el objeto del formulario.

Todo lo visto hasta aquí converge en una misma idea: en D1 la respuesta se construía a mano (texto o JSON); ahora la construye la plantilla con los datos que el controlador prepara. La siguiente práctica (D3) encadena varios formularios de estos conservando los datos entre pasos, y D4 vuelve a los parámetros HTTP y la codificación de URL.

<a id="recursos"></a>

## Recursos

- [Repositorio del proyecto en GitHub](https://github.com/KerinR432/DWES2)
- [Guía oficial: Validating Form Input](https://spring.io/guides/gs/validating-form-input/) — la base del Tutorial 3
- [Documentación de Thymeleaf](https://www.thymeleaf.org/documentation.html)
- Stack Overflow y Gemini (en concreto, para detectar el fallo del método `addViewControllers` renombrado)

<div class="endmark">
FIN DE LA TRANSMISIÓN // D2 · UD2
</div>
