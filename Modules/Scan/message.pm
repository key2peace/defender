# $Id: message.pm 8389 2007-10-27 14:55:53Z Thunderhacker $

package Modules::Scan::message;

use strict;
use warnings;

my $tot_rant = 0;
my $tot_mesg = 0;
my %nicks;

sub handle_topic
{
}

sub stats {
	main::message("Unique users to message the bot:  \002$tot_rant\002");
	main::message("Total messages received:          \002$tot_mesg\002");
}


sub handle_join
{

}

sub handle_part
{

}

sub handle_mode
{

}

sub scan_user
{
	my ($ident,$host,$serv,$nick,$gecos,$print_always) = @_;
	#main::killuser($nick,"Gerrout!");
}

sub handle_notice
{
	my ($nick,$ident,$host,$chan,$notice) = @_;
}

sub handle_privmsg
{
        my ($nick,$ident,$host,$chan,$msg) = @_;
	if (($chan !~ /^\#/) && ($msg !~ /^\001/)) # we only want non-ctcp, non-channel msgs
	{
		if ($nicks{$nick} != '1') {
			main::notice($nick,"I am a \002$main::netname network service\002 and cannot answer your messages. Please forward all support queries to \002$main::supportchannel\002.");

			$nicks{$nick} = '1';
			$tot_rant++;
		}
		$msg =~ s/\003\d+|\002|\037//gi;
		main::message("Message: \002$nick\002 -> \"$msg\"");
		$tot_mesg++;
	}
}

sub init {

        if (!main::depends("core-v1")) {
                print "This module requires version 1.x of defender.\n";
                exit(0);
        }
        main::provides("message");

}

1;
