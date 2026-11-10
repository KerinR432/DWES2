package ruvik.ud1ud2;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;
import ruvik.ud1ud2.Entity.Contacto;


@SpringBootApplication
@RestController
public class Ud1Ud2Application {

    public static void main(String[] args) {
        SpringApplication.run(Ud1Ud2Application.class, args);
    }

    @GetMapping("/hola")
    public String hello(@RequestParam(value = "nombre", defaultValue = "Mundo") String name) {
        return String.format("Hola, <b> %s!</b>",name);
    }

    @PostMapping("/mostrar")
    public String mostrar(@RequestParam(value = "nombre", defaultValue = "Mundo") String name) {
        return String.format("Hola, <b> %s!</b>",name);
    }


    @PostMapping("/formulario")
    public Contacto formulario(@RequestBody(required = false) Contacto contacto) {
        Contacto contacto1 = contacto;
        System.out.println("Si funciono, creo...");
        System.out.println(contacto1);
        return contacto1;
    }

    @GetMapping("/contacto")
    public Contacto contacto(@RequestParam(value = "nombre",defaultValue = "Benjamin") String nombre,
                             @RequestParam(value = "apellido",defaultValue = "Carmine") String apellido
    ){

        Contacto contacto = new Contacto();
        contacto.setNombre(nombre);
        contacto.setApellido(apellido);
        return contacto;
    }

}
