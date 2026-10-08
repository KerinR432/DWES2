package ruvik.validacionformulario;

import jakarta.validation.Valid;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Controller
public class ControladorWeb implements WebMvcConfigurer {

    @Override
    public void addViewControllers(ViewControllerRegistry registro) {
        registro.addViewController("/resultado").setViewName("resultado");
    }

    @GetMapping("/")
    public String verFornulario(@ModelAttribute("persona") FormularioPersona persona) {
        return "formulario";
    }

    @PostMapping("/")
    public String verificarInformacionPersona(@Valid @ModelAttribute("persona") FormularioPersona persona, BindingResult bindingResult) {

        if (bindingResult.hasErrors()) {
            return "formulario";
        }
        return "redirect:/resultado";
    }
}
