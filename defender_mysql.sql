# If you are going to use the Mysql logging module, you must
# run this sql script on the database you are going to use to
# create your defender logging table.
# $Id: defender_mysql.sql 300 2004-03-18 00:31:41Z reed $

CREATE TABLE defender_log (
  itemtime time NOT NULL default '00:00:00',
  details text NOT NULL,
  id bigint(20) unsigned NOT NULL default '0',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

