# ---- Link module for bahamut and ultimate (v3.x) servers ----
#
# Programmed by C.J.Edwards, licensed under GPL.
#
# Big thanks to laXity for access to an ultimateircd - irc.bongster.de
# (i couldnt get it to compile, shadowmaster fix -ldl!)
# $Id: dancer.pm 9880 2008-06-09 15:33:09Z Thunderhacker $

my %hosts = ();

sub link_init
{
        if (!main::depends("core-v1")) {
                print "This module requires version 1.x of defender.\n";
                exit(0);
        }
        main::provides("server","dancer-server","native-gline","native-globops");
}

sub rawirc
{
    my $out = $_[0]; $out .= "\n\r";
    print ">> $out\n" if $debug;
    syswrite(SH, $out, length($out));
}


sub privmsg
{
	# $_[0] = nick
	# $_[1] = message
    my $first = "PRIVMSG $_[0] :$_[1]\n\r";
    syswrite(SH, $first, length($first));
}


sub notice
{
	# $_[0] = nick
	# $_[1] = message
    my $first = "NOTICE $_[0] :$_[1]\n\r";
    syswrite(SH, $first, length($first));
}

sub globops
{
	# $_[0] = message
    &rawirc(":$servername GNOTICE :$_[0]");
}

sub mode
{
        my ($dest,$line) = @_;
        $line = ":$botnick MODE $dest $line";
        &rawirc($line);
}


sub message
{
    my $line = shift;
    $line = ":$botnick PRIVMSG $mychan :$line";
    &rawirc($line);
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
    my $now = time;
    &rawirc(":$servername AKILL $host $ident $duration $botnick $now :$reason");
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
    if ($hosts{lc($nick)}{isoper}) 
	{
        return 1;
    } 
	else 
	{
        return 0;
    }
}


sub checkmodes
{
        # this sub checks a nick's modes to see if theyre an oper or not
        # if they have +o theyre judged as being oper, and are inserted
        # into an @opers list which is used by non-native globops.
        my ($nick,$modes) = @_;
        if ($modes =~ /^\+/) 
		{
			# adding modes
            if ($modes =~ /^\+.*(o|a|l|A|O).*$/) 
			{
                $hosts{lc($nick)}{isoper} = 1;
            }
        }
        if ($modes =~ /^-/) 
		{
			# taking modes
            if ($modes =~ /^-.*(o|a|l|A|O).*$/) 
			{
                $hosts{lc($nick)}{isoper} = 0;
            }
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

    print ("Connecting to $server\:$port...\n");
    my $sin = sockaddr_in ($port,inet_aton($server));
    if (defined($main::dataValues{"bind"})) {
        print "Bound to ip address: " . $main::dataValues{"bind"} . "\n";
        bind(SH, sockaddr_in(0, inet_aton($main::dataValues{"bind"})));
    }
    else {
        bind(SH, sockaddr_in(0, INADDR_ANY));
    }
        connect(SH,$sin) || print "Could not connect to server: $!\n";

    print ("Logging in...\n");
    &rawirc("PASS $password :TS");
    &rawirc("CAPAB :EX DNCR SRV");
    &rawirc("SERVER $servername 1 :$serverdesc");

    print ("Introducing pseudoclient: $botnick...\n");
    &rawirc("NICK $botnick 1 42432425 +abcGhiIkKlnrsUvx $botnick $domain $servername 255.255.255.255 :$botname");
    &rawirc(":$botnick NICKSERV identify password");

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

sub poll {

    $KILLED = 0;
    $CONNECTS = 0;

    while (chomp($buffer = <SH>))
    {
        chomp($buffer);

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
            print "You might need to check your C/N lines on the ircd, or port number you are using.\n";
            exit(0);
        }

        # << :FurBall NICK test1 :1082336996
        if ($buffer =~ /^:(.+?) NICK (.+?) :[0-9]+$/)
        {
            $oldnick = quotemeta($1);
            $newnick = quotemeta($2);

            $hosts{lc($2)} = $hosts{lc($1)};

            foreach $mod (@modlist) {
                eval ("Modules::Scan::" . $mod ."::handle_nick(\"$oldnick\",\"$newnick\")");
            }
        }

        # << NICK Kayla 1 1082336827 + ~JustaGirl 24.210.122.qc6O= irc.adultchatnetwork.com 24.210.122.154 :Â
        if ($buffer =~ /^NICK (.+?) 1 \d+ (\+) ~(.+?) .+? (.+?) (.+?) :(.+?)$/)
        {
            $thenick = $1;
            $themodes = $2;
            $theident = $3;
            $thehost = $5;
            $theserver = $4;
            $thegecos = $6;
            $CONNECTS++;
            # :Defender PRIVMSG [Brain] 1 1078621980 :VERSION
            if ($thenick =~ / /)
            {
                ($thenick) = split(" ",$thenick);
            }

            $hosts{lc($thenick)} = "$theident\@$thehost";
            checkmodes($thenick,$themodes);

            $thegecos = quotemeta($thegecos);
            $thenick = quotemeta($thenick);
            foreach $mod (@modlist) {
                    my $func = ("Modules::Scan::" . $mod . "::scan_user(\"$theident\",\"$thehost\",\"$theserver\",\"$thenick\",\"$thegecos\",0)");
                    eval $func;
                print $@ if $@;
                my $func = ("Modules::Scan::" . $mod . "::handle_mode(\"$thenick\",\"$thenick\",\"$themodes\")");
                eval $func;
            }
        }
        # << :FurBall MODE FurBall :+abDfFGhHkKmopPrsUvwWx012345@
        if ($buffer =~ /^\:(.+?)\sMODE\s(.+?)\s:+(.+?)$/)
        {
            $thenick = $1;
            $thetarget = $2;
            $params = $3;
            $params =~ s/^\://;
            checkmodes($thetarget,$params);
            $thenick = quotemeta($thenick);
            $thetarget = quotemeta($thetarget);
            $params = quotemeta($params);
            foreach $mod (@modlist) {
                my $func = ("Modules::Scan::" . $mod . "::handle_mode(\"$thenick\",\"$thetarget\",\"$params\")");
                eval $func;
            }
        }
        # :[Brain] KILL Defender :NetAdmin.chatspike.net![Brain] (kill test)
        # HMM seems we don't issue a notice when kills happen with dancer... damn. :(
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
        # << :jstuart QUIT :Client Quit
        if ($buffer =~ /^\:(.+?)\sQUIT\s:(.+?)$/)
        {
            my $quitnick = $1;
            my $quitreason = $2;
            delete $hosts{$quitnick};
        }

        # :[Brain] TOPIC #chatspike [Brain] 1099522169 :moo moo
        if ($buffer =~ /^\:(.+?)\sTOPIC\s(.+?)\s\S+\s\d+\s:(.+?)$/)
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

        # << :irc.adultchatnetwork.com SJOIN 1082356999 #test1 + :@jstuart
        if ($buffer =~ /^:(.+?)\sSJOIN\s[0-9]+\s(.+)$/)
        {
            $thenick = $1;
            $thetarget = $2;
            $thenick = quotemeta($thenick);
            $thetarget = quotemeta($thetarget);
            foreach $mod (@modlist) {
                my $func = ("Modules::Scan::" . $mod . "::handle_join(\"$thenick\",\"$thetarget\")");
                eval $func;
            }
        }
        # << :FurBall PART #acn-ops :"I'm MELTING... I'm MELTING... AHHHH"
        if ($buffer =~ /^\:(.+?)\sPART\s(.+?)$/)
        {
            $thenick = $1;
            $thetarget = $2;
            if ($thetarget =~ / /) {
                $thetarget = split(" ",$thetarget);
            }
            $thenick = quotemeta($thenick);
            $thetarget = quotemeta($thetarget);
            foreach $mod (@modlist) {
                my $func = ("Modules::Scan::" . $mod . "::handle_part(\"$thenick\",\"$thetarget\")");
                eval $func;
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
            #$NETJOIN = 0;
            print "$njservername completed NETJOIN state\n";
        }
        if ($buffer =~ /^:(.+?)\sNOTICE\s(.+?)\s:(.+?)$/)
        {
            &noticehandler($buffer);
        }
        # << :FurBall PRIVMSG #ircops-private :test1
        elsif ($buffer =~ /^:(.+?)\sPRIVMSG\s(.+?)\s:(.+?)$/) {
            &msghandler($buffer);
        }
        elsif ($buffer =~ /^:(.+) WHOIS (.+) :.+$/) {
            $source = $1;
            # :bender.chatspike.net 320 [Brain] [Brain] :has whacked 33 virus drones
            &rawirc(":$servername 311 $source $botnick $botnick $domain * :$botname");
                        &rawirc(":$servername 312 $source $botnick $servername :$serverdesc");
            &rawirc(":$servername 313 $source $botnick :Is a network service");
                        &rawirc(":$servername 318 $source $botnick :End of /WHOIS list.");

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
    print "SIGINT caught\n";
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
