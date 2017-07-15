# ovh-freepbx-new-ip-addr

Update ip address restriction at OVH when your dynamic ip address changes and reload asterisk dialplan

Written by Michael Grant

Ths script is Public Domain.  Do what you want with this.  
It may or may not work for you.  Unsupported.  No warranty.
Always keep your keys secret and secure.

This perl script is to be run in cron.  It checks your dynamic ip
address to see when it changes.  When it changes, it does 2 things:
1. it connects to the OVH API and updates your IP restriction and
2. it prods asterisk (freepbx in my case) to reload the dialplan
Without this script, it required manual intervention both in freepbx
and in my OVH account to get my phone working again.

Instructions for use:
1. cpan -i OVH::OvhApi
2. follow instructions here to get an api key: https://api.ovh.com/g934.first_step_with_api to get a CK
3. copypaste the validationUrl into a browser, log in to OVH and validate your keys
4. configure ip address, domain name and keys below
5. add to cron to run once a minute:
```* * * * * /usr/local/bin/watch-for-new-ip.pl```