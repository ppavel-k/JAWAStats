package root.model;

import lombok.Getter;
import lombok.Setter;

import java.util.Objects;

@Getter
@Setter
public class Year {
    Integer year; // 0-99

    public Year(Integer year) {
        this.year = year;
    }

    @Override
    public boolean equals(Object o) {
        if (o == null || getClass() != o.getClass()) return false;
        Year year1 = (Year) o;
        return Objects.equals(year, year1.year);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(year);
    }
}
