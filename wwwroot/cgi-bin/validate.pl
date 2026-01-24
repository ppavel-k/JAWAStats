
# Output main frame page and exit. This must be after the security check.
if ($FrameName eq 'index') {

    # Define the NewLinkParams for main chart
    my $NewLinkParams = ${QueryString};
    $NewLinkParams =~ s/(^|&|&amp;)framename=[^&]*//i;
    $NewLinkParams =~ s/(&amp;|&)+/&amp;/i;
    $NewLinkParams =~ s/^&amp;//;
    $NewLinkParams =~ s/&amp;$//;
    if ($NewLinkParams) {$NewLinkParams = "${NewLinkParams}&amp;";}

    # Exit if main frame
    print "<frameset cols=\"$FRAMEWIDTH,*\">\n";
    print "<frame name=\"mainleft\" src=\""
        . XMLEncode("$AWScript${NewLinkParams}framename=mainleft")
        . "\" noresize=\"noresize\" frameborder=\"0\" />\n";
    print "<frame name=\"mainright\" src=\""
        . XMLEncode("$AWScript${NewLinkParams}framename=mainright")
        . "\" noresize=\"noresize\" scrolling=\"yes\" frameborder=\"0\" />\n";
    print "<noframes><body>";
    print "Your browser does not support frames.<br />\n";
    print "You must set AWStats UseFramesWhenCGI parameter to 0\n";
    print "to see your reports.<br />\n";
    print "</body></noframes>\n";
    print "</frameset>\n";
    &html_end(0);
    exit 0;
}