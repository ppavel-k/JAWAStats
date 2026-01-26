package root.configuration;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gg.jte.CodeResolver;
import gg.jte.ContentType;
import gg.jte.TemplateEngine;
import gg.jte.resolve.DirectoryCodeResolver;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import root.service.ReportService;

import java.nio.file.Paths;

@Configuration
@Import({ReportService.class})
public class ContextConfiguration {

    @Bean
    public TemplateEngine templateEngine() {
        // Toggle this based on your environment (e.g., profiles)
        boolean isDevMode = true;

        if (isDevMode) {
            // Development: Use DirectoryCodeResolver for hot-reloading
            CodeResolver codeResolver = new DirectoryCodeResolver(Paths.get("wwwroot/src/main/jte"));
            return TemplateEngine.create(codeResolver, Paths.get("jte-classes"), ContentType.Html);
        } else {
            // Production: Use precompiled templates for maximum performance
            return TemplateEngine.createPrecompiled(ContentType.Html);
        }
    }

    @Bean
    public ObjectMapper objectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());
        return mapper;
    }

}
