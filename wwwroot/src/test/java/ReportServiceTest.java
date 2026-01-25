import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.Test;
import root.model.CaddyLog;
import root.model.MonthOfYear;
import root.model.aggregation.DayOfYear;
import root.model.aggregation.DayOfYearBot;
import root.model.aggregation.DayOfYearCode;
import root.model.aggregation.DayOfYearHost;
import root.model.aggregation.DayOfYearPage;
import root.model.aggregation.DayOfYearReferer;
import root.model.view.Month;
import root.model.view.Year;
import root.service.AggregateService;
import root.service.ParseService;
import root.service.ReportService;
import root.util.Support;

import java.io.IOException;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.assertEquals;

public class ReportServiceTest {


    @Test
    void prepareReport() {
        System.out.println("test2");

        // ReportService reportService = new ReportService(null);

        Month january = new Month(2026, 0);

        Year y2025 = new Year(2025);

        LocalDate firstDay = january.getMonthWeeks().getFirst().getFirst();
        int firstDayDate = firstDay.getDayOfMonth() * 1000000 + firstDay.getMonthValue() * 10000 + firstDay.getYear();
        assertEquals(29122025, firstDayDate);

        LocalDate firstDayInDecember2025 = y2025.getMonths()[11].getMonthWeeks().getFirst().getFirst();
        int firstDayInDecemberWeek2025 = firstDayInDecember2025.getDayOfMonth() * 1000000 + firstDayInDecember2025.getMonthValue() * 10000 + firstDayInDecember2025.getYear();
        assertEquals(1122025, firstDayInDecemberWeek2025);

        System.out.println(january);

    }

}
