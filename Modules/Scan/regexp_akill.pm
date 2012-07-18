# regexp_akill.pm by typobox43 - modified by Az (2/21/2004)
# Permission is granted to modify and/or distribute this file in any way, 
# providing that this notice is left intact.
# $Id: regexp_akill.pm 1604 2005-07-07 12:01:50Z brain $
#
# Notes/Examples: 
# First, note that the regexp is not anchored unless you tell it to be. 
# So beware matching such things as !ident@, which can show up in the GECOS 
# As the Gecos/fullname field can have all sorts of stuff in it, but will 
# ALWAYS start with a space. 
# Also, any regexps you add can not have literal spaces in them, use the \s token 
# to match a space. 
# All hostmasks will be in the following form: 
#  nick!ident@host gecos(which can have spaces and other chars - or none at all) 
# Just remember that the '!', '@', and ' ' before the gecos will always be there 
# 
# DO NO USE THIS MODULE without understanding `perldoc perlre` and related materials first 
# http://www.perldoc.com/perl5.8.0/pod/perlre.html 
# 
# The characters '@' and '%' will be auto-escaped into their hex values if you enter them 
# literaly in your regexp, as there shoudl be no need to refer to any variables. 
# However, the character '$' is allowed, which is needed for the end of string anchor. 
# Ahh well, kinda defeats the purpose of blocking the others, but such is life, shouldn't 
# hurt much anyway. 
# 
# So, for examples (ALWAYS anchor your regexps due to the gecos having possible matching data)... 
# 
# To match a nick:		^nick!
# To match an ident:		^[^!]+!ident@		# note the use of [^!]+, which guarantees it wont match past the FIRST '!' 
# To match an unverified ident:	^[^!]+!~?ident@		# The question mark matches 0 or 1 of '~' 
# To match a host:		^[^@]+@some.host\s	# There will always be a space after the host, so it works as a boundary 
# To match a gecos:		^\S+\sBilly\sBob	# THe first space will always be the beginning of the Gecos!, so ^\S+ is everything else 
# 
# Here's a few other random tricks 
# To match people with the same ident and nick:	^([^!]+)!~?\1@
# To match people with domains in their gecos:	^\S+\s+.*?[^.\s]+\.(?:com|net|org|cc|tk|us)\b	# '(?:' can be just '(', this way just doesn't capture to memory 
# Match naughty users:				mirc|shit|bitch					# You get the picture ;) 

package Modules::Scan::regexp_akill;

use strict;
use warnings;

my $connects = 0;
my $killed = 0;

my %akills;

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

sub stats {

	my $percent = $connects ? $killed/$connects*100 : 0;
	$percent = $percent ? sprintf("%.3f", $percent) : 0;

	main::message("Total clients killed: \002$killed\002");
	main::message("Total connecting clients scanned: \002$connects\002");
	main::message("Percentage of akilled clients: $percent%");

}

sub scan_user {

	my($ident, $host, $serv, $nick, $fullname, $print_always) = @_;

	$connects++;

	my $hostmask = "$nick!$ident\@$host $fullname";

	my $time = time();
	my %timecheck = (regexp => '', timedelta => '0', lasttime => $time);
	foreach my $victim (keys %akills) {

		if($hostmask =~ /$victim/i) {
                        if ($nick !~ /^Guest\d+/) {
                                my (undef,$host) = split("@",main::gethost($nick));
                                main::gline("*\@$host",600,$akills{$victim});
                                main::message("User $hostmask matches regexp akill ($victim)!");
                                $killed++;
                                return;
                        }
		}

		my $curtime = time() - $timecheck{lasttime};
		if($curtime > $timecheck{timedelta}) {
			$timecheck{regexp} = $victim;
			$timecheck{lasttime} = time();
			$timecheck{timedelta} = $curtime;
		}

	}

	#main:message('Warning! Regexp scan took '.time()-$time." seconds! Slowest regexp was ($timecheck{regexp}) at $timecheck{timedelta} seconds.")
	#	if ((time() - $time) > 3);
		
}

sub handle_notice { }

sub dump_blacklist {

	open(BL, ">$main::dir/regexp_akill.conf");

	foreach my $key (keys %akills) {

		print BL "$key\t" . $akills{$key} . "\n";

	}

	close BL;

}

# Commands:
# regexp_akill add REGEXP_HOST REASON - add a regexp akill for REGEXP_HOST with REASON
# regexp_akill del REGEXP_HOST - delete regexp akill for REGEXP_HOST
# regexp_akill list - list all regexp akills
# Note hosts are in the form 'nick!ident@host.tld gecos can have spaces'
sub handle_privmsg { 

	my($nick, $ident, $host, $chan, $msg) = @_;

	return if($chan !~ /^\Q$main::mychan\E$/i);

	if($msg =~ /^regexp_akill\s+/) {
		$msg =~ s/^regexp_akill\s+//;

		if($msg =~ /^add (\S+) (.+)$/i) {
			my $regexp = $1;
			my $reason = $2;
	
			$regexp =~ s/\@/\\x40/g;
			$regexp =~ s/\%/\\x25/g;

			if($regexp =~ /\$\w/) { 
				main::message('The character \'$\' is not allowed in this usage.');
				return;
			}
	
			# Yes I am aware of the irony in this next statement, although I am only using it once :p - Az
			main::message('Note that using multiple \'.*\' constructs are often the cause of heavy processing overhead (you should optimize, but adding anyway)')
				if ($regexp =~ /\Q.*\E.*?\Q.*\E/);

			$akills{$regexp} = $reason;
			dump_blacklist;
			main::message("Regexp akill added. ($regexp)");
	
		} elsif($msg =~ /^del (.+)$/i) {
	
			foreach my $key (keys %akills) {
	
				if($key eq $1) {
	
					delete $akills{$key};
					dump_blacklist;
					main::message("Regexp akill deleted. ($1)");
					return;
	
				}
	
			}
	
			main::message("No such regexp akill.");

		} elsif($msg =~ /^list$/i) {
	
			main::message('Listing regexp kills:');
	
			my $flag = 0;
	
			foreach my $key (keys %akills) {
				$flag++;
				main::message("$key     " . $akills{$key});
	
			}
	
			main::message('No regexp akills defined!') unless $flag;
	
		} else {
			main::message('Unrecognized regexp_akill command!')
		}

	}
	
}

# The version blacklist file consists of a tab-separated list of regexp hostmasks and reasons to match against clients.
# Example:
#
# clone\d!.*@.*	Clone network
# .*!.*@65\.26\.6[78]\.\d{1,3}	User shows up on two different subnets, 65.26.67.* and 65.26.68.*
sub init {

        if (!main::depends("core-v1")) {
                print "This module requires version 1.x of defender.\n";
                exit(0);
        }
        main::provides("regexp_akill");

	%akills = ();

	open(BL, "<$main::dir/regexp_akill.conf") or die "Missing regexp_akill.conf file!";
	
	while(<BL>) {

		chomp;
		my($regexp, $reason) = split(/\t/);
		$akills{$regexp} = $reason;

	}

	close BL;

}

# Thou shalt not forget to end thy modules with 1.
1;
