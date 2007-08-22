#!/usr/bin/perl -w
# Sheldon McKay mckays@cshl.edu
# This script handles AJAX requests for page content

use strict;
use CGI qw/header param/;
use CGI::Carp 'fatalsToBrowser';
use XML::Simple ':strict';

use constant XML   => '/contents/';
use constant DEBUG => 0;

use vars qw/$help_item $help_page $help $contents/;

my $xml = XML::Simple->new;

$help_item = param('section'); # must be unique to a file
$help_page = param('url') || 'index'; # each page/script gets its own xml file

warn "Help item is $help_item\n" if DEBUG;

exit unless $help_item && $help_page;

# convert /path/to/script.pl to path-to-script
warn "Help url before: $help_page\n" if DEBUG;
$help_page =~ s|/|-|g;
$help_page =~ s/(\.\S+)?$/\.xml/;
$help_page = $ENV{DOCUMENT_ROOT} . XML . $help_page;
warn "Help url after: $help_page\n" if DEBUG;

my $help = $xml->XMLin($help_page, ForceArray => 1, KeyAttr => 'section_id');
if ($help) {
  $contents = $help->{section}->{$help_item}->{content} || $help_item;
}
else {
  $contents = $help_item;
}

warn "help text: $contents\n" if DEBUG;

# trailing '>'
$contents =~ s/^\s*\>\s*$//gm;

print header('text/html'), $contents
