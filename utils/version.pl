#!/usr/local/perl -w

use strict;

# Version = 1 + margin
my $size = 21 + 2;
foreach my $i (1..40) {
    print "              <option value=\"$i\">$i (${size}x${size})</option>\n";
    $size += 4;
}
