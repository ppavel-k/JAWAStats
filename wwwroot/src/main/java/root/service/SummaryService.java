package root.service;

public class SummaryService {

    /*

  # SUMMARY
        #---------------------------------------------------------------------
        if ($ShowSummary) {
            &HTMLMainSummary();
        }

        # BY MONTH
        #---------------------------------------------------------------------
        if ($ShowMonthStats) {
            &HTMLMainMonthly();
        }

        print "\n<a name=\"when\">&nbsp;</a>\n\n";

        # BY DAY OF MONTH
        #---------------------------------------------------------------------
        if ($ShowDaysOfMonthStats) {
            &HTMLMainDaily($firstdaytocountaverage, $lastdaytocountaverage,
                $firstdaytoshowtime, $lastdaytoshowtime);
        }

        # BY DAY OF WEEK
        #-------------------------
        if ($ShowDaysOfWeekStats) {
            &HTMLMainDaysofWeek($firstdaytocountaverage, $lastdaytocountaverage, $NewLinkParams, $NewLinkTarget);
        }

        # BY HOUR
        #----------------------------
        if ($ShowHoursStats) {
            &HTMLMainHours($NewLinkParams, $NewLinkTarget);
        }

        print "\n<a name=\"who\">&nbsp;</a>\n\n";

        # BY COUNTRY/DOMAIN
        #---------------------------
        if ($ShowDomainsStats) {
            &HTMLMainCountries($NewLinkParams, $NewLinkTarget);
        }

        # BY HOST/VISITOR
        #--------------------------
        if ($ShowHostsStats) {
            &HTMLMainHosts($NewLinkParams, $NewLinkTarget);
        }

        # BY SENDER EMAIL
        #----------------------------
        if ($ShowEMailSenders) {
            &HTMLShowEmailSendersChart($NewLinkParams, $NewLinkTarget);
        }

        # BY RECEIVER EMAIL
        #----------------------------
        if ($ShowEMailReceivers) {
            &HTMLShowEmailReceiversChart($NewLinkParams, $NewLinkTarget);
        }

        # BY LOGIN
        #----------------------------
        if ($ShowAuthenticatedUsers) {
            &HTMLMainLogins($NewLinkParams, $NewLinkTarget);
        }

        # BY ROBOTS
        #----------------------------
        if ($ShowRobotsStats) {
            &HTMLMainRobots($NewLinkParams, $NewLinkTarget);
        }

        # BY WORMS
        #----------------------------
        if ($ShowWormsStats) {
            &HTMLMainWorms();
        }

        print "\n<a name=\"how\">&nbsp;</a>\n\n";

        # BY SESSION
        #----------------------------
        if ($ShowSessionsStats) {
            &HTMLMainSessions();
        }

        # BY FILE TYPE
        #-------------------------
        if ($ShowFileTypesStats) {
            &HTMLMainFileType($NewLinkParams, $NewLinkTarget);
        }

        # BY FILE SIZE
        #-------------------------
        if ($ShowFileSizesStats) {
            &HTMLMainFileSize();
        }

        # BY REQUEST TIME
        #-------------------------
        if ($ShowRequestTimesStats) {
            &HTMLMainRequestTime();
        }

        # BY DOWNLOADS
        #-------------------------
        if ($ShowDownloadsStats) {
            &HTMLMainDownloads($NewLinkParams, $NewLinkTarget);
        }

        # BY PAGE
        #-------------------------
        if ($ShowPagesStats) {
            &HTMLMainPages($NewLinkParams, $NewLinkTarget);
        }

        # BY OS
        #----------------------------
        if ($ShowOSStats) {
            &HTMLMainOS($NewLinkParams, $NewLinkTarget);
        }

        # BY BROWSER
        #----------------------------
        if ($ShowBrowsersStats) {
            &HTMLMainBrowsers($NewLinkParams, $NewLinkTarget);
        }

        # BY SCREEN SIZE
        #----------------------------
        if ($ShowScreenSizeStats) {
            &HTMLMainScreenSize();
        }

        print "\n<a name=\"refering\">&nbsp;</a>\n\n";

        # BY REFERENCE
        #---------------------------
        if ($ShowOriginStats) {
            &HTMLMainReferrers($NewLinkParams, $NewLinkTarget);
        }

        print "\n<a name=\"keys\">&nbsp;</a>\n\n";

        # BY SEARCH KEYWORDS AND/OR KEYPHRASES
        #-------------------------------------
        if ($ShowKeyphrasesStats || $ShowKeywordsStats) {
            &HTMLMainKeys($NewLinkParams, $NewLinkTarget);
        }

        print "\n<a name=\"other\">&nbsp;</a>\n\n";

        # BY MISC
        #----------------------------
        if ($ShowMiscStats) {
            &HTMLMainMisc();
        }

        # BY HTTP STATUS
        #----------------------------
        if ($ShowHTTPErrorsStats) {
            &HTMLMainHTTPStatus($NewLinkParams, $NewLinkTarget);
        }

        # BY SMTP STATUS
        #----------------------------
        if ($ShowSMTPErrorsStats) {
            &HTMLMainSMTPStatus($NewLinkParams, $NewLinkTarget);
        }

        # BY CLUSTER
        #----------------------------
        if ($ShowClusterStats) {
            &HTMLMainCluster($NewLinkParams, $NewLinkTarget);
        }

        # BY EXTRA SECTIONS
        #----------------------------
        foreach my $extranum (1 .. @ExtraName - 1) {
            &HTMLMainExtra($NewLinkParams, $NewLinkTarget, $extranum);
        }
    * */


    /*
    HTMLShowRefererPages
    HTMLShowReferers
    HTMLMainFileType
    HTMLMainFileSize
    HTMLMainRequestTime
    HTMLShowBrowserDetail
HTMLShowOSDetail
HTMLShowKeyPhrases
HTMLShowKeywords
HTMLShowErrorCodes
HTMLShowRobots
HTMLMainMonthly
//         $total_u += $MonthUnique{ $YearRequired . $monthix } || 0;
//        $total_v += $MonthVisits{ $YearRequired . $monthix } || 0;
//        $total_p += $MonthPages{ $YearRequired . $monthix }  || 0;
//        $total_h += $MonthHits{ $YearRequired . $monthix }   || 0;
//        $total_k += $MonthBytes{ $YearRequired . $monthix }  || 0;

HTMLMainDaysofWeek
HTMLMainHours
HTMLMainCountries
HTMLMainHosts
HTMLMainRobots
HTMLMainWorms
HTMLMainPages
HTMLMainOS
HTMLMainBrowsers
HTMLMainScreenSize
HTMLMainReferrers
HTMLMainKeys
HTMLMainHTTPStatus

    * */

}
