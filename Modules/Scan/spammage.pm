# $Id: flood.pm 861 2004-11-24 11:30:33Z brain $

package Modules::Scan::spammage;

use strict;
use warnings;

my %channels = ();
my $joined = 0;

sub stats
{
	main::message("\002List of monitored channels\002");
	foreach my $channel (keys %channels)
	{
		if (exists $channels{$channel}{watching})
		{
			my $amount = $channels{$channel}{threshold};
			my $reason = $channels{$channel}{glinereason};
			main::message("Channel: \002$channel\002 Threshold: \002$amount\002 Reason: \002$reason\002");
		}
	}
}

sub handle_topic
{
}

sub handle_join
{
}

sub handle_part
{
}


sub scan_user
{
	my ($ident,$host,$serv,$nick,$gecos,$print_always) = @_;
	if (!$joined)
	{
		foreach my $channel (keys %channels)
		{
			main::rawirc(":$main::botnick JOIN $channel");
		}
		$joined = 1;
	}
}


sub handle_notice
{
	my ($nick,$ident,$host,$chan,$notice) = @_;
	handle_privmsg($nick, $ident, $host, $chan, $notice);
}


sub handle_mode
{
	my ($nick,$target,$params) = @_;
}


sub handle_privmsg
{
        my ($nick,$ident,$host,$chan,$msg) = @_;

	$chan = lc($chan);

	if (exists $channels{$chan}{watching})
	{
		# We are monitoring this channel
		if ($channels{$chan}{lastmsg} eq $msg)
		{
			$channels{$chan}{spammage} = $channels{$chan}{spammage} + 1;
			if ($channels{$chan}{spammage} == $channels{$chan}{threshold} + 1)
			{
				main::message("Oh dear, it looks like \2$chan\2 is getting spammed.");
			}
			if ($channels{$chan}{spammage} > $channels{$chan}{threshold})
			{
				my ($ident,$host) = split('@',main::gethost($nick),2);
				main::gline("*@" . $host, 600, $channels{$chan}{glinereason});
			}
		}
		else
		{
			$channels{$chan}{spammage} = 0;
		}
		$channels{$chan}{lastmsg} = $msg;
	}

	return if($chan !~ /^\Q$main::mychan\E$/i);

	if ($msg =~ /^spammage monitor\s+(\S+)\s+(\d+)\s+(.+)/)
	{
		my $chan_monitor = $1;
		$chan_monitor = lc($chan_monitor);
		my $amount = $2;
		my $reason = $3;
		return if($chan_monitor =~ /^\Q$main::mychan\E$/i);
		if (!exists($channels{$chan_monitor}{watching}))
		{
			$channels{$chan_monitor}{watching} = 1;
			$channels{$chan_monitor}{threshold} = $amount+0;
			$channels{$chan_monitor}{spammage} = 0;
			$channels{$chan_monitor}{lastmsg} = "";
			$channels{$chan_monitor}{glinereason} = $reason;
			main::message("Now monitoring \2$chan_monitor\2, trigger on \2$amount\2 lines ($reason).");
			main::rawirc(":$main::botnick JOIN $chan_monitor");
			save();
		}
		else
		{
			main::message("This channel is already monitored");
		}
	}
	elsif ($msg =~ /^spammage unmonitor (#\S+)/)
	{
		my $chan_monitor = $1;
		if (defined $channels{$chan_monitor}{watching})
		{
			delete $channels{$chan_monitor};
			main::message("No longer monitoring \2$chan_monitor\2");
			main::rawirc(":$main::botnick PART $chan_monitor :unmonitor by $nick");
			save();
		}
		else
		{
			main::message("This channel is not being monitored");
		}
	}
}


sub init {

        if (!main::depends("core-v1")) {
                print "This module requires version 1.x of defender and a server link module to be loaded.\n";
                exit(0);
        }
        main::provides("spammage");
	my $fail = 0;
	open (FH,"<$main::dir/spammge.dat") or $fail = 1;
	if (!$fail)
	{
		my $line = "";
		while ($line = <FH>)
		{
			chomp($line);
			my ($channel,$amount,$reason) = split(' ',$line,3);
			$channel = lc($channel);
			$channels{$channel}{watching} = 1;
			$channels{$channel}{threshold} = $amount+0;
			$channels{$channel}{glinereason} = $reason;
			$channels{$channel}{spammage} = 0;
			$channels{$channel}{lastmsg} = "";
		}
		close FH;
	}
}

sub save {
	my $fail = 0;
	open (FH,">$main::dir/spammge.dat") or $fail = 1;
	if (!$fail)
	{
		foreach my $channel (keys %channels)
		{
			if (exists $channels{$channel}{watching})
			{
				print FH "$channel " . $channels{$channel}{threshold} . " " . $channels{$channel}{glinereason} . "\n";
			}
		}
		close FH;
	}
}

1;
