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
    $species, $description
    );
for (@abvinfo) {
    $_ or next;
    s/\t/ /g;
}

my $editor = remote_host();

# If a new entry is entered, save it now
# but watch out for page re-loads
if ($new) {
    my $line = join( "\t", @abvinfo, $editor );
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
    my $editors = $columns[6];
    @columns = @columns[0..5];
    my @editors = split ',', $editors if $editors;
    my $edit_id = md5_hex(@columns[0..5]);
    my $disabled = '';

    # convert the values to form elements if an edit is requested
    # for this line
    if ($edit eq $edit_id) {
        @columns[0..5] = fields(@columns);
        $disabled = "disabled=1";
        print hidden(-name => 'replace', -value => $edit_id);
    }
    # If the data have changed, log the IP of the editor
    # and learn the changes
    elsif ($replace eq $edit_id) {
        @columns[0..5] = @abvinfo;
        my $new_edit_id = md5_hex(@columns[0..5]);
        unless ($new_edit_id eq $edit_id) {
            $editors .= $editors ? ",$editor" : $editor;
            $edit_id = $new_edit_id;
        }
	else {$edit = 1}
    }

    push @columns, qq(<input type="radio" name="edit" value="$edit_id" onclick="document.f1.submit()" $disabled>);
    push @columns, $editors;
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
    "Edit"
    );

my $submit = td( { -colspan => 2 }, submit( -name => 'Update' ));

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
    print Tr({-bgcolor=>$row_color}, td([@{$row}[0..5]]).td({-width => '30px'},$row->[6]) );
}  
print $new_entry, end_table, end_form;

exit 0 unless $replace;

# Store Final result here
open OUT, ">" . AB_VOTES || die $!;
flock(OUT, LOCK_EX);
for (@vote_data) {
    print OUT join( "\t", map {$_||''} @{$_}[ 0 .. 5, 7] ), "\n";
}
close OUT;

print end_html;

exit 0;

sub fields {
    return (
        textfield(  -name => 'target_name', -size => 15, -value => (shift || '')),
	textfield(  -name => 'ab_name',     -size => 15,  -value => (shift || '')),
	textfield(  -name => 'ab_status',   -size => 15,  -value => (shift || '')),
	popup_menu( -name => 'clone',       -value => ['', 'monoclonal', 'polyclonal'], -default => (shift || '')),
	textfield(  -name => 'species',     -size => 15,  -value => (shift || '') ),
	textfield(  -name => 'description', -size => 35,  -value => (shift || '') ),
	);
}
