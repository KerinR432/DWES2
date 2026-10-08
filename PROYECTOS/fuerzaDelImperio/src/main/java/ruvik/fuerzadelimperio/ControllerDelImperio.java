package ruvik.fuerzadelimperio;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;

@Controller
public class ControllerDelImperio {

    @GetMapping("/")
    public String mostrarFormulario(FormularioImperial imperial, Model modelo) {
        modelo.addAttribute("imperial", imperial);

        return "formulario";
    }

    @PostMapping("/")
    public String procesarFormulario(FormularioImperial imperial, Model modelo) {
        modelo.addAttribute("imperial", imperial);

        if(imperial.getEdad()>18) {
            modelo.addAttribute("esMayor",true);
        }
        if(imperial.getRango()>5) {
            modelo.addAttribute("esAltoRango",true);
        }

        return "tucartilla";
    }
}
