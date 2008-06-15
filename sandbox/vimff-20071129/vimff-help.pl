#!/usr/bin/perl -w
#
#
use strict;

open my $fh, '>>', '/tmp/vimff-help.txt' or die;
print $fh @ARGV;
close $fh;
