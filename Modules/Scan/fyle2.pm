# fyle2.pm by typobox43
# Permission is granted to modfiy and/or distribute this file in any way,
# providing that this notice is left intact.
# $Id: fyle2.pm 861 2004-11-24 11:30:33Z brain $

package Modules::Scan::fyle2;

my $connects = 0;
my $killed = 0;
my %wordlist = ();

sub handle_topic {}

sub handle_notice {}

sub handle_mode {}

sub handle_join {}

sub handle_part {}

sub handle_privmsg {}

sub stats {

	my $percent = ($connects ? $killed/$connects : $connects);
	
	$percent = ($percent ? sprintf("%.3f",$percent) : 0);

	main::message("Total drones killed:              \002$killed\002");
	main::message("Total connecting clients scanned: \002$connects\002");
	main::message("Percentage drones:                \002$percent%\002");

}

sub scan_user {

	my($ident,$host,$serv,$nick,$fullname,$print_always) = @_;

	my $matches = 0;
	my $name1;
	my $name2;

	$connects++;

	$ident =~ s/(~|\+|-)//;

	if($fullname =~ /^(\S+)\s(\S+)$/) {
		$name1 = $1;
		$name2 = $2;
	}
	else {
		$name1 = $fullname;
		$name2 = $fullname;
	}

	$matches++ if defined($wordlist{$nick});
	$matches++ if defined($wordlist{$ident});
	$matches++ if defined($wordlist{$name1});
	$matches++ if defined($wordlist{$name2});

	if($matches > 3) {

		if (($nick eq $name1) && ($nick eq $ident))
		{
			main::message("\2*HMM*\2 Fyle v2 false positive? - $nick!$ident\@$host ($fullname)");
			return;
		}

		main::message("\2*SPLAT!*\2 Fyle v2 drone detected - $nick!$ident\@$host ($fullname)");
		main::gline("*\@$host",600,"You have been detected as an automated virus drone. If you feel that there has been an error, please contact $main::killmail.");
		$killed++;

	}

}

sub init {

	if(!main::depends("core-v1")) {

		print "This module requires version 1.x of defender.\n";
		exit(0);

	}

	main::provides("fyle2");

	open(WORDS, "<$main::dir/fyle2words.txt") or print "Can't open fyle2 wordlist\n";

	my $word = "";

	while(chomp($word = <WORDS>)) {
		if (defined($word)) {
			chop($word);
			$wordlist{lc($word)} = 1;
			$wordlist{lc(substr($word,0,10))} = 1 if length($word) > 10;
		}
	}
	close WORDS;

}

1;
