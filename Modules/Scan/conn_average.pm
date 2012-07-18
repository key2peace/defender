# Connection Average module for IRC Defender, C. J. Edwards, Feb 2004
# $Id: conn_average.pm 1603 2005-07-07 11:52:37Z brain $

package Modules::Scan::conn_average;

use strict;
use warnings;

my $conns = 0;
my $currtime = time;
my $max_conns_per_min = 0;
my $peak = 0;
my $ptime = "(Never)";
my $pbroken = "(Never)";

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
	main::message("Connections in last minute:       \002$conns\002");
	main::message("Connections per minute peak:      \002$peak\002 at \002$ptime\002");
	main::message("Configuration alert level:        \002$max_conns_per_min\002 connections/minute");
	main::message("Alert peak last broken:           \002$pbroken\002");
}

sub scan_user
{
	# if we are using a server protocol module then we don't want to count the conenctions
	# emulated by a NETJOIN, on connecting to the hub...
	return if ($main::NETJOIN == 1);

	my ($ident,$host,$serv,$nick,$gecos,$print_always) = @_;
	$conns++;
	if (time > ($currtime+60))
	{
		if ($conns > $max_conns_per_min)
		{
			main::globops("\002WARNING!\002 Connections in the last minute was \002$conns\002, which is above the maximum safe connections of $max_conns_per_min per minute!");
			$pbroken = localtime;
		}
		if ($conns > $peak)
		{
			$peak = $conns;
			$ptime = localtime;
		}
		$conns = 0;
		$currtime = time;
	}
	# an example of how to eject a user
	# main::killuser($nick,"Gerrout!");
}


sub handle_notice
{
	my ($nick,$ident,$host,$chan,$notice) = @_;
}

sub handle_privmsg
{
        my ($nick,$ident,$host,$chan,$msg) = @_;
}


sub init {

        if (!main::depends("core-v1")) {
                print "This module requires version 1.x of defender.\n";
                exit(0);
        }
        main::provides("conn_average");

	$currtime = time;
	$peak = 0;
	$max_conns_per_min = $main::dataValues{"conn_average_max"};
}

# And larry said, all thou module slalt end with one, and it was so.

1;
