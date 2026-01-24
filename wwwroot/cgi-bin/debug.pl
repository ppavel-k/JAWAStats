# Print AWStats and Perl version
if ($Debug) {
    debug(ucfirst($PROG) . " - $VERSION - Perl $^X $]", 1);
    debug("DIR=$DIR PROG=$PROG Extension=$Extension", 2);
    debug("QUERY_STRING=$QueryString", 2);
    debug("HTMLOutput=" . join(',', keys %HTMLOutput), 1);
    debug("YearRequired=$YearRequired, MonthRequired=$MonthRequired", 2);
    debug("DayRequired=$DayRequired, HourRequired=$HourRequired", 2);
    debug("UpdateFor=$UpdateFor", 2);
    debug("PluginMode=$PluginMode", 2);
    debug("DirConfig=$DirConfig", 2);
}

if ($Debug) {
    debug("Last year=$lastyearbeforeupdate - Last month=$lastmonthbeforeupdate");
    debug("Last day=$lastdaybeforeupdate - Last hour=$lasthourbeforeupdate");
    debug("LastLine=$LastLine");
    debug("LastLineNumber=$LastLineNumber");
    debug("LastLineOffset=$LastLineOffset");
    debug("LastLineChecksum=$LastLineChecksum");
}