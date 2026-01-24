package root.service;

public class FilterService {
    /*
if ($ENV{'GATEWAY_INTERFACE'}) {
    # Run from a browser as CGI
    $DebugMessages = 0;

    # Prepare QueryString
    if ($ENV{'CONTENT_LENGTH'}) {
        binmode STDIN;
        read(STDIN, $QueryString, $ENV{'CONTENT_LENGTH'});
    }
    if ($ENV{'QUERY_STRING'}) {
        $QueryString = $ENV{'QUERY_STRING'};

        # Set & and &amp; to &amp;
        $QueryString =~ s/&amp;/&/g;
        $QueryString =~ s/&/&amp;/g;
    }

    # Remove all XSS vulnerabilities coming from AWStats parameters
    $QueryString = CleanXSS(&DecodeEncodedString($QueryString));

    # Security test
    if ($QueryString =~ /LogFile=([^&]+)/i) {
        error(
            "Logfile parameter can't be overwritten when AWStats is used from a CGI"
        );
    }

    # No update but report by default when run from a browser
    $UpdateStats = ($QueryString =~ /update=1/i ? 1 : 0);

    if ($QueryString =~ /config=([^&]+)/i) {
        $SiteConfig = &Sanitize("$1");
    }
    if ($QueryString =~ /diricons=([^&]+)/i) {$DirIcons = "$1";}
    if ($QueryString =~ /pluginmode=([^&]+)/i) {
        $PluginMode = &Sanitize("$1", 1);
    }
    if ($QueryString =~ /configdir=([^&]+)/i) {
        $DirConfig = &Sanitize("$1");
        $DirConfig =~ s/\\{2,}/\\/g; # This is to clean Remote URL
        $DirConfig =~ s/\/{2,}/\//g; # This is to clean Remote URL
    }

    # All filters
    if ($QueryString =~ /hostfilter=([^&]+)/i) {
        $FilterIn{'host'} = "$1";
    } # Filter on host list can also be defined with hostfilter=filter
    if ($QueryString =~ /hostfilterex=([^&]+)/i) {
        $FilterEx{'host'} = "$1";
    } #
    if ($QueryString =~ /urlfilter=([^&]+)/i) {
        $FilterIn{'url'} = "$1";
    }                                                                      # Filter on URL list can also be defined with urlfilter=filter
    if ($QueryString =~ /urlfilterex=([^&]+)/i) {$FilterEx{'url'} = "$1";} #
    if ($QueryString =~ /refererpagesfilter=([^&]+)/i) {
        $FilterIn{'refererpages'} = "$1";
    } # Filter on referer list can also be defined with refererpagesfilter=filter
    if ($QueryString =~ /refererpagesfilterex=([^&]+)/i) {
        $FilterEx{'refererpages'} = "$1";
    } #
    # All output
    if ($QueryString =~ /output=allhosts:([^&]+)/i) {
        $FilterIn{'host'} = "$1";
    } # Filter on host list can be defined with output=allhosts:filter to reduce number of lines read and showed
    if ($QueryString =~ /output=lasthosts:([^&]+)/i) {
        $FilterIn{'host'} = "$1";
    } # Filter on host list can be defined with output=lasthosts:filter to reduce number of lines read and showed
    if ($QueryString =~ /output=urldetail:([^&]+)/i) {
        $FilterIn{'url'} = "$1";
    } # Filter on URL list can be defined with output=urldetail:filter to reduce number of lines read and showed
    if ($QueryString =~ /output=refererpages:([^&]+)/i) {
        $FilterIn{'refererpages'} = "$1";
    } # Filter on referer list can be defined with output=refererpages:filter to reduce number of lines read and showed

    # If migrate
    if ($QueryString =~ /(^|-|&|&amp;)migrate=([^&]+)/i) {
        $MigrateStats = &Sanitize("$2");

        $MigrateStats =~ /^(.*)$PROG(\d{0,2})(\d\d)(\d\d\d\d)(.*)\.txt$/;
        $SiteConfig = &Sanitize($5 ? $5 : 'xxx');
        $SiteConfig =~ s/^\.//; # SiteConfig is used to find config file
    }

    $SiteConfig =~ s/\.\.//g; # Avoid directory transversal
}
else {
    # Run from command line
    $DebugMessages = 1;

    # Prepare QueryString
    for (0 .. @ARGV - 1) {

        # If migrate
        if ($ARGV[$_] =~ /(^|-|&|&amp;)migrate=([^&]+)/i) {
            $MigrateStats = &Sanitize("$2");

            $MigrateStats =~ /^(.*)$PROG(\d{0,2})(\d\d)(\d\d\d\d)(.*)\.txt$/;
            $SiteConfig = &Sanitize($5 ? $5 : 'xxx');
            $SiteConfig =~ s/^\.//; # SiteConfig is used to find config file
            next;
        }

        # TODO Check if ARGV is in @AllowedArg
        if ($QueryString) {$QueryString .= '&amp;';}
        my $NewLinkParams = $ARGV[$_];
        $NewLinkParams =~ s/^-+//;
        $QueryString .= "$NewLinkParams";
    }

    # Remove all XSS vulnerabilities coming from AWStats parameters
    $QueryString = CleanXSS($QueryString);

    # Security test
    if ($ENV{'AWSTATS_DEL_GATEWAY_INTERFACE'}
        && $QueryString =~ /LogFile=([^&]+)/i) {
        error(
            "Logfile parameter can't be overwritten when AWStats is used from a CGI"
        );
    }

    # Update with no report by default when run from command line
    $UpdateStats = 1;

    if ($QueryString =~ /config=([^&]+)/i) {
        $SiteConfig = &Sanitize("$1");
    }
    if ($QueryString =~ /diricons=([^&]+)/i) {$DirIcons = "$1";}
    if ($QueryString =~ /pluginmode=([^&]+)/i) {
        $PluginMode = &Sanitize("$1", 1);
    }
    if ($QueryString =~ /configdir=([^&]+)/i) {
        $DirConfig = &Sanitize("$1");
        $DirConfig =~ s/\\{2,}/\\/g; # This is to clean Remote URL
        $DirConfig =~ s/\/{2,}/\//g; # This is to clean Remote URL
    }

    # All filters
    if ($QueryString =~ /hostfilter=([^&]+)/i) {
        $FilterIn{'host'} = "$1";
    } # Filter on host list can also be defined with hostfilter=filter
    if ($QueryString =~ /hostfilterex=([^&]+)/i) {
        $FilterEx{'host'} = "$1";
    } #
    if ($QueryString =~ /urlfilter=([^&]+)/i) {
        $FilterIn{'url'} = "$1";
    }                                                                      # Filter on URL list can also be defined with urlfilter=filter
    if ($QueryString =~ /urlfilterex=([^&]+)/i) {$FilterEx{'url'} = "$1";} #
    if ($QueryString =~ /refererpagesfilter=([^&]+)/i) {
        $FilterIn{'refererpages'} = "$1";
    } # Filter on referer list can also be defined with refererpagesfilter=filter
    if ($QueryString =~ /refererpagesfilterex=([^&]+)/i) {
        $FilterEx{'refererpages'} = "$1";
    } #
    # All output
    if ($QueryString =~ /output=allhosts:([^&]+)/i) {
        $FilterIn{'host'} = "$1";
    } # Filter on host list can be defined with output=allhosts:filter to reduce number of lines read and showed
    if ($QueryString =~ /output=lasthosts:([^&]+)/i) {
        $FilterIn{'host'} = "$1";
    } # Filter on host list can be defined with output=lasthosts:filter to reduce number of lines read and showed
    if ($QueryString =~ /output=urldetail:([^&]+)/i) {
        $FilterIn{'url'} = "$1";
    } # Filter on URL list can be defined with output=urldetail:filter to reduce number of lines read and showed
    if ($QueryString =~ /output=refererpages:([^&]+)/i) {
        $FilterIn{'refererpages'} = "$1";
    } # Filter on referer list can be defined with output=refererpages:filter to reduce number of lines read and showed
    # Config parameters
    if ($QueryString =~ /LogFile=([^&]+)/i) {$LogFile = "$1";}

    # If show options
    if ($QueryString =~ /showsteps/i) {
        $ShowSteps = 1;
        $QueryString =~ s/showsteps[^&]*/ /*/i;
}
    if ($QueryString =~ /showcorrupted/i) {
$ShowCorrupted = 1;
$QueryString =~ s/showcorrupted[^&]*/ /*/i;
        }
        if ($QueryString =~ /showdropped/i) {
$ShowDropped = 1;
$QueryString =~ s/showdropped[^&]*/ /* /i;
        }
        if ($QueryString =~ /showunknownorigin/i) {
$ShowUnknownOrigin = 1;
//$QueryString =~ s/showunknownorigin[^&]*//* /i; */
//        }
//        if ($QueryString =~ /showdirectorigin/i) {
//$ShowDirectOrigin = 1;
//$QueryString =~ s/showdirectorigin[^&]*//i;
//        }
//
//$SiteConfig =~ s/\.\.//g;
//        }
//        if ($QueryString =~ /(^|&|&amp;)staticlinks/i) {
//$StaticLinks = "$PROG.$SiteConfig";
//        }
//        if ($QueryString =~ /(^|&|&amp;)staticlinks=([^&]+)/i) {
//$StaticLinks = "$2";
//        } # When ran from awstatsbuildstaticpages.pl
//if ($QueryString =~ /(^|&|&amp;)staticlinksext=([^&]+)/i) {
//$StaticExt = "$2";
//        }
//        if ($QueryString =~ /(^|&|&amp;)framename=([^&]+)/i) {$FrameName = "$2";}
//        if ($QueryString =~ /(^|&|&amp;)debug=(\d+)/i) {$Debug = $2;}
//        if ($QueryString =~ /(^|&|&amp;)databasebreak=(\w+)/i) {
//$DatabaseBreak = $2;
//}
//        if ($QueryString =~ /(^|&|&amp;)updatefor=(\d+)/i) {$UpdateFor = $2;}
//
//        if ($QueryString =~ /(^|&|&amp;)noloadplugin=([^&]+)/i) {
//foreach (split(/,/, $2)) {$NoLoadPlugin{ &Sanitize("$_", 1) } = 1;}
//        }
//        if ($QueryString =~ /(^|&|&amp;)limitflush=(\d+)/i) {$LIMITFLUSH = $2;}
//        if ($QueryString =~ /(^|&|&amp;)nboflastupdatelookuptosave=(\d+)/i) {$NBOFLASTUPDATELOOKUPTOSAVE = $2;}
//
//        # Get/Define output
//if ($QueryString =~
//        /(^|&|&amp;)output(=[^&]*|)(.*)(&|&amp;)output(=[^&]*|)(&|$)/i) {
//error("Only 1 output option is allowed", "", "", 1);
//}
//        if ($QueryString =~ /(^|&|&amp;)output(=[^&]*|)(&|$)/i) {
//
//        # At least one output expected. We define %HTMLOutput
//my $outputlist = "$2";
//    if ($outputlist) {
//$outputlist =~ s/^=//;
//foreach my $outputparam (split(/,/, $outputlist)) {
//$outputparam =~ s/:(.*)$//;
//            if ($outputparam) {$HTMLOutput{ lc($outputparam) } = "$1" || 1;}
//        }
//        }
//
//        # If on command line and no update
//    if (!$ENV{'GATEWAY_INTERFACE'} && $QueryString !~ /update/i) {
//$UpdateStats = 0;
//        }
//
//        # If no output defined, used default value
//    if (!scalar keys %HTMLOutput) {$HTMLOutput{'main'} = 1;}
//        }
//        if ($ENV{'GATEWAY_INTERFACE'} && !scalar keys %HTMLOutput) {
//$HTMLOutput{'main'} = 1;
//        }
//
//        # Remove -output option with no = from QueryString
//        $QueryString =~ s/(^|&|&amp;)output(&|$)/$1$2/i;
//$QueryString =~ s/&+$//;
//
//# Check year, month, day, hour parameters
//if ($QueryString =~ /(^|&|&amp;)month=(year)/i) {
//error("month=year is a deprecated option. Use month=all instead.");
//}
//        if ($QueryString =~ /(^|&|&amp;)year=(\d\d\d\d)/i) {
//$YearRequired = sprintf("%04d", $2);
//}
//        else {$YearRequired = "$nowyear";}
//        if ($QueryString =~ /(^|&|&amp;)month=(\d{1,2})/i) {
//$MonthRequired = sprintf("%02d", $2);
//}
//elsif ($QueryString =~ /(^|&|&amp;)month=(all)/i) {$MonthRequired = 'all';}
//        else {$MonthRequired = "$nowmonth";}
//        if ($QueryString =~ /(^|&|&amp;)day=(\d{1,2})/i) {
//$DayRequired = sprintf("%02d", $2);
//} # day is a hidden option. Must not be used (Make results not understandable). Available for users that rename history files with day.
//else {$DayRequired = '';}
//        if ($QueryString =~ /(^|&|&amp;)hour=(\d{1,2})/i) {
//$HourRequired = sprintf("%02d", $2);
//} # hour is a hidden option. Must not be used (Make results not understandable). Available for users that rename history files with day.
//else {$HourRequired = '';}
//
//    * */
}
