#!/usr/bin/env perl

use lib 'lib';
use Data::Dumper::ToXS;

open my $out, '>', $ARGV[0] or die "fail: $!";

my $ddxs = Data::Dumper::ToXS->new(
  target_package => 'Data::Dumper::ToXS::Test'
);

my @fix = do 't/fixtures.pl' or die "t/fixtures.pl: $@";

$ddxs->add_generator(@$_) for @fix;

print $out $ddxs->xs_code;
