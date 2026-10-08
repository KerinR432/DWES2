package ruvik.practicandoformulario;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class ControllerFormulario {
    @GetMapping("/")
    public String mostrarFormulario() {
        return "formulario";
    }
}
