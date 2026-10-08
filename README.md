# DWES2

Repositorio de prácticas y ejercicios del módulo de Desarrollo Web en Entorno Servidor (DWES2).

Este proyecto reúne varios ejercicios desarrollados con Java, Spring Boot, Thymeleaf, validaciones y MVC para aprender el funcionamiento de aplicaciones web dinámicas.

## Descripción general

El repositorio está organizado en dos grandes bloques:

- `PROYECTOS/`: aplicaciones y ejemplos prácticos realizados durante el curso.
- `TEORIA/`: apuntes, bitácoras y documentación de clase.
- `.github/agents/`: instrucciones y plantillas de apoyo para automatización o ayuda de estudio.

## Tecnologías utilizadas

- Java 21
- Spring Boot 4.1.1
- Gradle
- Thymeleaf
- Spring Validation
- HTML, CSS, JavaScript
- MVC (Model-View-Controller)

## Estructura del repositorio

```text
DWES2/
├── .github/
│   └── agents/
├── PROYECTOS/
│   ├── HolaMundoConPlantilla/
│   ├── PracticandoFormulario/
│   ├── UD1-UD2/
│   ├── ValidacionFormulario/
│   ├── contadorVisita/
│   ├── demo/
│   ├── demoFormulario/
│   ├── fuerzaDelImperio/
│   └── ...
├── TEORIA/
│   └── Bitacora-dia-uno.md
├── README.md
├── .gitignore
└── .gitattributes
```

## Proyectos incluidos

### HolaMundoConPlantilla
Proyecto inicial para practicar la estructura básica de una aplicación Spring Boot y la integración de vistas HTML con Thymeleaf.

### PracticandoFormulario
Ejemplo de formulario web con Spring MVC, donde se envían datos desde una vista a un controlador.

### ValidacionFormulario
Aplicación que valida campos de un formulario mediante anotaciones de Spring Validation y muestra errores en pantalla.

### contadorVisita
Pequeño ejercicio para practicar el contador de accesos con una variable compartida y respuesta HTTP en texto.

### demo
Proyecto base de demostración para aprender la configuración inicial de Spring Boot.

### demoFormulario
Ejemplo del uso de formularios con objetos y respuesta en una vista distinta.

### fuerzaDelImperio
Proyecto más orientado a prácticas con formularios y lógica de presentación de datos en MVC.

### UD1-UD2
Proyecto de aprendizaje más amplio donde se trabajan conceptos de la unidad didáctica 1 y 2 del curso.

## Requisitos previos

Para ejecutar cualquiera de los proyectos del repositorio necesitas:

- Java 21 o superior
- Gradle (se incluye wrapper en cada proyecto)
- IDE recomendado: IntelliJ IDEA o VS Code con extensiones Java

## Cómo ejecutar un proyecto

Cada proyecto tiene su propio `build.gradle` y `gradlew`.

Ejemplo:

```bash
cd PROYECTOS/ValidacionFormulario
./gradlew bootRun
```

También puedes usar:

```bash
./gradlew test
```

para ejecutar las pruebas del proyecto.

## Cómo arrancar la aplicación en el navegador

Tras iniciar el proyecto con `bootRun`, normalmente se accede en:

```text
http://localhost:8080/
```

Dependiendo del proyecto, algunas rutas pueden variar o incluir formularios o páginas específicas.

## Objetivo del repositorio

Este repositorio sirve como portfolio de prácticas del curso de DWES2, mostrando la progresión desde conceptos básicos de Java/Spring hasta formularios, validaciones y aplicaciones web más funcionales.

## Estado del proyecto

Se trata de un repositorio de aprendizaje y prácticas académicas en evolución.

## Autor

KerinR432

## Licencia

Actualmente no se ha especificado ninguna licencia en el repositorio.
