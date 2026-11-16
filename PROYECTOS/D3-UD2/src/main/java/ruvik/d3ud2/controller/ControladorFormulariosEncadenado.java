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

    @GetMapping("/")
    public String inicio() {
        return "redirect:/formulario1";
    }

    @GetMapping("/formulario1")
    public String formulario1(@ModelAttribute("datos") TusDatos datos, Model model) {
        model.addAttribute("datos", datos);
        model.addAttribute("contador", 0);
        return "Formulario1";
    }

    @PostMapping("/procesar")
    public String procesarDatos(@ModelAttribute("datos") TusDatos datos,
                                @RequestParam("contador") Integer contador,
                                Model modelo) {
        modelo.addAttribute("datos", datos);
        modelo.addAttribute("contador", contador);

        return switch (contador) {
            // Volver desde el paso 2 sin perder los datos ya introducidos.
            case -1 -> "Formulario1";
            // Empezar de nuevo: se descarta el objeto y se vuelve al paso 1.
            case 0 -> "redirect:/formulario1";
            case 1 -> "Formulario2";
            case 2 -> "Formulario3";
            case 3 -> "Formulario4";
            case 4 -> "Resultado";
            default -> "redirect:/formulario1";
        };
    }
}
