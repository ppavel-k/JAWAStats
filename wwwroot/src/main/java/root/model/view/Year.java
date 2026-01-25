package root.model.view;

import lombok.Getter;
import lombok.Setter;

import java.util.Arrays;
import java.util.List;

@Getter
@Setter
public class Year {

    Integer year;
    Month[] months = new Month[12];
    List<WeekDayName> weekDayNames;

    public Year(Integer year) {
        this.year = year % 2000;
        Arrays.stream(MonthName.values()).forEach(
                month -> {
                    months[month.ordinal()] = new Month(year, month.ordinal());
                }
        );
    }

}
