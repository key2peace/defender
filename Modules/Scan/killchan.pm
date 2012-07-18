# killchan.pm by typobox43
# Permission is granted to modify and/or distribute this file in any way,
# providing that this notice is left intact.
# Id$

package Modules::Scan::killchan;

use warnings;
use strict;

my $killed = 0;
my %killchans;

my $gline_time = 1800;

sub handle_mode {}

sub handle_topic
{
}


sub handle_join {

	my $gline_mins = int($gline_time / 60);

	my($nick,$chan) = @_;
	
	foreach(keys %killchans) {

		if(lc $chan eq lc $_) {
                        my (undef,$host) = split("@",main::gethost($nick));
			if (!main::isoper($nick)) {
	                        main::gline("*\@$host",$gline_time,"You joined a banned channel ($killchans{$_})");
				main::message("$nick joined $chan and was glined ($killchans{$_})");
				$killed++;
			} else {
				main::message("$nick joined $chan but is an ircop, so was not glined");
				main::notice($nick,"The channel \2$chan\2 is in the \2killchan list\2, so non-opers joining this channel will be G-Lined for \2$gline_mins\2 minutes.");
			}

		}

	}

}

sub handle_part {}

sub stats {

	my $chans;
	my @kc = keys %killchans;
	$chans = scalar @kc;
	
	main::message("Killed users:         \002$killed\002");
	main::message("Blacklisted channels: \002$chans\002");

}

sub scan_user {}

sub handle_notice {}

sub dump_chans {

	open(CHANS, ">$main::dir/killchans.conf");

	foreach my $key (keys %killchans) {

		print CHANS "$key\t$killchans{$key}\n";

	}
	
	close(CHANS);

}

sub add_killchan {
	my ($c,$m) = @_;
	$killchans{$c} = $m;
	dump_chans;
	return;
}

sub handle_privmsg {

	my($nick,$ident,$host,$chan,$msg) = @_;

	return if($chan !~ /^\Q$main::mychan\E$/i);

	if($msg =~ /^killchan\s+/) {

		$msg =~ s/^killchan\s+//;

		if($msg =~ /^add (\S+) (.+)$/i) {

			$killchans{$1} = $2;
			dump_chans;
			main::message("Added $1 to killchans list.");
			return;

		}

		if($msg =~ /^del (\S+)$/i) {

			foreach my $key (keys %killchans) {

				if($key eq $1) {

					delete $killchans{$1};
					dump_chans;
					main::message("Removed $1 from killchans list.");
					return;

				}

			}

			main::message("$1 isn't on the killchans list!");
			return;

		}

		if($msg =~ /^list$/i) {

			main::message("Killchans list:");
			
			my $flag = 0;

			foreach my $key (keys %killchans) {

				$flag++;
				main::message("$key     $killchans{$key}");

			}

			main::message("No channels on the killchans list!") if !$flag;
			return;

		}

		main::message("Unrecognized killchans command.");

	}

}

sub init {

	if(!main::depends("core-v1")) {

		print "This module requires version 1.x of defender.\n";
		exit(0);

	}

	main::provides("killchan");

	%killchans = ();

	if(open(CHANS, "<$main::dir/killchans.conf")) {

		while(<CHANS>) {

			chomp;
			my($chan,$reason) = split(/\t/);
			$killchans{$chan} = $reason;

		}

	}

	close CHANS;

}

1;
