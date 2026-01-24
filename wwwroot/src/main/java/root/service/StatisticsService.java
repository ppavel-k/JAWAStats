package root.service;

public class StatisticsService {


    /*
    # TotalVisits TotalUnique TotalPages TotalHits TotalBytes TotalHostsKnown TotalHostsUnknown
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


    */
}
