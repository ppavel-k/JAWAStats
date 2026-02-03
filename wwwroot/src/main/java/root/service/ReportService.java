package root.service;

import jakarta.annotation.Nonnull;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import root.model.Report;
import root.model.aggregation.DayOfYear;
import root.model.view.Year;

import java.io.IOException;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

import static java.lang.Math.round;
import static java.util.Arrays.stream;

@Service
@RequiredArgsConstructor
public class ReportService {

    private final AggregateService aggregateService;
    private final ParseService parseService;

    public Report getOverview(int currentYearValue) {

        Year currentYear = new Year(currentYearValue);

        Path logFilePath = Path.of("wwwroot/src/test/resources/access.log");
        System.out.println("Will process log file " + logFilePath);

        try {
            parseService.doParse(logFilePath);
            return new Report(currentYear, aggregateService);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    public Map<Integer, String> getWeeklyGraph(int year) {

        Map<Integer, String> weekDistribution = new HashMap<>();

        Map<DayOfYear, Integer> hits = aggregateService.getDayOfYearHits().getHits();
        Map<Integer, WeekValues> weeks = groupDaysByWeek(year % 2000, hits);

        for (Map.Entry<Integer, WeekValues> entry: weeks.entrySet()) {
            String data = getWeekGraph(entry.getValue().getValues());
            weekDistribution.put(entry.getKey(), data);
        }
        return weekDistribution;
    }

    public static String getEmptyWeekGraph() {
        return getWeekGraph(new int[] {0, 0, 0, 0, 0, 0, 0});
    }

    @Nonnull
    private static String getWeekGraph(int[] values) {
        long max = Integer.toUnsignedLong(stream(values).max().orElse(0));
        int[] scaled = stream(values).map(x -> x < 1 ? 1 : (int) round(((x - 1) * 15.0 / max) + 1)).toArray();
        AtomicInteger i = new AtomicInteger(0);
        return stream(scaled).mapToObj(s -> {
            int height = max == 0 || values[i.get()] == 0 ? 1 : s * 5;
            String style = String.format("style='height:%dpx; background-color:%s; color:white;" +
                    "display:block; width:50px; margin:0px; padding-bottom: 2px;" +
                    "text-align:center;font-family:Arial'", height, getColors(i.get()));
            String result = "<td style='vertical-align:bottom; text-align: center;'>" + (values[i.get()] == 0 ? "" : values[i.get()]) +
                    "<div " + style + "></div></td>";
            i.incrementAndGet();
            return result;
        }).collect(Collectors.joining(""));
    }

    private Map<Integer, WeekValues> groupDaysByWeek(int year, Map<DayOfYear, Integer> hits) {

        Map<Integer, WeekValues> weekView = new HashMap<>();

        hits.forEach((date, count) -> {
            if (year != date.getYear()) {
                return;
            }

            int weekNumber = date.getWeekNumber();
            weekView.putIfAbsent(weekNumber, new WeekValues());
            weekView.get(weekNumber).set(date.getDayOfWeekNumber(), count);
        });
        return weekView;
    }

    private static String getColors(int i) {
        String[] colors = {"5d5fef", "4ecdc4", "6bcb77", "ff8066", "ffd93d", "ff6b6b", "a29bfe"};
        return "#" + colors[i];
    }

    @Getter
    private static class WeekValues {
        int[] values = new int[7];

        public void set(int dayNum, int value) {
            values[dayNum] = value;
        }

    }
}
