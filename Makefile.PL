use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'Data::Dumper::ToXS::Test',
  VERSION => 1,
);

sub MY::postamble {
  'Test.xs :: t/fixtures.pl'
}
