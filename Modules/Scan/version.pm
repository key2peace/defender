# version.pm by typobox43
# Permission is granted to modify and/or distribute this file in any way, 
# providing that this notice is left intact.

#####
#modified by Homer <Homer@EpiKnet.org>
# - add support to warn (the user) or gline.
#   if warn, it sends the reason in PRIVMSG to the user
#
# Syntax of deny_version.conf
# - regexp \t action \t reason
# - regexp \t G \t reason -> will gline the user
# - regexp \t W \t reason -> will warn the user
#
# The reason will be send as it to the user if warn.
#####

package Modules::Scan::version;

use strict;
use warnings;

my $connects = 0;
# my $responded; - not utilizing until conflicts with cgiirc.pm are resolved
my $killed = 0;
my $warned = 0;

my $mirc = 0;
my $winbot = 0;
my $xchat = 0;
my $bitchx = 0;
my $trillian = 0;
my $eggdrop = 0;
my $kvirc = 0;
my $ircii = 0;
my $irssi = 0;
my $hydrairc = 0;
my $darkbot = 0;
my $nulls = 0;
my $infobot = 0;
my $muh = 0;
my $pjirc = 0;
my $cgiirc = 0;
my $iroffer = 0;

my %blacklist;

sub handle_mode
{

}

sub handle_join
{

}

sub handle_part
{

}

sub handle_topic
{
}

sub stats {

	my $percentG = ($connects ? $killed/$connects*100 : 0);
	$percentG = $percentG ? sprintf("%.3f", $percentG) : 0;
	
	my $percentW = ($connects ? $warned/$connects*100 : 0);
	$percentW = $percentW ? sprintf("%.3f", $percentW) : 0;

	main::message("Total clients killed: \002$killed\002");
	main::message("Total clients warned: \002$warned\002");
	main::message("Total connecting clients scanned: \002$connects\002");
#	main::message("Clients not responding to CTCP VERSION: \002" . $connects-$responded . "\002");
	main::message("Percentage of blacklisted versions (banned): \002$percentG%\002");
	main::message("Percentage of blacklisted versions (warned): \002$percentW%\002");
	main::message(" ");
	main::message("\002Version Survey:\002");
	main::message(" ");
	my $pmirc = ($connects ? $mirc/$connects*100 : 0);
	my $pkvirc = ($connects ? $kvirc/$connects*100 : 0);
	my $peggdrop  = ($connects ? $eggdrop/$connects*100 : 0);
	my $pwinbot = ($connects ? $winbot/$connects*100 : 0);
	my $pxchat = ($connects ? $xchat/$connects*100 : 0);
	my $pbitchx = ($connects ? $bitchx/$connects*100 : 0);
	my $ptrillian = ($connects ? $trillian/$connects*100 : 0);
	my $pircii = ($connects ? $ircii/$connects*100 : 0);
	my $pirssi = ($connects ? $irssi/$connects*100 : 0);
	my $phydrairc = ($connects ? $hydrairc/$connects*100 : 0);
	my $pdarkbot = ($connects ? $darkbot/$connects*100 : 0);
	my $pnull = ($connects ? $nulls/$connects*100 : 0);
	my $pinfobot = ($connects ? $infobot/$connects*100 : 0);
	my $pmuh = ($connects ? $muh/$connects*100 : 0);
	my $ppjirc = ($connects ? $pjirc/$connects*100 : 0);
	my $pcgiirc = ($connects ? $cgiirc/$connects*100 : 0);
	my $piroffer = ($connects ? $iroffer/$connects*100 : 0);
	my $scantotal = $mirc+$eggdrop+$winbot+$xchat+$bitchx+$trillian+$kvirc+$ircii+$irssi+$hydrairc+$darkbot+$nulls+$infobot+$muh+$cgiirc+$pjirc+$iroffer;
	my $unresponsive = $connects - $scantotal;
	my $punresponsive = ($connects ? $unresponsive/$connects*100 : 0);
	$punresponsive = $punresponsive ? sprintf("%.3f", $punresponsive) : 0;
	$pmirc = $pmirc ? sprintf("%.3f", $pmirc) : 0;
	$pcgiirc = $pcgiirc ? sprintf("%.3f", $pcgiirc) : 0;
	$ppjirc = $ppjirc ? sprintf("%.3f", $ppjirc) : 0;
	$pircii = $pircii ? sprintf("%.3f", $pircii) : 0;
	$pkvirc = $pkvirc ? sprintf("%.3f", $pkvirc) : 0;
	$pwinbot = $pwinbot ? sprintf("%.3f", $pwinbot) : 0;
	$pxchat = $pxchat ? sprintf("%.3f", $pxchat) : 0;
	$pbitchx = $pbitchx ? sprintf("%.3f", $pbitchx) : 0;
	$ptrillian = $ptrillian ? sprintf("%.3f", $ptrillian) : 0;
	$peggdrop = $peggdrop ? sprintf("%.3f", $peggdrop) : 0;
	$pirssi = $pirssi ? sprintf("%.3f", $pirssi) : 0;
	$phydrairc = $phydrairc ? sprintf("%.3f", $phydrairc) : 0;
	$pdarkbot = $pdarkbot ? sprintf("%.3f", $pdarkbot) : 0;
	$pnull = $pnull ? sprintf("%.3f", $pnull) : 0;
	$pinfobot = $pinfobot ? sprintf("%.3f", $pinfobot) : 0;
	$pmuh = $pmuh ? sprintf("%.3f", $pmuh) : 0;
	$piroffer = $piroffer ? sprintf("%.3f", $piroffer) : 0;
	#$punknown = $punknown ? sprintf("%.3f", $punknown) : 0;
	main::message("mIRC:         \002$mirc\002 ($pmirc%)");
	main::message("WinBot:       \002$winbot\002 ($pwinbot%)");
	main::message("X-Chat:       \002$xchat\002 ($pxchat%)");
	main::message("BitchX:       \002$bitchx\002 ($pbitchx%)");
	main::message("Trillian:     \002$trillian\002 ($ptrillian%)");
	main::message("Eggdrop:      \002$eggdrop\002 ($peggdrop%)");
	main::message("KVIrc:        \002$kvirc\002 ($pkvirc%)");
	main::message("ircII/EPIC:   \002$ircii\002 ($pircii%)");
	main::message("Irssi:        \002$irssi\002 ($pirssi%)");
	main::message("HydraIRC:     \002$hydrairc\002 ($phydrairc%)");
	main::message("Darkbot:      \002$darkbot\002 ($pdarkbot%)");
	main::message("Infobot:      \002$infobot\002 ($pinfobot%)");
	main::message("Empty reply:  \002$nulls\002 ($pnull%)");
	main::message("muh (bounce): \002$muh\002 ($pmuh%)");
	main::message("PJIRC:        \002$pjirc\002 ($ppjirc%)");
	main::message("CGI:IRC:      \002$cgiirc\002 ($pcgiirc%)");
	main::message("iroffer:      \002$iroffer\002 ($piroffer%)");
	main::message("Others:       \002$unresponsive\002 ($punresponsive%)");
	#main::message("No reply:    \002$unknown\002 ($punknown%)");
}

sub scan_user {

	# dont version everyone on NETJOIN, users get pissy
        #return if ($main::NETJOIN == 1);

	my($ident, $host, $serv, $nick, $fullname, $print_always) = @_;

	if ($host !~ /underhanded/)
	{	
		main::message_to($nick, "\001VERSION\001");
	}
	$connects++;
}

sub handle_notice {

	my($nick, $ident, $host, $chan, $notice) = @_;

	if ($notice =~ /^\001VERSION mIRC.+\001/) {
		$mirc++;
	}
	elsif ($notice =~ /^\001VERSION eggdrop.+\001/) {
		$eggdrop++;
	}
	elsif ($notice =~ /^\001VERSION WinBot.+\001/) {
		$winbot++;
	}
	elsif ($notice =~ /^\001VERSION xchat.+\001/) {
		$xchat++;
	}
	elsif ($notice =~ /^\001VERSION.+BitchX.+\001/) {
		$bitchx++;
	}
	elsif ($notice =~ /^\001VERSION.+Trillian/) {
		$trillian++;
	}
	elsif ($notice =~ /^\001VERSION KVIrc/) {
		$kvirc++;
	}
	elsif ($notice =~ /^\001VERSION.+ircII.+/) {
		$ircii++;
	}
	elsif ($notice =~ /^\001VERSION.+irssi.+/) {
		$irssi++;
	}
	elsif ($notice =~ /^\001VERSION.+HydraIRC.+/) {
		$hydrairc++;
	}
	elsif ($notice =~ /^\001VERSION.+Darkbot.+/) {
		$darkbot++;
	}
	elsif ($notice =~ /^\001VERSION.+infobot.+/) {
		$infobot++;
	}
	elsif ($notice =~ /^\001VERSION.+http\:\/\/mind\.riot\.org\/muh/) {
		$muh++;
	}
	elsif ($notice =~ /^\001VERSION.+PJIRC.+/) {
		$pjirc++;
	}
	elsif ($notice =~ /^\001VERSION.+CGI\:IRC.+/) {
		$cgiirc++;
	}
	elsif ($notice =~ /^\001VERSION iroffer.+/) {
		$iroffer++;
	}
	elsif ($notice eq "") {
		$nulls++;
	}

	if ($main::OneWord) {
		# Some people want to ban on one word version replies, some don't.
		# They can set a config option to turn it on or off.  Default to off
		# as it has a lot of false positives.
		if ($notice =~ /^\001VERSION (\S+)\001/) {
			my $litmus = $1;
			# added emule at suggestion of satmd <satmd@satmd.dyndns.org>
			if (($notice !~ /^\001VERSION Trillian\001/) && ($notice !~ /\@/) && ($notice !~ /WebTV/) && ($notice !~ /eMule/)) {
				main::message("$nick has one-word version response ($litmus), glined.");
				my $n = main::gethost($nick);
				my (undef,$host) = split('@',$n);
				main::gline('*@' . $host,86400,"Possible litmus trojan");
			}
		}
	}


	if ($notice =~ /^\001VERSION (.+?)\001/) {
		my $vreply = $1;
		if (defined $vreply) {
			print "Version reply for $nick is \"$vreply\"\n";
			if (main::depends("verbose") || $main::version_verbose) {
				if ($main::NETJOIN == 0) {
					if ($main::ugly) {
						main::message("Version reply for $nick is $vreply");
					}else{
						main::message("\00303Version reply for \00310$nick\00303 is \002$vreply\002\017");
					}
				}
			}

		}
	}


	foreach my $version (keys %blacklist) {
		my($raison, $action) = split(/\t/, $blacklist{$version});

		if($notice =~ /^\001VERSION ($version)\001/) {
			if ($action eq "G") {
				# on gline
				main::gline(main::gethost($nick),86400,"Your client is not authorised to connect to $main::netname.  Reason: " . $raison . ". If you believe this is an error, please contact \2$main::killmail\2.");
				main::message("$nick using $1 matches version blacklist entry ($version), glined.");
				$killed++;
				return;
			}
			else {
				# on avertis gentiement l'user :)
				main::message_to($nick, $raison);
				main::message("Warned $nick: $raison");
				$warned++;
			}

		}

	}

}

sub handle_privmsg
{
	my($nick, $ident, $host, $chan, $message) = @_;
	if ($chan =~ /$main::mychan/i)
	{
		if ($message =~ /^version ctcp-all$/i)
		{
			main::message_to('$*.net', "\001VERSION\001");
		}
	}
}

# The version blacklist file consists of a tab-separated list of regexps to match client versions and reasons.  Example:
#
# .*subseven.*	SubSeven Trojan
# .*mIRC 6.08.*	Insecure mIRC version
sub init {

        if (!main::depends("core-v1")) {
                print "This module requires version 1.x of defender.\n";
                exit(0);
        }
        main::provides("version");

	%blacklist = ();

	open(BL, "<$main::dir/deny_version.conf") or print "Missing deny_version.conf file!\n";
	
	while(<BL>) {
		chomp;
		my($version, $action, $reason) = split(/\t/);
		if (defined($version) && defined($action) &defined($reason)) {
			$blacklist{$version} = "$reason\t$action";
		}
	}

	close BL;

}

# Thou shalt not forget to end thy modules with 1.
1;

