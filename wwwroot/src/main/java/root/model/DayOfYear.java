package root.model;

import lombok.Getter;
import lombok.Setter;

import java.util.Objects;

@Getter
@Setter
public class DayOfYear {
    Integer year; // 0-99
    Integer day; // 0-365

    public DayOfYear(Integer year, Integer day) {
        this.year = year % 2000;
        this.day = day;
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
