#!/usr/bin/perl -w

use strict;

use POSIX qw/ceil LC_MESSAGES setlocale strftime/;
use CGI qw/-utf8/;
use I18N::AcceptLanguage;
use Locale::Messages qw/bindtextdomain/;
use Locale::TextDomain qw/qrpearls/;
use Imager::QRCode;
use SVG qw/-nocredits => 1/;
use PDF::API2;

use constant mm => 25.4/72;
use constant in => 1/72;
use constant pt => 1;

use constant pegs => 29;

BEGIN {
    # Select the pure-perl implementation, since xs version does not
    # work with mod_perl2
    Locale::Messages->select_package('gettext_pp');
};

# Directories
my $localedir = "$ENV{BASE_DIRECTORY}/locale";

# QR code defaults
my $preview = 0;
my $level = 'L';
my $version = 0;
my $content = 'http://qr.brixandersen.dk';

# Languages
my @langs = qw/da en/;
my $lang = 'en';

# Initialize CGI and catch errors
my $q = CGI->new;
my $error = $q->cgi_error;
if ($error) {
    print $q->header(-status => $error);
    exit 0;
}

# Determine language
if ($q->cookie('lang') ~~ @langs) {
    $lang = $q->cookie('lang');
} else {
    my $accept = I18N::AcceptLanguage->new(defaultLanguage => $lang);
    my $acceptLang = $accept->accepts($ENV{HTTP_ACCEPT_LANGUAGE}, \@langs);
    $lang = $acceptLang if ($acceptLang);
}
$ENV{'LANGUAGE'} = $lang;
bindtextdomain('qrpearls', $localedir);
setlocale(LC_MESSAGES, '');

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
    $content = $q->param('text');
}

# Generate QR Code
my $black = Imager::Color->new(0, 0, 0);
my $white = Imager::Color->new(255, 255, 255);
my $imager = Imager::QRCode->new(
	size			=> 1,
	margin			=> 1,
	version			=> $version,
	level			=> $level,
	casesensitive	=> 1,
	lightcolor		=> $white,
	darkcolor		=> $black,
    );
my $qrcode = $imager->plot($content);
my $size = $qrcode->getwidth;
$size == $qrcode->getheight or die "Generated QR code is not square";

if ($preview) {
    # Generate preview SVG
    my $svg = SVG->new(viewBox => "0 0 $size $size");
    my $d;

    for (my $y = 0; $y < $size; $y++) {
        my $ys = $y + 0.5;
        $d .= "M 0 $ys ";

        for (my $x = 0; $x < $size; $x++) {
            my $xs = $x + 1;
            my $color = $qrcode->getpixel(x => $x, y => $y);

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
    my $date = strftime("D:%Y%m%d%H%M%S%z'", localtime);
    substr($date, -3, 0, "'");
    $pdf->info(Author		=> 'Henrik Brix Andersen',
               Title		=> __("QR Pearls"),
               Subject		=> __("QR Code Beads Design"),
               Producer		=> 'http://qr.brixandersen.dk',
               CreationDate	=> $date);

    # Fonts
    my $encoding = 'iso-8859-1';
    my %fonts = (
        helvetica => {
            regular	=> $pdf->corefont('Helvetica', -encode => $encoding),
            bold	=> $pdf->corefont('Helvetica-Bold', -encode => $encoding),
        },
        );

    # Title page
    my $page = $pdf->page;
    my $gfx = $page->gfx;
    my $text = $page->text;
    $page->mediabox('A4');

    $gfx->rect(20/mm, 245/mm, 170/mm, 35/mm);
    $gfx->fillcolor('#aaaaaa');
    $gfx->fill;

    $text->translate(105/mm, 255/mm);
    $text->font($fonts{'helvetica'}{'bold'}, 72/pt);
    $text->fillcolor('#ffffff');
    $text->text_center(__("QR Pearls"));

    $gfx->qrcode(65/mm, 145/mm, 75/mm, $qrcode);

    # Parameters
    $text->fillcolor('#000000');
    $text->translate(105/mm, 120/mm);
    $text->font($fonts{'helvetica'}{'bold'}, 20/pt);
    $text->text_center(__("Parameters"));
    $text->font($fonts{'helvetica'}{'regular'}, 18/pt);
    $text->translate(33/mm, 110/mm);
    $text->text(__("Version:"));
    $text->cr(-25/pt);
    $text->text(__("Error correction:"));
    $text->cr(-50/pt);

    $text->translate(100/mm, 110/mm);
    my $realversion = ($size - 23) / 4 + 1;
    $text->text("$realversion (${size}x${size})" . ($version == 0 ? __(" (Automatic)") : ''));
    $text->cr(-25/pt);
    my %levels = (L => __("Low"), M => __("Medium"), Q => __("Quartile"), H => __("High"));
    $text->text($levels{$level});

    # Total required materials
    $text->translate(105/mm, 70/mm);
    $text->font($fonts{'helvetica'}{'bold'}, 20/pt);
    $text->text_center(__("Total Materials"));
    $text->font($fonts{'helvetica'}{'regular'}, 18/pt);
    $text->translate(33/mm, 60/mm);
    $text->text(__("Peg boards (29x29):"));
    $text->cr(-25/pt);
    $text->text(__("Black beads:"));
    $text->cr(-25/pt);
    $text->text(__("White beads:"));

    # Flip QR code before generating peg boards in order to iron the QR code "on the back"
    $qrcode->flip(dir => 'h');

    my $totalblackbeads;
    my $totalwhitebeads;

    # Fill in peg board pages
    my $boards = ceil($size / pegs);
    for (my $boardy = 0; $boardy < $boards; $boardy++) {
        for (my $boardx = 0; $boardx < $boards; $boardx++) {
            my $blackbeads;
            my $whitebeads;
            $page = $pdf->page;
            $gfx = $page->gfx;
            $text = $page->text;
            $page->mediabox('A4');

            # Header
            $text->translate(105/mm, 280/mm);
            $text->font($fonts{'helvetica'}{'regular'}, 8/pt);
            $text->fillcolor('#000000');
            $text->text_center(__("QR Pearls"));
            $gfx->move(20/mm, 280/mm - 4/pt);
            $gfx->hline(190/mm);
            $gfx->linewidth(1/pt);
            $gfx->linejoin(0);
            $gfx->strokecolor('#aaaaaa');
            $gfx->stroke;

            # Peg boards overview
            if ($boards > 1) {
                my $overview = 60/mm / $boards;
                my $posx = 120/mm;
                my $posy = 260/mm;
                my $boardno = 1;
                $gfx->linewidth(1/pt);
                $gfx->linejoin(1);
                $gfx->strokecolor('#aaaaaa');
                $gfx->fillcolor('#aaaaaa');
                for (my $overviewy = 0; $overviewy < $boards; $overviewy++) {
                    for (my $overviewx = 0; $overviewx < $boards; $overviewx++) {
                        $gfx->pegboard($posx + $overviewx * $overview, $posy - $overview - $overviewy * $overview, $overview);
                        if ($overviewx == $boardx && $overviewy == $boardy) {
                            $gfx->fillstroke;
                            $text->fillcolor('#ffffff');
                            $text->render(0);
                        } else {
                            $gfx->stroke;
                            $text->fillcolor('#aaaaaa');
                            $text->render(1);
                        }
                        # Peg boards overview labels
                        $text->translate($posx + $overviewx * $overview + $overview / 2, $posy - $overview - $overviewy * $overview + $overview / 4);
                        $text->font($fonts{'helvetica'}{'bold'}, $overview * 0.75);
                        $text->text_center($boardno++);
                    }
                }
                $text->render(0);
            }

            # Main pegboard
            $gfx->save;
            $gfx->pegboard(33/mm, 40/mm, 144/mm);
            $gfx->linewidth(1/pt);
            $gfx->linejoin(1);
            $gfx->strokecolor('#aaaaaa');
            $gfx->stroke;

            my $dia = 144/mm / pegs;
            $gfx->translate(33/mm, 40/mm + 144/mm);
            $gfx->linewidth(1/pt);
            $gfx->strokecolor('#000000');
            $gfx->fillcolor('#000000');
            for (my $beadx = 0; $beadx < pegs; $beadx++) {
                for (my $beady = 0; $beady < pegs; $beady++) {
                    my $x = $beadx * $dia + $dia / 2;
                    my $y = - $beady * $dia - $dia / 2;
                    my $color = $qrcode->getpixel(x => $boardx * pegs + $beadx, y => $boardy * pegs + $beady);
                    $gfx->circle($x, $y, $dia / 6);
                    if (defined($color)) {
                        $gfx->circle($x, $y, $dia / 2 - 0.5/pt);
                        if ($color->equals(other => $black)) {
                            $gfx->fillstroke(1);
                            $blackbeads++;
                        } else {
                            $gfx->stroke;
                            $whitebeads++;
                        }
                    } else {
                        $gfx->save;
                        $gfx->strokecolor('#aaaaaa');
                        $gfx->stroke;
                        $gfx->restore;
                    }
                }
            }
            $gfx->restore;

            # Required materials
            $text->translate(33/mm, 255/mm);
            $text->font($fonts{'helvetica'}{'bold'}, 18/pt);
            $text->fillcolor('#000000');
            $text->text(__("Materials"));
            $text->font($fonts{'helvetica'}{'regular'}, 16/pt);
            $text->translate(33/mm, 245/mm);
            $text->text(__("Black beads:"));
            $text->cr(-25/pt);
            $text->text(__("White beads:"));
            $text->translate(80/mm, 245/mm);
            $text->text($blackbeads);
            $text->cr(-25/pt);
            $text->text($whitebeads);

            $totalblackbeads += $blackbeads;
            $totalwhitebeads += $whitebeads;
        }
    }

    # Fill in total required materials on front page
    $page = $pdf->openpage(1);
    $text = $page->text;
    $text->font($fonts{'helvetica'}{'regular'}, 18/pt);
    $text->translate(110/mm, 60/mm);
    $text->text($boards ** 2);
    $text->cr(-25/pt);
    $text->text($totalblackbeads);
    $text->cr(-25/pt);
    $text->text($totalwhitebeads);

    # Add footer to all pages
    for (1..$pdf->pages) {
        $page = $pdf->openpage($_);
        $gfx = $page->gfx;
        $text = $page->text;

        $gfx->move(20/mm, 10/mm + 8/pt);
        $gfx->hline(190/mm);
        $gfx->linewidth(1/pt);
        $gfx->linejoin(0);
        $gfx->strokecolor('#aaaaaa');
        $gfx->stroke;

        $text->translate(20/mm + 1/pt, 10/mm);
        $text->font($fonts{'helvetica'}{'regular'}, 8/pt);
        $text->fillcolor('#000000');
        $text->text(__("Generated by http://qr.brixandersen.dk"));
        $text->translate(190/mm - 1/pt, 10/mm);
        $text->text_right(__("Page") . " $_/" . $pdf->pages);
    }

    print $q->header(-expires => '0',
                     -type => 'application/pdf',
                     -attachment => 'QR Pearls.pdf');
    print $pdf->stringify;

    $pdf->end;
}

sub PDF::API2::Content::qrcode {
    my ($gfx, $x, $y, $size, $qrcode) = @_;
    my $pixels = $qrcode->getheight;
    my $scale = $size / $pixels;

    $gfx->save;
    $gfx->translate($x, $y + $size);
    $gfx->scale($scale, $scale);
    $gfx->fillcolor('#000000');

    for (my $xp = 0; $xp < $pixels; $xp++) {
        for (my $yp = 0; $yp < $pixels; $yp++) {
            my $color = $qrcode->getpixel(x => $xp, y => $yp);
            if ($color->equals(other => $black)) {
                $gfx->rect($xp/pt, -$yp/pt, 1/pt, 1/pt);
            }
        }
    }

    $gfx->fill;
    $gfx->restore;

    return $gfx;
}

sub PDF::API2::Content::pegboard {
    my ($gfx, $x, $y, $size) = @_;
    my $r = $size / 72;
    my $hinge_w  = $size / 36;    # Hinge width
    my $hinge_ih = $size / 12;    # Hinge inner height
    my $hinge_oh = $size / 72;    # Hinge outer height
    my $hinge_d  = $size / 4.965; # Hinge distance from edge

    $gfx->save;
    $gfx->move($x, $y);

    # Top left corner
    $gfx->arc($x + $r, $y + $size - $r, $r, $r, 180, 90, 1);

    # Top right corner
    $gfx->arc($x + $size - $r, $y + $size - $r, $r, $r, 90, 0, 0);

    # Right topmost hinge
    $gfx->line($x + $size, $y + $size - $hinge_d);
    $gfx->line($x + $size + $hinge_w, $y + $size - $hinge_d + $hinge_oh);
    $gfx->vline($y + $size - $hinge_d - $hinge_ih - $hinge_oh);
    $gfx->line($x + $size, $y + $size - $hinge_d - $hinge_ih);

    # Right bottommost hinge
    $gfx->line($x + $size, $y + $hinge_d + $hinge_ih);
    $gfx->line($x + $size + $hinge_w, $y + $hinge_d + $hinge_ih + $hinge_oh);
    $gfx->vline($y + $hinge_d - $hinge_oh);
    $gfx->line($x + $size, $y + $hinge_d);

    # Bottom right corner
    $gfx->arc($x + $size - $r, $y + $r, $r, $r, 360, 270, 0);

    # Bottom rightmost hinge
    $gfx->line($x + $size - $hinge_d, $y);
    $gfx->line($x + $size - $hinge_d + $hinge_oh, $y - $hinge_w);
    $gfx->hline($x + $size - $hinge_d - $hinge_ih - $hinge_oh);
    $gfx->line($x + $size - $hinge_d - $hinge_ih, $y);

    # Right bottommost hinge
    $gfx->line($x + $hinge_d + $hinge_ih, $y);
    $gfx->line($x + $hinge_d + $hinge_ih + $hinge_oh, $y - $hinge_w);
    $gfx->hline($x + $hinge_d - $hinge_oh);
    $gfx->line($x + $hinge_d, $y);

    # Bottom left corner
    $gfx->arc($x + $r, $y + $r, $r, $r, 270, 180, 0);

    $gfx->close;
    $gfx->restore;

    return $gfx;
}
