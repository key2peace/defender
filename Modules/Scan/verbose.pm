# Verbose control channel reporting module
# Written by Thunderhacker
# Note: some features of this module aren't yet in the protocol modules!

# Loading this module also activates verbose channel reporting in some
# other modules

package Modules::Scan::verbose;

use strict;
use warnings;

sub handle_join
{
        # Don't flood channel on netjoin
        return if ($main::NETJOIN == 1);
        my($nick,$chan) = @_;
	if ($main::ugly) {
	main::message("Channel join: $nick joined $chan");
	}else{
        main::message("\00303Channel join: \00310$nick\00303 joined \017\002$chan\017");
	}
}

sub handle_part
{
        my($nick,$chan) = @_;
	if ($main::ugly) {
	main::message("Channel part: $nick parted $chan");
	}else{
        main::message("\00303Channel part: \00310$nick\00303 parted \017\002$chan\017");
	}

}

sub handle_kick
{
        my($nick,$chan,$kicked,$reason) = @_;
        if ($main::ugly) {
        main::message("Channel kick: $kicked was kicked from $chan");
        }else{
        main::message("\00307Channel kick: \00310$kicked\00307 was kicked from\017\002 $chan\017");
        }
}

sub handle_quit
{
        my($quitnick,$quitreason) = @_;
	if ($main::ugly) {
	main::message("Client exiting: $quitnick ( $quitreason )");
	}else{
        main::message("\00303Client exiting: \00310$quitnick \017\002(\017 $quitreason\017 \002)\017");
	}
}


sub handle_topic
{
	my($nick,$chan,$topic) = @_;
	if ($main::ugly) {
	main::message("Topic for channel $chan was changed.");
	}else{
	main::message("\00303Topic for channel \017\002$chan\017\00303 was changed.\017");
	}
}

sub scan_user
{
        my ($ident,$host,$serv,$nick,$gecos,$print_always) = @_;
        # Don't flood channel on netjoin
        return if ($main::NETJOIN == 1);
	if ($main::ugly) {
	main::message("Client connecting: $nick!$ident@$host $gecos");
	}else{
        main::message("\00303Client connecting: \00310$nick\017\002!\017\00303$ident\017\002@\017\00307$host\017 \00308$gecos\017");
	}
}

sub handle_nick
{
        my ($oldnick,$newnick) = @_;
	if ($main::ugly) {
	main::message("Nick change: $oldnick changed his/her nickname to $newnick");
	}else{
        main::message("\00308Nick change: \00310$oldnick\00308 changed his/her nickname to \00310\002$newnick\017");
	}
}

sub handle_notice
{

}

sub handle_privmsg
{

}

sub init {

        if (!main::depends("core-v1")) {
                print "This module requires version 1.x of defender.\n";
                exit(0);
        }
        main::provides("verbose");
	if (!$main::ugly) {
		print "\nThis module is configured to use colors in the control channel.  If this is undesirable, set the line 'ugly' to 1 in the config file.\n";
		print "Loading: Modules/Scan/verbose.pm... ";
	}
}

# And larry said, all thou module slalt end with one, and it was so.

1;