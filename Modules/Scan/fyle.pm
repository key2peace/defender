# $Id: fyle.pm 861 2004-11-24 11:30:33Z brain $

package Modules::Scan::fyle;

sub handle_notice
{

}

sub handle_topic
{
}


sub handle_mode
{

}

sub handle_join
{

}

sub handle_part
{

}

sub handle_privmsg
{
	my ($nick,$ident,$host,$chan,$msg) = @_;
	if ($msg =~ /^fyle\sscan\s(.+?)\s(.+?)\s(.+?)$/i) { # nongreedy or "fyle scan a b c d e" fails
               &scan_user($2,"","",$1,$3,1);
               return;
        }

}

sub stats {
	my $per = (($fyle_killtotal/($fyle_connects+0.0001))*100);
	if (length($per)>6)
	{
		$per  = substr($per,0,6);
	}
	main::message("Total drones killed:              \002$fyle_killtotal\002");
	main::message("Total connecting clients scanned: \002$fyle_connects\002");
	main::message("Percentage drones:                \002$per%\002");
}

my @result;

sub analyse_words
{
	my($nick,$type) = @_;

	my @words = ();
	my $word = "";
	my $i = 0;
	my $tot = 0;
	for($i = 0; $i < length($nick); $i++)
	{
		$blah = substr($nick,$i,1);
		if ($blah =~ /\{|\}|\[|\]|\||\'|-|_|\\|\s|\?|\!|\*|\&|\@|\"|\`|\+|\=|\%|\^/i)
		{
			push @words,$word;
			$word = "";
		}
		else
		{
			$word = "$word".substr($nick,$i,1);
		}
	}
	push @words,$nick;
	push @words,$word;

	my $stripnick = $nick;
	$stripnick =~ s/(\||\}|\{|\[|\]|`|-|_|\+|\@|\.|\,|\$)//gi;

	if ($stripnick ne "")
	{
		push @words,$stripnick;
	}

	foreach $word (@words)
	{
		$word = lc($word);
		if ($wordlist{$word} == 1)
		{
			push @result, "$type contains dictionary word '$word': -3pts";
			$tot-=3;
		}
	}
	return $tot;
}

sub scan_user
{
	my ($ident,$host,$serv,$nick,$fullname,$print_always) = @_;
	my $nicksyms = 0;
	my $nicknums = 0;
	my $total = 0;
	
	@result = ();

	print("Fyle module is scanning $ident $nick $host\n");
	
	# nick 6 chars or less, 1 point
	if (length($nick) < 6)
	{
		$total++;
		push @result, "Nick less than 6 chars: +1pt";
	}
	
	# nick 1 char, 1 point
	if (length($nick) == 1)
	{
		$total++;
		push @result, "Nick is only one char: +1pt";
	}
	
	# nick 3 chars or less, 1 point
	if (length($nick) < 3)
	{
		$total++;
		push @result, "Nick less than 3 chars: +1pt";
	}

	# nick and ident the same, -3 points
	if (lc($nick) eq lc($ident))
	{
		$total-=3;
		push @result, "Nick and ident the same: -3pts";
	}

	# ident and fullname the same, -3 points
	if (lc($ident) eq lc($fullname))
	{
		$total-=3;
		push @result, "Fullname and ident the same: -3pts";
	}

	# ident and fullname the same, -3 points
	if (lc($nick) eq lc($fullname))
	{
		$total-=3;
		push @result, "Fullname and nick the same: -3pts";
	}

	if (($nick =~ /^\[[A-Z][A-Z][A-Z]\].+/i) || ($nick =~ /^\[[A-Z][A-Z]\].+/i) || ($nick =~ /^\[[A-Z]\].+/i))
	{
		$total-=2;
		push @result, "Nickname starts with what looks like an alliance tag: -2pts";
	}

	if (($nick =~ /.+\[[A-Z][A-Z][A-Z]\]$/i) || ($nick =~ /.+\[[A-Z][A-Z]\]$/i) || ($nick =~ /.+\[[A-Z]\]$/i))
	{
		$total-=2;
		push @result, "Nickname ends with what looks like an alliance tag: -2pts";
	}
	
	if (($nick =~ /.+\[[A-Z][A-Z][A-Z]\].+/i) || ($nick =~ /.+\[[A-Z][A-Z]\].+/i) || ($nick =~ /.+\[[A-Z]\].+/i))
	{
		$total-=2;
		push @result, "Nickname contains what looks like an alliance tag: -2pts";
	}

	if ($fullname =~ /^[^a-z]*$/i)
	{
		$total-=3;
		push @result, "No letters in GECOS: -3pts";
	}

	if ($nick =~ /$ident/i)
	{
		$total=-3;
		push @result, "Nick contains ident: -3pts";
	}

	# ident over 9 chars, 1 point
	if (length($ident) > 9)
	{
		$total++;
		push @result, "Ident over 9 chars: +1pt";
	}


	# ircname is under 13 characters, 1 point
	if (length($ircname) < 13)
	{
		push @result, "Fullname under 13 chars: +1pt";
		$total++;
	}

	# ident contains . - or _, -2 points per symbol
	for($i=0;$i<length($ident);$i++)
	{
		if ((substr($ident,$i,1) eq "_") || (substr($ident,$i,1) eq "-") || (substr($ident,$i,1) eq "."))
		{
			push @result, "Symbol in ident: -1pt";
			$total--;
		}
	}

	# ircname has a space, -1 point per space
	for($i=0;$i<length($fullname);$i++)
	{
		if (substr($fullname,$i,1) eq " ")
		{
			push @result, "Space in fullname: -2pt";
			$total-=2;
		}
	}

	#ircname has colour, -1 point per colour code
	for($i=0;$i<length($fullname);$i++)
	{
		if ((substr($fullname,$i,1) eq "\003") || (substr($fullname,$i,1) eq "\002"))
		{
			push @result, "Colour in fullname: -5pt";
			$total-=5;
		}
	}

	#ircname has non-viruslike symbols, -1 point per symbol
	for($i=0;$i<length($fullname);$i++)
	{
		$data = substr($fullname,$i,1);
		if ($data =~ /(_|,|:|;|!|\?|\&|\#|\/|\\|\$|\(|\)|-|=|\+|\@)/i)
		{
			push @result, "Non-suspect symbol in fullname: -3pts";
			$total-=3;
		}
	}

	# ircname has .com, .net or .org on the end, 5 points
	if (($fullname =~ /\.com$/) || ($fullname =~ /\.net$/) || ($fullname =~ /\.org$/))
	{
		push @result, "Viruslike fullname ending: +5pts";
		$total+=5;
	}

	# ircname has an isp name in it, +5 pts per name
	if ($fullname =~ /^sympatico\./)
	{
		push @result, "Viruslike fullname start: +5pts";
		$total+=4;
	}
	if ($fullname =~ /^hotmail\./)
	{
		push @result, "Viruslike fullname start: +5pts";
		$total+=4;
	}
	if ($fullname =~ /^microsoft\./)
	{
		push @result, "Viruslike fullname start: +5pts";
		$total+=4;
	}
	if ($fullname =~ /^mail\./)
	{
		push @result, "Viruslike fullname start: +5pts";
		$total+=4;
	}

	if (length($fullname) < 5)
	{
		push @result, "Fullname length under 5: +1pt";
		$total+=1;
	}


	# nick has a {, 1 point
	# nick has a }, 1 point
	# nick has a |, 1 point
	# nick has a `, 1 point
	# nick has a ], 1 point
	# nick has a [, 1 point
	# nick has a _, 1 point
	# nick has a \, 1 point

	@syms = $nick =~ /([\Q{}|`]_\^\E])/g;
	foreach $sym (@syms) {
		push @result, "Symbol in nick: '$sym', +1pt";
		$nicksyms++;
		$total++;
	}

	@syms = $nick =~ /[0-9]/g;
	$nicknums = @syms + 0;

	@syms = $ident =~ /[0-9]/g;
	foreach $sym (@syms) {
		push @result, "Number in ident: '$sym', -3pts";
		$total-=3;
	}

	@syms = $fullname =~ /[0-9]/g;
	foreach $sym (@syms) {
		push @result, "Number in fullname: '$sym', -3pts";
		$total-=3;
	}
	
	# nick is 50% or more symbols, 1 point
	if ($nicksyms > (length($nick) / 2))
	{
		push @result, "Over half of nick is symbols: +1pt";
		$total++;
	}

	# ircname all letters and no spaces, 2 points
	$award = 1;
	for($i=0;$i<length($fullname);$i++)
	{
		$data = substr($fullname,$i,1);
		if (($data lt "A") || ($data gt "Z"))
		{
			if (($data lt "a") || ($data gt "z"))
			{
				$award = 0;
			}
		}
		if ($fullname =~ /(\\|\||@|!|"|\$|\%|\^|\&|\*|\(|\)|\{|\}|\[|\]|\:|\'|\,|\?)/)
		{
			$award = 0;
		}
		if ($data eq " ")
		{
			$award = 0;
		}
	}
	if ($award == 1)
	{
		push @result, "Fullname all letters, no space or symbol: +2pts";
		$total+=1;
	}

	# ident all letters, 1 point
	$award = 1;
	for($i=0;$i<length($ident);$i++)
	{
		$data = substr($ident,$i,1);
		if (($data lt "A") || ($data gt "Z"))
		{
			if (($data lt "a") || ($data gt "z"))
			{
				$award = 0;
			}
		}
	}
	# nick has no numbers, 1 point
	# nick has numbers, -1 point per number
	if ($award == 1)
	{
		push @result, "Ident no symbols: +1pt";
		$total++;
	}
	if (!$nicknums)
	{
		push @result, "Nick has no numbers: +1pt";
		$total++;
	}
	else
	{
		push @result, "Nick has numbers: -$nicknums"."pts";
		$total-=$nicknums;
	}

	$total+=analyse_words($nick,"Nick");
	$total+=analyse_words($ident,"Ident");
	$total+=analyse_words($fullname,"Fullname");

	# Extended debugging, requested by tatsujin
	print "Score for $nick is $total\n" if $main::debug;

	#foreach $line (@result) {
	#	print "$line\n";
	#}

	if ($print_always == 1)
	{
		main::message("Score for \002$nick\002 is: \002$total\002");
		foreach $line (@result) {
			main::message($line);
		}
		return;
	}

	if ($total > $main::paranoia)
	{
		main::message("\002*SPLAT*\002 Whacked drone; NICK: \002$nick\002 IDENT: \002$ident\002 GECOS: \002$fullname\002 SCORE: \002$total\002, \002".($fyle_killtotal+1)."\002 total drones killed.");
		main::killuser($nick,"You have a scan score of \002$total\002 and are possibly an \002automated virus drone\002. Please read the following page for details of the scoring system and how to avoid this in the future: \002$main::killurl\002");
		$fyle_killtotal++;
	}
	$fyle_connects++;
	$uhost = "";
}


sub init {

        if (!main::depends("core-v1")) {
                print "This module requires version 1.x of defender.\n";
                exit(0);
        }
        main::provides("fyle");

	our $fyle_killtotal = 0;
	our $fyle_connects = 0;

	open(FIH,"<$main::dir/words.txt") or die "Fyle: Wordlist open failed!";
	$count=0;
	while (chomp($word = <FIH>))
	{
		$word = lc($word);
		chop($word);
		if (length($word)>2)
		{
			$wordlist{$word} = 1;
			$count++;
		}
	}
	close FIH;
}

1;
