use strictures 1;
use Test::More;
use Data::Dumper::ToXS::Test;
use Data::Dumper;
use Devel::Peek qw(SvREFCNT);
use Scalar::Util qw(isweak);

my @fix = do 't/fixtures.pl' or die "t/fixtures.pl: $@";

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Deparse = 1;

my (%source, %result);

foreach my $f (@fix) {
  my $d = Dumper($source{$f->[0]} = $f->[1]);
  my $l = Dumper($result{$f->[0]} = Data::Dumper::ToXS::Test->can($f->[0])->());
  is($l, $d, "Round tripped ${\$f->[0]} ok");
}

{
  my $r = $result{weaken_1};
  ok(isweak($r->[1]), 'Weak element is weak');
  is(SvREFCNT(${$r->[1]}), 2, 'Refcount of target correct');
}

done_testing;
