# $Id: Main.pm 9859 2008-06-06 23:22:49Z Thunderhacker $

use Socket;

our $KILLED;
our $CONNECTS;
our $START_TIME;
our $curdir;

our @provides = ();

sub depends
{
	print "Checking depends: @_\n" if $debug;
	foreach my $t (@_) {
		if ($t ne '') {
			my $satisfy = 0;
			foreach my $token (@provides) {
				if ($token eq $t) {
					$satisfy = 1;
				}
			}
			if (!$satisfy) {
				return 0;
			}
		}
	}
	return 1;
}

sub provides
{
	print "Adding provides: @_\n" if $debug;
	foreach my $t (@_) {
		if ($t ne '') {
			if (depends($t)) {
				print "\n\nERROR! Two modules are providing the same features (token: $t)\n";
				print "You probably have the same module loaded twice, or a feature conflict!\n";
				print "Bailing...\n";
				exit(0);
			}
			push @provides,$t;
		}
	}
}

sub general_init
{
	if ($0 =~ /(^\/.*?)[^\/]*$/){
		# if called with fullpath or if script is in a ENV{PATH}-directory
		$curdir=$1;
	}
	else {
		$0 =~ /(.*?)[^\/]*$/;
		$curdir=$ENV{PWD}."/".$1;
	}
	print "IRC Defender version $VERSION ($DATE)\n\n";
	print "Programmed by C.J.Edwards (Brain) - irc.chatspike.net\n";
	print "Numerous fixes and modules by Whitewolf, typobox43, ol, Jay, Azhrarn\n\n";
	$START_TIME = time;
}

sub load_config
{
	print "Loading configuration file...\n";
	push @rehash_data, "Loading configuration file...";

        @provides = ();
        provides("core-v1");

	$cfg = "$curdir/defender.conf";
	$dir = $curdir;
	open (CONFIG, $cfg) or die "Can't locate config file! ($cfg): $!";
	while (chomp($pair=<CONFIG>))
	{
		if ($pair =~ /(\0x0D|\0x0A)$/) {
			# try to repair windows linefeeds in the config
			chop($pair);
		}
	        ( $var, $val ) = split ( "=", $pair );  # Split name/value pairs
	        $val =~ s/%(..)/pack("c",hex($1))/ge;   # Replace %nn with char
	        $dataValues{"$var"} = "$val";
	}
	close(CONFIG);
	$domain = $dataValues{"domain"};
	$nspass = $dataValues{"nickserv"};
	$dir = $dataValues{"datadir"};
	$killurl = $dataValues{"url"};
	$killmail = $dataValues{"mail"};
	$server = $dataValues{"server"};
	$server_re = $dataValues{"servregexp"};
	$botnick = $dataValues{"botnick"};
	$mychan = $dataValues{"channel"};
	$quitmsg = $dataValues{"quitmsg"};
	$port = $dataValues{"port"};
	$paranoia = $dataValues{"paranoia"};
	$botname = $dataValues{"fullname"};
	$oname = $dataValues{"opername"};
	$opass = $dataValues{"operpass"};
	$password = $dataValues{"password"};
	$netname    = $dataValues{"networkname"};
	$servername = $dataValues{"servername"};
	$numeric    = $dataValues{"numeric"};
	$serverdesc = $dataValues{"serverdesc"};
	$linkmodule = $dataValues{"linktype"};
	#$authmodule = $dataValues{"authtype"};
	$logger = $dataValues{"logto"};
	$supportchannel = $dataValues{"supportchannel"};
	$OneWord = $dataValues{"OneWord"};
	$ugly = $dataValues{"ugly"};
	$version_verbose = $dataValues{"version_verbose"};
	$sid = $dataValues{"sid"};
}


sub reinit_modules
{
	&link_init;

	my @removed;
	my @added;
	my @unchanged;

	$modules = $dataValues{"modules"};
	our @modlist = split(",",$modules);
	
	foreach my $mod (@modlist) {
		my $added = 1;
		foreach my $old (@oldmods) {
			if ($old eq $mod) {
				$added = 0;
			}
		}
		if ($added == 1) {
			push @added, $mod;
		}
	}	

	foreach my $mod (@oldmods) {
		my $removed = 1;
		foreach my $new (@modlist) {
			if ($new eq $mod) {
				$removed = 0;
			}
		}
		if ($removed == 1) {
			push @removed, $mod;
		}
	}

	foreach my $mod (@modlist) {
		my $unchanged = 1;
		foreach my $n (@removed) {
			if ($mod eq $n) {
				$unchanged = 0;
			}
		}
		foreach my $n (@added) {
			if ($mod eq $n) {
				$unchanged = 0;
			}
		}
		if ($unchanged == 1) {
			push @unchanged, $mod;
		}
	}

	print "Rehashing.\nAdded: @added Removed: @removed Unchanged: @unchanged\n\n";

	foreach $mod (@removed) {
		print "Unloading: Modules/Scan/$mod.pm... ";
		push @rehash_data, "Unloading: Modules/Scan/$mod.pm... ";
		my $func = "no Modules::Scan::" . $mod;
		eval $func;
		print $@ if $@;
		if ($@) { push @rehash_data, $@; }
		print "OK!\n";
	}

	foreach $mod (@added) {
		print ("Loading: Modules/Scan/$mod.pm... ");
		push @rehash_data, "Loading: Modules/Scan/$mod.pm... ";
		require "$curdir/Modules/Scan/$mod.pm";
		my $func = "Modules::Scan::" . $mod . "::init";
		eval $func;
		print $@ if $@;
		if ($@) { push @rehash_data, $@; }
		print "OK!\n";
	}

	foreach $mod (@unchanged) {
		print ("Re-initializing: Modules/Scan/$mod.pm... ");
		push @rehash_data, "Re-initializing: Modules/Scan/$mod.pm... ";
		my $func = "Modules::Scan::" . $mod . "::init";
		eval $func;
		print $@ if $@;
		if ($@) { push @rehash_data, $@; }
		print "OK!\n";
	}	
}

sub init_modules
{
	open(CHECK,"$curdir/Modules/Link/$linkmodule.pm") or &barf("Link",$linkmodule);
	close(CHECK);
	require "$curdir/Modules/Link/$linkmodule.pm";
	print ("Using $linkmodule connection module (loaded OK)...\n");
	&link_init;

	print ("\nLoading modules...\n");

	# added to load in auth module.
	# This is still under development so is not operating in this version
	#require "Modules/Auth/$authmodule.pm";
	#print ("Using $authmodule module for Authentication (loaded OK)...\n");
	#&authinit;

	$modules = $dataValues{"modules"};
	our @modlist = split(",",$modules);
	foreach $mod (@modlist) {
	        print ("Loading: Modules/Scan/$mod.pm... ");
		open(CHECK,"$curdir/Modules/Scan/$mod.pm") or &barf("Scan",$mod);
		close(CHECK);
	        require "$curdir/Modules/Scan/$mod.pm";
		my $func = "Modules::Scan::" . $mod . "::init";
	        eval $func;
		print ("OK!\n");
	}

	open(CHECK,"$curdir/Modules/Log/$logger.pm") or &barf("Log",$logger);
	close(CHECK);
	require "$curdir/Modules/Log/$logger.pm";
	if (!$debug)
	{
		print "Switching to $logger logging method from now\n";
		#my $startup = ("Modules::Log::" . $logger . "::init");
		eval "Modules::Log::$logger"->init();
		print $@ if $@;
	}
	else
	{
		print "Not enabling logging module because debugging is enabled\n";
		print "Will log to console.\n";
	}
}

sub rehash
{
	chdir $dir;
	our @rehash_data = ();
	our @oldmods = @modlist;
	main::load_config;
	main::reinit_modules;
	chdir '/';
}

sub check_params
{
	use Getopt::Long;
	GetOptions("debug" => \$debug, "help" => \$help);

	if (defined($help))
	{
		print <<CRUD;

--debug                Don't daemonize, display all raw I/O on console
--help                 Display this help text

IRC Defender (C) ChatSpike Development Team 2004-2005

IRC Defender comes with ABSOLUTELY NO WARRANTY; for details
read the file docs/COPYING. This is free software, and you
are welcome to redistribute it under certain conditions.
Again, see the license (GPL) for details.

CRUD
               exit(0);
		
	}
	if (defined($debug))
	{
		$debug = 1;
	}
	else
	{
		$debug = 0;
	}
}

sub writepid {
        $pidfile = "$curdir/defender.pid";
        open(PIDFILE, ">$pidfile");
        print PIDFILE "$$";
        close(PIDFILE);
};

sub daemon
{
	use POSIX qw(setsid);

	if (!$debug)
	{
		chdir '/'                 or die "Can't chdir to /: $!";
		umask 0;
		open STDIN, '/dev/null'   or die "Can't read /dev/null: $!";
		open STDERR, '>/dev/null' or die "Can't write to /dev/null: $!";
		defined(my $pid = fork)   or die "Can't fork: $!";
		exit if $pid;
		setsid                    or die "Can't start a new session: $!";
	}

	$SIG{'INT'} = 'shutdown';
	$SIG{'HUP'} = 'rehash';

       main::writepid;
}
                                                                                                                         
sub barf {
	my($type,$name) = @_;
	print <<EOSPAM;


ERROR: Cannot find the $type module you specified in your configuration 
file. It is possible that you specified the wrong name, or you edited 
your config file on windows then uploaded it to a unix machine and have 
a linefeed character in your filename because of it. If this is the 
case, edit your config file again from scratch on a unix (linux, freebsd etc)
machine where you are going to run the program.

Of course, it is equally possible that the filename you specified just
doesn't exist.

Specified $type module: $name

EOSPAM

	exit(0);
}

1;
