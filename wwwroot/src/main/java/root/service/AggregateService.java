package root.service;

import lombok.Getter;
import lombok.Setter;
import org.springframework.stereotype.Service;
import root.model.DayOfYear;
import root.model.MonthOfYear;
import root.model.CaddyLog;
import root.model.Host;
import root.model.Year;

import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.HashMap;
import java.util.Map;

@Service
@Getter
@Setter
public class AggregateService {

    DayOfYearHits dayOfYearHits = new DayOfYearHits();
    MonthOfYearHits monthOfYearHits = new MonthOfYearHits();

    public void process(CaddyLog caddyLog) {

        ZonedDateTime zonedDateTime = caddyLog.getTs().atZone(ZoneId.systemDefault());
        dayOfYearHits.addHit(zonedDateTime.getYear(), zonedDateTime.getDayOfYear());
        monthOfYearHits.addHit(zonedDateTime.getYear(), zonedDateTime.getMonth().ordinal());
    }

    @Getter
    @Setter
    public static class DayOfYearHits {
        Map<DayOfYear, Integer> hits = new HashMap<>();

        public void addHit(Integer year, int dayOfYear) {
            hits.merge(new DayOfYear(year, dayOfYear), 1, Integer::sum);
        }
    }

    @Getter
    @Setter
    public static class MonthOfYearHits {
        Map<MonthOfYear, Integer> hits = new HashMap<>();

        public void addHit(int year, int month) {
            hits.merge(new MonthOfYear(year, month), 1, Integer::sum);
        }
    }

    @Getter
    @Setter
    public static class DayPerMonthHits {
        Map<Host, Integer> hostHit = new HashMap<>();

        public void addHit(Integer host, int dayOfYear) {
            hostHit.merge(new Host(host), 1, Integer::sum);
        }
    }


}
