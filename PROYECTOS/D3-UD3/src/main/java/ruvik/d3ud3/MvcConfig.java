package ruvik.d3ud3;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
class MvcConfig implements WebMvcConfigurer {

    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        registry.addViewController("/home").setViewName("casa");
        registry.addViewController("/").setViewName("casa");
        registry.addViewController("/hello").setViewName("hola");
        registry.addViewController("/login").setViewName("login");
    }

}