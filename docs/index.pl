#!/usr/bin/perl -w

use strict;

use CGI qw/-utf8/;
use I18N::AcceptLanguage;
use HTML::Template;
use HTML::Template::Expr;
use Locale::TextDomain;
use Imager::QRCode;
use SVG qw/-nocredits => 1/;

my $tmpldir = "$ENV{BASE_DIRECTORY}/tmpl";

my $charset = 'UTF-8';
my @langs = qw/en da/;
my $lang = 'en';

my $q = CGI->new;
$q->charset('UTF-8');

# Catch errors
my $error = $q->cgi_error;
if ($error) {
    print $q->header(-status => $error);
    exit 0;
}

# Determine language
my $accept = I18N::AcceptLanguage->new(defaultLanguage => $lang);
my $acceptLang = $accept->accepts($ENV{HTTP_ACCEPT_LANGUAGE}, \@langs);
my $cookie;
if ($q->param('lang') ~~ @langs) {
    $lang = $q->param('lang');
    $cookie = $q->cookie(-name => 'lang', value => $lang);
} elsif ($q->cookie('lang') ~~ @langs) {
    $lang = $q->cookie('lang');
} elsif ($acceptLang) {
    $lang = $acceptLang;
}

# Print header
print $q->header(-cookie => $cookie);

# set template lang

# check page param, prepare template and present content

my $tmpl = HTML::Template->new(path => [$tmpldir],
                               filename => "$tmpldir/index.tmpl",
                               utf8 => 1,
                               cache => 1);
print $tmpl->output;
