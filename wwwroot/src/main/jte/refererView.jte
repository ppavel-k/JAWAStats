@import root.model.Report
@import root.model.aggregation.DayOfYearReferer
@import root.model.view.Month
@import root.service.ReportService
@import java.time.LocalDate
@import java.util.Map

@param Report overview
@param Map<Integer, String> monthlyView

Referer view
<table class="refererView">
    @for (Month month: overview.getYear().getMonths())
        <tr>
            <td>
                <br/><br/><br/>
                ${month.getMonthName().getFullName()}
            </td>
        </tr>
        <tr>
            <td>
                @for (Map.Entry<DayOfYearReferer, Integer> entry : overview.getAggregate().getDayOfYearRefererHits().getHits().entrySet())
                    @if (entry.getKey().getYear() == overview.getYear().getYear() && entry.getKey().getMonth() == month.getMonthName().ordinal())
                        ${entry.getKey().getReferer()} : ${entry.getValue()}<br/>
                    @endif
                @endfor
            </td>
        </tr>
    @endfor
</table>