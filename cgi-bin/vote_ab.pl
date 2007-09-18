#!/usr/bin/perl -w
use strict;
use CGI qw/:standard start_table end_table/;

# Make HTML human readable
use CGI::Pretty;

# Dump fatal errors to the browser
use CGI::Carp 'fatalsToBrowser';

# For locking files while the script is executing
use Fcntl ':flock';

# For generating unique IDs;
use Digest::MD5 'md5_hex';

# Edit as required
use constant AB_VOTES => "/home/zhengzha/public_html/www/cgi-bin/vote/abvotes_test.txt";

my $style = '<style>TD,TH {font-size:90%;}</style>';

print header;

print start_html( 
    -title => 'Transcription Factor Priority Voting Page',
    -head => $style,
    );
print start_form(-name => 'f1');

my $vote             = param('vote');
my $ab_name          = param('ab_name') || '';
my $ab_status        = param('ab_status') || '';
my $expattn_cellspec = param('cell_specificity') || '';
my $expattn_timespec = param('time_specificity') || '';
my $boundsites       = param('boundsites') || '';
my $phenotype        = param('phenotype') || '';
my $create           = param('create');
my $new              = 1
  if $ab_name
  || $ab_status
  || $expattn_cellspec
  || $expattn_timespec
  || $boundsites
  || $phenotype;

# Make sure we have at least an antibody name
if ( $new && !$ab_name ) {
    print h1(
        font(
            { color => 'red' },
            'An antibody name is required'
        )
    );
    $new    = '';
    $create = 1;
}

my @abvinfo = (
    $ab_name, $ab_status, $expattn_cellspec,
    $expattn_timespec, $boundsites, $phenotype, 1
    );
for (@abvinfo) {
    s/\t/ /g;
}

# If a new entry is entered, save it now
# but watch out for page re-loads
if ($new) {
    my $line = join( "\t", @abvinfo );
    my $file = AB_VOTES;
    unless (`grep '$line' $file`) {
	open OUT, ">>$file" || die $!;
	flock(OUT, LOCK_EX); # exclusive file lock
	print OUT "$line\n";
	close OUT;
    }
}

# Get the existing data
open IN, AB_VOTES;
flock(IN, LOCK_EX); # exclusive file lock

my @vote_data;

while ( my $line = <IN> ) {
    chomp $line;
    $line =~ /\S/ || next;
    my @columns = split "\t", $line;
    @columns == 7 || die "problem with data format for entry:\n$line\n";
    my $vote_id = md5_hex(@columns[0..5]);
    $columns[6]++ if $vote eq $vote_id;
    push @columns,
    qq(<input type="radio" name="vote" value="$vote_id" onclick="document.f1.submit()">);
    push @vote_data, \@columns;
}
close IN;

my @fields = (
    textfield( -name => 'ab_name', -size => 8,  -value => '' ),
    textfield( -name => 'ab_status', -size => 10,  -value => '' ),
    textfield( -name => 'cell_specificity', -size => 15,  -value => '' ),
    textfield( -name => 'time_specificity', -size => 15,  -value => '' ),
    textfield( -name => 'boundsites', -size => 15,  -value => '' ),
    textfield( -name => 'phenotype', -size => 15,  -value => '' ),
    textfield( -name => 'votes', -value => 1, -disabled => 1, -size => 2 ),
    );

my @abvheader = (
    "Antibody<br>Name",
    "already made?",     
    "tissue/cell<br>specific?",
    "time/stage<br>of expression?",
    "known<br>bound sites",
    "known<br>phenotype", 
    "Vote Tally",
    "Vote"
    );

my $new_entry = $create
  ? Tr( td( \@fields ) )
  : Tr(
    td(
        { -colspan => 8 },
        checkbox(
            -name    => 'create',
            -label   => '',
            -onclick => "document.f1.submit()"
          )
          . 'Check to create a new Entry '
    )
    );

my $row_color = 'gainsboro';
print start_table( { -border => 1, -width => '100%', -cellpadding => 2 } );
print Tr( {-bgcolor => 'lightblue'}, th( \@abvheader ) );
for my $row (@vote_data) {
    $row_color = $row_color eq 'ivory' ? 'gainsboro' : 'ivory';
    print Tr({-bgcolor=>$row_color}, td($row) )
}  
print $new_entry;
print end_table;

print br, submit( -name => 'Update' ), end_form, end_html;

# Store Final result here
open OUT, ">" . AB_VOTES || die $!;
flock(OUT, LOCK_EX);
for (@vote_data) {
    print OUT join( "\t", @{$_}[ 0 .. 6 ] ), "\n";
}
close OUT;

exit 0;
