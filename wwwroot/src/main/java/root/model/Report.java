package root.model;

import lombok.Getter;
import lombok.RequiredArgsConstructor;
import root.model.view.Year;import root.service.AggregateService;

import java.util.List;

@RequiredArgsConstructor
@Getter
public class Report {
    private final Year year;
    private final AggregateService aggregate;
}
