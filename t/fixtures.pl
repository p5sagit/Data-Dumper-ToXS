use strictures 1;
# disable the "Useless use of anonymous list ([]) in void context"
# warning so we can perl -c this file during development
no warnings 'void';
use Scalar::Util qw(weaken);
[
  data_structure =>
  {
    sv_undef => undef,
    sv_iv => 3,
    sv_nv => 4.2,
    sv_pv => "spoon",
    ref_scalar => \"foo\nbar",
    ref_array => [ 1, \undef, "73" ],
  }
],
[
  cross_refs =>
    do {
      my ($x, $y, $z) = (\1, { two => 2 }, [ three => 3 ]);
      +{
        one => $x,
        two => $y,
        three => $z,
        inner => {
          one => $x,
        },
        inner2 => [
          three => $z,
        ]
      };
    }
],
do { sub DDXSTest::foo { 'DDXSTest::foo' } () },
[
  global_sub => { foo => \&DDXSTest::foo }
],
[
  weaken_1 => do {
    my $x = 1;
    my $y = [ \$x, \$x, \$x ];
    weaken($y->[1]);
    $y;
  }
],
[
  weaken_0 => do {
    my $x = 1;
    my $y = [ \$x, \$x, \$x ];
    weaken($y->[0]);
    $y;
  }
],
[ simple_object => { object => bless({}, 'Class') } ],
[ double_object => { o1 => bless({}, 'Class'), o2 => bless({}, 'Class') } ],
