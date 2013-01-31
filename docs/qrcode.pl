#!/usr/bin/perl -w

use strict;

use CGI qw/-utf8/;
use Locale::TextDomain;
use Imager::QRCode;
use SVG qw/-nocredits => 1/;
use PDF::API2;

use constant mm => 25.4/72;
use constant in => 1/72;
use constant pt => 1;

# QR code defaults
my $preview = 0;
my $level = 'L';
my $version = 0;
my $text = 'http://qr.brixandersen.dk';

# Initialize CGI and catch errors
my $q = CGI->new;
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
	size			=> 1,
	margin			=> 1,
	version			=> $version,
	level			=> $level,
	casesensitive	=> 1,
	lightcolor		=> $white,
	darkcolor		=> $black,
    );
my $img = $qrcode->plot($text);

if ($preview) {
    # Generate preview SVG
    my $width = $img->getwidth;
    my $height = $img->getheight;
    my $svg = SVG->new(viewBox => "0 0 $width $height");
    my $d;

    for (my $y = 0; $y < $height; $y++) {
        my $ys = $y + 0.5;
        $d .= "M 0 $ys ";

        for (my $x = 0; $x < $width; $x++) {
            my $xs = $x + 1;
            my $color = $img->getpixel(x => $x, y => $y);

            if ($color->equals(other => $black)) {
                $d .= "H $xs ";
            } else {
                $d .= "M $xs $ys ";
            }
        }
    }

    $svg->path(d => $d,
               style => {
                   fill => 'none',
                   stroke => 'rgb(0,0,0)',
                   'stroke-width' => 1,
                   'stroke-linecap' => 'butt',
               });

    print $q->header(-expires => '0',
                     -type => 'image/svg+xml');
    print $svg->xmlify(-inline => 1);;
} else {
    # Generate PDF
    my $pdf = PDF::API2->new();
    # TODO: CreationDate
    $pdf->info(Author		=> 'Henrik Brix Andersen',
               Title		=> 'QR Pearls',
               Subject		=> 'QR Code Beads Design',
               Creator		=> 'http://qr.brixandersen.dk');

    # Fonts
    my $encoding = 'iso-8859-1';
    my %fonts = (
        helvetica => {
            regular	=> $pdf->corefont('Helvetica', -encode => $encoding),
            bold	=> $pdf->corefont('Helvetica-Bold', -encode => $encoding),
            italic	=> $pdf->corefont('Helvetica-Oblique', -encode => $encoding),
        },
        times => {
            regular	=> $pdf->corefont('Times', -encode => $encoding),
            bold	=> $pdf->corefont('Times-Bold', -encode => $encoding),
            italic	=> $pdf->corefont('Times-Italic', -encode => $encoding),
        }
        );

    # Title page
    my $page = $pdf->page;
    $page->mediabox('A4');

    # TODO: Fill in pages
    my $gfx = $page->gfx;

    $gfx->pegboard(33/mm, 60/mm, 144/mm);
    $gfx->linewidth(1/pt);
    $gfx->linejoin(1);
    $gfx->strokecolor('#aaaaaa');
    $gfx->stroke;

    print $q->header(-expires => '0',
                     -type => 'application/pdf',
                     -attachment => 'QR Pearls.pdf');
    print $pdf->stringify;
    $pdf->end;
}

sub PDF::API2::Content::pegboard {
    my ($gfx, $x, $y, $size) = @_;
    my $r = $size / 72;
    my $hinge_w  = $size / 36;    # Hinge width
    my $hinge_ih = $size / 12;    # Hinge inner height
    my $hinge_oh = $size / 72;    # Hinge outer height
    my $hinge_d  = $size / 4.965; # Hinge distance from edge

    $gfx->save;
    $gfx->translate($x, $y);
    $gfx->move(0, 0);

    # TODO: Use translate + rotate instead of this mess

    # Top left corner
    $gfx->arc($r, $size - $r, $r, $r, 180, 90, 1);

    # Top right corner
    $gfx->arc($size - $r, $size - $r, $r, $r, 90, 0, 0);

    # Right topmost hinge
    $gfx->line($size, $size - $hinge_d);
    $gfx->line($size + $hinge_w, $size - $hinge_d + $hinge_oh);
    $gfx->line($size + $hinge_w, $size - $hinge_d - $hinge_ih - $hinge_oh);
    $gfx->line($size, $size - $hinge_d - $hinge_ih);

    # Right bottommost hinge
    $gfx->line($size, $hinge_d + $hinge_ih);
    $gfx->line($size + $hinge_w, $hinge_d + $hinge_ih + $hinge_oh);
    $gfx->line($size + $hinge_w, $hinge_d - $hinge_oh);
    $gfx->line($size, $hinge_d);

    # Bottom right corner
    $gfx->arc($size - $r, $r, $r, $r, 360, 270, 0);

    # Bottom rightmost hinge
    $gfx->line($size - $hinge_d, 0);
    $gfx->line($size - $hinge_d + $hinge_oh, -$hinge_w);
    $gfx->line($size - $hinge_d - $hinge_ih - $hinge_oh, -$hinge_w);
    $gfx->line($size - $hinge_d - $hinge_ih, 0);

    # Right bottommost hinge
    $gfx->line($hinge_d + $hinge_ih, 0);
    $gfx->line($hinge_d + $hinge_ih + $hinge_oh, -$hinge_w);
    $gfx->line($hinge_d - $hinge_oh, -$hinge_w);
    $gfx->line($hinge_d, 0);

    # Bottom left corner
    $gfx->arc($r, $r, $r, $r, 270, 180, 0);

    $gfx->close;
    $gfx->restore;

    return $gfx;
}
