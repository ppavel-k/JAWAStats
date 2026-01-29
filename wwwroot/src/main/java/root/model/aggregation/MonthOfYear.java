package root.model.aggregation;

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
        MonthOfYear that = (MonthOfYear) o;
        return Objects.equals(year, that.year) && Objects.equals(month, that.month);
    }

    @Override
    public int hashCode() {
        return Objects.hash(year, month);
    }
}
