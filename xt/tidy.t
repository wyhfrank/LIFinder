#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

eval "use Test::PerlTidy";
plan skip_all => 'Test::PerlTidy required' if $@;

run_tests();
