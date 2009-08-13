
package Math::FastGF2::Matrix;

use 5.008000;
use strict;
use warnings;
use Carp;

use Math::FastGF2 ":ops";

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;

@ISA = qw(Exporter Math::FastGF2);
%EXPORT_TAGS = ( 'all' => [ qw( ) ],
	       );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = (  );
$VERSION = '0.02';

require XSLoader;
XSLoader::load('Math::FastGF2', $VERSION);

our @orgs=("undefined", "rowwise", "colwise");

sub new {
  my $proto  = shift;
  my $class  = ref($proto) || $proto;
  my $parent = ref($proto) && $proto;
  my %o=
    (
     rows => undef,
     cols => undef,
     width => undef,
     org => "rowwise",
     @_,
    );
  my $org;			# numeric value 1==ROWWISE, 2==COLWISE
  my $errors=0;

  foreach (qw(rows cols width)) {
    unless (defined($o{$_})) {
      carp "required parameter '$_' not supplied";
      ++$errors;
    }
  }

  if (defined($o{"org"})) {
    if ($o{"org"} eq "rowwise") {
      #carp "setting org to 1 as requested";
      $org=1;
    } elsif ($o{"org"} eq "colwise") {
      #carp "setting org to 2 as requested";
      $org=2;
    } else {
      carp "value of 'org' parameter should be 'rowwise' or 'colwise'";
      ++$errors;
    }
  } else {
    #carp "defaulting org to 1";
    $org=1;			# default to ROWWISE
  }

  if ($o{width} != 1 and $o{width} != 2 and $o{width} != 4) {
    carp "Invalid width $o{width} (must be 1, 2 or 4)";
    ++$errors;
  }

  return undef if $errors;

  #carp "Calling C Matrix allocator with rows=$o{rows}, ".
  #  "cols=$o{cols}, width=$o{width}, org=$org";
  return alloc_c($class,$o{rows},$o{cols},$o{width},$org);

}

sub new_identity {
  my $proto  = shift;
  my $class  = ref($proto) || $proto;
  my $parent = ref($proto) && $proto;
  my %o = (
	   size  => undef,
	   org   => "rowwise",	# default to rowwise
	   width => undef,
	   @_
	  );
  unless (defined($o{size}) and $o{size} > 0) {
    carp "new_identity needs a size argument";
    return undef;
  }
  unless (defined($o{width}) and ($o{width}==1 or $o{width}==2 or
				  $o{width}==4)) {
    carp "new_identity needs width parameter of 1, 2 or 4";
    return undef;
  }
  unless (defined($o{org}) and ($o{org} eq "rowwise"
				or $o{org}== "colwise")) {
    carp "new_identity org parameter must be 'rowwise' or 'colwise'";
    return undef;
  }
  my $org = ($o{org} eq "rowwise" ? 1 : 2);

  my $id=alloc_c($class,$o{size},$o{size},$o{width},$org);
  return undef unless $id;
  for my $i (0 .. $o{size} - 1 ) {
    $id->setval($i,$i,1);
  }
  return $id;
}

sub ORG {
  my $self=shift;
  #carp "Numeric organisation value is " . $self->ORGNUM;
  return $orgs[$self->ORGNUM];
}

sub multiply {
  my $self   = shift;
  my $class  = ref($self);
  my $other  = shift;
  my $result = shift;

  unless (defined($other) and ref($other) eq $class) {
    carp "need another matrix to multiply by";
    return undef;
  }
  unless ($self->COLS == $other->ROWS) {
    carp "this matrix's COLS must equal other's ROWS";
    return undef;
  }
  unless ($self->WIDTH == $other->WIDTH) {
    carp "can only multiply two matrices with the same WIDTH";
    return undef;
  }

  if (defined($result)) {
    unless (ref($result) eq $class) {
      carp "result object is not a matrix";
      return undef;
    }
    unless ($self->ROWS == $result->ROWS) {
      carp "this matrix's ROWS must equal result's ROWS";
      return undef;
    }
    unless ($self->WIDTH == $result->WIDTH) {
      carp "result matrix's WIDTH does not match this ones.";
      return undef;
    }
  } else {
    $result=new($class, rows=>$self->ROWS, cols =>$other->COLS,
			width=> $self->WIDTH, org=>$self->ORG);
    unless (defined ($result) and ref($result) eq $class) {
      carp "Problem allocating new RESULT matrix";
      return undef;
    }
  }

  multiply_submatrix_c($self, $other, $result,
		       0,0,$self->ROWS,
		       0,0,$other->COLS);
  return $result;
}

sub eq {
  my $self   = shift;
  my $class  = ref($self);
  my $other  = shift;

  unless (defined($other) and ref($other) eq $class) {
    carp "eq needs another matrix to compare against";
    return undef;
  }
  unless ($self->COLS == $other->COLS) {
    return 0;
  }
  unless ($self->COLS == $other->COLS) {
    return 0;
  }
  unless ($self->WIDTH == $other->WIDTH) {
    return 0;
  }
  return values_eq_c($self,$other);
}


sub ne {
  my $self   = shift;
  my $class  = ref($self);
  my $other  = shift;

  unless (defined($other) and ref($other) eq $class) {
    carp "eq needs another matrix to compare against";
    return undef;
  }
  if ($self->COLS != $other->COLS) {
    return 1;
  }
  if ($self->COLS != $other->COLS) {
    return 1;
  }
  if ($self->WIDTH != $other->WIDTH) {
    return 1;
  }
  return !values_eq_c($self,$other);
}

sub offset_to_rowcol {
  my $self=shift;
  my $offset=shift;

  if ($offset % $self->WIDTH) {
    carp "offset must be a multiple of WIDTH in offset_to_rowcol";
    return undef;
  }
  $offset /= $self->WIDTH;
  if ($offset < 0 or $offset >= $self->ROWS * $self->COLS) {
    carp "Offset out of range in offset_to_rowcol";
    return undef;
  }
  if ($self->ORG eq "rowwise") {
    return ((int ($offset / $self->COLS)),
	    ($offset % $self->COLS) );
  } else {
    return (($offset % $self->ROWS),
	    (int ($offset / $self->ROWS)));
  }
}

sub rowcol_to_offset {
  my $self=shift;
  my $row=shift;
  my $col=shift;

  if ($row < 0 or $row >= $self->ROWS) {
    carp "ROW out of range in rowcol_to_offset";
    return undef;
  }
  if ($col < 0 or $col >= $self->COLS) {
    carp "COL out of range in rowcol_to_offset";
    return undef;
  }
  if ($self->ORG eq "rowwise") {
    return ($row * $self->COLS + $col) * $self->WIDTH;# / $self->WIDTH;
  } else {
    return ($col * $self->ROWS + $row) * $self->WIDTH; # / $self->WIDTH
  }
}

sub getvals {
  my $self  = shift;
  my $class = ref($self);
  my $row   = shift;
  my $col   = shift;
  my $words = shift;
  my $order = shift || 0;
  my $want_list = wantarray;

  #carp "Asked to read ROW=$row, COL=$col, len=$bytes (words)";

  unless ($class) {
    carp "getvals only operates on an object instance";
    return undef;
  }
  #if ($bytes % $self->WIDTH) {
  #  carp "bytes to get must be a multiple of WIDTH";
  #  return undef;
  #}
  unless (defined($row) and defined($col) and defined($words)) {
    carp "getvals requires row, col, words parameters";
    return undef;
  }
  if ($order < 0 or $order > 2) {
    carp "order ($order) != 0 (native), 1 (little-endian) or 2 (big-endian)";
    return undef;
  }
  my $width=$self->WIDTH;
  my $msize=$self->ROWS * $self->COLS;
  if ($row < 0 or $row >= $self->ROWS) {
    carp "starting row out of range";
    return undef;
  }
  if ($col < 0 or $row >= $self->ROWS) {
    carp "starting row out of range";
    return undef;
  }

  my $s=get_raw_values_c($self, $row, $col, $words, $order);

  return $s unless $want_list;

  # Since the get_raw_values_c call swaps byte order, we don't do it here
  if ($self->WIDTH == 1) {
    return unpack "C*", $s;
  } elsif ($self->WIDTH == 2) {
    return unpack "S*", $s
  } else {
    return unpack "L*", $s;
  }

  # return unpack ($self->WIDTH == 2 ? "v*" : "V*"), $s;
  # return unpack ($self->WIDTH == 2 ? "n*" : "N*"), $s;
}

sub setvals {
  my $self    = shift;
  my $class   = ref($self);
  my ($row, $col, $vals, $order) = @_;
  my ($str,$words);
  $order=0 unless defined($order);

  #carp "Asked to write ROW=$row, COL=$col";

  unless ($class) {
    carp "setvals only operates on an object instance";
    return undef;
  }
  unless (defined($row) and defined($col)) {
    carp "setvals requires row, col, order parameters";
    return undef;
  }
  if ($order < 0 or $order > 2) {
    carp "order != 0 (native), 1 (little-endian) or 2 (big-endian)";
    return undef;
  }
  if ($row < 0 or $row >= $self->ROWS) {
    carp "starting row out of range";
    return undef;
  }
  if ($col < 0 or $row >= $self->ROWS) {
    carp "starting row out of range";
    return undef;
  }

  if(ref($vals)) {
    # treat $vals as a list(ref) of numbers
    unless ($words=scalar(@$vals)) {
      carp "setvals: values must be either a string or reference to a list";
      return undef;
    }
    if ($self->WIDTH == 1) {
      $str=pack "C*", @$vals;
    } elsif ($self->WIDTH == 2) {
      $str=pack "S*", @$vals;
    } else {
      $str=pack "L*", @$vals;
    }
  } else {
    # treat vals as a string
    $str="$vals";
    $words=(length $str) / $self->WIDTH;
  }

  my $msize=$self->ROWS * $self->COLS;
  if ( (($self->ORG eq "rowwise") and
	($words + $self->COLS * $row + $col > $msize)) or
       ($words + $self->ROWS * $col + $row > $msize)) {
    carp "string length exceeds matrix size";
    return undef;
  }

  #carp "Writing $words word(s) to ($row,$col) (string '$str')";
  set_raw_values_c($self, $row, $col, $words, $order, $str);
  return $str;
}

# return new matrix with self on left, other on right
sub concat {
  my $self  = shift;
  my $class = ref($self);
  my $other = shift;

  unless (defined($other) and ref($other) eq $class) {
    carp "concat needs a second matrix to operate on";
    return undef;
  }
  unless ($self->WIDTH == $other->WIDTH) {
    carp "concat: incompatible matrix widths";
    return undef;
  }
  unless ($self->ROWS == $other->ROWS) {
    carp "can't concat: the matrices have different number of rows";
    return undef;
  }

  my $cat=alloc_c($class, $self->ROWS, $self->COLS + $other->COLS,
		  $self->WIDTH, $self->ORGNUM);
  return undef unless defined $cat;
  if ($self->ORG eq "rowwise") {
    my $s;
    for my $row (0.. $other->ROWS - 1) {
      $s=get_raw_values_c($self, $row, 0, $self->COLS, 0);
      set_raw_values_c   ($cat,  $row, 0, $self->COLS, 0, $s);
      for my $col (0.. $other->COLS - 1) {
	$cat->setval($row, $self->COLS + $col,
		     $other->getval($row,$col));
      }
    }
  } else {
    my $s;
    $s=get_raw_values_c($self, 0, 0, $self->COLS * $self->ROWS, 0);
    set_raw_values_c   ($cat,  0, 0, $self->COLS * $self->ROWS, 0, $s);
    for my $row (0.. $other->ROWS - 1) {
      for my $col (0.. $other->COLS - 1) {
	$cat->setval($row, $self->COLS + $col,
		     $other->getval($row,$col));
      }
    }
  }

  return $cat;
}

# I'll replace this with some C code later
sub solve {

  my $self  = shift;
  my $class = ref($self);

  my $rows=$self->ROWS;
  my $cols=$self->COLS;
  my $order=$self->WIDTH * 8;

  unless ($cols > $rows) {
    carp "solve only works on matrices with COLS > ROWS";
    return undef;
  }

  local *swap_rows = sub {
    my ($row1, $row2, $start_col) = @_;
    return if $row1==$row2;

    my ($s,$t,$col);
    if ($self->ORG eq "rowwise") {
      $s=get_raw_values_c($self, $row1, $start_col,
			  $self->COLS - $start_col, 0);
      $t=get_raw_values_c($self, $row2, $start_col,
			  $self->COLS - $start_col, 0);
      set_raw_values_c   ($self, $row1, $start_col,
			  $self->COLS - $start_col, 0, $t);
      set_raw_values_c   ($self, $row2, $start_col,
			  $self->COLS - $start_col, 0, $s);
    } else {
      for $col ($start_col .. $cols -1) {
	$s=$self->getval($row1,$col);
	$t=$self->getval($row2,$col);
	$self->setval($row1, $col, $t);
	$self->setval($row2, $col, $s);
      }
    }
  };

  # work down the diagonal one row at a time ...
  for my $row (0 .. $rows - 1) {

    # We have to check whether the matrix is non-singular; all k x k
    # sub-matrices generated by the split part of the IDA are
    # guaranteed to be invertible, but user-supplied matrices may not
    # be, so we have to test for this.

    if ($self->getval($row,$row) == 0) {
      print "had to swap zeros\n";
      my $found=undef;
      for my $other_row ($row + 1 .. $rows - 1) {
	next if $row == $other_row;
	if ($self->getval($other_row,$row) != 0) {
	  $found=$other_row;
	  last;
	}
      }
      return undef unless defined $found;
      swap_rows($row,$found,$row);
    }

    # normalise the current row first
    my $diag_inverse = gf2_inv($order,$self->getval($row,$row));

    $self->setval($row,$row,1);
    for my $col ($row + 1 .. $cols - 1) {
      $self->setval($row,$col,
	gf2_mul($order, $self->getval($row,$col), $diag_inverse));
    }

    # zero all elements above and below ...
    for my $other_row (0 .. $rows - 1) {
      next if $row == $other_row;

      my $other=$self->getval($other_row,$row);
      next if $other == 0;
      $self->setval($other_row,$row,0);
      for my $col ($row + 1 .. $cols - 1) {
	$self->setval($other_row,$col,
	  gf2_mul($order, $self->getval($row,$col), $other) ^
	    $self->getval($other_row,$col));
      }
    }
  }

  my $result=alloc_c($class, $rows, $cols - $rows,
		     $self->WIDTH, $self->ORGNUM);
  for my $row (0 .. $rows - 1) {
    for my $col (0 .. $cols - $rows - 1) {
      $result->setval($row,$col,
		      $self->getval($row, $col + $rows));
    }
  }

  return $result;
}

sub invert {

  my $self  = shift;
  my $class = ref($self);

  #carp "Asked to invert matrix!";

  unless ($self->COLS == $self->ROWS) {
    carp "invert only works on square matrices";
    return undef;
  }

  my $cat=
    $self->concat($self->new_identity(size => $self->COLS,
				      width => $self->WIDTH));
  return undef unless defined ($cat);
  return $cat->solve;
}

1;


=head1 NAME

Math::FastGF2::Matrix - Matrix operations for fast Galois Field arithmetic

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 GETTING AND SETTING VALUES

=head1 SEE ALSO

=head1 AUTHOR

Declan Malone, E<lt>idablack@sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Declan Malone

This package is free software; you can redistribute it and/or modify
it under the terms of the "GNU General Public License" ("GPL").

Please refer to the files "GNU_GPL.txt" and "GNU_LGPL.txt" in this
distribution for details.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut



