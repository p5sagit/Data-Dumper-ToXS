use strictures 1;
use Test::More;
use Data::Dumper::ToXS::Test;
use Data::Dumper;

my @fix = do 't/fixtures.pl' or die "t/fixtures.pl: $@";

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Deparse = 1;

my (%source, %result);

foreach my $f (@fix) {
  my $d = Dumper($source{$f->[0]} = $f->[1]);
  my $l = Dumper($result{$f->[0]} = Data::Dumper::ToXS::Test->can($f->[0])->());
  is($l, $d, "Round tripped ${\$f->[0]} ok");
}

done_testing;
