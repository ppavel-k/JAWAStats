@import root.model.Report
@import root.model.view.Month
@import root.service.ReportService
@import java.time.LocalDate
@import java.util.Map

@param Report overview
@param Map<Integer, String> monthlyView

Weekly view
<table class="weeklyView">
    @for (Month month: overview.getYear().getMonths())
        <tr>
            <td colspan="7">
                <br/><br/><br/>
                ${month.getMonthName().getFullName()}
            </td>
        </tr>
        @for (int i = 0; i < month.getMonthWeeks().size(); i++)
            !{boolean isReported = false;}
            @for(Map.Entry<Integer, String> entry : monthlyView.entrySet())
                @if (entry.getKey().equals(month.getFirstWeekNumber() + i))
                    !{isReported = true;}
                    <tr>
                        $unsafe{entry.getValue()}
                    </tr>
                @endif
            @endfor
            @if (!isReported)
                <tr>
                    $unsafe{ReportService.getEmptyWeekGraph()}
                </tr>
            @endif
            <tr>
                @for (LocalDate day : month.getMonthWeeks().get(i))
                    <td align="right">
                        @if (day.getMonth().getValue() - 1 == month.getMonthName().ordinal())
                            <strong>${day.getDayOfMonth()}</strong>
                        @else
                            <span style="color: lightgrey">${day.getDayOfMonth()}</span>
                        @endif
                    </td>
                @endfor
            </tr>
        @endfor
    @endfor
</table>