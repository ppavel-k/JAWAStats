package root.model.aggregation;

import lombok.Getter;
import lombok.Setter;

import java.util.Objects;

@Getter
@Setter
public class DayOfYearHost {
    Integer year; // 0-99
    Integer day; // 0-365
    Integer host; // 0-255.0-255.0-255.0-255

    public DayOfYearHost(Integer year, Integer day, Integer host) {
        this.year = year % 2000;
        this.day = day;
        this.host = host;
    }

    @Override
    public boolean equals(Object o) {
        if (o == null || getClass() != o.getClass()) return false;
        DayOfYearHost that = (DayOfYearHost) o;
        return Objects.equals(year, that.year) && Objects.equals(day, that.day) && Objects.equals(host, that.host);
    }

    @Override
    public int hashCode() {
        return Objects.hash(year, day, host);
    }
}
