# DÍA ONCE — LOMBOK Y `@ModelAttribute`: OBJETOS EN EL FORMULARIO

## Índice

1. [Resumen de la sesión](#resumen-de-la-sesión)
2. [Contexto: el profesor replica `demoFormulario`](#contexto-el-profesor-replica-demoformulario)
3. [Lombok: `@Data` y adiós al código repetido](#lombok-data-y-adiós-al-código-repetido)
4. [Añadir Lombok a Gradle](#añadir-lombok-a-gradle)
5. [`@ModelAttribute`: qué hace de verdad](#modelattribute-qué-hace-de-verdad)
6. [El nombre por defecto sale del tipo](#el-nombre-por-defecto-sale-del-tipo)
7. [Cómo cambiar el nombre del objeto](#cómo-cambiar-el-nombre-del-objeto)
8. [El formulario Thymeleaf](#el-formulario-thymeleaf)
9. [El flujo completo de una petición](#el-flujo-completo-de-una-petición)
10. [`@ModelAttribute` frente a `@RequestParam`](#modelattribute-frente-a-requestparam)
11. [Errores y detalles detectados](#errores-y-detalles-detectados)
12. [Comparación con las bitácoras anteriores](#comparación-con-las-bitácoras-anteriores)
13. [Chuleta de código](#chuleta-de-código)
14. [Pendientes y preguntas](#pendientes-y-preguntas)

---

## Resumen de la sesión

El día 11 es una sesión de **observación y corrección**. El profesor replica en directo la práctica `demoFormulario`, que ya se había hecho antes, y mientras la reproduce van apareciendo dos temas nuevos:

1. **Lombok**, una librería que genera por nosotros el código repetido de un POJO (getters, setters, `toString`, `equals`, `hashCode`…).
2. **`@ModelAttribute`**, la anotación que convierte los parámetros del formulario en un **objeto Java** y lo deja disponible en la plantilla.

La libreta original de este día era muy corta y contenía varias confusiones. Decía, literalmente:

> «La libreria `@lombook` es una libreria que permite no crear geters y setters `@Data`»
>
> «exite un gran fallo y es que el `@ModelAtribute` aunque si recopila lo que se envia, en la plantilla obligatoriamente es el nombre de la clase. Siempre pilla eso si la clases el **saludo** peta cuando pones **saluditos** entonces si o si **ModelAttribute** automaticamente cosa es **saludo**. E igual pasa con Saludo cualquiercosa funciona, porque es un Objeto.»
>
> «Asi que si queres si o si especificar algo `@Model` es la opción que nos viene mejor»

La intuición de fondo era buena —el nombre del objeto en la plantilla **no** lo decide el nombre de la variable—, pero la explicación tiene tres errores que conviene corregir:

- Se escribe **Lombok**, no `@lombook`.
- Se escribe **`@ModelAttribute`**, no `@ModelAtribute`.
- **`@Model` no es una anotación.** `Model` es una **interfaz** de Spring que se recibe como parámetro. Para cambiar el nombre del objeto se usa `@ModelAttribute("nombre")` o `model.addAttribute("nombre", objeto)`.

Lo que vimos:

- Qué genera exactamente **`@Data`** de Lombok.
- Cómo se añade Lombok en **Gradle** (`compileOnly` + `annotationProcessor`).
- Cómo `@ModelAttribute` rellena un POJO a partir de los campos del formulario.
- Por qué `Saludo` se llama `saludo` en la plantilla y **no** depende de cómo se llame la variable.
- Cómo ponerle un nombre propio al objeto.
- La diferencia entre **`@ModelAttribute`** y **`@RequestParam`**.
- El flujo **GET → formulario → POST → resultado**.

> 💡 **Idea clave del día:** `@ModelAttribute` no «recoge un texto», **rellena un objeto**. Y el nombre con el que ese objeto viaja al `Model` se deriva del **tipo** de la clase, no del nombre del parámetro. Si quieres otro nombre, hay que decirlo explícitamente.

---

## Contexto: el profesor replica `demoFormulario`

La práctica `demoFormulario` ya existía en el repositorio. El profesor la vuelve a hacer en clase para explicar **por qué** funciona, no solo **cómo** se copia. El proyecto tiene tres piezas:

```text
PROYECTOS/demoFormulario/
├── build.gradle
└── src/main/
    ├── java/ruvik/demoformulario/
    │   ├── DemoFormularioApplication.java
    │   ├── Saludo.java
    │   └── ControllerDemoFormulario.java
    └── resources/templates/
        ├── saludos.html
        └── resultado.html
```

| Pieza | Papel en MVC |
| --- | --- |
| `Saludo` | **Modelo**: el POJO que guarda los datos |
| `saludos.html` y `resultado.html` | **Vista**: las plantillas Thymeleaf |
| `ControllerDemoFormulario` | **Controlador**: recibe, enlaza y elige la vista |

El controlador real del repositorio es este:

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

Y el POJO, tal y como está subido al repositorio:

```java
package ruvik.demoformulario;

public class Saludo {
    private long id;
    private String contenido;

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public String getContenido() {
        return contenido;
    }

    public void setContenido(String contenido) {
        this.contenido = contenido;
    }
}
```

> 📌 **Nota importante:** el `demoFormulario` del repositorio **no usa Lombok**: tiene los getters y setters escritos a mano. En la sesión el profesor probablemente los sustituyó por `@Data` para explicar la librería. Aquí se documentan **las dos versiones**, porque son equivalentes.

> 🔗 Esto continúa el [día 10](bitacora-dia-diez.md): allí el `Model` llevaba **valores sueltos** (`mensaje`, `contador`); aquí lleva un **objeto completo** (`saludo`).

---

## Lombok: `@Data` y adiós al código repetido

**Lombok** es una librería de Java que **genera código durante la compilación** a partir de anotaciones. No es magia en tiempo de ejecución: el compilador produce los métodos de verdad dentro del `.class`.

### Qué genera `@Data`

`@Data` es un atajo que agrupa varias anotaciones:

```java
@Data
// equivale a:
@Getter
@Setter
@ToString
@EqualsAndHashCode
@RequiredArgsConstructor
```

| Método | ¿Lo genera `@Data`? | Para qué sirve |
| --- | --- | --- |
| Getters | ✅ Sí | Leer los campos |
| Setters | ✅ Sí (salvo `final`) | Escribir los campos |
| `toString()` | ✅ Sí | Imprimir el objeto legible |
| `equals()` / `hashCode()` | ✅ Sí | Comparar objetos |
| Constructor con campos obligatorios | ✅ Sí | Crear el objeto |
| Constructor sin argumentos | ✅ Sí, si no hay campos `final` ni `@NonNull` | Necesario para el *binding* de Spring |
| Constructor con todos los argumentos | ❌ No | Hay que añadir `@AllArgsConstructor` |

### El mismo `Saludo`, con y sin Lombok

**Sin Lombok** (lo que hay en el repositorio):

```java
public class Saludo {
    private long id;
    private String contenido;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }
    public String getContenido() { return contenido; }
    public void setContenido(String contenido) { this.contenido = contenido; }
}
```

**Con Lombok**:

```java
package ruvik.demoformulario;

import lombok.Data;

@Data
public class Saludo {
    private Long id;
    private String contenido;
}
```

Las dos versiones se comportan igual desde fuera: Spring puede llamar a `setContenido(...)` porque el método existe en el bytecode. La diferencia es que **una se escribe y la otra se genera**.

> ⚠️ En el ejemplo con Lombok he cambiado `long` por `Long`. No es un capricho: un `long` primitivo vale `0` por defecto y no admite `null`, lo que da problemas si el campo del formulario llega vacío. Se explica en [errores y detalles](#errores-y-detalles-detectados).

### Qué NO hace Lombok

| Idea equivocada | Realidad |
| --- | --- |
| «Lombok elimina los getters y setters» | Los **genera** en el `.class`; existen igual |
| «Lombok funciona en tiempo de ejecución» | Trabaja en **compilación**; en el JAR solo quedan los métodos ya generados |
| «`@Data` genera el constructor con todos los argumentos» | No: eso es `@AllArgsConstructor` |
| «`@Data` genera un constructor vacío siempre» | Solo si no hay campos `final` ni `@NonNull`; si añades `@AllArgsConstructor`, desaparece |
| «Lombok es imprescindible» | Es comodidad; el proyecto funciona igual con getters a mano |

### Ejemplo real del repositorio: `TusDatos`

En `PROYECTOS/D3-UD2` sí se usa Lombok:

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

Un POJO de cuatro campos pasa de ~40 líneas a 10. Y como `aficciones` ya está inicializada, el formulario puede añadir elementos sin `NullPointerException`.

### Cómo comprobar que Lombok ha funcionado

Si el IDE marca `getId()` como «no existe» pero Gradle compila, casi siempre es que **el procesador de anotaciones no está activo en el IDE**. Se puede comprobar el bytecode:

```bash
javap -p build/classes/java/main/ruvik/demoformulario/Saludo.class
```

Deberían aparecer `getId`, `setId`, `getContenido`, `setContenido`, `toString`, `equals` y `hashCode` aunque no estén escritos en el fuente.

---

## Añadir Lombok a Gradle

Lombok no se declara como una dependencia normal. Se necesitan **dos** líneas: una para compilar contra ella y otra para que se ejecute el procesador que genera el código.

```groovy
dependencies {
    // ... resto de dependencias

    compileOnly 'org.projectlombok:lombok'
    annotationProcessor 'org.projectlombok:lombok'

    // También en pruebas, si se usan POJOs con Lombok
    testCompileOnly 'org.projectlombok:lombok'
    testAnnotationProcessor 'org.projectlombok:lombok'
}
```

Así está configurado en `PROYECTOS/D3-UD2/build.gradle` y en `PROYECTOS/D4-UD2/build.gradle`.

| Línea | Qué hace | Por qué |
| --- | --- | --- |
| `compileOnly` | Compila usando Lombok | No se empaqueta en el JAR final: solo hacen falta las anotaciones al compilar |
| `annotationProcessor` | Ejecuta el generador de código | Sin esto, las anotaciones no producen métodos |
| `testCompileOnly` | Lombok para el código de test | Los tests también pueden usar `@Data` |
| `testAnnotationProcessor` | Procesador en test | Genera los métodos también al compilar tests |

> ⚠️ **Error típico:** poner solo `implementation 'org.projectlombok:lombok'`. Compila las anotaciones, pero **no genera** los getters/setters, y el proyecto falla al llamarlos.

### Comparación con `demoFormulario`

El `build.gradle` del repositorio **no tiene Lombok**:

```groovy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-thymeleaf'
    implementation 'org.springframework.boot:spring-boot-starter-webmvc'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    testImplementation 'org.springframework.boot:spring-boot-starter-thymeleaf-test'
    testImplementation 'org.springframework.boot:spring-boot-starter-webmvc-test'
    testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
}
```

Si se quisiera usar `@Data` en `Saludo`, habría que añadir las cuatro líneas de Lombok. Mientras no se añadan, **hay que mantener los getters y setters manuales**.

---

## `@ModelAttribute`: qué hace de verdad

`@ModelAttribute` sobre un **parámetro de método** hace tres cosas:

1. **Crea** una instancia del tipo indicado (usando el constructor sin argumentos).
2. **Rellena** sus campos con los parámetros de la petición, llamando a los setters.
3. **Añade** el objeto al `Model` para que la vista pueda usarlo.

```text
POST /saludos
id=7&contenido=Hola
        │
        ▼
@ModelAttribute Saludo saludo
        │
        ├── new Saludo()
        ├── setId(7)
        ├── setContenido("Hola")
        └── model.addAttribute("saludo", saludo)
        │
        ▼
return "resultado"
```

### Lo que nos ahorra

Sin `@ModelAttribute`, el mismo POST habría que escribirlo así:

```java
@PostMapping("/saludos")
public String saludosEnviado(
        @RequestParam long id,
        @RequestParam String contenido,
        Model modelo) {

    Saludo saludo = new Saludo();
    saludo.setId(id);
    saludo.setContenido(contenido);
    modelo.addAttribute("saludo", saludo);

    return "resultado";
}
```

| Sin `@ModelAttribute` | Con `@ModelAttribute` |
| --- | --- |
| Un `@RequestParam` por campo | Una sola anotación |
| `new` + un `set` por campo | Spring lo hace solo |
| `addAttribute` manual | Se añade automáticamente |
| Crece con cada campo nuevo | No cambia al añadir campos |

> 💡 Por eso el [día 12](bitacora-dia-doce.md) concluye que `@ModelAttribute` es mejor que `@RequestParam` **cuando los datos forman un objeto**. Para un único valor suelto, `@RequestParam` sigue siendo perfectamente válido.

### El objeto ya está en el `Model`

En el POST del repositorio aparece:

```java
modelo.addAttribute("saludo", saludo);
```

Esa línea es **redundante**: `@ModelAttribute` ya añadió el objeto con la clave `"saludo"`. No rompe nada, pero conviene saber que se puede omitir:

```java
@PostMapping("/saludos")
public String saludosEnviado(@ModelAttribute Saludo saludo) {
    return "resultado";   // "saludo" ya está en el Model
}
```

> ⚠️ Si se usa `@ModelAttribute("saluditos")`, el objeto se añade como `saluditos`. Añadir entonces `modelo.addAttribute("saludo", saludo)` crearía **dos claves distintas** para el mismo objeto. Hay que ser coherente.

---

## El nombre por defecto sale del tipo

Esta es la parte que en la libreta original se intuía pero se explicaba mal.

Cuando no se indica nombre, Spring genera la clave del `Model` a partir del **tipo** del parámetro:

```text
Saludo  →  "saludo"
```

No importa cómo se llame la variable:

```java
public String saludosEnviado(@ModelAttribute Saludo saludo)     // clave: "saludo"
public String saludosEnviado(@ModelAttribute Saludo saluditos)  // clave: "saludo"
public String saludosEnviado(@ModelAttribute Saludo loQueSea)   // clave: "saludo"
```

| Método | Clave en el `Model` | ¿Funciona `th:object="${saludo}"`? |
| --- | --- | --- |
| `@ModelAttribute Saludo saludo` | `saludo` | ✅ Sí |
| `@ModelAttribute Saludo saluditos` | `saludo` | ✅ Sí |
| `@ModelAttribute Saludo loQueSea` | `saludo` | ✅ Sí |
| `@ModelAttribute("saluditos") Saludo saludo` | `saluditos` | ❌ No (hay que cambiar la plantilla) |

Por eso la frase «si le pones `saluditos` peta» es correcta **a medias**: lo que falla no es el nombre de la variable Java, sino que la plantilla intente leer `${saluditos}` cuando el `Model` solo tiene la clave `saludo`. La variable puede llamarse `saluditos` sin problema; lo que no puede es que la plantilla use una clave que no existe.

### El error exacto

Si en el controlador se registra la clave `saluditos` y la plantilla usa `${saludo}`, Thymeleaf lanza algo así:

```text
java.lang.IllegalStateException:
Neither BindingResult nor plain target object for bean name 'saludo'
available as request attribute
```

O, si la plantilla usa `${saluditos}` y el controlador registró `saludo`:

```text
java.lang.IllegalStateException:
Neither BindingResult nor plain target object for bean name 'saluditos'
available as request attribute
```

> 🧠 **Regla práctica:** la clave del `Model` y el `th:object` de la plantilla tienen que ser **exactamente la misma cadena**.

### La regla completa

```text
@ModelAttribute Saludo saluditos
        │
        ├── tipo: Saludo
        └── clave: "saludo"   ← se deriva del TIPO, no de la variable
```

La variable se llama `saluditos`, pero en el `Model` el objeto se llama `saludo`. Son dos nombres distintos para dos cosas distintas:

| Nombre | Dónde vive | Quién lo usa |
| --- | --- | --- |
| `saluditos` | Parámetro del método Java | Solo el código Java |
| `saludo` | Clave del `Model` | La plantilla (`${saludo}`) |

---

## Cómo cambiar el nombre del objeto

Hay dos formas correctas y una que **no existe**.

### Opción A: `@ModelAttribute("nombre")`

```java
@PostMapping("/saludos")
public String saludosEnviado(
        @ModelAttribute("saluditos") Saludo saludo) {

    return "resultado";   // la clave es "saluditos"
}
```

Y la plantilla debe usar esa clave:

```html
<p th:text="|id: ${saluditos.id}|"></p>
<p th:text="|contenido: ${saluditos.contenido}|"></p>
```

### Opción B: `model.addAttribute("nombre", objeto)`

```java
@PostMapping("/saludos")
public String saludosEnviado(
        @ModelAttribute Saludo saludo,
        Model modelo) {

    modelo.addAttribute("saluditos", saludo);   // clave personalizada
    return "resultado";
}
```

En este caso el `Model` acaba con **dos claves**: `saludo` (la automática) y `saluditos` (la manual). Funciona, pero es más limpio usar solo una.

### Opción C (incorrecta): `@Model`

```java
// ❌ ESTO NO COMPILA: @Model no es una anotación
public String saludosEnviado(@Model Saludo saludo) { ... }
```

`Model` es una **interfaz** de Spring, no una anotación. Se recibe como parámetro para añadir atributos:

```java
import org.springframework.ui.Model;

public String formularioSaludos(Model modelo) {
    modelo.addAttribute("saludo", new Saludo());
    return "saludos";
}
```

| Nombre | Qué es | Cómo se usa |
| --- | --- | --- |
| `Model` | Interfaz de Spring | `Model modelo` como parámetro |
| `@ModelAttribute` | Anotación | Sobre un parámetro o un método |
| `@Model` | **No existe** | — |

> ⚠️ **Corrección de la libreta:** donde decía «`@Model` es la opción que nos viene mejor» debe decir **`@ModelAttribute("nombre")`** o **`model.addAttribute("nombre", objeto)`**.

---

## El formulario Thymeleaf

La plantilla del formulario es esta:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>SALUDOS</title>
</head>
<body>
    <h1>Formulario</h1>
    <form action="#" th:action="@{/saludos}" th:object="${saludo}" method="post">
        <p>Id: <input type="text" th:field="*{id}" /> </p>
        <p>Mensaje: <input type="text" th:field="*{contenido}" /> </p>
        <p><input type="submit" value="submit" />  <input type="reset" value="reset" /> </p>
    </form>
</body>
</html>
```

### Los tres atributos clave

| Atributo | Qué hace | Equivalente HTML |
| --- | --- | --- |
| `th:action="@{/saludos}"` | URL de envío, con el *context path* de la aplicación | `action="/saludos"` |
| `th:object="${saludo}"` | Declara el **objeto de formulario** | — |
| `th:field="*{id}"` | Enlaza el input con la propiedad `id` del objeto | `name="id"` + `value` + `id` |

### `th:object` y `th:field`

`th:object="${saludo}"` busca en el `Model` una clave llamada **`saludo`**. Si no existe, el formulario falla antes de renderizarse.

`th:field="*{id}"` usa el asterisco porque se refiere a una **propiedad del objeto declarado** en `th:object`. No es lo mismo que `${...}`, que accede al `Model` completo.

```text
${saludo}      → atributo del Model
*{id}          → propiedad del objeto de th:object
```

`th:field` genera automáticamente:

```html
<input type="text" id="id" name="id" value="0" />
<input type="text" id="contenido" name="contenido" value="" />
```

Por eso el `POST` llega con los parámetros `id` y `contenido`, que son exactamente los que `@ModelAttribute` usa para rellenar el objeto.

### El detalle de `action="#"`

El formulario tiene `action="#"` **y** `th:action="@{/saludos}"`. Thymeleaf sobrescribe el `action`, así que funciona, pero el `#` es un resto que confunde. Lo correcto es dejar solo `th:action`:

```html
<form th:action="@{/saludos}" th:object="${saludo}" method="post">
```

### La plantilla de resultado

```html
<!DOCTYPE html>
<html lang="en">
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

| Expresión | Qué muestra |
| --- | --- |
| `${saludo.id}` | La propiedad `id` del objeto |
| `${saludo.contenido}` | La propiedad `contenido` |
| `|id: ${...}|` | Literal + expresión (sintaxis de tubería) |

> 🔗 `th:text` escapa el HTML. Si en vez de `th:text` se usara `th:utext`, un contenido como `<script>alert('xss')</script>` se ejecutaría. Es lo que se explicó en el [día 9](bitacora-dia-nueve.md).

---

## El flujo completo de una petición

```text
1. GET /saludos
        │
        ▼
   formularioSaludos(Model)
        │  modelo.addAttribute("saludo", new Saludo())
        │  return "saludos"
        ▼
   templates/saludos.html
        │  th:object="${saludo}"
        │  th:field="*{id}" / "*{contenido}"
        ▼
   El usuario rellena y pulsa submit
        │
        ▼
2. POST /saludos
   id=7&contenido=Hola
        │
        ▼
   saludosEnviado(@ModelAttribute Saludo saludo)
        │  new Saludo()
        │  setId(7) / setContenido("Hola")
        │  model.addAttribute("saludo", saludo)
        │  return "resultado"
        ▼
   templates/resultado.html
        │  ${saludo.id} / ${saludo.contenido}
        ▼
   HTML final  ──►  Navegador
```

| Paso | Método HTTP | Método Java | Vista |
| --- | --- | --- | --- |
| 1 | `GET /saludos` | `formularioSaludos` | `saludos.html` |
| 2 | `POST /saludos` | `saludosEnviado` | `resultado.html` |
| 3 | `GET /saludos` (enlace) | `formularioSaludos` | `saludos.html` |

> ⚠️ El POST devuelve `"resultado"` **directamente**, sin `redirect:`. Eso significa que si el usuario recarga la página de resultado, el navegador **reenvía el formulario**. Es el problema que se resuelve en el [día 12](bitacora-dia-doce.md) con el patrón *Post/Redirect/Get*.

---

## `@ModelAttribute` frente a `@RequestParam`

| Aspecto | `@RequestParam` | `@ModelAttribute` |
| --- | --- | --- |
| Qué enlaza | **Un** parámetro | **Muchos** parámetros → campos de un objeto |
| Tipo habitual | `String`, `int`, `Long`… | Un POJO |
| Necesita constructor vacío | No | Sí |
| Necesita setters | No | Sí |
| Añade al `Model` | No (hay que hacerlo a mano) | Sí, automáticamente |
| Valida con `@Valid` | No directamente | Sí, con `BindingResult` |
| Nombre por defecto | El del parámetro | El del **tipo** |
| Cuándo usarlo | Un valor suelto (`?nombre=Ruvik`) | Un formulario con varios campos |

### Ejemplo comparado

**Un solo dato** → `@RequestParam`:

```java
@GetMapping("/saludo")
public String saludo(
        @RequestParam(defaultValue = "mundo") String nombre,
        Model modelo) {

    modelo.addAttribute("mensaje", nombre);
    return "hola";
}
```

**Varios datos que forman un objeto** → `@ModelAttribute`:

```java
@PostMapping("/saludos")
public String saludosEnviado(@ModelAttribute Saludo saludo) {
    return "resultado";
}
```

> 🧠 No son excluyentes. Un formulario grande puede usar `@ModelAttribute` para el objeto y `@RequestParam` para un valor auxiliar (por ejemplo, un idioma o un filtro).

---

## Errores y detalles detectados

### 1. `@lombook` → **Lombok**

No es una anotación, es el nombre de la librería. La anotación es `@Data` (o `@Getter`, `@Setter`, etc.).

### 2. `@ModelAtribute` → **`@ModelAttribute`**

Falta una `t`. Es fácil de confundir porque en español «atributo» lleva una sola `t`, pero la anotación inglesa lleva `tt`.

### 3. `@Model` no es una anotación

`Model` es una **interfaz** (`org.springframework.ui.Model`). Se recibe como parámetro para añadir atributos. Para poner nombre al objeto se usa `@ModelAttribute("nombre")` o `model.addAttribute("nombre", objeto)`.

### 4. El nombre no depende de la variable, sino del tipo

`@ModelAttribute Saludo saluditos` registra la clave **`saludo`**, no `saluditos`. La variable solo existe en Java; la clave del `Model` se deriva del tipo.

### 5. «Cualquier cosa funciona porque es un objeto»

La conclusión es correcta, pero el motivo hay que decirlo bien: Spring usa el **nombre simple de la clase en minúscula** (`Saludo` → `saludo`) porque no es un tipo simple (`String`, `int`, etc.). No es que «cualquier nombre valga»: es que **el nombre de la variable se ignora**.

### 6. `long id` frente a `Long id`

Con `long` primitivo:

- Un `Saludo` nuevo tiene `id = 0`, y el formulario muestra `value="0"`.
- Si el usuario borra el campo y envía, Spring no puede convertir `""` a `long` y se produce un error de *binding* (normalmente un `400 Bad Request` si no hay `BindingResult`).

Con `Long`:

- Un `Saludo` nuevo tiene `id = null`, y el campo aparece vacío.
- El valor vacío se acepta como `null`.

| Tipo | Valor inicial | Campo vacío | Recomendación |
| --- | --- | --- | --- |
| `long` | `0` | ❌ Error de conversión | Evitar en formularios |
| `Long` | `null` | ✅ Se acepta | Preferible |

### 7. `action="#"` sobra

`th:action` ya genera el `action` correcto. El `#` es un resto del HTML estático y confunde al leerlo.

### 8. El POST devuelve la vista sin `redirect:`

Al recargar `resultado.html`, el navegador repite el `POST`. Se soluciona con `return "redirect:/resultado"` o, mejor, con el patrón Post/Redirect/Get que se ve en el día 12.

### 9. `modelo.addAttribute("saludo", saludo)` es redundante

`@ModelAttribute` ya añade el objeto al `Model` con la clave `saludo`. La línea no molesta, pero se puede quitar.

### 10. `lang="en"` con contenido en español

Detalle menor de accesibilidad: si el contenido está en español, lo correcto es `<html lang="es">`.

### 11. El enlace de vuelta está escrito a mano

```html
<a href="/saludos">Envia otro saludo</a>
```

Funciona, pero si la aplicación se despliega bajo un *context path* (`/mi-app`), el enlace se rompe. Lo correcto es:

```html
<a th:href="@{/saludos}">Envia otro saludo</a>
```

### 12. `demoFormulario` no usa Lombok en el repositorio

El `Saludo.java` subido tiene getters y setters manuales. Si se documenta `@Data`, hay que aclarar que es la versión de la sesión, no la del proyecto tal y como está guardado.

### 13. Lombok no se empaqueta en el JAR

Al usar `compileOnly`, Lombok no viaja al artefacto final. Eso es correcto: en ejecución solo hacen falta los métodos ya generados, no la librería.

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
Día 6   POJOs, servlets y MVC   ──►  saber qué es un modelo
   │
Día 7   @RequestParam           ──►  leer un dato suelto
   │
Día 9   MVC y saneamiento       ──►  separar responsabilidades
   │
Día 10  Model + Thymeleaf       ──►  pasar datos a la vista
   │
Día 11  @ModelAttribute         ──►  pasar un OBJETO a la vista
   │
Día 12  redirect                ──►  cerrar el flujo del formulario
   │
Día 13  HttpSession             ──►  recordar al usuario
```

### Antes y después del día 11

| Aspecto | Día 10 | Día 11 |
| --- | --- | --- |
| Datos que viajan | Valores sueltos (`mensaje`) | Un objeto completo (`saludo`) |
| Cómo se leen | `@RequestParam` | `@ModelAttribute` |
| Cómo se enlaza la vista | `th:text="${mensaje}"` | `th:object` + `th:field` |
| Código repetido | Getters y setters a mano | `@Data` de Lombok |
| Nombre en el `Model` | Se elige a mano en `addAttribute` | Se deriva del tipo |
| Flujo | Una sola petición `GET` | `GET` formulario + `POST` resultado |
| Errores típicos | Clave mal escrita en `${...}` | Clave del `Model` distinta del `th:object` |

### Lo que se mantiene

- **`@Controller`** sigue eligiendo la vista por su nombre.
- **`Model`** sigue siendo el puente entre controlador y plantilla.
- **Thymeleaf** sigue renderizando el HTML final.
- **`@GetMapping` / `@PostMapping`** siguen mapeando las rutas.
- **`./gradlew bootRun`** sigue siendo el comando de desarrollo.

### Lo que cambia de verdad

1. **El dato deja de ser un valor suelto** y pasa a ser un **objeto con propiedades**.
2. **El enlace del formulario es automático**: `th:field` genera `name`, `id` y `value`.
3. **Spring rellena el objeto** llamando a los setters; ya no se hace a mano.
4. **Lombok elimina el ruido** de getters, setters, `toString`, `equals` y `hashCode`.
5. **El nombre del objeto en el `Model` tiene reglas**: sale del tipo y se puede cambiar explícitamente.

> 🧠 **Conclusión:** el día 11 une dos piezas que ya existían por separado: **POJO** (día 6) y **`Model`** (día 10). `@ModelAttribute` las conecta, y Lombok quita el trabajo repetitivo de escribir el POJO. La clave está en entender que **el nombre de la variable Java y la clave del `Model` son cosas distintas**.

---

## Chuleta de código

```groovy
// build.gradle — Lombok
dependencies {
    compileOnly 'org.projectlombok:lombok'
    annotationProcessor 'org.projectlombok:lombok'
    testCompileOnly 'org.projectlombok:lombok'
    testAnnotationProcessor 'org.projectlombok:lombok'
}
```

```java
// POJO con Lombok
import lombok.Data;

@Data
public class Saludo {
    private Long id;
    private String contenido;
}
```

```java
// POJO sin Lombok (equivalente)
public class Saludo {
    private Long id;
    private String contenido;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getContenido() { return contenido; }
    public void setContenido(String contenido) { this.contenido = contenido; }
}
```

```java
// Controlador con formulario
@Controller
public class ControllerDemoFormulario {

    @GetMapping("/saludos")
    public String formularioSaludos(Model modelo) {
        modelo.addAttribute("saludo", new Saludo());
        return "saludos";
    }

    @PostMapping("/saludos")
    public String saludosEnviado(@ModelAttribute Saludo saludo) {
        return "resultado";   // "saludo" ya está en el Model
    }
}
```

```java
// Cambiar el nombre del objeto
@PostMapping("/saludos")
public String saludosEnviado(
        @ModelAttribute("saluditos") Saludo saludo) {
    return "resultado";   // clave: "saluditos"
}
```

```java
// Alternativa con Model
@PostMapping("/saludos")
public String saludosEnviado(
        @ModelAttribute Saludo saludo,
        Model modelo) {

    modelo.addAttribute("saluditos", saludo);
    return "resultado";
}
```

```html
<!-- Formulario Thymeleaf -->
<form th:action="@{/saludos}" th:object="${saludo}" method="post">
    <input type="text" th:field="*{id}" />
    <input type="text" th:field="*{contenido}" />
    <input type="submit" value="Enviar" />
</form>
```

```html
<!-- Resultado -->
<p th:text="|id: ${saludo.id}|"></p>
<p th:text="|contenido: ${saludo.contenido}|"></p>

<!-- Con clave personalizada -->
<p th:text="|id: ${saluditos.id}|"></p>
```

```text
Reglas rápidas
─────────────────────────────────────────────
${...}          → atributo del Model
*{...}          → propiedad del objeto de th:object
Saludo          → clave "saludo"
Saludo x        → clave "saludo" (la variable no importa)
@ModelAttribute("otro")  → clave "otro"
Model           → interfaz, NO anotación
@Data           → getters, setters, toString, equals, hashCode
compileOnly     → Lombok no va al JAR
```

---

## Pendientes y preguntas

- [ ] Añadir Lombok a `demoFormulario` y comprobar que `Saludo` sigue funcionando con `@Data`.
- [ ] Cambiar `long id` por `Long id` y probar a enviar el campo vacío.
- [ ] Probar `@ModelAttribute("saluditos")` y actualizar `resultado.html` para usar `${saluditos}`.
- [ ] Comprobar el error exacto que aparece al desajustar la clave del `Model` y el `th:object`.
- [ ] Quitar `modelo.addAttribute("saludo", saludo)` del POST y verificar que sigue funcionando.
- [ ] Sustituir `@RequestParam` por `@ModelAttribute` en un formulario con varios campos.
- [ ] Añadir `@Valid` + `BindingResult` al formulario y mostrar los errores en la plantilla.
- [ ] Cambiar el POST para que devuelva `"redirect:/resultado"` y comprobar que recargar ya no reenvía.
- [ ] Revisar la diferencia entre `compileOnly` e `implementation` en Gradle.
- [ ] Ejecutar `javap -p` sobre `Saludo.class` para ver los métodos generados por Lombok.
- [ ] ¿Qué pasa si se añade `@AllArgsConstructor` sin `@NoArgsConstructor`? ¿Por qué falla el *binding*?
- [ ] ¿Por qué `@ModelAttribute` necesita constructor vacío y setters?
- [ ] Rellenar la **bitácora del día 13**, que está vacía.
- [ ] Completar el [día 12](bitacora-dia-doce.md) con el patrón Post/Redirect/Get.

---

**Relacionado:** [[bitacora-dia-diez]] · [[bitacora-dia-doce]] · [[bitacora-dia-nueve]] · [[bitacora-dia-siete]] · [[bitacpra-dia-seis]] · [[bitacora-dia-trece]]

**Documentación:** `TEORIA/documentanción - profe/D1 -UD2.md` (tutorial 2) · `PROYECTOS/demoFormulario/` · `PROYECTOS/D3-UD2/src/main/java/ruvik/d3ud2/TusDatos.java`

**Proyecto:** [[demoFormulario]]
