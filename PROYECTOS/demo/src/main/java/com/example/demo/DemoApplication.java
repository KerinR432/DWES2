package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }

    // EL PRIMERO GET DE TODO EL MUNDO DE SPRINGBOOT


    @PostMapping("/formulario")
    public String procesarDatos(@RequestParam(value = "nombre") String nombre){
        System.out.println("Procesando proceso de datos");

        if (!nombre.isEmpty()){
            return String.format("Hola %s", nombre) ;
        }
        return String.format("Hola mundo") ;
    }

}
