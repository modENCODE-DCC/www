#!/usr/bin/perl

print "Content-type: text/plain\n\n";
print "Allo, user.\n";

if(exists $ENV{MOD_PERL}) {
  print "We're running under mod_perl.\n";
} else {
  print "We're NOT running under mod_perl.\n";
}

