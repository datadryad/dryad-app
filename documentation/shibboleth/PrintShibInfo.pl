#!/usr/bin/perl
# @(#) Test shibboleth IdP configuration via CGI

my $HTML_HEADER=<<"END_HEADER";
Content-type: text/html; charset=iso-8859-1

<title>Shibboleth Attribute Test</title>
<h1>Shibboleth Attribute Test - $ENV{"SERVER_NAME"}</h1>
<p>
This CGI checks to see if this server is receiving the
attributes from your Identity Provider that it requires to
successfully authenticate you as a user of this resource.
</p>
END_HEADER

#----------------------------------------------------------------------------

my $eppn;
my $mail;
$eppn = $mail = '';

print $HTML_HEADER;

KEY_LOOP:
for my $k (sort(keys(%ENV))) {
    # Skip keys with empty values.
    $headervalue = $ENV{$k}
      or next KEY_LOOP;

    # Skip environment variables we (probably) don't care about.
    $k =~ /^(HTTP_EPPN|HTTP_MAIL|Shib|[a-z])/
      or next KEY_LOOP;

    $label = "<b>$k:</b> ";

    # Probably not necessary, but just in case.....
    $headervalue =~ tr/\000-\037\177-\377//d;
    $headervalue =~ s/</&lt;/g;
    $headervalue =~ s/>/&gt;/g;

    if (($k eq 'HTTP_EPPN') && ($headervalue =~ /.+\@.+\..+/)) {
      $eppn = $headervalue;
    } elsif (($k eq 'HTTP_MAIL') && ($headervalue =~ /.+\@.+\..+/)) {
      $mail = $headervalue;
    } else {
      $printInfo .= $label . $headervalue . "\n";
    }
}

if ($eppn && $mail) {
    print <<"END_SUCCESS_MSG";
        <h2>Success!</h2>
        The attributes required (eppn and mail) are being successfully received by this SP.
        <ul>
        <li> eppn: $eppn
        <li> mail: $mail
        </ul>
END_SUCCESS_MSG
} else {
    print <<"END_FAILURE_MSG";
        <h2>Failure!</h2>
        All the attributes required (eppn and mail) are NOT being successfully received by this SP.
        <ul>
        <li> eppn: $eppn
        <li> mail: $mail
        </ul>
        Please review your Identity Provider logs and attribute release rules
        to determine what might be preventing releasing all the necessary
        attributes to this SP.
END_FAILURE_MSG
}

print <<"END_HTML_FOOTER";
<h3>All the Shibboleth-related information being received by this SP</h3>
<pre>
$printInfo
</pre>
END_HTML_FOOTER

exit;
