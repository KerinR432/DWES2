# DÍA DOCE — `redirect`, PRG Y `@ModelAttribute` FRENTE A `@RequestParam`

## Índice

1. [Resumen de la sesión](#resumen-de-la-sesión)
2. [`redirect:`: qué hace exactamente](#redirect-qué-hace-exactamente)
3. [Forward frente a redirect](#forward-frente-a-redirect)
4. [El patrón Post/Redirect/Get (PRG)](#el-patrón-postredirectget-prg)
5. [Qué pasa con los datos tras un redirect](#qué-pasa-con-los-datos-tras-un-redirect)
6. [Cómo conservar los datos](#cómo-conservar-los-datos)
7. [Ejemplo real: D3-UD2](#ejemplo-real-d3-ud2)
8. [`@ModelAttribute` frente a `@RequestParam`](#modelattribute-frente-a-requestparam)
9. [La práctica `PracticandoFormulario`](#la-práctica-practicandoformulario)
10. [Errores y detalles detectados](#errores-y-detalles-detectados)
11. [Comparación con las bitácoras anteriores](#comparación-con-las-bitácoras-anteriores)
12. [Chuleta de código](#chuleta-de-código)
13. [Pendientes y preguntas](#pendientes-y-preguntas)

---

## Resumen de la sesión

El día 12 es una sesión corta en apuntes, pero muy importante para cerrar el flujo de un formulario. La libreta original decía, literalmente:

> «"redirect" lo que hace es reenvar a una pagina, pero si enviar información. Tener en cuenta esto»
>
> «`@ModelAddatribute` es mejor que `@RequestParam`»

Las dos ideas son correctas en el fondo, pero necesitan matices:

- **`redirect:`** no «reenvía a una página» exactamente: devuelve una respuesta **302** con una cabecera `Location`, y es el **navegador** el que hace una **nueva petición GET**. Por eso el `Model` de la petición anterior **no llega** al destino.
- La frase «pero sin enviar información» es una **simplificación**: no se envía el cuerpo ni el `Model`, pero sí pueden viajar **parámetros de consulta**, **cookies** o **datos de sesión**.
- **`@ModelAttribute` no siempre es «mejor»** que `@RequestParam`: es mejor **cuando los datos forman un objeto**. Para un valor suelto —por ejemplo, un contador— `@RequestParam` sigue siendo lo correcto.

Lo que vimos:

- Qué hace `return "redirect:/ruta"` y en qué se diferencia de `return "ruta"`.
- El patrón **Post/Redirect/Get (PRG)** y por qué evita el doble envío al recargar.
- Por qué el `Model` se pierde tras un redirect.
- Cómo conservar datos con **flash attributes**, **query params**, **sesión** o **persistencia**.
- El ejemplo real de `D3-UD2`: redirect para **empezar de nuevo**, forward para **conservar los datos**.
- `@ModelAttribute` y `@RequestParam` usados **juntos** en el mismo controlador.
- El estado real de `PracticandoFormulario`, que todavía es un esqueleto.

> 💡 **Idea clave del día:** un redirect **cambia de petición**. Si el dato tiene que sobrevivir, hay que decírselo a Spring de forma explícita: flash, query string, sesión o base de datos.

---

## `redirect:`: qué hace exactamente

Cuando un controlador devuelve un `String` que empieza por `redirect:`, Spring no busca una plantilla con ese nombre. Construye una respuesta de redirección:

```java
@PostMapping("/formulario")
public String procesar(...) {
    return "redirect:/resultado";
}
```

La respuesta HTTP es parecida a esta:

```http
HTTP/1.1 302 Found
Location: /resultado
```

El navegador, al recibirla, hace **una petición nueva**:

```text
POST /formulario
        │
        ▼
Controlador procesa y responde 302
        │
        ▼
Navegador recibe Location: /resultado
        │
        ▼
GET /resultado          ← petición nueva, no la anterior
        │
        ▼
Controlador de resultado + plantilla
```

### Lo que NO es un redirect

| Idea | Realidad |
| --- | --- |
| «El servidor pinta la página de resultado» | El servidor solo dice **a dónde ir**; el navegador vuelve a pedir |
| «La URL no cambia» | La URL **sí cambia** a la del destino |
| «El `Model` viaja al destino» | El `Model` pertenece a la petición anterior; **no viaja** |
| «Es lo mismo que `forward:`» | No: `forward:` es interno y conserva la petición |

> ⚠️ **Corrección de la libreta:** «reenviar a una página» se entiende, pero técnicamente es **responder con una redirección** para que el cliente haga otra petición. Esa diferencia es la que explica por qué se pierden los datos.

### `redirect:` con barra y sin barra

```java
return "redirect:/resultado";   // absoluto desde la raíz de la aplicación
return "redirect:resultado";    // relativo a la ruta actual
```

En Spring, `redirect:/resultado` incluye el **context path** de la aplicación. Es la forma recomendada para no romper el enlace si la app se despliega en `/mi-app`.

---

## Forward frente a redirect

Spring también permite `forward:`, que **no** es un redirect:

```java
return "forward:/resultado";
```

| Aspecto | `return "resultado"` | `return "forward:/resultado"` | `return "redirect:/resultado"` |
| --- | --- | --- | --- |
| Qué ocurre | Se renderiza la vista `resultado` | Se reenvía internamente al handler/ruta | Se responde 302 y el navegador hace otro GET |
| Peticiones HTTP | 1 | 1 | 2 |
| ¿Cambia la URL? | No | No | Sí |
| ¿Se conserva el `Model`? | Sí | Sí | No (salvo flash/query/sesión) |
| ¿Se conserva el método HTTP? | Sí | Sí | No: el nuevo GET es GET |
| Uso típico | Mostrar una vista | Pasar a otro controlador sin cambiar la URL | Cerrar un POST con PRG |

```text
FORWARD                          REDIRECT
Cliente                          Cliente
   │ POST /a                        │ POST /a
   ▼                                ▼
Servidor                            Servidor → 302 Location: /b
   │ forward interno                │
   ▼                                ▼
 /b (misma petición)             Cliente → GET /b
   │                                │
   ▼                                ▼
 Respuesta                       Respuesta
```

> 🧠 **Regla práctica:** si necesitas que el navegador **recuerde** una URL nueva y que recargar no reenvíe el formulario, usa `redirect:`. Si solo quieres cambiar de vista sin perder el `Model`, usa `forward:` o devuelve el nombre de la vista.

---

## El patrón Post/Redirect/Get (PRG)

El problema clásico: un formulario se envía por `POST` y el controlador devuelve directamente la vista de resultado.

```java
@PostMapping("/formulario")
public String procesar(@ModelAttribute Datos datos) {
    return "resultado";   // ⚠️ el navegador sigue en un POST
}
```

Si el usuario recarga la página de resultado, el navegador **reenvía el POST**. Eso puede duplicar un pedido, un pago o un registro.

La solución es **PRG**:

```text
POST /formulario  ──►  procesa  ──►  302 Location: /resultado
                                          │
                                          ▼
                                   GET /resultado  ──►  200 HTML
```

Ahora la última petición es un **GET**. Recargar solo repite el GET, que es seguro e idempotente.

| Sin PRG | Con PRG |
| --- | --- |
| `POST` → vista | `POST` → `302` → `GET` |
| Recargar reenvía el formulario | Recargar solo vuelve a pedir el resultado |
| Riesgo de doble envío | Sin doble envío |
| URL final puede ser la del POST | URL final es la del GET |

> 🔗 Esto es exactamente lo que se aplica en el [día 13](bitacora-dia-trece.md) con el carrito: `POST /agregar/{id}` termina en `redirect:/tienda/carrito`.

---

## Qué pasa con los datos tras un redirect

El `Model` es un objeto que vive **durante una petición**. Al hacer redirect, la petición termina y el `Model` desaparece. La nueva petición crea un `Model` nuevo y vacío.

```text
Petición 1 (POST)                 Petición 2 (GET)
┌─────────────────────┐          ┌─────────────────────┐
│ Model: datos=Ruvik  │          │ Model: (vacío)      │
└─────────────────────┘          └─────────────────────┘
          │                                 ▲
          └──── 302 ────► navegador ────────┘
```

Por eso esto **no funciona** como se espera:

```java
@PostMapping("/formulario")
public String procesar(@ModelAttribute Datos datos, Model modelo) {
    modelo.addAttribute("datos", datos);
    return "redirect:/resultado";   // ⚠️ "datos" no llega
}
```

La plantilla `resultado.html` buscará `${datos}` y no lo encontrará.

### El matiz de Spring

Spring, a través de `RedirectView`, puede añadir **atributos simples** del `Model` como **parámetros de consulta** en la URL. Pero un objeto complejo como `Datos` **no se convierte** en un query param utilizable. Por eso, para objetos, la solución no es confiar en el `Model`: hay que usar flash attributes, sesión o persistencia.

> ⚠️ **No confundas «no viaja el Model» con «no viaja nada».** Pueden viajar parámetros de consulta, cookies y la sesión. Lo que no viaja es el objeto `Model` de la petición anterior.

---

## Cómo conservar los datos

### Opción A: flash attributes (la más limpia para un redirect)

`RedirectAttributes` permite guardar un atributo **temporal** que sobrevive **exactamente un redirect**:

```java
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@PostMapping("/formulario")
public String procesar(
        @ModelAttribute("datos") Datos datos,
        RedirectAttributes flash) {

    flash.addFlashAttribute("datos", datos);
    return "redirect:/resultado";
}

@GetMapping("/resultado")
public String resultado() {
    return "resultado";   // ${datos} está disponible gracias al flash
}
```

```html
<!-- resultado.html -->
<p th:text="|Nombre: ${datos.nombre}|"></p>
```

| Método | Qué hace | ¿Dónde se ve? |
| --- | --- | --- |
| `flash.addFlashAttribute("datos", datos)` | Guarda el objeto para la **siguiente** petición | En el `Model`, no en la URL |
| `flash.addAttribute("id", 7)` | Añade un **query param** | En la URL: `/resultado?id=7` |

Los flash attributes se guardan en la **sesión** de forma temporal. Si el usuario bloquea las cookies, el flash puede no funcionar. Es la antesala de lo que se ve en el [día 13](bitacora-dia-trece.md).

### Opción B: parámetros de consulta

```java
@PostMapping("/formulario")
public String procesar(@ModelAttribute Datos datos, RedirectAttributes redirect) {
    redirect.addAttribute("nombre", datos.getNombre());
    return "redirect:/resultado";
}
```

Genera:

```text
/resultado?nombre=Ruvik
```

| Ventaja | Inconveniente |
| --- | --- |
| Sencillo y visible | Todo queda en la URL y en el historial |
| Se puede compartir el enlace | No sirve para objetos grandes |
| No necesita sesión | No apto para datos sensibles |

### Opción C: sesión

```java
@PostMapping("/formulario")
public String procesar(@ModelAttribute Datos datos, HttpSession session) {
    session.setAttribute("datos", datos);
    return "redirect:/resultado";
}
```

El dato vive en el servidor hasta que caduque la sesión o se borre. Es lo que se desarrolla en el [día 13](bitacora-dia-trece.md).

### Opción D: persistencia

Guardar en base de datos y redirigir con un identificador:

```java
return "redirect:/resultado/" + guardado.getId();
```

Es la solución real para un proyecto grande: el dato no depende de la memoria del servidor ni de la sesión.

### Opción E: campos `hidden` (para pasos, no para redirect)

En formularios encadenados, los datos se reenvían con campos ocultos **mientras se usa forward**:

```html
<input type="hidden" th:field="*{nombre}">
<input type="hidden" th:each="aficcion : ${datos.aficciones}"
       name="aficciones" th:value="${aficcion}">
```

Eso funciona en `D3-UD2` porque los pasos intermedios **no hacen redirect**: devuelven la vista directamente y el `Model` sigue vivo.

| Mecanismo | Sobrevive al redirect | Ideal para |
| --- | --- | --- |
| Flash attribute | ✅ Un redirect | Objetos pequeños/medianos |
| Query param | ✅ Sí | Un id o un valor simple |
| Sesión | ✅ Hasta caducar | Estado por usuario |
| Base de datos | ✅ Permanente | Datos reales |
| Campo `hidden` | ❌ No por sí solo | Formularios encadenados con forward |

---

## Ejemplo real: D3-UD2

El proyecto `PROYECTOS/D3-UD2` implementa un formulario de cuatro pasos con `@ModelAttribute`, `@RequestParam` y `redirect:`. Su controlador es la mejor ilustración de cuándo se usa cada cosa:

```java
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

### La decisión clave: redirect solo para empezar de nuevo

| `contador` | `return` | Tipo | Por qué |
| --- | --- | --- | --- |
| `-1` | `"Formulario1"` | Forward | Volver atrás **conservando** los datos |
| `0` | `"redirect:/formulario1"` | Redirect | Empezar de nuevo y **descartar** el objeto |
| `1` | `"Formulario2"` | Forward | Siguiente paso con el mismo `Model` |
| `2` | `"Formulario3"` | Forward | Siguiente paso con el mismo `Model` |
| `3` | `"Formulario4"` | Forward | Siguiente paso con el mismo `Model` |
| `4` | `"Resultado"` | Forward | Mostrar el resumen con los datos |
| otro | `"redirect:/formulario1"` | Redirect | Valor inválido: volver al inicio limpio |

Esto demuestra que **redirect y forward no son intercambiables**:

- Cuando hay que **conservar** el objeto entre pasos, se devuelve la vista (`forward` implícito).
- Cuando hay que **resetear** el flujo, se usa `redirect:` para que la nueva petición empiece sin el `Model` anterior.

### Los campos ocultos que sostienen el flujo

```html
<form method="post" th:action="@{/procesar}" th:object="${datos}">
    <button type="submit" name="contador" th:value="${contador + 1}">Siguiente</button>
    <button type="submit" name="contador" value="-1">Volver atrás</button>

    <input type="hidden" th:field="*{nombre}">
    <input type="hidden" th:each="aficcion : ${datos.aficciones}"
           name="aficciones" th:value="${aficcion}">
</form>
```

Los campos ocultos reenvían lo que no se ve en el paso actual. No son una solución de redirect: son la forma de **arrastrar** datos entre forwards.

> ⚠️ Los campos ocultos los puede modificar el usuario. No sirven para datos sensibles ni para confiar en el servidor. Ese problema lo resuelve la sesión del [día 13](bitacora-dia-trece.md).

---

## `@ModelAttribute` frente a `@RequestParam`

La libreta decía que `@ModelAttribute` es mejor que `@RequestParam`. Es cierto **en su contexto**, pero no en términos absolutos. En `D3-UD2` se usan **los dos a la vez**:

```java
public String procesarDatos(
        @ModelAttribute("datos") TusDatos datos,   // objeto completo
        @RequestParam("contador") Integer contador, // un valor de control
        Model modelo) { ... }
```

| Aspecto | `@RequestParam` | `@ModelAttribute` |
| --- | --- | --- |
| Qué enlaza | **Un** parámetro | **Muchos** parámetros → campos de un objeto |
| Tipo | `String`, `int`, `Integer`… | Un POJO |
| Necesita constructor vacío | No | Sí |
| Necesita setters | No | Sí |
| Añade al `Model` | No | Sí, automáticamente |
| Nombre por defecto | El del parámetro | El del **tipo** |
| Ideal para | Un id, un contador, un filtro | Un formulario con varios campos |

### La corrección importante

`@ModelAttribute` es mejor **cuando los datos forman un objeto**. Para un único valor suelto, `@RequestParam` es más directo y no obliga a crear una clase.

```java
// Un solo valor: @RequestParam
@GetMapping("/saludo")
public String saludo(@RequestParam(defaultValue = "mundo") String nombre, Model modelo) {
    modelo.addAttribute("mensaje", nombre);
    return "hola";
}
```

```java
// Varios valores: @ModelAttribute
@PostMapping("/formulario")
public String procesar(@ModelAttribute("datos") Datos datos) {
    return "resultado";
}
```

> 🧠 **No es «uno mejor que otro»: es «cada uno para lo que sirve».** La frase de la libreta se queda corta; el matiz es el que importa.

### El nombre del objeto vuelve a aparecer

`@ModelAttribute("datos")` fija la clave `datos` en el `Model`. Sin nombre, Spring la derivaría del tipo:

```text
@ModelAttribute Datos datos          → clave "datos"
@ModelAttribute DatosFormulario d    → clave "datosFormulario"
@ModelAttribute("datos") DatosFormulario d → clave "datos"
```

Por eso, si la plantilla usa `th:object="${datos}"`, hay que escribir `@ModelAttribute("datos")` o registrar el objeto con `model.addAttribute("datos", ...)`. Es la misma regla del [día 11](bitacora-dia-once.md).

---

## La práctica `PracticandoFormulario`

El proyecto `PROYECTOS/PracticandoFormulario` es el que se estaba usando para practicar formularios. Ahora mismo es un **esqueleto**: permite ver el formulario, pero **no enviarlo**. Su controlador solo tiene un `GET`:

```java
@Controller
public class ControllerFormulario {

    @GetMapping("/")
    public String mostrarFormulario() {
        return "formulario";
    }
}
```

Y la plantilla envía a una ruta que no existe:

```html
<form method="POST" action="/formulario" enctype="multipart/form-data">
    <label for="nombre">Nombre:</label>
    <input type="text" name="nombre">

    <label for="apellido">Apellido:</label>
    <input type="text" name="apellido">

    <label for="capitulo">¿A qué capítulo perteneces?</label>
    <input type="text" name="capitulo">

    <label for="cantidadHermanos"></label>
    <input type="text" name="cantidadHermanos">
</form>
```

### Qué falla

| Problema | Consecuencia |
| --- | --- |
| No hay `@PostMapping("/formulario")` | Al enviar se produce un **404** |
| No hay objeto de datos | Spring no tiene dónde enlazar los campos |
| No hay `th:object` ni `th:field` | Los valores no se conservan si hay errores |
| No hay botón `submit` | El usuario no puede enviar |
| `enctype="multipart/form-data"` | Innecesario: solo hay texto |
| `action="/formulario"` escrito a mano | Se rompe si hay *context path* |
| No hay vista de resultado | No se muestra nada después de enviar |
| No hay `redirect:` | Recargar reenviaría el `POST` |

> 📌 **Nota:** la revisión completa está en `PROYECTOS/PracticandoFormulario/ANALISIS.md`. Aquí se resume lo que afecta al día 12: sin `POST`, sin objeto y sin redirect, el flujo no se puede cerrar.

### Cómo quedaría el flujo completo

**1. El DTO**

```java
package ruvik.practicandoformulario;

public class DatosFormulario {
    private String nombre;
    private String apellido;
    private String capitulo;
    private Integer cantidadHermanos;

    // getters y setters (o @Data de Lombok)
}
```

**2. El controlador con PRG**

> En el ejemplo se renombra la clase a `FormularioController` por convención. El nombre de la clase no afecta al funcionamiento; lo importante son las anotaciones y las rutas.

```java
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
public class FormularioController {

    @GetMapping("/")
    public String mostrarFormulario(Model modelo) {
        modelo.addAttribute("datos", new DatosFormulario());
        return "formulario";
    }

    @PostMapping("/formulario")
    public String procesar(
            @ModelAttribute("datos") DatosFormulario datos,
            RedirectAttributes flash) {

        flash.addFlashAttribute("datos", datos);
        return "redirect:/resultado";
    }

    @GetMapping("/resultado")
    public String resultado() {
        return "resultado";
    }
}
```

**3. El formulario enlazado**

```html
<form th:action="@{/formulario}" th:object="${datos}" method="post">
    <label for="nombre">Nombre:</label>
    <input id="nombre" type="text" th:field="*{nombre}">

    <label for="apellido">Apellido:</label>
    <input id="apellido" type="text" th:field="*{apellido}">

    <label for="capitulo">¿A qué capítulo perteneces?</label>
    <input id="capitulo" type="text" th:field="*{capitulo}">

    <label for="cantidadHermanos">Cantidad de hermanos:</label>
    <input id="cantidadHermanos" type="number" min="0" th:field="*{cantidadHermanos}">

    <button type="submit">Enviar</button>
</form>
```

**4. El resultado**

```html
<p th:text="|Nombre: ${datos.nombre}|"></p>
<p th:text="|Apellido: ${datos.apellido}|"></p>
<p th:text="|Capítulo: ${datos.capitulo}|"></p>
<p th:text="|Hermanos: ${datos.cantidadHermanos}|"></p>
```

### El flujo, paso a paso

```text
GET /                  → formulario con "datos" vacío
        │
        ▼
POST /formulario       → @ModelAttribute("datos") rellena el objeto
        │
        ▼
flash.addFlashAttribute("datos", datos)
        │
        ▼
302 Location: /resultado
        │
        ▼
GET /resultado         → ${datos} llega desde el flash
        │
        ▼
HTML con los datos
```

Si se recarga `/resultado`, solo se repite el `GET`. El `POST` no se reenvía. Ese es el beneficio de PRG.

---

## Errores y detalles detectados

### 1. «pero si enviar información» → **«pero sin enviar información»**

Falta la `n`. La idea es que el redirect **no transporta** el `Model` ni el cuerpo de la petición anterior.

### 2. `@ModelAddatribute` → **`@ModelAttribute`**

Dos correcciones: `Add` sobra y falta una `t`. La anotación correcta es `@ModelAttribute`.

### 3. Un redirect no es «reenviar a una página»

Técnicamente es una respuesta **302** con `Location`; el **navegador** hace una petición nueva. Esa es la causa de que el `Model` se pierda.

### 4. «No envía información» es una simplificación

No viaja el `Model` ni el cuerpo, pero sí pueden viajar:

- parámetros de consulta (`/resultado?nombre=Ruvik`),
- cookies (`JSESSIONID`),
- datos de sesión,
- flash attributes (que usan la sesión por debajo).

### 5. El `Model` no sobrevive al redirect

```java
modelo.addAttribute("datos", datos);
return "redirect:/resultado";   // ⚠️ "datos" no llega
```

Para objetos, usa `RedirectAttributes.addFlashAttribute`, sesión o base de datos.

### 6. `@ModelAttribute` no es siempre mejor que `@RequestParam`

Es mejor **para objetos**. Para un valor suelto, `@RequestParam` es más directo. En `D3-UD2` se usan juntos: `@ModelAttribute("datos")` para el objeto y `@RequestParam("contador")` para el paso.

### 7. `PracticandoFormulario` devuelve 404 al enviar

El formulario hace `POST /formulario`, pero el controlador solo tiene `@GetMapping("/")`. No hay ningún mapeo para `/formulario`.

### 8. `PracticandoFormulario` no tiene botón de envío

Sin `<button type="submit">` ni `<input type="submit">`, el usuario no puede enviar el formulario de forma evidente.

### 9. `multipart/form-data` sobra

Solo se usa para subir archivos. Para texto, el valor por defecto `application/x-www-form-urlencoded` es el correcto.

### 10. Sin `th:object` ni `th:field` no se conservan los datos

Si el formulario falla y se vuelve a mostrar, los campos aparecen vacíos. Thymeleaf puede rellenarlos automáticamente si están enlazados al objeto.

### 11. `action="/formulario"` escrito a mano

Funciona en la raíz, pero se rompe con un *context path*. Lo correcto es `th:action="@{/formulario}"`.

### 12. El nombre del objeto debe coincidir con `th:object`

Si usas `@ModelAttribute("datos")`, la plantilla debe usar `${datos}`. Si usas `@ModelAttribute DatosFormulario datos`, la clave por defecto sería `datosFormulario`, no `datos`.

### 13. Sin redirect, recargar reenvía el POST

Es el problema que resuelve PRG. Si el `POST` devuelve directamente la vista de resultado, el navegador mantiene el método y al recargar lo repite.

### 14. Un redirect a `/resultado` no garantiza que exista el `GET`

Si no hay un `@GetMapping("/resultado")`, el redirect termina en **404**. La redirección y el destino son dos piezas que deben existir.

---

## Comparación con las bitácoras anteriores

### Línea temporal

| Día | Qué se aprendió | Proyecto |
| --- | --- | --- |
| **7** | Primer endpoint `GET`, formulario `POST`, `@RequestParam` | `demo` |
| **9** | Repaso D1-UD2, JAR, puerto 80 y teoría MVC | — |
| **10** | `@Controller`, plantillas Thymeleaf, `Model`, `AtomicInteger` | `contadorVisita`, `HolaMundoConPlantilla` |
| **11** | Lombok (`@Data`), `@ModelAttribute` y el nombre del objeto | `demoFormulario` |
| **12** | `redirect`, PRG y `@ModelAttribute` vs `@RequestParam` | `PracticandoFormulario`, `D3-UD2` |
| **13** | HTTP sin estado, cookies, sesiones, `HttpSession`, carrito | `Carrito-compra-gemini` |

### Qué aporta cada día a lo de hoy

```text
Día 7   GET/POST + formularios  ──►  saber enviar datos
   │
Día 10  Model + Thymeleaf       ──►  saber mostrarlos
   │
Día 11  @ModelAttribute         ──►  saber enlazarlos a un objeto
   │
Día 12  redirect + PRG          ──►  cerrar el flujo sin reenviar
   │
Día 13  HttpSession             ──►  recordar el estado entre peticiones
```

### Antes y después del día 12

| Aspecto | Día 11 | Día 12 |
| --- | --- | --- |
| Flujo | `GET` formulario + `POST` resultado directo | `POST` → `302` → `GET` resultado |
| Datos | `@ModelAttribute` en la misma petición | Hay que decidir cómo cruzar el redirect |
| `Model` | Disponible en la vista | Se pierde salvo flash/query/sesión |
| URL | No cambia | Cambia a la del destino |
| Recarga | Reenvía el `POST` | Repite el `GET` |
| `@RequestParam` | Sustituido por `@ModelAttribute` | Se usa para valores de control (`contador`) |
| Proyecto | `demoFormulario` | `PracticandoFormulario`, `D3-UD2` |

### Lo que se mantiene

- **`@Controller`** sigue eligiendo la vista.
- **`Model`** sigue llevando datos del controlador a la plantilla.
- **Thymeleaf** sigue renderizando el HTML.
- **`@GetMapping` / `@PostMapping`** siguen mapeando las rutas.
- **`@ModelAttribute`** sigue siendo la forma de enlazar un objeto.

### Lo que cambia de verdad

1. **El flujo deja de ser una sola petición** y pasa a ser `POST` + `GET`.
2. **El `Model` ya no es suficiente** para llevar datos al resultado.
3. **Aparecen los flash attributes** como puente temporal entre peticiones.
4. **El patrón PRG** evita el doble envío al recargar.
5. **Se elige entre redirect y forward** según se quiera conservar o descartar el estado.

> 🧠 **Conclusión:** el día 12 no añade una anotación nueva, sino **control sobre el flujo**. Un formulario no termina cuando el controlador recibe los datos: termina cuando el usuario puede recargar sin miedo y ver el resultado sin reenviar nada. `redirect:` + PRG es la forma de cerrarlo bien.

---

## Chuleta de código

```java
// Redirect simple (PRG)
@PostMapping("/formulario")
public String procesar(...) {
    return "redirect:/resultado";
}
```

```java
// Forward: misma petición, conserva el Model
@PostMapping("/formulario")
public String procesar(...) {
    return "forward:/resultado";
}
```

```java
// Flash attributes: el objeto sobrevive un redirect
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@PostMapping("/formulario")
public String procesar(
        @ModelAttribute("datos") Datos datos,
        RedirectAttributes flash) {

    flash.addFlashAttribute("datos", datos);
    return "redirect:/resultado";
}

@GetMapping("/resultado")
public String resultado() {
    return "resultado";   // ${datos} viene del flash
}
```

```java
// Query param en el redirect
redirect.addAttribute("id", datos.getId());
// → /resultado?id=7
```

```java
// Sesión: el dato vive en el servidor
session.setAttribute("datos", datos);
return "redirect:/resultado";
```

```java
// D3-UD2: redirect solo para resetear
return switch (contador) {
    case -1 -> "Formulario1";              // forward: conserva datos
    case 0 -> "redirect:/formulario1";     // redirect: descarta datos
    case 1 -> "Formulario2";
    case 2 -> "Formulario3";
    case 3 -> "Formulario4";
    case 4 -> "Resultado";
    default -> "redirect:/formulario1";
};
```

```html
<!-- Formulario enlazado -->
<form th:action="@{/formulario}" th:object="${datos}" method="post">
    <input type="text" th:field="*{nombre}">
    <button type="submit">Enviar</button>
</form>
```

```text
Reglas rápidas
─────────────────────────────────────────────
return "vista"            → forward implícito, conserva Model
return "forward:/ruta"    → forward explícito, conserva Model
return "redirect:/ruta"   → 302 + nuevo GET, NO conserva Model
flash.addFlashAttribute   → sobrevive un redirect
flash.addAttribute        → query param visible
session.setAttribute      → sobrevive hasta caducar
@ModelAttribute("datos")  → clave "datos" en el Model
@RequestParam("contador") → un valor suelto
```

---

## Pendientes y preguntas

- [ ] Añadir `@PostMapping("/formulario")` a `PracticandoFormulario`.
- [ ] Crear el DTO `DatosFormulario` con `Integer cantidadHermanos`.
- [ ] Añadir el botón `submit` y cambiar `action` por `th:action`.
- [ ] Quitar `enctype="multipart/form-data"` del formulario.
- [ ] Enlazar los campos con `th:object` y `th:field`.
- [ ] Implementar `redirect:/resultado` con `RedirectAttributes.addFlashAttribute`.
- [ ] Crear la vista `resultado.html` y comprobar que `${datos}` llega.
- [ ] Recargar `/resultado` y verificar que **no** se reenvía el `POST`.
- [ ] Comparar el comportamiento de `redirect:` con `forward:` en el mismo formulario.
- [ ] Probar a quitar el flash y comprobar el error de `${datos}`.
- [ ] Revisar `D3-UD2` y explicar por qué `case -1` usa forward y `case 0` usa redirect.
- [ ] Añadir validación con `@Valid` + `BindingResult` y conservar los datos al volver al formulario.
- [ ] Documentar el paso de los datos al [día 13](bitacora-dia-trece.md): sesión y cookies.

---

**Relacionado:** [[bitacora-dia-once]] · [[bitacora-dia-trece]] · [[bitacora-dia-diez]] · [[bitacora-dia-nueve]] · [[bitacora-dia-siete]] · [[bitacpra-dia-seis]]

**Documentación:** `TEORIA/documentanción - profe/D3-UD2.md` · `PROYECTOS/D3-UD2/` · `PROYECTOS/PracticandoFormulario/ANALISIS.md`

**Proyectos:** [[PracticandoFormulario]] · [[D3-UD2]]
