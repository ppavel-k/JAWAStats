package root.service;

import org.junit.jupiter.api.Test;
import root.model.view.Month;
import root.model.view.Year;

import java.time.LocalDate;

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
