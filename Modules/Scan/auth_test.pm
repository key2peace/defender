# This is just to test auth processes. 
# It's JUST for testing and development and should NOT
# be loaded in production cases.

package Modules::Scan::auth_test;

use strict;
use warnings;

sub handle_topic
{
}

sub stats {
	main::message("Auth Test Module");
}


sub handle_join
{

}

sub handle_part
{

}

sub handle_mode
{

}

sub scan_user
{
	my ($ident,$host,$serv,$nick,$gecos,$print_always) = @_;
}

sub handle_notice
{
	my ($nick,$ident,$host,$chan,$notice) = @_;
}

sub handle_privmsg
{
        my ($nick,$ident,$host,$chan,$msg) = @_;

        if($msg =~ /^auth_test\s+/) {
                                                                                                                       
                $msg =~ s/^auth_test\s+//;
                                                                                                                       
                if (($msg =~ /^add (\S+) (.+)$/i) && (main::authcheck($nick,4))){
                                                                                                                       
                        main::message("Added $1 to auth_test. v1");
                        return;
                                                                                                                       
                }
    	}

}

sub init {

        if (!main::depends("core-v1")) {
                print "This module requires version 1.x of defender.\n";
                exit(0);
        }
        main::provides("auth_test");

}

1;
