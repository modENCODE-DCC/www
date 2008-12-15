#!/usr/bin/perl -w

use strict;
#use lib "/var/www/cgi-bin/lib";
use lib "./lib";

use CMS::MediaWiki;
use Search::Tools::XML;
use CGI;

my $page=$ENV{'QUERY_STRING'};

my $header = 
"Content-type: text/html\n\n
<html><head>
 <link rel=\"stylesheet\" href=\"http://www.modencode.org/css/modencode.css\">
 <title>".$page."</title>
</head><body>";



my $banner ="
<table width=96%  align=center cellpadding=5 cellspacing=0>
<tr>
<td colspan=4>
<tr >
<td valign=center align=right bgcolor=#5f5050 width=10% >
<font color=white size=2 face=helvetica>
<b>Browse Genomes:</h4>
<td valign=center align=left bgcolor=#5f5050 width=35%>
<a href=\"http://www.modencode.org/WormGenome.shtml\">
<img src=\"http://www.modencode.org/img/wgb_s.png\" alt=\"C.elegans\"/></a>
<a href=\"http://www.modencode.org/FlyGenome.shtml\">
<img src=\"http://www.modencode.org/img/dgb_s.png\" alt=\"D.melanogaster\"/></a>
<td valign=center align=right bgcolor=#ad8d8c width=10%>
<font color=white size=2 face=helvetica>
<b>mine modENCODE:
<td bgcolor=#ad8d8c width=15%>
<a href=\"http://intermine.modencode.org/query/\">
<img src=\"http://www.modencode.org/img/modmine_s.png\" alt=\"query!!\"/></a>
</td></tr>
</table>
<div id=main>
";

my $menu = "
<table width=100%>
<tr valign=top>
<td>
<a href=\"http://www.modencode.org/\">
<img src=\"http://www.modencode.org/img/modENCODE_logo_small.png\" border=0 alt=\"modENCODE home\"/></a>
<div class=Links>
<h4>RESOURCES</h4>
<a class=list id=GenomesLink href=\"http://www.modencode.org/Genomes.shtml\" >Browse Genomes</a><br>
<a class=list id=Mine href=\"http://intermine.modencode.org/query/\">modENCODE-mine</a><br>
<a class=list id=VoteLink href=\"http://www.modencode.org/Vote.shtml\" >TF Priority List</a><br>
<a class=list id=ProtocolsLink href=\"http://www.modencode.org/Protocols.shtml\" >Protocols</a><br>
<a class=list id=ReagentsLink href=\"http://www.modencode.org/Reagents.shtml\" >Reagents</a><br>
<a class=list id=WIKILink
href=\"http://wiki.modencode.org/project/\">WIKI</a>&nbsp;<span
class=PI>[restricted&nbsp;access]&nbsp;</span><br>
<a class=list id=SteinLink href=\"http://www.modencode.org/Stein.shtml\"  >Data Coordinating Center</a><br>
<a class=list id=ContactLink href=\"mailto:help\@modencode.org\" >Contact us</a><br>
<a class=list id=IntroductionLink href=\"http://www.modencode.org/index.shtml\" >Home</a>
</div>
<div class=Links>
<h4><span>PROJECTS</span></h4>
<span class=list><i>C. elegans</i></span><br>
<a class=list id=WaterstonLink href=\"http://www.modencode.org/Waterston.shtml\" >The Transcriptome</a><br>
<a class=list id=LiebLink href=\"http://www.modencode.org/Lieb.shtml\"  >Chromatin Function</a><br>
<a class=list id=HenikoffLink href=\"http://www.modencode.org/Henikoff.shtml\" >Histone Variants</a><br>
<a class=list id=SnyderLink href=\"http://www.modencode.org/Snyder.shtml\" >Regulatory Elements</a><br>
<a class=list id=PianoLink href=\"http://www.modencode.org/Piano.shtml\" >The 3&#39; UTRome</a>
<br>
<span class=list><i>D. melanogaster</i></span><br>
<a class=list id=CelnikerLink href=\"http://www.modencode.org/Celniker.shtml\" >The Transcriptome</a><br>
<a class=list id=WhiteLink href=\"http://www.modencode.org/White.shtml\" >Regulatory Elements</a><br>
<a class=list id=KarpenLink href=\"http://www.modencode.org/Karpen.shtml\" >Chromosomal Proteins</a><br>
<a class=list id=LaiLink href=\"http://www.modencode.org/Lai.shtml\" >Small and microRNAs</a><br>
<a class=list id=MacAlpineLink href=\"http://www.modencode.org/MacAlpine.shtml\" > Origins of Replication</a>
</div>
<div class=Links>
<h4>EXTERNAL&nbsp;LINKS</h4>
<a class=list href=\"http://www.genome.gov/modencode/\"  >modENCODE\@NHGRI</a><br>
<a class=list href=\"http://www.flybase.org\">FlyBase</a><br>
<a class=list href=\"http://www.wormbase.org\">WormBase</a><br>
<a class=list href=\"http://www.flymine.org/\"  >FlyMine</a><br>
</div>
</td>
<td align=left>
"
;



my $footer = "</div></table></body></html>";

my $denial_message = "
<p><p>
<table cellspacing=20, cellpadding=20 align=center><tr><td>
Sorry, the page that you are trying to access ($page) is not available.
</table>
";

my $mw = CMS::MediaWiki->new(
      host  => 'wiki.modencode.org',   # Default: localhost
      path  => 'project' ,             # Can be empty on 3rd-level domain Wikis
      debug => 0                       # Optional. 0=no debug msgs, 1=some msgs, 2=more msgs
);


if ($mw->login(user => 'Publisher', pass => 'newyork')) {
  die "Could not login\n";
}

my $publicPage = $mw->getHTML(title => "Public_index");

my $bool = "private";

#    if ($publicPage =~ m/.*&lt;li&gt;\s*$page.*/) {
    if ($publicPage =~ m/.*<li>\s*$page.*/) {
	$bool = "public";
    }

#my $lines_ref = $mw->getPage(title => $page);

print $header;
print $menu;
print $banner;


if ($bool eq "public") { 

    my $content = $mw->getHTML(title => $page);

    my $purified = "<h2>".&parseHTML($content);

#    print Search::Tools::XML->unescape($content), "\n";
    print Search::Tools::XML->unescape($purified), "\n";


} else {   
    print $denial_message;
}

print $footer;


sub parseHTML {
    # returns page source
    my $before = $_[0];

#rm edit boxes
    $before =~ s/\[.*edit.*\]//g;

#rm form buttons
    $before =~ s/<input type=\"submit\".*>//g;

#rm help links
    $before =~ s/<.*alt=\"?\".*>//g;

#rm reference to wiki
    $before =~ s/<br\/>Please use this page\'s permanent link when referencing .* -->//sg;

#rm footer
    $before =~ s/<div class=\"printfooter.*>//sg;

#to cut all before the first header
    $before =~ m/<h2>/;

     return $'; 

}

