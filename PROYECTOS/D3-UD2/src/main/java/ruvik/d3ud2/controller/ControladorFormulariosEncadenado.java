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
    //static int siguiente = 0;


    @GetMapping("/formulario1")
    public String formulario1(@ModelAttribute("datos") TusDatos datos, Model model) {
        model.addAttribute("datos", datos);
        return "Formulario1";
    }


    @GetMapping("/formulario2")
    public String formulario2(@ModelAttribute("datos") TusDatos datos, Model model) {
        model.addAttribute("datos", datos);
        return "Formulario2";
    }

    @PostMapping("/procesar")
    public String procesarDatos(@ModelAttribute TusDatos datos,
                                @RequestParam("contador") Integer contador,
                                Model modelo) {
        int siguiente = contador;
        System.out.println(datos);
        System.out.println(siguiente);

        if (contador == 0) {
            return "redirect:/formulario1";
        }

        if (siguiente == 1) {

            modelo.addAttribute("datos", datos);
            modelo.addAttribute("contador", contador);
            return "Formulario2";
        }

        if (siguiente == 2) {
            modelo.addAttribute("datos", datos);
            modelo.addAttribute("contador", contador);
            return "Formulario3";
        }

        if (siguiente == 3) {
            modelo.addAttribute("datos", datos);
            modelo.addAttribute("contador", contador);
            return "Formulario4";
        }



        modelo.addAttribute("datos", datos);
        modelo.addAttribute("contador", contador);
        return "/Resultado";
    }
}
