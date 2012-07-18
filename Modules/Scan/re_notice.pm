# regexp_notice.pm by [Brain]
# Permission is granted to modify and/or distribute this file in any way,
# providing that this notice is left intact.
# $Id: re_notice.pm 861 2004-11-24 11:30:33Z brain $

package Modules::Scan::re_notice;

my $totalsent = 0;
my $totalrecipients = 0;

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
	print "stats handler\n";
	main::message("Total regexp notices sent:  \002$totalsent\002");
	main::message("Total recipients:           \002$totalrecipients\002");
}

sub scan_user {
}

sub handle_notice {
}

sub handle_privmsg {
	my ($nick,$ident,$host,$chan,$msg) = @_;
	if ($chan =~ /^\Q$main::mychan\E$/i) {
		if ($msg =~ /^re_notice (.+?) (.+?)$/i) {
			my $regexp = $1;
			my $notice = "From \002$nick\002: $2";
			$totalsent++;
			my $start = time;
			my @recipients = main::getmatching($regexp);
			foreach my $n (@recipients) {
				main::notice($n,$notice);
			}
			$totalrecipients += scalar @recipients;
			my $thisrecip = scalar @recipients;
			my $kilo = 0;
			if ((scalar @recipients * length($notice))>0) {
				$kilo = (scalar @recipients * length($notice)) / 1024;
			}
			$kilo = $kilo ? sprintf("%.3f", $kilo) : "0.000";
			my $end = time;
			my $delta = $end-$start;
			main::message("Your \002NOTICE\002 was sent to the users matching the regexp \"\002$regexp\002\". \002$thisrecip\002 total recipients, total output \002$kilo Kb\002 in \002$delta\002 seconds.");
		}
	}
 
}

sub init {

	if(!main::depends("core-v1")) {

		print "This module requires version 1.x of defender.\n";
		exit(0);

	}
	main::provides("re_notice");
}

1;
