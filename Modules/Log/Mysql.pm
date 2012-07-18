# $Id: Mysql.pm 300 2004-03-18 00:31:41Z reed $

package Modules::Log::Mysql;

use Modules::Log::TieLibs::MySQLTie;

# Nice simple one to illustrate the concept behind logging methods
# init is called on startup

sub init {
	tie *DUPHANDLE, "Modules::Log::TieLibs::MySQLTie", $main::dataValues{"db_hostname"}, $main::dataValues{"db_database"}, $main::dataValues{"db_username"}, $main::dataValues{"db_password"};
	open DUPHANDLE, "";
	print DUPHANDLE "Test";
	open STDOUT, ">&DUPHANDLE";
	#open STDERR, ">&DUPHANDLE";
}

sub shutdown {
	close STDOUT;
}

1;
