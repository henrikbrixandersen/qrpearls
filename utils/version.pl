#!/usr/local/perl -w

use strict;

my $size = 21;
foreach my $i (1..40) {
    print "              <option value=\"$i\">$i (${size}x${size})</option>\n";
    $size += 4;
}
