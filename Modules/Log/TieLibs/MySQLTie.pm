# $Id: MySQLTie.pm 867 2005-03-02 00:49:13Z reed $

package Modules::Log::TieLibs::MySQLTie;

use DBI;

my $dbh;

sub DoWriteSQL {
	print "DoWriteSQL called";
	my $line = $_[0];
	my $sth = $dbh->prepare("INSERT INTO defender_log VALUES ('" . localtime() . "','$line','')");
	$sth->execute() or print "$DBI::errstr\n";
	$sth->finish();
}

sub WRITE {
	my $r = shift;
	my($buf,$len,$offset) = @_;
	DoWriteSQL($buf);
}

sub PRINTF {
        shift;
        my $fmt = shift;
        DoWriteSQL(sprintf($fmt, @_)."\n");
}


sub TIEHANDLE {
	print "TIEHANDLE called\n";
	my $class = shift;
	my $fh = local *FH;
	bless \$fh, $class;
	my ($db_host,$db_database,$db_user,$db_pass) = @_;
	my $data_source = "DBI:mysql:$db_database:$db_host";
	print "Logging into mysql database $db_host ($db_database) for MySQL logging...";
	$dbh = DBI->connect($data_source, $db_user, $db_pass) or print "$DBI::errstr\n";
	print "Done!\n";
	$| = 1;
	DoWriteSQL("test test!");
	\$class;
}

sub READLINE {
	return 1;
}

sub PRINT {
	print "PRINT handler called\n";
	my $class = shift;
	DoWriteSQL(join('', @_));
	1;

}

sub OPEN {
	print "OPEN handler called\n";
	# always succeeds
	return 1;
}

1;
