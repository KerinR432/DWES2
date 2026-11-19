package com.ejemplo.bean;

import com.ejemplo.dominio.Usuario;
import org.springframework.stereotype.Service;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.beans.factory.annotation.Autowired;

// 3) Bean: componente gestionado por Spring que maneja OBJETOS de dominio
@Service
public class UsuarioService {

    // Simula una "base de datos" en memoria
    private final java.util.Map<Long, Usuario> usuarios = new java.util.HashMap<>();

    public UsuarioService() {
        usuarios.put(1L, new Usuario(1L, "Kerin", "kerin@ejemplo.com", "ADMIN"));
        usuarios.put(2L, new Usuario(2L, "Ana", "ana@ejemplo.com", "USER"));
    }

    public Usuario buscarPorId(Long id) {
        return usuarios.get(id);
    }

    public Usuario buscarPorEmail(String email) {
        return usuarios.values().stream()
                .filter(u -> u.getEmail().equalsIgnoreCase(email))
                .findFirst().orElse(null);
    }

    public Usuario registrar(String nombre, String email, String password) {
        Long nuevoId = (long) (usuarios.size() + 1);
        Usuario u = new Usuario(nuevoId, nombre, email, "USER");
        usuarios.put(nuevoId, u);
        return u;
    }
}

@Controller
public class HomeController {

    private final UsuarioService usuarioService;

    // Inyeccion por constructor del Bean (Spring lo crea y lo inyecta)
    @Autowired
    public HomeController(UsuarioService usuarioService) {
        this.usuarioService = usuarioService;
    }

    @GetMapping("/")
    public String home() {
        Usuario u = usuarioService.buscarPorId(1L); // uso del Bean con objeto de dominio
        System.out.println("Usuario cargado por el Bean: " + u);
        return "home";
    }

    @PostMapping("/registro")
    public String registro(@RequestParam String nombre,
                           @RequestParam String email,
                           @RequestParam String password,
                           org.springframework.ui.Model model) {
        Usuario nuevo = usuarioService.registrar(nombre, email, password);
        model.addAttribute("usuario", nuevo);
        return "registroOk";
    }
}
