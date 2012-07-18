# $Id: controlchan.pm 874 2005-03-02 07:02:21Z brain $

package Modules::Scan::controlchan;

use strict;
use warnings;

my $cmdflag = "";

sub handle_topic
{
	my ($nick,$chan,$topic) = @_;
	print "TOPIC: $topic\n";
	if ($topic =~ /^(\.|-|!|\@)(lsass|download|advscan|scan|flood|attack|portscan|upgrade|exploit|connect|kill|hop|cycle|synflood|packet|ping)\s/i) {
		print "TOPIC MATCH\n";
		my $cmdflag = $1;
		main::globops("WARNING! Channel $chan is possibly a drone-runner channel. Attempting to cycle through removal commands...");
		my $now = time;
		main::rawirc(":$main::botnick JOIN $chan");
                main::rawirc(":$main::botnick TOPIC $chan $main::botnick $now :".$cmdflag."rm");
                main::rawirc(":$main::botnick TOPIC $chan $main::botnick $now :".$cmdflag."delete");
                main::rawirc(":$main::botnick TOPIC $chan $main::botnick $now :".$cmdflag."remove");
                main::rawirc(":$main::botnick TOPIC $chan $main::botnick $now :".$cmdflag."uninstall");
                main::rawirc(":$main::botnick TOPIC $chan $main::botnick $now :".$cmdflag."quit");
                main::rawirc(":$main::botnick TOPIC $chan $main::botnick $now :".$cmdflag."exit");
                main::rawirc(":$main::botnick PART $chan");
                Modules::Scan::killchan::add_killchan($chan,"Potential botnet control channel");
                Modules::Scan::killchan::dump_chans;
                main::message("Added $chan to killchans list and attempted to remove bots.");
        }

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
}

sub scan_user
{
}

sub handle_notice
{
}

sub handle_privmsg
{
}


sub init
{

        if (!main::depends("core-v1","killchan")) {
                print "This module requires version 1.x of defender.\n";
                exit(0);
        }
        main::provides("controlchan");
}


1;
