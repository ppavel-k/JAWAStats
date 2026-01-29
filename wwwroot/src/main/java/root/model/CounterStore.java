package root.model;

import lombok.Getter;
import lombok.Setter;
import root.model.aggregation.DayOfYear;
import root.model.aggregation.DayOfYearBot;
import root.model.aggregation.DayOfYearCode;
import root.model.aggregation.DayOfYearHost;
import root.model.aggregation.DayOfYearPage;
import root.model.aggregation.DayOfYearReferer;
import root.model.aggregation.MonthOfYear;

import java.util.HashMap;
import java.util.Map;

public class CounterStore {
    @Getter
    @Setter
    public static class DayOfYearHits {
        Map<DayOfYear, Integer> hits = new HashMap<>();

        public Integer addHit(Integer year, int dayOfYear) {
            DayOfYear key = new DayOfYear(year, dayOfYear);
            return hits.merge(key, 1, Integer::sum);
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

}
