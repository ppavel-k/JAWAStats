package root.model.aggregation;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.util.Objects;

@Getter
@Setter
public class DayOfYearPage {
    Integer year; // 0-99
    Integer day; // 0-365
    Integer month; // 0-11
    String page;

    public DayOfYearPage(Integer year, Integer day, String page) {
        this.year = year % 2000;
        this.day = day;
        this.page = page;
        this.month = LocalDate.ofYearDay(year, day).getMonthValue() - 1;
    }

    @Override
    public boolean equals(Object o) {
        if (o == null || getClass() != o.getClass()) return false;
        DayOfYearPage that = (DayOfYearPage) o;
        return Objects.equals(year, that.year) && Objects.equals(day, that.day) && Objects.equals(page, that.page);
    }

    @Override
    public int hashCode() {
        return Objects.hash(year, day, page);
    }
}
