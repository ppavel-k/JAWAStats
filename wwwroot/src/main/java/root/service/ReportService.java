package root.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import root.model.Report;
import root.model.view.Year;

import java.io.IOException;
import java.nio.file.Path;
import java.time.LocalDate;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.random.RandomGenerator;
import java.util.stream.Collectors;

import static java.lang.Math.round;
import static java.util.Arrays.stream;

@Service
@RequiredArgsConstructor
public class ReportService {

    private final AggregateService aggregateService;
    private final ParseService parseService;

    public Report getOverview(int currentYearValue1) {

        Year currentYear = new Year(currentYearValue1);

        Path logFilePath = Path.of("wwwroot/src/test/resources/caddy.log");
        System.out.println("Will process log file " + logFilePath);

        try {
            parseService.doParse(logFilePath);
            return new Report(currentYear, aggregateService);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    public String getPerMonth(int currentYearValue) {
        int[] scaled = stream(getSevenDays()).map(x -> (int) round(((x - 1) * 15.0 / 127.0) + 1)).toArray();
        AtomicInteger i = new AtomicInteger(0);
        String data = stream(scaled).mapToObj(s ->
        {
            int height = s * 10;
            String style = String.format("style='height:%dpx; background-color:%s; color:white;" +
                    "display:inline-block; width:25px; margin:2px; vertical-align:bottom;" +
                    "text-align:center;font-family:Arial'", height, getColors(i.getAndIncrement()));
            return "<td " + style + ">" + s + "</td>";
        }).collect(Collectors.joining(""));
        return data;
    }

    private String getColors(int i) {
        String[] colors = {"5d5fef", "4ecdc4", "6bcb77", "ff8066", "ffd93d", "ff6b6b", "a29bfe"};
        return "#" + colors[i];
    }

    private int[] getSevenDays() {
        return RandomGenerator.getDefault()
                .ints(7, 0, 129) // 7 numbers, from 0 (inclusive) to 129 (exclusive)
                .toArray();
    }
}
