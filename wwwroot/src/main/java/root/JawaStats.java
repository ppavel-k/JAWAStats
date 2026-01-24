package root;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.security.servlet.SecurityAutoConfiguration;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;
import org.springframework.context.annotation.Import;
import root.configuration.ContextConfiguration;

@SpringBootApplication(exclude = {SecurityAutoConfiguration.class})
@Import({ContextConfiguration.class})
public class JawaStats extends SpringBootServletInitializer {
    public static void main(String[] args) {
        SpringApplication.run(JawaStats.class, args);
    }
}