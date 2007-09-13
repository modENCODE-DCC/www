#!/usr/bin/perl -w
use strict; 
use CGI qw/:standard start_table end_table/;
# Make HTML human readable
use CGI::Pretty;
# Dump fatal errors to the browser
use CGI::Carp 'fatalsToBrowser';


# Edit as required
use constant TF_VOTES => "/FRONT-END/www/cgi-bin/tfvotes_test.txt";
#use constant TF_VOTES => "/FRONT-END/www/cgi-bin/tfvotes.txt";

print header;
print start_html(-title=>'Transcription Factor Priority Voting Page',
		 -style=>{'src'=>'/css/modencode.css'}, 
		 -bgcolor => 'white');

print start_form(-name => 'f1');

my $vote            = param('vote'); 
my $usr_initial     = param('usr_initial') || '';
my $gene_name       = param('gene_name')   || '';
my $dbs_id          = param('database_id') || '';
my $tag             = param('tag')         || '';
my $tag_loc         = param('tag_loc')     || '?';
my $sty_pp          = param('sty_pp')      || '';
my $ab_avail        = param('ab_avail')    || '';
my $mut_avail       = param('mut_avail')   || '';
my $construct_avail = param('construct_avail')  || '';
my $new = 1 if $usr_initial || $gene_name || $dbs_id || $tag || $sty_pp || $ab_avail || $mut_avail;
my $create = param('create');

# Make sure we have at least a gene data or database ID
if ($new && !($gene_name||$dbs_id)) {
    print h1(font({color => 'red'},'Either a gene name or database ID is required'));
    $new = '';
    $create = 1;
}

my @tfvinfo = ($usr_initial, $gene_name, $dbs_id, $tag_loc, $tag, $sty_pp, $ab_avail, $mut_avail, $construct_avail,1);
for (@tfvinfo) {
    s/\t/ /g;
}

# If a new entry is requested, save it now
if ($new) {
    print "saving...",br;
    open OUT, ">>".TF_VOTES || die $!;
    print OUT join("\t", @tfvinfo), "\n";
    close OUT;
}

# Get the existing data
open IN, TF_VOTES;
my (@vote_data,$vote_idx);

while (my $line = <IN>) {
    chomp $line;
    $line =~ /\S/ || next;
    my @columns = split "\t", $line;
    @columns == 10 || die "problem with data format for entry:\n$line\n";
    $vote_idx++;
    @columns[9]++ if $vote == $vote_idx; 
    push @columns, qq(<input type="radio" name="vote" value="$vote_idx" onclick="document.f1.submit()">);
    push @vote_data, \@columns;
}
close IN;


my @fields = (
    textfield(-name=>'usr_initial',     -size=>4, -value=>''),
    textfield(-name=>'gene_name',       -size=>8, -value=>''),
    textfield(-name=>'database_id',     -size=>8, -value=>''),
    textfield(-name=>'tag_loc',         -size=>3, -value=>''),
    textfield(-name=>'tag',             -size=>5, -value=>''),
    textfield(-name=>'sty_pp',          -size=>15, -value=>''),
    textfield(-name=>'ab_avail',        -size=>8, -value=>''),
    textfield(-name=>'mut_avail',       -size=>8, -value=>''),
    textfield(-name=>'construct_avail', -size=>8, -value=>''),
    textfield(-name=>'votes', -value=> 1, -disabled=>1, -size=>2),
    );


my @tfvheader = ("Initials", "Gene<br>Name", "Worm/<br>FlyBase ID", "Preferred<br>Tag ", "Preferred<br>Terminus", "Study<br>Purpose", 
		 "Antibodies<br>available", "Mutants<br>available", "Constructs<br>available", "Vote<br>Tally","Vote");


my $new_entry = $create ? Tr(td(\@fields)) 
              : Tr(td({-colspan=>11}, checkbox(-name=>'create', -label=>'',-onclick=>"document.f1.submit()"). 'Check to create a new Entry '));

print start_table({-border => 1, -width => '100%', -cellpadding => 2});
print Tr(th(\@tfvheader));
print map {Tr(td($_))} @vote_data;
print $new_entry;
print end_table;
    
print br,submit(-name => 'Update'), end_form;

# Store Final result here
open OUT, ">".TF_VOTES || die $!;
for (@vote_data) {
    print OUT join("\t", @{$_}[0..9]), "\n";
}
close OUT;
