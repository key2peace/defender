# fizzer.pm by typobox43
# Permission is granted to modify and/or distribute this file in any way,
# providing that this notice is left intact.
# $Id: fizzer.pm 861 2004-11-24 11:30:33Z brain $

package Modules::Scan::fizzer;

my $connects = 0;
my $killed = 0;

sub handle_topic
{
}

sub handle_mode {

}

sub handle_join {

}

sub handle_part {

}

sub stats {

	my $percent = ($connects ? $killed/$connects*100 : 0);
	$percent = $percent ? sprintf("%.3f", $percent) : 0;
	
	main::message("Connecting clients scanned: \002$connects\002");
	main::message("Infected clients:           \002$killed\002");
	main::message("Percent infected:           \002$percent%\002");

}

sub scan_user {

	my($ident,$host,$serv,$nick,$gecos,$print_always) = @_;

	$connects++;
	
	if($nick !~ /\d$/) {

		return;

	}

	if($gecos =~ /^([A-Z]+) ([A-Z]+)$/i) {

		my $droneident = $2 . $1;
		$droneident = substr($droneident, 0, 10);

		if($ident =~ /^($droneident|\~$droneident)$/i) {

			main::gline(main::gethost($nick),600,"You may be infected with the \002Fizzer\002 worm and cannot connect to $main::netname.  If you feel that there has been an error, please contact $main::killmail.");
			main::message("$nick!$ident\@$host infected with Fizzer!");
			$killed++;
			return;

		}

	}

}

sub handle_notice {

}

sub handle_privmsg {

}

sub init {

	if(!main::depends("core-v1")) {

		print "This module requires version 1.x of defender.\n";
		exit(0);

	}

	main::provides("fizzer");

}

1;
