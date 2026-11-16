package com.example.demo.Controller;

import com.example.demo.Jugador;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.Optional;
import java.util.Random;

@Controller
public class JugadorController {
    private static Random random = new Random();
    static final Integer LIMITE = 50;
    @GetMapping("/resultados")
    public String mostrarResultado(Model modelo) {
        Jugador jugador = new Jugador();
        modelo.addAttribute("Jugador", jugador.ejemploFakeListaJugadores());
        return "resultado";
    }

    @GetMapping("/jugar")
    public String mostrarFormularioParaJugar(Model modelo) {
        Integer numeroAleatorio = random.nextInt(1,50);
        System.out.println("Numero Aleatorio en el GET: " + numeroAleatorio);
        modelo.addAttribute("tope", LIMITE);
        Jugador jugando = new Jugador();
        jugando.setOportunidades(6);
        System.out.print("Numero de oportunidades que tienes en GET: " + jugando.getOportunidades() + "\n");
        modelo.addAttribute("oportunidad", jugando.getOportunidades());
        modelo.addAttribute("mostrarOportunidad", jugando.getOportunidades());
        modelo.addAttribute("aleatorio", numeroAleatorio);
        return "formAdivina";
    }

    @PostMapping("/jugar")
    public String empezarAJugar(Model modelo,
                                @RequestParam ("numero") int numero,
                                @RequestParam ("oportunidad") Integer oportunidad,
                                @RequestParam ("aleatorio") Integer aleatorio,
                                Jugador jugando) {
        System.out.print("Numero introducido: " + numero + "\n");
        System.out.println("Numero Aleatorio en el POST: " + aleatorio);

        if (numero == aleatorio) {
            jugando.setGanar(true);
            modelo.addAttribute("Ganar", jugando.isGanar());
        }

        if (oportunidad <= 0) {
            jugando.setGanar(false);
            System.out.println("TRAS JUGAR TU RESULTADO ES: " + jugando.isGanar());
            modelo.addAttribute("Ganar", jugando.isGanar());
        }

        if (numero < aleatorio) {
            jugando.setOportunidades(oportunidad - 1);
            modelo.addAttribute("oportunidad", jugando.getOportunidades());
            modelo.addAttribute("mostrarOportunidad", jugando.getOportunidades());
            modelo.addAttribute("mensaje","Lo siento, tu numero es menor");
        } else {
            jugando.setOportunidades(oportunidad - 1);
            modelo.addAttribute("oportunidad", jugando.getOportunidades());
            modelo.addAttribute("mostrarOportunidad", jugando.getOportunidades());
            modelo.addAttribute("mensaje","Lo siento, tu numero es mayor");
        }
        modelo.addAttribute("aleatorio",aleatorio);
        System.out.print("Numero de oportunidades que tienes en POST: " + oportunidad + "\n");
        modelo.addAttribute("tope", LIMITE);
        return "formAdivina";
    }


}
