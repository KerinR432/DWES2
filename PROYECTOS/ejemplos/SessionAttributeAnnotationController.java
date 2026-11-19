package com.ejemplo.session;

import com.ejemplo.dominio.Usuario;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.SessionAttribute;
import org.springframework.web.bind.annotation.SessionAttributes;

// @SessionAttributes declara que el atributo "usuario" del modelo
// se guarda automaticamente en la sesion HTTP cuando se añade al Model.
@Controller
@SessionAttributes("usuario")
public class UsuarioController {

    // Guardamos un OBJETO Usuario en el modelo -> Spring lo sube a sesion
    @PostMapping("/login")
    public String login(@RequestParam String email, @RequestParam String password,
                        org.springframework.ui.Model model) {
        // Simulacion de autenticacion
        Usuario u = new Usuario(1L, "Kerin", email, "USER");
        model.addAttribute("usuario", u); // <-- se guarda en sesion por @SessionAttributes
        return "redirect:/perfil";
    }

    // 2) @SessionAttribute: inyecta el OBJETO Usuario ya guardado en la sesion
    @GetMapping("/perfil")
    public String perfil(@SessionAttribute("usuario") Usuario usuario,
                         org.springframework.ui.Model model) {
        // "usuario" se recupera automaticamente de la HttpSession y se inyecta
        model.addAttribute("usuario", usuario);
        System.out.println("Usuario en sesion: " + usuario);
        return "perfil";
    }

    @GetMapping("/saludo")
    public String saludo(@SessionAttribute(name = "usuario", required = false) Usuario usuario) {
        if (usuario == null) {
            return "redirect:/login";
        }
        System.out.println("Hola " + usuario.getNombre() + " (" + usuario.getRol() + ")");
        return "saludo";
    }

    // @ModelAttribute con name="usuario" recupera el objeto de sesion para usarlo en el form
    @GetMapping("/editar-perfil")
    public String editarPerfil(@ModelAttribute("usuario") Usuario usuario) {
        // usuario ya viene de la sesion
        return "editarPerfil";
    }

    @PostMapping("/logout")
    public String logout(org.springframework.web.bind.support.SessionStatus status) {
        status.setComplete(); // limpia los atributos de @SessionAttributes
        return "redirect:/";
    }
}
