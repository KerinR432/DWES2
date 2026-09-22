# PRESENTACIONES DE COMPAÑEROS

## ♦️ RUBY

Lenguajes de scripts. 
MVC separar el software por capaz. 
__ORM__ es una base de datos y en ves de programarlo directamente. 
servidores middewale un servidor adiconal que capture peticones y pasarlo al programa. 
__Dependecias__ hay sistema de descargar libreria y comprobar si son compatibles. 
Desarollo vs prudcción, el desarollo utiliza IDEs y los producción se utiliza en consola o linea de comando. 

---
## 🐘 PHP

PHP se utiliza en el lado de servidor, interprete, editor de texto o IDEs su IDE dedicado es PHPStorm el php tiene su composer para tener librerias. 
utiliza contenerdores como Docker o XAMPP y su base de datos que puede ser msql

Ejecución

necesita recibir la peteción del servidor, necesita un servidor apache o gnix, eterpete, codigo inscrustado en HTML 

codigo 

```php
 <PHP>...<?PHP>
```
Visual Studio Code, necesitas extensiones para ejecutar o utilizar para codificar en `PHP`
PHPStroms ya tiene todo esto y solo es escoger Laravel y que el propio IDE descargue las depetendecias.

las webs implementada con PHP Facebook en su comienzo lo utilizo, la Wikipedia, !Yahoo, AbusoluteWrite, tumblr y WordPress.

ejemplo de codigo ⬇️
```php
// routes/web.php
route::get('/', function () {
    return view('welcome');
});
```

### RECARGO DEL PROFESOR

en javascript si ve, porque el codigo lo manda al navegador, pero en PHP no, el CGI estaba desconsejado por seguridad y rendimiento, en PHP antiende varios procesos.


---
## 🐍 PYTHON

### 1. FASK

Pycharm y Visual son los IDEs son las utilizados, utiliza liberias dedicadas de FASK. 

ejemplo de codigo ⬇️
```python
from flask import Flask

app = Flask(__name__)


@app.route("/")
def home():
  return "¡Hola, mundo con Flask!"


if __name__ == "__main__":
  app.run(debug=True)
```

### 2. FastAPI

crea aplicaciones y APIs tiene libreria para validar datos, genera todo de manera automatica, tener versión de PYTHON 3.8 superior, instalar FastAPI en el IDE, Depende de Uvicorn. 

nextflix lo usa en sus servidores interno, lo usa Uber en su maching learning

ejemplo de codigo ⬇️
```python
from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def leer_raiz():
  return {"mensaje": "¡Hola, mundo!"}


@app.get("/items/{item_id}")
def leer_item(item_id: int, q: str | None = None):
  return {"item_id": item_id, "q": q}
```

 ### 3. Django 

 se utiliza para proyectos grande que necesiten seguridad, tiene herramientas ya lista, bases de datos, seguridad. Se utiliza en mucho en redes sociales, contenido y noticias, tienda y empresas. 
 un gester bit, entorno virtual y bases de datos. Se base en en el modelo vista, templeate. 



 ## #️⃣ C# .NET

 __relacionada__ con [[bitacora-dia-cinco]]
ejemplo de codigo ⬇️
 ```python
from django.db import models

class Articulo(models.Model):
    titulo = models.CharField(max_length=100)
    contenido = models.TextField()
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.titulo
 ```


---
 ## #️⃣ C# y .NET

C# es el principal, tipado fuerte y objetos, seguridad y el framework ASP.NET core, sus requisitos son .NET SDK, el sistemas operativo y Herramientas CLI

servidor y usuario, se ejecuta ASP.NET core, paginas y servidores Kestrel, Nginx o Apahce
Usuario
Chrome, edge, firefox y conectarse al servidor

IDEs -> visual studio, entonorno de microsoft, utilizada para progamar en C# y es mucho mas en gran escala que VS code. 
ejemplo de codigo ⬇️

```c#
var builder = webCreateBuilder(args)

var app = builder
```

Stack Overflow 
Microsoft.com
MarketWatch
GoDaddy
