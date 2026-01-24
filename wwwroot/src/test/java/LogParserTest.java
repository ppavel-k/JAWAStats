import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import root.model.CaddyLog;
import root.model.CounterStore;
import root.model.DayOfYear;
import root.model.DayOfYearBot;
import root.model.DayOfYearCode;
import root.model.DayOfYearHost;
import root.model.DayOfYearPage;
import root.model.DayOfYearReferer;
import root.model.MonthOfYear;
import root.model.Year;
import root.service.AggregateService;
import root.service.ParseService;
import root.util.Support;

import java.io.IOException;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static root.util.Support.interfaceToIp;

public class LogParserTest {


    @Test
    void parseLog() throws IOException, URISyntaxException {
        System.out.println("test");

        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());

        ParseService parseService = new ParseService(mapper);
        AggregateService aggregateService = new AggregateService();

        URL resource = getClass().getClassLoader().getResource("caddy.log");
        Path path = Path.of(resource.toURI());

        List<CaddyLog> caddyLogList;
        try (Stream<String> lines = Files.lines(path)) {
            caddyLogList = lines.skip(0)
                    .limit(256)
                    .map(line -> {
                        try {
                            CaddyLog caddyLog = parseService.parseLine(line);
                            aggregateService.process(caddyLog);
                            return caddyLog;
                        } catch (Exception e) {
                            return null; // Handle or log malformed lines
                        }
                    })
                    .filter(Objects::nonNull)
                    .toList();
        }

        assertEquals(97, caddyLogList.size());
        Map<DayOfYear, Integer> dayHitsPerYear = aggregateService.getDayOfYearHits().getHits();
        assertEquals(6, dayHitsPerYear.get(new DayOfYear(2025, 335)));

        Map<MonthOfYear, Integer> dayHitsPerMonthYear = aggregateService.getMonthOfYearHits().getHits();
        assertEquals(24, dayHitsPerMonthYear.get(new MonthOfYear(2025, 10)));

        Map<DayOfYearHost, Integer> hostHitsPerDayYear = aggregateService.getDayOfYearHostHits().getHits();
        assertEquals(6, hostHitsPerDayYear.get(new DayOfYearHost(2025, 11, Support.ipToInterface("44.255.130.211"))));

        Map<DayOfYearBot, Integer> botHitsPerDayYear = aggregateService.getDayOfYearBotHits().getHits();
        assertEquals(16, botHitsPerDayYear.get(new DayOfYearBot(2025, 305, "gptbot(at)openai.com")));

        Map<DayOfYearCode, Integer> responseCodePerDayYear = aggregateService.getDayOfYearResponseCode().getCodes();
        assertEquals(36, responseCodePerDayYear.get(new DayOfYearCode(2025, 9, 404)));

        Map<DayOfYearReferer, Integer> refererHitsPerDayYear = aggregateService.getDayOfYearRefererHits().getHits();
        assertEquals(1, refererHitsPerDayYear.get(new DayOfYearReferer(2025, 290, "https://vse.abamo.eu/0")));

        Map<DayOfYearPage, Integer> pageHitsPerDayYear = aggregateService.getDayOfYearPageHits().getHits();
        assertEquals(6, pageHitsPerDayYear.get(new DayOfYearPage(2025, 9, "/0")));

        System.out.println("found: " + caddyLogList.size());
    }

}
