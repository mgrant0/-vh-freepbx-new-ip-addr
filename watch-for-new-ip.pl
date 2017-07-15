#!/usr/bin/perl

# Written by Michael Grant
# Ths script is Public Domain.  Do what you want with this.  
# It may or may not work for you.  Unsupported.  No warranty.
# Always keep your keys secret and secure.
#
# This perl script is to be run in cron.  It checks your dynamic ip
# address to see when it changes.  When it changes, it does 2 things:
# 1. it connects to the OVH API and updates your IP restriction and
# 2. it prods asterisk (freepbx in my case) to reload the dialplan
# Without this script, it required manual intervention both in freepbx
# and in my OVH account to get my phone working again.

# Instructions for use:
# 1. cpan -i OVH::OvhApi
# 2. follow instructions here to get an api key: https://api.ovh.com/g934.first_step_with_api to get a CK
# 3. copypaste the validationUrl into a browser, log in to OVH and validate your keys
# 3. configure ip address, domain name and keys below
# 3. add to cron to run once a minute:
# * * * * * /usr/local/bin/watch-for-new-ip.pl

use strict;
use OVH::OvhApi;
use Socket;

my $AK = 'Your OVH Application Key goes here';
my $AS = 'Your OVH Secret Key goes here';
my $CK = 'Your OVH Comsumer Key goes here';
my $ID = 'Your OVH client ID goes here';
my $PN = 'Your OVH phone number goes here, usually starts with 00';
my $name = 'example.ddns.net';    # your dynamic host name
my @ipRestrictions = ();
# my @ipRestrictions = ('1.2.3.4/32');  # add static ip addresses if you want to also aways add them too
my $lastIpAddrFile = "/tmp/my-last-ip-addr";  # the file where to cache the previous ip address

# read ip address from last time to see if it changed
open(my $ipfp, '<', $lastIpAddrFile) || print "$lastIpAddrFile: $?\n";
my $lastIp = <$ipfp>;
close($ipfp);

# look up dynamic name
my @addresses = gethostbyname($name)   or die "Can't resolve $name: $!\n";
@addresses = map { inet_ntoa($_) } @addresses[4 .. $#addresses];
my $currAddr = $addresses[0].'/32';

# if the current address == the last address we cached, then nothing to do, exit.
if ($currAddr == $lastIp) { exit;}

# Connect to OVH API and update the ip address restriction
my $Api    = OVH::OvhApi->new(type => OVH::OvhApi::OVH_API_EU, 
			      applicationKey => $AK, 
			      applicationSecret => $AS, 
			      consumerKey => $CK);

# add current IP
push(@ipRestrictions, $currAddr);

# Set current address ip address restriction at OVH
my $Answer = $Api->put(path => "/telephony/$ID/line/$PN/options", 
		       body => {'ipRestrictions' => [@ipRestrictions]});

if ($Answer) {
    # Success: can fetch content and process
    my $content = $Answer->content;
    print "PUT $PN/options/ipRestrictions {@ipRestrictions}: success\n";
} else {
    # Request failed: stop here and retrieve the error
    my $error = $Answer->error;
    die "error PUT $PN/options/ipRestrictions {@ipRestrictions}: $error";
}

# update LastIpAddrFile
open(my $ipfp, '>', $lastIpAddrFile) || die "$lastIpAddrFile";
print $ipfp $currAddr;
close($ipfp);

# update Asterisk
# Note: asterisk for some reason does not automatically sense a new
# dynamic ip address, it needs to be prodded.  Not sure why.
system("asterisk -rx 'dialplan reload'");
