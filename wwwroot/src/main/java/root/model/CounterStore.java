package root.model;

import lombok.Getter;
import lombok.Setter;

import java.util.HashMap;
import java.util.Map;

public class CounterStore {
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
    public static class DayOfYearHostHits {
        Map<DayOfYearHost, Integer> hits = new HashMap<>();

        public void addHit(Integer year, int dayOfYear, int host) {
            hits.merge(new DayOfYearHost(year, dayOfYear, host), 1, Integer::sum);
        }
    }

    @Getter
    @Setter
    public static class DayOfYearBotHits {
        Map<DayOfYearBot, Integer> hits = new HashMap<>();

        public void addHit(Integer year, int dayOfYear, String bot) {
            hits.merge(new DayOfYearBot(year, dayOfYear, bot), 1, Integer::sum);
        }
    }

    @Getter
    @Setter
    public static class DayOfYearRefererHits {
        Map<DayOfYearReferer, Integer> hits = new HashMap<>();

        public void addHit(Integer year, int dayOfYear, String referer) {
            hits.merge(new DayOfYearReferer(year, dayOfYear, referer), 1, Integer::sum);
        }
    }

    @Getter
    @Setter
    public static class DayOfYearPageHits {
        Map<DayOfYearPage, Integer> hits = new HashMap<>();

        public void addHit(Integer year, int dayOfYear, String page) {
            hits.merge(new DayOfYearPage(year, dayOfYear, page), 1, Integer::sum);
        }
    }

    @Getter
    @Setter
    public static class DayOfYearResponseCode {
        Map<DayOfYearCode, Integer> codes = new HashMap<>();

        public void addCode(Integer year, Integer dayOfYear, Integer code) {
            codes.merge(new DayOfYearCode(year, dayOfYear, code), 1, Integer::sum);
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
