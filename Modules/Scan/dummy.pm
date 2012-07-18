# Dummy module for IRC Defender, C. J. Edwards, Feb 2004
# $Id: dummy.pm 861 2004-11-24 11:30:33Z brain $

package Modules::Scan::dummy;

=head1 NAME

IRC Defender dummy module for developers

=head1 DESCRIPTION

An example module that doesn't do much but demonstrates functions, API calls, event names etc.
B<WARNING!> Do NOT load this plugin into your setup without reading it through and modifying it,
it will /kill all users that connect!

=head1 CREDITS

Thanks to the users on irc.chatspike.net for their ongoing patience while this service was tested,
suffering multiple kills, shuns, force joins and being bitched at by machines ;-)

=head1 SYNOPSIS

All scanning modules for IRC Defender must be under the Modules::Scan namespace and be placed
into the Modules/Scan directory. Your modules can be loaded from the config by putting their name
into the list, e.g. if your module is "foomatic.pm" then you should put "foomatic" into the comma
seperated list in the config file. Modules are event driven, events being triggered by the core or
the protocol module.

=cut

use strict;
use warnings;

=head1 Event Subroutines

The following subroutines must be defined by your module.

=cut

=head2 sub stats

The stats sub is called whenever your module is to display statistics to the log channel.
You should use main::message to output stats, and should own up to any kills your module
has made here, seperately to any counted by the core and protocol module.

=cut

sub stats {

	# An example of how to produce output
	main::message("Percentage CGI users:             \002XXX%\002");
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

sub handle_topic
{
}

=head2 sub scan_user

This subroutine will be called whenever a user connects, with all information about the user.
it is up to the protocol module how this information is gathered but the parameter order
is always the same.

=cut

sub scan_user
{
	# The only parameter of note here is $print_always. When called by the core, this will
	# always be 0. You can use this in recursive calls, or when calling from handle_privmsg,
	# to indicate your scan call should create output etc. See the fyle module for an
	# example of this.
	my ($ident,$host,$serv,$nick,$gecos,$print_always) = @_;

	# an example of how to eject a user
	main::killuser($nick,"Gerrout!");
}

=head2 sub handle_notice

This subroutine will be called whenever a notice is received. Note that some protocol modules
may not fill the $ident and $host fields because the information is simply not sent to the
server.

=cut

sub handle_notice
{
	my ($nick,$ident,$host,$chan,$notice) = @_;
}

=head2 sub handle_privmsg

This function works similarly to handle_notice above, except that it receives privmsg commands.
Yet again, some protocol modules may omit the values for $ident and $host if they are
not passed to them and no caching is in use.

=cut

sub handle_privmsg
{
        my ($nick,$ident,$host,$chan,$msg) = @_;
}

=head2 sub init

This function is called before the connection to the irc server takes place, immediately
after the module is loaded. You should load files and initialise your modules here.

=cut

sub init {

        if (!main::depends("core-v1","client")) {
                print "This module requires version 1.x of defender and the unreal client module (because its a test, dummy!).\n";
                exit(0);
        }
        main::provides("dummy");

}

=head1 Core Functions

These functions can be used from any module. They exist in the main:: namespace and are exported by
both the core and the protocol module. You MUST use these functions to produce output and fetch
information, as you cannot gaurantee the format of the output, which varies from protocol to protocol.

=cut

=head2 main::message

This function takes one parameter, a string to be sent to the output channel. This may arrive in the
channel through various means, depending on the protocol module, but always arrives and displays literally
with no changes. You may include irc escapes such as \002 for bold.

=cut

=head2 main::message_to

This function takes two parameters, a target channel or user and a string to be sent to the target channel.
This may arrive in the channel through various means, depending on the protocol module, but always arrives
and displays literally with no changes. You may include irc escapes such as \002 for bold.

=cut

=head2 main::killuser

This function sends a KILL to remove a target user from the network. The actual format of the kill varies
between protocols, but has the same effect of closing the users connection with the given kill message. This
function also increments the global kill counter, used by 'status', so that you don't have to maintain it.
This function takes two parameters, the nick of the user to remove, and the kill reason.

=cut

=head1 Core Variables

These variables are exported by the core. B<Warning!> these variables are writeable, but be careful not to
write to them from your module, accidentally or otherwise! This may be fixed in some future release.

=cut

=head2 $main::dir

This variable contains the directory of the program, where you may store and retrieve data in files.

=cut

=head2 $main::domain

This holds the domain name of the irc network, e.g. chatspike.net

=cut

=head2 $main::nspass

If defined, holds the program's nickserv password. Unused when the server module is loaded.

=cut

=head2 $main::killurl

A page to refer users to regarding why they have been killed. This is generic and depending on your
network may contain related information.

=cut

=head2 $main::killmail

This variable contains an email address from the config file to which queries about kills should be
addressed. This should usually be the akill or admin email for your network.

=cut

=head2 $main::botnick

This variable contains the nickname of the pseudoclient, or bot, that this program creates. In client
mode, the program creates a connection directly as this user, meaning it is limited by the same
restrictions as other users on your network. In server mode, the program connects as a server then
masquerades this client as a connection of it, meaning there are no real restrictions on this fake client
(commonly known as a pseudoclient)

=cut

=head2 $main::mychan

This is the channel that all output appears on. main::message automatically sends its data here.

=cut

=head2 $main::botname

This contains the GECOS (fullname field) of the pseudoclient or bot on the network.

=cut

=head2 $main::netname

This contains the displayed name of the network the program is connected to, e.g. 'ChatSpike'.

=cut

=head2 @main::modlist

This list is a list of all loaded modules currently in the system. Removing a module from this list
will keep it loaded but all event calls to it will cease. You may use this list to, for example,
check for dependencies.

=cut

=head1 AUTHOR

This document was composed by Craig Edwards (aka Brain). Stylesheet from the TrillPerl documentation.

=head1 COPYRIGHT

This text and program code it was generated from are (C) Craig Edwards 2004. Permission to modify this text is granted
so long as the copyright notice given is preserved. See the comments in the source code for more information.

=head1 VERSION

Version 1.0, 20th February 2003

The newest version of this file should always be available at E<lt>http://brainbox.winbot.co.uk/~chatspike/modules.htmlE<gt>

=cut

# And larry said, all thou module slalt end with one, and it was so.

1;
