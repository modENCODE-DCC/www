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
use constant TF_VOTES => "/FRONT-END/www/html/votes/tfvotes_test.txt";

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

my $vote            = param('vote');
my $usr_initial     = param('usr_initial') || '';
my $gene_name       = param('gene_name') || '';
my $dbs_id          = param('database_id') || '';
my $tag             = param('tag') || '';
my $tag_loc         = param('tag_loc') || '?';
my $sty_pp          = param('sty_pp') || '';
my $ab_avail        = param('ab_avail') || '';
my $mut_avail       = param('mut_avail') || '';
my $construct_avail = param('construct_avail') || '';
my $create          = param('create');
my $new             = 1
  if $usr_initial
  || $gene_name
  || $dbs_id
  || $tag
  || $sty_pp
  || $ab_avail
  || $mut_avail;

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
    $usr_initial, $gene_name, $dbs_id, $tag,
    $tag_loc, $sty_pp, $ab_avail, $mut_avail,
    $construct_avail, 1
);
for (@tfvinfo) {
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
    #@columns == 11 || die "problem with data format for entry:\n$line\n";
    my $vote_id = md5_hex(@columns[0..8]);
    my $voters = pop @columns || '' if @columns == 11;
    my @voters = split ',', $voters;

    # increment the vote and keep track of who voted
    if ($vote eq $vote_id) {
        my $override = param('override');
        if (!$override && $voter && grep /$voter/, @voters) {
            print h4(font( {-color => 'red'},
                     "Sorry, someone at $voter has already voted for ". 
			   ($columns[1] || $columns[2])), '&nbsp;&nbsp;',  
                  a({-href => url()."?vote=$vote;override=1"},'[Vote anyway]'),
		  '&nbsp;',
		  a({-href => url()}, '[Cancel]'));
        }
        else {
            $columns[9]++;
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
    textfield( -name => 'usr_initial',     -size => 4,   -value => '' ),
    textfield( -name => 'gene_name',       -size => 8,   -value => '' ),
    textfield( -name => 'database_id',     -size => 10,  -value => '' ),
    textfield( -name => 'tag',             -size => 5,   -value => '' ),
    popup_menu( -name => 'tag_loc',        -values => ['','C','N']),
    textfield( -name => 'sty_pp',          -size => 18,  -value => '' ),
    textfield( -name => 'ab_avail',        -size => 8,   -value => '' ),
    textfield( -name => 'mut_avail',       -size => 8,   -value => '' ),
    textfield( -name => 'construct_avail', -size => 8,   -value => '' )
);

my $new_vote = hidden( -name => 'votes', -value => 1, -disabled => 1, -size => 2 );

my @tfvheader = (
    "Initials",                "Gene<br>Name",
    "Worm/<br>FlyBase ID",     "Preferred<br>Tag ",
    "Preferred<br>Terminus",   "Study<br>Purpose",
    "Antibodies<br>available", "Mutants<br>available",
    "Constructs<br>available", "Vote<br>Tally",
    "Vote"
);


my $submit = td( { -colspan => 2 }, submit( -name => 'Update' ));

my $new_entry = $create
  ? Tr( td( \@fields ).$submit )
  : Tr(
    td(
        { -colspan => 9 },
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
print Tr( {-bgcolor => 'lightblue'}, th( \@tfvheader ) );
for my $row (@vote_data) {
  $row_color = $row_color eq 'ivory' ? 'gainsboro' : 'ivory';
  print Tr({-bgcolor=>$row_color}, td([@{$row}[0..10]]) )
}  
print $new_entry, end_table, end_form;;

# Store Final result here
open OUT, ">" . TF_VOTES || die $!;
flock(OUT, LOCK_EX);
for (@vote_data) {
    print OUT join( "\t", @{$_}[ 0 .. 9, 11]), "\n";
}
close OUT;

print end_html;

exit 0;
