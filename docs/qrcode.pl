#!/usr/bin/perl -w

use strict;

use CGI qw/-utf8/;
use Locale::TextDomain;
use Imager::QRCode;
use SVG qw/-nocredits => 1/;

# QR code defaults
my $preview = 0;
my $level = 'L';
my $version = 0;
my $text = 'http://qr.brixandersen.dk';

# SVG defaults
my $svgscale = 10;

# Initialize CGI and catch errors
my $q = CGI->new;
$q->charset('UTF-8');
my $error = $q->cgi_error;
if ($error) {
    print $q->header(-status => $error);
    exit 0;
}

# Validate parameters
if ($q->param('preview') == 1) {
    $preview = 1;
}
if ($q->param('level') =~ /^[LMQH]$/) {
    $level = $q->param('level');
}
if ($q->param('version') >= 0 && $q->param('version') <= 40) {
    $version = $q->param('version');
}
if (utf8::valid($q->param('text'))) {
    $text = $q->param('text');
}

# Generate QR Code
my $black = Imager::Color->new(0, 0, 0);
my $white = Imager::Color->new(255, 255, 255);
my $qrcode = Imager::QRCode->new(
	'size'			=> 1,
	'margin'		=> 1,
	'version'		=> $version,
	'level'			=> $level,
	'casesensitive'	=> 1,
	'lightcolor'	=> $white,
	'darkcolor'		=> $black,
    );
my $img = $qrcode->plot($text);

if ($preview) {
    # Generate preview SVG
    my $width = $img->getwidth;
    my $height = $img->getheight;
    # TODO: Calculate scale

    my $svg = SVG->new('width' => $width * $svgscale, 'height' => $height * $svgscale);
    my $d;

    for (my $y = 0; $y < $height; $y++) {
        my $ys = ($y + 0.5) * $svgscale;
        $d .= "M 0 $ys ";

        for (my $x = 0; $x < $width; $x++) {
            my $xs = ($x + 1) * $svgscale;
            my $color = $img->getpixel('x' => $x, 'y' => $y);

            if ($color->equals('other' => $black)) {
                $d .= "H $xs ";
            } else {
                $d .= "M $xs $ys ";
            }
        }
    }

    $svg->path('d' => $d,
               'style' => {
                   'fill' => 'none',
                   'stroke' => 'rgb(0,0,0)',
                   'stroke-width' => $svgscale,
                   'stroke-linecap' => 'butt',
               });

    print $q->header(-expires => '0',
                     -type => 'image/svg+xml');
    print $svg->xmlify;
} else {
    # Generate PDF
    # TODO
}
