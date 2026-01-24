package root.service;

import org.springframework.stereotype.Service;

@Service
public class ParseService {

    public void validateHttpVerb() {
//        $field[$pos_method] eq 'GET'
//                || $field[$pos_method] eq 'POST'
//                || $field[$pos_method] eq 'HEAD'
//                || $field[$pos_method] eq 'PROPFIND'
//                || $field[$pos_method] eq 'CHECKOUT'
//                || $field[$pos_method] eq 'LOCK'
//                || $field[$pos_method] eq 'PROPPATCH'
//                || $field[$pos_method] eq 'OPTIONS'
//                || $field[$pos_method] eq 'MKACTIVITY'
//                || $field[$pos_method] eq 'PUT'
//                || $field[$pos_method] eq 'MERGE'
//                || $field[$pos_method] eq 'DELETE'
//                || $field[$pos_method] eq 'REPORT'
//                || $field[$pos_method] eq 'MKCOL'
//                || $field[$pos_method] eq 'COPY'
//                || $field[$pos_method] eq 'RPC_IN_DATA'
//                || $field[$pos_method] eq 'RPC_OUT_DATA'
//                || $field[$pos_method] eq 'OK'   # Webstar
//                || $field[$pos_method] eq 'ERR!' # Webstar
//                || $field[$pos_method] eq 'PRIV' # Webstar
    }

    public void getSupportedTechnology() {
//        if ($_ =~ /^nojs=(\w+)/i) {
//            $foundparam++;
//            if ($1 eq 'y') {$_misc_h{"JavascriptDisabled"}++;}
//            next;
//        }
//        if ($_ =~ /^java=(\w+)/i) {
//            $foundparam++;
//            if ($1 eq 'true') {$_misc_h{"JavaEnabled"}++;}
//            next;
//        }
//        if ($_ =~ /^shk=(\w+)/i) {
//            $foundparam++;
//            if ($1 eq 'y') {$_misc_h{"DirectorSupport"}++;}
//            next;
//        }
//        if ($_ =~ /^fla=(\w+)/i) {
//            $foundparam++;
//            if ($1 eq 'y') {$_misc_h{"FlashSupport"}++;}
//            next;
//        }
//        if ($_ =~ /^rp=(\w+)/i) {
//            $foundparam++;
//            if ($1 eq 'y') {$_misc_h{"RealPlayerSupport"}++;}
//            next;
//        }
//        if ($_ =~ /^mov=(\w+)/i) {
//            $foundparam++;
//            if ($1 eq 'y') {$_misc_h{"QuickTimeSupport"}++;}
//            next;
//        }
//        if ($_ =~ /^wma=(\w+)/i) {
//            $foundparam++;
//            if ($1 eq 'y') {
//                $_misc_h{"WindowsMediaPlayerSupport"}++;
//            }
//            next;
//        }
//        if ($_ =~ /^pdf=(\w+)/i) {
//            $foundparam++;
//            if ($1 eq 'y') {$_misc_h{"PDFSupport"}++;}
//            next;
//        }
//    }
    }

    public void isAddedToFavorites() {
//        if ($field[$pos_code] != 404) {
//            $_misc_h{'AddToFavourites'}++;
//        }
    }

    public void detectWorms() {
//        foreach (@WormsSearchIDOrder) {
//            if ($field[$pos_url] =~ /$_/) {
//
//                        # It's a worm
//                my $worm = &UnCompileRegex($_);
//                if ($Debug) {
//                    debug(
//                            " Record is a hit from a worm identified by '$worm'",
//                            2
//                    );
//                }
//                $worm = $WormsHashID{$worm} || 'unknown';
//                $_worm_h{$worm}++;
//                if ($pos_size > 0) {$_worm_k{$worm} += int($field[$pos_size]);}
//                $_worm_l{$worm} = $timerecord;
//                $countedtraffic = 2;
//                if ($PageBool) {$_time_nv_p[$hourrecord]++;}
//                $_time_nv_h[$hourrecord]++;
//                if ($pos_size > 0) {$_time_nv_k[$hourrecord] += int($field[$pos_size]);}
//                last;
//            }
//        }
    }

    public void checkRobot() {
//     #study $UserAgent;		Does not increase speed
//        foreach (@RobotsSearchIDOrder) {
//            if ($UserAgent =~ /$_/) {
//                my $bot = &UnCompileRegex($_);
//                $TmpRobot{$UserAgent} = $uarobot = "$bot"
//                ; # Last time, we won't search if robot or not. We know it is.
//                if ($Debug) {
//                    debug(
//                            "  UserAgent '$UserAgent' is added to TmpRobot with value '$bot'",
//                            2
//                    );
//                }
//                last;
//            }
//        }
    }

    public void noUserAgent() {

    }

    public void getRobotByHitToRobotsTxt() {

    }

    public void doDnsLookup() {

    }

    public void processReferrer() {
    // same domain
        // direct access
        // true referrer

        // http://www.mysite.com/ must be same referer than http://www.mysite.com but .../mypage/ differs of .../mypage
//# Origin not found
//        if (!$found) {
//            if ($ShowUnknownOrigin) {
//                print "Unknown origin: $field[$pos_referer]\n";
//            }
//            if ($PageBool) {$_from_p[1]++;}
//            $_from_h[1]++;
//        }

    }

    public void parseCondition() {
//        if ($conditiontype eq 'URL') {
//            if ($Debug) {
//                debug(
//                        "  Check condition '$conditiontype' must contain '$conditiontypeval' in '$urlwithnoquery'",
//                        5
//                );
//            }
//            if ($urlwithnoquery =~ /$conditiontypeval/) {
//                $conditionok = 1;
//                last;
//            }
//        }
//        elsif ($conditiontype eq 'QUERY_STRING') {
//            if ($Debug) {
//                debug(
//                        "  Check condition '$conditiontype' must contain '$conditiontypeval' in '$standalonequery'",
//                        5
//                );
//            }
//            if ($standalonequery =~ /$conditiontypeval/) {
//                $conditionok = 1;
//                last;
//            }
//        }
//        elsif ($conditiontype eq 'URLWITHQUERY') {
//            if ($Debug) {
//                debug(
//                        "  Check condition '$conditiontype' must contain '$conditiontypeval' in '$urlwithnoquery$tokenquery$standalonequery'",
//                        5
//                );
//            }
//            if ("$urlwithnoquery$tokenquery$standalonequery" =~
//                    /$conditiontypeval/) {
//                $conditionok = 1;
//                last;
//            }
//        }
//        elsif ($conditiontype eq 'REFERER') {
//            if ($Debug) {
//                debug(
//                        "  Check condition '$conditiontype' must contain '$conditiontypeval' in '$field[$pos_referer]'",
//                        5
//                );
//            }
//            if ($field[$pos_referer] =~ /$conditiontypeval/) {
//                $conditionok = 1;
//                last;
//            }
//        }
//        elsif ($conditiontype eq 'UA') {
//            if ($Debug) {
//                debug(
//                        "  Check condition '$conditiontype' must contain '$conditiontypeval' in '$field[$pos_agent]'",
//                        5
//                );
//            }
//            if ($field[$pos_agent] =~ /$conditiontypeval/) {
//                $conditionok = 1;
//                last;
//            }
//        }
//        elsif ($conditiontype eq 'HOSTINLOG') {
//            if ($Debug) {
//                debug(
//                        "  Check condition '$conditiontype' must contain '$conditiontypeval' in '$field[$pos_host]'",
//                        5
//                );
//            }
//            if ($field[$pos_host] =~ /$conditiontypeval/) {
//                $conditionok = 1;
//                last;
//            }
//        }
//        elsif ($conditiontype eq 'HOST') {
//            my $hosttouse = ($HostResolved ? $HostResolved : $Host);
//            if ($Debug) {
//                debug(
//                        "  Check condition '$conditiontype' must contain '$conditiontypeval' in '$hosttouse'",
//                        5
//                );
//            }
//            if ($hosttouse =~ /$conditiontypeval/) {
//                $conditionok = 1;
//                last;
//            }
//        }
//        elsif ($conditiontype eq 'VHOST') {
//            if ($Debug) {
//                debug(
//                        "  Check condision '$conditiontype' must contain '$conditiontypeval' in '$field[$pos_vh]'",
//                        5
//                );
//            }
//            if ($field[$pos_vh] =~ /$conditiontypeval/) {
//                $conditionok = 1;
//                last;
//            }
//        }
//        elsif ($conditiontype =~ /extra(\d+)/i) {
//            if ($Debug) {
//                debug(
//                        "  Check condition '$conditiontype' must contain '$conditiontypeval' in '$field[$pos_extra[$1]]'",
//                        5
//                );
//            }
//            if ($field[ $pos_extra[$1] ] =~ /$conditiontypeval/) {
//                $conditionok = 1;
//                last;
//            }
//        }
//                else {
//            error(
//                    "Wrong value of parameter ExtraSectionCondition$extranum"
//            );
//        }
//    }
    }

}
