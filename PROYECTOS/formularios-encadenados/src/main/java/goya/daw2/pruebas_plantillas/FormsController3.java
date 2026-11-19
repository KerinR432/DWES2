package goya.daw2.pruebas_plantillas;

import java.util.ArrayList;

import entity.Quizz;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/version3")
public class FormsController3 {

    static final String[] SIGNOS = { "", "Aries", "Tauro", "Géminis", "Cáncer", "Leo", "Virgo", "Libra", "Escorpio",
            "Sagitario", "Capricornio", "Acuario", "Piscis" };
    static final String[] AFICCIONES = { "Deportes", "Juerga", "Lectura", "Relaciones sociales" };

    private final QuizzSesion quizzSesion;

    public FormsController3(QuizzSesion quizzSesion) {
        this.quizzSesion = quizzSesion;
    }

    @PostMapping("/quizz")
    String procesaEtapaX(Model modelo, Quizz sesion) {

        QuizzSesion actual = quizzSesion;

        if (quizzSesion.getNumEtapa() == null) {
            quizzSesion.setNumEtapa(1);
        }

        if (sesion.getNombre() != null) {
            actual.setNombre(sesion.getNombre());
        }
        if (sesion.getSigno() != null) {
            actual.setSigno(sesion.getSigno());
        }
        if (sesion.getAficciones() != null && !sesion.getAficciones().isEmpty()) {
            actual.setAficciones(sesion.getAficciones());
        }

        modelo.addAttribute("signos", SIGNOS);
        modelo.addAttribute("aficciones", AFICCIONES);
        modelo.addAttribute("quizz", actual);

        String errores = "";

        if (actual.getNumEtapa() == 1 && (actual.getNombre() == null || actual.getNombre().isBlank())) {
            errores = "Debes poner un nombre no vacío";
        } else if (actual.getNumEtapa() == 1 && (actual.getNombre().length() < 3 || actual.getNombre().length() > 10)) {
            errores = "La longitud del nombre debe estar entre 3 y 10";
        }

        if (actual.getNumEtapa() == 2 && (actual.getSigno() == null || actual.getSigno() == 0)) {
            errores = "Debes seleccionar un signo";
        }

        if (actual.getNumEtapa() == 3 && (actual.getAficciones() == null || actual.getAficciones().isEmpty())) {
            errores = "Debes elegir al menos una aficción, no seas soso/a";
        }

        if (!errores.isBlank()) {
            modelo.addAttribute("errores", errores);
            return "etapa" + actual.getNumEtapa();
        }

        actual.setNumEtapa(actual.getNumEtapa() + 1);

        if (actual.getNumEtapa() == 4) {
            ArrayList<String> respuestas = new ArrayList<String>();
            respuestas.add(actual.getNombre());
            respuestas.add(SIGNOS[actual.getSigno()]);
            respuestas.add(String.join(", ", actual.getAficciones()));
            modelo.addAttribute("respuestas", respuestas);
        }

        return "etapa" + actual.getNumEtapa();
    }

    @GetMapping("/quizz")
    String getEtapa0(Model modelo) {
        quizzSesion.setNumEtapa(1);
        quizzSesion.setNombre(null);
        quizzSesion.setSigno(null);
        quizzSesion.getAficciones().clear();
        modelo.addAttribute("quizz", quizzSesion);
        modelo.addAttribute("signos", SIGNOS);
        modelo.addAttribute("aficciones", AFICCIONES);
        return "etapa1";
    }
}
