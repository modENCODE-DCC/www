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
use constant AB_VOTES => "$ENV{DOCUMENT_ROOT}/votes/abvotes.txt";
-e AB_VOTES or die "I could not find ".AB_VOTES." $!\n";

my $style = '<style>TD,TH {font-size:90%;}</style>';

print header;

# voting override is only good for one vote.                                                                                                                                  
my @onload = ();
if (param('override')) {
    my $url = url;
    @onload = (-onload => "window.location = '$url'");
}

print start_html( 
    -title => 'Transcription Factor Priority Voting Page',
    -head => $style,
    @onload
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

my $voter = remote_host();

# If a new entry is entered, save it now
# but watch out for page re-loads
if ($new) {
    my $line = join( "\t", @abvinfo, $voter );
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
    #@columns == 8 || die "problem with data format for entry:\n$line\n";
    my $voters = pop @columns if @columns == 8;
    my @voters = split ',', $voters;
    my $vote_id = md5_hex(@columns[0..5]);
    
    # increment the vote and keep track of who voted
    if ($vote eq $vote_id) {
        my $override = param('override');
	if (!$override && $voter && grep /$voter/, @voters) {
	    print h4(font( {-color => 'red'},
			   "Sorry, someone at $voter has already voted for $columns[0]&nbsp;&nbsp;".
			   a({-href => url()."?vote=$vote;override=1"},'[Vote anyway]').
			   '&nbsp;'.
			   a({-href => url()}, '[Cancel]')));
	}
        else {
            $columns[6]++;
            $voters .= $voters ? ",$voter" : $voter;
        }
    }
    push @columns,
    qq(<input type="radio" name="vote" value="$vote_id" onclick="document.f1.submit()">);
    push @columns, $voters;
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
    );

my @abvheader = (
    "Antibody<br>Name",
    "Already made?",     
    "Tissue/cell<br>specific expression?",
    "Time/stage<br>of expression?",
    "Known binding<br>sites on TF",
    "Known associated<br>phenotype", 
    "Vote<br>Tally",
    "Vote"
    );

my $submit = td( { -colspan => 2, -border => 0 }, submit( -name => 'Update' ));

my $new_entry = $create
  ? Tr( td( \@fields ).$submit )
  : Tr(
    td(
        { -colspan => 6, -border => 0},
        checkbox(
            -name    => 'create',
            -label   => '',
            -onclick => "document.f1.submit()"
          )
          . 'Check to create a new Entry '
    ) . $submit
    );

my $row_color = 'gainsboro';
print start_table( { -border => 1, -width => '100%', -cellpadding => 2 } );
print Tr( {-bgcolor => 'lightblue'}, th( \@abvheader ) );
for my $row (@vote_data) {
    $row_color = $row_color eq 'ivory' ? 'gainsboro' : 'ivory';
    print Tr({-bgcolor=>$row_color}, td([@{$row}[0..7]]) )
}  
print $new_entry;
print end_table, end_form, end_html;;

# Store Final result here
open OUT, ">" . AB_VOTES || die $!;
flock(OUT, LOCK_EX);
for (@vote_data) {
    print OUT join( "\t", @{$_}[ 0 .. 6, 8 ] ), "\n";
}
close OUT;

exit 0;
