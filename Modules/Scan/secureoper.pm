# $Id: secureoper.pm 4555 2006-07-27 12:06:13Z brain $

package Modules::Scan::secureoper;

use strict;
use warnings;

my @masks;

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
}


sub handle_notice
{
    my ($nick,$ident,$host,$chan,$notice) = @_;
}


sub handle_mode
{
    my ($nick,$target,$params) = @_;

    if ($target !~ /^(\#|\&|\!)/)   # don't bounce any channel modes
    {
        if ($params =~ /^\+${main::opermodes}/) # Attempt at shoving this in the protocol module
        {
            my $allow = 0;
            foreach my $nickmask (@masks)
            {
                chomp($nickmask);
                if ($target =~ /^$nickmask$/i)
                {
                    $allow = 1;
                }
            }
            if ($allow)
            {
                main::message("\002Allowed\002 an oper mode change: $target got modes $params");
                return;
            }
            else
            {
                main::killuser($target,"You are not an operator, please do not attempt, and succeed, in opering. If you believe this is in error please email ".$main::killmail);
                main::globops("Warning! \002$target\002 became an IRC operator, and is not in the access list!");
                return;
            }
        }
    }
}


sub handle_privmsg
{
        my ($nick,$ident,$host,$chan,$msg) = @_;
}


sub stats
{

}


sub init {
        if (!main::depends("core-v1","server","inspircd-server")) {
                print "This module requires version 1.x of defender and the inspircd server module to be loaded.\n";
                exit(0);
        }
        main::provides("secureoper");
        main::message("Secureoper Version 0.1a");

    open CONFIGFILE, "$main::dir/opernicks.conf";
    @masks = <CONFIGFILE>;
    close CONFIGFILE;
}

1;
