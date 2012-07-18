# $Id: Text.pm 300 2004-03-18 00:31:41Z reed $

package Modules::Log::Text;

# Nice simple one to illustrate the concept behind logging methods
# init is called on startup

sub init {
	# for now, open a hardcoded file defender.log
	our $filename = $main::dataValues{"logpath"};
	open STDOUT, ">>$filename";
	open STDERR, ">&STDOUT";
}

sub shutdown {
	close STDOUT;
}

1;
