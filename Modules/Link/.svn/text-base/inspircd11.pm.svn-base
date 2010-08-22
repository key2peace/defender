# $Id: inspircd.pm 4269 2006-07-10 13:34:24Z brain $

my %hosts = ();

sub link_init
{
	srand(time);
	if (!main::depends("core-v1")) {
		print "This module requires version 1.x of defender.\n";
		exit(0);
	}
	main::provides("server","inspircd-server","native-gline","native-globops");
}

sub rawirc
{
	my $out = $_[0];
	my $first = "$out\r\n";
	syswrite(SH, $first, length($first));
	print ">> $out\n" if $debug;
}

sub mode
{
	my ($dest,$line) = @_;
	my $time = time();
	$line = ":$servername FMODE $dest $time $line";
	&rawirc($line);
}

sub privmsg
{
	my $nick = $_[0];
	my $msg = $_[1];
	my $first = ":$botnick PRIVMSG $nick :$msg\r\n";
	syswrite(SH, $first, length($first));
}


sub notice
{
	my $nick = $_[0];
	my $msg = $_[1];
	my $first = ":$botnick NOTICE $nick :$msg\r\n";
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
	&rawirc(":$botnick GLOBOPS :$msg");
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
	&rawirc(":$botnick KILL $nick :Killed ($botnick ($reason))");
	$KILLED++;
}

sub gline
{
	my($hostname,$duration,$reason) = @_;
	&rawirc(":$botnick GLINE $hostname $duration :$reason");
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
	if ($hosts{lc($nick)}{isoper}) {
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
	&rawirc("SERVER $servername $password 0 :$serverdesc");
}

sub finishburst {
	&rawirc("BURST");
	&rawirc(":$servername VERSION :IRC Defender $VERSION");

	print ("Introducing pseudoclient: $botnick...\n");
	my $now = time;
	&rawirc(":$servername NICK $now $botnick $domain $domain $botnick +oi 0.0.0.0 :$botname");

	print ("Joining channel...\n");
	$t = time();
	&rawirc(":$servername FJOIN $mychan $t :@,$botnick");

	$njservername = $servername;
	$njtime = time+40;
	$NETJOIN = 1;

	&rawirc("ENDBURST");

}

sub pingreply {
	&rawirc(":$servername PONG " . $_[0]);
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
	if ($modes =~ /^-/) { # taking modes
		if ($modes =~ /^-.*o.*$/) {
			$hosts{lc($nick)}{isoper} = 0;
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

		if ($buffer =~ /^ERROR\s:(.+?)$/)
		{
			print "ERROR received from ircd: $1\n";
			print "You might need to check your C/N lines or link block on the ircd, or port number you are using.\n";
			exit(0);
		}
		elsif ($buffer =~ /^:(.+?)\sPRIVMSG\s(.+?)\s:(.+?)$/) {
			&msghandler($buffer);
		}
		elsif ($buffer =~ /^AES\s(.+?)$/)
		{
			print "You can't link using AES with defender (Server: $1)!\n";
			exit(0);
		}
		elsif ($buffer =~ /^SERVER\s.+?\s.+?\s(\d+)\s:.+?$/)
		{
			finishburst();
		}
		elsif ($buffer =~ /:(.+?)\sIDLE\s(.+?)$/)
		{
			$source = $1;
			$dest = $2;
			if ($dest !~ /\s/) {
				&rawirc(":$dest IDLE $source " . time() . " 0");
			}
		}
		elsif ($buffer =~ /^:(.+?)\sNICK\s([^ ]+?)$/)
		{
			$oldnick = quotemeta($1);
			$newnick = quotemeta($2);

			$hosts{lc($2)} = $hosts{lc($1)};

			foreach $mod (@modlist) {
				eval ("Modules::Scan::" . $mod ."::handle_nick(\"$oldnick\",\"$newnick\")");
			}
		}
		#                 SVR          TS   NICK   HOST   VHST IDENT MOD   IP    GECOS
		elsif ($buffer =~ /^:(.+?)\sNICK\s.+?\s(.+?)\s(.+?)\s.+?\s(.+?)\s.+?\s.+?\s:(.+?)$/)
		{
			# :server NICK 1111691007 OperServ chatspike.net chatspike.net services-dev +oio 0.0.0.0 :Operator Server
			$thenick = $2;
			$thehost = $3;
			$theident = $4;
			$theserver = $1;
			$thegecos = $5;
			$CONNECTS++;

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
		elsif ($buffer =~ /^:(.+?)\sMODE\s(.+?)\s(.+?)$/)
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
		elsif ($buffer =~ /^:(.+?)\sTOPIC\s(.+?)\s:(.+?)$/)
		{
			$thenick = $1;
			$thetarget = $2;
			$params = $3;
			$params =~ s/^\://;
			$thenick = quotemeta($thenick);
			$thetarget = quotemeta($thetarget);
			$params = quotemeta($params);
			foreach $mod (@modlist) {
				my $func = ("Modules::Scan::" . $mod . "::handle_topic(\"$thenick\",\"$thetarget\",\"$params\")");
				eval $func;
			}
		}
		# :[Brain] KILL Defender :NetAdmin.chatspike.net![Brain] (kill test)
		elsif ($buffer =~ /^:(.+?)\sKILL\s(.+?)\s:(.+?)$/)
		{
			my $killedby = $1;
			my $killnick = $2;
			my $killreason = $3;
			if ($killnick =~ /^\Q$botnick\E$/i)
			{
				$t = time();
				&rawirc(":$servername NICK $now $botnick $domain $domain $botnick +oi 0.0.0.0 :$botname");
				&rawirc(":$servername FJOIN $mychan $t :@,$botnick");
				&rawirc(":$servername KILL $killedby :$servername (Do \002NOT\002 kill $botnick!)");
			}
		}
		elsif ($buffer =~ /^:(.+?)\sQUIT\s:(.+?)$/)
		{
			my $quitnick = $1;
			my $quitreason = $2;
			delete $hosts{$quitnick};
			foreach $mod (@modlist) {
				my $func = ("Modules::Scan::" . $mod . "::handle_quit(\"$quitnick\",\"$quitreason\")");
				eval $func;
			}
		}
		elsif ($buffer =~ /^:(.+?)\sJOIN\s(.+?)\s\d+$/)
		{
			$thenick = $1;
			$thetarget = $2;
			$thenick = quotemeta($thenick);
			# deal effectively with multiple chan joins
			my @chanlist = split(' ',$thetarget);
			$chan = quotemeta($chanlist[0]);
			foreach $mod (@modlist) {
				my $func = ("Modules::Scan::" . $mod . "::handle_join(\"$thenick\",\"$chan\")");
				eval $func;
			}
		}
		elsif ($buffer =~ /^:(.+?)\sJOIN\s(.+?)$/)
		{
			$thenick = $1;
			$thetarget = $2;
			$thenick = quotemeta($thenick);
			# deal effectively with multiple chan joins
			my @chanlist = split(' ',$thetarget);
			$chan = quotemeta($chanlist[0]);
			foreach $mod (@modlist) {
				my $func = ("Modules::Scan::" . $mod . "::handle_join(\"$thenick\",\"$chan\")");
				eval $func;
			}
		}
		elsif ($buffer =~ /^:.+?\sFJOIN\s(.+?)\s\d+\s:?(.+?)$/)
		{
			$channel = quotemeta($1);
			$nicklist = $2;
			@nicks = split(' ',$nicklist);
			foreach my $nick (@nicks) {
				(undef,$nick) = split(',',$nick);
				foreach $mod (@modlist) {
					my $func = ("Modules::Scan::" . $mod . "::handle_join(\"$nick\",\"$channel\")");
					eval $func;
				}
			}
		}
		elsif ($buffer =~ /^:(.+?)\sKICK\s(.+?)\s(.+?)\s:(.+?)$/)
		{
			$nick = quotemeta($1);
			$channel = $2;
			$kicked = $3;
			$reason = $4;
			foreach $mod (@modlist) {
				my $func = ("Modules::Scan::" . $mod . "::handle_kick(\"$nick\",\"$channel\",\"$kicked\",\"$reason\")");
				eval $func;
			}
		}
		elsif ($buffer =~ /^:(.+?)\sPART\s(.+?)\s/)
		{
			$thenick = $1;
			$thetarget = $2;
			if ($thetarget =~ / /) {
				$thetarget = split(" ",$thetarget);
			}
			$thenick = quotemeta($thenick);
			my @chanlist = split(',',$thetarget);
			foreach my $chan (@chanlist) {
				$chan = quotemeta($chan);
				foreach $mod (@modlist) {
					my $func = ("Modules::Scan::" . $mod . "::handle_part(\"$thenick\",\"$thetarget\")");
					eval $func;
				}
			}
		}
		elsif ($buffer =~ /^:(.+?)\sNOTICE\s(.+?)\s:(.+?)$/)
		{
			&noticehandler($buffer);
		}
		elsif ($buffer =~ /^:(.+?)\sPING\s(.+?)$/)
		{
			&pingreply($buffer);
		}
		elsif ($buffer =~ /^CAPAB\s(.+?)$/)
		{
			# Nothing here folks.
		}
                elsif ($buffer =~ /^:(.*?) OPERTYPE .+/)
		# Fix by Wulf @ forums
		# Emulates the +o mode and sends to other modules
                {
                        $hosts{lc($1)}{isoper} = 1;
			$thetarget = $1;
			$params = "+o";
			&checkmodes($thetarget,$params);
			foreach $mod (@modlist) {
				my $func = ("Modules::Scan::" . $mod . "::handle_mode(\"$servername\",\"$thetarget\",\"$params\")");
				eval $func;
                        }
                }

	}
}


# sig handler

sub shutdown {
	#print "SIGINT caught\n";
	&rawirc(":$botnick QUIT :Defender terminating");
	print("Disconnecting from irc server (SIGINT)\n");
	close SH;
	exit;
}

sub handle_alarm
{
}

1;
