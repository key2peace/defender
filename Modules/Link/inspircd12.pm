# $Id: inspircd12.pm 4269 2006-07-10 13:34:24Z brain $

# This file was originally inspircd11.pm
# Modified to work with InspIRCd 1.2 by Thunderhacker

# Notes about this beta module:
# Please check SVN for the latest copy.  I will try to keep it updated nightly
# as I make progress on it.  Please don't submit patches/bugfixes as it is
# likely I will have changed the part you have worked on.  This is a work in
# progress and will change frequently.

my %hosts = ();
my $sid = $main::sid;
our $opermodes = '(o|W|H|Q|I|h)';
# create hash to track uuid <-> nick pairs
# give uuid, return nick
our %uuidnick = ();
# give nick, return uuid
our %nickuuid = ();
$uuid = $sid . "AAAAAA";

# ugly hack to get the timestamp of the control channel
# since we can't put a variable inside a regex we must build the regex into a variable
# if this is not true please clean this ugly hack up a little
my $mychanregex = "^:.+?\\sFJOIN\\s$mychan" . "\\s(.+?)\\s.+?\$";

# timestamp of the control channel (used to op the psedoclient)
my $mychants = 0;

# flag used to determine if the globops module is loaded
my $capabglobops = 0;

sub link_init
{
    srand(time);
    if (!main::depends("core-v1")) {
        print "This module requires version 1.x of defender.\n";
        exit(0);
    }
    main::provides("server","inspircd-server","native-gline","native-globops","uuidnick","nickuuid");
    print "\n";
    print "BIG FAT WARNING! BIG FAT WARNING! BIG FAT WARNING!\n";
        print " #     # ####### ####### ###  #####  ####### ###\n";
        print " ##    # #     #    #     #  #     # #       ###\n";
        print " # #   # #     #    #     #  #       #       ###\n";
        print " #  #  # #     #    #     #  #       #####    #\n";
        print " #   # # #     #    #     #  #       #         \n";
        print " #    ## #     #    #     #  #     # #       ###\n";
        print " #     # #######    #    ###  #####  ####### ### \n";
    print "BIG FAT WARNING! BIG FAT WARNING! BIG FAT WARNING!\n";
    print "\n";
    print "This link module is in a BETA state.  That means there's likely still bugs and\n";
    print "possibly a few things that don't work!\n";
    print "USE AT YOUR OWN RISK!\n";
    print "Please read the top of the module Modules/Link/inspircd12.pm for details.\n";
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
    $line = ":$sid FMODE $dest $time $line";
    &rawirc($line);
}

sub privmsg
{
    my $nick = $_[0];
    my $msg = $_[1];
    my $first = ":\$uuid PRIVMSG $nick :$msg\r\n";
    syswrite(SH, $first, length($first));
}


sub notice
{
    my $nick = $_[0];
    my $msg = $_[1];
    my $first = ":$uuid NOTICE $nick :$msg\r\n";
    syswrite(SH, $first, length($first));
}

sub message
{
    my $line = $_[0];
    $line = ":$uuid PRIVMSG $mychan :$line";
    &rawirc($line);
}

sub globops
{
    my $msg = $_[0];
    &rawirc(":$uuid SNONOTICE g :$msg");
}

sub message_to
{
    my ($dest,$line) = @_;
    $line = ":$uuid PRIVMSG $dest :$line";
    &rawirc($line);
}


sub killuser
{
    my($nick,$reason) = @_;
    &rawirc(":$uuid KILL $nickuuid{$nick} :Killed ($botnick ($reason))");
    $KILLED++;
}

sub gline
{
    my($hostname,$duration,$reason) = @_;
    &rawirc(":$uuid GLINE $hostname $duration :$reason");
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
    &rawirc("SERVER $servername $password 0 $sid :$serverdesc");
}

sub finishburst {
    $now = time();
    &rawirc(":$sid BURST $now");
    &rawirc(":$sid VERSION :IRC Defender $VERSION");

    print ("Introducing pseudoclient: $botnick...\n");
    my $now = time;
    &rawirc(":$sid UID $uuid $now $botnick $domain $domain $botnick 0.0.0.0 $now +oi :$botname");

    print ("Joining channel...\n");
    $t = time();
    &rawirc(":$sid FJOIN $mychan $t +nt :o,$uuid");

    $njservername = $servername;
    $njtime = time+10;
    $NETJOIN = 1;

    $now = time();
    &rawirc(":$sid ENDBURST $now");
}

sub pingreply {
    &rawirc(":$sid PONG " . $_[0]);
}


sub reconnect {
    close SH;
    &connect;
}

my $njtime = time+10;

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

        if ($buffer =~ /^CAPAB\s(.+?)$/)
        # Read the CAPAB line
        {
            if ($1 =~ /^MODULES\s.*?m_globops\.so.*?$/)
            # Set the globops flag if the module is loaded
            {
                $capabglobops = 1;
            }

            if ($1 =~ /^MODULES\s.*?m_invisible\.so.*?$/)
            {
                my $capabinvisible = 1;
            }

            elsif ($1 =~ /^END$/)
            # End of CAPAB lines, check if the module is loaded, print error and die if not
            {
                if ($capabglobops == 0)
                {
                    print "Defender requires the module m_globops.so to be loaded in the IRCd.\n";
                    exit(0);
                }
                if ($capabinvisible == 1)
                {
                    print("Please do not use m_invisible. Ever.");
                    die;
                }
            }
        }

        # continued ugly hack to get the timestamp of the control channel
        # now we use the regex to extract the timestamp and op the pseudoclient
        elsif ($buffer =~ /$mychanregex/ && $mychants eq 0) {
            $mychants = $1;
            &rawirc(":$uuid FMODE $mychan $mychants +o $uuid");
        }

        # set netjoin state again to squelch possible noise from verbose modules
        elsif ($buffer =~ /^:.+?\sSERVER\s.+?\s.+?\s.+?\s.+?\s:.+?$/) {
            print "Server connection detected, setting NETJOIN\n";
            $NETJOIN = 1;
            $njtime = time+10;
        }

        elsif ($buffer =~ /^:(.+?)\sPRIVMSG\s(.+?)\s:(.+?)$/) {
            &msghandler($buffer);
        }

        elsif ($buffer =~ /^SERVER\s.+?\s.+?\s(.+)\s:.+?$/)
        {
            finishburst();
        }

        elsif ($buffer =~ /^:(.+?)\sNICK\s(.+?)\s.+?$/)
        {
            $oldnick = $uuidnick{$1};
            $newnick = quotemeta($2);

            $uuidnick{quotemeta($1)}=$newnick;
            delete $nickuuid{$oldnick};
            $nickuuid{$newnick}=quotemeta($1);

            $hosts{lc($2)} = $hosts{lc($1)};

            foreach $mod (@modlist) {
                eval ("Modules::Scan::" . $mod ."::handle_nick(\"$oldnick\",\"$newnick\")");
            }
        }

        # << :144 UID 144AAAAAB 1234614139 User 10.0.0.2 10.0.0.2 TH 10.0.0.2 1234614144 + :Thunderhacker

        #                     SID         UID   TS   NICK   HOST  VHST  IDENT  IP  SIGN  MODE PARA GECOS
        elsif ($buffer =~ /^:(.+?)\sUID\s(.+?)\s.+?\s(.+?)\s(.+?)\s.+?\s(.+?)\s.+?\s.+?\s.+?\s.*?:(.+?)$/)
        #                      1           2           3      4           5                         6
        # New client introduced.  Parse the UID line and extract the parts we need
        {
            $theuuid = $2;
            $thenick = $3;
            $thehost = $4;
            $theident = $5;
            $theserver = $1;
            $thegecos = $6;
            $CONNECTS++;

            # update uuid <-> nick tracking tables
            $uuidnick{$theuuid} = $thenick;
            $nickuuid{$thenick} = $theuuid;

            $hosts{lc($thenick)} = "$theident\@$thehost";

            $thegecos = quotemeta($thegecos);
            $thenick = quotemeta($thenick);
            foreach $mod (@modlist) {
                my $func = ("Modules::Scan::" . $mod . "::scan_user(\"$theident\",\"$thehost\",\"$theserver\",\"$thenick\",\"$thegecos\",0)");
                eval $func;
                print $@ if $@;
            }
        }

        # :787AAAAAK TOPIC #Testing :"New topic!"
        elsif ($buffer =~ /^:(.+?)\sTOPIC\s(.+?)\s:(.+?)$/)
        {
            $thenick = $uuidnick{quotemeta($1)};
            $thetarget = quotemeta($2);
            $params = $3;
            $params =~ s/^\://;
            $params = quotemeta($params);
            foreach $mod (@modlist) {
                my $func = ("Modules::Scan::" . $mod . "::handle_topic(\"$thenick\",\"$thetarget\",\"$params\")");
                eval $func;
            }
        }

        # :787AAAAAK KILL 000AAAAAA :Killed (Thunderhacker (kill test))
        elsif ($buffer =~ /^:(.+?)\sKILL\s(.+?)\s:(.+?)$/)
        {
            my $killedby = $1;
            my $killnick = $2;
            my $killreason = $3;
            my $killregex = "$uuid";
            if ($killnick =~ /^$killregex$/i)
            {
                $now = time();
                &rawirc(":$sid UID $uuid $now $botnick $domain $domain $botnick 0.0.0.0 $now +oi :$botname");
                &rawirc(":$sid FJOIN $mychan $mychants * :o,$uuid");
                &rawirc(":$killedby OPERQUIT :Killed ($botnick (DON'T KILL ME!))");
                &rawirc(":$uuid KILL $killedby :Killed ($botnick (DON'T KILL ME!))");
            }
        }

        elsif ($buffer =~ /^:(.+?)\sQUIT\s:(.+?)$/)
        {
            my $quituuid = $1;
            my $quitreason = $2;

            # delete uuid|nick pair
            $quitnick = $uuidnick{$1};
            delete $uuidnick{$quituuid};
            delete $nickuuid{$quitnick};

            delete $hosts{$quitnick};
            foreach $mod (@modlist) {
                my $func = ("Modules::Scan::" . $mod . "::handle_quit(\"$quitnick\",\"$quitreason\")");
                eval $func;
            }
        }

        elsif ($buffer =~ /^:(.+?)\sJOIN\s(.+?)\s\d+$/)
        {
            $thenick = $uuidnick{quotameta($1)};
            $thetarget = $2;
            # deal effectively with multiple chan joins
            my @chanlist = split(' ',$thetarget);
            $chan = quotemeta($chanlist[0]);
            foreach $mod (@modlist) {
                my $func = ("Modules::Scan::" . $mod . "::handle_join(\"$thenick\",\"$chan\")");
                eval $func;
            }
        }

        elsif ($buffer =~ /^:.+?\sFJOIN\s(.+?)\s.+?\s.+?\s(.+?)$/)
        {
            $channel = quotemeta($1);
            $nicklist = $2;
            @nicks = split(' ',$nicklist);
            foreach my $nick (@nicks) {
                (undef,$nick) = split(',',$nick);
                foreach $mod (@modlist) {
                    my $func = ("Modules::Scan::" . $mod . "::handle_join(\"$uuidnick{$nick}\",\"$channel\")");
                    eval $func;
                }
            }
        }

        elsif ($buffer =~ /^:(.+?)\sKICK\s(.+?)\s(.+?)\s:(.+?)$/)
        {
            $nick = $uuidnick{quotemeta($1)};
            $channel = $2;
            $kicked = $uuidnick{quotemeta($3)};
            $reason = $4;
            foreach $mod (@modlist) {
                my $func = ("Modules::Scan::" . $mod . "::handle_kick(\"$nick\",\"$channel\",\"$kicked\",\"$reason\")");
                eval $func;
            }
        }

        # :787AAAAAE PART #Control :leaving
        elsif ($buffer =~ /^:(.+?)\sPART\s(.+?)\s.+?$/)
        {
            $thenick = $uuidnick{quotemeta($1)};
            $thetarget = $2;
            if ($thetarget =~ / /) {
                $thetarget = split(" ",$thetarget);
            }
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
            $buffer = ":" . $uuidnick{$1} . " NOTICE Defender :" . $3;
            &noticehandler($buffer);
        }

        elsif ($buffer =~ /^:.+?\sPING\s.+?\s.+?$/)
        {
            $buffer=~/^:.+?\sPING\s(.+?)\s(.+?)$/;
            &pingreply("$2 $1");
        }

                elsif ($buffer =~ /^:(.*?)\sOPERTYPE\s.+$/)
        # Fix by Wulf @ forums
        # Emulates the +o mode and sends to other modules
                {
            $opernick=$uuidnick{quotemeta($1)};

                        $hosts{lc($opernick)}{isoper} = 1;
            $thetarget = $opernick;
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
