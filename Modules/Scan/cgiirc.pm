# $Id: cgiirc.pm 9506 2008-04-14 22:16:03Z Thunderhacker $

package Modules::Scan::cgiirc;

our $cgi_connects;
our $cgi_killtotal;
my %whitelist;

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

sub stats {
    my $per = (($Modules::Scan::cgiirc::cgi_killtotal/($Modules::Scan::cgiirc::cgi_connects+0.0001))*100);
    if (length($per)>6)
    {
        $per  = substr($per,0,6);
    }
    main::message("Total clients killed:             \002$Modules::Scan::cgiirc::cgi_killtotal\002");
    main::message("Total connecting clients scanned: \002$Modules::Scan::cgiirc::cgi_connects\002");
    main::message("Percentage CGI users:             \002$per%\002");
}

my @names;

sub scan_user
{
    my ($ident,$host,$serv,$nick,$fullname,$print_always) = @_;
    my $nicksyms = 0;
    my $nicknums = 0;
    my $total = 0;
    my $status = "";

    if (($fullname =~ /^\[[0-9a-f]{8}\]../i) || ($ident =~ /^[0-9a-f]{8}$/i))
    {
        main::message_to($nick,"\001VERSION\001");
        main::message("Possible unauthorised CGI:IRC usage by $nick!$ident\@$host, \"$fullname\"");
        my $coded = "";
        if ($fullname =~ /^\[([0-9a-f]{8})\]../i)
        {
            $coded = $1;
        }
        if ($ident =~ /^([0-9a-f]{8})$/i)
        {
            $coded = $1;
        }
    }
    $Modules::Scan::cgiirc::cgi_connects++;
}

sub handle_notice
{
    my ($nick,$ident,$host,$chan,$notice) = @_;

    # ignore people who are on the whitelist
        foreach my $entry (keys %whitelist) {
                if($host =~ /$entry/i) {
            return;
        }
    }
    if ($notice =~ /\001VERSION CGI\:IRC ([^ \001]+)[^\001]*\001/)
    {
                my $version = $1;
        $Modules::Scan::cgiirc::cgi_killtotal++;
                main::message("\002Killed! Unauthorised IRC VERIFIED\002 from nickname $nick (using CGI:IRC version \002$version\002)");
        main::gline(main::gethost($nick),1200,"You are using an \002unauthorised CGI:IRC gateway\002 to connect to $main::netname. This is a form of \002open proxy\002 used to evade bans and get around firewall policies, and is therefore not allowed. Please email \002$main::killmail\002 for a list of authorised CGI:IRC proxies for connecting to $main::netname.");
    }
}

sub handle_privmsg
{
        my ($nick,$ident,$host,$chan,$msg) = @_;
}


sub init {

        if (!main::depends("core-v1")) {
                print "This module requires version 1.x of defender.\n";
                exit(0);
        }
        main::provides("cgiirc");

    %whitelist = ();
        open(WL, "<$main::dir/cgiirc.conf") or die "Missing cgiirc.conf file!";
        while(chomp($re = <WL>)) {
        if ($re ne "") {
                    $whitelist{$re} = $re;
        }
        }
        close WL;

    $cgi_killtotal = 0;
    $cgi_connects = 0;
}


1;
