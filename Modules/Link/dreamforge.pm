# $Id: dreamforge.pm 9880 2008-06-09 15:33:09Z Thunderhacker $
#
# Warning - this module is experimental and largely untested.
#
# Note - we use AKILL rather than GLINE on our network, so this module uses
# AKILL as well.
#
#    -- PinkFreud, Nightstar
#
# Based on:
# # $Id: dreamforge.pm 9880 2008-06-09 15:33:09Z Thunderhacker $

my %hosts = ();

sub link_init
{
        if (!main::depends("core-v1")) {
                print "This module requires version 1.x of defender.\n";
                exit(0);
        }
        main::provides("server","dreamforge-server","native-gline","native-globops");
}

sub rawirc
{
	my $out = $_[0];
	my $first = "$out\n\r";
	syswrite(SH, $first, length($first));
	print ">> $out\n" if $debug;
}

sub mode
{
        my ($dest,$line) = @_;
        $line = ":$botnick MODE $dest $line";
        &rawirc($line);
}

sub privmsg
{
	my $nick = $_[0];
	my $msg = $_[1];
	my $first = "PRIVMSG $nick :$msg\n\r";
	syswrite(SH, $first, length($first));
}


sub notice
{
	my $nick = $_[0];
	my $msg = $_[1];
	my $first = "NOTICE $nick :$msg\n\r";
	syswrite(SH, $first, length($first));
}

sub message
{
	my $line = shift;
	$line = ":$botnick PRIVMSG $mychan :$line";
	&rawirc($line);
}

sub globops
{
	my $msg = $_[0];
	&rawirc("GLOBOPS :$msg");
}

sub message_to
{
        my ($dest,$line) = @_;
        $line = ":$botnick PRIVMSG $dest :$line";
        &rawirc($line);
}


sub killuser
{
        my($nick,$reason) = @_;
        &rawirc(":$botnick KILL $nick :$botnick ($reason)");
	$KILLED++;
}

sub gline
{
	my($hostname,$duration,$reason) = @_;
	my ($ident,$host) = split("@",$hostname);
	my $delta = time + $duration;
	my $now = time;
	#&rawirc(":$servername TKL + G $ident $host $servername $delta $now :$reason");
	#print ":$servername OPERSERV :AKILL add +${duration}s ${hostname} $reason\n" if $debug;
	&rawirc(":$servername OPERSERV :AKILL add +${duration}s ${hostname} $reason");
	$KILLED++;
}

sub gethost
{
	my($nick) = @_;
	$nick = lc($nick);
	return $hosts{$nick};
}

sub isoper
{
	my($nick) = @_;
	if ($hosts{lc($nick)}{isoper} eq "yes") {
		return 1;
	} else {
		return 0;
	}
}

sub getmatching
{
	my @results = ();
	my($re) = @_;
	foreach my $mask (%hosts) {
		if (defined($hosts{$mask})) {
			if ($hosts{$mask} =~ /$re/i) {
				push @results, $mask;
			}
		}
	}
	return @results;
}

sub connect {
	$CONNECT_TYPE = "Server";
	my $time = time;

	print ("Creating socket...\n");
        socket(SH, PF_INET, SOCK_STREAM, getprotobyname('tcp')) || print "socket() failed: $!\n";
        if (defined($main::dataValues{"bind"})) {
		print "Bound to ip address: " . $main::dataValues{"bind"} . "\n";
                bind(SH, sockaddr_in(0, inet_aton($main::dataValues{"bind"})));
        }
        else {
		bind(SH, sockaddr_in(0, INADDR_ANY));
        }

	print ("Connecting to $server\:$port...\n");
        my $sin = sockaddr_in ($port,inet_aton($server));
        connect(SH,$sin) || print "Could not connect to server: $!\n";

	print ("Logging in...\n");
	&rawirc("PROTOCTL VL");
	&rawirc("PASS :$password");
	&rawirc("SERVER $servername 1 :$serverdesc");

	print ("Introducing pseudoclient: $botnick...\n");
	&rawirc("NICK $botnick 1 $time $botnick $domain $servername 0 :$botname");
	&rawirc(":$botnick MODE $botnick -x+oiS");

	print ("Joining channel...\n");
	&rawirc(":$botnick JOIN $mychan");

	$njservername = $servername;
	$njtime = time+20;
	$NETJOIN = 1;

}

sub pingreply {
	$string = $_[0];
	@per = split(':', $string, 2);
	$pier = $per[1];
	$ret = "PONG :$pier";
	&rawirc($ret);
}


sub reconnect {
	close SH;
	&connect;
}

my $njtime = time+20;

sub checkmodes
{
        # this sub checks a nick's modes to see if theyre an oper or not
        # if they have +o theyre judged as being oper, and are inserted
        # into an @opers list which is used by non-native globops.
        my ($nick,$modes) = @_;
        if ($modes =~ /^\+/) { # adding modes
                if ($modes =~ /^\+.*(o|a|A|S|O).*$/) {
                        $hosts{lc($nick)}{isoper} = "yes";
                }
        }
        if ($modes =~ /^-/) { # taking modes
                if ($modes =~ /^-.*(o|a|A|S|O).*$/) {
                        $hosts{lc($nick)}{isoper} = "no";
                }
        }
}


sub poll {

	$KILLED = 0;
	$CONNECTS = 0;

	while (chomp($buffer = <SH>))
	{
		chop($buffer);

		print "<< $buffer\n" if $debug;

		if (($NETJOIN != 0) && (time > $njtime))
	        {
                	$NETJOIN = 0;
	                print "$njservername completed NETJOIN state (merge time exceeded)\n";
        	}

		
                if ($buffer =~ /KICK/i)
                {
                        &rawirc(":$botnick JOIN $mychan");
                }

		if ($buffer =~ /^ERROR :(.+?)$/)
		{
			print "ERROR received from ircd: $1\n";
			print "You might need to check your C/N lines or link block on the ircd, or port number you are using.\n";
			exit(0);
		}

		if ($buffer =~ /^:(.+) REHASH (.+)$/)
		{
			my $rnick = $1;
			if ($2 =~ /$servername/)
			{
				&globops("$servername rehashing at request of \002$rnick\002");
				&rehash;
				foreach my $line (@rehash_data) {
					notice($rnick,$line);
				}
			}
		}
		# :Brain4 NICK [Brain] :1078842182
		if ($buffer =~ /^:(.+?) NICK (.+?) :[0-9]+$/)
		{
			$oldnick = quotemeta($1);
			$newnick = quotemeta($2);

			$hosts{lc($2)} = $hosts{lc($1)};
			delete $hosts{lc($1)};

			foreach $mod (@modlist) {
				eval ("Modules::Scan::" . $mod ."::handle_nick(\"$oldnick\",\"$newnick\")");
			}
		}

		# NICK BotServ2 2 1077205492 BotServ2 nightstar.net botserv2.nightstar.net 0 :0
		if ($buffer =~ /^NICK (.+?) .+? .+? (.+?) (.+?) (.+?) .+? :(.+?)$/)
		{
			$thenick = $1;
			$theident = $2;
			$thehost = $3;
			$theserver = $4;
			$thegecos = $5;
			$CONNECTS++;
			# :Defender PRIVMSG [Brain] 1 1078621980 :VERSION
			if ($thenick =~ / /)
			{
				($thenick) = split(" ",$thenick);
			}

			$hosts{lc($thenick)} = "$theident\@$thehost";
			# Unreal needs no checkmodes here in this protocol setup

			$thegecos = quotemeta($thegecos);
			$thenick = quotemeta($thenick);
			foreach $mod (@modlist) {
			        my $func = ("Modules::Scan::" . $mod . "::scan_user(\"$theident\",\"$thehost\",\"$theserver\",\"$thenick\",\"$thegecos\",0)");
			        eval $func;
				print $@ if $@;
			}
		}
		if ($buffer =~ /^\:(.+?)\sMODE\s(.+?)\s(.+?)$/)
		{
			$thenick = $1;
			$thetarget = $2;
			$params = $3;
			$params =~ s/^\://;
			&checkmodes($thetarget,$params);
			$thenick = quotemeta($thenick);
			$thetarget = quotemeta($thetarget);
			$params = quotemeta($params);
			foreach $mod (@modlist) {
				my $func = ("Modules::Scan::" . $mod . "::handle_mode(\"$thenick\",\"$thetarget\",\"$params\")");
				eval $func;
			}
		}
		# :[Brain] KILL Defender :NetAdmin.chatspike.net![Brain] (kill test)
		if ($buffer =~ /^\:(.+?)\sKILL\s(.+?)\s:(.+?)$/)
		{
			my $killedby = $1;
			my $killnick = $2;
			my $killreason = $3;
			if ($killnick =~ /^\Q$botnick\E$/i)
			{
				&rawirc("NICK $botnick 1 1077205492 $botnick $domain $servername 0 +oiSq $domain :$botname");
				&rawirc(":$botnick JOIN $mychan");
				&rawirc(":$servername KILL $killedby :$servername (Do \002NOT\002 kill $botnick!)");
			}
		}

		if ($buffer =~ /^:(.+?)\sQUIT\s:(.+?)$/)
		{
			my $quitnick = $1;
			my $quitreason = $2;
			delete $hosts{$quitnick};
		}

		if ($buffer =~ /^:(.+?)\sJOIN\s:?(.+?)$/)
		{
			$thenick = $1;
			$thetarget = $2;
			$thenick = quotemeta($thenick);
			# deal effectively with multiple chan joins
			my @chanlist = split(',',$thetarget);
			foreach my $chan (@chanlist) {
				print "Processing join to $chan\n" if $debug;
				$chan = quotemeta($chan);
				foreach $mod (@modlist) {
					my $func = ("Modules::Scan::" . $mod . "::handle_join(\"$thenick\",\"$chan\")");
					eval $func;
				}
			}
		}
		
		if ($buffer =~ /^:(.+?)\sPART\s(.+?)$/)
		{
			$thenick = $1;
			$thetarget = $2;
			if ($thetarget =~ / /) {
				$thetarget = split(" ",$thetarget);
			}
			$thenick = quotemeta($thenick);
			my @chanlist = split(',',$thetarget);
			foreach my $chan (@chanlist) {
				print "Processing part from $chan\n" if $debug;
				$chan = quotemeta($chan);
				foreach $mod (@modlist) {
					my $func = ("Modules::Scan::" . $mod . "::handle_part(\"$thenick\",\"$thetarget\")");
					eval $func;
				}
			}
		}

		if ($buffer =~ /^:(.+?)\sSERVER\s(.+?)\s(.+?)\s:(.+?)/)
		{
			$NETJOIN = 1;
			$njservername = $2;
			print "$njservername joined the net and began syncing\n";
			$njtime = time+20;
		}

		if ($buffer =~ /^NETINFO/)
		{
			$NETJOIN = 0;
			print "$njservername completed NETJOIN state\n";
		}

		if ($buffer =~ /^:(.+?)\sNOTICE\s(.+?)\s:(.+?)$/)
		{
			&noticehandler($buffer);
		}
		elsif ($buffer =~ /^:(.+?)\sPRIVMSG\s(.+?)\s:(.+?)$/) {
			&msghandler($buffer);
		}
		elsif ($buffer =~ /^:(.+) WHOIS (.+) :.+$/) {
			$source = $1;
			# :bender.chatspike.net 320 [Brain] [Brain] :has whacked 33 virus drones
			main::rawirc(":$servername 311 $source $botnick $botnick $domain * :$botname");
                        main::rawirc(":$servername 312 $source $botnick $servername :$serverdesc");
			main::rawirc(":$servername 320 $source $botnick :Is your benevolent protector");
			main::rawirc(":$servername 313 $source $botnick :Is a network service");
                        main::rawirc(":$servername 318 $source $botnick :End of /WHOIS list.");

		}
		else
		{
		        if (substr($buffer,0,4) =~ /ping/i)
			{
			        &pingreply($buffer);
       			}
		}
	}
}


# sig handler

sub shutdown {
	#print "SIGINT caught\n";
	&rawirc(":$botnick QUIT :Defender terminating");
	print("Disconnecting from irc server (SIGINT)\n");
	&rawirc(":$servername SQUIT :$quitmsg");
	close SH;
	exit;
}

sub handle_alarm
{
}

1;
