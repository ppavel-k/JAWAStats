@import root.model.Report
@import root.model.view.Month
@import root.service.ReportService
@import java.time.LocalDate
@import java.time.format.DateTimeFormatter
@import java.util.Map
@import java.util.stream.Collectors

@param Report overview
@param Map<Integer, String> monthlyView

@template.mainLayout(
centralViewPort = @`

    <div class="col s12">
        <h5 style="text-align: right; padding-right: 4%;">Last processed date ${overview.getAggregate().getLastProcessedLineDateTime().format(DateTimeFormatter.ofPattern("dd-MM-yyyy"))}</h5>
    </div>

    <div class="container" style="margin-left: 3%;">
        <div class="masonry row">
            <h2>Site(s): ${String.join(", ", overview.getAggregate().getHosts())}</h2>
            <hr/>
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

            @template.monthlyView(overview = overview)

            <br/><br/><br/>
            @template.weeklyView(overview = overview, monthlyView = monthlyView)

            <br/><br/><br/>
            @template.refererView(overview = overview, monthlyView = monthlyView)

        </div>

    </div>
`
)

