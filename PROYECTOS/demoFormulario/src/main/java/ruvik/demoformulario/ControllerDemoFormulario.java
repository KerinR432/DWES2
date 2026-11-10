package ruvik.demoformulario;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;

@Controller
public class ControllerDemoFormulario {
    @GetMapping("/saludos")
    public String formularioSaludos(Model modelo) {
        modelo.addAttribute("saludo", new Saludo());
        return "saludos";
    }

    @PostMapping("/saludos")
    public String saludosEnviado(@ModelAttribute Saludo saludo, Model modelo) {
        modelo.addAttribute("saludo", saludo);
        return "resultado";
    }
}
