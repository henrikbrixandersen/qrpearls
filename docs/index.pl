#!/usr/bin/perl -w

use strict;

use CGI qw/-utf8/;
use I18N::AcceptLanguage;
use HTML::Template;
use HTML::Template::Expr;
use Locale::TextDomain;
use Imager::QRCode;
use SVG qw/-nocredits => 1/;

# Directories
my $tmpldir = "$ENV{BASE_DIRECTORY}/tmpl";

# Pages
my $pages = {
    home => {
        path => '/',
        name => __('Home'),
        icon => 'home',
    },
    about => {
        name => __('About'),
        icon => 'book',
    }
};
my @pageorder = qw/home about/;
my $page = $pageorder[0];

# Languages
my $langs = {
    en => 'English',
    da => 'Dansk',
};
my $lang = 'en';

# Initialize CGI and catch errors
my $q = CGI->new;
$q->charset('UTF-8');
my $error = $q->cgi_error;
if ($error) {
    print $q->header(-status => $error);
    exit 0;
}

# Determine language
if ($q->cookie('lang') ~~ $langs) {
    $lang = $q->cookie('lang');
} else {
    my @available = keys $langs;
    my $accept = I18N::AcceptLanguage->new(defaultLanguage => $lang);
    my $acceptLang = $accept->accepts($ENV{HTTP_ACCEPT_LANGUAGE}, \@available);
    $lang = $acceptLang if ($acceptLang);
}

# Print header
print $q->header;

# TODO: set template lang

# Determine page
if ($q->param('page') ~~ $pages) {
    $page = $q->param('page');
}

# Load template
my $tmpl = HTML::Template->new(path => [$tmpldir],
                               filename => "$page.tmpl",
                               utf8 => 1,
                               cache => 1);

# Generate template language parameters
my @langs_loop;
foreach (sort keys $langs) {
    my $lang_data = {
        LANG => $_,
        NAME => $langs->{$_},
        SELECTED => ($_ eq $lang)
    };
    push @langs_loop, $lang_data;
}

# Generate template page parameters
my @pages_loop;
foreach (@pageorder) {
    my $page_data = {
        PATH => $pages->{$_}->{path} || "/$_/",
        ICON => $pages->{$_}->{icon},
        NAME => $pages->{$_}->{name},
        SELECTED => ($_ eq $page)
    };
    push @pages_loop, $page_data;
}

# Fill in template
$tmpl->param(LANG => $lang,
             LANGS_LOOP => \@langs_loop,
             PAGES_LOOP => \@pages_loop);
print $tmpl->output;
