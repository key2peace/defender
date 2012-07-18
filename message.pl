#!/usr/bin/perl
# $Id: message.pl 11965 2009-10-24 17:48:23Z brain $

#use warnings;
#use strict;

# Input should be as follows:
# :nick!ident@hostname NOTICE Defender :Some stuff here
# :nick NOTICE Defender :Some stuff here
sub noticehandler {
	my $raw = shift;

	$raw =~ /^:(.+?)\sNOTICE\s(.+?)\s:(.+?)$/xi or print "Bad input to noticehandler: $raw\n";
	
	my ($sNick, $sIdent, $sHost, $target, $message) = ($1, '', '', $2, $3);

	if($sNick =~ /^([^!]+)!([^@]+)\@(\S+)/) {
		$sNick = $1;
		$sIdent = $2;
		$sHost = $3;
	}

	if (lc($target) eq lc($botnick)) {
		$target = $sNick; # Don't want to talk to myself
	}

	$message = quotemeta($message);
	$sNick = quotemeta($sNick);
	$sIdent = quotemeta($sIdent);
	$sHost = quotemeta($sHost);
	$target = quotemeta($target);
	
	foreach my $mod (@modlist) {
		my $func = ("Modules::Scan::" . $mod . "::handle_notice(\"$sNick\",\"$sIdent\",\"$sHost\",\"$target\",\"$message\")");
		eval $func;
		print $@ if $@;
	}
}


sub msghandler {
	my $raw = shift;

	# Fixed by brain
	$raw =~ /^:(.+?)\sPRIVMSG\s(.+?)\s:(.+?)$/xi or print "Bad input to msghandler: $raw\n";

	my ($sNick, $sIdent, $sHost, $target, $message) = ($1, '', '', $2, $3);

	if($sNick =~ /^([^!]+)!([^@]+)\@(\S+)/) {
		$sNick = $1;
		$sIdent = $2;
		$sHost = $3;
	}

	if ($target eq $botnick) { # *FIXME* Mysterious globals like $botnick should be in all caps or something
		$target = $sNick; # Don't want to talk to myself
	}

	my $sMessage = quotemeta($message);
	$sNick = grep (/^uuidnick$/, @provides) ? $uuidnick{quotemeta($sNick)} :
	         quotemeta($sNick);
	$target = quotemeta($target);

	foreach my $mod (@modlist) {
		my $func = ("Modules::Scan::" . $mod . "::handle_privmsg(\"$sNick\",\"$sIdent\",\"$sHost\",\"$target\",\"$sMessage\")");
		eval $func;
		print $@ if $@;
	}
	
	# Added hook for handling privmsg authcmds subset.
	#my $func = ("main::auth_handle_privmsg(\"$sNick\",\"$target\",\"$sMessage\")");
	#eval $func;
        #print $@ if $@;


	if (lc($target) eq quotemeta(lc($mychan)))
	{
		if (lc($message) eq lc("$botnick quit")) {
			&shutdown;
			return;
		}

		if ($message =~ /^status all/i) {
			message("\002IRC Defender Status\002");
			message(" ");
			message("Using \002$CONNECT_TYPE\002 protocol module.");
			message(" ");
			foreach my $mod (@modlist) {
				message("Module: \002$mod\002");
				message(" ");
				my $func = ("Modules::Scan::" . $mod . "::stats");
				eval $func;
				print $@ if $@;
				message(" ");
			}
			my $modtotal = $#modlist+1;
			message("Total of \002$modtotal\002 modules loaded.");
			return;
		}

		# added for status of auth only.
		#if ($message =~ /^status auth/i) {
		#	message("\002IRC Defender Status\002");
		#	message(" ");
		#	message("Using \002$CONNECT_TYPE\002 protocol module.");
		#	message(" ");
		#	my $func = ("main::authstats");
		#	eval $func;
		#	print $@ if $@;
		#	return;
		#}

		# added for hook to reload from auth file.
		#if ($message =~ /^\Q$botnick reloadauth\E$/i) {
		#	message("Reloading access list...");
		#	&authreload;
		#	message("Reload complete.");
		#}

		if ($message =~ /^\Q$botnick rehash\E$/i) {
			message("Rehashing...");
			&rehash;
			foreach my $line (@rehash_data) {
				message($line);
			}
			message("Rehash complete.");
		}

		if ($message =~ /^status/i) {
			message("\002IRC Defender Status\002");
			if ($message !~ /^status\s+(\S+)$/i)
			{
                                message("\002$KILLED\002 clients have been killed, from a total of \002$CONNECTS\002 total connections.");
                                my $delta = time - $START_TIME;
                                my $weeks = int($delta/(7*24*60*60));
                                my $days = int($delta/(24*60*60));
                                my $hours = ($delta/(60*60))%24;
                                my $mins = ($delta/60)%60;
                                my $secs = $delta%60;
                                                                                                                          
                                undef $uptime;
                                if ($weeks){$uptime .= $weeks =~ /^1$/ ? "$weeks week, " : "$weeks weeks, ";}
                                if ($days){$uptime .= $days =~ /^1$/ ? "$days day, " : "$days days, ";}
                                if ($hours){$uptime .= $hours =~ /^1$/ ? "$hours hour, " : "$hours hours, ";}
                                if ($mins){$uptime .= $mins =~/^[01]$/ ? "$mins min, " : "$mins mins, ";}
                                $uptime .= $secs =~ /^[01]$/ ? "$secs sec" : "$secs secs";

				message("Uptime: \002$uptime\002.");
				
				my $modlist = join(", ",@modlist).', '.lc($CONNECT_TYPE);
				message("Loaded modules: \002$modlist\002");
				
				$features = join(", ",@provides);
				message("Features provided: \002$features\002");
			} else {
				$message =~ /^status\s+(\S+)$/i;
				my $module = $1;
				print "Module: '$1'\n";
				message(" ");
				message("Using \002$CONNECT_TYPE\002 protocol module.");
				message(" ");
				
				foreach my $mod (@modlist) {
					if (($module eq "") || ($mod =~ /^\Q$module\E$/i)) {
						message("Module: \002$mod\002");
						message(" ");
						my $func = ("Modules::Scan::" . $mod . "::stats");
						eval $func;
						print $@ if $@;
						message(" ");
					}
				}
				
				my $modtotal = $#modlist+1;
				message("Total of \002$modtotal\002 modules loaded.");
			}
		}
	}
}


1;
