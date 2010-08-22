# Auth module by Whitewolf
# This auth module does the following:
# auth by nickname from a conf file (accesslist.conf) by level.
# confirm authed with nickserv (todo)
# confirm oper mode needed (todo)
# writes to accesslist.conf in the main directory with the simple format of:
# username,level

# Authmodes - Check for needed oper modes.
sub authmodes
{
        my ($nick,$target,$params) = @_;
	return 1;
}

# Authcheck - Check for access level of user.
# (todo) confirm identified with nickserv
sub authcheck
{
	my ($nick,$level,$oper) = @_;
	my $nick_lower = lc($nick);
	if ($authlist{$nick_lower} >= $level) {
		main::message("$nick $authlist{$nick_lower} $level SUCCESS") if $debug;
		return 1;
	} else {
		main::message("$nick $authlist{$nick_lower} $level FAILURE") if $debug;
		return 0;
	}
	return 0;
}

# Authstats - Info block
sub authstats {
	our $count = 0;
	main::message(sprintf("%-32s  %-6s","Username","Level"));
	foreach our $key (keys %authlist) {
	main::message(sprintf("%-32s  %-6d",$key,$authlist{$key}));
	$count++;
	}
	main::message("$count Total users.");
}

# Authreload - reload the accesslist from the file.
sub authreload {
	%authlist = ();
	open(FIH,"<$main::dir/accesslist.conf") or die "Auth: accesslist.conf open failed!";
        while ($authline = <FIH>)
        {
                $authline = lc($authline);
                if (length($authline)>2)
                {
                        my ($nick,$level) = split(/\,/,$authline);
                        chop($level);
                        $authlist{$nick} = $level;
                }
        }
        close FIH;
}

# This is to handle the authcmds subset.
sub auth_handle_privmsg {
        my($nick,$chan,$msg) = @_;

        return if($chan !~ /^\Q$main::mychan\E$/i);
                                                                                                                       
        if($msg =~ /^authcmds\s+/) {
                                                                                                                       
                $msg =~ s/^authcmds\s+//;
                                                                                                                       
                if($msg =~ /^list/i) {
                        main::authstats;
                        return;
                                                                                                                       
                }

                if($msg =~ /^adduser (\S+) (\d+)$/i) {
                        $authlist{lc($1)} = $2;
                        dump_users;
                        main::message("Added $1 to access list with level $2.");
                        return;
                }
                                                                                                                       
                if($msg =~ /^deluser (\S+)$/i) {
                        foreach my $key (keys %authlist) {
                                if($key eq lc($1)) {
                                        delete $authlist{$1};
                                        dump_users;
                                        main::message("Removed $1 from access list.");
                                        return;
                                }
                        }
                        main::message("$1 isn't on the access list!");
                        return;
                }
	}
}

sub dump_users {
                                                                                                                       
        open(ACL, ">$main::dir/accesslist.conf");
                                                                                                                       
        foreach my $key (keys %authlist) {
                                                                                                                       
                print ACL "$key,$authlist{$key}\n";
                                                                                                                       
        }
	close(ACL);
}

# Authinit - Initialize the auth lists.
sub authinit {
 
        if (!main::depends("core-v1")) {
                print "This module requires version 1.x of defender.\n";
                exit(0);
        }
        main::provides("authcheck");
 
        open(FIH,"<$main::dir/accesslist.conf") or die "Auth: accesslist.conf open failed!";
        while ($authline = <FIH>)
        {
                $authline = lc($authline);
                if (length($authline)>2)
                {
			my ($nick,$level) = split(/\,/,$authline);
			chop($level);
                        $authlist{$nick} = $level;
                }
        }
        close FIH;
}

1;
