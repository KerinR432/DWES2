package goya.daw2.pruebas_plantillas;

import java.util.ArrayList;

import entity.Quizz;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.CookieValue;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletResponse;

@Controller
public class FormsController {

	static final String[] SIGNOS = { "", "Aries", "Tauro", "Géminis", "Cáncer", "Leo", "Virgo", "Libra", "Escorpio",
			"Sagitario", "Capricornio", "Acuario", "Piscis" };
	static final String[] AFICCIONES = { "Deportes", "Juerga", "Lectura", "Relaciones sociales" };

	@PostMapping("/")
	String procesaEtapaX(@RequestParam(name = "numEtapa") Integer numEtapa,
                         Model modelo,
                         Quizz quizz,
                         HttpSession session) {

        Quizz actual = (Quizz) session.getAttribute("quizz");
        if (actual == null) {
            actual = new Quizz();
        }
        System.out.println(actual);


		if (numEtapa == null) {
            return "etapa1";
        }
		if (quizz.getNombre() != null) {
            System.out.println("soy Nombre: " + quizz.getNombre());
			actual.setNombre(quizz.getNombre());
		}
        if(quizz.getSigno()!= null ) {
            System.out.println("soy Signo: " + quizz.getSigno());
            actual.setSigno(quizz.getSigno());
        }
        if(quizz.getAficciones()!=null) {
            System.out.println("soy Aficionado: " + quizz.getAficciones());
            actual.setAficciones(quizz.getAficciones());
        }

		modelo.addAttribute("signos", SIGNOS);
		modelo.addAttribute("aficciones", AFICCIONES);

		if (quizz.getSigno() != null) {
			modelo.addAttribute("signo", quizz.getSigno());
		}

		String errores = "";

		if (numEtapa == 1 && (quizz.getNombre() == null || quizz.getNombre().isBlank())) {
			errores = "Debes poner un nombre no vacío";
		} else if (numEtapa == 1 && (quizz.getNombre().length() < 3 || quizz.getNombre().length() > 10)) {
			errores = "La longitud del nombre debe estar entre 3 y 10";
		}

		if (numEtapa == 2 && (quizz.getSigno() == null || quizz.getSigno().equals("0"))) {
			errores = "Debes seleccionar un signo";
		}

		if (numEtapa == 3 && (quizz.getAficciones() == null || quizz.getAficciones().isBlank())) {
			errores = "Debes elegir al menos una aficción, no seas soso/a";
		}

		if (!errores.isBlank()) {
			modelo.addAttribute("errores", errores);
			modelo.addAttribute("numEtapa", numEtapa);
			return "etapa" + numEtapa;
		}

		numEtapa++;

		modelo.addAttribute("numEtapa", numEtapa);

        session.setAttribute("quizz",actual);

		if (numEtapa == 4) {
			ArrayList<String> respuestas = new ArrayList<String>();
			respuestas.add(actual.getNombre());
			respuestas.add(SIGNOS[(actual.getSigno())]);
			respuestas.add(actual.getAficciones());
			modelo.addAttribute("respuestas", respuestas);
		}

		return "etapa" + numEtapa;
	}

	@GetMapping("/")
	String getEtapa0(HttpSession sesion) {
        @SuppressWarnings("unchecked")
        Quizz quizz = (Quizz) sesion.getAttribute("quizz");
		return "etapa1";
	}

}
