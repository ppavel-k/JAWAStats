package root.service;

import lombok.Getter;
import lombok.Setter;
import org.springframework.stereotype.Service;
import root.model.CounterStore;
import root.model.CaddyLog;
import root.util.Support;

import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.List;

@Service
@Getter
@Setter
public class AggregateService {

    CounterStore.DayOfYearHits dayOfYearHits = new CounterStore.DayOfYearHits();
    CounterStore.MonthOfYearHits monthOfYearHits = new CounterStore.MonthOfYearHits();

    CounterStore.DayOfYearHostHits dayOfYearHostHits = new CounterStore.DayOfYearHostHits();
    CounterStore.DayOfYearBotHits dayOfYearBotHits = new CounterStore.DayOfYearBotHits();
    CounterStore.DayOfYearResponseCode dayOfYearResponseCode = new CounterStore.DayOfYearResponseCode();

    CounterStore.DayOfYearRefererHits dayOfYearRefererHits = new CounterStore.DayOfYearRefererHits();

    CounterStore.DayOfYearPageHits dayOfYearPageHits = new CounterStore.DayOfYearPageHits();


    public void process(CaddyLog caddyLog) {

        ZonedDateTime zonedDateTime = caddyLog.getTs().atZone(ZoneId.systemDefault());
        dayOfYearHits.addHit(zonedDateTime.getYear(), zonedDateTime.getDayOfYear());
        monthOfYearHits.addHit(zonedDateTime.getYear(), zonedDateTime.getMonth().ordinal());
        dayOfYearResponseCode.addCode(zonedDateTime.getYear(), zonedDateTime.getMonth().ordinal(), caddyLog.status);

        if (caddyLog.getRequest() != null) {
            dayOfYearPageHits.addHit(zonedDateTime.getYear(), zonedDateTime.getMonth().ordinal(), caddyLog.getRequest().uri);
            dayOfYearHostHits.addHit(zonedDateTime.getYear(), zonedDateTime.getMonth().ordinal(), Support.ipToInterface(caddyLog.getRequest().remoteIp));

            if (caddyLog.getRequest().headers != null) {
                List<String> from = caddyLog.getRequest().headers.get("From");
                if (from != null && !from.isEmpty()) {
                    dayOfYearBotHits.addHit(zonedDateTime.getYear(), zonedDateTime.getDayOfYear(), from.getFirst());
                }

                List<String> referer = caddyLog.getRequest().headers.get("Referer");
                if (referer != null && !referer.isEmpty()) {
                    dayOfYearRefererHits.addHit(zonedDateTime.getYear(), zonedDateTime.getDayOfYear(), referer.getFirst());
                }

            }
        }

    }


}
