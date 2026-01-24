
#------------------------------------------
# MIGRATE PROCESS (Must be after reading config cause we need MaxNbOf... and Min...)
#------------------------------------------
if ($MigrateStats) {
    if ($Debug) {debug("MigrateStats is $MigrateStats", 2);}
    if ($MigrateStats !~
        /^(.*)$PROG(\d\d)(\d\d\d\d)(\d{0,2})(\d{0,2})(.*)\.txt$/) {
        error(
            "AWStats history file name must match following syntax: ${PROG}MMYYYY[.config].txt",
            "", "", 1
        );
    }
    $DirData = "$1";
    $MonthRequired = "$2";
    $YearRequired = "$3";
    $DayRequired = "$4";
    $HourRequired = "$5";
    $FileSuffix = "$6";

    # Correct DirData
    if (!$DirData || $DirData =~ /^\./) {
        if (!$DirData || $DirData eq '.') {
            $DirData = "$DIR";
        } # If not defined or chosen to '.' value then DirData is current dir
        elsif ($DIR && $DIR ne '.') {$DirData = "$DIR/$DirData";}
    }
    $DirData ||= '.'; # If current dir not defined then we put it to '.'
    $DirData =~ s/[\\\/]+$//;
    print "Start migration for file '$MigrateStats'.";
    print $ENV{'GATEWAY_INTERFACE'} ? "<br />\n" : "\n";
    if ($EnableLockForUpdate) {&Lock_Update(1);}
    my $newhistory =
        &Read_History_With_TmpUpdate($YearRequired, $MonthRequired, $DayRequired,
            $HourRequired, 1, 0, 'all');
    if (rename("$newhistory", "$MigrateStats") == 0) {
        unlink "$newhistory";
        error(
            "Failed to rename \"$newhistory\" into \"$MigrateStats\".\nWrite permissions on \"$MigrateStats\" might be wrong"
                . (
                $ENV{'GATEWAY_INTERFACE'} ? " for a 'migration from web'" : ""
            )
                . " or file might be opened."
        );
    }
    if ($EnableLockForUpdate) {&Lock_Update(0);}
    print "Migration for file '$MigrateStats' successful.";
    print $ENV{'GATEWAY_INTERFACE'} ? "<br />\n" : "\n";
    &html_end(1);
    exit 0;
}
