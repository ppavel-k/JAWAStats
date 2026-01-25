package root.model.view;

import lombok.Getter;

import java.time.LocalDate;
import java.time.YearMonth;
import java.time.temporal.WeekFields;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

@Getter
public class Month {

    MonthName monthName;
    List<List<LocalDate>> monthWeeks;

    /**
     *
     * @param year like 2025
     * @param monthNumber 0-11
     */
    public Month(Integer year, Integer monthNumber) {
        this.monthName = MonthName.values()[monthNumber];

        LocalDate start = YearMonth.of(year, monthNumber + 1).atDay(1);
        LocalDate end = start.plusMonths(1);

        WeekFields weekFields = WeekFields.of(Locale.FRANCE);

        Collection<List<LocalDate>> weeks = start.datesUntil(end)
                .collect(Collectors.groupingBy(
                        date -> date.get(weekFields.weekOfMonth()), // Group by week number in month
                        LinkedHashMap::new,                         // Preserve calendar order
                        Collectors.toList()
                ))
                .values();

        // Convert to a List of Lists
        monthWeeks = new ArrayList<>(weeks);

        List<LocalDate> firstWeek = monthWeeks.getFirst();
        int daysToHeader = 7 - firstWeek.size();

        for (int i = 0; i < daysToHeader; i++) {
            // Always subtract 1 from the current start of the week
            firstWeek.addFirst(firstWeek.getFirst().minusDays(1));
        }
    }
}
