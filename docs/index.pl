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
if ($q->cookie('lang') ~~ @langs) {
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

# Fill in template language parameters
my @langs_loop;
foreach (@langs) {
    my $lang_data = { LANG => $_, SELECTED => ($_ eq $lang) };
    push @langs_loop, $lang_data;
}
$tmpl->param(LANG => $lang, LANGS_LOOP => \@langs_loop);

# Print filled-in template
print $tmpl->output;
