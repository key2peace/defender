# $Id: message.pm 861 2004-11-24 11:30:33Z brain $

package Modules::Scan::tssync;

sub handle_topic
{
}

sub stats
{
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
}

sub handle_notice
{
}

sub handle_privmsg
{
        my ($nick,$ident,$host,$chan,$msg) = @_;
	if (($chan =~ /^\#/) && ($msg =~ /^tssync/i)) # TSSYNC on the control channel...
	{
		$tm = time();
		main::rawirc(":$main::servername TSCTL SVSTIME $tm");
		main::message("TSSYNC: Set server times to :\002$tm\002");
	}
}

sub init {

        if (!main::depends("core-v1")) {
                print "This module requires version 1.x of defender.\n";
                exit(0);
        }
        main::provides("tsctl");

}

1;
