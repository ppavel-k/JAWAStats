#!/usr/bin/perl
#------------------------------------------------------------------------------
# Free realtime web server logfile analyzer to show advanced web statistics.
# Works from command line or as a CGI. You must use this script as often as
# necessary from your scheduler to update your statistics and from command
# line or a browser to read report results.
# See AWStats documentation (in docs/ directory) for all setup instructions.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#------------------------------------------------------------------------------
require 5.007;

#$|=1;
#use warnings;		# Must be used in test mode only. This reduce a little process speed
#use diagnostics;	# Must be used in test mode only. This reduce a lot of process speed
use strict;
no strict "refs";
use Time::Local
; # use Time::Local 'timelocal_nocheck' is faster but not supported by all Time::Local modules
use Socket;
use Encode;
use File::Spec;
use JSON::XS;
use Try::Tiny;


#------------------------------------------------------------------------------
# Defines
#------------------------------------------------------------------------------
use vars qw/$REVISION $VERSION/;
$REVISION = '20240604';
$VERSION = "8.0 (build $REVISION)";

# ----- Constants -----
use vars qw/
    $DEBUGFORCED $NBOFLINESFORBENCHMARK $FRAMEWIDTH $NBOFLASTUPDATELOOKUPTOSAVE
    $LIMITFLUSH $NEWDAYVISITTIMEOUT $VISITTIMEOUT $NOTSORTEDRECORDTOLERANCE
    $WIDTHCOLICON $TOOLTIPON
    $lastyearbeforeupdate $lastmonthbeforeupdate $lastdaybeforeupdate $lasthourbeforeupdate $lastdatebeforeupdate
    $NOHTML
/;
$DEBUGFORCED = 0
; # Force debug level to log lesser level into debug.log file (Keep this value to 0)
$NBOFLINESFORBENCHMARK = 8192
;                  # Benchmark info are printing every NBOFLINESFORBENCHMARK lines (Must be a power of 2)
$FRAMEWIDTH = 240; # Width of left frame when UseFramesWhenCGI is on
$NBOFLASTUPDATELOOKUPTOSAVE =
    500; # Nb of records to save in DNS last update cache file
$LIMITFLUSH =
    5000;                     # Nb of records in data arrays after how we need to flush data on disk
$NEWDAYVISITTIMEOUT = 764041; # Delay between 01-23:59:59 and 02-00:00:00
$VISITTIMEOUT = 10000
; # Lapse of time to consider a page load as a new visit. 10000 = 1 hour (Default = 10000)
$NOTSORTEDRECORDTOLERANCE = 20000
; # Lapse of time to accept a record if not in correct order. 20000 = 2 hour (Default = 20000)
$WIDTHCOLICON = 32;
$TOOLTIPON = 0; # Tooltips plugin loaded
$NOHTML = 0;    # Suppress the html headers

# ----- Running variables -----
use vars qw/
    $DIR $PROG $Extension
    $Debug $ShowSteps
    $DebugResetDone $DNSLookupAlreadyDone
    $RunAsCli $UpdateFor $HeaderHTTPSent $HeaderHTMLSent
    $LastLine $LastLineNumber $LastLineOffset $LastLineChecksum $LastUpdate
    $lowerval
    $PluginMode
    $MetaRobot
    $AverageVisits $AveragePages $AverageHits $AverageBytes
    $TotalUnique $TotalVisits $TotalHostsKnown $TotalHostsUnknown
    $TotalPages $TotalHits $TotalBytes $TotalHitsErrors
    $TotalNotViewedPages $TotalNotViewedHits $TotalNotViewedBytes
    $TotalEntries $TotalExits $TotalBytesPages $TotalDifferentPages
    $TotalKeyphrases $TotalKeywords $TotalDifferentKeyphrases $TotalDifferentKeywords
    $TotalSearchEnginesPages $TotalSearchEnginesHits $TotalRefererPages $TotalRefererHits $TotalDifferentSearchEngines $TotalDifferentReferer
    $FrameName $Center $FileConfig $FileSuffix $Host $YearRequired $MonthRequired $DayRequired $HourRequired
    $QueryString $SiteConfig $StaticLinks $PageCode $PageDir $PerlParsingFormat $PerlParsingFormatJsonMap $UserAgent
    $pos_vh $pos_host $pos_logname $pos_date $pos_tz $pos_method $pos_url $pos_code $pos_size $pos_time
    $pos_referer $pos_agent $pos_query $pos_gzipin $pos_gzipout $pos_compratio $pos_timetaken
    $pos_cluster $pos_emails $pos_emailr $pos_hostr @pos_extra
/;
$DIR = $PROG = $Extension = '';
$Debug = $ShowSteps = 0;
$DebugResetDone = $DNSLookupAlreadyDone = 0;
$RunAsCli = $UpdateFor = $HeaderHTTPSent = $HeaderHTMLSent = 0;
$LastLine = $LastLineNumber = $LastLineOffset = $LastLineChecksum = 0;
$LastUpdate = 0;
$lowerval = 0;
$PluginMode = '';
$MetaRobot = 0;
$AverageVisits = $AveragePages = $AverageHits = $AverageBytes = 0;
$TotalUnique = $TotalVisits = $TotalHostsKnown = $TotalHostsUnknown = 0;
$TotalPages = $TotalHits = $TotalBytes = $TotalHitsErrors = 0;
$TotalNotViewedPages = $TotalNotViewedHits = $TotalNotViewedBytes = 0;
$TotalEntries = $TotalExits = $TotalBytesPages = $TotalDifferentPages = 0;
$TotalKeyphrases = $TotalKeywords = $TotalDifferentKeyphrases = 0;
$TotalDifferentKeywords = 0;
$TotalSearchEnginesPages = $TotalSearchEnginesHits = $TotalRefererPages = 0;
$TotalRefererHits = $TotalDifferentSearchEngines = $TotalDifferentReferer = 0;
(
    $FrameName, $Center, $FileConfig, $FileSuffix,
    $Host, $YearRequired, $MonthRequired, $DayRequired,
    $HourRequired, $QueryString, $SiteConfig, $StaticLinks,
    $PageCode, $PageDir, $PerlParsingFormat, $UserAgent,
    $PerlParsingFormatJsonMap
)
    = ('', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', undef);

# ----- Plugins variable -----
use vars qw/%PluginsLoaded $PluginDir $AtLeastOneSectionPlugin/;
%PluginsLoaded = ();
$PluginDir = '';
$AtLeastOneSectionPlugin = 0;

# ----- Time vars -----
use vars qw/
    $starttime
    $nowtime $tomorrowtime
    $nowweekofmonth $nowweekofyear $nowdaymod $nowsmallyear
    $nowsec $nowmin $nowhour $nowday $nowmonth $nowyear $nowwday $nowyday $nowns
    $StartSeconds $StartMicroseconds
/;
$StartSeconds = $StartMicroseconds = 0;

# ----- Variables for config file reading -----
use vars qw/
    $FoundNotPageList
/;
$FoundNotPageList = 0;

# ----- Config file variables -----
use vars qw/
    $StaticExt
    $DNSStaticCacheFile
    $DNSLastUpdateCacheFile
    $MiscTrackerUrl
    $Lang
    $MaxRowsInHTMLOutput
    $MaxLengthOfShownURL
    $MaxLengthOfStoredURL
    $MaxLengthOfStoredUA
    %BarPng
    $BuildReportFormat
    $BuildHistoryFormat
    $ExtraTrackedRowsLimit
    $DatabaseBreak
    $SectionsToBeSaved
/;
$StaticExt = 'html';
$DNSStaticCacheFile = 'dnscache.txt';
$DNSLastUpdateCacheFile = 'dnscachelastupdate.txt';
$MiscTrackerUrl = '/js/awstats_misc_tracker.js';
$Lang = 'auto';
$SectionsToBeSaved = 'all';
$MaxRowsInHTMLOutput = 1000;
$MaxLengthOfShownURL = 64;
$MaxLengthOfStoredURL = 256; # Note: Apache LimitRequestLine is default to 8190
$MaxLengthOfStoredUA = 256;
%BarPng = (
    'vv' => 'vv.png',
    'vu' => 'vu.png',
    'hu' => 'hu.png',
    'vp' => 'vp.png',
    'hp' => 'hp.png',
    'he' => 'he.png',
    'hx' => 'hx.png',
    'vh' => 'vh.png',
    'hh' => 'hh.png',
    'vk' => 'vk.png',
    'hk' => 'hk.png'
);
$BuildReportFormat = 'html';
$BuildHistoryFormat = 'text';
$ExtraTrackedRowsLimit = 500;
$DatabaseBreak = 'month';

use vars qw/
    $AllowFullYearView
    $LevelForRobotsDetection $LevelForWormsDetection $LevelForBrowsersDetection $LevelForOSDetection $LevelForRefererAnalyze
    $LevelForFileTypesDetection $LevelForSearchEnginesDetection $LevelForKeywordsDetection
/;
(
    $AllowFullYearView, $LevelForRobotsDetection,
    $LevelForWormsDetection, $LevelForBrowsersDetection,
    $LevelForOSDetection, $LevelForRefererAnalyze,
    $LevelForFileTypesDetection, $LevelForSearchEnginesDetection,
    $LevelForKeywordsDetection
)
    = (2, 2, 0, 2, 2, 2, 2, 2, 2);


# ---------- Init arrays --------
use vars qw/
    @RobotsSearchIDOrder_list1 @RobotsSearchIDOrder_list2 @RobotsSearchIDOrder_listgen
    @SearchEnginesSearchIDOrder_list1 @SearchEnginesSearchIDOrder_list2 @SearchEnginesSearchIDOrder_listgen
    @BrowsersSearchIDOrder @OSSearchIDOrder @WordsToCleanSearchUrl
    @WormsSearchIDOrder
    @RobotsSearchIDOrder @SearchEnginesSearchIDOrder
    @_from_p @_from_h
    @_time_p @_time_h @_time_k @_time_nv_p @_time_nv_h @_time_nv_k
    @DOWIndex @fieldlib @keylist
/;
@RobotsSearchIDOrder = @SearchEnginesSearchIDOrder = ();
@_from_p = @_from_h = ();
@_time_p = @_time_h = @_time_k = @_time_nv_p = @_time_nv_h = @_time_nv_k = ();
@DOWIndex = @fieldlib = @keylist = ();

@SessionsRange =
    ('0s-30s', '30s-2mn', '2mn-5mn', '5mn-15mn', '15mn-30mn', '30mn-1h', '1h+');
%SessionsAverage = (
    '0s-30s', 15, '30s-2mn', 75, '2mn-5mn', 210,
    '5mn-15mn', 600, '15mn-30mn', 1350, '30mn-1h', 2700,
    '1h+', 3600
);

@PayloadRange = ('0-44', '44-100', '100-500', '500-1K', '1K-2K', '2K-5K', '5K+');
%PayloadAverage = (
    '0-44', 44, '44-100', 100, '100-500', 500, '500-1K', 1024,
    '1K-2K', 2048, '2K-5K', 5120, '5K+', 5121
);

@TimeRange = ('0-44', '44-100', '100-500', '500-1K', '1K-2K', '2K-5K', '5K+');
%TimeAverage = (
    '0-44', 44, '44-100', 100, '100-500', 500, '500-1K', 1024,
    '1K-2K', 2048, '2K-5K', 5120, '5K+', 5121
);

# HTTP-Accept or Lang parameter => AWStats code to use for lang
# ISO-639-1 or 2 or other       => awstats-xx.txt where xx is ISO-639-1
%LangBrowserToLangAwstats = (
    'en' => 'en',
);


# ---------- Init hash arrays --------
use vars qw/
    %BrowsersHashIDLib %BrowsersHashIcon %BrowsersHereAreGrabbers
    %DomainsHashIDLib
    %MimeHashLib %MimeHashFamily
    %OSHashID %OSHashLib
    %RobotsHashIDLib %RobotsAffiliateLib
    %SearchEnginesHashID %SearchEnginesHashLib %SearchEnginesWithKeysNotInQuery %SearchEnginesKnownUrl %NotSearchEnginesKeys
    %WormsHashID %WormsHashLib %WormsHashTarget
/;
use vars qw/
    %HTMLOutput %NoLoadPlugin %FilterIn %FilterEx
    %BadFormatWarning
    %MonthNumLib
    %ValidHTTPCodes %ValidSMTPCodes
    %TrapInfosForHTTPErrorCodes %NotPageList %DayBytes %DayHits %DayPages %DayVisits
    %MaxNbOf %MinHit
    %ListOfYears %HistoryAlreadyFlushed %PosInFile %ValueInFile
    %val %nextval %egal
    %TmpDNSLookup %TmpOS %TmpRefererServer %TmpRobot %TmpBrowser %MyDNSTable
/;
%HTMLOutput = %NoLoadPlugin = %FilterIn = %FilterEx = ();
%BadFormatWarning = ();
%MonthNumLib = ();
%ValidHTTPCodes = %ValidSMTPCodes = ();
%TrapInfosForHTTPErrorCodes = ();
%NotPageList = ();
%DayBytes = %DayHits = %DayPages = %DayVisits = ();
%MaxNbOf = %MinHit = ();
%ListOfYears = %HistoryAlreadyFlushed = %PosInFile = %ValueInFile = ();
%val = %nextval = %egal = ();
%TmpDNSLookup = %TmpOS = %TmpRefererServer = %TmpRobot = %TmpBrowser = ();
%MyDNSTable = ();
use vars qw/
    %FirstTime %LastTime
    %MonthHostsKnown %MonthHostsUnknown
    %MonthUnique %MonthVisits
    %MonthPages %MonthHits %MonthBytes
    %MonthNotViewedPages %MonthNotViewedHits %MonthNotViewedBytes
    %_session %_browser_h %_browser_p
    %_filesize
    %_requesttime
    %_domener_p %_domener_h %_domener_k %_errors_h %_errors_k
    %_filetypes_h %_filetypes_k %_filetypes_gz_in %_filetypes_gz_out
    %_host_p %_host_h %_host_k %_host_l %_host_s %_host_u
    %_waithost_e %_waithost_l %_waithost_s %_waithost_u
    %_keyphrases %_keywords %_os_h %_os_p %_pagesrefs_p %_pagesrefs_h %_robot_h %_robot_k %_robot_l %_robot_r
    %_worm_h %_worm_k %_worm_l %_login_h %_login_p %_login_k %_login_l %_screensize_h
    %_misc_p %_misc_h %_misc_k
    %_cluster_p %_cluster_h %_cluster_k
    %_se_referrals_p %_se_referrals_h %_sider_h %_referer_h %_err_host_h %_url_p %_url_k %_url_e %_url_x
    %_downloads
    %_unknownreferer_l %_unknownrefererbrowser_l
    %_emails_h %_emails_k %_emails_l %_emailr_h %_emailr_k %_emailr_l
/;
&Init_HashArray();

# ---------- Init Regex --------
use vars qw/$regclean1 $regclean2 $regdate/;
$regclean1 = qr/<(recnb|\/td)>/i;
$regclean2 = qr/<\/?[^<>]+>/i;
$regdate = qr/(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/;

# ---------- Init Tie::hash arrays --------
# Didn't find a tie that increase speed
#use Tie::StdHash;
#use Tie::Cache::LRU;
#tie %_host_p, 'Tie::StdHash';
#tie %TmpOS, 'Tie::Cache::LRU';

# PROTOCOL CODES
use vars qw/%httpcodelib %ftpcodelib %smtpcodelib/;

# DEFAULT MESSAGE
use vars qw/@Message/;
#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------
($DIR = $0) =~ s/([^\/\\]+)$//;
($PROG = $1) =~ s/\.([^\.]*)$//;
$Extension = $1;
$DIR ||= '.';
$DIR =~ s/([^\/\\])[\\\/]+$/$1/;

$starttime = time();

# Get current time (time when AWStats was started)
($nowsec, $nowmin, $nowhour, $nowday, $nowmonth, $nowyear, $nowwday, $nowyday)
    = localtime($starttime);
$nowweekofmonth = int($nowday / 7);
$nowweekofyear =
    int(($nowyday - 1 + 6 - ($nowwday == 0 ? 6 : $nowwday - 1)) / 7) + 1;
if ($nowweekofyear > 52) {$nowweekofyear = 1;}
$nowdaymod = $nowday % 7;
$nowwday++;
$nowns = Time::Local::timegm(0, 0, 0, $nowday, $nowmonth, $nowyear);

if ($nowdaymod <= $nowwday) {
    if (($nowwday != 7) || ($nowdaymod != 0)) {
        $nowweekofmonth = $nowweekofmonth + 1;
    }
}
if ($nowdaymod > $nowwday) {$nowweekofmonth = $nowweekofmonth + 2;}

# Change format of time variables
$nowweekofmonth = "0$nowweekofmonth";
if ($nowweekofyear < 10) {$nowweekofyear = "0$nowweekofyear";}
if ($nowyear < 100) {$nowyear += 2000;}
else {$nowyear += 1900;}
$nowsmallyear = $nowyear;
$nowsmallyear =~ s/^..//;
if (++$nowmonth < 10) {$nowmonth = "0$nowmonth";}
if ($nowday < 10) {$nowday = "0$nowday";}
if ($nowhour < 10) {$nowhour = "0$nowhour";}
if ($nowmin < 10) {$nowmin = "0$nowmin";}
if ($nowsec < 10) {$nowsec = "0$nowsec";}
$nowtime = int($nowyear . $nowmonth . $nowday . $nowhour . $nowmin . $nowsec);

# Get tomorrow time (will be used to discard some record with corrupted date (future date))
my (
    $tomorrowsec, $tomorrowmin, $tomorrowhour,
    $tomorrowday, $tomorrowmonth, $tomorrowyear
)
    = localtime($starttime + 86400);
if ($tomorrowyear < 100) {$tomorrowyear += 2000;}
else {$tomorrowyear += 1900;}
if (++$tomorrowmonth < 10) {$tomorrowmonth = "0$tomorrowmonth";}
if ($tomorrowday < 10) {$tomorrowday = "0$tomorrowday";}
if ($tomorrowhour < 10) {$tomorrowhour = "0$tomorrowhour";}
if ($tomorrowmin < 10) {$tomorrowmin = "0$tomorrowmin";}
if ($tomorrowsec < 10) {$tomorrowsec = "0$tomorrowsec";}
$tomorrowtime =
    int($tomorrowyear
        . $tomorrowmonth
        . $tomorrowday
        . $tomorrowhour
        . $tomorrowmin
        . $tomorrowsec);


# Check parameter validity
# TODO



# Force SiteConfig if AWSTATS_FORCE_CONFIG is defined
if ($ENV{'AWSTATS_CONFIG'}) {
    $ENV{'AWSTATS_FORCE_CONFIG'} = $ENV{'AWSTATS_CONFIG'};
} # For backward compatibility
if ($ENV{'AWSTATS_FORCE_CONFIG'}) {
    if ($Debug) {
        debug("AWSTATS_FORCE_CONFIG parameter is defined to '"
            . $ENV{'AWSTATS_FORCE_CONFIG'}
            . "'. $PROG will use this as config value.");
    }
    $SiteConfig = &Sanitize($ENV{'AWSTATS_FORCE_CONFIG'});
}

# Display version information
if ($QueryString =~ /(^|&|&amp;)version/i) {
    print "$PROG $VERSION\n";
    exit 0;
}
# Display help information
if ((!$ENV{'GATEWAY_INTERFACE'}) && (!$SiteConfig)) {
    &PrintCLIHelp();
    exit 2;
}
$SiteConfig ||= &Sanitize($ENV{'SERVER_NAME'});

#$ENV{'SERVER_NAME'}||=$SiteConfig;	# For thoose who use __SERVER_NAME__ in conf file and use CLI.
$ENV{'AWSTATS_CURRENT_CONFIG'} = $SiteConfig;

# Read config file (SiteConfig must be defined)
&Read_Config($DirConfig);

# Check language
if ($QueryString =~ /(^|&|&amp;)lang=([^&]+)/i) {$Lang = "$2";}
if (!$Lang || $Lang eq 'auto') {
    # If lang not defined or forced to auto
    my $langlist = $ENV{'HTTP_ACCEPT_LANGUAGE'} || '';
    $langlist =~ s/;[^,]*//g;
    if ($Debug) {
        debug(
            "Search an available language among HTTP_ACCEPT_LANGUAGE=$langlist",
            1
        );
    }
    foreach my $code (split(/,/, $langlist)) {
        # Search for a valid lang in priority
        if ($LangBrowserToLangAwstats{$code}) {
            $Lang = $LangBrowserToLangAwstats{$code};
            if ($Debug) {debug(" Will try to use Lang=$Lang", 1);}
            last;
        }
        $code =~ s/-.*$//;
        if ($LangBrowserToLangAwstats{$code}) {
            $Lang = $LangBrowserToLangAwstats{$code};
            if ($Debug) {debug(" Will try to use Lang=$Lang", 1);}
            last;
        }
    }
}
if (!$Lang || $Lang eq 'auto') {
    if ($Debug) {
        debug(" No language defined or available. Will use Lang=en", 1);
    }
    $Lang = 'en';
}

# Check and correct bad parameters
&Check_Config();

# Now SiteDomain is defined

if ($Debug && !$DebugMessages) {
    error(
        "Debug has not been allowed. Change DebugMessages parameter in config file to allow debug."
    );
}

# Define frame name and correct variable for frames
if (!$FrameName) {
    if ($ENV{'GATEWAY_INTERFACE'}
        && $UseFramesWhenCGI
        && $HTMLOutput{'main'}
        && !$PluginMode) {
        $FrameName = 'index';
    }
    else {$FrameName = 'main';}
}

# Load Message files, Reference data files and Plugins
if ($Debug) {debug("FrameName=$FrameName", 1);}
if ($FrameName ne 'index') {
    &Read_Language_Data($Lang);
    if ($FrameName ne 'mainleft') {
        my %datatoload = ();
        my (
            $filedomains, $filemime, $filerobots, $fileworms,
            $filebrowser, $fileos, $filese
        )
            = (
            'domains', 'mime',
            'robots', 'worms',
            'browsers', 'operating_systems',
            'search_engines'
        );
        my ($filestatushttp, $filestatussmtp) =
            ('status_http', 'status_smtp');
        if ($LevelForBrowsersDetection eq 'allphones') {
            $filebrowser = 'browsers_phone';
        }
        if ($UpdateStats) {
            # If update
            if ($LevelForFileTypesDetection) {
                $datatoload{$filemime} = 1;
            } # Only if need to filter on known extensions
            if ($LevelForRobotsDetection) {
                $datatoload{$filerobots} = 1;
            } # ua
            if ($LevelForWormsDetection) {
                $datatoload{$fileworms} = 1;
            } # url
            if ($LevelForBrowsersDetection) {
                $datatoload{$filebrowser} = 1;
            } # ua
            if ($LevelForOSDetection) {
                $datatoload{$fileos} = 1;
            } # ua
            if ($LevelForRefererAnalyze) {
                $datatoload{$filese} = 1;
            } # referer
            # if (...) { $datatoload{'referer_spam'}=1; }
        }
        if (scalar keys %HTMLOutput) {
            # If output
            if ($ShowDomainsStats || $ShowHostsStats) {
                $datatoload{$filedomains} = 1;
            } # TODO Replace by test if ($ShowDomainsStats) when plugins geoip can force load of domains datafile.
            if ($ShowFileTypesStats) {$datatoload{$filemime} = 1;}
            if ($ShowRobotsStats) {$datatoload{$filerobots} = 1;}
            if ($ShowWormsStats) {$datatoload{$fileworms} = 1;}
            if ($ShowBrowsersStats) {$datatoload{$filebrowser} = 1;}
            if ($ShowOSStats) {$datatoload{$fileos} = 1;}
            if ($ShowOriginStats) {$datatoload{$filese} = 1;}
            if ($ShowHTTPErrorsStats) {$datatoload{$filestatushttp} = 1;}
            if ($ShowSMTPErrorsStats) {$datatoload{$filestatussmtp} = 1;}
        }
        &Read_Ref_Data(keys %datatoload);
    }
    &Read_Plugins();
}

# Here charset is defined, so we can send the http header (Need BuildReportFormat,PageCode)
if (!$HeaderHTTPSent && $ENV{'GATEWAY_INTERFACE'}) {
    http_head();
} # Run from a browser as CGI

# Init other parameters
$NBOFLINESFORBENCHMARK--;
if ($ENV{'GATEWAY_INTERFACE'}) {$DirCgi = '';}
if ($DirCgi && !($DirCgi =~ /\/$/) && !($DirCgi =~ /\\$/)) {
    $DirCgi .= '/';
}
if (!$DirData || $DirData =~ /^\./) {
    if (!$DirData || $DirData eq '.') {
        $DirData = "$DIR";
    } # If not defined or chosen to '.' value then DirData is current dir
    elsif ($DIR && $DIR ne '.') {$DirData = "$DIR/$DirData";}
}
$DirData ||= '.'; # If current dir not defined then we put it to '.'
$DirData =~ s/[\\\/]+$//;

if ($FirstDayOfWeek == 1) {@DOWIndex = (1, 2, 3, 4, 5, 6, 0);}
else {@DOWIndex = (0, 1, 2, 3, 4, 5, 6);}

# Should we link to ourselves or to a wrapper script
$AWScript = ($WrapperScript ? "$WrapperScript" : "$DirCgi$PROG.$Extension");
if (index($AWScript, '?') > -1) {
    $AWScript .= '&amp;'; # $AWScript contains URL parameters
}
else {
    $AWScript .= '?';
}


# Print html header (Need HTMLOutput,Expires,Lang,StyleSheet,HTMLHeadSectionExpires defined by Read_Config, PageCode defined by Read_Language_Data)
if (!$HeaderHTMLSent) {&html_head;}

# AWStats output is replaced by a plugin output
if ($PluginMode) {

    #	my $function="BuildFullHTMLOutput_$PluginMode()";
    #	eval("$function");
    my $function = "BuildFullHTMLOutput_$PluginMode";
    &$function();
    if ($? || $@) {error("$@");}
    &html_end(0);
    exit 0;
}

# Security check
if ($AllowAccessFromWebToAuthenticatedUsersOnly && $ENV{'GATEWAY_INTERFACE'}) {
    if ($Debug) {debug("REMOTE_USER=" . $ENV{"REMOTE_USER"});}
    if (!$ENV{"REMOTE_USER"}) {
        error(
            "Access to statistics is only allowed from an authenticated session to authenticated users."
        );
    }
    if (@AllowAccessFromWebToFollowingAuthenticatedUsers) {
        my $userisinlist = 0;
        my $remoteuser = quotemeta($ENV{"REMOTE_USER"});
        $remoteuser =~ s/\s/%20/g
        ;                                     # Allow authenticated user with space in name to be compared to allowed user list
        my $currentuser = qr/^$remoteuser$/i; # Set precompiled regex
        foreach (@AllowAccessFromWebToFollowingAuthenticatedUsers) {
            if (/$currentuser/o) {
                $userisinlist = 1;
                last;
            }
        }
        if (!$userisinlist) {
            error("User '"
                . $ENV{"REMOTE_USER"}
                . "' is not allowed to access statistics of this domain/config."
            );
        }
    }
}
if ($AllowAccessFromWebToFollowingIPAddresses && $ENV{'GATEWAY_INTERFACE'}) {
    my $IPAddress = $ENV{"REMOTE_ADDR"}; # IPv4 or IPv6
    my $useripaddress = &Convert_IP_To_Decimal($IPAddress);
    my @allowaccessfromipaddresses =
        split(/[\s,]+/, $AllowAccessFromWebToFollowingIPAddresses);
    my $allowaccess = 0;
    foreach my $ipaddressrange (@allowaccessfromipaddresses) {
        if ($ipaddressrange !~
            /^(\d+\.\d+\.\d+\.\d+)(?:-(\d+\.\d+\.\d+\.\d+))*$/
            && $ipaddressrange !~
            /^([0-9A-Fa-f]{1,4}:){1,7}(:|)([0-9A-Fa-f]{1,4}|\/\d)/) {
            error(
                "AllowAccessFromWebToFollowingIPAddresses is defined to '$AllowAccessFromWebToFollowingIPAddresses' but part of value does not match the correct syntax: IPv4AddressMin[-IPv4AddressMax] or IPv6Address[\/prefix] in \"$ipaddressrange\""
            );
        }

        # Test ip v4
        if ($ipaddressrange =~
            /^(\d+\.\d+\.\d+\.\d+)(?:-(\d+\.\d+\.\d+\.\d+))*$/) {
            my $ipmin = &Convert_IP_To_Decimal($1);
            my $ipmax = $2 ? &Convert_IP_To_Decimal($2) : $ipmin;

            # Is it an authorized ip ?
            if (($useripaddress >= $ipmin) && ($useripaddress <= $ipmax)) {
                $allowaccess = 1;
                last;
            }
        }

        # Test ip v6
        if ($ipaddressrange =~
            /^([0-9A-Fa-f]{1,4}:){1,7}(:|)([0-9A-Fa-f]{1,4}|\/\d)/) {
            if ($ipaddressrange =~ /::\//) {
                my @IPv6split = split(/::/, $ipaddressrange);
                if ($IPAddress =~ /^$IPv6split[0]/) {
                    $allowaccess = 1;
                    last;
                }
            }
            elsif ($ipaddressrange == $IPAddress) {
                $allowaccess = 1;
                last;
            }
        }
    }
    if (!$allowaccess) {
        error("Access to statistics is not allowed from your IP Address "
            . $ENV{"REMOTE_ADDR"});
    }
}
if (($UpdateStats || $MigrateStats)
    && (!$AllowToUpdateStatsFromBrowser)
    && $ENV{'GATEWAY_INTERFACE'}) {
    error(""
        . ($UpdateStats ? "Update" : "Migrate")
        . " of statistics has not been allowed from a browser (AllowToUpdateStatsFromBrowser should be set to 1)."
    );
}
if (scalar keys %HTMLOutput && $MonthRequired eq 'all') {
    if (!$AllowFullYearView) {
        error(
            "Full year view has not been allowed (AllowFullYearView is set to 0)."
        );
    }
    if ($AllowFullYearView < 3 && $ENV{'GATEWAY_INTERFACE'}) {
        error(
            "Full year view has not been allowed from a browser (AllowFullYearView should be set to 3)."
        );
    }
}


%MonthNumLib = (
    "01", "$Message[60]", "02", "$Message[61]", "03", "$Message[62]",
    "04", "$Message[63]", "05", "$Message[64]", "06", "$Message[65]",
    "07", "$Message[66]", "08", "$Message[67]", "09", "$Message[68]",
    "10", "$Message[69]", "11", "$Message[70]", "12", "$Message[71]"
);

# Build ListOfYears list with all existing years
(
    $lastyearbeforeupdate, $lastmonthbeforeupdate, $lastdaybeforeupdate,
    $lasthourbeforeupdate, $lastdatebeforeupdate
)
    = (0, 0, 0, 0, 0);
my $datemask = '';
if ($DatabaseBreak eq 'month') {$datemask = '(\d\d)(\d\d\d\d)';}
elsif ($DatabaseBreak eq 'year') {$datemask = '(\d\d\d\d)';}
elsif ($DatabaseBreak eq 'day') {$datemask = '(\d\d)(\d\d\d\d)(\d\d)';}
elsif ($DatabaseBreak eq 'hour') {
    $datemask = '(\d\d)(\d\d\d\d)(\d\d)(\d\d)';
}

if ($Debug) {
    debug(
        "Scan for last history files into DirData='$DirData' with mask='$datemask'"
    );
}

my $retval = opendir(DIR, "$DirData");
if (!$retval) {
    error("Failed to open directory $DirData : $!");
}
my $regfilesuffix = quotemeta($FileSuffix);
foreach (grep /^$PROG$datemask$regfilesuffix\.txt(|\.gz)$/i,
    file_filt sort readdir DIR) {
    /^$PROG$datemask$regfilesuffix\.txt(|\.gz)$/i;
    if (!$ListOfYears{"$2"} || "$1" gt $ListOfYears{"$2"}) {

        # ListOfYears contains max month found
        $ListOfYears{"$2"} = "$1";
    }
    my $rangestring = ($2 || "") . ($1 || "") . ($3 || "") . ($4 || "");
    if ($rangestring gt $lastdatebeforeupdate) {

        # We are on a new max for mask
        $lastyearbeforeupdate = ($2 || "");
        $lastmonthbeforeupdate = ($1 || "");
        $lastdaybeforeupdate = ($3 || "");
        $lasthourbeforeupdate = ($4 || "");
        $lastdatebeforeupdate = $rangestring;
    }
}
close DIR;

# If at least one file found, get value for LastLine
if ($lastyearbeforeupdate) {

    # Read 'general' section of last history file for LastLine
    &Read_History_With_TmpUpdate($lastyearbeforeupdate, $lastmonthbeforeupdate,
        $lastdaybeforeupdate, $lasthourbeforeupdate, 0, 0, "general");
}

# Warning if lastline in future
if ($LastLine > ($nowtime + 20000)) {
    warning(
        "WARNING: LastLine parameter in history file is '$LastLine' so in future. May be you need to correct manually the line LastLine in some awstats*.$SiteConfig.conf files."
    );
}

# Force LastLine
if ($QueryString =~ /lastline=(\d{14})/i) {
    $LastLine = $1;
}


# Init vars
&Init_HashArray();

#------------------------------------------
# UPDATE PROCESS
#------------------------------------------
my $lastlinenb = 0;
my $lastlineoffset = 0;
my $lastlineoffsetnext = 0;
if ($Debug) {debug("UpdateStats is $UpdateStats", 2);}
if ($UpdateStats && $FrameName ne 'index' && $FrameName ne 'mainleft') {
    # Update only on index page or when not framed to avoid update twice

    my %MonthNum = (
        "Jan", "01", "jan", "01", "Feb", "02", "feb", "02", "Mar", "03",
        "mar", "03", "Apr", "04", "apr", "04", "May", "05", "may", "05",
        "Jun", "06", "jun", "06", "Jul", "07", "jul", "07", "Aug", "08",
        "aug", "08", "Sep", "09", "sep", "09", "Oct", "10", "oct", "10",
        "Nov", "11", "nov", "11", "Dec", "12", "dec", "12"
    )
    ; # MonthNum must be in english because used to translate log date in apache log files

    if (!scalar keys %HTMLOutput) {
        print
            "Create/Update database for config \"$FileConfig\" by AWStats version $VERSION\n";
        print "From data in log file \"$LogFile\"...\n";
    }

    my $lastprocessedyear = $lastyearbeforeupdate || 0;
    my $lastprocessedmonth = $lastmonthbeforeupdate || 0;
    my $lastprocessedday = $lastdaybeforeupdate || 0;
    my $lastprocessedhour = $lasthourbeforeupdate || 0;
    my $lastprocesseddate = '';
    if ($DatabaseBreak eq 'month') {
        $lastprocesseddate =
            sprintf("%04i%02i", $lastprocessedyear, $lastprocessedmonth);
    }
    elsif ($DatabaseBreak eq 'year') {
        $lastprocesseddate = sprintf("%04i%", $lastprocessedyear);
    }
    elsif ($DatabaseBreak eq 'day') {
        $lastprocesseddate = sprintf("%04i%02i%02i",
            $lastprocessedyear, $lastprocessedmonth, $lastprocessedday);
    }
    elsif ($DatabaseBreak eq 'hour') {
        $lastprocesseddate = sprintf(
            "%04i%02i%02i%02i",
            $lastprocessedyear, $lastprocessedmonth,
            $lastprocessedday, $lastprocessedhour
        );
    }

    my @list;

    # Init RobotsSearchIDOrder required for update process
    @list = ();
    if ($LevelForRobotsDetection >= 1) {
        foreach (1 .. $LevelForRobotsDetection) {push @list, "list$_";}
        push @list, "listgen"; # Always added
    }
    foreach my $key (@list) {
        push @RobotsSearchIDOrder, @{"RobotsSearchIDOrder_$key"};
        if ($Debug) {
            debug(
                "Add "
                    . @{"RobotsSearchIDOrder_$key"}
                    . " elements from RobotsSearchIDOrder_$key into RobotsSearchIDOrder",
                2
            );
        }
    }
    if ($Debug) {
        debug(
            "RobotsSearchIDOrder has now " . @RobotsSearchIDOrder . " elements",
            1
        );
    }

    # Init SearchEnginesIDOrder required for update process
    @list = ();
    if ($LevelForSearchEnginesDetection >= 1) {
        foreach (1 .. $LevelForSearchEnginesDetection) {
            push @list, "list$_";
        }
        push @list, "listgen"; # Always added
    }
    foreach my $key (@list) {
        push @SearchEnginesSearchIDOrder, @{"SearchEnginesSearchIDOrder_$key"};
        if ($Debug) {
            debug(
                "Add "
                    . @{"SearchEnginesSearchIDOrder_$key"}
                    . " elements from SearchEnginesSearchIDOrder_$key into SearchEnginesSearchIDOrder",
                2
            );
        }
    }
    if ($Debug) {
        debug(
            "SearchEnginesSearchIDOrder has now "
                . @SearchEnginesSearchIDOrder
                . " elements",
            1
        );
    }

    # Complete HostAliases array
    my $sitetoanalyze = quotemeta(lc($SiteDomain));
    if (!@HostAliases) {
        warning(
            "Warning: HostAliases parameter is not defined, $PROG choose \"$SiteDomain localhost 127.0.0.1\"."
        );
        push @HostAliases, qr/^$sitetoanalyze$/i;
        push @HostAliases, qr/^localhost$/i;
        push @HostAliases, qr/^127\.0\.0\.1$/i;
    }
    else {
        unshift @HostAliases, qr/^$sitetoanalyze$/i;
    } # Add SiteDomain as first value

    # Optimize arrays
    @HostAliases = &OptimizeArray(\@HostAliases, 1);
    if ($Debug) {
        debug("HostAliases precompiled regex list is now @HostAliases", 1);
    }
    @SkipDNSLookupFor = &OptimizeArray(\@SkipDNSLookupFor, 1);
    if ($Debug) {
        debug(
            "SkipDNSLookupFor precompiled regex list is now @SkipDNSLookupFor",
            1
        );
    }
    @SkipHosts = &OptimizeArray(\@SkipHosts, 1);
    if ($Debug) {
        debug("SkipHosts precompiled regex list is now @SkipHosts", 1);
    }
    @SkipReferrers = &OptimizeArray(\@SkipReferrers, 1);
    if ($Debug) {
        debug("SkipReferrers precompiled regex list is now @SkipReferrers",
            1);
    }
    @SkipUserAgents = &OptimizeArray(\@SkipUserAgents, 1);
    if ($Debug) {
        debug("SkipUserAgents precompiled regex list is now @SkipUserAgents",
            1);
    }
    @SkipFiles = &OptimizeArray(\@SkipFiles, $URLNotCaseSensitive);
    if ($Debug) {
        debug("SkipFiles precompiled regex list is now @SkipFiles", 1);
    }
    @OnlyHosts = &OptimizeArray(\@OnlyHosts, 1);
    if ($Debug) {
        debug("OnlyHosts precompiled regex list is now @OnlyHosts", 1);
    }
    @OnlyUsers = &OptimizeArray(\@OnlyUsers, 1);
    if ($Debug) {
        debug("OnlyUsers precompiled regex list is now @OnlyUsers", 1);
    }
    @OnlyUserAgents = &OptimizeArray(\@OnlyUserAgents, 1);
    if ($Debug) {
        debug("OnlyUserAgents precompiled regex list is now @OnlyUserAgents",
            1);
    }
    @OnlyFiles = &OptimizeArray(\@OnlyFiles, $URLNotCaseSensitive);
    if ($Debug) {
        debug("OnlyFiles precompiled regex list is now @OnlyFiles", 1);
    }
    @NotPageFiles = &OptimizeArray(\@NotPageFiles, $URLNotCaseSensitive);
    if ($Debug) {
        debug("NotPageFiles precompiled regex list is now @NotPageFiles", 1);
    }

    # Precompile the regex search strings with qr
    @RobotsSearchIDOrder = map {qr/$_/i} @RobotsSearchIDOrder;
    @WormsSearchIDOrder = map {qr/$_/i} @WormsSearchIDOrder;
    @BrowsersSearchIDOrder = map {qr/$_/i} @BrowsersSearchIDOrder;
    @OSSearchIDOrder = map {qr/$_/i} @OSSearchIDOrder;
    @SearchEnginesSearchIDOrder = map {qr/$_/i} @SearchEnginesSearchIDOrder;
    my $miscquoted = quotemeta("$MiscTrackerUrl");
    my $defquoted = quotemeta("/$DefaultFile[0]");
    my $sitewithoutwww = lc($SiteDomain);
    $sitewithoutwww =~ s/www\.//;
    $sitewithoutwww = quotemeta($sitewithoutwww);

    # Define precompiled regex
    my $regmisc = qr/^$miscquoted/;
    my $regfavico = qr/\/favicon\.ico$/i;
    my $regrobot = qr/\/robots\.txt$/i;
    my $regtruncanchor = qr/#(\w*)$/;
    my $regtruncurl = qr/([$URLQuerySeparators])(.*)$/;
    my $regext = qr/\.(\w{1,6})$/;
    my $regdefault;
    if ($URLNotCaseSensitive) {$regdefault = qr/$defquoted$/i;}
    else {$regdefault = qr/$defquoted$/;}
    my $regipv4 = qr/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;
    my $regipv4l = qr/^::ffff:\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;
    my $regipv6 = qr/^[0-9A-F]*:/i;
    my $regveredge = qr/edge\/([\d]+)/i;
    my $regvermsie = qr/msie([+_ ]|)([\d\.]*)/i;
    #my $regvermsie11      = qr/trident\/7\.\d*\;([+_ ]|)rv:([\d\.]*)/i;
    my $regvermsie11 = qr/trident\/7\.\d*\;([a-zA-Z;+_ ]+|)rv:([\d\.]*)/i;
    my $regvernetscape = qr/netscape.?\/([\d\.]*)/i;
    my $regverfirefox = qr/firefox\/([\d\.]*)/i;
    # For Opera:
    # OPR/15.0.1266 means Opera 15
    # Opera/9.80 ...... Version/12.16 means Opera 12.16
    # Mozilla/5.0 .... Opera 11.51 means Opera 11.51
    my $regveropera = qr/opera\/9\.80\s.+\sversion\/([\d\.]+)|ope?ra?[\/\s]([\d\.]+)/i;
    my $regversafari = qr/safari\/([\d\.]*)/i;
    my $regversafariver = qr/version\/([\d\.]*)/i;
    my $regverchrome = qr/chrome\/([\d\.]*)/i;
    my $regverkonqueror = qr/konqueror\/([\d\.]*)/i;
    my $regversvn = qr/svn\/([\d\.]*)/i;
    my $regvermozilla = qr/mozilla(\/|)([\d\.]*)/i;
    my $regnotie = qr/webtv|omniweb|opera/i;
    my $regnotnetscape = qr/gecko|compatible|opera|galeon|safari|charon/i;
    my $regnotfirefox = qr/flock/i;
    my $regnotsafari = qr/android|arora|chrome|shiira|webpositive/i;
    my $regreferer = qr/^(\w+):\/\/([^\/:]+)(:\d+|)/;
    my $regreferernoquery = qr/^([^$URLQuerySeparators]+)/;
    my $reglocal = qr/^(www\.|)$sitewithoutwww/i;
    my $regget = qr/get|out/i;
    my $regsent = qr/sent|put|in/i;

    # Define value of $pos_xxx, @fieldlib, $PerlParsingFormat
    &DefinePerlParsingFormat($LogFormat);

    # Load DNS Cache Files
    #------------------------------------------
    if ($DNSLookup) {
        &Read_DNS_Cache(\%MyDNSTable, "$DNSStaticCacheFile", "", 1)
        ;                      # Load with save into a second plugin file if plugin enabled and second file not up to date. No use of FileSuffix
        if ($DNSLookup == 1) { # System DNS lookup required
            #if (! eval("use Socket;")) { error("Failed to load perl module Socket."); }
            #use Socket;
            &Read_DNS_Cache(\%TmpDNSLookup, "$DNSLastUpdateCacheFile",
                "$FileSuffix", 0)
            ; # Load with no save into a second plugin file. Use FileSuffix
        }
    }

    # Processing log
    #------------------------------------------

    if ($EnableLockForUpdate) {

        # Trap signals to remove lock
        $SIG{INT} = \&SigHandler; # 2
        #$SIG{KILL} = \&SigHandler;	# 9
        #$SIG{TERM} = \&SigHandler;	# 15
        # Set AWStats update lock
        &Lock_Update(1);
    }

    if ($Debug) {
        debug("Start Update process (lastprocesseddate=$lastprocesseddate)");
    }

    # Open log file
    if ($Debug) {debug("Open log file \"$LogFile\"");}
    open(LOG, "$LogFile")
        || error("Couldn't open server log file \"$LogFile\" : $!");
    binmode LOG
    ; # Avoid premature EOF due to log files corrupted with \cZ or bin chars

    # Define local variables for loop scan
    my @field = ();
    my $counterforflushtest = 0;
    my $qualifdrop = '';
    my $countedtraffic = 0;

    # Reset chrono for benchmark (first call to GetDelaySinceStart)
    &GetDelaySinceStart(1);
    if (!scalar keys %HTMLOutput) {
        print "Phase 1 : First bypass old records, searching new record...\n";
    }

    # Can we try a direct seek access in log ?
    my $line;
    if ($LastLine && $LastLineNumber && $LastLineOffset && $LastLineChecksum) {

        # Try a direct seek access to save time
        if ($Debug) {
            debug(
                "Try a direct access to LastLine=$LastLine, LastLineNumber=$LastLineNumber, LastLineOffset=$LastLineOffset, LastLineChecksum=$LastLineChecksum"
            );
        }
        seek(LOG, $LastLineOffset, 0);
        if ($line = <LOG>) {
            chomp $line;
            $line =~ s/\r$//;
            @field = map(/$PerlParsingFormat/, $line);
            if ($Debug) {
                my $string = '';
                foreach (0 .. @field - 1) {
                    $string .= "$fieldlib[$_]=$field[$_] ";
                }
                if ($Debug) {
                    debug(" Read line after direct access: $string", 1);
                }
            }
            my $checksum = &CheckSum($line);
            if ($Debug) {
                debug(
                    " LastLineChecksum=$LastLineChecksum, Read line checksum=$checksum",
                    1
                );
            }
            if ($checksum == $LastLineChecksum) {
                if (!scalar keys %HTMLOutput) {
                    print
                        "Direct access after last parsed record (after line $LastLineNumber)\n";
                }
                $lastlinenb = $LastLineNumber;
                $lastlineoffset = $LastLineOffset;
                $lastlineoffsetnext = tell LOG;
                $NewLinePhase = 1;
            }
            else {
                if (!scalar keys %HTMLOutput) {
                    print
                        "Direct access to last remembered record has fallen on another record.\nSo searching new records from beginning of log file...\n";
                }
                $lastlinenb = 0;
                $lastlineoffset = 0;
                $lastlineoffsetnext = 0;
                seek(LOG, 0, 0);
            }
        }
        else {
            if (!scalar keys %HTMLOutput) {
                print
                    "Direct access to last remembered record is out of file.\nSo searching it from beginning of log file...\n";
            }
            $lastlinenb = 0;
            $lastlineoffset = 0;
            $lastlineoffsetnext = 0;
            seek(LOG, 0, 0);
        }
    }
    else {

        # No try of direct seek access
        if (!scalar keys %HTMLOutput) {
            print "Searching new records from beginning of log file...\n";
        }
        $lastlinenb = 0;
        $lastlineoffset = 0;
        $lastlineoffsetnext = 0;
    }

    #
    # Loop on each log line
    #
    while ($line = <LOG>) {

        # 20080525 BEGIN Patch to test if first char of $line = hex "00" then conclude corrupted with binary code
        my $FirstHexChar;
        $FirstHexChar = sprintf("%02X", ord(substr($line, 0, 1)));
        if ($FirstHexChar eq '00') {
            $NbOfLinesCorrupted++;
            if ($ShowCorrupted) {
                print "Corrupted record line "
                    . ($lastlinenb + $NbOfLinesParsed)
                    . " (record starts with hex 00; binary code): $line\n";
            }
            if ($NbOfLinesParsed >= $NbOfLinesForCorruptedLog
                && $NbOfLinesParsed == $NbOfLinesCorrupted) {
                error("Format error", $line, $LogFile);
            } # Exit with format error
            next;
        }
        # 20080525 END

        chomp $line;
        $line =~ s/\r$//;
        if ($UpdateFor && $NbOfLinesParsed >= $UpdateFor) {last;}
        $NbOfLinesParsed++;

        $lastlineoffset = $lastlineoffsetnext;
        $lastlineoffsetnext = tell LOG;

        if ($ShowSteps) {
            if ((++$NbOfLinesShowsteps & $NBOFLINESFORBENCHMARK) == 0) {
                my $delay = &GetDelaySinceStart(0);
                print "$NbOfLinesParsed lines processed ("
                    . ($delay > 0 ? $delay : 1000) . " ms, "
                    . int(
                    1000 * $NbOfLinesShowsteps / ($delay > 0 ? $delay : 1000)
                )
                    . " lines/second)\n";
            }
        }

        if ($LogFormat eq '2' && $line =~ /^#Fields:/) {
            my @fixField = map(/^#Fields: (.*)/, $line);
            if ($fixField[0] !~ /s-kernel-time/) {
                debug("Found new log format: '" . $fixField[0] . "'", 1);
                &DefinePerlParsingFormat($fixField[0]);
            }
        }

        # Parse line record to get all required fields
        my $json_error = undef;
        if (defined $PerlParsingFormatJsonMap) {
            my $json = undef;
            try {
                $json = JSON::XS->new->utf8->decode($line);
            }
            catch {
                $json_error = $_;
                $json_error =~ s/^\s+|\s+$//g;
            }
            @field = ();
            if ($json) {
                for my $el (@fieldlib) {
                    my $json_key = ${$PerlParsingFormatJsonMap}{$el};
                    push(@field, ${$json}{$json_key});
                }
            }
        }
        else {
            @field = map(/$PerlParsingFormat/, $line);
        }
        if (!@field) {
            # see if the line is a comment, blank or corrupted
            if ($line =~ /^#/ || $line =~ /^!/) {
                $NbOfLinesComment++;
                if ($ShowCorrupted) {
                    print "Comment record line "
                        . ($lastlinenb + $NbOfLinesParsed)
                        . ": $line\n";
                }
            }
            elsif ($line =~ /^\s*$/) {
                $NbOfLinesBlank++;
                if ($ShowCorrupted) {
                    print "Blank record line "
                        . ($lastlinenb + $NbOfLinesParsed)
                        . "\n";
                }
            }
            else {
                $NbOfLinesCorrupted++;
                if ($ShowCorrupted) {
                    my $err = $json_error ? $json_error : "record format does not match LogFormat parameter";
                    print "Corrupted record line "
                        . ($lastlinenb + $NbOfLinesParsed)
                        . " ($err): $line\n";
                }
            }
            if ($NbOfLinesParsed >= $NbOfLinesForCorruptedLog
                && $NbOfLinesParsed == ($NbOfLinesCorrupted + $NbOfLinesComment + $NbOfLinesBlank)) {
                error("Format error", $line, $LogFile);
            }                                         # Exit with format error
            if ($line =~ /^__end_of_file__/i) {last;} # For test purpose only
            next;
        }

        if ($Debug) {
            my $string = '';
            foreach (0 .. @field - 1) {
                $string .= "$fieldlib[$_]=$field[$_] ";
            }
            if ($Debug) {
                debug(
                    " Correct format line "
                        . ($lastlinenb + $NbOfLinesParsed)
                        . ": $string",
                    4
                );
            }
        }

        # Drop wrong virtual host name
        #----------------------------------------------------------------------
        if ($pos_vh >= 0 && $field[$pos_vh] !~ /^$SiteDomain$/i) {
            my $skip = 1;
            foreach (@HostAliases) {
                if ($field[$pos_vh] =~ /$_/) {
                    $skip = 0;
                    last;
                }
            }
            if ($skip) {
                $NbOfLinesDropped++;
                if ($ShowDropped) {
                    print
                        "Dropped record (virtual hostname '$field[$pos_vh]' does not match SiteDomain='$SiteDomain' nor HostAliases parameters): $line\n";
                }
                next;
            }
        }

        # Drop wrong method/protocol
        #---------------------------
        if ($LogType ne 'M') {$field[$pos_url] =~ s/\s/%20/g;}
        if (
            $LogType eq 'W'
                && (
                $field[$pos_method] eq 'GET'
                    || $field[$pos_method] eq 'POST'
                    || $field[$pos_method] eq 'HEAD'
                    || $field[$pos_method] eq 'PROPFIND'
                    || $field[$pos_method] eq 'CHECKOUT'
                    || $field[$pos_method] eq 'LOCK'
                    || $field[$pos_method] eq 'PROPPATCH'
                    || $field[$pos_method] eq 'OPTIONS'
                    || $field[$pos_method] eq 'MKACTIVITY'
                    || $field[$pos_method] eq 'PUT'
                    || $field[$pos_method] eq 'MERGE'
                    || $field[$pos_method] eq 'DELETE'
                    || $field[$pos_method] eq 'REPORT'
                    || $field[$pos_method] eq 'MKCOL'
                    || $field[$pos_method] eq 'COPY'
                    || $field[$pos_method] eq 'RPC_IN_DATA'
                    || $field[$pos_method] eq 'RPC_OUT_DATA'
                    || $field[$pos_method] eq 'OK'   # Webstar
                    || $field[$pos_method] eq 'ERR!' # Webstar
                    || $field[$pos_method] eq 'PRIV' # Webstar
            )
        ) {

            # HTTP request.	Keep only GET, POST, HEAD, *OK* and ERR! for Webstar. Do not keep OPTIONS, TRACE
        }
        elsif (
            ($LogType eq 'W' || $LogType eq 'S')
                && (uc($field[$pos_method]) eq 'GET'
                || uc($field[$pos_method]) eq 'MMS'
                || uc($field[$pos_method]) eq 'RTSP'
                || uc($field[$pos_method]) eq 'HTTP'
                || uc($field[$pos_method]) eq 'RTP')
        ) {

            # Streaming request (windows media server, realmedia or darwin streaming server)
        }
        elsif ($LogType eq 'M' && $field[$pos_method] eq 'SMTP') {

            # Mail request ('SMTP' for mail log with maillogconvert.pl preprocessor)
        }
        elsif (
            $LogType eq 'F'
                && ($field[$pos_method] eq 'RETR'
                || $field[$pos_method] eq 'D'
                || $field[$pos_method] eq 'o'
                || $field[$pos_method] =~ /$regget/o)
        ) {

            # FTP GET request
        }
        elsif (
            $LogType eq 'F'
                && ($field[$pos_method] eq 'STOR'
                || $field[$pos_method] eq 'U'
                || $field[$pos_method] eq 'i'
                || $field[$pos_method] =~ /$regsent/o)
        ) {

            # FTP SENT request
        }
        elsif ($line =~ m/#Fields:/) {
            # log #fields as comment
            $NbOfLinesComment++;
            next;
        }
        else {
            $NbOfLinesDropped++;
            if ($ShowDropped) {
                print
                    "Dropped record (method/protocol '$field[$pos_method]' not qualified when LogType=$LogType): $line\n";
            }
            next;
        }

        # Reformat date for IIS date -DWG 12/8/2008
        if ($field[$pos_date] =~ /,/) {
            $field[$pos_date] =~ s/,//;
            my @split_date = split(' ', $field[$pos_date]);
            my @dateparts2 = split('/', $split_date[0]);
            my @timeparts2 = split(':', $split_date[1]);
            #add leading zero
            for ($dateparts2[0], $dateparts2[1], $timeparts2[0], $timeparts2[1], $timeparts2[2]) {
                if ($_ =~ /^.$/) {
                    $_ = '0' . $_;
                }

            }

            $field[$pos_date] = "$dateparts2[2]-$dateparts2[0]-$dateparts2[1] $timeparts2[0]:$timeparts2[1]:$timeparts2[2]";
        }

        $field[$pos_date] =~
            tr/,-\/ \tT/::::::/s; # " \t" is used instead of "\s" not known with tr
        my @dateparts =
            split(/:/, $field[$pos_date]); # tr and split faster than @dateparts=split(/[\/\-:\s]/,$field[$pos_date])
        # Detected date format:
        # dddddddddd, YYYY-MM-DD HH:MM:SS (IIS), MM/DD/YY\tHH:MM:SS,
        # DD/Month/YYYY:HH:MM:SS (Apache), DD/MM/YYYY HH:MM:SS, Mon DD HH:MM:SS,
        # YYYY-MM-DDTHH:MM:SS (iso)
        if (!$dateparts[1]) {
            # Unix timestamp
            (
                $dateparts[5], $dateparts[4], $dateparts[3],
                $dateparts[0], $dateparts[1], $dateparts[2]
            )
                = localtime(int($field[$pos_date]));
            $dateparts[1]++;
            $dateparts[2] += 1900;
        }
        elsif ($dateparts[0] =~ /^....$/) {
            my $tmp = $dateparts[0];
            $dateparts[0] = $dateparts[2];
            $dateparts[2] = $tmp;
        }
        elsif ($field[$pos_date] =~ /^..:..:..:/) {
            $dateparts[2] += 2000;
            my $tmp = $dateparts[0];
            $dateparts[0] = $dateparts[1];
            $dateparts[1] = $tmp;
        }
        elsif ($dateparts[0] =~ /^...$/) {
            my $tmp = $dateparts[0];
            $dateparts[0] = $dateparts[1];
            $dateparts[1] = $tmp;
            $tmp = $dateparts[5];
            $dateparts[5] = $dateparts[4];
            $dateparts[4] = $dateparts[3];
            $dateparts[3] = $dateparts[2];
            $dateparts[2] = $tmp || $nowyear;
        }
        if (exists($MonthNum{ $dateparts[1] })) {
            $dateparts[1] = $MonthNum{ $dateparts[1] };
        } # Change lib month in num month if necessary
        if ($dateparts[1] <= 0) {
            # Date corrupted (for example $dateparts[1]='dic' for december month in a spanish log file)
            $NbOfLinesCorrupted++;
            if ($ShowCorrupted) {
                print "Corrupted record line "
                    . ($lastlinenb + $NbOfLinesParsed)
                    . " (bad date format for month, may be month are not in english ?): $line\n";
            }
            next;
        }

        # Now @dateparts is (DD,MM,YYYY,HH,MM,SS) and we're going to create $timerecord=YYYYMMDDHHMMSS
        if ($PluginsLoaded{'ChangeTime'}{'timezone'}) {
            @dateparts = ChangeTime_timezone(\@dateparts);
        }
        my $yearrecord = int($dateparts[2]);
        my $monthrecord = int($dateparts[1]);
        my $dayrecord = int($dateparts[0]);
        my $hourrecord = int($dateparts[3]);
        my $daterecord = '';
        if ($DatabaseBreak eq 'month') {
            $daterecord = sprintf("%04i%02i", $yearrecord, $monthrecord);
        }
        elsif ($DatabaseBreak eq 'year') {
            $daterecord = sprintf("%04i%", $yearrecord);
        }
        elsif ($DatabaseBreak eq 'day') {
            $daterecord =
                sprintf("%04i%02i%02i", $yearrecord, $monthrecord, $dayrecord);
        }
        elsif ($DatabaseBreak eq 'hour') {
            $daterecord = sprintf("%04i%02i%02i%02i",
                $yearrecord, $monthrecord, $dayrecord, $hourrecord);
        }

        # TODO essayer de virer yearmonthrecord
        my $yearmonthdayrecord =
            sprintf("$dateparts[2]%02i%02i", $dateparts[1], $dateparts[0]);
        my $timerecord =
            ((int("$yearmonthdayrecord") * 100 + $dateparts[3]) * 100 +
                $dateparts[4]) * 100 + $dateparts[5];

        # Check date
        #-----------------------
        if ($LogType eq 'M' && $timerecord > $tomorrowtime) {

            # Postfix/Sendmail does not store year, so we assume that year is year-1 if record is in future
            $yearrecord--;
            if ($DatabaseBreak eq 'month') {
                $daterecord = sprintf("%04i%02i", $yearrecord, $monthrecord);
            }
            elsif ($DatabaseBreak eq 'year') {
                $daterecord = sprintf("%04i%", $yearrecord);
            }
            elsif ($DatabaseBreak eq 'day') {
                $daterecord = sprintf("%04i%02i%02i",
                    $yearrecord, $monthrecord, $dayrecord);
            }
            elsif ($DatabaseBreak eq 'hour') {
                $daterecord = sprintf("%04i%02i%02i%02i",
                    $yearrecord, $monthrecord, $dayrecord, $hourrecord);
            }

            # TODO essayer de virer yearmonthrecord
            $yearmonthdayrecord =
                sprintf("$yearrecord%02i%02i", $dateparts[1], $dateparts[0]);
            $timerecord =
                ((int("$yearmonthdayrecord") * 100 + $dateparts[3]) * 100 +
                    $dateparts[4]) * 100 + $dateparts[5];
        }
        if ($timerecord < 10000000000000 || $timerecord > $tomorrowtime) {
            $NbOfLinesCorrupted++;
            if ($ShowCorrupted) {
                print
                    "Corrupted record (invalid date, timerecord=$timerecord): $line\n";
            }
            next; # Should not happen, kept in case of parasite/corrupted line
        }
        if ($NewLinePhase) {

            # TODO NOTSORTEDRECORDTOLERANCE does not work around midnight
            if ($timerecord < ($LastLine - $NOTSORTEDRECORDTOLERANCE)) {

                # Should not happen, kept in case of parasite/corrupted old line
                $NbOfLinesCorrupted++;
                if ($ShowCorrupted) {
                    print
                        "Corrupted record (date $timerecord lower than $LastLine-$NOTSORTEDRECORDTOLERANCE): $line\n";
                }
                next;
            }
        }
        else {
            if ($timerecord <= $LastLine) {
                # Already processed
                $NbOfOldLines++;
                next;
            }

            # We found a new line. This will replace comparison "<=" with "<" between timerecord and LastLine (we should have only new lines now)
            $NewLinePhase = 1; # We will never enter here again
            if ($ShowSteps) {
                if ($NbOfLinesShowsteps > 1
                    && ($NbOfLinesShowsteps & $NBOFLINESFORBENCHMARK)) {
                    my $delay = &GetDelaySinceStart(0);
                    print ""
                        . ($NbOfLinesParsed - 1)
                        . " lines processed ("
                        . ($delay > 0 ? $delay : 1000) . " ms, "
                        . int(1000 * ($NbOfLinesShowsteps - 1) /
                        ($delay > 0 ? $delay : 1000))
                        . " lines/second)\n";
                }
                &GetDelaySinceStart(1);
                $NbOfLinesShowsteps = 1;
            }
            if (!scalar keys %HTMLOutput) {
                print
                    "Phase 2 : Now process new records (Flush history on disk after "
                        . ($LIMITFLUSH << 2)
                        . " hosts)...\n";

                #print "Phase 2 : Now process new records (Flush history on disk after ".($LIMITFLUSH<<2)." hosts or ".($LIMITFLUSH)." URLs)...\n";
            }
        }

        # Convert URL for Webstar to common URL
        if ($LogFormat eq '3') {
            $field[$pos_url] =~ s/:/\//g;
            if ($field[$pos_code] eq '-') {$field[$pos_code] = '200';}
        }

        # Here, field array, timerecord and yearmonthdayrecord are initialized for log record
        if ($Debug) {
            debug("  This is a not already processed record ($timerecord)",
                4);
        }

        # Check if there's a CloudFlare Visitor IP in the query string
        # If it does, replace the ip
        if ($pos_query >= 0 && $field[$pos_query] && $field[$pos_query] =~ /\[CloudFlare_Visitor_IP[:](\d+[.]\d+[.]\d+[.]\d+)\]/) {
            $field[$pos_host] = "$1";
        }

        # We found a new line
        #----------------------------------------
        if ($timerecord > $LastLine) {
            $LastLine = $timerecord;
        } # Test should always be true except with not sorted log files

        # Skip for some client host IP addresses, some URLs, other URLs
        if (
            @SkipHosts
                && (&SkipHost($field[$pos_host])
                || ($pos_hostr && &SkipHost($field[$pos_hostr])))
        ) {
            $qualifdrop =
                "Dropped record (host $field[$pos_host]"
                    . ($pos_hostr ? " and $field[$pos_hostr]" : "")
                    . " not qualified by SkipHosts)";
        }
        elsif (@SkipFiles && &SkipFile($field[$pos_url])) {
            $qualifdrop =
                "Dropped record (URL $field[$pos_url] not qualified by SkipFiles)";
        }
        elsif (@SkipUserAgents
            && $pos_agent >= 0
            && &SkipUserAgent($field[$pos_agent])) {
            $qualifdrop =
                "Dropped record (user agent '$field[$pos_agent]' not qualified by SkipUserAgents)";
        }
        elsif (@SkipReferrers
            && $pos_referer >= 0
            && &SkipReferrer($field[$pos_referer])) {
            $qualifdrop =
                "Dropped record (URL $field[$pos_referer] not qualified by SkipReferrers)";
        }
        elsif (@OnlyHosts
            && !&OnlyHost($field[$pos_host])
            && (!$pos_hostr || !&OnlyHost($field[$pos_hostr]))) {
            $qualifdrop =
                "Dropped record (host $field[$pos_host]"
                    . ($pos_hostr ? " and $field[$pos_hostr]" : "")
                    . " not qualified by OnlyHosts)";
        }
        elsif (@OnlyUsers && !&OnlyUser($field[$pos_logname])) {
            $qualifdrop =
                "Dropped record (URL $field[$pos_logname] not qualified by OnlyUsers)";
        }
        elsif (@OnlyFiles && !&OnlyFile($field[$pos_url])) {
            $qualifdrop =
                "Dropped record (URL $field[$pos_url] not qualified by OnlyFiles)";
        }
        elsif (@OnlyUserAgents && !&OnlyUserAgent($field[$pos_agent])) {
            $qualifdrop =
                "Dropped record (user agent '$field[$pos_agent]' not qualified by OnlyUserAgents)";
        }
        if ($qualifdrop) {
            $NbOfLinesDropped++;
            if ($Debug) {debug("$qualifdrop: $line", 4);}
            if ($ShowDropped) {print "$qualifdrop: $line\n";}
            $qualifdrop = '';
            next;
        }

        # Record is approved
        #-------------------

        # Is it in a new break section ?
        #-------------------------------
        if ($daterecord > $lastprocesseddate) {

            # A new break to process
            if ($lastprocesseddate > 0) {

                # We save data of previous break
                &Read_History_With_TmpUpdate(
                    $lastprocessedyear, $lastprocessedmonth,
                    $lastprocessedday, $lastprocessedhour,
                    1, 1,
                    "all", ($lastlinenb + $NbOfLinesParsed),
                    $lastlineoffset, &CheckSum($line)
                );
                $counterforflushtest = 0; # We reset counterforflushtest
            }
            $lastprocessedyear = $yearrecord;
            $lastprocessedmonth = $monthrecord;
            $lastprocessedday = $dayrecord;
            $lastprocessedhour = $hourrecord;
            if ($DatabaseBreak eq 'month') {
                $lastprocesseddate =
                    sprintf("%04i%02i", $yearrecord, $monthrecord);
            }
            elsif ($DatabaseBreak eq 'year') {
                $lastprocesseddate = sprintf("%04i%", $yearrecord);
            }
            elsif ($DatabaseBreak eq 'day') {
                $lastprocesseddate = sprintf("%04i%02i%02i",
                    $yearrecord, $monthrecord, $dayrecord);
            }
            elsif ($DatabaseBreak eq 'hour') {
                $lastprocesseddate = sprintf("%04i%02i%02i%02i",
                    $yearrecord, $monthrecord, $dayrecord, $hourrecord);
            }
        }

        $countedtraffic = 0;
        $NbOfNewLines++;

        # Convert $field[$pos_size]
        # if ($field[$pos_size] eq '-') { $field[$pos_size]=0; }

        # Define a clean target URL and referrer URL
        # We keep a clean $field[$pos_url] and
        # we store original value for urlwithnoquery, tokenquery and standalonequery
        #---------------------------------------------------------------------------

        # Decode "unreserved characters" - URIs with common ASCII characters
        # percent-encoded are equivalent to their unencoded versions.
        #
        # See section 2.3. of RFC 3986.

        $field[$pos_url] = DecodeRFC3986UnreservedString($field[$pos_url]);

        if ($URLNotCaseSensitive) {$field[$pos_url] = lc($field[$pos_url]);}

        # Possible URL syntax for $field[$pos_url]: /mydir/mypage.ext?param1=x&param2=y#aaa, /mydir/mypage.ext#aaa, /
        my $urlwithnoquery;
        my $tokenquery;
        my $standalonequery;
        my $anchor = '';
        if ($field[$pos_url] =~ s/$regtruncanchor//o) {
            $anchor = $1;
        } # Remove and save anchor
        if ($URLWithQuery) {
            $urlwithnoquery = $field[$pos_url];
            my $foundparam = ($urlwithnoquery =~ s/$regtruncurl//o);
            $tokenquery = $1 || '';
            $standalonequery = $2 || '';

            # For IIS setup, if pos_query is enabled we need to combine the URL to query strings
            if (!$foundparam
                && $pos_query >= 0
                && $field[$pos_query]
                && $field[$pos_query] ne '-') {
                $foundparam = 1;
                $tokenquery = '?';
                $standalonequery = $field[$pos_query];

                # Define query
                $field[$pos_url] .= '?' . $field[$pos_query];
            }
            if ($foundparam) {

                # Keep only params that are defined in URLWithQueryWithOnlyFollowingParameters
                my $newstandalonequery = '';
                if (@URLWithQueryWithOnly) {
                    foreach (@URLWithQueryWithOnly) {
                        foreach my $p (split(/&/, $standalonequery)) {
                            if ($URLNotCaseSensitive) {
                                if ($p =~ /^$_=/i) {
                                    $newstandalonequery .= "$p&";
                                    last;
                                }
                            }
                            else {
                                if ($p =~ /^$_=/) {
                                    $newstandalonequery .= "$p&";
                                    last;
                                }
                            }
                        }
                    }
                    chop $newstandalonequery;
                }

                # Remove params that are marked to be ignored in URLWithQueryWithoutFollowingParameters
                elsif (@URLWithQueryWithout) {
                    foreach my $p (split(/&/, $standalonequery)) {
                        my $found = 0;
                        foreach (@URLWithQueryWithout) {

                            #if ($Debug) { debug("  Check if '$_=' is param '$p' to remove it from query",5); }
                            if ($URLNotCaseSensitive) {
                                if ($p =~ /^$_=/i) {
                                    $found = 1;
                                    last;
                                }
                            }
                            else {
                                if ($p =~ /^$_=/) {
                                    $found = 1;
                                    last;
                                }
                            }
                        }
                        if (!$found) {$newstandalonequery .= "$p&";}
                    }
                    chop $newstandalonequery;
                }
                else {$newstandalonequery = $standalonequery;}

                # Define query
                $field[$pos_url] = $urlwithnoquery;
                if ($newstandalonequery) {
                    $field[$pos_url] .= "$tokenquery$newstandalonequery";
                }
            }
        }
        else {

            # Trunc parameters of URL
            $field[$pos_url] =~ s/$regtruncurl//o;
            $urlwithnoquery = $field[$pos_url];
            $tokenquery = $1 || '';
            $standalonequery = $2 || '';

            # For IIS setup, if pos_query is enabled we need to use it for query strings
            if ($pos_query >= 0
                && $field[$pos_query]
                && $field[$pos_query] ne '-') {
                $tokenquery = '?';
                $standalonequery = $field[$pos_query];
            }
        }
        if ($URLWithAnchor && $anchor) {
            $field[$pos_url] .= "#$anchor";
        } # Restore anchor
        # Here now urlwithnoquery is /mydir/mypage.ext, /mydir, /, /page#XXX
        # Here now tokenquery is '' or '?' or ';'
        # Here now standalonequery is '' or 'param1=x'

        # Define page and extension
        #--------------------------
        my $PageBool = 1;

        # Extension
        my $extension = Get_Extension($regext, $urlwithnoquery);
        if ($NotPageList{$extension} ||
            ($MimeHashLib{$extension}[1]) && $MimeHashLib{$extension}[1] ne 'p') {$PageBool = 0;}
        if (@NotPageFiles && &NotPageFile($field[$pos_url])) {$PageBool = 0;}

        # Analyze: misc tracker (must be before return code)
        #---------------------------------------------------
        if ($urlwithnoquery =~ /$regmisc/o) {
            if ($Debug) {
                debug(
                    "  Found an URL that is a MiscTracker record with standalonequery=$standalonequery",
                    2
                );
            }
            my $foundparam = 0;
            foreach (split(/&/, $standalonequery)) {
                if ($_ =~ /^screen=(\d+)x(\d+)/i) {
                    $foundparam++;
                    $_screensize_h{"$1x$2"}++;
                    next;
                }

                #if ($_ =~ /cdi=(\d+)/i) 			{ $foundparam++; $_screendepth_h{"$1"}++; next; }
                if ($_ =~ /^nojs=(\w+)/i) {
                    $foundparam++;
                    if ($1 eq 'y') {$_misc_h{"JavascriptDisabled"}++;}
                    next;
                }
                if ($_ =~ /^java=(\w+)/i) {
                    $foundparam++;
                    if ($1 eq 'true') {$_misc_h{"JavaEnabled"}++;}
                    next;
                }
                if ($_ =~ /^shk=(\w+)/i) {
                    $foundparam++;
                    if ($1 eq 'y') {$_misc_h{"DirectorSupport"}++;}
                    next;
                }
                if ($_ =~ /^fla=(\w+)/i) {
                    $foundparam++;
                    if ($1 eq 'y') {$_misc_h{"FlashSupport"}++;}
                    next;
                }
                if ($_ =~ /^rp=(\w+)/i) {
                    $foundparam++;
                    if ($1 eq 'y') {$_misc_h{"RealPlayerSupport"}++;}
                    next;
                }
                if ($_ =~ /^mov=(\w+)/i) {
                    $foundparam++;
                    if ($1 eq 'y') {$_misc_h{"QuickTimeSupport"}++;}
                    next;
                }
                if ($_ =~ /^wma=(\w+)/i) {
                    $foundparam++;
                    if ($1 eq 'y') {
                        $_misc_h{"WindowsMediaPlayerSupport"}++;
                    }
                    next;
                }
                if ($_ =~ /^pdf=(\w+)/i) {
                    $foundparam++;
                    if ($1 eq 'y') {$_misc_h{"PDFSupport"}++;}
                    next;
                }
            }
            if ($foundparam) {$_misc_h{"TotalMisc"}++;}
        }

        # Analyze: successful favicon (=> countedtraffic=1 if favicon)
        #--------------------------------------------------
        if ($urlwithnoquery =~ /$regfavico/o) {
            if ($field[$pos_code] != 404) {
                $_misc_h{'AddToFavourites'}++;
            }
            $countedtraffic =
                1; # favicon is a case that must not be counted anywhere else
            $_time_nv_h[$hourrecord]++;
            if ($field[$pos_code] != 404 && $pos_size > 0) {
                $_time_nv_k[$hourrecord] += int($field[$pos_size]);
            }
        }

        # Analyze: Worms (=> countedtraffic=2 if worm)
        #---------------------------------------------
        if (!$countedtraffic) {
            if ($LevelForWormsDetection) {
                foreach (@WormsSearchIDOrder) {
                    if ($field[$pos_url] =~ /$_/) {

                        # It's a worm
                        my $worm = &UnCompileRegex($_);
                        if ($Debug) {
                            debug(
                                " Record is a hit from a worm identified by '$worm'",
                                2
                            );
                        }
                        $worm = $WormsHashID{$worm} || 'unknown';
                        $_worm_h{$worm}++;
                        if ($pos_size > 0) {$_worm_k{$worm} += int($field[$pos_size]);}
                        $_worm_l{$worm} = $timerecord;
                        $countedtraffic = 2;
                        if ($PageBool) {$_time_nv_p[$hourrecord]++;}
                        $_time_nv_h[$hourrecord]++;
                        if ($pos_size > 0) {$_time_nv_k[$hourrecord] += int($field[$pos_size]);}
                        last;
                    }
                }
            }
        }

        # Analyze: Status code (=> countedtraffic=3 if error)
        #----------------------------------------------------
        if (!$countedtraffic) {
            if ($LogType eq 'W' || $LogType eq 'S') { # HTTP record or Stream record
                if ($ValidHTTPCodes{ $field[$pos_code] }) {
                                                      # Code is valid
                    if (int($field[$pos_code]) == 304 && $pos_size > 0) {$field[$pos_size] = 0;}
                    # track downloads
                    if (int($field[$pos_code]) == 200 && $MimeHashLib{$extension}[1] eq 'd' && $urlwithnoquery !~ /robots.txt$/) # We track download if $MimeHashLib{$extension}[1] = 'd'
                    {
                        $_downloads{$urlwithnoquery}->{'AWSTATS_HITS'}++;
                        $_downloads{$urlwithnoquery}->{'AWSTATS_SIZE'} += ($pos_size > 0 ? int($field[$pos_size]) : 0);
                        if ($Debug) {debug(" New download detected: '$urlwithnoquery'", 2);}
                    }
                    # handle 206 download continuation message IF we had a successful 200 before, otherwise it goes in errors
                }
                elsif (int($field[$pos_code]) == 206
                    #&& $_downloads{$urlwithnoquery}->{$field[$pos_host]}[0] > 0
                    && ($MimeHashLib{$extension}[1] eq 'd')) {
                    $_downloads{$urlwithnoquery}->{'AWSTATS_SIZE'} += ($pos_size > 0 ? int($field[$pos_size]) : 0);
                    $_downloads{$urlwithnoquery}->{'AWSTATS_206'}++;
                    #$_downloads{$urlwithnoquery}->{$field[$pos_host]}[1] = $timerecord;
                    if ($pos_size > 0) {
                        #$_downloads{$urlwithnoquery}->{$field[$pos_host]}[2] = int($field[$pos_size]);
                        $DayBytes{$yearmonthdayrecord} += int($field[$pos_size]);
                        $_time_k[$hourrecord] += int($field[$pos_size]);
                    }
                    $countedtraffic = 6; # 206 continued download, so we track bandwidth but not pages or hits
                    if ($Debug) {debug(" Download continuation detected: '$urlwithnoquery'", 2);}
                }
                else {
                    # Code is not valid
                    if ($field[$pos_code] !~ /^\d\d\d$/) {
                        $field[$pos_code] = 999;
                    }
                    $_errors_h{ $field[$pos_code] }++;
                    if ($pos_size > 0) {$_errors_k{ $field[$pos_code] } += int($field[$pos_size]);}
                    foreach my $code (keys %TrapInfosForHTTPErrorCodes) {
                        if ($field[$pos_code] == $code) {

                            # This is an error code which referrer need to be tracked
                            my $newurl =
                                substr($field[$pos_url], 0,
                                    $MaxLengthOfStoredURL);
                            $newurl =~ s/[$URLQuerySeparators].*$//;
                            $_sider_h{$code}{$newurl}++;
                            if ($pos_referer >= 0 && $ShowHTTPErrorsPageDetail =~ /R/i) {
                                my $newreferer = $field[$pos_referer];
                                if (!$URLReferrerWithQuery) {
                                    $newreferer =~ s/[$URLQuerySeparators].*$//;
                                }
                                $_referer_h{$code}{$newurl} = $newreferer;
                            }
                            if ($pos_host >= 0 && $ShowHTTPErrorsPageDetail =~ /H/i) {
                                my $newhost = $field[$pos_host];
                                if (!$URLReferrerWithQuery) {
                                    $newhost =~ s/[$URLQuerySeparators].*$//;
                                }
                                $_err_host_h{$code}{$newurl} = $newhost;
                                last;
                            }
                        }
                    }
                    if ($Debug) {
                        debug(
                            " Record stored in the status code chart (status code=$field[$pos_code])",
                            3
                        );
                    }
                    $countedtraffic = 3;
                    if ($PageBool) {$_time_nv_p[$hourrecord]++;}
                    $_time_nv_h[$hourrecord]++;
                    if ($pos_size > 0) {$_time_nv_k[$hourrecord] += int($field[$pos_size]);}
                }
            }
            elsif ($LogType eq 'M') { # Mail record
                if (!$ValidSMTPCodes{ $field[$pos_code] }) {
                    # Code is not valid
                    $_errors_h{ $field[$pos_code] }++;
                    if ($field[$pos_size] ne '-' && $pos_size > 0) {
                        $_errors_k{ $field[$pos_code] } +=
                            int($field[$pos_size]);
                    }
                    if ($Debug) {
                        debug(
                            " Record stored in the status code chart (status code=$field[$pos_code])",
                            3
                        );
                    }
                    $countedtraffic = 3;
                    if ($PageBool) {$_time_nv_p[$hourrecord]++;}
                    $_time_nv_h[$hourrecord]++;
                    if ($field[$pos_size] ne '-' && $pos_size > 0) {
                        $_time_nv_k[$hourrecord] += int($field[$pos_size]);
                    }
                }
            }
            elsif ($LogType eq 'F') { # FTP record
            }
        }

        # Analyze: Robot from robot database (=> countedtraffic=4 if robot)
        #------------------------------------------------------------------
        if (!$countedtraffic || $countedtraffic == 6) {
            if ($pos_agent >= 0) {
                if ($DecodeUA) {
                    $field[$pos_agent] =~ s/%20/_/g;
                } # This is to support servers (like Roxen) that writes user agent with %20 in it
                $UserAgent = $field[$pos_agent];
                if ($UserAgent && $UserAgent eq '-') {$UserAgent = '';}

                if ($LevelForRobotsDetection) {

                    if ($UserAgent) {
                        my $uarobot = $TmpRobot{$UserAgent};
                        if (!$uarobot) {

                            #study $UserAgent;		Does not increase speed
                            foreach (@RobotsSearchIDOrder) {
                                if ($UserAgent =~ /$_/) {
                                    my $bot = &UnCompileRegex($_);
                                    $TmpRobot{$UserAgent} = $uarobot = "$bot"
                                    ; # Last time, we won't search if robot or not. We know it is.
                                    if ($Debug) {
                                        debug(
                                            "  UserAgent '$UserAgent' is added to TmpRobot with value '$bot'",
                                            2
                                        );
                                    }
                                    last;
                                }
                            }
                            if (!$uarobot) { # Last time, we won't search if robot or not. We know it's not.
                                $TmpRobot{$UserAgent} = $uarobot = '-';
                            }
                        }
                        if ($uarobot ne '-') {

                            # If robot, we stop here
                            if ($Debug) {
                                debug(
                                    "  UserAgent '$UserAgent' contains robot ID '$uarobot'",
                                    2
                                );
                            }
                            $_robot_h{$uarobot}++;
                            if ($field[$pos_size] ne '-' && $pos_size > 0) {
                                $_robot_k{$uarobot} += int($field[$pos_size]);
                            }
                            $_robot_l{$uarobot} = $timerecord;
                            if ($urlwithnoquery =~ /$regrobot/o) {
                                $_robot_r{$uarobot}++;
                            }
                            $countedtraffic = 4;
                            if ($PageBool) {$_time_nv_p[$hourrecord]++;}
                            $_time_nv_h[$hourrecord]++;
                            if ($field[$pos_size] ne '-' && $pos_size > 0) {
                                $_time_nv_k[$hourrecord] +=
                                    int($field[$pos_size]);
                            }
                        }
                    }
                    else {
                        my $uarobot = 'no_user_agent';

                        # It's a robot or at least a bad browser, we stop here
                        if ($Debug) {
                            debug(
                                "  UserAgent not defined so it should be a robot, saved as robot 'no_user_agent'",
                                2
                            );
                        }
                        $_robot_h{$uarobot}++;
                        if ($pos_size > 0) {$_robot_k{$uarobot} += int($field[$pos_size]);}
                        $_robot_l{$uarobot} = $timerecord;
                        if ($urlwithnoquery =~ /$regrobot/o) {
                            $_robot_r{$uarobot}++;
                        }
                        $countedtraffic = 4;
                        if ($PageBool) {$_time_nv_p[$hourrecord]++;}
                        $_time_nv_h[$hourrecord]++;
                        if ($pos_size > 0) {$_time_nv_k[$hourrecord] += int($field[$pos_size]);}
                    }
                }
            }
        }

        # Analyze: Robot from "hit on robots.txt" file (=> countedtraffic=5 if robot)
        # -------------------------------------------------------------------------
        if (!$countedtraffic) {
            if ($urlwithnoquery =~ /$regrobot/o) {
                if ($Debug) {debug("  It's an unknown robot", 2);}
                $_robot_h{'unknown'}++;
                if ($pos_size > 0) {$_robot_k{'unknown'} += int($field[$pos_size]);}
                $_robot_l{'unknown'} = $timerecord;
                $_robot_r{'unknown'}++;
                $countedtraffic = 5; # Must not be counted somewhere else
                if ($PageBool) {$_time_nv_p[$hourrecord]++;}
                $_time_nv_h[$hourrecord]++;
                if ($pos_size > 0) {$_time_nv_k[$hourrecord] += int($field[$pos_size]);}
            }
        }

        # Analyze: File type - Compression
        #---------------------------------
        if (!$countedtraffic || $countedtraffic == 6) {
            if ($LevelForFileTypesDetection) {
                if ($countedtraffic != 6) {$_filetypes_h{$extension}++;}
                if ($field[$pos_size] ne '-' && $pos_size > 0) {
                    $_filetypes_k{$extension} += int($field[$pos_size]);
                }

                # Compression
                if ($pos_gzipin >= 0 && $field[$pos_gzipin]) {
                    # If in and out in log
                    my ($notused, $in) = split(/:/, $field[$pos_gzipin]);
                    my ($notused1, $out, $notused2) =
                        split(/:/, $field[$pos_gzipout]);
                    if ($out) {
                        $_filetypes_gz_in{$extension} += $in;
                        $_filetypes_gz_out{$extension} += $out;
                    }
                }
                elsif ($pos_compratio >= 0
                    && ($field[$pos_compratio] =~ /(\d+)/)) {
                    # Calculate in/out size from percentage
                    if ($fieldlib[$pos_compratio] eq 'gzipratio') {

                        # with mod_gzip:    % is size (before-after)/before (low for jpg) ??????????
                        $_filetypes_gz_in{$extension} +=
                            int(
                                $field[$pos_size] * 100 / ((100 - $1) || 1));
                    }
                    else {

                        # with mod_deflate: % is size after/before (high for jpg)
                        $_filetypes_gz_in{$extension} +=
                            int($field[$pos_size] * 100 / ($1 || 1));
                    }
                    if ($pos_size > 0) {$_filetypes_gz_out{$extension} += int($field[$pos_size]);}
                }
            }

            # Analyze: Date - Hour - Pages - Hits - Kilo
            #-------------------------------------------
            if ($PageBool) {

                # Replace default page name with / only ('if' is to increase speed when only 1 value in @DefaultFile)
                if (@DefaultFile > 1) {
                    foreach my $elem (@DefaultFile) {
                        if ($field[$pos_url] =~ s/\/$elem$/\//) {last;}
                    }
                }
                else {$field[$pos_url] =~ s/$regdefault/\//o;}

                # FirstTime and LastTime are First and Last human visits (so changed if access to a page)
                $FirstTime{$lastprocesseddate} ||= $timerecord;
                $LastTime{$lastprocesseddate} = $timerecord;
                $DayPages{$yearmonthdayrecord}++;
                $_url_p{ $field[$pos_url] }++; #Count accesses for page (page)
                if ($field[$pos_size] ne '-' && $pos_size > 0) {
                    $_url_k{ $field[$pos_url] } += int($field[$pos_size]);
                }
                $_time_p[$hourrecord]++; #Count accesses for hour (page)
                # TODO Use an id for hash key of url
                # $_url_t{$_url_id}
            }
            if ($countedtraffic != 6) {$_time_h[$hourrecord]++;}
            if ($countedtraffic != 6) {$DayHits{$yearmonthdayrecord}++;} #Count accesses for hour (hit)
            if ($field[$pos_size] ne '-' && $pos_size > 0) {
                $_time_k[$hourrecord] += int($field[$pos_size]);
                $DayBytes{$yearmonthdayrecord} += int($field[$pos_size]); #Count accesses for hour (kb)
            }

            # Analyze: Login
            #---------------
            if ($pos_logname >= 0
                && $field[$pos_logname]
                && $field[$pos_logname] ne '-') {
                $field[$pos_logname] =~
                    s/ /_/g; # This is to allow space in logname
                if ($LogFormat eq '6') {
                    $field[$pos_logname] =~ s/^\"//;
                    $field[$pos_logname] =~ s/\"$//;
                } # logname field has " with Domino 6+
                if ($AuthenticatedUsersNotCaseSensitive) {
                    $field[$pos_logname] = lc($field[$pos_logname]);
                }

                # We found an authenticated user
                if ($PageBool) {
                    $_login_p{ $field[$pos_logname] }++;
                }                                                              #Count accesses for page (page)
                if ($countedtraffic != 6) {$_login_h{$field[$pos_logname]}++;} #Count accesses for page (hit)
                if ($pos_size > 0) {$_login_k{ $field[$pos_logname] } +=
                    int($field[$pos_size]);} #Count accesses for page (kb)
                $_login_l{ $field[$pos_logname] } = $timerecord;
            }
        }

        # Do DNS lookup
        #--------------
        my $Host = $field[$pos_host];
        my $HostResolved = ''
        ; # HostResolved will be defined in next paragraf if countedtraffic is true

        if ($Host =~ /^([^:]+):[0-9]+$/) { # Host may sometimes have an ip:port syntax (ex: 54.32.12.12:60321)
            $Host = $1;
        }

        if (!$countedtraffic || $countedtraffic == 6) {
            my $ip = 0;
            if ($DNSLookup) {
                # DNS lookup is 1 or 2
                if ($Host =~ /$regipv4l/o) {
                # IPv4 lighttpd
                    $Host =~ s/^::ffff://;
                    $ip = 4;
                }
                elsif ($Host =~ /$regipv4/o) {$ip = 4;} # IPv4
                elsif ($Host =~ /$regipv6/o) {$ip = 6;} # IPv6
                if ($ip) {

                    # Check in static DNS cache file
                    $HostResolved = $MyDNSTable{$Host};
                    if ($HostResolved) {
                        if ($Debug) {
                            debug(
                                "  DNS lookup asked for $Host and found in static DNS cache file: $HostResolved",
                                4
                            );
                        }
                    }
                    elsif ($DNSLookup == 1) {

                        # Check in session cache (dynamic DNS cache file + session DNS cache)
                        $HostResolved = $TmpDNSLookup{$Host};
                        if (!$HostResolved) {
                            if (@SkipDNSLookupFor && &SkipDNSLookup($Host)) {
                                $HostResolved = $TmpDNSLookup{$Host} = '*';
                                if ($Debug) {
                                    debug(
                                        "  No need of reverse DNS lookup for $Host, skipped at user request.",
                                        4
                                    );
                                }
                            }
                            else {
                                if ($ip == 4) {
                                    my $lookupresult =
                                        gethostbyaddr(
                                            pack("C4", split(/\./, $Host)),
                                            AF_INET)
                                    ; # This is very slow, may spend 20 seconds
                                    if (!$lookupresult
                                        || $lookupresult =~ /$regipv4/o
                                        || !IsAscii($lookupresult)) {
                                        $TmpDNSLookup{$Host} = $HostResolved =
                                            '*';
                                    }
                                    else {
                                        $TmpDNSLookup{$Host} = $HostResolved =
                                            $lookupresult;
                                    }
                                    if ($Debug) {
                                        debug(
                                            "  Reverse DNS lookup for $Host done: $HostResolved",
                                            4
                                        );
                                    }
                                }
                                elsif ($ip == 6) {
                                    if ($PluginsLoaded{'GetResolvedIP'}
                                        {'ipv6'}) {
                                        my $lookupresult =
                                            GetResolvedIP_ipv6($Host);
                                        if (!$lookupresult
                                            || !IsAscii($lookupresult)) {
                                            $TmpDNSLookup{$Host} =
                                                $HostResolved = '*';
                                        }
                                        else {
                                            $TmpDNSLookup{$Host} =
                                                $HostResolved = $lookupresult;
                                        }
                                    }
                                    else {
                                        $TmpDNSLookup{$Host} = $HostResolved =
                                            '*';
                                        warning(
                                            "Reverse DNS lookup for $Host not available without ipv6 plugin enabled."
                                        );
                                    }
                                }
                                else {error("Bad value vor ip");}
                            }
                        }
                    }
                    else {
                        $HostResolved = '*';
                        if ($Debug) {
                            debug(
                                "  DNS lookup by static DNS cache file asked for $Host but not found.",
                                4
                            );
                        }
                    }
                }
                else {
                    if ($Debug) {
                        debug(
                            "  DNS lookup asked for $Host but this is not an IP address.",
                            4
                        );
                    }
                    $DNSLookupAlreadyDone = $LogFile;
                }
            }
            else {
                if ($Host =~ /$regipv4l/o) {
                    $Host =~ s/^::ffff://;
                    $HostResolved = '*';
                    $ip = 4;
                }
                elsif ($Host =~ /$regipv4/o) {
                    $HostResolved = '*';
                    $ip = 4;
                } # IPv4
                elsif ($Host =~ /$regipv6/o) {
                    $HostResolved = '*';
                    $ip = 6;
                } # IPv6
                if ($Debug) {debug("  No DNS lookup asked.", 4);}
            }

            # Analyze: Country (Top-level domain)
            #------------------------------------
            if ($Debug) {
                debug(
                    "  Search country (Host=$Host HostResolved=$HostResolved ip=$ip)",
                    4
                );
            }
            my $Domain = 'ip';

            # Set $HostResolved to host and resolve domain
            if ($HostResolved eq '*') {

                # $Host is an IP address and is not resolved (failed or not asked) or resolution gives an IP address
                $HostResolved = $Host;

                # Resolve Domain
                if ($PluginsLoaded{'GetCountryCodeByAddr'}{'geoip6'}) {
                    $Domain = GetCountryCodeByAddr_geoip6($HostResolved);
                }
                elsif ($PluginsLoaded{'GetCountryCodeByAddr'}{'geoip'}) {
                    $Domain = GetCountryCodeByAddr_geoip($HostResolved);
                }

                #			elsif ($PluginsLoaded{'GetCountryCodeByAddr'}{'geoip_region_maxmind'}) { $Domain=GetCountryCodeByAddr_geoip_region_maxmind($HostResolved); }
                #			elsif ($PluginsLoaded{'GetCountryCodeByAddr'}{'geoip_city_maxmind'})   { $Domain=GetCountryCodeByAddr_geoip_city_maxmind($HostResolved); }
                elsif ($PluginsLoaded{'GetCountryCodeByAddr'}{'geoipfree'}) {
                    $Domain = GetCountryCodeByAddr_geoipfree($HostResolved);
                }
                elsif ($PluginsLoaded{'GetCountryCodeByAddr'}{'geoip2_country'}) {
                    $Domain = GetCountryCodeByAddr_geoip2_country($HostResolved);
                }
                if ($AtLeastOneSectionPlugin) {
                    foreach my $pluginname (
                        keys %{$PluginsLoaded{'SectionProcessIp'}}) {
                        my $function = "SectionProcessIp_$pluginname";
                        if ($Debug) {
                            debug("  Call to plugin function $function", 5);
                        }
                        &$function($HostResolved);
                    }
                }
            }
            else {

                # $Host was already a host name ($ip=0, $Host=name, $HostResolved='') or has been resolved ($ip>0, $Host=ip, $HostResolved defined)
                $HostResolved = lc($HostResolved ? $HostResolved : $Host);

                # Resolve Domain
                if ($ip) {
                    # If we have ip, we use it in priority instead of hostname
                    if ($PluginsLoaded{'GetCountryCodeByAddr'}{'geoip6'}) {
                        $Domain = GetCountryCodeByAddr_geoip6($Host);
                    }
                    elsif ($PluginsLoaded{'GetCountryCodeByAddr'}{'geoip'}) {
                        $Domain = GetCountryCodeByAddr_geoip($Host);
                    }

                    #				elsif ($PluginsLoaded{'GetCountryCodeByAddr'}{'geoip_region_maxmind'}) { $Domain=GetCountryCodeByAddr_geoip_region_maxmind($Host); }
                    #				elsif ($PluginsLoaded{'GetCountryCodeByAddr'}{'geoip_city_maxmind'})   { $Domain=GetCountryCodeByAddr_geoip_city_maxmind($Host); }
                    elsif (
                        $PluginsLoaded{'GetCountryCodeByAddr'}{'geoipfree'}) {
                        $Domain = GetCountryCodeByAddr_geoipfree($Host);
                    }
                    elsif (
                        $PluginsLoaded{'GetCountryCodeByAddr'}{'geoip2_country'}) {
                        $Domain = GetCountryCodeByAddr_geoip2_country($Host);
                    }
                    elsif ($HostResolved =~ /\.(\w+)$/) {$Domain = $1;}
                    if ($AtLeastOneSectionPlugin) {
                        foreach my $pluginname (
                            keys %{$PluginsLoaded{'SectionProcessIp'}}) {
                            my $function = "SectionProcessIp_$pluginname";
                            if ($Debug) {
                                debug("  Call to plugin function $function",
                                    5);
                            }
                            &$function($Host);
                        }
                    }
                }
                else {
                    if ($PluginsLoaded{'GetCountryCodeByName'}{'geoip6'}) {
                        $Domain = GetCountryCodeByName_geoip6($HostResolved);
                    }
                    elsif ($PluginsLoaded{'GetCountryCodeByName'}{'geoip'}) {
                        $Domain = GetCountryCodeByName_geoip($HostResolved);
                    }

                    #				elsif ($PluginsLoaded{'GetCountryCodeByName'}{'geoip_region_maxmind'}) { $Domain=GetCountryCodeByName_geoip_region_maxmind($HostResolved); }
                    #				elsif ($PluginsLoaded{'GetCountryCodeByName'}{'geoip_city_maxmind'})   { $Domain=GetCountryCodeByName_geoip_city_maxmind($HostResolved); }
                    elsif (
                        $PluginsLoaded{'GetCountryCodeByName'}{'geoipfree'}) {
                        $Domain = GetCountryCodeByName_geoipfree($HostResolved);
                    }
                    elsif (
                        $PluginsLoaded{'GetCountryCodeByName'}{'geoip2_country'}) {
                        $Domain = GetCountryCodeByName_geoip2_country($HostResolved);
                    }
                    elsif ($HostResolved =~ /\.(\w+)$/) {$Domain = $1;}
                    if ($AtLeastOneSectionPlugin) {
                        foreach my $pluginname (
                            keys %{$PluginsLoaded{'SectionProcessHostname'}}) {
                            my $function = "SectionProcessHostname_$pluginname";
                            if ($Debug) {
                                debug("  Call to plugin function $function",
                                    5);
                            }
                            &$function($HostResolved);
                        }
                    }
                }
            }

            # Store country
            if ($PageBool) {$_domener_p{$Domain}++;}
            if ($countedtraffic != 6) {$_domener_h{$Domain}++;}
            if ($field[$pos_size] ne '-' && $pos_size > 0) {
                $_domener_k{$Domain} += int($field[$pos_size]);
            }

            # Analyze: Host, URL entry+exit and Session
            #------------------------------------------
            if ($PageBool) {
                my $timehostl = $_host_l{$HostResolved};
                if ($timehostl) {

                    # A visit for this host was already detected
                    # TODO everywhere there is $VISITTIMEOUT
                    #				$timehostl =~ /^\d\d\d\d\d\d(\d\d)/; my $daytimehostl=$1;
                    #				if ($timerecord > ($timehostl+$VISITTIMEOUT+($dateparts[3]>$daytimehostl?$NEWDAYVISITTIMEOUT:0))) {
                    if ($timerecord > ($timehostl + $VISITTIMEOUT)) {

                        # This is a second visit or more
                        if (!$_waithost_s{$HostResolved}) {

                            # This is a second visit or more
                            # We count 'visit','exit','entry','DayVisits'
                            if ($Debug) {
                                debug(
                                    "  This is a second visit for $HostResolved.",
                                    4
                                );
                            }
                            my $timehosts = $_host_s{$HostResolved};
                            my $page = $_host_u{$HostResolved};
                            if ($page) {$_url_x{$page}++;}
                            $_url_e{ $field[$pos_url] }++;
                            $DayVisits{$yearmonthdayrecord}++;

                            # We can't count session yet because we don't have the start so
                            # we save params of first 'wait' session
                            $_waithost_l{$HostResolved} = $timehostl;
                            $_waithost_s{$HostResolved} = $timehosts;
                            $_waithost_u{$HostResolved} = $page;
                        }
                        else {

                            # This is third visit or more
                            # We count 'session','visit','exit','entry','DayVisits'
                            if ($Debug) {
                                debug(
                                    "  This is a third visit or more for $HostResolved.",
                                    4
                                );
                            }
                            my $timehosts = $_host_s{$HostResolved};
                            my $page = $_host_u{$HostResolved};
                            if ($page) {$_url_x{$page}++;}
                            $_url_e{ $field[$pos_url] }++;
                            $DayVisits{$yearmonthdayrecord}++;
                            if ($timehosts) {
                                $_session{ GetSessionRange($timehosts,
                                    $timehostl) }++;
                            }
                        }

                        # Save new session properties
                        $_host_s{$HostResolved} = $timerecord;
                        $_host_l{$HostResolved} = $timerecord;
                        $_host_u{$HostResolved} = $field[$pos_url];
                    }
                    elsif ($timerecord > $timehostl) {

                        # This is a same visit we can count
                        if ($Debug) {
                            debug(
                                "  This is same visit still running for $HostResolved. host_l/host_u changed to $timerecord/$field[$pos_url]",
                                4
                            );
                        }
                        $_host_l{$HostResolved} = $timerecord;
                        $_host_u{$HostResolved} = $field[$pos_url];
                    }
                    elsif ($timerecord == $timehostl) {

                        # This is a same visit we can count
                        if ($Debug) {
                            debug(
                                "  This is same visit still running for $HostResolved. host_l/host_u changed to $timerecord/$field[$pos_url]",
                                4
                            );
                        }
                        $_host_u{$HostResolved} = $field[$pos_url];
                    }
                    elsif ($timerecord < $_host_s{$HostResolved}) {

                        # Should happens only with not correctly sorted log files
                        if ($Debug) {
                            debug(
                                "  This is same visit still running for $HostResolved with start not in order. host_s changed to $timerecord (entry page also changed if first visit)",
                                4
                            );
                        }
                        if (!$_waithost_s{$HostResolved}) {

                            # We can reorder entry page only if it's the first visit found in this update run (The saved entry page was $_waithost_e if $_waithost_s{$HostResolved} is not defined. If second visit or more, entry was directly counted and not saved)
                            $_waithost_e{$HostResolved} = $field[$pos_url];
                        }
                        else {

                            # We can't change entry counted as we dont't know what was the url counted as entry
                        }
                        $_host_s{$HostResolved} = $timerecord;
                    }
                    else {
                        if ($Debug) {
                            debug(
                                "  This is same visit still running for $HostResolved with hit between start and last hits. No change",
                                4
                            );
                        }
                    }
                }
                else {

                    # This is a new visit (may be). First new visit found for this host. We save in wait array the entry page to count later
                    if ($Debug) {
                        debug(
                            "  New session (may be) for $HostResolved. Save in wait array to see later",
                            4
                        );
                    }
                    $_waithost_e{$HostResolved} = $field[$pos_url];

                    # Save new session properties
                    $_host_u{$HostResolved} = $field[$pos_url];
                    $_host_s{$HostResolved} = $timerecord;
                    $_host_l{$HostResolved} = $timerecord;
                }
                $_host_p{$HostResolved}++;
            }
            $_host_h{$HostResolved}++;
            if ($field[$pos_size] ne '-' && $pos_size > 0) {
                $_host_k{$HostResolved} += int($field[$pos_size]);
            }

            # Analyze: Browser - OS
            #----------------------
            if ($pos_agent >= 0) {

                if ($LevelForBrowsersDetection) {

                    # Analyze: Browser
                    #-----------------
                    my $uabrowser = $TmpBrowser{$UserAgent};
                    if (!$uabrowser) {
                        my $found = 1;

                        # Edge (must be at beginning)
                        if ($UserAgent =~ /$regveredge/o) {
                            $_browser_h{"edge$1"}++;
                            if ($PageBool) {$_browser_p{"edge$1"}++;}
                            $TmpBrowser{$UserAgent} = "edge$1";
                        }

                        # Opera ?
                        elsif ($UserAgent =~ /$regveropera/o) {
                            # !!!! version number in in regex $1 or $2 !!!
                            $_browser_h{"opera" . ($1 || $2)}++;
                            if ($PageBool) {$_browser_p{"opera" . ($1 || $2)}++;}
                            $TmpBrowser{$UserAgent} = "opera" . ($1 || $2);
                        }

                        # Firefox ?
                        elsif ($UserAgent =~ /$regverfirefox/o
                            && $UserAgent !~ /$regnotfirefox/o) {
                            $_browser_h{"firefox$1"}++;
                            if ($PageBool) {$_browser_p{"firefox$1"}++;}
                            $TmpBrowser{$UserAgent} = "firefox$1";
                        }

                        # Chrome ?
                        elsif ($UserAgent =~ /$regverchrome/o) {
                            $_browser_h{"chrome$1"}++;
                            if ($PageBool) {$_browser_p{"chrome$1"}++;}
                            $TmpBrowser{$UserAgent} = "chrome$1";
                        }

                        # Safari ?
                        elsif ($UserAgent =~ /$regversafari/o
                            && $UserAgent !~ /$regnotsafari/o) {
                            my $safariver = $BrowsersSafariBuildToVersionHash{$1};
                            if ($UserAgent =~ /$regversafariver/o) {
                                $safariver = $1;
                            }
                            $_browser_h{"safari$safariver"}++;
                            if ($PageBool) {$_browser_p{"safari$safariver"}++;}
                            $TmpBrowser{$UserAgent} = "safari$safariver";
                        }

                        # Konqueror ?
                        elsif ($UserAgent =~ /$regverkonqueror/o) {
                            $_browser_h{"konqueror$1"}++;
                            if ($PageBool) {$_browser_p{"konqueror$1"}++;}
                            $TmpBrowser{$UserAgent} = "konqueror$1";
                        }

                        # Subversion ?
                        elsif ($UserAgent =~ /$regversvn/o) {
                            $_browser_h{"svn$1"}++;
                            if ($PageBool) {$_browser_p{"svn$1"}++;}
                            $TmpBrowser{$UserAgent} = "svn$1";
                        }

                        # IE < 11 ? (must be at end of test)
                        elsif ($UserAgent =~ /$regvermsie/o
                            && $UserAgent !~ /$regnotie/o) {
                            $_browser_h{"msie$2"}++;
                            if ($PageBool) {$_browser_p{"msie$2"}++;}
                            $TmpBrowser{$UserAgent} = "msie$2";
                        }

                        # IE >= 11
                        elsif ($UserAgent =~ /$regvermsie11/o && $UserAgent !~ /$regnotie/o) {
                            $_browser_h{"msie$2"}++;
                            if ($PageBool) {$_browser_p{"msie$2"}++;}
                            $TmpBrowser{$UserAgent} = "msie$2";
                        }

                        # Netscape 6.x, 7.x ... ? (must be at end of test)
                        elsif ($UserAgent =~ /$regvernetscape/o) {
                            $_browser_h{"netscape$1"}++;
                            if ($PageBool) {$_browser_p{"netscape$1"}++;}
                            $TmpBrowser{$UserAgent} = "netscape$1";
                        }

                        # Netscape 3.x, 4.x ... ? (must be at end of test)
                        elsif ($UserAgent =~ /$regvermozilla/o
                            && $UserAgent !~ /$regnotnetscape/o) {
                            $_browser_h{"netscape$2"}++;
                            if ($PageBool) {$_browser_p{"netscape$2"}++;}
                            $TmpBrowser{$UserAgent} = "netscape$2";
                        }

                        # Other known browsers ?
                        else {
                            $found = 0;
                            foreach (@BrowsersSearchIDOrder) { # Search ID in order of BrowsersSearchIDOrder
                                if ($UserAgent =~ /$_/) {
                                    my $browser = &UnCompileRegex($_);

                                    # TODO If browser is in a family, use version
                                    $_browser_h{"$browser"}++;
                                    if ($PageBool) {$_browser_p{"$browser"}++;}
                                    $TmpBrowser{$UserAgent} = "$browser";
                                    $found = 1;
                                    last;
                                }
                            }
                        }

                        # Unknown browser ?
                        if (!$found) {
                            $_browser_h{'Unknown'}++;
                            if ($PageBool) {$_browser_p{'Unknown'}++;}
                            $TmpBrowser{$UserAgent} = 'Unknown';
                            my $newua = $UserAgent;
                            $newua =~ tr/\+ /__/;
                            $_unknownrefererbrowser_l{$newua} = $timerecord;
                        }
                    }
                    else {
                        $_browser_h{$uabrowser}++;
                        if ($PageBool) {$_browser_p{$uabrowser}++;}
                        if ($uabrowser eq 'Unknown') {
                            my $newua = $UserAgent;
                            $newua =~ tr/\+ /__/;
                            $_unknownrefererbrowser_l{$newua} = $timerecord;
                        }
                    }

                }

                if ($LevelForOSDetection) {

                    # Analyze: OS
                    #------------
                    my $uaos = $TmpOS{$UserAgent};
                    if (!$uaos) {
                        my $found = 0;

                        # in OSHashID list ?
                        foreach (@OSSearchIDOrder) { # Search ID in order of OSSearchIDOrder
                            if ($UserAgent =~ /$_/) {
                                my $osid = $OSHashID{ &UnCompileRegex($_) };
                                $_os_h{"$osid"}++;
                                if ($PageBool) {$_os_p{"$osid"}++;}
                                $TmpOS{$UserAgent} = "$osid";
                                $found = 1;
                                last;
                            }
                        }

                        # Unknown OS ?
                        if (!$found) {
                            $_os_h{'Unknown'}++;
                            if ($PageBool) {$_os_p{'Unknown'}++;}
                            $TmpOS{$UserAgent} = 'Unknown';
                            my $newua = $UserAgent;
                            $newua =~ tr/\+ /__/;
                            $_unknownreferer_l{$newua} = $timerecord;
                        }
                    }
                    else {
                        $_os_h{$uaos}++;
                        if ($PageBool) {
                            $_os_p{$uaos}++;
                        }
                        if ($uaos eq 'Unknown') {
                            my $newua = $UserAgent;
                            $newua =~ tr/\+ /__/;
                            $_unknownreferer_l{$newua} = $timerecord;
                        }
                    }

                }

            }
            else {
                $_browser_h{'Unknown'}++;
                $_os_h{'Unknown'}++;
                if ($PageBool) {
                    $_browser_p{'Unknown'}++;
                    $_os_p{'Unknown'}++;
                }
            }

            # Analyze: Referer
            #-----------------
            my $found = 0;
            if ($pos_referer >= 0
                && $LevelForRefererAnalyze
                && $field[$pos_referer]) {

                # Direct ?
                if ($field[$pos_referer] eq '-'
                    || $field[$pos_referer] eq 'bookmarks') {
                    # "bookmarks" is sent by Netscape, '-' by all others browsers
                    # Direct access
                    if ($PageBool) {
                        if ($ShowDirectOrigin) {
                            print "Direct access for line $line\n";
                        }
                        $_from_p[0]++;
                    }
                    $_from_h[0]++;
                    $found = 1;
                }
                else {
                    $field[$pos_referer] =~ /$regreferer/o;
                    my $refererprot = $1;
                    my $refererserver =
                        ($2 || '')
                            . (!$3 || $3 eq ':80' ? '' : $3)
                    ; # refererserver is www.xxx.com or www.xxx.com:81 but not www.xxx.com:80
                    # HTML link ?
                    if ($refererprot =~ /^http/i) {

                        #if ($Debug) { debug("  Analyze referer refererprot=$refererprot refererserver=$refererserver",5); }

                        # Kind of origin
                        if (!$TmpRefererServer{$refererserver}) { # TmpRefererServer{$refererserver} is "=" if same site, "search egine key" if search engine, not defined otherwise
                            if ($refererserver =~ /$reglocal/o) {

                                # Intern (This hit came from another page of the site)
                                if ($Debug) {
                                    debug(
                                        "  Server '$refererserver' is added to TmpRefererServer with value '='",
                                        2
                                    );
                                }
                                $TmpRefererServer{$refererserver} = '=';
                                $found = 1;
                            }
                            else {
                                foreach (@HostAliases) {
                                    if ($refererserver =~ /$_/) {

                                        # Intern (This hit came from another page of the site)
                                        if ($Debug) {
                                            debug(
                                                "  Server '$refererserver' is added to TmpRefererServer with value '='",
                                                2
                                            );
                                        }
                                        $TmpRefererServer{$refererserver} = '=';
                                        $found = 1;
                                        last;
                                    }
                                }
                                if (!$found) {

                                    # Extern (This hit came from an external web site).

                                    if ($LevelForSearchEnginesDetection) {

                                        foreach (@SearchEnginesSearchIDOrder) { # Search ID in order of SearchEnginesSearchIDOrder
                                            if ($refererserver =~ /$_/) {
                                                my $key = &UnCompileRegex($_);
                                                if (
                                                    !$NotSearchEnginesKeys{$key}
                                                        || $refererserver !~
                                                        /$NotSearchEnginesKeys{$key}/i
                                                ) {

                                                    # This hit came from the search engine $key
                                                    if ($Debug) {
                                                        debug(
                                                            "  Server '$refererserver' is added to TmpRefererServer with value '$key'",
                                                            2
                                                        );
                                                    }
                                                    $TmpRefererServer{
                                                        $refererserver} =
                                                        $SearchEnginesHashID{ $key
                                                        };
                                                    $found = 1;
                                                }
                                                last;
                                            }
                                        }

                                    }
                                }
                            }
                        }

                        my $tmprefererserver =
                            $TmpRefererServer{$refererserver};
                        if ($tmprefererserver) {
                            if ($tmprefererserver eq '=') {

                                # Intern (This hit came from another page of the site)
                                if ($PageBool) {$_from_p[4]++;}
                                $_from_h[4]++;
                                $found = 1;
                            }
                            else {

                                # This hit came from a search engine
                                if ($PageBool) {
                                    $_from_p[2]++;
                                    $_se_referrals_p{$tmprefererserver}++;
                                }
                                $_from_h[2]++;
                                $_se_referrals_h{$tmprefererserver}++;
                                $found = 1;
                                if ($PageBool && $LevelForKeywordsDetection) {

                                    # we will complete %_keyphrases hash array
                                    my @refurl =
                                        split(/\?/, $field[$pos_referer], 2)
                                    ; # TODO Use \? or [$URLQuerySeparators] ?
                                    if ($refurl[1]) {

                                        # Extract params of referer query string (q=cache:mmm:www/zzz+aaa+bbb q=aaa+bbb/ccc key=ddd%20eee lang_en ie=UTF-8 ...)
                                        if (
                                            $SearchEnginesKnownUrl{
                                                $tmprefererserver}) { # Search engine with known URL syntax
                                            foreach my $param (
                                                split(
                                                    /&/,
                                                    $KeyWordsNotSensitive
                                                        ? lc($refurl[1])
                                                        : $refurl[1]
                                                )
                                            ) {
                                                if ($param =~
                                                    s/^$SearchEnginesKnownUrl{$tmprefererserver}//
                                                ) {

                                                    # We found good parameter
                                                    # Now param is keyphrase: "cache:mmm:www/zzz+aaa+bbb/ccc+ddd%20eee'fff,ggg"
                                                    $param =~
                                                        s/^(cache|related):[^\+]+//
                                                    ; # Should be useless since this is for hit on 'not pages'
                                                    &ChangeWordSeparatorsIntoSpace
                                                        ($param)
                                                    ; # Change [ aaa+bbb/ccc+ddd%20eee'fff,ggg ] into [ aaa bbb/ccc ddd eee fff ggg]
                                                    $param =~ s/^ +//;
                                                    $param =~ s/ +$//; # Trim
                                                    $param =~ tr/ /\+/s;
                                                    if (((length $param) > 0) and ((length $param) < 80)) {
                                                        $_keyphrases{$param}++;
                                                    }
                                                    last;
                                                }
                                            }
                                        }
                                        elsif (
                                            $LevelForKeywordsDetection >= 2) { # Search engine with unknown URL syntax
                                            foreach my $param (
                                                split(
                                                    /&/,
                                                    $KeyWordsNotSensitive
                                                        ? lc($refurl[1])
                                                        : $refurl[1]
                                                )
                                            ) {
                                                my $foundexcludeparam = 0;
                                                foreach my $paramtoexclude (
                                                    @WordsToCleanSearchUrl) {
                                                    if ($param =~
                                                        /$paramtoexclude/i) {
                                                        $foundexcludeparam = 1;
                                                        last;
                                                    } # Not the param with search criteria
                                                }
                                                if ($foundexcludeparam) {
                                                    next;
                                                }

                                                # We found good parameter
                                                $param =~ s/.*=//;

                                                # Now param is keyphrase: "aaa+bbb/ccc+ddd%20eee'fff,ggg"
                                                $param =~
                                                    s/^(cache|related):[^\+]+//
                                                ; # Should be useless since this is for hit on 'not pages'
                                                &ChangeWordSeparatorsIntoSpace(
                                                    $param)
                                                ; # Change [ aaa+bbb/ccc+ddd%20eee'fff,ggg ] into [ aaa bbb/ccc ddd eee fff ggg ]
                                                $param =~ s/^ +//;
                                                $param =~ s/ +$//; # Trim
                                                $param =~ tr/ /\+/s;
                                                if ((length $param) > 2) {
                                                    $_keyphrases{$param}++;
                                                    last;
                                                }
                                            }
                                        }
                                    } # End of elsif refurl[1]
                                    elsif (
                                        $SearchEnginesWithKeysNotInQuery{
                                            $tmprefererserver}) {

                                        #										debug("xxx".$refurl[0]);
                                        # If search engine with key inside page url like a9 (www.a9.com/searchkey1%20searchkey2)
                                        if ($refurl[0] =~
                                            /$SearchEnginesKnownUrl{$tmprefererserver}(.*)$/
                                        ) {
                                            my $param = $1;
                                            &ChangeWordSeparatorsIntoSpace(
                                                $param);
                                            $param =~ tr/ /\+/s;
                                            if ((length $param) > 0) {
                                                $_keyphrases{$param}++;
                                            }
                                        }
                                    }

                                }
                            }
                        } # End of if ($TmpRefererServer)
                        else {

                            # This hit came from a site other than a search engine
                            if ($PageBool) {$_from_p[3]++;}
                            $_from_h[3]++;

                            # http://www.mysite.com/ must be same referer than http://www.mysite.com but .../mypage/ differs of .../mypage
                            #if ($refurl[0] =~ /^[^\/]+\/$/) { $field[$pos_referer] =~ s/\/$//; }	# Code moved in Save_History
                            # TODO: lowercase the value for referer server to have refering server not case sensitive
                            if ($URLReferrerWithQuery) {
                                if ($PageBool) {
                                    $_pagesrefs_p{ $field[$pos_referer] }++;
                                }
                                $_pagesrefs_h{ $field[$pos_referer] }++;
                            }
                            else {

                                # We discard query for referer
                                if ($field[$pos_referer] =~
                                    /$regreferernoquery/o) {
                                    if ($PageBool) {$_pagesrefs_p{"$1"}++;}
                                    $_pagesrefs_h{"$1"}++;
                                }
                                else {
                                    if ($PageBool) {
                                        $_pagesrefs_p{ $field[$pos_referer] }++;
                                    }
                                    $_pagesrefs_h{ $field[$pos_referer] }++;
                                }
                            }
                            $found = 1;
                        }
                    }

                    # News Link ?
                    #if (! $found && $refererprot =~ /^news/i) {
                    #	$found=1;
                    #	if ($PageBool) { $_from_p[5]++; }
                    #	$_from_h[5]++;
                    #}
                }
            }

            # Origin not found
            if (!$found) {
                if ($ShowUnknownOrigin) {
                    print "Unknown origin: $field[$pos_referer]\n";
                }
                if ($PageBool) {$_from_p[1]++;}
                $_from_h[1]++;
            }

            # Analyze: EMail
            #---------------
            if ($pos_emails >= 0 && $field[$pos_emails]) {
                if ($field[$pos_emails] eq '<>') {
                    $field[$pos_emails] = 'Unknown';
                }
                elsif ($field[$pos_emails] !~ /\@/) {
                    $field[$pos_emails] .= "\@$SiteDomain";
                }
                $_emails_h{ lc($field[$pos_emails]) }
                    ++; #Count accesses for sender email (hit)
                if ($pos_size > 0) {$_emails_k{ lc($field[$pos_emails]) } +=
                    int($field[$pos_size])
                ;} #Count accesses for sender email (kb)
                $_emails_l{ lc($field[$pos_emails]) } = $timerecord;
            }
            if ($pos_emailr >= 0 && $field[$pos_emailr]) {
                if ($field[$pos_emailr] !~ /\@/) {
                    $field[$pos_emailr] .= "\@$SiteDomain";
                }
                $_emailr_h{ lc($field[$pos_emailr]) }
                    ++; #Count accesses for receiver email (hit)
                if ($pos_size > 0) {$_emailr_k{ lc($field[$pos_emailr]) } +=
                    int($field[$pos_size])
                ;} #Count accesses for receiver email (kb)
                $_emailr_l{ lc($field[$pos_emailr]) } = $timerecord;
            }
        }

        # Check cluster
        #--------------
        if ($pos_cluster >= 0) {
            if ($PageBool) {
                $_cluster_p{ $field[$pos_cluster] }++;
            } #Count accesses for page (page)
            $_cluster_h{ $field[$pos_cluster] }
                ++; #Count accesses for page (hit)
            if ($pos_size > 0) {$_cluster_k{ $field[$pos_cluster] } +=
                int($field[$pos_size]);} #Count accesses for page (kb)
        }

        # Check size frequency
        #---------------------
        if ($pos_size >= 0) {
            $_filesize{ GetBandwidthRange(int($field[$pos_size])) }++;
        }

        # Check request time frequency
        #-----------------------------
        if ($pos_time >= 0) {
            $_requesttime{GetRequestTimeRange(int($field[$pos_time]))}++;
        }

        # Analyze: Extra
        #---------------
        foreach my $extranum (1 .. @ExtraName - 1) {
            if ($Debug) {debug("  Process extra analyze $extranum", 4);}

            # Check code
            my $conditionok = 0;
            if ($ExtraCodeFilter[$extranum]) {
                foreach
                my $condnum (0 .. @{$ExtraCodeFilter[$extranum]} - 1) {
                    if ($Debug) {
                        debug(
                            "  Check code '$field[$pos_code]' must be '$ExtraCodeFilter[$extranum][$condnum]'",
                            5
                        );
                    }
                    if ($field[$pos_code] eq
                        "$ExtraCodeFilter[$extranum][$condnum]") {
                        $conditionok = 1;
                        last;
                    }
                }
                if (!$conditionok && @{$ExtraCodeFilter[$extranum]}) {
                    next;
                } # End for this section
                if ($Debug) {
                    debug(
                        "  No check on code or code is OK. Now we check other conditions.",
                        5
                    );
                }
            }

            # Check conditions
            $conditionok = 0;
            foreach my $condnum (0 .. @{$ExtraConditionType[$extranum]} - 1) {
                my $conditiontype = $ExtraConditionType[$extranum][$condnum];
                my $conditiontypeval =
                    $ExtraConditionTypeVal[$extranum][$condnum];
                if ($conditiontype eq 'URL') {
                    if ($Debug) {
                        debug(
                            "  Check condition '$conditiontype' must contain '$conditiontypeval' in '$urlwithnoquery'",
                            5
                        );
                    }
                    if ($urlwithnoquery =~ /$conditiontypeval/) {
                        $conditionok = 1;
                        last;
                    }
                }
                elsif ($conditiontype eq 'QUERY_STRING') {
                    if ($Debug) {
                        debug(
                            "  Check condition '$conditiontype' must contain '$conditiontypeval' in '$standalonequery'",
                            5
                        );
                    }
                    if ($standalonequery =~ /$conditiontypeval/) {
                        $conditionok = 1;
                        last;
                    }
                }
                elsif ($conditiontype eq 'URLWITHQUERY') {
                    if ($Debug) {
                        debug(
                            "  Check condition '$conditiontype' must contain '$conditiontypeval' in '$urlwithnoquery$tokenquery$standalonequery'",
                            5
                        );
                    }
                    if ("$urlwithnoquery$tokenquery$standalonequery" =~
                        /$conditiontypeval/) {
                        $conditionok = 1;
                        last;
                    }
                }
                elsif ($conditiontype eq 'REFERER') {
                    if ($Debug) {
                        debug(
                            "  Check condition '$conditiontype' must contain '$conditiontypeval' in '$field[$pos_referer]'",
                            5
                        );
                    }
                    if ($field[$pos_referer] =~ /$conditiontypeval/) {
                        $conditionok = 1;
                        last;
                    }
                }
                elsif ($conditiontype eq 'UA') {
                    if ($Debug) {
                        debug(
                            "  Check condition '$conditiontype' must contain '$conditiontypeval' in '$field[$pos_agent]'",
                            5
                        );
                    }
                    if ($field[$pos_agent] =~ /$conditiontypeval/) {
                        $conditionok = 1;
                        last;
                    }
                }
                elsif ($conditiontype eq 'HOSTINLOG') {
                    if ($Debug) {
                        debug(
                            "  Check condition '$conditiontype' must contain '$conditiontypeval' in '$field[$pos_host]'",
                            5
                        );
                    }
                    if ($field[$pos_host] =~ /$conditiontypeval/) {
                        $conditionok = 1;
                        last;
                    }
                }
                elsif ($conditiontype eq 'HOST') {
                    my $hosttouse = ($HostResolved ? $HostResolved : $Host);
                    if ($Debug) {
                        debug(
                            "  Check condition '$conditiontype' must contain '$conditiontypeval' in '$hosttouse'",
                            5
                        );
                    }
                    if ($hosttouse =~ /$conditiontypeval/) {
                        $conditionok = 1;
                        last;
                    }
                }
                elsif ($conditiontype eq 'VHOST') {
                    if ($Debug) {
                        debug(
                            "  Check condision '$conditiontype' must contain '$conditiontypeval' in '$field[$pos_vh]'",
                            5
                        );
                    }
                    if ($field[$pos_vh] =~ /$conditiontypeval/) {
                        $conditionok = 1;
                        last;
                    }
                }
                elsif ($conditiontype =~ /extra(\d+)/i) {
                    if ($Debug) {
                        debug(
                            "  Check condition '$conditiontype' must contain '$conditiontypeval' in '$field[$pos_extra[$1]]'",
                            5
                        );
                    }
                    if ($field[ $pos_extra[$1] ] =~ /$conditiontypeval/) {
                        $conditionok = 1;
                        last;
                    }
                }
                else {
                    error(
                        "Wrong value of parameter ExtraSectionCondition$extranum"
                    );
                }
            }
            if (!$conditionok && @{$ExtraConditionType[$extranum]}) {
                next;
            } # End for this section
            if ($Debug) {
                debug(
                    "  No condition or condition is OK. Now we extract value for first column of extra chart.",
                    5
                );
            }

            # Determine actual column value to use.
            my $rowkeyval;
            my $rowkeyok = 0;
            foreach my $rowkeynum (
                0 .. @{$ExtraFirstColumnValuesType[$extranum]} - 1) {
                my $rowkeytype =
                    $ExtraFirstColumnValuesType[$extranum][$rowkeynum];
                my $rowkeytypeval =
                    $ExtraFirstColumnValuesTypeVal[$extranum][$rowkeynum];
                if ($rowkeytype eq 'URL') {
                    if ($urlwithnoquery =~ /$rowkeytypeval/) {
                        $rowkeyval = "$1";
                        $rowkeyok = 1;
                        last;
                    }
                }
                elsif ($rowkeytype eq 'QUERY_STRING') {
                    if ($Debug) {
                        debug(
                            "  Extract value from '$standalonequery' with regex '$rowkeytypeval'.",
                            5
                        );
                    }
                    if ($standalonequery =~ /$rowkeytypeval/) {
                        $rowkeyval = "$1";
                        $rowkeyok = 1;
                        last;
                    }
                }
                elsif ($rowkeytype eq 'URLWITHQUERY') {
                    if ("$urlwithnoquery$tokenquery$standalonequery" =~
                        /$rowkeytypeval/) {
                        $rowkeyval = "$1";
                        $rowkeyok = 1;
                        last;
                    }
                }
                elsif ($rowkeytype eq 'REFERER') {
                    if ($field[$pos_referer] =~ /$rowkeytypeval/) {
                        $rowkeyval = "$1";
                        $rowkeyok = 1;
                        last;
                    }
                }
                elsif ($rowkeytype eq 'UA') {
                    if ($field[$pos_agent] =~ /$rowkeytypeval/) {
                        $rowkeyval = "$1";
                        $rowkeyok = 1;
                        last;
                    }
                }
                elsif ($rowkeytype eq 'HOSTINLOG') {
                    if ($field[$pos_host] =~ /$rowkeytypeval/) {
                        $rowkeyval = "$1";
                        $rowkeyok = 1;
                        last;
                    }
                }
                elsif ($rowkeytype eq 'HOST') {
                    my $hosttouse = ($HostResolved ? $HostResolved : $Host);
                    if ($hosttouse =~ /$rowkeytypeval/) {
                        $rowkeyval = "$1";
                        $rowkeyok = 1;
                        last;
                    }
                }
                elsif ($rowkeytype eq 'VHOST') {
                    if ($field[$pos_vh] =~ /$rowkeytypeval/) {
                        $rowkeyval = "$1";
                        $rowkeyok = 1;
                        last;
                    }
                }
                elsif ($rowkeytype =~ /extra(\d+)/i) {
                    if ($field[ $pos_extra[$1] ] =~ /$rowkeytypeval/) {
                        $rowkeyval = "$1";
                        $rowkeyok = 1;
                        last;
                    }
                }
                else {
                    error(
                        "Wrong value of parameter ExtraSectionFirstColumnValues$extranum"
                    );
                }
            }
            if (!$rowkeyok) {next;} # End for this section
            if (!defined($rowkeyval)) {$rowkeyval = 'Failed to extract key';}
            if ($Debug) {debug("  Key val found: $rowkeyval", 5);}

            # Apply function on $rowkeyval
            if ($ExtraFirstColumnFunction[$extranum]) {

                # Todo call function on string $rowkeyval
            }

            # Here we got all values to increase counters
            if ($PageBool && $ExtraStatTypes[$extranum] =~ /P/i) {
                ${'_section_' . $extranum . '_p'}{$rowkeyval}++;
            }
            ${'_section_' . $extranum . '_h'}{$rowkeyval}++; # Must be set
            if ($ExtraStatTypes[$extranum] =~ /B/i && $pos_size > 0) {
                ${'_section_' . $extranum . '_k'}{$rowkeyval} +=
                    int($field[$pos_size]);
            }
            if ($ExtraStatTypes[$extranum] =~ /L/i) {
                if (${'_section_' . $extranum . '_l'}{$rowkeyval}
                    || 0 < $timerecord) {
                    ${'_section_' . $extranum . '_l'}{$rowkeyval} =
                        $timerecord;
                }
            }

            # Check to avoid too large extra sections
            if (
                scalar keys %{'_section_' . $extranum . '_h'} >
                    $ExtraTrackedRowsLimit) {
                error(<<END_ERROR_TEXT);
The number of values found for extra section $extranum has grown too large.
In order to prevent awstats from using an excessive amount of memory, the number
of values is currently limited to $ExtraTrackedRowsLimit. Perhaps you should consider
revising extract parameters for extra section $extranum. If you are certain you
want to track such a large data set, you can increase the limit by setting
ExtraTrackedRowsLimit in your awstats configuration file.
END_ERROR_TEXT
            }
        }

        # Every 20,000 approved lines after a flush, we test to clean too large hash arrays to flush data in tmp file
        if (++$counterforflushtest >= 20000) {

            #if (++$counterforflushtest >= 1) {
            if ((scalar keys %_host_u) > ($LIMITFLUSH << 2)
                || (scalar keys %_url_p) > $LIMITFLUSH) {

                # warning("Warning: Try to run AWStats update process more frequently to analyze smaler log files.");
                if ($^X =~ /activestate/i || $^X =~ /activeperl/i) {

                    # We don't flush if perl is activestate to avoid slowing process because of memory hole
                }
                else {

                    # Clean tmp hash arrays
                    #%TmpDNSLookup = ();
                    %TmpOS = %TmpRefererServer = %TmpRobot = %TmpBrowser = ();

                    # We flush if perl is not activestate
                    print "Flush history file on disk";
                    if ((scalar keys %_host_u) > ($LIMITFLUSH << 2)) {
                        print " (unique hosts reach flush limit of "
                            . ($LIMITFLUSH << 2) . ")";
                    }
                    if ((scalar keys %_url_p) > $LIMITFLUSH) {
                        print " (unique url reach flush limit of "
                            . ($LIMITFLUSH) . ")";
                    }
                    print "\n";
                    if ($Debug) {
                        debug(
                            "End of set of $counterforflushtest records: Some hash arrays are too large. We flush and clean some.",
                            2
                        );
                        print " _host_p:"
                            . (scalar keys %_host_p)
                            . " _host_h:"
                            . (scalar keys %_host_h)
                            . " _host_k:"
                            . (scalar keys %_host_k)
                            . " _host_l:"
                            . (scalar keys %_host_l)
                            . " _host_s:"
                            . (scalar keys %_host_s)
                            . " _host_u:"
                            . (scalar keys %_host_u) . "\n";
                        print " _url_p:"
                            . (scalar keys %_url_p)
                            . " _url_k:"
                            . (scalar keys %_url_k)
                            . " _url_e:"
                            . (scalar keys %_url_e)
                            . " _url_x:"
                            . (scalar keys %_url_x) . "\n";
                        print " _waithost_e:"
                            . (scalar keys %_waithost_e)
                            . " _waithost_l:"
                            . (scalar keys %_waithost_l)
                            . " _waithost_s:"
                            . (scalar keys %_waithost_s)
                            . " _waithost_u:"
                            . (scalar keys %_waithost_u) . "\n";
                    }
                    &Read_History_With_TmpUpdate(
                        $lastprocessedyear,
                        $lastprocessedmonth,
                        $lastprocessedday,
                        $lastprocessedhour,
                        1,
                        1,
                        "all",
                        ($lastlinenb + $NbOfLinesParsed),
                        $lastlineoffset,
                        &CheckSum($_)
                    );
                    &GetDelaySinceStart(1);
                    $NbOfLinesShowsteps = 1;
                }
            }
            $counterforflushtest = 0;
        }

    } # End of loop for processing new record.

    if ($Debug) {
        debug(
            " _host_p:"
                . (scalar keys %_host_p)
                . " _host_h:"
                . (scalar keys %_host_h)
                . " _host_k:"
                . (scalar keys %_host_k)
                . " _host_l:"
                . (scalar keys %_host_l)
                . " _host_s:"
                . (scalar keys %_host_s)
                . " _host_u:"
                . (scalar keys %_host_u) . "\n",
            1
        );
        debug(
            " _url_p:"
                . (scalar keys %_url_p)
                . " _url_k:"
                . (scalar keys %_url_k)
                . " _url_e:"
                . (scalar keys %_url_e)
                . " _url_x:"
                . (scalar keys %_url_x) . "\n",
            1
        );
        debug(
            " _waithost_e:"
                . (scalar keys %_waithost_e)
                . " _waithost_l:"
                . (scalar keys %_waithost_l)
                . " _waithost_s:"
                . (scalar keys %_waithost_s)
                . " _waithost_u:"
                . (scalar keys %_waithost_u) . "\n",
            1
        );
        debug(
            "End of processing log file (AWStats memory cache is TmpDNSLookup="
                . (scalar keys %TmpDNSLookup)
                . " TmpBrowser="
                . (scalar keys %TmpBrowser)
                . " TmpOS="
                . (scalar keys %TmpOS)
                . " TmpRefererServer="
                . (scalar keys %TmpRefererServer)
                . " TmpRobot="
                . (scalar keys %TmpRobot) . ")",
            1
        );
    }

    # Save current processed break section
    # If lastprocesseddate > 0 means there is at least one approved new record in log or at least one existing history file
    if ($lastprocesseddate > 0) {
        # TODO: Do not save if we are sure a flush was just already done
        # Get last line
        seek(LOG, $lastlineoffset, 0);
        my $line = <LOG>;
        chomp $line;
        $line =~ s/\r$//;
        if (!$NbOfLinesParsed) {
            # TODO If there was no lines parsed (log was empty), we only update LastUpdate line with YYYYMMDDHHMMSS 0 0 0 0 0
            &Read_History_With_TmpUpdate(
                $lastprocessedyear, $lastprocessedmonth,
                $lastprocessedday, $lastprocessedhour,
                1, 1,
                "all", ($lastlinenb + $NbOfLinesParsed),
                $lastlineoffset, &CheckSum($line)
            );
        }
        else {
            &Read_History_With_TmpUpdate(
                $lastprocessedyear, $lastprocessedmonth,
                $lastprocessedday, $lastprocessedhour,
                1, 1,
                "all", ($lastlinenb + $NbOfLinesParsed),
                $lastlineoffset, &CheckSum($line)
            );
        }
    }

    if ($Debug) {debug("Close log file \"$LogFile\"");}
    close LOG || error("Command for pipe '$LogFile' failed");

    # Process the Rename - Archive - Purge phase
    my $renameok = 1;
    my $archiveok = 1;

    # Open Log file for writing if PurgeLogFile is on
    if ($PurgeLogFile) {
        if ($ArchiveLogRecords) {
            if ($ArchiveLogRecords == 1) { # For backward compatibility
                $ArchiveFileName = "$DirData/${PROG}_archive$FileSuffix.log";
            }
            else {
                $ArchiveFileName =
                    "$DirData/${PROG}_archive$FileSuffix."
                        . &Substitute_Tags($ArchiveLogRecords) . ".log";
            }
            open(LOG, "+<$LogFile")
                || error(
                "Enable to archive log records of \"$LogFile\" into \"$ArchiveFileName\" because source can't be opened for read and write: $!<br />\n"
            );
        }
        else {
            open(LOG, "+<$LogFile");
        }
        binmode LOG;
    }

    # Rename all HISTORYTMP files into HISTORYTXT
    &Rename_All_Tmp_History();

    # Purge Log file if option is on and all renaming are ok
    if ($PurgeLogFile) {

        # Archive LOG file into ARCHIVELOG
        if ($ArchiveLogRecords) {
            if ($Debug) {debug("Start of archiving log file");}
            open(ARCHIVELOG, ">>$ArchiveFileName")
                || error(
                "Couldn't open file \"$ArchiveFileName\" to archive log: $!");
            binmode ARCHIVELOG;
            while (<LOG>) {
                if (!print ARCHIVELOG $_) {
                    $archiveok = 0;
                    last;
                }
            }
            close(ARCHIVELOG)
                || error("Archiving failed during closing archive: $!");
            if ($SaveDatabaseFilesWithPermissionsForEveryone) {
                chmod 0666, "$ArchiveFileName";
            }
            if ($Debug) {debug("End of archiving log file");}
        }

        # If rename and archive ok
        if ($renameok && $archiveok) {
            if ($Debug) {debug("Purge log file");}
            my $bold = ($ENV{'GATEWAY_INTERFACE'} ? '<b>' : '');
            my $unbold = ($ENV{'GATEWAY_INTERFACE'} ? '</b>' : '');
            my $br = ($ENV{'GATEWAY_INTERFACE'} ? '<br />' : '');
            truncate(LOG, 0)
                || warning(
                "Warning: $bold$PROG$unbold couldn't purge logfile \"$bold$LogFile$unbold\".$br\nChange your logfile permissions to allow write for your web server CGI process or change PurgeLogFile=1 into PurgeLogFile=0 in configure file and think to purge sometimes manually your logfile (just after running an update process to not loose any not already processed records your log file contains)."
            );
        }
        close(LOG);
    }

    if ($DNSLookup == 1 && $DNSLookupAlreadyDone) {

        # DNSLookup warning
        my $bold = ($ENV{'GATEWAY_INTERFACE'} ? '<b>' : '');
        my $unbold = ($ENV{'GATEWAY_INTERFACE'} ? '</b>' : '');
        my $br = ($ENV{'GATEWAY_INTERFACE'} ? '<br />' : '');
        warning(
            "Warning: $bold$PROG$unbold has detected that some hosts names were already resolved in your logfile $bold$DNSLookupAlreadyDone$unbold.$br\nIf DNS lookup was already made by the logger (web server), you should change your setup DNSLookup=$DNSLookup into DNSLookup=0 to increase $PROG speed."
        );
    }
    if ($DNSLookup == 1 && $NbOfNewLines) {

        # Save new DNS last update cache file
        Save_DNS_Cache_File(\%TmpDNSLookup, "$DirData/$DNSLastUpdateCacheFile",
            "$FileSuffix"); # Save into file using FileSuffix
    }

    if ($EnableLockForUpdate) {

        # Remove lock
        &Lock_Update(0);

        # Restore signals handler
        $SIG{INT} = 'DEFAULT'; # 2
        #$SIG{KILL} = 'DEFAULT';	# 9
        #$SIG{TERM} = 'DEFAULT';	# 15
    }

}

# End of log processing if ($UPdateStats)

#---------------------------------------------------------------------
# SHOW REPORT
#---------------------------------------------------------------------

if (scalar keys %HTMLOutput) {

    debug("YearRequired=$YearRequired, MonthRequired=$MonthRequired", 2);
    debug("DayRequired=$DayRequired, HourRequired=$HourRequired", 2);

    # Define the NewLinkParams for main chart
    my $NewLinkParams = ${QueryString};
    $NewLinkParams =~ s/(^|&|&amp;)update(=\w*|$)//i;
    $NewLinkParams =~ s/(^|&|&amp;)output(=\w*|$)//i;
    $NewLinkParams =~ s/(^|&|&amp;)staticlinks(=\w*|$)//i;
    $NewLinkParams =~ s/(^|&|&amp;)framename=[^&]*//i;
    my $NewLinkTarget = '';
    if ($DetailedReportsOnNewWindows) {
        $NewLinkTarget = " target=\"awstatsbis\"";
    }
    if (($FrameName eq 'mainleft' || $FrameName eq 'mainright')
        && $DetailedReportsOnNewWindows < 2) {
        $NewLinkParams .= "&amp;framename=mainright";
        $NewLinkTarget = " target=\"mainright\"";
    }
    $NewLinkParams =~ s/(&amp;|&)+/&amp;/i;
    $NewLinkParams =~ s/^&amp;//;
    $NewLinkParams =~ s/&amp;$//;
    if ($NewLinkParams) {$NewLinkParams = "${NewLinkParams}&amp;";}

    if ($FrameName ne 'mainleft') {

        # READING DATA
        #-------------
        &Init_HashArray();

        # Lecture des fichiers history / reading history file
        if ($DatabaseBreak eq 'month') {
            for (my $ix = 12; $ix >= 1; $ix--) {
                my $stringforload = '';
                my $monthix = sprintf("%02s", $ix);
                if ($MonthRequired eq 'all' || $monthix eq $MonthRequired) {
                    $stringforload = 'all'; # Read full history file
                }
                elsif (($HTMLOutput{'main'} && $ShowMonthStats)
                    || $HTMLOutput{'alldays'}) {
                    $stringforload =
                        'general time'; # Read general and time sections.
                }
                if ($stringforload) {

                    # On charge fichier / file is loaded
                    &Read_History_With_TmpUpdate($YearRequired, $monthix, '',
                        '', 0, 0, $stringforload);
                }
            }
        }
        if ($DatabaseBreak eq 'day') {
            my $stringforload = 'all';
            my $monthix = sprintf("%02s", $MonthRequired);
            my $dayix = sprintf("%02s", $DayRequired);
            &Read_History_With_TmpUpdate($YearRequired, $monthix, $dayix, '',
                0, 0, $stringforload);
        }
        if ($DatabaseBreak eq 'hour') {
            my $stringforload = 'all';
            my $monthix = sprintf("%02s", $MonthRequired);
            my $dayix = sprintf("%02s", $DayRequired);
            my $hourix = sprintf("%02s", $HourRequired);
            &Read_History_With_TmpUpdate($YearRequired, $monthix, $dayix,
                $hourix, 0, 0, $stringforload);
        }

    }

    # HTMLHeadSection
    if ($FrameName ne 'index' && $FrameName ne 'mainleft') {
        print "<a name=\"top\"></a>\n\n";
        my $newhead = $HTMLHeadSection;
        $newhead =~ s/\\n/\n/g;
        print "$newhead\n";
        print "\n";
    }

    # Call to plugins' function AddHTMLBodyHeader
    foreach my $pluginname (keys %{$PluginsLoaded{'AddHTMLBodyHeader'}}) {
        my $function = "AddHTMLBodyHeader_$pluginname";
        &$function();
    }

    my $WIDTHMENU1 = ($FrameName eq 'mainleft' ? $FRAMEWIDTH : 150);

    # TOP BAN
    #---------------------------------------------------------------------
    if ($ShowMenu || $FrameName eq 'mainleft') {
        HTMLTopBanner($WIDTHMENU1);
    }

    # Call to plugins' function AddHTMLMenuHeader
    foreach my $pluginname (keys %{$PluginsLoaded{'AddHTMLMenuHeader'}}) {
        my $function = "AddHTMLMenuHeader_$pluginname";
        &$function();
    }

    # MENU (ON LEFT IF FRAME OR TOP)
    #---------------------------------------------------------------------
    if ($ShowMenu || $FrameName eq 'mainleft') {
        HTMLMenu($NewLinkParams, $NewLinkTarget);
    }

    # Call to plugins' function AddHTMLMenuFooter
    foreach my $pluginname (keys %{$PluginsLoaded{'AddHTMLMenuFooter'}}) {
        my $function = "AddHTMLMenuFooter_$pluginname";
        &$function();
    }

    # Exit if left frame
    if ($FrameName eq 'mainleft') {
        &html_end(0);
        exit 0;
    }


    # TotalVisits TotalUnique TotalPages TotalHits TotalBytes TotalHostsKnown TotalHostsUnknown
    $TotalUnique = $TotalVisits = $TotalPages = $TotalHits = $TotalBytes = 0;
    $TotalNotViewedPages = $TotalNotViewedHits = $TotalNotViewedBytes = 0;
    $TotalHostsKnown = $TotalHostsUnknown = 0;
    my $beginmonth = $MonthRequired;
    my $endmonth = $MonthRequired;
    if ($MonthRequired eq 'all') {
        $beginmonth = 1;
        $endmonth = 12;
    }
    for (my $month = $beginmonth; $month <= $endmonth; $month++) {
        my $monthix = sprintf("%02s", $month);
        $TotalHostsKnown += $MonthHostsKnown{ $YearRequired . $monthix }
            || 0; # Wrong in year view
        $TotalHostsUnknown += $MonthHostsUnknown{ $YearRequired . $monthix }
            || 0; # Wrong in year view
        $TotalUnique += $MonthUnique{ $YearRequired . $monthix }
            || 0; # Wrong in year view
        $TotalVisits += $MonthVisits{ $YearRequired . $monthix }
            || 0; # Not completely true
        $TotalPages += $MonthPages{ $YearRequired . $monthix } || 0;
        $TotalHits += $MonthHits{ $YearRequired . $monthix } || 0;
        $TotalBytes += $MonthBytes{ $YearRequired . $monthix } || 0;
        $TotalNotViewedPages += $MonthNotViewedPages{ $YearRequired . $monthix }
            || 0;
        $TotalNotViewedHits += $MonthNotViewedHits{ $YearRequired . $monthix }
            || 0;
        $TotalNotViewedBytes += $MonthNotViewedBytes{ $YearRequired . $monthix }
            || 0;
    }

    # TotalHitsErrors TotalBytesErrors
    $TotalHitsErrors = 0;
    my $TotalBytesErrors = 0;
    foreach (keys %_errors_h) {

        #		print "xxxx".$_." zzz".$_errors_h{$_};
        $TotalHitsErrors += $_errors_h{$_};
        $TotalBytesErrors += $_errors_k{$_};
    }

    # TotalEntries (if not already specifically counted, we init it from _url_e hash table)
    if (!$TotalEntries) {
        foreach (keys %_url_e) {$TotalEntries += $_url_e{$_};}
    }

    # TotalExits (if not already specifically counted, we init it from _url_x hash table)
    if (!$TotalExits) {
        foreach (keys %_url_x) {$TotalExits += $_url_x{$_};}
    }

    # TotalBytesPages (if not already specifically counted, we init it from _url_k hash table)
    if (!$TotalBytesPages) {
        foreach (keys %_url_k) {$TotalBytesPages += $_url_k{$_};}
    }

    # TotalKeyphrases (if not already specifically counted, we init it from _keyphrases hash table)
    if (!$TotalKeyphrases) {
        foreach (keys %_keyphrases) {$TotalKeyphrases += $_keyphrases{$_};}
    }

    # TotalKeywords (if not already specifically counted, we init it from _keywords hash table)
    if (!$TotalKeywords) {
        foreach (keys %_keywords) {$TotalKeywords += $_keywords{$_};}
    }

    # TotalSearchEnginesPages (if not already specifically counted, we init it from _se_referrals_p hash table)
    if (!$TotalSearchEnginesPages) {
        foreach (keys %_se_referrals_p) {
            $TotalSearchEnginesPages += $_se_referrals_p{$_};
        }
    }

    # TotalSearchEnginesHits (if not already specifically counted, we init it from _se_referrals_h hash table)
    if (!$TotalSearchEnginesHits) {
        foreach (keys %_se_referrals_h) {
            $TotalSearchEnginesHits += $_se_referrals_h{$_};
        }
    }

    # TotalRefererPages (if not already specifically counted, we init it from _pagesrefs_p hash table)
    if (!$TotalRefererPages) {
        foreach (keys %_pagesrefs_p) {
            $TotalRefererPages += $_pagesrefs_p{$_};
        }
    }

    # TotalRefererHits (if not already specifically counted, we init it from _pagesrefs_h hash table)
    if (!$TotalRefererHits) {
        foreach (keys %_pagesrefs_h) {
            $TotalRefererHits += $_pagesrefs_h{$_};
        }
    }

    # TotalDifferentPages (if not already specifically counted, we init it from _url_p hash table)
    $TotalDifferentPages ||= scalar keys %_url_p;

    # TotalDifferentKeyphrases (if not already specifically counted, we init it from _keyphrases hash table)
    $TotalDifferentKeyphrases ||= scalar keys %_keyphrases;

    # TotalDifferentKeywords (if not already specifically counted, we init it from _keywords hash table)
    $TotalDifferentKeywords ||= scalar keys %_keywords;

    # TotalDifferentSearchEngines (if not already specifically counted, we init it from _se_referrals_h hash table)
    $TotalDifferentSearchEngines ||= scalar keys %_se_referrals_h;

    # TotalDifferentReferer (if not already specifically counted, we init it from _pagesrefs_h hash table)
    $TotalDifferentReferer ||= scalar keys %_pagesrefs_h;

    # Define firstdaytocountaverage, lastdaytocountaverage, firstdaytoshowtime, lastdaytoshowtime
    my $firstdaytocountaverage =
        $nowyear . $nowmonth . "01"; # Set day cursor to 1st day of month
    my $firstdaytoshowtime =
        $nowyear . $nowmonth . "01"; # Set day cursor to 1st day of month
    my $lastdaytocountaverage =
        $nowyear . $nowmonth . $nowday; # Set day cursor to today
    my $lastdaytoshowtime =
        $nowyear . $nowmonth . "31"; # Set day cursor to last day of month
    if ($MonthRequired eq 'all') {
        $firstdaytocountaverage =
            $YearRequired
                . "0101"; # Set day cursor to 1st day of the required year
    }
    if (($MonthRequired ne $nowmonth && $MonthRequired ne 'all')
        || $YearRequired ne $nowyear) {
        if ($MonthRequired eq 'all') {
            $firstdaytocountaverage =
                $YearRequired
                    . "0101"; # Set day cursor to 1st day of the required year
            $firstdaytoshowtime =
                $YearRequired . "1201"
            ; # Set day cursor to 1st day of last month of required year
            $lastdaytocountaverage =
                $YearRequired
                    . "1231"; # Set day cursor to last day of the required year
            $lastdaytoshowtime =
                $YearRequired . "1231"
            ; # Set day cursor to last day of last month of required year
        }
        else {
            $firstdaytocountaverage =
                $YearRequired
                    . $MonthRequired
                    . "01"; # Set day cursor to 1st day of the required month
            $firstdaytoshowtime =
                $YearRequired
                    . $MonthRequired
                    . "01"; # Set day cursor to 1st day of the required month
            $lastdaytocountaverage =
                $YearRequired
                    . $MonthRequired
                    . "31"; # Set day cursor to last day of the required month
            $lastdaytoshowtime =
                $YearRequired
                    . $MonthRequired
                    . "31"; # Set day cursor to last day of the required month
        }
    }
    if ($Debug) {
        debug(
            "firstdaytocountaverage=$firstdaytocountaverage, lastdaytocountaverage=$lastdaytocountaverage",
            1
        );
        debug(
            "firstdaytoshowtime=$firstdaytoshowtime, lastdaytoshowtime=$lastdaytoshowtime",
            1
        );
    }

    # Call to plugins' function AddHTMLContentHeader
    foreach my $pluginname (keys %{$PluginsLoaded{'AddHTMLContentHeader'}}) {
        # to add unique visitors & number of visits, by J Ruano @ CAPSiDE
        if ($ShowDomainsStats =~ /U/i) {
            print "<th bgcolor=\"#$color_u\" width=\"80\">$Message[11]</th>";
        }
        if ($ShowDomainsStats =~ /V/i) {
            print "<th bgcolor=\"#$color_v\" width=\"80\">$Message[10]</th>";
        }

        my $function = "AddHTMLContentHeader_$pluginname";
        &$function();
    }

    # Output individual frames or static pages for specific sections
    #-----------------------
    if (scalar keys %HTMLOutput == 1) {

        if ($HTMLOutput{'alldomains'}) {
            &HTMLShowDomains();
        }
        if ($HTMLOutput{'allhosts'} || $HTMLOutput{'lasthosts'}) {
            &HTMLShowHosts();
        }
        if ($HTMLOutput{'unknownip'}) {
            &HTMLShowHostsUnknown();
        }
        if ($HTMLOutput{'allemails'} || $HTMLOutput{'lastemails'}) {
            &HTMLShowEmailSendersChart($NewLinkParams, $NewLinkTarget);
            &html_end(1);
        }
        if ($HTMLOutput{'allemailr'} || $HTMLOutput{'lastemailr'}) {
            &HTMLShowEmailReceiversChart($NewLinkParams, $NewLinkTarget);
            &html_end(1);
        }
        if ($HTMLOutput{'alllogins'} || $HTMLOutput{'lastlogins'}) {
            &HTMLShowLogins();
        }
        if ($HTMLOutput{'allrobots'} || $HTMLOutput{'lastrobots'}) {
            &HTMLShowRobots();
        }
        if ($HTMLOutput{'urldetail'}
            || $HTMLOutput{'urlentry'}
            || $HTMLOutput{'urlexit'}) {
            &HTMLShowURLDetail();
        }
        if ($HTMLOutput{'unknownos'}) {
            &HTMLShowOSUnknown($NewLinkTarget);
        }
        if ($HTMLOutput{'unknownbrowser'}) {
            &HTMLShowBrowserUnknown($NewLinkTarget);
        }
        if ($HTMLOutput{'osdetail'}) {
            &HTMLShowOSDetail();
        }
        if ($HTMLOutput{'browserdetail'}) {
            &HTMLShowBrowserDetail();
        }
        if ($HTMLOutput{'refererse'}) {
            &HTMLShowReferers($NewLinkTarget);
        }
        if ($HTMLOutput{'refererpages'}) {
            &HTMLShowRefererPages($NewLinkTarget);
        }
        if ($HTMLOutput{'keyphrases'}) {
            &HTMLShowKeyPhrases($NewLinkTarget);
        }
        if ($HTMLOutput{'keywords'}) {
            &HTMLShowKeywords($NewLinkTarget);
        }
        if ($HTMLOutput{'downloads'}) {
            &HTMLShowDownloads();
        }
        foreach my $code (keys %TrapInfosForHTTPErrorCodes) {
            if ($HTMLOutput{"errors$code"}) {
                &HTMLShowErrorCodes($code);
            }
        }

        # BY EXTRA SECTIONS
        #----------------------------
        HTMLShowExtraSections();

        if ($HTMLOutput{'info'}) {
            # TODO Not yet available
            print "$Center<a name=\"info\">&nbsp;</a><br />";
            &html_end(1);
        }

        # Print any plugins that have individual pages
        # TODO - change name, graph isn't so descriptive
        my $htmloutput = '';
        foreach my $key (keys %HTMLOutput) {$htmloutput = $key;}
        if ($htmloutput =~ /^plugin_(\w+)$/) {
            my $pluginname = $1;
            print "$Center<a name=\"plugin_$pluginname\">&nbsp;</a><br />";
            my $function = "AddHTMLGraph_$pluginname";
            &$function();
            &html_end(1);
        }
    }

    # Output main page
    #-----------------
    if ($HTMLOutput{'main'}) {

        # Calculate averages
        my $max_p = 0;
        my $max_h = 0;
        my $max_k = 0;
        my $max_v = 0;
        my $average_nb = 0;
        foreach my $daycursor ($firstdaytocountaverage .. $lastdaytocountaverage) {
            $daycursor =~ /^(\d\d\d\d)(\d\d)(\d\d)/;
            my $year = $1;
            my $month = $2;
            my $day = $3;
            if (!DateIsValid($day, $month, $year)) {
                next;
            }              # If not an existing day, go to next
            $average_nb++; # Increase number of day used to count
            $AverageVisits += ($DayVisits{$daycursor} || 0);
            $AveragePages += ($DayPages{$daycursor} || 0);
            $AverageHits += ($DayHits{$daycursor} || 0);
            $AverageBytes += ($DayBytes{$daycursor} || 0);
        }
        if ($average_nb) {
            $AverageVisits = $AverageVisits / $average_nb;
            $AveragePages = $AveragePages / $average_nb;
            $AverageHits = $AverageHits / $average_nb;
            $AverageBytes = $AverageBytes / $average_nb;
            if ($AverageVisits > $max_v) {$max_v = $AverageVisits;}
            #if ($average_p > $max_p) { $max_p=$average_p; }
            if ($AverageHits > $max_h) {$max_h = $AverageHits;}
            if ($AverageBytes > $max_k) {$max_k = $AverageBytes;}
        }
        else {
            $AverageVisits = "?";
            $AveragePages = "?";
            $AverageHits = "?";
            $AverageBytes = "?";
        }

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

        # close the HTML page
        &html_end(1);
    }
}
else {
    print "Jumped lines in file: $lastlinenb\n";
    if ($lastlinenb) {print " Found $lastlinenb already parsed records.\n";}
    print "Parsed lines in file: $NbOfLinesParsed\n";
    print " Found $NbOfLinesDropped dropped records,\n";
    print " Found $NbOfLinesComment comments,\n";
    print " Found $NbOfLinesBlank blank records,\n";
    print " Found $NbOfLinesCorrupted corrupted records,\n";
    print " Found $NbOfOldLines old records,\n";
    print " Found $NbOfNewLines new qualified records.\n";
}


#sleep 10;

0; # Do not remove this line

#-------------------------------------------------------
# ALGORITHM SUMMARY
#
# Read_Config();
# Check_Config() and Init variables
# if 'frame not index'
#	&Read_Language_Data($Lang);
#	if 'frame not mainleft'
#		&Read_Ref_Data();
#		&Read_Plugins();
# html_head
#
# If 'migrate'
#   We create/update tmp file with
#     &Read_History_With_TmpUpdate(year,month,day,hour,UPDATE,NOPURGE,"all");
#   Rename the tmp file
#   html_end
#   Exit
# End of 'migrate'
#
# Get last history file name
# Get value for $LastLine $LastLineNumber $LastLineOffset $LastLineChecksum with
#	&Read_History_With_TmpUpdate(lastyearbeforeupdate,lastmonthbeforeupdate,lastdaybeforeupdate,lasthourbeforeupdate,NOUPDATE,NOPURGE,"general");
#
# &Init_HashArray()
#
# If 'update'
#   Loop on each new line in log file
#     lastlineoffset=lastlineoffsetnext; lastlineoffsetnext=file pointer position
#     If line corrupted, skip --> next on loop
#	  Drop wrong virtual host --> next on loop
#     Drop wrong method/protocol --> next on loop
#     Check date --> next on loop
#     If line older than $LastLine, skip --> next on loop
#     So it's new line
#     $LastLine = time or record
#     Skip if url is /robots.txt --> next on loop
#     Skip line for @SkipHosts --> next on loop
#     Skip line for @SkipFiles --> next on loop
#     Skip line for @SkipUserAgent --> next on loop
#     Skip line for not @OnlyHosts --> next on loop
#     Skip line for not @OnlyUsers --> next on loop
#     Skip line for not @OnlyFiles --> next on loop
#     Skip line for not @OnlyUserAgent --> next on loop
#     So it's new line approved
#     If other month/year, create/update tmp file and purge data arrays with
#       &Read_History_With_TmpUpdate(lastprocessedyear,lastprocessedmonth,lastprocessedday,lastprocessedhour,UPDATE,PURGE,"all",lastlinenb,lastlineoffset,CheckSum($_));
#     Define a clean Url and Query (set urlwithnoquery, tokenquery and standalonequery and $field[$pos_url])
#     Define PageBool and extension
#     Analyze: Misc tracker --> complete %misc
#     Analyze: Hit on favorite icon --> complete %_misc, countedtraffic=1 (not counted anywhere)
#     If (!countedtraffic) Analyze: Worms --> complete %_worms, countedtraffic=2
#     If (!countedtraffic) Analyze: Status code --> complete %_error_, %_sider404, %_referrer404 --> countedtraffic=3
#     If (!countedtraffic) Analyze: Robots known --> complete %_robot, countedtraffic=4
#     If (!countedtraffic) Analyze: Robots unknown on robots.txt --> complete %_robot, countedtraffic=5
#     If (!countedtraffic) Analyze: File types - Compression
#     If (!countedtraffic) Analyze: Date - Hour - Pages - Hits - Kilo
#     If (!countedtraffic) Analyze: Login
#     If (!countedtraffic) Do DNS Lookup
#     If (!countedtraffic) Analyze: Country
#     If (!countedtraffic) Analyze: Host - Url - Session
#     If (!countedtraffic) Analyze: Browser - OS
#     If (!countedtraffic) Analyze: Referer
#     If (!countedtraffic) Analyze: EMail
#     Analyze: Cluster
#     Analyze: Extra (must be after 'Define a clean Url and Query')
#     If too many records, we flush data arrays with
#       &Read_History_With_TmpUpdate(lastprocessedyear,lastprocessedmonth,lastprocessedday,lastprocessedhour,UPDATE,PURGE,"all",lastlinenb,lastlineoffset,CheckSum($_));
#   End of loop
#
#   Create/update tmp file
#	  Seek to lastlineoffset in logfile to read and get last line into $_
#	  &Read_History_With_TmpUpdate(lastprocessedyear,lastprocessedmonth,lastprocessedday,lastprocessedhour,UPDATE,PURGE,"all",lastlinenb,lastlineoffset,CheckSum($_))
#   Rename all created tmp files
# End of 'update'
#
# &Init_HashArray()
#
# If 'output'
#   Loop for each month of required year
#     &Read_History_With_TmpUpdate($YearRequired,$monthloop,'','',NOUPDATE,NOPURGE,'all' or 'general time' if not required month)
#   End of loop
#   Show data arrays in HTML page
#   html_end
# End of 'output'
#-------------------------------------------------------

#-------------------------------------------------------
# DNS CACHE FILE FORMATS SUPPORTED BY AWSTATS
# Format /etc/hosts     x.y.z.w hostname
# Format analog         UT/60 x.y.z.w hostname
#-------------------------------------------------------

#-------------------------------------------------------
# IP Format (d=decimal on 16 bits, x=hexadecimal on 16 bits)
#
# 13.1.68.3						IPv4 (d.d.d.d)
# 0:0:0:0:0:0:13.1.68.3 		IPv6 (x:x:x:x:x:x:d.d.d.d)
# ::13.1.68.3
# 0:0:0:0:0:FFFF:13.1.68.3 		IPv6 (x:x:x:x:x:x:d.d.d.d)
# ::FFFF:13.1.68.3 				IPv6
#
# 1070:0:0:0:0:800:200C:417B 	IPv6
# 1070:0:0:0:0:800:200C:417B 	IPv6
# 1070::800:200C:417B 			IPv6
#-------------------------------------------------------
