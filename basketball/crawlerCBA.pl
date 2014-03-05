#!/usr/bin/perl
use LWP::UserAgent;
use HTML::TreeBuilder::XPath;
use Encode;
use strict;

our $g_debug = "true";
our $g_page = LWP::UserAgent -> new;
our $g_pageEncode = "gbk";
our $g_teamUrlPattern = '//div[@class="team_txt"]/h3/a';
our @g_teamOut = ();
our %g_hashTeam2Member = (); #队名到hash,hash中存队员名和url
our %g_hashTeam2url = (); #队名到url


main();




#	function define

sub main{
  init(); #初始化
  $g_debug = 'false';
  getTeamUrls("http://cba.sports.sina.com.cn/cba/team/all/?dpc=1");
  $g_debug = 'false';
  parseTeamUrls();
  foreach (@g_teamOut){
	print $_;
  }
}
sub test{
  print getPage("http://www.baidu.com","utf8");
}

sub parseTeamUrls{
  foreach my $team(sort keys %g_hashTeam2url){
	my $url = $g_hashTeam2url{$team};
	#print "New $team $url\n";
	my $page = getPage($url,$g_pageEncode);
	#print $page;
	my $m_xpath = new HTML::TreeBuilder::XPath;
	$m_xpath->parse($page);
	$m_xpath->eof();
	my $teamName = "NULL"; #队名中英
	my $items = $m_xpath->findnodes('//div[@class="team_info"]/h3');
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
	my $outStr = "$teamName";
	my $items = $m_xpath->findnodes('//div[@class="team_info"]/p');
	my @res = ();
	for my $item ($items->get_nodelist()){
	  my $value = $item->string_value();
	  if($g_debug eq "true"){
		#print "Here:\t$value\t$url\nEnter";
		#<stdin>;
	  }
	  $outStr .= "|$value";
	}
	push @g_teamOut,encode("utf8","$outStr\n");

	$outStr = "";
	push @g_teamOut,"<members>\n";
	my $ref = $g_hashTeam2Member{$team};
	foreach my $memberName (sort keys %{$ref}){ #下载每隔成员信息
	  $outStr = $memberName;
	  my $url = ${$ref}{$memberName};
	  my $page = getPage($url,$g_pageEncode);
	  my $m_xpath = new HTML::TreeBuilder::XPath;
	  $m_xpath->parse($page);
	  $m_xpath->eof();
	  my $items = $m_xpath->findnodes('//div[@class="info_base"]/h3/span');
	  for my $item ($items->get_nodelist()){
		my $value = $item->string_value();
		if($g_debug eq "true"){
		  #print "First:\t$value\t$url\nEnter";
		  #<stdin>;
		}
		$outStr .= "|$value";
	  }
	  #print $outStr;
	  push @g_teamOut,encode("utf8","$outStr\n");
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
	#if($g_debug eq "true"){
	#print "$value\t$url\nEnter";
	#<stdin>;
	#}
	$g_hashTeam2url{$value} = $url;
	push @arr,$value;
  }
  for(my $i = 1;$i <= @arr;$i++){
	my $str = '//body/div/div/div[position() = '.$i.']/div[@class="team_txt"]/p/a';
	my $items = $m_xpath->findnodes($str);
	for my $item ($items->get_nodelist()){
	  my $value = $item->string_value();
	  my $url = $item->attr('href');
	  if($g_debug eq "true"){
		print $arr[$i - 1]."\t$value\t$url\nEnter";
		<stdin>;
	  }
	  if(defined $g_hashTeam2Member{$arr[$i - 1]}){
		my $ref = $g_hashTeam2Member{$arr[$i - 1]};
		${$ref}{$value} = $url;
	  }else{
		my %hash = (); $hash{$value} = $url;
		$g_hashTeam2Member{$arr[$i - 1]} = \%hash;
	  }
	}
  }
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
