@import root.model.Report
@import root.model.view.Month
@import java.util.Map

@param Report overview

@template.mainLayout(
centralViewPort = @`

    <div class="col s12">
        <h5 style="text-align: right; padding-right: 4%;">Stat</h5>
    </div>

    <div class="container" style="margin-left: 3%;">
        <div class="masonry row">

            Available years:
            <table>
                <tr>
                    @for(Integer year : overview.getAggregate().getMonthOfYearHits().getHits()
                            .entrySet().stream()
                            .map(es -> es.getKey().getYear())
                            .distinct()
                            .toList())
                        <td><a href="/year/20${year}">20${year}</a></td>
                    @endfor
                </tr>
            </table>

            <br/><br/><br/>

            Total hits:
            <table>
                <thead>
                @for (Month month: overview.getYear().getMonths())
                    <th>${month.getMonthName().getShortName()}</th>
                @endfor
                </thead>
                <tr>
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
            </table>

        </div>

    </div>
`
)

