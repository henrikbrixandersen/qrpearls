#!/usr/bin/perl -w

use strict;

use CGI qw/-utf8/;
use I18N::AcceptLanguage;
use HTML::Template::Expr;
use Locale::Messages qw/bindtextdomain/;
use Locale::TextDomain qw/qrpearls/;
use POSIX qw/setlocale LC_MESSAGES/;

BEGIN {
    # Select the pure-perl implementation, since xs version does not
    # work with mod_perl2
    Locale::Messages->select_package('gettext_pp');
};

# Directories
my $tmpldir = "$ENV{BASE_DIRECTORY}/tmpl";
my $localedir = "$ENV{BASE_DIRECTORY}/locale";

# Pages
my $pages = {
    home => {
        path => '/',
        name => N__"Home",
        icon => 'home',
    },
    about => {
        name => N__"About",
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
$ENV{'LANGUAGE'} = $lang;
bindtextdomain('qrpearls', $localedir);
setlocale(LC_MESSAGES, '');

# Print header
print $q->header(-expires => 0);

# Determine page
if ($q->param('page') ~~ $pages) {
    $page = $q->param('page');
}

# Load template
my $tmpl = HTML::Template::Expr->new(path => [$tmpldir],
                                     filename => "$page.tmpl",
                                     utf8 => 1,
                                     cache => 1,
                                     filter => sub {
                                         my $text = shift;
                                         $$text =~ s/_\("(.*?)"\)/<TMPL_VAR EXPR="translate('$1')">/g;
                                     },
                                     functions => {
                                         translate => sub { my $t = shift; return __($t); },
                                     }
);

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
        NAME => __($pages->{$_}->{name}),
        SELECTED => ($_ eq $page)
    };
    push @pages_loop, $page_data;
}

# Fill in template
$tmpl->param(LANG => $lang,
             LANGS_LOOP => \@langs_loop,
             PAGES_LOOP => \@pages_loop);
print $tmpl->output;
