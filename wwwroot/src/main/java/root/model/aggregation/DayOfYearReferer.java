package root.model.aggregation;

import lombok.Getter;
import lombok.Setter;

import java.util.Objects;

@Getter
@Setter
public class DayOfYearReferer {
    Integer year; // 0-99
    Integer day; // 0-365
    String referer;

    public DayOfYearReferer(Integer year, Integer day, String referer) {
        this.year = year % 2000;
        this.day = day;
        this.referer = referer;
    }

    @Override
    public boolean equals(Object o) {
        if (o == null || getClass() != o.getClass()) return false;
        DayOfYearReferer that = (DayOfYearReferer) o;
        return Objects.equals(year, that.year) && Objects.equals(day, that.day) && Objects.equals(referer, that.referer);
    }

    @Override
    public int hashCode() {
        return Objects.hash(year, day, referer);
    }
}
