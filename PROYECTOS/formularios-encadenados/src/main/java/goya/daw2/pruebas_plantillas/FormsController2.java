package goya.daw2.pruebas_plantillas;

import java.util.ArrayList;
import java.util.List;

import entity.Quizz;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@SessionAttributes("quizz")
@RequestMapping("/version2")
public class FormsController2 {

    static final String[] SIGNOS = { "", "Aries", "Tauro", "Géminis", "Cáncer", "Leo", "Virgo", "Libra", "Escorpio",
            "Sagitario", "Capricornio", "Acuario", "Piscis" };
    static final String[] AFICCIONES = { "Deportes", "Juerga", "Lectura", "Relaciones sociales" };


    @PostMapping("/quizz")
    String procesaEtapaX(Model modelo,
                         Quizz quizz) {

        Quizz actual = quizz;

        if (actual.getNumEtapa() == null) {
            actual.setNumEtapa(1);
        }

        if (quizz.getNombre() != null) {
            actual.setNombre(quizz.getNombre());
        }
        if (quizz.getSigno() != null) {
            actual.setSigno(quizz.getSigno());
        }
        if (quizz.getAficciones() != null && !quizz.getAficciones().isEmpty()) {
            actual.setAficciones(quizz.getAficciones());
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
        modelo.addAttribute("numEtapa", actual.getNumEtapa());

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
    String getEtapa0(Quizz quizz,Model modelo) {
        Quizz nuevo = new Quizz();
        nuevo.setNumEtapa(1);
        modelo.addAttribute("quizz", nuevo);
        modelo.addAttribute("signos", SIGNOS);
        modelo.addAttribute("aficciones", AFICCIONES);
        return "etapa1";
    }
}
