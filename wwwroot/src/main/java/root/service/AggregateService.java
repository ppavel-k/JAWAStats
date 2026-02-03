package root.service;

import lombok.Getter;
import lombok.Setter;
import org.springframework.stereotype.Service;
import root.model.CounterStore;
import root.model.CaddyLog;
import root.util.Support;

import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
@Getter
@Setter
public class AggregateService {

    int maxHitsValue = 0;

    ZonedDateTime lastProcessedLineDateTime = null;

    Set<String> hosts = new HashSet<>();

    CounterStore.DayOfYearHits dayOfYearHits = new CounterStore.DayOfYearHits();
    CounterStore.MonthOfYearHits monthOfYearHits = new CounterStore.MonthOfYearHits();

    CounterStore.DayOfYearHostHits dayOfYearHostHits = new CounterStore.DayOfYearHostHits();
    CounterStore.DayOfYearHostHits dayOfYearAllHostHits = new CounterStore.DayOfYearHostHits();
    CounterStore.DayOfYearBotHits dayOfYearBotHits = new CounterStore.DayOfYearBotHits();
    CounterStore.DayOfYearResponseCode dayOfYearResponseCode = new CounterStore.DayOfYearResponseCode();

    CounterStore.DayOfYearRefererHits dayOfYearRefererHits = new CounterStore.DayOfYearRefererHits();
    CounterStore.DayOfYearPageHits dayOfYearPageHits = new CounterStore.DayOfYearPageHits();
    CounterStore.DayOfYearPageHits dayOfYearAssetHits = new CounterStore.DayOfYearPageHits();

    public void process(CaddyLog caddyLog) {

        ZonedDateTime zonedDateTime = caddyLog.getTs().atZone(ZoneId.systemDefault());

        if (lastProcessedLineDateTime != null && !zonedDateTime.isAfter(lastProcessedLineDateTime)) {
            // System.out.println("skip");
            return;
        }

        lastProcessedLineDateTime = zonedDateTime;

        hosts.add(caddyLog.getRequest().host);

        Integer hitCount = dayOfYearHits.addHit(zonedDateTime.getYear(), zonedDateTime.getDayOfYear());
        // TODO: Split by year
        if (hitCount < maxHitsValue) {
            maxHitsValue = hitCount;
        }

        monthOfYearHits.addHit(zonedDateTime.getYear(), zonedDateTime.getMonth().ordinal());
        dayOfYearResponseCode.addCode(zonedDateTime.getYear(), zonedDateTime.getMonth().ordinal(), caddyLog.status);

        if (caddyLog.getRequest() != null && caddyLog.getStatus() == 200) {
            String uri = caddyLog.getRequest().uri;
            dayOfYearAssetHits.addHit(zonedDateTime.getYear(), zonedDateTime.getDayOfYear() - 1, uri);

            if (uri.endsWith(".htm") || uri.endsWith(".html")) {
                dayOfYearPageHits.addHit(zonedDateTime.getYear(), zonedDateTime.getDayOfYear() - 1, uri);
            }
            dayOfYearAllHostHits.addHit(zonedDateTime.getYear(), zonedDateTime.getDayOfYear() - 1, Support.ipToInterface(caddyLog.getRequest().remoteIp));

            if (caddyLog.getRequest().headers != null) {
                List<String> from = caddyLog.getRequest().headers.get("From");
                if (from != null && !from.isEmpty()) {
                    dayOfYearBotHits.addHit(zonedDateTime.getYear(), zonedDateTime.getDayOfYear() - 1, from.getFirst());
                } else {
                    dayOfYearHostHits.addHit(zonedDateTime.getYear(), zonedDateTime.getDayOfYear() - 1, Support.ipToInterface(caddyLog.getRequest().remoteIp));
                }

                List<String> referer = caddyLog.getRequest().headers.get("Referer");
                if (referer != null && !referer.isEmpty() && !referer.getFirst().contains(caddyLog.getRequest().host)) {
                    dayOfYearRefererHits.addHit(zonedDateTime.getYear(), zonedDateTime.getDayOfYear() - 1, referer.getFirst());
                }

            }

            // add search engines: Bing, Google, Seznam
            // add search phrases
            // add browsers
            // add browser languages
        } else {
            // todo: add missing resource count
        }

    }


}
