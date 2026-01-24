
@HostAliases = @AllowAccessFromWebToFollowingAuthenticatedUsers = ();
@DefaultFile = @SkipDNSLookupFor = ();
@SkipHosts = @SkipUserAgents = @NotPageFiles = @SkipFiles = @SkipReferrers = ();
@OnlyHosts = @OnlyUserAgents = @OnlyFiles = @OnlyUsers = ();
@URLWithQueryWithOnly     = @URLWithQueryWithout    = ();
@ExtraName                = @ExtraCondition         = @ExtraStatTypes = ();
@MaxNbOfExtra             = @MinHitExtra            = ();
@ExtraFirstColumnTitle    = @ExtraFirstColumnValues = ();
@ExtraFirstColumnFunction = @ExtraFirstColumnFormat = ();
@ExtraCodeFilter = @ExtraConditionType = @ExtraConditionTypeVal = ();
@ExtraFirstColumnValuesType = @ExtraFirstColumnValuesTypeVal = ();
@ExtraAddAverageRow         = @ExtraAddSumRow                = ();
@PluginsToLoad              = ();

use vars qw/
    @MiscListOrder %MiscListCalc
    %OSFamily %BrowsersFamily @SessionsRange %SessionsAverage
    @PayloadRange %PayloadAverage
    @TimeRange %TimeAverage
    %LangBrowserToLangAwstats %LangAWStatsToFlagAwstats %BrowsersSafariBuildToVersionHash
    @HostAliases @AllowAccessFromWebToFollowingAuthenticatedUsers
    @DefaultFile @SkipDNSLookupFor
    @SkipHosts @SkipUserAgents @SkipFiles @SkipReferrers @NotPageFiles
    @OnlyHosts @OnlyUserAgents @OnlyFiles @OnlyUsers
    @URLWithQueryWithOnly @URLWithQueryWithout
    @ExtraName @ExtraCondition @ExtraStatTypes @MaxNbOfExtra @MinHitExtra
    @ExtraFirstColumnTitle @ExtraFirstColumnValues @ExtraFirstColumnFunction @ExtraFirstColumnFormat
    @ExtraCodeFilter @ExtraConditionType @ExtraConditionTypeVal
    @ExtraFirstColumnValuesType @ExtraFirstColumnValuesTypeVal
    @ExtraAddAverageRow @ExtraAddSumRow
    @PluginsToLoad
/;
@MiscListOrder = (
    'AddToFavourites',  'JavascriptDisabled',
    'JavaEnabled',      'DirectorSupport',
    'FlashSupport',     'RealPlayerSupport',
    'QuickTimeSupport', 'WindowsMediaPlayerSupport',
    'PDFSupport'
);

use vars qw/
    $DebugMessages $AllowToUpdateStatsFromBrowser $EnableLockForUpdate $DNSLookup $DynamicDNSLookup $AllowAccessFromWebToAuthenticatedUsersOnly
    $BarHeight $BarWidth $CreateDirDataIfNotExists $KeepBackupOfHistoricFiles
    $NbOfLinesParsed $NbOfLinesDropped $NbOfLinesCorrupted $NbOfLinesComment $NbOfLinesBlank $NbOfOldLines $NbOfNewLines
    $NbOfLinesShowsteps $NewLinePhase $NbOfLinesForCorruptedLog $PurgeLogFile $ArchiveLogRecords
    $ShowDropped $ShowCorrupted $ShowUnknownOrigin $ShowDirectOrigin $ShowLinksToWhoIs
    $ShowAuthenticatedUsers $ShowFileSizesStats $ShowRequestTimesStats $ShowScreenSizeStats $ShowSMTPErrorsStats
    $ShowEMailSenders $ShowEMailReceivers $ShowWormsStats $ShowClusterStats
    $IncludeInternalLinksInOriginSection
    $AuthenticatedUsersNotCaseSensitive
    $Expires $UpdateStats $MigrateStats $URLNotCaseSensitive $URLWithQuery $URLReferrerWithQuery
    $DecodeUA $DecodePunycode
/;
(
    $DebugMessages,
    $AllowToUpdateStatsFromBrowser,
    $EnableLockForUpdate,
    $DNSLookup,
    $DynamicDNSLookup,
    $AllowAccessFromWebToAuthenticatedUsersOnly,
    $BarHeight,
    $BarWidth,
    $CreateDirDataIfNotExists,
    $KeepBackupOfHistoricFiles,
    $NbOfLinesParsed,
    $NbOfLinesDropped,
    $NbOfLinesCorrupted,
    $NbOfLinesComment,
    $NbOfLinesBlank,
    $NbOfOldLines,
    $NbOfNewLines,
    $NbOfLinesShowsteps,
    $NewLinePhase,
    $NbOfLinesForCorruptedLog,
    $PurgeLogFile,
    $ArchiveLogRecords,
    $ShowDropped,
    $ShowCorrupted,
    $ShowUnknownOrigin,
    $ShowDirectOrigin,
    $ShowLinksToWhoIs,
    $ShowAuthenticatedUsers,
    $ShowFileSizesStats,
    $ShowRequestTimesStats,
    $ShowScreenSizeStats,
    $ShowSMTPErrorsStats,
    $ShowEMailSenders,
    $ShowEMailReceivers,
    $ShowWormsStats,
    $ShowClusterStats,
    $IncludeInternalLinksInOriginSection,
    $AuthenticatedUsersNotCaseSensitive,
    $Expires,
    $UpdateStats,
    $MigrateStats,
    $URLNotCaseSensitive,
    $URLWithQuery,
    $URLReferrerWithQuery,
    $DecodeUA,
    $DecodePunycode
)
    = (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0
);


use vars qw/
    $DetailedReportsOnNewWindows
    $FirstDayOfWeek $KeyWordsNotSensitive $SaveDatabaseFilesWithPermissionsForEveryone
    $WarningMessages $ShowLinksOnUrl $UseFramesWhenCGI
    $ShowMenu $ShowSummary $ShowMonthStats $ShowDaysOfMonthStats $ShowDaysOfWeekStats
    $ShowHoursStats $ShowDomainsStats $ShowHostsStats
    $ShowRobotsStats $ShowSessionsStats $ShowPagesStats $ShowFileTypesStats $ShowDownloadsStats
    $ShowOSStats $ShowBrowsersStats $ShowOriginStats
    $ShowKeyphrasesStats $ShowKeywordsStats $ShowMiscStats $ShowHTTPErrorsStats $ShowHTTPErrorsPageDetail
    $AddDataArrayMonthStats $AddDataArrayShowDaysOfMonthStats $AddDataArrayShowDaysOfWeekStats $AddDataArrayShowHoursStats
/;
(
    $DetailedReportsOnNewWindows,
    $FirstDayOfWeek,
    $KeyWordsNotSensitive,
    $SaveDatabaseFilesWithPermissionsForEveryone,
    $WarningMessages,
    $ShowLinksOnUrl,
    $UseFramesWhenCGI,
    $ShowMenu,
    $ShowSummary,
    $ShowMonthStats,
    $ShowDaysOfMonthStats,
    $ShowDaysOfWeekStats,
    $ShowHoursStats,
    $ShowDomainsStats,
    $ShowHostsStats,
    $ShowRobotsStats,
    $ShowSessionsStats,
    $ShowPagesStats,
    $ShowFileTypesStats,
    $ShowDownloadsStats,
    $ShowOSStats,
    $ShowBrowsersStats,
    $ShowOriginStats,
    $ShowKeyphrasesStats,
    $ShowKeywordsStats,
    $ShowMiscStats,
    $ShowHTTPErrorsStats,
    $ShowHTTPErrorsPageDetail,
    $AddDataArrayMonthStats,
    $AddDataArrayShowDaysOfMonthStats,
    $AddDataArrayShowDaysOfWeekStats,
    $AddDataArrayShowHoursStats
)
    = (
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
);

use vars qw/
    $DirLock $DirCgi $DirConfig $DirData $DirIcons $DirLang $AWScript $ArchiveFileName
    $AllowAccessFromWebToFollowingIPAddresses $HTMLHeadSection $HTMLEndSection $LinksToWhoIs $LinksToIPWhoIs
    $LogFile $LogType $LogFormat $LogSeparator $Logo $LogoLink $StyleSheet $WrapperScript $SiteDomain
    $UseHTTPSLinkForUrl $URLQuerySeparators $URLWithAnchor $ErrorMessages $ShowFlagLinks
    $AddLinkToExternalCGIWrapper $LogFormatJsonMap
/;
(
    $DirLock,                                  $DirCgi,
    $DirConfig,                                $DirData,
    $DirIcons,                                 $DirLang,
    $AWScript,                                 $ArchiveFileName,
    $AllowAccessFromWebToFollowingIPAddresses, $HTMLHeadSection,
    $HTMLEndSection,                           $LinksToWhoIs,
    $LinksToIPWhoIs,                           $LogFile,
    $LogType,                                  $LogFormat,
    $LogSeparator,                             $Logo,
    $LogoLink,                                 $StyleSheet,
    $WrapperScript,                            $SiteDomain,
    $UseHTTPSLinkForUrl,                       $URLQuerySeparators,
    $URLWithAnchor,                            $ErrorMessages,
    $ShowFlagLinks,                            $AddLinkToExternalCGIWrapper,
    $LogFormatJsonMap
)
    = (
    '', '', '', '', '', '', '', '', '', '', '', '', '', '',
    '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''
);


use vars qw/
    $color_Background $color_TableBG $color_TableBGRowTitle
    $color_TableBGTitle $color_TableBorder $color_TableRowTitle $color_TableTitle
    $color_text $color_textpercent $color_titletext $color_weekend $color_link $color_hover $color_other
    $color_h $color_k $color_p $color_e $color_x $color_s $color_u $color_v
/;
(
    $color_Background,   $color_TableBG,     $color_TableBGRowTitle,
    $color_TableBGTitle, $color_TableBorder, $color_TableRowTitle,
    $color_TableTitle,   $color_text,        $color_textpercent,
    $color_titletext,    $color_weekend,     $color_link,
    $color_hover,        $color_other,       $color_h,
    $color_k,            $color_p,           $color_e,
    $color_x,            $color_s,           $color_u,
    $color_v
)
    = (
    '', '', '', '', '', '', '', '', '', '', '', '',
    '', '', '', '', '', '', '', '', '', ''
);

%MiscListCalc = (
    'TotalMisc'                 => '',
    'AddToFavourites'           => 'u',
    'JavascriptDisabled'        => 'hm',
    'JavaEnabled'               => 'hm',
    'DirectorSupport'           => 'hm',
    'FlashSupport'              => 'hm',
    'RealPlayerSupport'         => 'hm',
    'QuickTimeSupport'          => 'hm',
    'WindowsMediaPlayerSupport' => 'hm',
    'PDFSupport'                => 'hm'
);

%LangAWStatsToFlagAwstats =
    (  # If flag (country ISO-3166 two letters) is not same than AWStats Lang code
        'ca' => 'es_cat',
        'et' => 'ee',
        'eu' => 'es_eu',
        'cy' => 'wlk',
        'gl' => 'glg',
        'he' => 'il',
        'ko' => 'kr',
        'ar' => 'sa',
        'sr' => 'cs'
    );

@Message = (
    'Unknown',
    'Unknown (unresolved ip)',
    'Others',
    'View details',
    'Day',
    'Month',
    'Year',
    'Statistics for',
    'First visit',
    'Last visit',
    'Number of visits',
    'Unique visitors',
    'Visit',
    'different keywords',
    'Search',
    'Percent',
    'Traffic',
    'Domains/Countries',
    'Visitors',
    'Pages-URL',
    'Hours',
    'Browsers',
    '',
    'Referers',
    'Never updated (See \'Build/Update\' on awstats_setup.html page)',
    'Visitors domains/countries',
    'hosts',
    'pages',
    'different pages-url',
    'Viewed',
    'Other words',
    'Pages not found',
    'HTTP Error codes',
    'Netscape versions',
    'IE versions',
    'Last Update',
    'Connect to site from',
    'Origin',
    'Direct address / Bookmarks',
    'Origin unknown',
    'Links from an Internet Search Engine',
    'Links from an external page (other web sites except search engines)',
    'Links from an internal page (other page on same site)',
    'Keyphrases used on search engines',
    'Keywords used on search engines',
    'Unresolved IP Address',
    'Unknown OS (Referer field)',
    'Required but not found URLs (HTTP code 404)',
    'IP Address',
    'Error&nbsp;Hits',
    'Unknown browsers (Referer field)',
    'different robots',
    'visits/visitor',
    'Robots/Spiders visitors',
    'Free realtime logfile analyzer for advanced web statistics',
    'of',
    'Pages',
    'Hits',
    'Versions',
    'Operating Systems',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
    'Navigation',
    'File type',
    'Update now',
    'Bandwidth',
    'Back to main page',
    'Top',
    'dd mmm yyyy - HH:MM',
    'Filter',
    'Full list',
    'Hosts',
    'Known',
    'Robots',
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Days of week',
    'Who',
    'When',
    'Authenticated users',
    'Min',
    'Average',
    'Max',
    'Web compression',
    'Bandwidth saved',
    'Compression on',
    'Compression result',
    'Total',
    'different keyphrases',
    'Entry',
    'Code',
    'Average size',
    'Links from a NewsGroup',
    'KB',
    'MB',
    'GB',
    'Grabber',
    'Yes',
    'No',
    'Info.',
    'OK',
    'Exit',
    'Visits duration',
    'Close window',
    'Bytes',
    'Search&nbsp;Keyphrases',
    'Search&nbsp;Keywords',
    'different refering search engines',
    'different refering sites',
    'Other phrases',
    'Other logins (and/or anonymous users)',
    'Refering search engines',
    'Refering sites',
    'Summary',
    'Exact value not available in "Year" view',
    'Data value arrays',
    'Sender EMail',
    'Receiver EMail',
    'Reported period',
    'Extra/Marketing',
    'Screen sizes',
    'Worm/Virus attacks',
    'Hit on favorite icon',
    'Days of month',
    'Miscellaneous',
    'Browsers with Java support',
    'Browsers with Macromedia Director Support',
    'Browsers with Flash Support',
    'Browsers with Real audio playing support',
    'Browsers with Quictime audio playing support',
    'Browsers with Windows Media audio playing support',
    'Browsers with PDF support',
    'SMTP Error codes',
    'Countries',
    'Mails',
    'Size',
    'First',
    'Last',
    'Exclude filter',
    'Codes shown here gave hits or traffic "not viewed" by visitors, so they are not included in other charts.',
    'Cluster',
    'Robots shown here gave hits or traffic "not viewed" by visitors, so they are not included in other charts.',
    'Numbers after + are successful hits on "robots.txt" files',
    'Worms shown here gave hits or traffic "not viewed" by visitors, so thay are not included in other charts.',
    'Not viewed traffic includes traffic generated by robots, worms, or replies with special HTTP status codes.',
    'Traffic viewed',
    'Traffic not viewed',
    'Monthly history',
    'Worms',
    'different worms',
    'Mails successfully sent',
    'Mails failed/refused',
    'Sensitive targets',
    'Javascript disabled',
    'Created by',
    'plugins',
    'Regions',
    'Cities',
    'Opera versions',
    'Safari versions',
    'Chrome versions',
    'Konqueror versions',
    ',',
    'Downloads',
    'Export CSV',
    'TB',
    'Frequency[/s]',
    'Number of requests',
    'Period',
    's',
    'Request average frequency [/s]',
    'Request size',
    'Request time'
);


# Allowed option
my @AllowedCLIArgs = (
    'migrate',            'config',
    'logfile',            'output',
    'runascli',           'update',
    'staticlinks',        'staticlinksext',
    'noloadplugin',       'loadplugin',
    'hostfilter',         'urlfilter',
    'refererpagesfilter', 'lang',
    'month',              'year',
    'framename',          'debug',
    'showsteps',          'showdropped',
    'showcorrupted',      'showunknownorigin',
    'showdirectorigin',   'limitflush',
    'nboflastupdatelookuptosave',
    'confdir',            'updatefor',
    'hostfilter',         'hostfilterex',
    'urlfilter',          'urlfilterex',
    'refererpagesfilter', 'refererpagesfilterex',
    'pluginmode',         'filterrawlog'
);