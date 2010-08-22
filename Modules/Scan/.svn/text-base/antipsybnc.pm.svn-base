# antipsybnc.pm by PinkFreud
# based on antibear.pm by Thunderhacker
# based on version.pm
# Permission is granted to modify and/or distribute this file in any way,
# providing that this notice is left intact.

# Reads a predefined nicklist taken from Independent's psybnc spambots.
# If realname and nick are on the list, send a warning via globops.  If realname
# and nick are not the same, follow that with a gline.

#
# Version 0.0.1.
#

package Modules::Scan::antipsybnc;

use strict;
use warnings;

my $connects = 0;
my $killed = 0;
my $gline_hours;
my $gline_seconds;
my @psybnc_ident;

sub handle_mode {
}

sub handle_join {
}

sub handle_part {
}

sub handle_topic {
}

sub stats {
  main::message("Total PsyBNC bots killed: \002$killed\002");
  main::message("Total connecting clients scanned: \002$connects\002");
  main::message(sprintf ("PsyBNC bot percentage: %.2f%% of connecting clients",
                        ($killed / $connects) * 100));
}

sub scan_user {
  my($ident, $host, $serv, $nick, $realname, $print_always) = @_;

  if (grep (/^\Q${nick}\E$/, @psybnc_ident) &&
      grep (/^\Q${realname}\E$/, @psybnc_ident)) {
    main::globops("\002WARNING!\002  ${nick}!${ident}\@${host}:${realname} looks suspiciously like a psybnc bot!");
  
    unless ($nick eq $realname) {
      main::message("antipsybnc killing ${nick}!${ident}\@${host}:${realname}");
      $gline_hours = 24 + int rand (1 + 168 - 24);  # 1 - 7 days
      $gline_seconds = $gline_hours * 60 * 60;
      main::gline("*@" . $host, $gline_seconds, "Your client has been flagged as a trojan bot.  If you believe this is an error, please contact \002$main::killmail\002.");
      $killed++;
    }
  }

  $connects++;
}

sub handle_notice {
}


sub handle_privmsg {
}

sub init {
  if(!main::depends("core-v1")) {
    print "This module requires version 1.x of defender.\n";
    exit(0);
  }

  main::provides("antipsybnc");

  if (open (IDENT, "< $main::dir/psybnc_ident.txt")) {
    @psybnc_ident = <IDENT>;
    map { s/[\r\n]//g } @psybnc_ident;
  } else {
    print "Missing or unreadable $main::dir/psybnc_ident.txt!\n";
    exit 0;
  }

  close IDENT;
}

# Thou shalt not forget to end thy modules with 1.
1;
