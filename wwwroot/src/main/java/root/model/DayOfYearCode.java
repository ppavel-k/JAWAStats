package root.model;

import lombok.Getter;
import lombok.Setter;

import java.util.Objects;

@Getter
@Setter
public class DayOfYearCode {
    Integer year; // 0-99
    Integer day; // 0-365
    Integer code;

    public DayOfYearCode(Integer year, Integer day, Integer code) {
        this.year = year % 2000;
        this.day = day;
        this.code = code;
    }

    @Override
    public boolean equals(Object o) {
        if (o == null || getClass() != o.getClass()) return false;
        DayOfYearCode that = (DayOfYearCode) o;
        return Objects.equals(year, that.year) && Objects.equals(day, that.day) && Objects.equals(code, that.code);
    }

    @Override
    public int hashCode() {
        return Objects.hash(year, day, code);
    }
}
