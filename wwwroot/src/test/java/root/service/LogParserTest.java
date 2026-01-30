package root.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.Test;
import root.model.CaddyLog;
import root.model.aggregation.DayOfYear;
import root.model.aggregation.DayOfYearBot;
import root.model.aggregation.DayOfYearCode;
import root.model.aggregation.DayOfYearHost;
import root.model.aggregation.DayOfYearPage;
import root.model.aggregation.DayOfYearReferer;
import root.model.aggregation.MonthOfYear;
import root.util.Support;

import java.io.IOException;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;

public class LogParserTest {

    @Test
    void parseLog() throws IOException, URISyntaxException {
        System.out.println("test");

        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());

        AggregateService aggregateService = new AggregateService();
        ParseService parseService = new ParseService(mapper, aggregateService);

        URL resource = getClass().getClassLoader().getResource("caddy.log");
        Path path = Path.of(resource.toURI());

        List<CaddyLog> caddyLogList = parseService.processLog(path);

        assertEquals(97, caddyLogList.size());
        Map<DayOfYear, Integer> dayHitsPerYear = aggregateService.getDayOfYearHits().getHits();
        assertEquals(6, dayHitsPerYear.get(new DayOfYear(2025, 335)));

        Map<MonthOfYear, Integer> dayHitsPerMonthYear = aggregateService.getMonthOfYearHits().getHits();
        assertEquals(24, dayHitsPerMonthYear.get(new MonthOfYear(2025, 10)));

        Map<DayOfYearHost, Integer> hostHitsPerDayYear = aggregateService.getDayOfYearAllHostHits().getHits();
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
