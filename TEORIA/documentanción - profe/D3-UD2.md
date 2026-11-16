<link rel="stylesheet" href="../css/guia-galactica.css">

<div class="cover">
<p class="serial">CUADERNO DE PRÁCTICAS // DESARROLLO WEB EN ENTORNO SERVIDOR</p>

# D3 · UD2<br>SPRING BOOT

<p class="subtitle">Formularios encadenados</p>
<p>Kerin Aguilera</p>
<p class="serial">JAVA 21 · SPRING BOOT · THYMELEAF · OCTUBRE 2026</p>
</div>

<div class="toc">
<p class="toc-title">ÍNDICE DE RUTA</p>
<ol>
<li><a href="#objetivo">Objetivo de la práctica</a></li>
<li><a href="#problema">El problema de fondo: HTTP no recuerda</a></li>
<li><a href="#recorrido">Recorrido de la práctica</a></li>
<li><a href="#primera-version">Primera versión: avanzar entre formularios</a>
<ul>
<li><a href="#paso-1">Paso 1 · El nombre</a></li>
<li><a href="#paso-2">Paso 2 · Las aficiones</a></li>
<li><a href="#paso-3">Paso 3 · El lugar</a></li>
</ul>
</li>
<li><a href="#primera-logica">Primera lógica del controlador</a></li>
<li><a href="#modelo">El modelo de datos: Lombok entra en juego</a></li>
<li><a href="#fallo">Problema · Se pierden los datos al volver atrás</a></li>
<li><a href="#solucion">Solución · Reenviar los valores anteriores</a></li>
<li><a href="#segunda-version">Segunda versión: el paso llega en la petición</a></li>
<li><a href="#version-final">Versión final: switch, ruta raíz y limpieza</a>
<ul>
<li><a href="#paso-4">Paso 4 · El sexo y el resultado</a></li>
<li><a href="#pojo-final">El POJO definitivo</a></li>
</ul>
</li>
<li><a href="#tests">La suite de pruebas del flujo completo</a></li>
<li><a href="#resumen">Resumen de conceptos</a></li>
<li><a href="#repaso">Preguntas de repaso</a></li>
<li><a href="#conclusion">Conclusión</a></li>
<li><a href="#recursos">Recursos</a></li>
</ol>
</div>

<a id="objetivo"></a>

## Objetivo de la práctica

En D2 cada práctica era un formulario suelto: un GET, un POST y a otra cosa. Aquí el salto es de concepto: construir un **formulario dividido en pasos** —nombre, aficiones, lugar, sexo— donde cada paso solo pide parte de los datos, y al final se muestra un resumen con todo lo introducido, con botones para **avanzar, retroceder y empezar de nuevo**.

El ejemplo usa Spring Boot, Thymeleaf y un objeto Java (`TusDatos`) que enlaza los campos con el modelo. La dificultad no está en los formularios individuales (eso ya salía en D2), sino en que **la información tiene que sobrevivir a varios envíos**, y para eso hay que entender cómo viajan los datos por HTTP y decidir dónde guardarlos.

<div class="spec">

| Pieza | Detalle |
|---|---|
| Proyecto | `D3-UD2` |
| Plantillas | `Formulario1` … `Formulario4` y `Resultado` (Thymeleaf) |
| Novedad | Lombok (`@Data`) y la expresión `switch` de Java 21 |
| Pruebas | `FlujoFormularioTest` con MockMvc (8 casos) |
| Conceptos clave | Campos ocultos · `th:each` · estado entre peticiones |

</div>

<a id="problema"></a>

## El problema de fondo: HTTP no recuerda

Antes de ver código conviene tener claro el enemigo: **HTTP es un protocolo sin estado**. Cada petición que recibe el servidor es independiente de las anteriores: cuando el usuario envía el paso 2, el servidor no recuerda nada del paso 1 salvo lo que **vuelva a llegar en esa petición**.

Eso deja tres estrategias posibles para un formulario por pasos:

1. **Reenviarlo todo en cada formulario** (campos ocultos) — la que usa esta práctica.
2. Guardarlo en la **sesión** del usuario en el servidor.
3. Guardarlo en una base de datos a medio plazo.

La primera es la más didáctica porque te obliga a ver, campo a campo, qué viaja en cada POST. Por eso el ejercicio la pide así.

<a id="recorrido"></a>

## Recorrido de la práctica

1. Se solicita el **nombre**.
2. Se seleccionan las **aficiones**.
3. Se elige el **lugar** de nacimiento.
4. Se indica el **sexo**.
5. Se muestra el **resumen** con los datos y las opciones de volver atrás o empezar de nuevo.

<a id="primera-version"></a>

## Primera versión: avanzar entre formularios

<a id="paso-1"></a>

### Paso 1 · El nombre

El primer formulario no necesita campos ocultos: todavía no hay datos anteriores que conservar. El atributo `th:object` vincula los campos al objeto que recibe la plantilla:

```html
<!DOCTYPE html>
<html lang="es" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <title>Formulario 1 · Nombre</title>
</head>
<body>
<h1>Paso 1 · Tu nombre</h1>

<form method="post" th:action="@{/procesar}" th:object="${datos}">
    <p>
        <label for="nombre">Nombre:</label>
        <input id="nombre" type="text" th:field="*{nombre}" autocomplete="name" required>
    </p>

    <button type="submit" name="contador" value="1">Enviar</button>
</form>
</body>
</html>
```

Fíjate en el botón: además de enviar el formulario, lleva `name="contador"` y `value="1"`. El botón de envío **también es un parámetro de la petición**, y ese número le dice al controlador a qué paso vamos.

Para comprobar los datos recibidos, imprimí temporalmente el objeto y el contador en la consola:

```java
System.out.println(datos);
System.out.println(siguiente);
```

<div class="machine">

```text
TusDatos(nombre=Ruvik, aficciones=[], lugar=null, sexo=null)
1
```

El `toString()` tan limpio no lo escribí yo: lo genera Lombok (ver la sección del modelo de datos). El `1` es el `contador` del botón.

</div>

Así se ve el primer formulario:

![Primer paso: introducción del nombre](img%20-%20documents/D3-UD2.1.png)

<a id="paso-2"></a>

### Paso 2 · Las aficiones

El segundo formulario recibe el nombre del paso anterior. El campo oculto `nombre` permite volver a enviarlo junto con las nuevas selecciones:

```html
<!DOCTYPE html>
<html lang="es" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <title>Formulario 2 · Aficiones</title>
</head>
<body>
<h1>Paso 2 · Tus aficiones</h1>

<form method="post" th:action="@{/procesar}" th:object="${datos}">
    <fieldset>
        <legend>Selecciona tus aficiones:</legend>

        <label><input type="checkbox" th:field="*{aficciones}" value="Fútbol"> Fútbol</label>
        <label><input type="checkbox" th:field="*{aficciones}" value="Baloncesto"> Baloncesto</label>
        <label><input type="checkbox" th:field="*{aficciones}" value="Voleibol"> Voleibol</label>
        <label><input type="checkbox" th:field="*{aficciones}" value="Bádminton"> Bádminton</label>
    </fieldset>

    <button type="submit" name="contador" th:value="${contador + 1}">Siguiente</button>
    <button type="submit" name="contador" value="-1">Volver atrás</button>

    <input type="hidden" th:field="*{nombre}">
</form>
</body>
</html>
```

Vista del formulario:

![Segundo paso: selección de aficiones](img%20-%20documents/D3-UD2.2.png)

En la primera implementación, la consola mostraba cómo se incorporan los datos paso a paso:

<div class="machine">

```text
TusDatos(nombre=Ruvik, aficciones=[], lugar=null, sexo=null)
1
TusDatos(nombre=Ruvik, aficciones=[Baloncesto, Bádminton], lugar=null, sexo=null)
2
```

</div>

Dos detalles del HTML: los botones ya usan `th:value="${contador + 1}"` para calcular el paso siguiente a partir del que llegó al modelo, y "Volver atrás" envía `-1`, el valor especial que el controlador interpreta como "regresa al paso 1 pero conservando lo escrito".

<a id="paso-3"></a>

### Paso 3 · El lugar

El tercer formulario añade el lugar y vuelve a enviar los datos de los pasos anteriores. Aquí aparece la pieza más delicada: **conservar una colección**. Para `aficciones` (una lista) no basta un campo oculto: se genera **uno por cada elemento** con `th:each`:

```html
<!DOCTYPE html>
<html lang="es" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <title>Formulario 3 · Lugar</title>
</head>
<body>
<h1>Paso 3 · Lugar de nacimiento</h1>

<form method="post" th:action="@{/procesar}" th:object="${datos}">
    <p>
        <label for="lugar">Lugar:</label>
        <select id="lugar" th:field="*{lugar}" required>
            <option value="">-- Selecciona una opción --</option>
            <option value="Madrid">Madrid</option>
            <option value="Sevilla">Sevilla</option>
            <option value="Málaga">Málaga</option>
        </select>
    </p>

    <button type="submit" name="contador" th:value="${contador + 1}">Siguiente</button>
    <button type="submit" name="contador" th:value="${contador - 1}">Volver atrás</button>

    <input type="hidden" th:field="*{nombre}">
    <input type="hidden" th:each="aficcion : ${datos.aficciones}"
           name="aficciones" th:value="${aficcion}">
</form>
</body>
</html>
```

Vista del formulario:

![Tercer paso: selección del lugar](img%20-%20documents/D3-UD2.3.png)

Después de seleccionar, por ejemplo, Sevilla, el objeto ya contiene los datos de los tres pasos:

<div class="machine">

```text
TusDatos(nombre=Ruvik, aficciones=[Baloncesto, Bádminton], lugar=Sevilla, sexo=null)
3
```

</div>

<a id="primera-logica"></a>

## Primera lógica del controlador

En la primera versión, un único método `@PostMapping` procesa todos los envíos. El parámetro `contador` indica qué paso se acaba de completar y determina qué plantilla se muestra a continuación:

```java
@PostMapping("/procesar")
public String procesarDatos(
        @ModelAttribute TusDatos datos,
        @RequestParam("contador") String contador,
        Model modelo) {

    siguiente += Integer.parseInt(contador);
    System.out.println(datos);
    System.out.println(siguiente);

    if (siguiente == 1) {
        modelo.addAttribute("datos", datos);
        return "Formulario2";
    }

    if (siguiente == 2) {
        modelo.addAttribute("datos", datos);
        return "Formulario3";
    }

    modelo.addAttribute("datos", datos);
    return "Resultado";
}
```

Esta primera aproximación utiliza un contador global:

```java
static int siguiente = 0;
```

Es una solución cómoda para probar el recorrido, pero tiene un fallo serio: **una variable `static` se comparte entre todas las peticiones de todos los usuarios**. Dos personas rellenando el formulario a la vez escribirían en el mismo contador y el flujo se desincronizaría. Además, si un usuario recargaba la página o usaba el botón atrás del navegador, el contador quedaba desfasado respecto a su paso real.

> La conclusión de esta primera versión: el estado del flujo **no puede vivir en el servidor** sin más; o viaja con el usuario (en la petición) o se gestiona con algo pensado para ello (sesión, base de datos).

<a id="modelo"></a>

## El modelo de datos: Lombok entra en juego

`TusDatos` reúne la información que se va completando en los distintos formularios. Frente a los POJOs de D2 (escritos a mano), aquí uso **Lombok** para generar el código repetitivo:

```java
package ruvik.d3ud2;

import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Data
public class TusDatos {
    private String nombre;
    private List<String> aficciones = new ArrayList<>();
    private String lugar;
    private String sexo;
}
```

`@Data` genera en compilación los *getters*, *setters*, `toString`, `equals` y `hashCode*` de todas las propiedades. Por eso las trazas de consola del apartado anterior salen tan legibles sin que yo haya escrito un solo `toString()`. En el `build.gradle`, Lombok entra en dos líneas porque es un procesador de anotaciones:

```gradle
compileOnly 'org.projectlombok:lombok'
annotationProcessor 'org.projectlombok:lombok'
```

<div class="note">

Este POJO pasó por una limpieza a mitad de práctica: la primera versión tenía el campo `Aficciones` (con mayúscula, siguiendo el nombre de la lista de la vista) y una lista `datosFinales` que al final no usé. Lo dejé como `aficciones` en minúscula (convención Java para propiedades) y eliminé lo que no servía. Las plantillas y los `th:field` tuvieron que renombrarse en consecuencia.

</div>

<a id="fallo"></a>

## Problema · Se pierden los datos al volver atrás

Con el avance lineal funcionando, probé la navegación hacia atrás… y los datos de los pasos anteriores **desaparecían**. Volvía del paso 3 al 2 y el nombre ya no estaba; seguía del 2 al 1 y volvía a aparecer (porque el paso 1 es el que tiene el campo visible).

<div class="dont-panic">

La causa, al final, era de libro: el formulario de cada paso solo enviaba **el campo visible del paso actual**. Los valores previos no viajaban en la petición, no llegaban al controlador y, por tanto, no podían volver a incluirse en el modelo. HTTP no recuerda: si no lo envías, no existe.

</div>

![Consulta realizada para resolver la pérdida de datos](img%20-%20documents/D3-UD2.6.png)

<a id="solucion"></a>

## Solución · Reenviar los valores anteriores

La corrección fue añadir a cada formulario **campos ocultos** con los datos ya introducidos:

- Para campos simples (`nombre`, `lugar`, `sexo`): `<input type="hidden" th:field="*{nombre}">` — `th:field` genera el `name` y el `value` actual.
- Para la lista de aficiones: un campo oculto **por cada elemento**, generado con `th:each` (como se vio en el paso 3).

Así, cada POST lleva siempre el estado completo del objeto hasta ese momento, y el controlador puede volver a ponerlo en el modelo para la siguiente vista.

<div class="warning">

Los campos ocultos sirven para transportar valores entre peticiones, pero **viajan por el navegador del usuario**: cualquiera puede abrir las herramientas de desarrollo y modificarlos antes de enviar. No deben usarse para información sensible (precios, permisos, cantidades de stock…) ni para confiar en valores que el servidor no haya validado. Para eso, el estado debe validarse o guardarse en el servidor.

</div>

<a id="segunda-version"></a>

## Segunda versión: el paso llega en la petición

El segundo problema (el contador `static`) se arregló a la vez: en vez de acumular el paso en una variable global, **cada petición trae el suyo** en el botón pulsado, y el controlador limita a interpretarlo:

```java
@PostMapping("/procesar")
public String procesarDatos(@ModelAttribute TusDatos datos,
                            @RequestParam("contador") Integer contador,
                            Model modelo) {
    int siguiente = contador;
    System.out.println(datos);
    System.out.println(siguiente);

    if (siguiente == 0) {
        return "redirect:/formulario1";
    }

    if (siguiente == 1) {
        modelo.addAttribute("datos", datos);
        modelo.addAttribute("contador", contador);
        return "Formulario2";
    }
    // … y así hasta el paso 4 y el resultado
}
```

Ahora el flujo es **sin estado**: da igual quién navega ni en qué orden; el paso siguiente se calcula desde el valor que el propio usuario envía (`contador + 1` para avanzar, `contador - 1` para retroceder, `0` para reiniciar). Cada botón de la interfaz decla su intención en el HTML:

```html
<button type="submit" name="contador" th:value="${contador + 1}">Siguiente</button>
<button type="submit" name="contador" th:value="${contador - 1}">Volver atrás</button>
<button type="submit" name="contador" value="0">Volver al inicio</button>
```

<a id="version-final"></a>

## Versión final: switch, ruta raíz y limpieza

La última refactorización dejó el controlador en su estado actual en el repositorio: una **expresión `switch`** de Java 21 sustituye la cadena de `if`, y una ruta raíz `/` redirige al primer paso para que la aplicación siempre empiece por el sitio correcto:

```java
package ruvik.d3ud2.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import ruvik.d3ud2.TusDatos;

@Controller
public class ControladorFormulariosEncadenado {

    @GetMapping("/")
    public String inicio() {
        return "redirect:/formulario1";
    }

    @GetMapping("/formulario1")
    public String formulario1(@ModelAttribute("datos") TusDatos datos, Model model) {
        model.addAttribute("datos", datos);
        model.addAttribute("contador", 0);
        return "Formulario1";
    }

    @PostMapping("/procesar")
    public String procesarDatos(@ModelAttribute("datos") TusDatos datos,
                                @RequestParam("contador") Integer contador,
                                Model modelo) {
        modelo.addAttribute("datos", datos);
        modelo.addAttribute("contador", contador);

        return switch (contador) {
            // Volver desde el paso 2 sin perder los datos ya introducidos.
            case -1 -> "Formulario1";
            // Empezar de nuevo: se descarta el objeto y se vuelve al paso 1.
            case 0 -> "redirect:/formulario1";
            case 1 -> "Formulario2";
            case 2 -> "Formulario3";
            case 3 -> "Formulario4";
            case 4 -> "Resultado";
            default -> "redirect:/formulario1";
        };
    }
}
```

Puntos a comentar de esta versión:

- **`case -1`**: el "Volver atrás" del paso 2. No redirige, sino que devuelve `Formulario1` **con los datos en el modelo**, para que el campo nombre llegue relleno.
- **`case 0`**: "Volver al inicio". Redirige (en vez de renderizar) para que el navegador haga un GET limpio y el objeto empiece de cero.
- **`default`**: cualquier otro valor se trata como reinicio. Si alguien manipula el `contador` desde el navegador, la aplicación no rompe.
- **`@ModelAttribute("datos")`**: fija explícitamente la clave del modelo; así las cinco plantillas siempre se refieren a `${datos}`.
- El **GET de `/formulario1` inicializa `contador` a `0`** para que los `th:value="${contador + 1}"` de las plantillas tengan de dónde partir.

<a id="paso-4"></a>

### Paso 4 · El sexo y el resultado

El cuarto formulario incorpora botones de opción y reenvía todos los valores anteriores:

```html
<!DOCTYPE html>
<html lang="es" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <title>Formulario 4 · Sexo</title>
</head>
<body>
<h1>Paso 4 · Sexo</h1>

<form method="post" th:action="@{/procesar}" th:object="${datos}">
    <fieldset>
        <legend>Selecciona una opción:</legend>

        <label><input type="radio" th:field="*{sexo}" value="M" required> Masculino (M)</label>
        <label><input type="radio" th:field="*{sexo}" value="F"> Femenino (F)</label>
    </fieldset>

    <button type="submit" name="contador" th:value="${contador + 1}">Finalizar</button>
    <button type="submit" name="contador" th:value="${contador - 1}">Volver atrás</button>

    <input type="hidden" th:field="*{nombre}">
    <input type="hidden" th:each="aficcion : ${datos.aficciones}"
           name="aficciones" th:value="${aficcion}">
    <input type="hidden" th:field="*{lugar}">
</form>
</body>
</html>
```

El formulario se muestra así:

![Cuarto paso: selección del sexo](img%20-%20documents/D3-UD2.4.png)

Y la vista final presenta los datos recibidos, con `th:text` insertando valores y `th:each` recorriendo la lista de aficiones. El formulario de navegación reenvía también todos los campos ocultos:

```html
<!DOCTYPE html>
<html lang="es" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <title>Resultado · Resumen</title>
</head>
<body>
<h1>Resumen de tus datos</h1>

<p th:text="|Te llamas: ${datos.nombre}|"></p>

<p>Tus aficiones:</p>
<ul>
    <li th:each="aficcion : ${datos.aficciones}" th:text="${aficcion}"></li>
</ul>

<p th:text="|Tu lugar de nacimiento: ${datos.lugar}|"></p>
<p th:text="|Género: ${datos.sexo}|"></p>

<form method="post" th:action="@{/procesar}" th:object="${datos}">
    <button type="submit" name="contador" th:value="${contador - 1}">Volver atrás</button>
    <button type="submit" name="contador" value="0">Volver al inicio</button>

    <input type="hidden" th:field="*{nombre}">
    <input type="hidden" th:each="aficcion : ${datos.aficciones}"
           name="aficciones" th:value="${aficcion}">
    <input type="hidden" th:field="*{lugar}">
    <input type="hidden" th:field="*{sexo}">
</form>
</body>
</html>
```

La captura muestra el resultado final:

![Resumen final de los datos](img%20-%20documents/D3-UD2.5.png)

<a id="pojo-final"></a>

### El POJO definitivo

Queda recogido arriba, en la sección del modelo de datos: cuatro propiedades (`nombre`, `aficciones`, `lugar`, `sexo`), la lista inicializada a `new ArrayList<>()` para que los `th:each` sobre una lista vacía no fallen, y `@Data` de Lombok para el resto.

<a id="tests"></a>

## La suite de pruebas del flujo completo

Para rematar la práctica (y poder tocar el controlador sin miedo) escribí `FlujoFormularioTest`: ocho pruebas con **MockMvc** que simulan las peticiones HTTP sin levantar navegador. Dos ejemplos representativos:

```java
@SpringBootTest
@AutoConfigureMockMvc
class FlujoFormularioTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void avanzaDelPasoUnoAlDosConservandoElNombre() throws Exception {
        mockMvc.perform(post("/procesar")
                        .param("nombre", "Ruvik")
                        .param("contador", "1"))
                .andExpect(status().isOk())
                .andExpect(view().name("Formulario2"))
                .andExpect(model().attribute("contador", 1))
                .andExpect(model().attribute("datos", hasProperty("nombre", is("Ruvik"))));
    }

    @Test
    void elBotonVolverDelPasoDosRegresaAlUnoSinPerderElNombre() throws Exception {
        mockMvc.perform(post("/procesar")
                        .param("nombre", "Ruvik")
                        .param("contador", "-1"))
                .andExpect(status().isOk())
                .andExpect(view().name("Formulario1"))
                .andExpect(model().attribute("datos", hasProperty("nombre", is("Ruvik"))));
    }
}
```

El resto de la suite cubre: la redirección de la raíz, el render del primer paso, los avances 2→3 y 3→4 (comprobando que las aficiones y el lugar **siguen en el modelo**), el resultado final con todos los datos, y el "volver al inicio". Son precisamente los casos que fallaban con el contador `static` y con la pérdida de datos, así que la suite es la prueba de que ambas correcciones funcionan.

<a id="resumen"></a>

## Resumen de conceptos

| Elemento | Qué hace |
|---|---|
| `@ModelAttribute("datos")` | Enlaza los campos enviados con el objeto `TusDatos`, con clave fija `datos` |
| `@RequestParam("contador")` | Lee el paso enviado por el botón pulsado |
| `th:object="${datos}"` | Vincula el formulario con el objeto del modelo |
| `th:field="*{propiedad}"` | Vincula un control con una propiedad (campos visibles y ocultos) |
| `th:each` | Itera la colección y repite el elemento (lista de aficiones, campos ocultos múltiples) |
| `<input type="hidden">` | Reenvía valores previos que no aparecen como controles editables en el paso actual |
| `name="contador"` en un `<button>` | El botón de envío aporta su `value` como parámetro de la petición |
| `redirect:` | Redirección HTTP en vez de render (para reiniciar con un GET limpio) |
| `@Data` (Lombok) | Genera getters, setters, `toString`, `equals` y `hashCode` en compilación |
| `switch` (Java 21) | Expresión que devuelve el nombre de la vista según el paso |
| `MockMvc` | Simula peticiones HTTP en los tests sin levantar servidor ni navegador |

Ideas clave que me llevo de la práctica:

- **HTTP no guarda estado**: todo lo que el siguiente paso necesita debe viajar en su petición; de ahí los campos ocultos.
- Una variable `static` en el controlador **se comparte entre todos los usuarios**; el paso correcto es que cada petición traiga el suyo.
- Un botón `<button name="contador" value="2">` **es un parámetro más** de la petición; es la forma barata de que cada botón diga qué quiere.
- Para conservar una colección en un formulario se necesita **un campo oculto por elemento**, generado con `th:each`.
- Los campos ocultos son editables desde el navegador: jamás confiar en ellos para datos sensibles.
- "Volver atrás" puede renderizar la vista con los datos (no perderlos); "empezar de nuevo" conviene que redirija (GET limpio).

<a id="repaso"></a>

## Preguntas de repaso

1. ¿Por qué se pierden los datos de los pasos anteriores si cada formulario solo envía su campo visible? *(El problema de fondo)*
2. ¿Qué tres estrategias existen para mantener el estado entre peticiones y cuál usa esta práctica? *(El problema de fondo)*
3. ¿Cómo contribuye un `<button name="contador" value="1">` a la petición POST? *(Primera versión)*
4. ¿Por qué es incorrecto guardar el paso actual en una variable `static` del controlador? *(Primera lógica)*
5. ¿Qué genera la anotación `@Data` de Lombok y qué dos líneas necesita en `build.gradle`? *(El modelo de datos)*
6. ¿Cómo se conservan una propiedad simple y una lista cuando el paso actual no las muestra? *(Solución)*
7. ¿Qué riesgos tiene confiar en los valores de los campos ocultos? *(Solución)*
8. ¿Qué significa que el flujo de la segunda versión sea "sin estado"? ¿De dónde sale el paso en cada petición? *(Segunda versión)*
9. ¿Qué diferencia hay entre `case -1` (render) y `case 0` (`redirect`) en el controlador final? ¿Por qué uno redirige y el otro no? *(Versión final)*
10. ¿Para qué sirve `@ModelAttribute("datos")` con nombre explícito y qué habría pasado sin él? *(Versión final)*
11. ¿Qué ventaja aporta la expresión `switch` de Java 21 frente a la cadena de `if`? ¿Qué ocurre en `default`? *(Versión final)*
12. ¿Qué es MockMvc y qué dos detalles del flujo vienen a certificar la suite de pruebas? *(La suite de pruebas)*

<a id="conclusion"></a>

## Conclusión

Esta práctica me hizo tocar con las manos lo que hasta entonces había leído: que HTTP no recuerda nada y que todo lo que quieres conservar **tiene que viajar**. El fallo de los datos perdidos al volver atrás me costó un buen rato (y una búsqueda en Stack Overflow) hasta ver que la solución no era código nuevo en el controlador, sino reenviar lo que ya tenía en los formularios.

También me quedo con dos correcciones de diseño que nacieron de errores reales: el contador `static` compartido entre usuarios (sustituido por el valor de cada petición) y la utilidad de distinguir *render* de *redirect* según convenga conservar o descartar los datos.

Con D1 (respuestas directas), D2 (plantillas y objetos) y esta (estado entre pasos), el recorrido de la unidad queda casi cerrado; D4 vuelve al lado del protocolo con la codificación de parámetros y la internacionalización.

<a id="recursos"></a>

## Recursos

- [Repositorio del proyecto en GitHub](https://github.com/KerinR432/DWES2)
- [Documentación de Thymeleaf](https://www.thymeleaf.org/documentation.html)
- [Proyecto Lombok](https://projectlombok.org/features/Data)
- [Documentación de Spring Testing (MockMvc)](https://docs.spring.io/spring-framework/reference/testing/webtestclient.html)
- Stack Overflow, en concreto para el problema de la pérdida de datos al navegar hacia atrás
- Gemini, como apoyo para interpretar los mensajes de error

<div class="endmark">
FIN DEL REGISTRO DE NAVEGACIÓN // D3 · UD2
</div>
