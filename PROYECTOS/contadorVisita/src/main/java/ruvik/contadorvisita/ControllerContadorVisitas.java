package ruvik.contadorvisita;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.concurrent.atomic.AtomicInteger;

@RestController
public class ControllerContadorVisitas {
    private AtomicInteger cotador = new AtomicInteger(0);
    @GetMapping("/")
    public String contadorVisitas() {

        return "Visitantes: " + cotador.getAndAdd(1);
    }
}

