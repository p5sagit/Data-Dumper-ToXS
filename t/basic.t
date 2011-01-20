use strictures 1;
use Test::More;
use Data::Dumper::ToXS::Test;
use Data::Dumper;

my @fix = do 't/fixtures.pl' or die "t/fixtures.pl: $@";

$Data::Dumper::Sortkeys = 1;

foreach my $f (@fix) {
  my $d = Dumper($f->[1]);
  my $l = Dumper(Data::Dumper::ToXS::Test->can($f->[0])->());
  is($l, $d, "Round tripped ${\$f->[0]} ok");
}

done_testing;
