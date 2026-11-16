# DWES2 · Desarrollo Web en Entorno Servidor

Repositorio de prácticas del módulo **Desarrollo Web en Entorno Servidor (DWES2)**: aplicaciones con **Java 21** y **Spring Boot**, apuntes de clase y bitácoras de aprendizaje.

![Java](https://img.shields.io/badge/Java-21-orange)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-4.x-green)
![Gradle](https://img.shields.io/badge/Build-Gradle-blue)
![Thymeleaf](https://img.shields.io/badge/Vistas-Thymeleaf-005F0F)

> 👨‍🏫 **Profesor**: cada práctica de `PROYECTOS/` indica los conceptos que trabaja y sus rutas principales. La progresión completa del curso está en [`TEORIA/`](TEORIA/) (bitácoras por días).
>
> 🧑‍🎓 **Compañeros**: si solo quieres ver y ejecutar una práctica, ve al apartado [Cómo ejecutar un proyecto](#cómo-ejecutar-un-proyecto).

---

## Índice

- [Mapa del repositorio](#mapa-del-repositorio)
- [Prácticas (PROYECTOS)](#prácticas-proyectos)
- [Teoría y bitácoras](#teoría-y-bitácoras)
- [Cómo ejecutar un proyecto](#cómo-ejecutar-un-proyecto)
- [Rutas de cada práctica](#rutas-de-cada-práctica)

---

## Mapa del repositorio

```text
DWES2/
├── PROYECTOS/                    # Prácticas con Spring Boot (una carpeta por práctica)
│   ├── HolaMundoConPlantilla/     #   Primera web con plantilla Thymeleaf
│   ├── contadorVisita/            #   Sesiones y contador de visitas
│   ├── demoFormulario/            #   Formularios con objeto (ModelAttribute)
│   ├── PracticandoFormulario/     #   Formularios básicos GET/POST
│   ├── ValidacionFormulario/      #   Validación con Spring Validation
│   ├── fuerzaDelImperio/          #   Formularios + lógica de presentación
│   ├── UD1-UD2/                   #   Práctica integradora UD1–UD2
│   ├── D3-UD2/                    #   Formularios encadenados en varios pasos
│   ├── D4-UD2/                    #   Internacionalización (i18n) y codificación
│   └── demo/                      #   Proyecto base de demostración
├── TEORIA/                        # Bitácoras de clase + documentación
│   ├── Bitacora-dia-*.md          #   Apuntes sesión a sesión
│   ├── css/                       #   Hojas de estilo de las bitácoras
│   └── documentanción - profe/    #   Documentación aportada en clase
└── README.md
```

---

## Prácticas (PROYECTOS)

Ordenadas aproximadamente por dificultad y por el momento del curso en que se hicieron:

| Práctica | Conceptos que trabaja |
|---|---|
| [`HolaMundoConPlantilla`](PROYECTOS/HolaMundoConPlantilla) | Primer proyecto Spring Boot. Controlador `@GetMapping`, vista HTML con **Thymeleaf**. |
| [`contadorVisita`](PROYECTOS/contadorVisita) | Sesión HTTP y estado compartido en el servidor con un contador de accesos. |
| [`demoFormulario`](PROYECTOS/demoFormulario) | Envío de formulario con **objeto** (`@ModelAttribute`) y respuesta en otra vista. |
| [`PracticandoFormulario`](PROYECTOS/PracticandoFormulario) | Formularios GET/POST básicos con Spring MVC. |
| [`ValidacionFormulario`](PROYECTOS/ValidacionFormulario) | Validación de campos con anotaciones de **Spring Validation** y mensajes de error. |
| [`fuerzaDelImperio`](PROYECTOS/fuerzaDelImperio) | Formulario + lógica de presentación en MVC (con temática Star Wars 🌌). |
| [`UD1-UD2`](PROYECTOS/D1-UD2) | Práctica integradora de las unidades didácticas 1 y 2. |
| [`D3-UD2`](PROYECTOS/D3-UD2) | **Formularios encadenados** en varios pasos: los datos se conservan entre pantallas. |
| [`D4-UD2`](PROYECTOS/D4-UD2) | **Internacionalización (i18n)** con `messages.properties` y manejo de codificación. |
| [`demo`](PROYECTOS/demo) | Proyecto base de demostración y configuración inicial. |

---

## Teoría y bitácoras

En [`TEORIA/`](TEORIA/) está el aprendizaje del curso día a día.

### Bitácoras por sesión

| Día | Tema |
|---|---|
| [Día 1](TEORIA/Bitacora-dia-uno.md) | Servidores de desarrollo web |
| [Día 2](TEORIA/Bitacora-dia-dos.md) | El protocolo HTTP |
| [Día 3](TEORIA/Bitacora-dia-tres.md) | Anatomía de una URL |
| [Día 4](TEORIA/bitacora-dia-cuatro.md) | Presentaciones de compañeros |
| [Día 5](TEORIA/bitacora-dia-cinco.md) | Conceptos de las presentaciones (CLI y más) |
| [Día 6](TEORIA/bitacpra-dia-seis.md) | Backend en Java: hilos, servlets y Spring Boot |
| [Día 7](TEORIA/bitacora-dia-siete.md) | Spring Boot puro: primeros endpoints y formularios |
| [Día 8](TEORIA/bitacora-dia-ocho.md) | Familiarización con Spring Boot |
| [Día 9](TEORIA/bitacora-dia-nueve.md) | Repaso D1-UD2, JAR, puerto 80 y teoría MVC |
| [Día 10](TEORIA/bitacora-dia-diez.md) | Plantillas Thymeleaf, `Model` y contador thread-safe |
| [Día 11](TEORIA/bitacora-dia-once.md) | Lombok (`@Data`) y `@ModelAttribute` en formularios |
| [Día 12](TEORIA/bitacora-dia-doce.md) | `redirect`, PRG y `@ModelAttribute` vs `@RequestParam` |
| [Día 13](TEORIA/bitacora-dia-trece.md) | Cookies, sesiones y carrito de la compra |

### Otros recursos

- 📄 [Documentación del profe](TEORIA/documentanción%20-%20profe) — apuntes aportados en clase (UD1-UD2, D1, D3, D4 en `.md` y `.pdf`).
- 🎨 [`TEORIA/css/`](TEORIA/css) — hojas de estilo usadas en las bitácoras (`diselpunk.css`, `solarpunk.css`, `fantasia-crepuscular.css`, `guia-galactica.css`).

---

## Cómo ejecutar un proyecto

**Requisitos:** Java 21+ y conexión a internet (Gradle descarga las dependencias la primera vez). No hace falta instalar Gradle: cada práctica incluye su *wrapper*.

1. Clona el repositorio:

   ```bash
   git clone https://github.com/KerinR432/DWES2.git
   cd DWES2
   ```

2. Entra en la práctica que quieras probar y arráncala:

   ```bash
   cd PROYECTOS/ValidacionFormulario   # o la que quieras
   ./gradlew bootRun
   ```

   En Windows: `gradlew.bat bootRun`

3. Abre el navegador en la ruta indicada (puerto por defecto `8080`):

   ```text
   http://localhost:8080/
   ```

4. Para ejecutar los tests del proyecto:

   ```bash
   ./gradlew test
   ```

> 💡 Solo se puede ejecutar **una práctica a la vez** si ambas usan el puerto 8080. Detén una (`Ctrl + C`) antes de arrancar otra, o cambia el puerto con `--args='--server.port=8081'`.

---

## Rutas de cada práctica

Puerto por defecto: **http://localhost:8080**

| Práctica | Ruta principal | Qué verás |
|---|---|---|
| `HolaMundoConPlantilla` | `/saludo` | Saludo renderizado con Thymeleaf |
| `contadorVisita` | `/` | Contador que aumenta en cada visita |
| `demoFormulario` | `/saludos` | Formulario y resultado con objeto |
| `PracticandoFormulario` | `/` | Formulario GET/POST |
| `ValidacionFormulario` | `/` | Formulario con validaciones y errores |
| `fuerzaDelImperio` | `/` | Cartilla imperial (formulario temático) |
| `D3-UD2` | `/formulario1` | Cadena de formularios en varios pasos |
| `D4-UD2` | `/i18n` | Página internacionalizada |

---

## Objetivo del repositorio

Servir como **portfolio de aprendizaje** del módulo: muestra la progresión desde conceptos básicos de HTTP y Java hasta formularios validados, sesiones, plantillas e internacionalización con Spring Boot.

## Autor

**KerinR432** · [github.com/KerinR432](https://github.com/KerinR432)

## Licencia

Sin licencia especificada por el momento (uso académico).
