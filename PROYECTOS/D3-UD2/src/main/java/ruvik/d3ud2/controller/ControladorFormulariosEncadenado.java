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
    public String formulario1(@ModelAttribute TusDatos tusDatos, Model model) {
        model.addAttribute("tusDatos", tusDatos);
        return "Formulario1";
    }


    @GetMapping("/formulario2")
    public String formulario2(@ModelAttribute TusDatos tusDatos, Model model) {
        model.addAttribute("tusDatos", tusDatos);
        return "Formulario2";
    }

    @PostMapping("/procesar")
    public String procesarDatos(@ModelAttribute TusDatos datos,
                                @RequestParam("contador") Integer contador,
                                Model modelo) {
        int siguiente = contador;
        System.out.println(datos);
        System.out.println(siguiente);

        if (siguiente == 1) {

            modelo.addAttribute("datos", datos);
            modelo.addAttribute("contador", contador);
            return "/Formulario2";
        }

        if (siguiente == 2) {
            modelo.addAttribute("datos", datos);
            modelo.addAttribute("contador", contador);
            return "/Formulario3";
        }


        modelo.addAttribute("datos", datos);
        return "/Resultado";
    }
}
