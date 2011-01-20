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
]
