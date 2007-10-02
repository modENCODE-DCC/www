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

my $vote         = param('vote') || '';
my $edit         = param('edit') || '';
my $target_name  = param('target_name');
my $ab_name      = param('ab_name') || '';
my $ab_status    = param('ab_status') || '';
my $clone        = param('clone') || '';
my $species      = param('species') || '';
my $description  = param('description') || '';
my $create       = param('create') || '';
my $replace      = param('replace') || '';
my $new          = 1 if ($target_name || $ab_name) && !$replace;

# Make sure we have at least an antibody or target name
if ( $new && ! ($target_name || $ab_name) ) {
    print h1(
        font(
            { color => 'red' },
            'Either a target name or an antibody name is required'
        )
    );
    $new    = '';
    $create = 1;
}

my @abvinfo = (
    $target_name, $ab_name, $ab_status, $clone, 
    $species, $description, 1
    );
for (@abvinfo) {
    $_ or next;
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
    #@columns == 9 || die "problem with data format for entry:\n$line\n";
    my $voters = $columns[7] || '';
    my $editors = $columns[8] || '';
    @columns = @columns[0..6];
    my @voters = split ',', $voters if $voters;
    my $vote_id = md5_hex(@columns[0..5]);
    my $disabled = '';

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
    # convert the values to form elements if an edit is requested
    # for this line
    elsif ($edit eq $vote_id) {
        @columns[0..9] = fields(@columns);
        $disabled = "disabled=1";
        print hidden(-name => 'replace', -value => $vote_id);
    }
    # If the data have changed, log the IP of the editor
    # and learn the changes
    elsif ($replace eq $vote_id) {
        @columns[0..6] = @abvinfo;
        my $new_vote_id = md5_hex(@columns[0..5]);
        unless ($new_vote_id eq $vote_id) {
            $editors .= $editors ? ",$voter" : $voter;
            $vote_id = $new_vote_id;
        }
    }

    push @columns, qq(<input type="radio" name="vote" value="$vote_id" onclick="document.f1.submit()" $disabled>);
    push @columns, qq(<input type="radio" name="edit" value="$vote_id" onclick="document.f1.submit()" $disabled>);
    push @columns, $voters;
    push @vote_data, \@columns;
}
close IN;

my @fields = fields();

my @abvheader = (
    "Target<br>Name",
    "Antibody<br>Name",
    "Already made?",     
    "Type",
    "Made in",
    "Description",
    "Vote<br>Tally",
    "Vote",
    "Edit"
    );

my $submit = td( { -colspan => 3 }, submit( -name => 'Update' ));

my $new_entry = $create
  ? Tr( td( \@fields ).$submit )
  : Tr(
    td(
        { -colspan => 6 },
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
    print Tr({-bgcolor=>$row_color}, td([@{$row}[0..8]]) );
}  
print $new_entry, end_table, end_form;

exit 0 if $edit;

# Store Final result here
open OUT, ">" . AB_VOTES || die $!;
flock(OUT, LOCK_EX);
for (@vote_data) {
    print OUT join( "\t", map {$_||''} @{$_}[ 0 .. 6, 9, 10] ), "\n";
}
close OUT;

print end_html;

exit 0;

sub fields {
    return (
        textfield( -name => 'target_name', -size => 15, -value => shift || ''),
	textfield( -name => 'ab_name',     -size => 15,  -value => shift || '' ),
	textfield( -name => 'ab_status',   -size => 15,  -value => shift || '' ),
	popup_menu( -name => 'clone',      -value => ['', 'monoclonal', 'polyclonal'], -default => shift || ''),
	textfield( -name => 'species',     -size => 15,  -value => shift || '' ),
	textarea( -name => 'description',  -rows => 4,   -column => 3,  -value => shift || '' ),
	);
}
