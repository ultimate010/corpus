#!/usr/bin/perl
use LWP::UserAgent;
use HTML::TreeBuilder::XPath;
use Encode;
use strict;

our $g_debug = "true";
our $g_page = LWP::UserAgent -> new;
our $g_pageEncode = "gbk";
our $g_teamUrlPattern = "//body/center/div/div/div/div/table/tr/td/a";
our @g_teamOut = ();


main();




#	function define

sub main{
  init(); #初始化
  $g_debug = 'false';
  my @arr = getTeamUrls("http://nba.sports.sina.com.cn/teams.php?dpc=1");
  $g_debug = 'false';
  parseTeamUrls(@arr);
  foreach (@g_teamOut){
	print $_;
  }
}
sub test{
  print getPage("http://www.baidu.com","utf8");
}

sub parseTeamUrls{
  my(@arr) = @_;
  foreach my $url(@arr){
	#print "New $url\n";
	my $page = getPage($url,$g_pageEncode);
	#print $page;
	my $m_xpath = new HTML::TreeBuilder::XPath;
	$m_xpath->parse($page);
	$m_xpath->eof();
	my $teamName = "NULL"; #队名中英
	my $items = $m_xpath->findnodes('//body/center/div/div/div/div[@id="table730top"]/div/p');
	for my $item ($items->get_nodelist()){
	  my $value = $item->string_value();
	  if($g_debug eq "true"){
		print "First:\t$value\t$url\nEnter";
		<stdin>;
	  }
	  my @tmp = split(/\|/,$value);
	  $teamName = $tmp[0];
	  last;
	}
	my $items = $m_xpath->findnodes('//body/center/div/div/div/div[@id="table730middle"][position()=1]/div/table/tr/td');
	my @res = ();
	for my $item ($items->get_nodelist()){
	  my $value = $item->string_value();
	  # if($g_debug eq "true"){
	  #	print "Here:\t$value\t$url\nEnter";
	  #	<stdin>;
	  #}
	  push @res,$value;
	}
	my $teamCity = $res[5]; #城市
	my $teamSection = $res[9]; #分区
	my $teamBoss = $res[11]; #老板
	my $teamCourts = $res[13]; #球场
	my $teamEnterTime = $res[15]; #进入NBA
	my $teamWin = $res[17]; #中冠军数
	my $teamCurrentOrder = $res[19];	#当前排名
	my $teamChiefCoach = $res[6];	#主教练
	my @members = (); #队员们
	my $str = encode("utf8","$teamName|$teamCity|$teamSection|$teamBoss|$teamCourts|$teamEnterTime|$teamWin|$teamCurrentOrder|$teamChiefCoach\n");
	push @g_teamOut,$str;
	my $items = $m_xpath->findnodes('//body/center/div/div/div/div[@id="table730middle"][position()=2]/div/table/tr/td');
	my @res = ();
	for my $item ($items->get_nodelist()){
	  my $value = $item->string_value();
	  #if($g_debug eq "true"){
	  #	print "Here:\t$value\t$url\nEnter";
	  #	<stdin>;
	  #}
	  push @res,$value;
	}
	push @g_teamOut,"<members>\n";
	for(my $j = 1;$j < (@res / 8);$j++){
	  my $i = $j * 8;
	  my $str = encode("utf8","$res[$i]|$res[$i + 1]|$res[$i + 2]|$res[$i + 3]|$res[$i + 4]|$res[$i + 5]|$res[$i + 6]|$res[$i + 7]\n");
	  push @g_teamOut,$str;
	  #<stdin>;
	}
	push @g_teamOut,"<endmembers>\n";
  }
}
sub getTeamUrls{
  my($url) = @_;
  my $page = getPage($url,$g_pageEncode);
  #print $page;
  my @arr = ();
  my $m_xpath = new HTML::TreeBuilder::XPath;
  $m_xpath->parse($page);
  $m_xpath->eof();
  my $items = $m_xpath->findnodes($g_teamUrlPattern);
  for my $item ($items->get_nodelist()){
	my $value = $item->string_value();
	my $url = $item->attr('href');
	if($g_debug eq "true"){
	  print "$value\t$url\nEnter";
	  <stdin>;
	}
	push @arr,$url;
  }
  return @arr;
}
sub init{
  $g_page->timeout(10);
}

sub getPage{
  my($url,$encode) = @_;
  my $return = $g_page->get( $url);
  my $content = $return->content;
  $content = decode($encode,$content);
  return $content;
}
