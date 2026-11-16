# DÍA TRECE — COOKIES, SESIONES Y CARRITO DE LA COMPRA

## Índice

1. [Resumen de la sesión](#resumen-de-la-sesión)
2. [El problema: HTTP no tiene estado](#el-problema-http-no-tiene-estado)
3. [Cookies](#cookies)
4. [Sesiones](#sesiones)
5. [De los campos `hidden` a `HttpSession`](#de-los-campos-hidden-a-httpsession)
6. [Práctica: `Carrito-compra-gemini`](#práctica-carrito-compra-gemini)
7. [Detalles y fallos detectados](#detalles-y-fallos-detectados)
8. [Comparación con las bitácoras anteriores](#comparación-con-las-bitácoras-anteriores)
9. [Chuleta de código](#chuleta-de-código)
10. [Pendientes y preguntas](#pendientes-y-preguntas)

---

## Resumen de la sesión

Hoy cerramos el círculo que veníamos abriendo desde el **día 7**:

- Vimos que **HTTP es un protocolo sin estado** y por qué eso es bueno para el rendimiento… y malo para un carrito de la compra.
- Conocimos las **cookies** (`Set-Cookie` / `Cookie`) como forma de que el cliente «recuerde» algo entre peticiones.
- Vimos que guardar toda la información en la cookie es incómodo e inseguro, así que el servidor usa una **sesión**: en la cookie solo viaja un **identificador**, y los datos se quedan en el servidor.
- En Spring Boot eso se traduce en el objeto **`HttpSession`**, con `setAttribute()` / `getAttribute()` / `removeAttribute()`.
- Los **campos `hidden`** de las prácticas anteriores dejan de ser necesarios: el estado ya no viaja en el formulario, vive en la sesión.
- Lo aplicamos en el proyecto nuevo **`Carrito-compra-gemini`**, un carrito que guarda un `Map<Producto, Integer>` en la sesión.

> 💡 **Idea clave del día:** una cookie no guarda «tu carrito»; guarda una **llave**. El carrito está en el servidor, asociado a esa llave.

---

## El problema: HTTP no tiene estado

HTTP es un protocolo **stateless (sin estado)**: cada petición es independiente y el servidor no recuerda, por sí mismo, lo que pasó en la petición anterior.

```text
Cliente                                   Servidor
   │                                          │
   │ ── GET /tienda/productos ──────────────► │   "no sé quién eres"
   │ ◄────────────────────── 200 OK ───────── │
   │                                          │
   │ ── POST /tienda/carrito/agregar/1 ─────► │   "¿quién eres? ¿qué carrito?"
   │ ◄────────────────────── 200 OK ───────── │
   │                                          │
   │ ── GET /tienda/carrito ────────────────► │   "sigo sin saber quién eres"
   │ ◄────────────────────── 200 OK ───────── │
```

Que no haya estado es precisamente lo que hace a HTTP **rápido, sencillo y escalable**: el servidor no tiene que reservar memoria para cada cliente entre peticiones. Pero un carrito, un login o un formulario por pasos **necesitan recordar**.

Formas de recuperar el estado:

| Mecanismo | Dónde vive el estado | Quién lo controla |
| --- | --- | --- |
| Campos `hidden` | En el HTML del formulario | Cliente (editable) |
| Cookie | En el navegador | Cliente (editable/borrable) |
| Sesión | En el servidor, con un id en cookie | Servidor |
| Token (JWT, etc.) | En el cliente, firmado | Servidor (firma) |

---

## Cookies

Una **cookie** es un pequeño par de `nombre=valor` que el servidor envía al cliente y que el navegador devuelve automáticamente en las siguientes peticiones al mismo dominio.

### Cabeceras implicadas

- **`Set-Cookie`** → la envía el **servidor** en la respuesta.
- **`Cookie`** → la envía el **cliente** en la siguiente petición.

> ⚠️ En los apuntes originales puse `setCookies`. El nombre correcto de la cabecera es **`Set-Cookie`** (en singular).

```http
HTTP/1.1 200 OK
Set-Cookie: JSESSIONID=8F3A9C2B7D1E; Path=/; HttpOnly
```

```http
GET /tienda/carrito HTTP/1.1
Host: localhost:8080
Cookie: JSESSIONID=8F3A9C2B7D1E
```

### Ciclo completo

```text
1. Cliente ──── GET /tienda/productos ─────────────► Servidor
2. Cliente ◄─── 200 OK + Set-Cookie: JSESSIONID=… ── Servidor
3. Cliente ──── GET /tienda/carrito                 Servidor
                Cookie: JSESSIONID=…  ────────────►
4. Cliente ◄─── 200 OK (contenido de TU carrito) ─── Servidor
```

### Atributos que conviene conocer

| Atributo | Para qué sirve |
| --- | --- |
| `Path` | Rutas para las que se envía la cookie |
| `Domain` | Dominio al que pertenece |
| `Max-Age` / `Expires` | Cuándo caduca |
| `Secure` | Solo se envía por HTTPS |
| `HttpOnly` | JavaScript **no** puede leerla (protege de XSS) |
| `SameSite` | Limita el envío en peticiones cruzadas (protege de CSRF) |

### Problemas de las cookies

- Tamaño muy limitado (unos **4 KB** por cookie).
- Se envían en **cada petición**, aunque no hagan falta.
- El usuario puede **verlas, modificarlas y borrarlas**.
- Guardar datos sensibles en ellas es una mala idea.

Por eso, para un carrito no se guarda el carrito en la cookie: se guarda **solo un identificador**.

---

## Sesiones

La **sesión** es la solución habitual: el servidor genera un identificador único, lo manda en una cookie y guarda la información real **en su propia memoria** (o en una base de datos), asociada a ese identificador.

```text
                        SERVIDOR
                  ┌─────────────────────────┐
Cliente           │  Sesiones               │
   │              │  ┌───────────────────┐  │
   │ JSESSIONID=7 │  │ 7 → { carrito: … }│  │
   │ ────────────►│  └───────────────────┘  │
   │              │  ┌───────────────────┐  │
   │              │  │ 9 → { carrito: … }│  │
   │              │  └───────────────────┘  │
   │ ◄────────────│                         │
   │   HTML       └─────────────────────────┘
```

- La cookie solo lleva el **id** (`JSESSIONID`).
- El servidor busca ese id y recupera **sus** datos.
- Si el id no existe o caduca, el servidor crea una sesión nueva.

### Ventajas

- Los datos **no viajan** al cliente: no se pueden manipular.
- No hay límite de 4 KB.
- El servidor decide qué se guarda y cuándo se borra.

### Inconvenientes

- **Consume memoria** del servidor: muchas sesiones = muchos datos.
- Si hay varios servidores, hay que compartir la sesión (**replicación** o *sticky sessions*).
- Al reiniciar el servidor se pierden las sesiones en memoria.
- Sigue dependiendo de una cookie, así que si el usuario la borra, pierde la sesión.

> 💡 En los apuntes originales lo llamé «sobrecarga al servidor». Es exactamente eso: **cuanto más estado guardamos en el servidor, menos ligero es**. El equilibrio está en guardar solo lo necesario.

### `HttpSession` en Spring Boot

Basta con declarar `HttpSession` como parámetro de un método del controlador:

```java
@GetMapping("/carrito")
public String verCarrito(HttpSession session, Model model) {
    ...
}
```

Spring pide la sesión a Tomcat; si no existe, la crea y manda la cookie `JSESSIONID` al cliente.

| Método | Qué hace |
| --- | --- |
| `session.setAttribute("clave", objeto)` | Guarda un objeto en la sesión |
| `session.getAttribute("clave")` | Lo recupera, pero devuelve `Object` |
| `session.removeAttribute("clave")` | Elimina solo ese dato |
| `session.invalidate()` | Destruye la sesión completa |
| `session.getId()` | Devuelve el identificador de la sesión |
| `session.isNew()` | Indica si la sesión se acaba de crear |

**Importante:** `getAttribute()` devuelve `Object`. Hay que **castear** al tipo real o el programa fallará:

```java
@SuppressWarnings("unchecked")
Map<Producto, Integer> carrito =
        (Map<Producto, Integer>) session.getAttribute("carrito");
```

En Spring Boot la cookie de sesión es `HttpOnly` por defecto y la sesión caduca a los **30 minutos** (`server.servlet.session.timeout`).

---

## De los campos `hidden` a `HttpSession`

En las prácticas anteriores (formularios, `fuerzaDelImperio`, etc.) el estado se llevaba de una pantalla a otra con **campos `hidden`** o con `@ModelAttribute`: los datos viajaban **dentro del formulario**.

```html
<!-- Antes: el estado viaja en el HTML -->
<input type="hidden" name="nombre" value="Ruvik">
<input type="hidden" name="precio" value="899.99">
```

Problemas:

- El usuario puede **cambiar el valor** desde las herramientas del navegador.
- Si se pierde el formulario, se pierde el estado.
- Hay que repetir los campos en cada paso.

Con sesión:

```text
Antes:  Cliente ──[formulario + datos ocultos]──► Servidor
Ahora:  Cliente ──[cookie con id]──────────────► Servidor
                                                   │
                                            datos en la sesión
```

El formulario solo envía **lo nuevo** (por ejemplo, el `id` del producto). El resto ya está guardado.

> ⚠️ **Matiz importante:** la sesión sigue necesitando una cookie. No hemos eliminado las cookies: hemos cambiado *qué* llevan. Antes llevaban datos; ahora llevan una llave.

---

## Práctica: `Carrito-compra-gemini`

**Ruta:** `PROYECTOS/Carrito-compra-gemini`

**Stack:** Java 21 · Spring Boot 4.1.2 · Gradle · Spring Web MVC · Thymeleaf · Lombok.

### Estructura

```text
Carrito-compra-gemini/
├── build.gradle
├── settings.gradle
└── src/main/
    ├── java/ruvik/carritocompragemini/
    │   ├── CarritoCompraGeminiApplication.java
    │   ├── Producto.java
    │   └── TiendaController.java
    └── resources/
        ├── application.properties
        └── templates/
            └── carrito.html
```

### Modelo: `Producto`

```java
public class Producto {
    private Long id;
    private String nombre;
    private double precio;

    // constructor, getters...

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Producto producto = (Producto) o;
        return Objects.equals(id, producto.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
```

**¿Por qué importan `equals()` y `hashCode()`?** Porque el carrito es un `Map<Producto, Integer>` y el producto se usa como **clave**. Si no se sobrescriben, dos objetos `Producto` con el mismo `id` se considerarían distintos y el carrito crearía líneas duplicadas. Aquí se comparan **solo por `id`**, que es lo correcto.

### Catálogo y controlador

El catálogo es una lista fija en memoria:

```java
private static final List<Producto> CATALOGO = Arrays.asList(
        new Producto(1L, "Portátil Gaming", 899.99),
        new Producto(2L, "Ratón Inalámbrico", 25.50),
        new Producto(3L, "Teclado Mecánico", 75.00)
);
```

| Verbo | Ruta | Método | Qué hace |
| --- | --- | --- | --- |
| `GET` | `/tienda/productos` | `listarProductos` | Muestra el catálogo |
| `POST` | `/tienda/carrito/agregar/{id}` | `agregarAlCarrito` | Suma 1 unidad del producto |
| `GET` | `/tienda/carrito` | `verCarrito` | Muestra el carrito y el total |
| `GET` | `/tienda/carrito/vaciar` | `vaciarCarrito` | Borra el carrito de la sesión |

### Añadir al carrito

```java
@PostMapping("/carrito/agregar/{id}")
public String agregarAlCarrito(@PathVariable Long id, HttpSession session) {

    @SuppressWarnings("unchecked")
    Map<Producto, Integer> carrito =
            (Map<Producto, Integer>) session.getAttribute("carrito");

    if (carrito == null) {
        carrito = new HashMap<>();
    }

    Producto productoSeleccionado = CATALOGO.stream()
            .filter(p -> p.getId().equals(id))
            .findFirst()
            .orElse(null);

    if (productoSeleccionado != null) {
        int cantidadActual = carrito.getOrDefault(productoSeleccionado, 0);
        carrito.put(productoSeleccionado, cantidadActual + 1);
    }

    session.setAttribute("carrito", carrito);

    return "redirect:/tienda/carrito";
}
```

Puntos a destacar:

1. **`@PathVariable Long id`** recibe el `{id}` de la URL.
2. Se recupera el carrito de la sesión; si es la primera vez, es `null` y se crea un `HashMap`.
3. Se busca el producto en el catálogo con `stream().filter().findFirst()`.
4. Se suma una unidad con `getOrDefault(producto, 0) + 1`.
5. Se vuelve a guardar en la sesión (aunque el `Map` es el mismo objeto, es buena costumbre).
6. **`redirect:`** evita reenviar el `POST` al recargar la página (**patrón PRG**: *Post/Redirect/Get*).

```text
POST /agregar/1  ──►  actualiza sesión  ──►  302 redirect  ──►  GET /carrito
                                                                    │
                                                              pinta el HTML
```

> 🔗 Esto conecta con el **día 12**: `redirect` reenvía a otra página **sin enviar información**. El estado ya no va en la redirección, va en la sesión.

### Ver el carrito y calcular el total

```java
@GetMapping("/carrito")
public String verCarrito(HttpSession session, Model model) {

    @SuppressWarnings("unchecked")
    Map<Producto, Integer> carrito =
            (Map<Producto, Integer>) session.getAttribute("carrito");

    if (carrito == null) {
        carrito = new HashMap<>();
    }

    double total = carrito.entrySet().stream()
            .mapToDouble(entry -> entry.getKey().getPrecio() * entry.getValue())
            .sum();

    model.addAttribute("carrito", carrito);
    model.addAttribute("total", total);

    return "carrito";
}
```

- Se recorre el `Map` con `entrySet()`.
- Cada línea vale `precio * cantidad`.
- `mapToDouble(...).sum()` convierte el flujo en un `double` y suma.

### Vaciar el carrito

```java
@GetMapping("/carrito/vaciar")
public String vaciarCarrito(HttpSession session) {
    session.removeAttribute("carrito");
    return "redirect:/tienda/productos";
}
```

Se elimina **solo** la clave `carrito`, no toda la sesión. Para destruirla entera sería `session.invalidate()`.

### Plantilla `carrito.html`

```html
<tr th:each="entry : ${carrito}">
    <td th:text="${entry.key.nombre}">Nombre</td>
    <td th:text="${entry.key.precio} + ' €'">Precio</td>
    <td th:text="${entry.value}">Cantidad</td>
    <td th:text="${entry.key.precio * entry.value} + ' €'">Subtotal</td>
</tr>

<h2>Total: <span th:text="${total}">0.0</span> €</h2>
```

Al iterar un `Map` con `th:each`, cada elemento es una entrada:

```text
entry
├── key    → el Producto
└── value  → la cantidad
```

Se usa `entry.key.nombre` porque Thymeleaf traduce `nombre` a `getNombre()`.

---

## Detalles y fallos detectados

Revisando el proyecto he encontrado varios puntos que conviene dejar anotados. No son teoría: son cosas que **romperían la práctica** o que se pueden mejorar.

### 1. Falta `productos.html` ⚠️

El controlador devuelve `"productos"`:

```java
@GetMapping("/productos")
public String listarProductos(Model model) {
    model.addAttribute("productos", CATALOGO);
    return "productos";
}
```

Pero en `src/main/resources/templates/` **solo existe `carrito.html`**. Al entrar en `/tienda/productos`, Thymeleaf lanzará un error del tipo *«Error resolving template [productos]»*.

Solución mínima:

```html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <title>Tienda</title>
</head>
<body>
<h1>Productos</h1>

<ul>
    <li th:each="p : ${productos}">
        <span th:text="${p.nombre}">Nombre</span> —
        <span th:text="${p.precio} + ' €'">0.0</span>

        <form th:action="@{/tienda/carrito/agregar/{id}(id=${p.id})}" method="post">
            <button type="submit">Añadir al carrito</button>
        </form>
    </li>
</ul>

<a th:href="@{/tienda/carrito}">Ver carrito</a>
</body>
</html>
```

> 💡 Como el `POST` se hace con un `<form method="post">`, la ruta `action` **debe coincidir** con el `@PostMapping`, igual que en el día 7.

### 2. `HashMap` no garantiza el orden

El carrito se crea con `new HashMap<>()`. Al pintar la tabla, el orden de las líneas puede cambiar entre peticiones. Si se quiere un orden estable (por orden de inserción), usar `LinkedHashMap`.

### 3. `double` para dinero

`double` no es exacto para precios (`0.1 + 0.2 != 0.3`). Para un ejercicio vale, pero en un proyecto real se usa `BigDecimal`. También se podría formatear el total a 2 decimales en la plantilla.

### 4. Vaciar con `GET`

`GET /tienda/carrito/vaciar` **modifica estado**. Lo correcto en HTTP es usar `POST` (y, si hay login, un token CSRF). Con `GET` basta con que alguien comparta el enlace o lo precargue el navegador para vaciar el carrito sin querer.

### 5. Cast sin comprobar el tipo

```java
(Map<Producto, Integer>) session.getAttribute("carrito");
```

Si en la sesión hubiera otra cosa bajo la clave `carrito`, saltaría un `ClassCastException`. Es aceptable en un ejercicio, pero una clase `Carrito` con sus métodos `agregar`, `total`, `vaciar` sería más limpia y evitaría repetir el cast en cada método.

### 6. La sesión vive en memoria

Si se reinicia el servidor, se pierden todos los carritos. Y si la aplicación crece a varios servidores, habría que compartir sesiones. Para un carrito real se usaría una base de datos o un almacén externo.

### 7. No se puede quitar una unidad

Solo se suma y se vacía todo. Faltaría `POST /carrito/quitar/{id}` para restar una unidad o eliminar una línea.

### 8. Concurrencia y estado compartido

El `CATALOGO` es `static` y compartido por todos los hilos, pero es de **solo lectura**, así que no hay problema. El carrito, en cambio, es **por sesión**, y por eso no se pisa entre usuarios. Esto conecta con el **día 10**: allí el contador era compartido y hubo que usar `AtomicInteger`; aquí el estado está aislado por sesión.

---

## Comparación con las bitácoras anteriores

### Línea temporal

| Día | Qué se aprendió | Proyecto |
| --- | --- | --- |
| **7** | Primer endpoint `GET`, formulario `POST`, `@RequestParam`, HTML estático | `demo` |
| **9** | MVC (Modelo / Vista / Controlador), estructura Spring Boot | — |
| **10** | `@Controller`, plantillas Thymeleaf, `Model`, `th:text`, `th:each`, hilos y `AtomicInteger` | `contadorVisita`, `HolaMundoConPlantilla` |
| **11** | Lombok (`@Data`), comportamiento de `@ModelAttribute` y el nombre del objeto | `demoFormulario` |
| **12** | `redirect`, PRG y `@ModelAttribute` vs `@RequestParam` | `PracticandoFormulario`, `D3-UD2` |
| **13** | HTTP sin estado, cookies, sesiones, `HttpSession`, carrito | `Carrito-compra-gemini` |

### Qué aporta cada día a lo de hoy

```text
Día 7   GET/POST + formularios
   │
Día 9   MVC: dónde va cada cosa
   │
Día 10  Plantillas + Model  ──────►  carrito.html y ${carrito}
   │
Día 11  @ModelAttribute     ──────►  por qué la sesión evita depender del nombre
   │
Día 12  redirect            ──────►  PRG después de agregar
   │
Día 13  HttpSession         ──────►  el estado ya no viaja en el formulario
```

### Del formulario a la sesión

| Aspecto | Días 7–12 (`hidden` / `@ModelAttribute`) | Día 13 (`HttpSession`) |
| --- | --- | --- |
| Dónde vive el estado | En el HTML / en la petición | En el servidor |
| Quién puede modificarlo | El usuario | Solo el servidor |
| Se pierde al cambiar de página | Sí, si no se arrastra | No, mientras dure la sesión |
| Límite de tamaño | El del formulario | Memoria del servidor |
| Se pierde al reiniciar | No (está en el HTML) | Sí (sesión en memoria) |
| Necesita cookie | No | Sí (`JSESSIONID`) |
| Sirve para varias pestañas | Con dificultad | Sí, comparten sesión |

### Lo que se mantiene

- **Thymeleaf** sigue siendo la vista: `th:text`, `th:each`, `th:if`.
- **`Model`** sigue llevando datos del controlador a la plantilla.
- **`@GetMapping` / `@PostMapping`** y la coincidencia entre `action` y ruta no cambian.
- **`redirect:`** se sigue usando después de un `POST`.
- **MVC** no cambia: lo único nuevo es *dónde* se guarda el modelo entre peticiones.

### Lo que cambia de verdad

1. **El estado deja de ser responsabilidad del cliente.**
2. **Aparece la cookie como transporte de identidad**, no de datos.
3. **El servidor asume el coste de la memoria** (el «problema» que apunté en clase).
4. **Los campos `hidden` pasan a ser un antipatrón** para este caso: se pueden manipular y hay que repetirlos.

> 🧠 **Conclusión:** los días anteriores enseñaban a **transportar** datos; el día 13 enseña a **recordarlos**. Un carrito no necesita que el navegador lleve el carrito: necesita que el servidor sepa **quién** está pidiendo.

---

## Chuleta de código

```java
// Obtener / crear la sesión (Spring la crea si no existe)
public String metodo(HttpSession session) { ... }

// Guardar
session.setAttribute("carrito", carrito);

// Leer (devuelve Object → hay que castear)
@SuppressWarnings("unchecked")
Map<Producto, Integer> carrito =
        (Map<Producto, Integer>) session.getAttribute("carrito");

// Borrar una clave
session.removeAttribute("carrito");

// Destruir toda la sesión
session.invalidate();

// Identificador y estado
String id = session.getId();
boolean nueva = session.isNew();
```

```properties
# application.properties
server.servlet.session.timeout=30m
server.servlet.session.cookie.http-only=true
```

```html
<!-- Recorrer un Map en Thymeleaf -->
<tr th:each="entry : ${carrito}">
    <td th:text="${entry.key.nombre}"></td>
    <td th:text="${entry.value}"></td>
</tr>
```

---

## Pendientes y preguntas

- [ ] Crear `productos.html` para que `/tienda/productos` funcione.
- [ ] Probar el carrito con **dos navegadores distintos** y comprobar que cada uno tiene su propio `JSESSIONID`.
- [ ] Abrir las **DevTools → Application → Cookies** y ver la cookie de sesión.
- [ ] Reiniciar el servidor y comprobar que el carrito se pierde (sesión en memoria).
- [ ] Cambiar `HashMap` por `LinkedHashMap` y observar el orden.
- [ ] Añadir `POST /carrito/quitar/{id}` para restar unidades.
- [ ] Comparar `session.removeAttribute("carrito")` con `session.invalidate()`.
- [ ] Relacionar esta sesión con el [día 12](bitacora-dia-doce.md): qué datos viajan en el `redirect` y cuáles se quedan en la sesión.
- [ ] ¿Qué pasa si el usuario bloquea las cookies? ¿Cómo se comporta la sesión?

---

**Relacionado:** [[bitacora-dia-doce]] · [[bitacora-dia-once]] · [[bitacora-dia-diez]] · [[bitacora-dia-nueve]] · [[bitacora-dia-siete]]

**Proyecto:** `PROYECTOS/Carrito-compra-gemini`

**TODO LO VISTO CONVERGE AHÍ:** [[D1 -UD2]]
