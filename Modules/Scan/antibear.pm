# antibear.pm by Thunderhacker
# based on version.pm
# Permission is granted to modify and/or distribute this file in any way,
# providing that this notice is left intact.

#
# This is version 0.1 of the module.  It currently only checks TIME.
# Planned additions include the other methods used in InspIRCd's
# m_antibear.
#

package Modules::Scan::antibear;

use strict;
use warnings;

my $connects = 0;
my $killed = 0;

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

        main::message("Total BearBots killed: \002$killed\002");
        main::message("Total connecting clients scanned: \002$connects\002");
}

sub scan_user {

        my($ident, $host, $serv, $nick, $fullname, $print_always) = @_;

        if ($host !~ /underhanded/)
        {
                main::message_to($nick, "\001TIME\001");
        }
        $connects++;
}

sub handle_notice {

        my($nick, $ident, $host, $chan, $notice) = @_;

        if($notice =~ /^\001TIME Mon May 01 18:54:20 2006/) {
                main::gline(main::gethost($nick),86400,"Your client has been flagged as a trojan bot.  If you believe this is an error, please contact \2$main::killmail\2.");
                main::message("$nick flagged as a BearBot, glined.");
                $killed++;
                return;
        }
}


sub handle_privmsg
{

}

sub init {

}

# Thou shalt not forget to end thy modules with 1.
1;