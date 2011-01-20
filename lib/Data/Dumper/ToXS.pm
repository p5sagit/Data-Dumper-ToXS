package Data::Dumper::ToXS;

our (%ix, %seen, $weaken);

sub _newix { $_[0].'['.($ix{$_[0]}++).']' }
sub _getglob { \*{$_[0]} }

use B qw(svref_2object cstring);
use Scalar::Util qw(refaddr isweak);
use Moo;

has target_package => (is => 'ro', required => 1);

has _to_generate => (is => 'ro', default => sub { [] });

sub add_generator {
  my ($self, $name, $ref) = @_;
  die "Generation target must be a reference" unless ref($ref);
  push(@{$self->_to_generate}, [ $name => $ref ]);
}

sub xs_code {
  my ($self) = @_;
  my @do = @{$self->_to_generate};
  join "\n\n", $self->_preamble,
    (map $self->_generate_target(@$_), @do),
    $self->_package_start($self->target_package),
    (map $self->_generate_xsub($_->[0]), @do);
}

sub _preamble {
  <<'END';
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

END
}

sub _package_start {
  my ($self, $package) = @_;
  <<"END";
MODULE = ${package} PACKAGE = ${package}

PROTOTYPES: DISABLE

END
}

sub _generate_xsub {
  my ($self, $name) = @_;
  <<"END";
SV *
${name}()
  CODE:
    RETVAL = ${name}(aTHX);
  OUTPUT:
    RETVAL
END
}

sub _generate_target {
  my ($self, $name, $ref) = @_;
  local %ix = map +($_ => 0), qw(av hv sv);
  local %seen;
  local $weaken = '';
  my $first = _newix('sv');
  my $body = $self->_dump_svrv($first, $ref);
  my $vars = join '', map +(
    $ix{$_} ? "  ${\uc}* ${_}[$ix{$_}];\n" : ""
  ), qw(av hv sv);
  <<"END";
SV * ${name} (pTHX)
{
${vars}${body}${weaken}  return ${first};
}
END
}

sub _dump_svrv {
  my ($self, $ix, $ref) = @_;
  my $r = ref($ref);
  $weaken .= "  sv_rvweaken(${ix});\n" if isweak($_[2]);
  if ($seen{$ref}) {
    # already seen this reference so make a copy
    "  ${ix} = newSVsv($seen{$ref});\n";
  } else {
    $seen{$ref} = $ix;
    if ($r eq 'SCALAR') {
      my $t_ix = _newix('sv');
      join '',
        $self->_dump_sv($t_ix, $ref),
        "  ${ix} = newRV_noinc(${t_ix});\n";
    } elsif ($r eq 'HASH') {
      my $t_ix = _newix('hv');
      join '',
        $self->_dump_hv($t_ix, $ref),
        "  ${ix} = newRV_noinc((SV *)${t_ix});\n";
    } elsif ($r eq 'ARRAY') {
      my $t_ix = _newix('av');
      join '',
        $self->_dump_av($t_ix, $ref),
        "  ${ix} = newRV_noinc((SV *)${t_ix});\n";
    } elsif ($r eq 'REF') {
      my $t_ix = _newix('sv');
      join '',
        $self->_dump_svrv($t_ix, $$ref),
        "  ${ix} = newRV_noinc(${t_ix});\n";
    } elsif ($r eq 'CODE') {
      my $full_name = join '::',
        map $_->NAME, map +($_->GV->STASH, $_->GV), svref_2object($ref);
      if (*{_getglob($full_name)}{CODE}||'' eq $ref) {
        # GV_ADD strikes me as more likely to DWIM than to simply blow up
        # if the generated routine gets called before the method is declared.
        "  ${ix} = newRV_inc((SV *) get_cv(${\cstring $full_name}, GV_ADD));\n";
      } else {
        die "Can't find ${ref} at ${full_name}";
      }
    } else {
      die "Can't handle reftype ${r}";
    }
  }
}

sub _dump_sv {
  my ($self, $ix, $ref) = @_;
  if (ref($$ref)) {
    $self->_dump_svrv($ix, $$ref);
  } else {
    # Not a reference. What are we dumping?
    my $sv = svref_2object($ref);
    if (!defined($$ref)) {
      "  ${ix} = newSVsv(&PL_sv_undef);\n";
    } elsif ($sv->isa('B::IV')) {
      "  ${ix} = newSViv(".$sv->int_value.");\n";
    } elsif ($sv->isa('B::NV')) {
      "  ${ix} = newSVnv(".$sv->NV.");\n";
    } elsif ($sv->isa('B::PV')) {
      "  ${ix} = newSVpvs(".cstring($$ref).");\n";
    } else {
      die "Unsure how to dump ".$$ref;
    }
  }
}

sub _dump_hv {
  my ($self, $ix, $ref) = @_;
  join '',
    "  ${ix} = newHV();\n",
    map {
      my $t_ix = _newix('sv');
      ($self->_dump_sv($t_ix, \($ref->{$_})),
      "  hv_stores(${ix}, ${\cstring $_}, ${t_ix});\n")
    } sort keys %$ref;
}

sub _dump_av {
  my ($self, $ix, $ref) = @_;
  join '',
    "  ${ix} = newAV();\n",
    map {
      my $t_ix = _newix('sv');
      $self->_dump_sv($t_ix, \($ref->[$_])),
      "  av_push(${ix}, ${t_ix});\n"
    } 0 .. $#$ref;
}

1;
