# dnsbl.pm by OUTsider
# Permission is granted to modify and/or distribute this file in any way, 
# providing that this notice is left intact.
# $Id: dnsbl.pm,v 1.20 2012/07/21 14:28:44 key2peace Exp $

package Modules::Scan::dnsbl;

use strict;
use warnings;
use Socket;
use Config::General;
use Tie::IxHash;
require HTTP::Request;

my $dnsblconnects = 0;
my $dnsblkilled = 0;

tie my %dnsbls, "Tie::IxHash";

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

sub stats
{
	my $percent = $dnsblconnects ? $dnsblkilled/$dnsblconnects*100 : 0;
	$percent = $percent ? sprintf("%.3f", $percent) : 0;

	main::message("Total clients killed: \002$dnsblkilled\002");
	main::message("Total connecting clients scanned: \002$dnsblconnects\002");
	main::message("Percentage of akilled clients: $percent%");
}

sub scan_user
{
	my($ident, $host, $serv, $nick, $fullname, $print_always) = @_;
	return if ($main::NETJOIN == 1);
	$dnsblconnects++;
	my $ipaddr = gethostbyname($host);
	if(defined $ipaddr) {
		my $ip = inet_ntoa($ipaddr);
		my $arpa  = join '.', reverse split /\./, $ip;
		foreach my $dnsbl (keys %dnsbls) {
			my $res1 = gethostbyname("$arpa.$dnsbl");
			if(defined $res1) {
				my($ver1, $ver2, $ver3, $ipres) = split(/\./,inet_ntoa($res1));
				if ($ver1 != 127 && $ver2 != 0 && $ver3 != 0) {
					main::message("DNS Resolve through $dnsbl returned an invalid reply (".
						inet_ntoa($res1).")!");
				} else {
					my $desc = $dnsbls{$dnsbl}{'reply'}{$ipres};
					my $reason = $dnsbls{$dnsbl}{'reason'};
					$reason =~ s/\$ip/$ip/;
					main::message("User $nick!$ident\@$host ($ip) matches on $dnsbl ($desc)!");
					main::gline("*\@$ip",$dnsbls{$dnsbl}{'duration'},"$desc $reason");
					$dnsblkilled++;
					return;
				}
			}
		}
	}
}

sub handle_notice
{
}

sub handle_privmsg
{
}

sub init
{
        if (!main::depends("core-v1")) {
                print "This module requires version 1.x of defender.\n";
                exit(0);
        }
        main::provides("dnsbl");

	my $conf = new Config::General(
		-ConfigFile	=> "$main::dir/dnsbl.conf",
		-ExtendedAccess	=> 1,
		-LowerCaseNames => 1,
		-BackslashEscape => 1,
		-Tie		=> "Tie::IxHash"
	);
	%dnsbls = $conf->getall;
}

# Thou shalt not forget to end thy modules with 1.
1;
