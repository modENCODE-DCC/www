#!/usr/bin/perl -w
use strict;
use CGI qw/:standard start_table end_table/;
use Data::Dumper;

# Make HTML human readable
use CGI::Pretty;

# Dump fatal errors to the browser
use CGI::Carp 'fatalsToBrowser';

# For locking files while the script is executing
use Fcntl ':flock';

# For generating unique IDs;
use Digest::MD5 'md5_hex';

# Edit if required
use constant TF_VOTES => "$ENV{DOCUMENT_ROOT}/votes/tfvotes.txt";
-e TF_VOTES or die "I could not find ".TF_VOTES." $!\n"; 

my $style = "<style>TD,TH {font-size:90%;}</style>\n";

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

my $vote            = param('vote') || '';
my $edit            = param('edit') || '';
my $usr_initial     = param('usr_initial') || '';
my $email           = param('email') || '';
my $gene_name       = param('gene_name') || '';
my $dbs_id          = param('database_id') || '';
my $tag             = param('tag') || '';
my $tag_loc         = param('tag_loc') || '?';
my $sty_pp          = param('sty_pp') || '';
my $ab_avail        = param('ab_avail') || '';
my $mut_avail       = param('mut_avail') || '';
my $construct_avail = param('construct_avail') || '';
my $create          = param('create') || '';
my $replace         = param('replace') || '';
my $new             = 1
  if $usr_initial
  || $email
  || $gene_name
  || $dbs_id
  || $tag
  || $sty_pp
  || $ab_avail
  || $mut_avail;
undef $new if $replace;

# Make sure we have at least a gene data or database ID
if ( $new && !( $gene_name || $dbs_id ) ) {
    print h1(
        font(
            { color => 'red' },
            'Either a gene name, or a Worm/FlyBase ID is required'
        )
    );
    $new    = '';
    $create = 1;
}

my @tfvinfo = (
    $usr_initial, $email, $gene_name, $dbs_id, $tag,
    $tag_loc, $sty_pp, $ab_avail, $mut_avail,
    $construct_avail, 1
);
for (@tfvinfo) {
    $_ or next;
    s/\t/ /g;
}

my $voter = remote_host();

# If a new entry is entered, save it now
# but watch out for page re-loads
if ($new) {
    my $line = join( "\t", @tfvinfo, $voter );
    my $file = TF_VOTES;
    unless (`grep '$line' $file`) {
      open OUT, ">>$file" || die $!;
      flock(OUT, LOCK_EX); # exclusive file lock
      print OUT "$line\n";
      close OUT;
    }
}

# Get the existing data
open IN, TF_VOTES;
flock(IN, LOCK_EX);

my @vote_data;

while ( my $line = <IN> ) {
    chomp $line;
    $line =~ /\S/ || next;
    my @columns = split "\t", $line;

    #@columns == 13 || die "problem with data format for entry:\n$line\n";

    # The md5_hex string is a key for the first 10 data fields
    my $vote_id = md5_hex(@columns[0..9]);

    my $voters = $columns[11] || '';
    my $editors = $columns[12] || '';
    @columns = @columns[0..10];
    my @voters = split ',', $voters;
    
    my $disabled = '';

    my %voters;
    for (@voters) {
        $voters{$_}++;
    }

    # increment the vote and keep track of who voted
    if ($vote eq $vote_id) {
        my $override = param('override'); # WTF? proxy?
        if (!$override && $voter && grep /$voter/, @voters) {
            my $msg =  h4(span( {style=>'color:red;font-size:100%'},
				"Someone at your IP address ($voter) has already voted for ". 
				($columns[2] || $columns[3])), '&nbsp;&nbsp;' .  
			  a({-href => url()."?vote=$vote;override=1"},'[Vote anyway]') .
			  '&nbsp;' .
			  a({-href => url()}, '[Cancel]'));
	    push @vote_data, $msg;
        }
        else {
    	    $voters{$voter}++;
            $voters .= $voters ? ",$voter" : $voter;
        }
    }
    # provide forms elements if an edit is requested for this row
    elsif ($edit eq $vote_id) {
	@columns[0..9] = fields(@columns);
	$disabled = "disabled=1";
        print hidden(-name => 'replace', -value => $vote_id);
    }
    # If the data have changed, log the IP of the editor
    # and learn the changes
    elsif ($replace eq $vote_id) {
	@columns[0..9] = @tfvinfo;
        my $new_vote_id = md5_hex(@columns[0..9]);
	unless ($new_vote_id eq $vote_id) {
	    $editors .= $editors ? ",$voter" : $voter;
	    $vote_id = $new_vote_id;
	}
	else {
	    $replace = '';
	}
    }

    $columns[10] = tally(%voters);    

    push @columns, qq(<input type="radio" name="vote" value="$vote_id" onclick="document.f1.submit()" $disabled>);
    push @columns, qq(<input type="radio" name="edit" value="$vote_id" onclick="document.f1.submit()" $disabled>);
    push @columns, ($voters,$editors);
    push @vote_data, \@columns;
}
close IN;

my @fields = fields();

my $new_vote = hidden( -name => 'votes', -value => 1, -disabled => 1, -size => 2 );

my @tfvheader = (
    "Your<br>Name", "email",   "Gene<br>Name",
    "Worm/<br>FlyBase ID",     "Preferred<br>Tag ",
    "Preferred<br>Terminus",   "Study<br>Purpose",
    "Antibodies<br>available", "Mutants<br>available",
    "Constructs<br>available", "Vote<br>Tally",
    "Vote", "Edit"
);


my $submit = td( { -colspan => 3 }, submit( -name => 'Update' ));

my $new_entry = $create
  ? Tr( td( \@fields ). $submit )
  : Tr(
    td(
        { -colspan => 10 },
        checkbox(
            -name    => 'create',
            -label   => '',
            -onclick => "document.f1.submit()"
          )
          . 'Check to create a new Entry '
    ) . $submit
  );

my $row_color = 'gainsboro';

print start_table( { -border => 1, -width => '100%', -cellpadding => 2} );
print Tr( {-bgcolor => 'lightblue'}, th( \@tfvheader ) );

for my $row (@vote_data) {
    unless (ref $row) {
	print Tr({-bgcolor=>$row_color}, td({-colspan=>13, -align=>'right'},$row));
	next;
    }
    $row_color = $row_color eq 'ivory' ? 'gainsboro' : 'ivory';
    print Tr({-bgcolor=>$row_color}, td([@{$row}[0..12]]) )
}  

print $new_entry, end_table, end_form;

print end_html and exit 0 if $edit || !($vote || $replace);

# Store Final result here
open OUT, ">" . TF_VOTES || die $!;
flock(OUT, LOCK_EX);
for (@vote_data) {
    ref $_ or next;
    print OUT join( "\t", map {$_||''} @{$_}[ 0 .. 10, 13, 14]), "\n";
}
close OUT;

print end_html;

exit 0;


sub fields {
    return (
	textfield( -name => 'usr_initial',     -size => 10,   -value => shift || '' ),
	textfield( -name => 'email',           -size => 18,   -value => shift || '' ),
	textfield( -name => 'gene_name',       -size => 8,   -value => shift || '' ),
	textfield( -name => 'database_id',     -size => 15,  -value => shift || '' ),
	textfield( -name => 'tag',             -size => 5,   -value => shift || '' ),
	popup_menu( -name => 'tag_loc',        -values => ['','C','N'], -default => shift),
	textfield( -name => 'sty_pp',          -size => 18,  -value => shift || '' ),
	textfield( -name => 'ab_avail',        -size => 8,   -value => shift || '' ),
	textfield( -name => 'mut_avail',       -size => 8,   -value => shift || '' ),
	textfield( -name => 'construct_avail', -size => 8,   -value => shift || '' )
	);
}

sub tally {
    my %voters = @_;
    my $count;
    # enforcement disabled for now
    for my $v (keys %voters) {
	$count += $voters{$v};
#	if ($v eq '192.168.128.60') { # temp                                                                                                                          
#	    $count += $voters{$v};
#	}
#	else {
#	    $count += $voters{$v} > 2 ? 2 : $voters{$v};
#	}
    }
    $count;
}
