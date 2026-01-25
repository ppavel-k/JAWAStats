package root.model.aggregation;

import lombok.Getter;
import lombok.Setter;

import java.util.Objects;

@Getter
@Setter
public class DayOfYearBot {
    Integer year; // 0-99
    Integer day; // 0-365
    String bot;

    public DayOfYearBot(Integer year, Integer day, String bot) {
        this.year = year % 2000;
        this.day = day;
        this.bot = bot;
    }

    @Override
    public boolean equals(Object o) {
        if (o == null || getClass() != o.getClass()) return false;
        DayOfYearBot that = (DayOfYearBot) o;
        return Objects.equals(year, that.year) && Objects.equals(day, that.day) && Objects.equals(bot, that.bot);
    }

    @Override
    public int hashCode() {
        return Objects.hash(year, day, bot);
    }
}
