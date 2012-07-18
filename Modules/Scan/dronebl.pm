# dronebl.pm by OUTsider
# Permission is granted to modify and/or distribute this file in any way, 
# providing that this notice is left intact.
# $Id: dnsbl.pm,v 1.20 2008/04/06 12:01:50 brain Exp $

package Modules::Scan::dronebl;

use strict;
use warnings;
use Socket;
use Config::General;
use Tie::IxHash;
require HTTP::Request;

my $droneblconnects = 0;
my $droneblkilled = 0;
my $dronebl_rpckey = '';

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
	my $percent = $droneblconnects ? $droneblkilled/$droneblconnects*100 : 0;
	$percent = $percent ? sprintf("%.3f", $percent) : 0;

	main::message("Total clients killed: \002$droneblkilled\002");
	main::message("Total connecting clients scanned: \002$droneblconnects\002");
	main::message("Percentage of akilled clients: $percent%");
}

sub scan_user
{
	my($ident, $host, $serv, $nick, $fullname, $print_always) = @_;
	return if ($main::NETJOIN == 1);
	$droneblconnects++;
	my $ipaddr = gethostbyname($host);
	if(defined $ipaddr) {
		my $ip = inet_ntoa($ipaddr);
		my $arpa  = join '.', reverse split /\./, $ip;
		my $res1 = gethostbyname("$arpa.dnsbl.dronebl.org");
		if(defined $res1) {
			my ($ver1, $ver2, $ver3, $ipres) = split(/\./,inet_ntoa($res1));
			if ($ver1 != "127" && $ver2 != "0" && $ver3 != "0") {
				main::message("DNS Resolve through DroneBL returned an invalid reply (".
					inet_ntoa($res1).")!");
			} else {
				my $info = "Unknown type $ipres";
				if ($ipres eq "3") {
					$info = "IRC spam drone (litmus/sdbot/fyle)";
				} elsif ($ipres eq "5") {
					$info = "Bottler (experimental)";
				} elsif ($ipres eq "6") {
					$info = "Unknown worm or spambot";
				} elsif ($ipres eq "7") {
				        $info = "DDoS drone";
				} elsif ($ipres eq "8") {
				        $info = "Open SOCKS proxy";
				} elsif ($ipres eq "9") {
				        $info = "Open HTTP proxy";
				} elsif ($ipres eq "10") {
				        $info = "Proxychain";
				} elsif ($ipres eq "13") {
				        $info = "Automated dictionary attacks";
				} elsif ($ipres eq "14") {
				        $info = "Open WINGATE proxy";
				} elsif ($ipres eq "15") {
				        $info = "Compromised router / gateway";
					return;
				} elsif ($ipres eq "16") {
					$info = "Autorooting worms";
				} elsif ($ipres eq "17") {
					$info = "Automatically determined botnet IPs";
				} elsif ($ipres eq "255") {
					$info = "Uncategorized threat class";
				}

				main::message("User $nick!$ident\@$host \($ip\) matches on DroneBL ($info)!");
				main::gline("*\@$ip",7200,"You have a host listed in the DroneBL. $info.".
						"For more information, visit http://dronebl.org/lookup_branded?ip=$ip&network=ScaryNet");
				$droneblkilled++;
				return;
			}
		} else {
			foreach my $dnsbl (keys %dnsbls) {
				my $res2 = gethostbyname("$arpa.$dnsbl");
				if(defined $res2) {
					my($ver1, $ver2, $ver3, $ipres) = split(/\./,inet_ntoa($res2));
					if ($ver1 != 127 && $ver2 != 0 && $ver3 != 0) {
						main::message("DNS Resolve through $dnsbl returned an invalid reply (".
							inet_ntoa($res2).")!");
					} else {
						my($type, $desc) = split(/:/,$dnsbls{$dnsbl}{'reply'}{$ipres},2);
						my $reason = $dnsbls{$dnsbl}{'reason'};
						$reason =~ s/\$ip/$ip/;
						main::message("User $nick!$ident\@$host ($ip) matches on $dnsbl ($desc)!");
						main::gline("*\@$ip",$dnsbls{$dnsbl}{'duration'},"$desc $reason");
						if ($dnsbls{$dnsbl}{'report'} == 1 && $type != 4) {
							my $report = HTTP::Request->new("POST","http://dronebl.org/RPC2",
								     "Content-Type: application/x-www-form-urlencoded",
								     "<?xml version=\"1.0\"?>\n".
								     "<request key=\"".$dronebl_rpckey."\">\n".
								     "<add ip=\"".$ip."\" type=\"".$type."\" />\n".
								     "</request>\n");
						}
						$droneblkilled++;
						return;
					}
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
        main::provides("dronebl");

	$dronebl_rpckey = $main::dataValues{"dronebl_rpckey"};
	my $conf = new Config::General(
		-ConfigFile	=> "$main::dir/dronebl.conf",
		-ExtendedAccess	=> 1,
		-LowerCaseNames => 1,
		-BackslashEscape => 1,
		-Tie		=> "Tie::IxHash"
	);
	%dnsbls = $conf->getall;
}

# Thou shalt not forget to end thy modules with 1.
1;
