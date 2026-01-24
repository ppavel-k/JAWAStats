import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import root.model.CaddyLog;
import root.service.ParseService;

import java.io.IOException;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class LogParserTest {


    @Test
    void parseLog() throws IOException, URISyntaxException {
        System.out.println("test");

        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());

        ParseService parseService = new ParseService(mapper);

        URL resource = getClass().getClassLoader().getResource("caddy.log");
        Path path = Path.of(resource.toURI());

        List<CaddyLog> caddyLogList;
        try (Stream<String> lines = Files.lines(path)) {
            caddyLogList = lines.skip(0)
                    .limit(256)
                    .map(line -> {
                        try {
                            return parseService.parseLine(line);
                        } catch (Exception e) {
                            return null; // Handle or log malformed lines
                        }
                    })
                    .filter(Objects::nonNull)
                    .toList();
        }

        Assertions.assertEquals(97, caddyLogList.size());
        System.out.println("found: " + caddyLogList.size());
    }

}
