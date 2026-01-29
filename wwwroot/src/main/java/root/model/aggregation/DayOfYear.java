package root.model.aggregation;

import lombok.Getter;
import lombok.Setter;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.WeekFields;
import java.util.Locale;
import java.util.Objects;

@Getter
@Setter
public class DayOfYear {
    Integer year; // 0-99
    Integer day; // 0-365
    LocalDate date;
    int dayOfWeekNumber;
    int weekNumber;

    public DayOfYear(Integer year, Integer day) {
        this.year = year % 2000;
        this.day = day;
        this.date = LocalDate.ofYearDay(year, day);
        this.dayOfWeekNumber = date.getDayOfWeek().getValue() - 1;
        WeekFields weekFields = WeekFields.of(Locale.getDefault());
        this.weekNumber = date.get(weekFields.weekOfWeekBasedYear());
    }

    @Override
    public boolean equals(Object o) {
        if (o == null || getClass() != o.getClass()) return false;
        DayOfYear year1 = (DayOfYear) o;
        return Objects.equals(year, year1.year) && Objects.equals(day, year1.day);
    }

    @Override
    public int hashCode() {
        return Objects.hash(year, day);
    }
}
