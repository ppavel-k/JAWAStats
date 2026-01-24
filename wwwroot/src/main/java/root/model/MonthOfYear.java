package root.model;

import lombok.Getter;
import lombok.Setter;

import java.util.Objects;

@Getter
@Setter
public class MonthOfYear {
    Integer year; // 0-99
    Integer month; // 0-11

    public MonthOfYear(Integer year, Integer month) {
        this.year = year % 2000;
        this.month = month;
    }

    @Override
    public boolean equals(Object o) {
        if (o == null || getClass() != o.getClass()) return false;
        MonthOfYear month1 = (MonthOfYear) o;
        return Objects.equals(year, month1.year) && Objects.equals(month, month1.month);
    }

    @Override
    public int hashCode() {
        return Objects.hash(year, month);
    }
}
