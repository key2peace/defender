# $Id: nickflood.pm 861 2004-11-24 11:30:33Z brain $

package Modules::Scan::nickflood;

use strict;
use warnings;

my @nicks;
my @times;
my $nextinterval = time+5;
my $threshold = 12;
my $killed = 0;
my $totalnicks = 0;

sub handle_topic
{
}

sub stats
{
	main::message("Flood threshold (kill user):     \002 $threshold\002");
	main::message("Total users killed:              \002 $killed\002");
	main::message("Total nickchanges network wide:  \002 $totalnicks\002");
	main::message("Nicks currently being tracked:   \002 " . scalar @nicks . "\002");
}

sub handle_join
{
}

sub handle_part
{
}


sub scan_user
{
}


sub handle_notice
{
}


sub handle_mode
{
}


sub handle_privmsg
{
}

sub handle_nick
{
	my ($oldnick,$newnick) = @_;
	$oldnick = lc($oldnick);
	$newnick = lc($newnick);
	$totalnicks++;
	if (time > $nextinterval)
	{
		$nextinterval = time + 5;
		@times = ();
		@nicks = ();
	}
	my $q = 0;
	for($q = 0; $q < scalar @nicks; $q++)
	{
		if ($oldnick eq $nicks[$q])
		{
			$times[$q]++;
			$nicks[$q] = $newnick;
			if ($times[$q] > $threshold)
			{
				main::message("Killed \002$newnick\002 for nick flooding: " . $times[$q] . " changes in\002 5\002 secs.");
				main::killuser($nicks[$q],"Nick flood");
				$killed++;
			}
			return;
		}
		$q++;
	}
	push @nicks, $newnick;
	push @times, 0;
}


sub init {

	if (!main::depends("core-v1","server")) {
		print "This module requires version 1.x of defender, and a server link module to be loaded.\n";
		exit(0);
	}
	main::provides("nickflood");

	$threshold = $main::dataValues{'nickflood_limit'};
	$nextinterval = time + 5;
}

1;
