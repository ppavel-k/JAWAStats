package root.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import root.model.Report;
import root.model.view.Year;

import java.io.IOException;
import java.nio.file.Path;
import java.time.LocalDate;

@Service
@RequiredArgsConstructor
public class ReportService {

    private final AggregateService aggregateService;
    private final ParseService parseService;

    public Report getOverview(int currentYearValue1) {

        Year currentYear = new Year(currentYearValue1);

        Path logFilePath = Path.of("wwwroot/src/test/resources/caddy.log");
        System.out.println("Will process log file " + logFilePath);

        try {
            parseService.doParse(logFilePath);
            return new Report(currentYear, aggregateService);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

}
