@import root.model.Report
@import root.model.view.Month
@import java.util.Map

@param Report overview

<table class="monthlyView">
    <thead>
    <td></td>
    @for (Month month: overview.getYear().getMonths())
        <th>${month.getMonthName().getShortName()}</th>
    @endfor
    </thead>
    <tr>
        <td>Total hits:</td>
        @for (Month month: overview.getYear().getMonths())
            <td>
                ${overview.getAggregate().getMonthOfYearHits().getHits()
                        .entrySet().stream()
                        .filter(es ->
                            es.getKey().getMonth().equals(month.getMonthName().ordinal())
                            && es.getKey().getYear().equals(overview.getYear().getYear()))
                        .map(Map.Entry::getValue)
                        .findFirst().orElse(0)}
            </td>
        @endfor
    </tr>
    <tr>
        <td>Bot hits:</td>
        @for (Month month: overview.getYear().getMonths())
            <td>
                ${overview.getAggregate().getDayOfYearBotHits().getHits()
                        .entrySet().stream()
                        .filter(es ->
                            es.getKey().getMonth().equals(month.getMonthName().ordinal())
                            && es.getKey().getYear().equals(overview.getYear().getYear()))
                        .mapToInt(Map.Entry::getValue)
                        .sum()}
            </td>
        @endfor
    </tr>
    <tr>
        <td>Page hits:</td>
        @for (Month month: overview.getYear().getMonths())
            <td>
                ${overview.getAggregate().getDayOfYearPageHits().getHits()
                        .entrySet().stream()
                        .filter(es ->
                            es.getKey().getMonth().equals(month.getMonthName().ordinal())
                            && es.getKey().getYear().equals(overview.getYear().getYear()))
                        .mapToInt(Map.Entry::getValue)
                        .sum()}
            </td>
        @endfor
    </tr>
    <tr>
        <td>Asset hits:</td>
        @for (Month month: overview.getYear().getMonths())
            <td>
                ${overview.getAggregate().getDayOfYearAssetHits().getHits()
                        .entrySet().stream()
                        .filter(es ->
                            es.getKey().getMonth().equals(month.getMonthName().ordinal())
                            && es.getKey().getYear().equals(overview.getYear().getYear()))
                        .mapToInt(Map.Entry::getValue)
                        .sum()}
            </td>
        @endfor
    </tr>
</table>
