#!/usr/bin/perl -w
#
# Rabin's information dispersal algorithm
#
# Copyright (c) Declan Malone 2009
#
# License: GPL 2

use strict;
use warnings;
use Getopt::Long;
use File::Path;

use Bit::Vector;
use IPC::Open2;
use Fcntl qw(:DEFAULT);


# Table of irreducible polynomials for all GF(2^8x) from GF(2^8) to GF(2^1024)
#
# (ie, everything from 1 byte to 128-byte words, aka "security level" 1..128)
#
my @irreducibles=
  (
   [4,3,1],    # f(x)=x^8  + x^4 + x^3 + x + 1, irreducible poly for GF(2^8)
   [5,3,1],    # f(x)=x^16 + x^5 + x^3 + x + 1, irreducible poly for GF(2^16)
   [4,3,1],[7,3,2],[5,4,3],[5,3,2],[7,4,2],[4,3,1],
   [10,9,3],   # f(x)=x^72 + x^10 + x^9 + x^3 + 1, irreduc. poly for GF(2^72)
   [9,4,2],[7,6,2],[10,9,6],[4,3,1],[5,4,3],[4,3,1],[7,2,1],
   [5,3,2],    # f(x)=x^136 + ... + 1
   [7,4,2],[6,3,2],[5,3,2],[15,3,2],[11,3,2],[9,8,7],[7,2,1],
   [5,3,2],    # f(x)=x^200 + ... + 1
   [9,3,1],[7,3,1],[9,8,3],[9,4,2],[8,5,3],[15,14,10],[10,5,2],
   [9,6,2],    # f(x)=x^264 + ... + 1
   [9,3,2],[9,5,2],[11,10,1],[7,3,2],[11,2,1],[9,7,4],[4,3,1],
   [8,3,1],    # f(x)=x^328 + ... + 1
   [7,4,1],[7,2,1],[13,11,6],[5,3,2],[7,3,2],[8,7,5],[12,3,2],
   [13,10,6],  # f(x)=x^392 + ... + 1
   [5,3,2],[5,3,2],[9,5,2],[9,7,2],[13,4,3],[4,3,1],[11,6,4],
   [18,9,6],   # f(x)=x^456 + ... + 1
   [19,18,13],[11,3,2],[15,9,6],[4,3,1],[16,5,2],[15,14,6],[8,5,2],
   [15,11,2],  # f(x)=x^520 + ... + 1
   [11,6,2],[7,5,3],[8,3,1],[19,16,9],[11,9,6],[15,7,6],[13,4,3],
   [14,13,3],  # f(x)=x^584 + ... + 1
   [13,6,3],[9,5,2],[19,13,6],[19,10,3],[11,6,5],[9,2,1],[14,3,2],
   [13,3,1],   # f(x)=x^648 + ... + 1
   [7,5,4],[11,9,8],[11,6,5],[23,16,9],[19,14,6],[23,10,2],[8,3,2],
   [5,4,3],    # f(x)=x^712 + ... + 1
   [9,6,4],[4,3,2],[13,8,6],[13,11,1],[13,10,3],[11,6,5],[19,17,4],
   [15,14,7],  # f(x)=x^776 + ... + 1
   [13,9,6],[9,7,3],[9,7,1],[14,3,2],[11,8,2],[11,6,4],[13,5,2],
   [11,5,1],   # f(x)=x^840 + ... + 1
   [11,4,1],[19,10,3],[21,10,6],[13,3,1],[15,7,5],[19,18,10],[7,5,3],
   [12,7,2],   # f(x)=x^904 + ... + 1
   [7,5,1],[14,9,6],[10,3,2],[15,13,12],[12,11,9],[16,9,7],[12,9,3],
   [9,5,2],    # f(x)=x^968 + ... + 1
   [17,10,6],[24,9,3],[17,15,13],[5,4,3],[19,17,8],[15,6,3],[19,6,1]
);

sub gcd {

  my ($a,$b,@junk)=@_;

  ($a,$b)=($b,$a) if $a<$b;

  my $t;
  while ($b) {
    $t=$a % $b;
    $a=$b;
    $b=$t;
  }

  return $a;
}

# This extended GCD is fairly normal except that it swaps the order of
# the inputs so that the algorithm always tries to divide a smaller
# number into a larger number, and it avoids division by zero errors
# in the cases where one operand is zero or one operand divides into
# the other with no remainder.  Because division by zero is avoided,
# the algorithm returns 0 to signify that there is no multiplicative
# inverse, so it's up to the calling program to test for a zero return
# value (or check if the value is zero *before* calling). Finally, the
# inverse is normalised to be a positive number.

sub extended_gcd {
  my ($a,$b,@junk)=@_;		# $a should be prime larger than $b

  ($a,$b)=($b,$a) if $a<$b;	# want $a to be larger than $b

  return ($a,0) if $b == 0;
  return ($a,0) if $b != 1 and ($a % $b) == 0;

  my @remainder=($a,$b);
  my @auxiliary=(0,1);
  my $quotient=0;

  while ($remainder[1] != 1 ) {
    push @remainder,($remainder[0] % $remainder[1]);
    $quotient=int($remainder[0] / $remainder[1]);
    push @auxiliary,($auxiliary[0] - $quotient * $auxiliary[1]);

    shift @remainder;
    shift @auxiliary;
    #    print "Next step: \@remainder=($remainder[0],$remainder[1]); ",
    #          "\@auxiliary=($auxiliary[0],$auxiliary[1]); ",
    #          "\$quotient=$quotient\n";
  }

  $auxiliary[1]+=$a if $auxiliary[1] < 0;   # normalise inverse to be positive

  # return (gcd, inverse)
  return ($remainder[1],$auxiliary[1]);
}


sub multiplicative_inverse {
  my ($a,$b)=@_;
  my ($gcd,$inverse,$quotient)=extended_gcd(@_);

  return $inverse;
}





sub size_in_bits {
  my $x=shift;
  my $i=$x->Size;

  while (--$i >= 0) {
    last if $x->bit_test($i);
  }
  return $i+1;
}

sub gf2_mult {
  my ($poly,$x,$y,@junk)=@_;
  my ($b,$i,$z,$s,$carry);

  # All input variables assumed to be the same size as each other

  # Initialise $b = $x
  $b=$x->Clone;

  # variable initialisation is unrolling of first loop iteration
  if ($y->lsb) {		# first line of multplication
    $z=$x->Clone;
  } else {
    $z=$x->Shadow;
  }

  $i=1;
  $s=$poly->Size;
   while ($i < $s) {
    $carry=$b->shift_left(0);

    if ($carry) {
      $b->Xor($b,$poly);
    }
    if ($y->bit_test($i)) {
      $z->Xor($z,$b);
    }
  } continue {
    ++$i;
  }

  return $z;
}

sub gf2_mult_inv {

  # Extended Euclidian Algorithm applied to GF(2^x) polynomials

  my ($poly,$x,$debug,@junk)=@_;

  my ($u,$v,$z,$g,$h,$i);

  my $s=$poly->Size;
  my $one=Bit::Vector->new_Enum($s,"0");

  return $one unless $x->Lexicompare($one);

  $u=$poly->Clone;		# u==poly
  $v=$x->Clone;			# v==x
  $z=$poly->Shadow;		# z==0

  $g=$one->Clone;		# g==1

  # unroll first loop iteration
  $i=$s + 1 - size_in_bits($v,0);
  print "(\$i = $i)\n" if $debug;

  $h=$v->Clone; $h->Move_Left($i);
  $u->Xor($u,$h);
  $h=$g->Clone; $h->Move_Left($i);
  $z->Xor($z,$h);

  while ($u->Lexicompare($one)) { # while u != 1 (unsigned)

    print "[Entering: \$u = ", $u->to_Bin, "; \$v = ", $v->to_Bin,
      "]\n" if $debug;

    $i=size_in_bits($u,0) - size_in_bits($v,0);
    print "(\$i = $i)\n" if $debug;
    if ($i < 0) {
      ($u,$v) = ($v,$u);	# this exchange should be OK since
      ($z,$g) = ($g,$z);	# variables are just references to
      $i=-$i;			# objects
    }
    $h=$v->Clone; $h->Move_Left($i);
    $u->Xor($u,$h);
    $h=$g->Clone; $h->Move_Left($i);
    $z->Xor($z,$h);
    print "[Leaving: \$u = ", $u->to_Bin, "; \$v = ", $v->to_Bin,
      "; \$z = ", $z->to_Bin, "]\n" if $debug;
  }
  return $z;
}


sub gauss_jordan_invert {

  # My implementation of Gauss-Jordan elimination. This takes O(n^3)
  # operations, which should be OK for practical values of k in the
  # IDA

  my ($matrix,$k,$order,$poly)=@_;

  my $one=Bit::Vector->new_Enum($order,0);
  my $zero=Bit::Vector->new($order);
  my @identity_row=($one);
  for (1..  $k - 1) {
    push @identity_row, $zero;
  }

  # extend the matrix to add an identity matrix on the right
  foreach my $row (@$matrix) {
    my $elem;
    foreach $elem (@identity_row) {
      push @$row,$elem->Clone;
    }
    $elem= pop @identity_row;
    unshift @identity_row, $elem;
  }

  # Due to the way in which we've generated the transform matrix in
  # the split routine, there should be no zeroes in the main part of
  # the matrix. This means that we can dispense with the normal method
  # of swapping rows to eliminate zeroes or put them in more
  # favourable places. The outline of the method to be used here is:
  #
  # working down the diagonal:
  #
  #   all elements to the left of the diagonal are expected to be
  #   zero, or, in the case of the first row, nothing is to the left
  #   of the diagonal.
  #
  #   We make all elements below this row's diagonal zero by
  #   subtracting some multiple of this row to the rows below. If the
  #   diagonal element is called diag, and the element directly below
  #   it in the row below is called below, then we calculate
  #
  #                                below
  #   row       -= row        x   -------
  #      below        current      diag
  #
  #   We can eliminate the calculations for all columns to the left of
  #   and including the current diagonal element being considered,
  #   since those elements should remain zero (or become zero in this
  #   step).
  #
  # working back up the diagonal:
  #
  #   At this stage, we have a matrix with non-zero elements along the
  #   diagonal, and zero elements in the triangle below the diagonal.
  #   We can employ a similar set of steps to fill the triangle above
  #   the diagonal with zeroes. Starting at the bottom of the
  #   diagonal, we calculate:
  #
  #                                above
  #   row       -= row        x   -------
  #      above        current      diag
  #
  #   As with working down the diagonal, we can omit actually
  #   calculating the changes to elements to the left, and including
  #   the element above the diagonal since they will either become
  #   zero or be unchanged.
  #
  # Optimisation
  #
  #   Also note that we have a choice of working up or down the
  #   diagonal in the second stage. Working down from the second row
  #   may make calculations easier. Note that it makes no difference
  #   whether we're working up or down the diagonal---we still want to
  #   eliminate any non-zero values /above/ the diagonal in this step.
  #
  #   Also, we don't need to wait until we've gone down the diagonal
  #   fully before eliminating zeroes above the diagaonl: we can work
  #   down the diagonal eliminating non-zero values below then above
  #   without any problem.
  #
  #
  # normalise the diagonal
  #
  #   We should now have a matrix where all the diagonal values are
  #   non-zero, and all the values above and below it are zero. We
  #   want to have the diagonal values all 1, so we multiply each row
  #   of the adjunct matrix on the right by the inverse of the
  #   corresponding diagonal elements.
  #
  # read the output
  #
  #   The k * k matrix on the left is now an identity matrix, and we
  #   can remove those k columns from the full matrix. The adjoined
  #   matrix on the right should contain the inverse of the original
  #   matrix.

  # work down the diagonal ...
  for my $row (0 .. $k - 1) {
    my $diag=$matrix->[$row]->[$row];
    my $diag_inverse=gf2_mult_inv($poly,$diag);

    # normalise the current row first ...
    $matrix->[$row]->[$row]=$one->Clone;
    for my $col ($row + 1 .. 2 * $k - 1) {
      $matrix->[$row]->[$col]=
	gf2_mult($poly,
		 $matrix->[$row]->[$col],
		 $diag_inverse
		);
    }

    # ... and zero all elements above and below ...
    for my $other_row (0 .. $k - 1) {
      next if $row == $other_row;
      my $row_multiplier=$matrix->[$other_row]->[$row];
      $matrix->[$other_row]->[$row]=$zero->Clone;	# ->Empty;
      for my $column ($row .. $k * 2 - 1) {
	$matrix->[$other_row]->[$column]->
	  Xor( $matrix->[$other_row]->[$column],
	       gf2_mult($poly,
			$matrix->[$row]->[$column],
			$row_multiplier)
	     );
      }
    }
  }

  # Remove the identity matrix on the left
  foreach my $row (0 .. $k -1 ) {
    for (0 .. $k -1) {
      shift @{ $matrix->[$row] };
    }
  }
}

sub test_gauss_jordan_invert {
  my @m1 = (
	    ["35","36","82","7A","D2","7D","75","31"],
	    ["0E","76","C3","B0","97","A8","47","14"],
	    ["F4","42","A2","7E","1C","4A","C6","99"],
	    ["3D","C6","1A","05","30","B6","42","0F"],
	    ["81","6E","F2","72","4E","BC","38","8D"],
	    ["5C","E5","5F","A5","E4","32","F8","44"],
	    ["89","28","94","3C","4F","EC","AA","D6"],
	    ["54","4B","29","B8","D5","A4","0B","2C"],
	   );

  my @inv= (
	    ["3E","02","23","87","8C","C0","4C","79"],
	    ["5D","2B","2A","5B","7E","FE","25","36"],
	    ["F2","A9","B5","57","A2","F6","A2","7D"],
	    ["11","5E","E4","61","59","F4","B9","42"],
	    ["D5","16","B8","5B","30","85","1E","72"],
	    ["3B","F7","1B","5B","4C","55","35","04"],
	    ["58","95","73","33","8A","77","1C","F4"],
	    ["59","C0","7B","13","9F","8B","BE","E3"],
	   );

  my @matrix;

  foreach my $row (@m1) {
    my @new_row=();
    push @new_row,map { Bit::Vector->new_Hex(8,$_) } @$row;
    push @matrix,[@new_row];
  }

  my $poly_spec="4,3,1,0";
  my $poly=Bit::Vector->new_Enum(8,$poly_spec);
  gauss_jordan_invert(\@matrix,8,8,$poly);

  foreach my $row (@matrix) {
    print join ",", (map { "\"". ($_->to_Hex) . "\"" } @$row);
    print "\n";
  }

  print "\nInverse of inverse:\n";
  gauss_jordan_invert(\@matrix,8,8,$poly);
  foreach my $row (@matrix) {
    print join ",", (map { "\"". ($_->to_Hex) . "\"" } @$row);
    print "\n";
  }

}


# Simple istream/ostream wrappers for I/O on files/strings

sub mk_file_istream {
  my ($filename,$default_bytes_per_read)=@_;
  my ($fh,$eof)=(undef,0);

  # basic checking of args
  if (!defined($filename) or !defined($default_bytes_per_read) or
      $default_bytes_per_read <= 0) {
    return undef;
  }

  # try opening the file; use sysopen to match better with later sysreads
  return undef unless sysopen $fh,$filename,O_RDONLY;

  # Use closure/callback technique to provide an iterator for this file
  my $methods=
    {
     FILENAME => sub {
       return $filename;
     },
     READ => sub {
       # This reads words from the file in network (big-endian) byte
       # order, with zero padding in the least significant bytes. So,
       # for example, if we are using 2-byte chunks and the file
       # contains three bytes 0d fe 2d, then two reads on the file
       # will return the values 0dfe and 2d00. Each read will return a
       # new Bit::Vector object which will contain an integer number
       # of bytes, so it may have to be resized later.

       my ($override_bytes,$bytes_to_read);

       if ($override_bytes=shift) {
	 $bytes_to_read=$override_bytes;
       } else {
	 $bytes_to_read=$default_bytes_per_read;
       }

       my $buf="";
       my $vec=Bit::Vector->new(8 * $bytes_to_read);
       my $bytes_read=sysread $fh, $buf, $bytes_to_read;

       # There are three possible return value from sysread:
       # undef   there was a problem with the read (caller should check $!)
       # 0       no bytes read (eof)
       # >0      some bytes read (maybe fewer than we wanted, due to eof)
       return undef unless defined($bytes_read);
       if ($bytes_read == 0) {
	 $eof=1;
	 return undef;
       }

       # we don't need to set eof, but it might be useful for callers
       $eof=1 if ($bytes_read < $bytes_to_read);

       # Convert these bytes into a single bit vector value
       #$buf=pack "a$bytes_to_read", $buf; # pad zeroes on right
       $buf.="\000" x ($bytes_to_read - length $buf);
       my $hex_format="H" . ($bytes_to_read * 2); # number of nibbles
       $vec->from_Hex(unpack $hex_format, $buf);

       return $vec;
     },
     EOF => sub {
       return $eof;
     },
     CLOSE => sub {
       close $fh;
     }
    };
  return $methods;
}

sub test_mk_file_istream {

  my $tmpfile="/tmp/rabin-$$.txt";

  # create a test file for reading
  open TESTFILE, ">$tmpfile" or die "Couldn't create temp file: $!\n";
  print TESTFILE "ABCDEFG";	# 7 bytes
  close TESTFILE;

  my $istream;

  # test reading file in chunks of 1..8 bytes
  for my $bytes (1..8) {
    $istream=mk_file_istream($tmpfile,$bytes);
    die "Error creating istream [$tmpfile,$bytes]: $!\n"
      unless defined $istream;

    # Now dump the complete file to the terminal
    print "[$tmpfile,$bytes]: ";
    my $vec;
    while ($vec=$istream->{READ}->()) {
      print $vec->to_Hex, " ";
    }
    print "EOF\n";
    $istream->{CLOSE}->();
  }

  # test overriding number of bytes to read
  my $bytes=1;
  $istream=mk_file_istream($tmpfile,1);
  die "Error creating istream [$tmpfile,varable=1]: $!\n"
    unless defined $istream;

  print "[$tmpfile,variable]: ";
  my $vec;
  while ($vec=$istream->{READ}->($bytes++)) {
    print $vec->to_Hex, " ";
  }
  print "EOF\n";
  $istream->{CLOSE}->();
}

sub mk_file_ostream {
  my ($filename,$default_bytes_per_write)=@_;
  my ($fh,$eof)=(undef,0);

  # basic checking of args
  if (!defined($filename) or !defined($default_bytes_per_write) or
      $default_bytes_per_write <= 0) {
    return undef;
  }

  # try opening the file; use sysopen to match better with later sysreads
  return undef unless sysopen $fh,$filename,O_CREAT|O_TRUNC|O_WRONLY;

  my $methods=
    {
     FILENAME => sub {
       return $filename;
     },
     WRITE => sub {
       my $obj=shift;
       die "ostream can only write Bit::Vector objects\n"
	 unless defined($obj) and ref($obj) eq "Bit::Vector";

       my ($override_bytes,$bytes_to_write);

       if ($override_bytes=shift) {
	 $bytes_to_write=$override_bytes;
       } else {
	 $bytes_to_write=$default_bytes_per_write;
       }

       # Writing is a little easier than reading, but we have to take
       # care if the Bit::Vector object is actually larger/smaller
       # than what we expect. We'll make a copy of the original object
       # and die if it's too small (since that's probably an error),
       # but truncate it if it's too large (by discarding extra high
       # bits). This resizing code is probably redundant, since I made
       # changes at some point that meant that the high bit of the
       # polynomial wasn't actually stored...

       my $buf="";
       my $clone=$obj->Clone;

       die "ostream: Passed object was too small. Aborting.\n"
	 if $clone->Size < $bytes_to_write * 8;

       $clone->Resize($bytes_to_write * 8);

       my $hex_format="H" . ($bytes_to_write * 2);
       $buf=pack $hex_format, $clone->to_Hex;
       syswrite $fh,$buf,$bytes_to_write;

     },
     EOF => sub {
       0;
     },
     FILENAME => sub {
       return $filename;
     },
     FLUSH => sub {
       0; # syswrite doesn't buffer, so flush does nothing
     },
     CLOSE => sub {
       close $fh;
     }
    };
  return $methods;		# be explicit
}

sub test_mk_file_ostream {

  my $ostream=mk_file_ostream("/tmp/rabin-$$.txt",1);

  die "Failed to create ostream: $!\n" unless defined($ostream);

  my $b1=Bit::Vector->new_Hex(9, "41");	     # A               1 extra bit
  my $b2=Bit::Vector->new_Hex(18,"4243");    # BC (big endian) 2 extra bits
  my $b3=Bit::Vector->new_Hex(24,"444546");  # DEF
  my $b4=Bit::Vector->new_Hex(8, "0047");    # G               8 extra bits

  my $wrote;

  $wrote=$ostream->{WRITE}->($b1);
  die "Wrote $wrote bytes instead of expected (1 byte)\n" unless $wrote==1;

  $wrote=$ostream->{WRITE}->($b2,2);
  die "Wrote $wrote bytes instead of expected (2 bytes)\n" unless $wrote==2;

  $wrote=$ostream->{WRITE}->($b3,3);
  die "Wrote $wrote bytes instead of expected (3 bytes)\n" unless $wrote==3;

  $wrote=$ostream->{WRITE}->($b4,1);
  die "Wrote $wrote bytes instead of expected (1 byte)\n" unless $wrote==1;

  $ostream->{CLOSE}->();

  open REREAD, "</tmp/rabin-$$.txt" or die "Couldn't re-open file for reading\n";
  my $buf=<REREAD> || die "Couldn't read data back from file\n";

  print "Expected result: ABCDEFG\nGot: $buf (";
  if ($buf ne "ABCDEFG") {
    print "Mismatch detected!)\n";
  } else {
    print "OK)\n";
  }
}

sub mk_helper_process {
  # Create and attach to a new process which create and merge shares
  # more efficiently (ie, external C program)
  my ($external_command,@junk)=@_;


  # At the moment, the Perl program is responsible for:
  # * generating/checking the transform matrix
  # * creating share files
  # * writing headers for each of the share files
  # * perform matrix multiplication creating share data    (*)
  # * open share files for reading
  # * create recombined file                               (*)
  # * read in header information from share files
  # * calculate inverse matrix based on share header info
  # * perform matrix multiplication combining share data   (*)
  #
  # If using a helper process, it can take over responsibilty for
  # those tasks marked with (*). The Perl program will still have to
  # do all the other tasks.
  #
  # This routine only needs to be called once per program. At that
  # time it will create the child process, eg:
  #
  # my $helper=mk_helper_process("/usr/bin/rabin-ida-helper");
  #
  # To get the process to do something, there are three steps:
  # * prepare the process to work with your parameters (k, n, poly,
  #   list of share files, etc)
  # * send an n x k transform matrix or a k x k inverse matrix
  # * run split, using the transform matrix, or combine, using the
  #   inverse matrix
  #
  # The input file and output file names can be sent along with the
  # prepare message, or they can be set to undef. If either/both of
  # these were undefined in the prepare message, the appropriate
  # filename can be passed as an optional second argument to the
  # matrix/inverse messages.

  # Spawn sub-process and save filehandles used to talk with it ...
  my ($pid,$pipe_out,$pipe_in);

  # Run external_command without going through shell
  $pid=open2($pipe_in,$pipe_out,$external_command);
  return undef unless $pid;

  # some closure-local variables
  my ($n,$k,$s);

  my $methods =
    {
     PREPARE => sub {
       my ($shares,$quorum,$security,$poly,$header,$infile,$outfile,
	   $sharefiles,$padding,$spawn_opt,$timer_opt)=@_;
       print $pipe_out "shares $shares\n";      $n=$shares;
       print $pipe_out "quorum $quorum\n";      $k=$quorum;
       print $pipe_out "security $security\n";  $s=$security;
       print $pipe_out "poly ", $poly->to_Hex, "\n";
       print $pipe_out "header $header\n";
       print $pipe_out "infile $infile\n"   if (defined($infile));
       print $pipe_out "outfile $outfile\n" if (defined($outfile));
       foreach (@$sharefiles) {
	 print $pipe_out "sharefile $_\n";
       }
       foreach (@$padding) {
	 print $pipe_out "padding ", $_->to_Hex, "\n";
       }
       print $pipe_out "spawn $spawn_opt\n" if defined($spawn_opt);
       print $pipe_out "timer $timer_opt\n" if defined($timer_opt);

     },
     MATRIX => sub {
       my $m=shift;
       my $infile=shift;	# allow late specification

       print "infile $infile\n"    if (defined($infile));

       die "helper: matrix is undefined\n" unless defined($m);
       die "helper: Matrix has wrong number of rows\n"
	 unless scalar(@$m) == $n;
       foreach my $row (@$m) {
	 die "helper: Row has wrong number of elements\n"
	   unless scalar(@$row) == $k;
	 foreach my $elem (@$row) {
	   print $pipe_out "matrix ", $elem->to_Hex, "\n";
	 }
       }
     },
     INVERSE => sub {
       my $m=shift;
       my $outfile=shift;	# allow late specification

       print "outfile $outfile\n"  if (defined($outfile));

       die "helper: Inverse has wrong number of rows\n"
	 unless scalar(@$m) == $k;
       foreach my $row (@$m) {
	 die "helper: Row has wrong number of elements\n"
	   unless scalar(@$row) == $k;
	 foreach my $elem (@$row) {
	   print $pipe_out "inverse ", $elem->to_Hex, "\n";
	 }
       }
     },
     RUN => sub {
       0;
     },
     SPLIT => sub {
       print "Sending split command to helper\n";
       print $pipe_out "split ", shift, "\n\n";
     },
     COMBINE => sub {
       print "Sending combine command to helper\n";
       print $pipe_out "combine ", shift , "\n\n";
     },
     RANGE => sub {
       print $pipe_out "range ",shift, "\n";
     },
     RESET => sub {
       print $pipe_out "reset\n";
     },
     QUIT => sub {
       print $pipe_out "quit\n";
     },
     READ => sub {
       <$pipe_in>;
     },
    };
  return $methods;
}

sub check_transform {
  my ($k,$n,$order,$transform)=@_;

  # Check that matrix generated by the transform array has the
  # properties required for linear independence

  # The transform list supplied must be in the order
  # x1,...,xk,y1,...,yn

  die "No transform elements to check\n" unless defined $transform;

  die "Supplied array for generating transform is of the wrong size"
    unless scalar(@$transform) == $k + $n;

  my %values;

  # For integer values xi, yj mod a prime p, the conditons that must
  # be satisfied are...
  # xi + yj != 0        |
  # i != j -> xi != xj  } for all i,j
  # i != j -> yi != yj  |
  #
  # For calculations in GF_2, since each number is its own additive
  # inverse, these conditions can be achieved by stating that all xi,
  # yi must be unique

  foreach my $value (@$transform) {
    my $hex=$value->to_Hex;
    return 0 if exists($values{$hex}); # failure; duplicate value
    #return 0 if $hex=~/^0+$/;	# (and non-zero?)
    $values{$hex}=1;
  }

  return 1;			# success; all values distinct

}

sub test_gen_and_check_transform {

  # There's not much to be tested with gen_random_transform except to
  # ensure that it creates a list of the proper size with no
  # duplicates. The check_transform function tests those, so we can
  # test both functions at once. Since gen_random_transform uses two
  # distinct algorithms depending on the order, we'll have to use test
  # for different values of order.

  for my $k (2,3,7) {
    for my $n ($k, $k * 2, $k * 7 +3) {
      for my $order (8, 16, 128) {
	my $transform=gen_random_transform($k,$n,$order);

	print "testing k=$k, n=$n, order=$order ... ";

	die "Got null return from gen_random_transform\n"
	  unless defined($transform);

	my $expected_size=$k+$n;

	my $compare_ok=check_transform($k,$n,$order,$transform);
	if ($compare_ok) {
	  print "OK\n";
	} else {
	  print "Fail!\n";
	}
      }
    }
  }

  # Actually, we can check whether check_transform correctly finds
  # duplicates by deliberately inserting them... maybe do that later

}


sub rng_init {

  my $bytes=shift;
  my $fh;

  return undef unless sysopen $fh,"/dev/urandom",O_RDONLY;

  # Return an anonymous closure to act as an iterator. Calling the
  # iterator will return a new Bit::Vector object of the chosen size
  # with a new random value read from the kernel entropy source.
  return sub {
    my $deinit=shift;		# passing any args will close the
    my $buf;			# file, allowing the calling program
    my $vec;                    # to deallocate the iterator without
                                # (possibly) leaving an open, but
                                # inaccessible file handle
    if (defined($deinit)) {
      close $fh;
      return undef;
    }

    # The following was failing occasionally when reading from
    # /dev/random, most likely because there was a lack of random bits
    # ready and I was receiving back some fewer number of bytes.
    # Rather than loop until I have collected enough bytes, I changed
    # to using /dev/urandom instead. I also added a new loop in the
    # test routine to ask for a large number of random bytes to make
    # sure that the error won't recur, and also to generate a
    # histogram of frequencies, just to test the spread of numbers.
    if ($bytes != sysread $fh,$buf,$bytes) {
      die "Fatal Error: not enough bytes in /dev/[u]random!\n";
    }

    my $hex_format="H" . ($bytes * 2); # number of nibbles
    $vec=Bit::Vector->new_Hex(8 * $bytes, unpack $hex_format, $buf);
  };

}

sub test_rng_init {

  foreach my $bytes (1,2,3) {

    # Generate some random numbers of the appropriate size
    my $rng=rng_init($bytes);

    if (defined($rng)) {
      print "$bytes: ";
      for my $i (1..5) {
	my $vec=$rng->();
	if (defined($vec)) {
	  print $vec->to_Hex, " ";
	} else {
	  print "Undefined value returned from rng!\n";
	  next;
	}
      }
      $rng->("finished");
      $rng=undef;
      print "\n";
    } else {
      warn "Failed to initialise rng for $bytes bytes\n";
    }
  }

  # Test spread of random numbers
  my $rng=rng_init(1);
  my %freq;
  for my $hi (0..9,'A'..'F') {
    for my $lo (0..9,'A'..'F') {
      $freq{"$hi$lo"}=0;	# initialise all frequencies for 00 .. FF
    }
  }

  for my $i (1..5000) {
    my $vec=&$rng;		# note alternative iterator calling notation
    my $hex=$vec->to_Hex;
    ++$freq{$hex};		# shouldn't complain about undefined values
  }

  # Report frequencies for each byte
  my $total=0;
  foreach (sort {$a cmp $b} keys %freq) {
    print "$_:$freq{$_}\t";
    print "\n" if /[7F]$/;	# print 8 values per line
    $total+=$freq{$_};
  }
  print "Total rolls: $total\n";
  for my $hi (0..9,'A'..'F') {
    for my $lo (0..9,'A'..'F') {
      print "Warning: never rolled a $hi$lo in trials!\n"
	unless $freq{"$hi$lo"};
    }
  }
}

sub fisher_yates_shuffle {	# based on Perl Cookbook, recipe 4.15
  my $array=shift;

  # Note that this uses plain old rand rather than our high-quality
  # RNG. If that is a problem, either replace this rand with a better
  # alternative or avoid having this function called by using more
  # than 1 byte-security. Since we're using the random variables to
  # generate a permutation, the actual numbers chosen won't be
  # revealed, so it should be a little more difficult for an attacker
  # to guess the sequence used (and hence make better guesses about
  # the random values for the other shares). I can't say either way
  # whether this will be a problem in practice, but it might be a good
  # idea to shuffle the array a second time if attacking rand is a
  # worry. Since an attacker won't have access to all the shares,
  # this should destroy or limit his ability to determine the order in
  # which the numbers were generated. Shuffling a list of high-quality
  # random numbers (such as from the rng_init function) with a
  # poor-quality rand-based shuffle should not leak any extra
  # information, while using two passes with the rand-based shuffler
  # (effectively one to select elements, the other to shuffle them)
  # seems like it should improve security.

  # Change recipe to allow picking a certain number of elements
  my $picks=shift;
  $picks=scalar(@$array) unless
    defined($picks) and $picks >=0 and $picks<scalar(@$array);

  my $i=scalar(@$array);
  while (--$i > $picks - scalar(@$array)) {
    my $j=int rand ($i + 1);	# random int from [0,$i]
    next if $i==$j;		# don't swap element with itself
    @$array[$i,$j]=@$array[$j,$i]
  }
  # If we want fewer picks than are in the full list, then truncate
  # the list by shifting off some elements from the front. This
  # destruction of the list may not be a good thing in general, but
  # it's fine for our purposes in this program. Also, note that using
  # delete wouldn't work here, since the array wouldn't be shortened.
  # Also note that this tail processing effectively brings the
  # algorithm up to O(n), where n is the list length, but we still
  # save out on the more expensive calls to rand and the element-
  # swapping for elements we'll never select. Using mjd-permute might
  # be a marginally better choice where there are many unused
  # elements, but since we're only interested in using this with
  # arrays of up to 256 elements, this will be fine.
  #
  while (scalar(@$array) > $picks) {
    shift @$array;		# splice() is probably quicker!
  }
}

sub test_fisher_yates_shuffle {

  my @list0=();
  my @list1=(1);
  my @list2=(2,3);
  my @list3=(4,5,6);
  my $list;

  # first test that passing a null list works as expected
  $list=[@list0];
  fisher_yates_shuffle($list);
  print "Shuffle null list, no size arg: [", (join ",", @$list), "]\n";

  $list=[@list0];
  fisher_yates_shuffle($list,0);
  print "Shuffle null list,  0 size arg: [", (join ",", @$list), "]\n";

  $list=[@list0];
  fisher_yates_shuffle($list,1);
  print "Shuffle null list,  1 size arg: [", (join ",", @$list), "]\n";

  # next test a list with 1 element
  $list=[@list1];
  fisher_yates_shuffle($list);
  print "Shuffle 1-elem list, no size arg: [", (join ",", @$list), "]\n";

  $list=[@list1];
  fisher_yates_shuffle($list,0);
  print "Shuffle 1-elem list,  0 size arg: [", (join ",", @$list), "]\n";

  $list=[@list1];
  fisher_yates_shuffle($list,1);
  print "Shuffle 1-elem list,  1 size arg: [", (join ",", @$list), "]\n";

  $list=[@list1];
  fisher_yates_shuffle($list,2);
  print "Shuffle 1-elem list,  2 size arg: [", (join ",", @$list), "]\n";

  # next test a list with 2 elements
  $list=[@list2];
  fisher_yates_shuffle($list);
  print "Shuffle 2-elem list, no size arg: [", (join ",", @$list), "]\n";

  $list=[@list2];
  fisher_yates_shuffle($list,0);
  print "Shuffle 2-elem list,  0 size arg: [", (join ",", @$list), "]\n";

  $list=[@list2];
  fisher_yates_shuffle($list,1);
  print "Shuffle 2-elem list,  1 size arg: [", (join ",", @$list), "]\n";

  $list=[@list2];
  fisher_yates_shuffle($list,2);
  print "Shuffle 2-elem list,  2 size arg: [", (join ",", @$list), "]\n";

  # next test a list with 3 elements
  $list=[@list3];
  fisher_yates_shuffle($list);
  print "Shuffle 3-elem list, no size arg: [", (join ",", @$list), "]\n";

  $list=[@list3];
  fisher_yates_shuffle($list,0);
  print "Shuffle 3-elem list,  0 size arg: [", (join ",", @$list), "]\n";

  $list=[@list3];
  fisher_yates_shuffle($list,1);
  print "Shuffle 3-elem list,  1 size arg: [", (join ",", @$list), "]\n";

  $list=[@list3];
  fisher_yates_shuffle($list,2);
  print "Shuffle 3-elem list,  2 size arg: [", (join ",", @$list), "]\n";

  # quick check for bias (no standard deviation/chi-squared tests;
  # just examine list to see if one answer predominates... introducing
  # a bias for one particular answer is the most common problem when
  # re-implementing the Fisher-Yates shuffle, so this should be an
  # adequate test)
  my $i=9000;
  my %freq;
  while ($i--) {
    $list=[@list3];
    fisher_yates_shuffle($list);
    my $key=join ",", @$list;
    if (defined($freq{$key})) {
      ++$freq{$key};
    } else {
      $freq{$key}=0;
    }
  }
  foreach (sort keys %freq) {
    print $_, ": ", $freq{$_}, "\n";
  }
}

sub gen_random_transform {

  my ($k,$n,$order)=@_;

  # Generate an array of $k + $n distinct random values, each in the
  # range [0..2**$order)

  my $transform=[];

  # If the order is 8 bits, then we'll use the Fisher-Yates shuffle to
  # choose distinct numbers in the range [0,255]. This takes only
  # O($k+$n) steps and requires O(256) storage. If the order is 16
  # or more bits, the Fisher-Yates shuffle would require too much
  # memory (O(2**16), O(2**24), etc.), so we use a different algorithm
  # which uses the rng to generate the numbers directly, checking for
  # duplicates as it goes, and re-rolling whenever dupes are found.
  if ($order == 8) {
    push @$transform,(0..255);
    fisher_yates_shuffle($transform,$k + $n);
    map { $_ = Bit::Vector->new_Dec(8,$_) } @$transform;
  } else {
    my $rng=rng_init(int ($order/8));
    my %rolled;
    my $count=$k+$n;
    while ($count) {
      my $r=$rng->();
      my $rhex=$r->to_Hex;
      next if exists($rolled{$rhex});
      $rolled{$rhex}=1;
      push @$transform,$r;
      --$count;
    }
  }

  # do a final shuffle of the elements. This should help guard against
  # exploiting weaknesses in either random generator, but particularly
  # the 1-byte version which uses the system's rand function. The
  # extra security derives from the fact that consecutively-generated
  # numbers will likely end up being distributed to different parties,
  # so it should no longer be possible for an attacker to determine
  # the order in which the rng generated them without actually
  # collecting all the shares (which would avoid the need to attack
  # the rng in the first place).
  fisher_yates_shuffle($transform);

  return $transform;
}

# Check settings that are common to split/combine; return 0 for success
sub check_codec_opts {
  my $h=shift;
  my $fail=0;
  my $i;

  # test for existence of needed settings in hash
  foreach (qw(k n order sharestreams header_version)) {
    unless (exists($h->{$_})) {
      warn "Required setting '$_' for encoding/decoding not set\n";
      ++$fail;
    }
  }
  return $fail if $fail;

  # Now do some bound checking on the above
  if ($h->{k} < 1 or $h->{k} > 255) {
    warn "Value for quorum k=$h->{k} is out of range\n";
    ++$fail;
  }
  if ($h->{n} < 1 or $h->{n} > 255) {
    warn "Value for number of shares n=$h->{n} is out of range.\n";
    ++$fail;
  }
  unless ($h->{k} <= $h->{n}) {
    warn "quorum k=$h->{k} exceeds number of shares n=$h->{n}.\n";
    ++$fail;
  }
  if ($h->{order} < 8 or $h->{order} > 1024) {
    warn "Value for order of polynomial order=$h->{order} is out of range.\n";
    ++$fail;
  }
  if ($h->{order} & 7) {
    warn "Value for order=$h->{order} is not a multiple of 8.\n";
    ++$fail;
  }
  unless ($h->{sharestreams}) {
    warn "No list of share streams defined.\n";
    ++$fail;
  } elsif (($i=scalar(@{$h->{sharestreams}})) != $h->{n}) {
    warn "Number of defined share streams ($i) not equal to n ($h->{n}).\n";
    ++$fail;
  }

  # Now check ranges, if defined
  if (exists($h->{range_start}) or exists($h->{range_start})) {
    unless (exists($h->{range_start}) and exists($h->{range_start})) {
      warn "Only one of range start, range end options set.\n";
      ++$fail;
    } else {
      $i=($h->{k} * $h->{order} / 8);
      if ($h->{range_start} % $i) {
	warn "Alignment problem with range start\n";
	++$fail;
      }
      if ($h->{range_next} and $h->{range_next} <= $h->{range_start}) {
	warn "Range end is less than or equal to range start.\n";
	++$fail;
      }
      if (exists($h->{final_chunk})) {
	unless (defined($h->{final_chunk})) {
	  warn "final_chunk option exists but is not set.\n";
	  ++$fail;
	} else {
	  if ($h->{range_start} % $i and !$h->{final_chunk}) {
	    warn "Alignment problem with range end\n";
	    ++$fail;
	  }
	}
      }
    }
  } elsif (exists($h->{final_chunk})){
    warn "Useless use of final_chunk option without range settings\n";
    ++$fail;
  }
}

sub check_encode_opts {
  my $h=shift;
  my $fail=0;

  # check settings common to both encode/decode first
  $fail=check_codec_opts($h);
  return $fail if $fail;

  # Check that the polynomial order is sufficient for the requested
  # quorum, number of shares settings.
  # FIXME: possible overflow with (2 ** $order)?
  if ($h->{k} + $h->{n} >= 2 ** $h->{order}) {
    warn "Insufficient polynomial order for requested quorum, shares\n";
    ++$fail;
  }

  # Do we have a input stream defined?
  unless (exists($h->{istream}) and defined($h->{istream})) {
    warn "We need an istream setting for encoding!\n";
    ++$fail;
  }

  return $fail;
}

sub check_decode_opts {
  my $h=shift;
  my $fail=0;

  # check settings common to both encode/decode first
  $fail=check_codec_opts($h);
  return $fail if $fail;

  # Do we have an output stream defined?
  unless (exists($h->{ostream}) and defined($h->{ostream})) {
    warn "We need an ostream setting for decoding!\n";
    ++$fail;
  }

  return $fail;
}

# Routines to read/write share file header
#
# header version 1
#
# bytes   name          value
# 2       magic         marker for "Share File" format; "SF" = {5346}
# 1       version       file format version = 1
# 1       options       options bits (see below)
# 1-2     k,quorum      quorum k-value (set both names on read)
# 1-2     s,security    security level s-value (set both names on read)
# var     chunk_start   absolute offset of chunk in file
# var     chunk_next     absolute offset of next chunk in file
# var     transform     transform matrix row
#
# The options bits are as follows:
#
# Bit     name          Settings
# 0       opt_large_k   Large (2-byte) k value?
# 1 	  opt_large_s   Large (2-byte) s value?
# 2 	  opt_final     Final chunk in file? (1=full file/final chunk)
# 3 	  opt_transform Is transform data included?
#
# Note that the chunk_next field is 1 greater than the actual offset of
# the chunk end. In other words, the chunk ranges from the byte
# starting at chunk_start up to, but not including the byte at
# chunk_next. I made this decision fairly late on to handle the case
# where we've been asked to split a zero-length file, which we can
# represent with the condition chunk_start == chunk_next. In
# retrospect, had I considered this corner case earlier I would have
# called the variables chunk_start and chunk_next instead. I will
# probably end up making this change in naming later on, but only
# after I've got the code working.
#
# More on this: it might seem that it's ok to refuse to split a
# zero-length file, but if we're using this for backups, it's not a
# good idea to fail just because we don't like zero-length
# files. Also, splitting a zero-length file might be useful in some
# cases, since we might be interested in just creating and storing a
# transform matrix for later use, or maybe generating test cases for a
# matrix inverse routine.

sub read_ida_header {
  my $istream=shift;		  # assume istream is at start of file
  my $header_info={};   	  # values will be returned in this hash

  # When calling this routine the caller can specify any
  # previously-read values for k, s, and so on and have us check the
  # values in the current header against these values for consistency.
  # This implies that all the shares we're being presented for
  # processing will combine to form a single chunk (or full file). If
  # this is the first share header being read, the following may be
  # undefined. We store any read values in the returned hash, so it's
  # up to the caller to take them out and pass them back to us when
  # reading the next header in the batch.
  my ($k,$s,$start,$end,$hdr)=@_;

  my $header_length=0;		  # we also send this back in hash

  # error reporting
  $header_info->{header_error}=0;   # 0=no error, 1=failure
  $header_info->{error_message}=""; # text of error

  # use a local subroutine to save the tedium of checking for eof and
  # doing conversion of input. Updates variables from our local scope
  # directly, so we don't need to pass them in or out. (Actually,
  # technically speaking, this creates an anonymous closure and
  # locally assigns a name to it for the current scope, but it's
  # pretty much the same thing as a local subroutine)
  local *read_some = sub {
    my ($bytes,$field,$conversion)=@_;
    my ($vec,$hex);
    if ($vec=$istream->{READ}->($bytes)) {
      if (defined ($conversion)) {
	if ($conversion eq "hex") {
	  $vec=$vec->to_Hex;
	} elsif ($conversion eq "dec") {
	  $vec=hex $vec->to_Hex;
	} else {
	  die "Unknown format conversion (use undef, hex or dec)\n";
	}
      }
      $header_info->{$field}=$vec;
      $header_length+=$bytes;
      return 1;			# read some? got some.
    } else {
      $header_info->{error}++;
      $header_info->{error_message}="Premature end of stream\n";
      return 0;                 # read some? got none!
    }
  };

  # same idea for saving and reporting errors
  local *header_error = sub {
    $header_info->{error}++;
    $header_info->{error_message}=shift;
    return $header_info;
  };

  return $header_info unless read_some(2,"magic","hex");
  if ($header_info->{magic} ne "5346") {
    return header_error("This doesn't look like a share file\n" .
			"Magic is $header_info->{magic}\n");
  }

  return $header_info unless read_some(1,"version","dec");
  if ($header_info->{version} != 1) {
    return header_error("Don't know how to handle header version " .
      $header_info->{version} . "\n");
  }

  # read options field and split out into separate names for each bit
  return $header_info unless read_some(1,"options","dec");
  $header_info->{opt_large_k}   = ($header_info->{options} & 1);
  $header_info->{opt_large_s}   = ($header_info->{options} & 2) >> 1;
  $header_info->{opt_final}     = ($header_info->{options} & 4) >> 2;
  $header_info->{opt_transform} = ($header_info->{options} & 8) >> 3;

  # read k (regular or large variety) and check for consistency
  return $header_info unless
    read_some($header_info->{opt_large_k} ? 2 : 1 ,"k","dec");
  if (defined($k) and $k != $header_info->{k}) {
    return header_error("Inconsistent quorum value read from streams\n");
  } else {
    $header_info->{quorum} = $header_info->{k};
  }

  # read s (regular or large variety) and check for consistency
  return $header_info unless
    read_some($header_info->{opt_large_s} ? 2 : 1 ,"s","dec");
  if (defined($s) and $s != $header_info->{s}) {
    return 
      header_error("Inconsistent security values read from streams\n");
  } else {
    $header_info->{security} = $header_info->{s};
  }

  # File offsets can be of variable width, so we precede each offset
  # with a length field. For an offset of 0, we only have to store a
  # single byte of zero (since it takes zero bytes to store the value
  # zero). So while storing the start offset for a complete file is a
  # little bit wasteful (1 extra byte) compared to just using an
  # options bit to indicate that the share is a share for a complete
  # file and just storing the file length, it helps us to keep the
  # code simpler and less prone to errors by not having to treat full
  # files any differently than chunks.

  # Read in the chunk_start value. We'll re-use the offset_width key
  # for the chunk_next code, and then delete that key before pasing the
  # hash back to the caller (provided we don't run into errors).
  return $header_info unless read_some(1 ,"offset_width","dec");
  my $offset_width=$header_info->{offset_width};

  # Perl has no problem working with values as big as 2 ** 41 == 2Tb, but
  # we should probably impose a sane limit on file sizes here.
  if ($offset_width > 5) {
    return header_error("1Tb of file size should be enough for anybody\n");
  }

  # now read in chunk_start and check that that it is a multiple of k * s
  my $colsize=$header_info->{k} * $header_info->{s};
  if ($offset_width) {
    return $header_info unless 
      read_some($offset_width ,"chunk_start","dec");
    if ($header_info->{chunk_start} % ($colsize)) {
      return header_error("Alignment error on chunk start offset\n");
    }
  } else {
    $header_info->{chunk_start}=0;
  }

  # and also that it's consistent with other shares
  if (defined($start) and $start != $header_info->{chunk_start}) {
    return header_error("Inconsistent chunk_start values read from streams\n");
  } else {
    $start=$header_info->{chunk_start};
  }

  # now get in the offset of the end of the chunk
  # Note that chunk_next must be a multiple of k * s
  return $header_info unless read_some(1 ,"offset_width","dec");
  $offset_width=$header_info->{offset_width};
  if ($offset_width > 5) {
    return header_error("1Tb of file size should be enough for anybody\n");
  }
  if ($offset_width) {
    return $header_info unless 
      read_some($offset_width, "chunk_next","dec");
    if (!$header_info->{opt_final} and
	($header_info->{chunk_next}) % ($colsize)) {
      return header_error("Alignment error on non-final chunk end offset\n");
    }
  } else {
    # header end of 0 is strange, but we'll allow it for now and only
    # raise an error later if chunk_next <= chunk_start. Test code
    # should make sure that the program works correctly when
    # splitting/combining zero-length files.
    $header_info->{chunk_next}=0;
  }
  if (defined($end) and $end != $header_info->{chunk_next}) {
    return header_error("Inconsistent chunk_next values read from streams\n");
  } else {
    $end=$header_info->{chunk_next};
  }
  delete $header_info->{offset_width}; # caller doesn't need or want this

  # don't allow chunk_start > chunk_next, but allow chunk_start ==
  # chunk_next to represent an empty file
  if ($header_info->{chunk_start} > $header_info->{chunk_next}) {
    return header_error("Invalid chunk range: chunk_start > chunk_next\n");
  }

  # If transform data is included in the header, then read in a matrix
  # row of $k values of $s bytes apiece
  if ($header_info->{opt_transform}) {
    my $matrix_row=[];
    for my $i (1 .. $header_info->{k}) {
      return $header_info unless read_some($header_info->{s},"element");
      push @$matrix_row, $header_info->{element};
    }
    delete $header_info->{element};
    $header_info->{transform}=$matrix_row;
  }

  # Now that we've read in all the header bytes, check that header
  # size is consistent with expectations.
  if (defined($hdr) and $hdr != $header_length) {
    return header_error("Inconsistent header sizes read from streams\n");
  } else {
    $header_info->{header_length}=$header_length;
  }

  return $header_info;
}

# When writing the header, we return number of header bytes written or
# zero in the event of some error.
sub write_ida_header {
  my $ostream=shift;
  my $header_info=shift;
  my $header_size=0;		

  # save to local variables
  my ($version,$k,$s,$chunk_start,$chunk_next,$transform,$opt_final) =
    map {
      exists($header_info->{$_}) ? $header_info->{$_} : undef
    } qw(version k s chunk_start chunk_next transform opt_final);

  return 0 unless defined($version) and $version == 1;
  return 0 unless defined($k) and defined($s) and
    defined($chunk_start) and defined($chunk_next);

  return 0 if defined($transform) and scalar(@$transform) != $k;

  # magic
  $ostream->{WRITE}->(Bit::Vector->new_Hex(16,"5346"),2);
  $header_size += 2;

  # version
  $ostream->{WRITE}->(Bit::Vector->new_Dec(8,$version),1);
  $header_size += 1;

  # Set up and write options byte
  my ($opt_large_k,$opt_large_s,$opt_transform);

  my $kvec;
  if ($k < 256) {
    $kvec=Bit::Vector->new_Dec(8,$k);
    $opt_large_k=0;
  } elsif ($k < 65536) {
    $kvec=Bit::Vector->new_Dec(16,$k);
    $opt_large_k=1;
  } else {
    return 0;
  }

  my $svec;
  if ($s < 256) {
    $svec=Bit::Vector->new_Dec(8,$s);
    $opt_large_s=0;
  } elsif ($s < 65536) {
    $svec=Bit::Vector->new_Dec(16,$s);
    $opt_large_s=1;
  } else {
    return 0;
  }

  $opt_transform=(defined($transform) ? 1 : 0);

  $ostream->{WRITE}->(
      Bit::Vector->new_Dec(8,
			   ($opt_large_k)        |
			   ($opt_large_s)   << 1 |
			   ($opt_final)     << 2 |
			   ($opt_transform) << 3),
		      1);
  $header_size += 1;

  # write k and s values
  $ostream->{WRITE}->($kvec, $opt_large_k + 1);
  $header_size += $opt_large_k + 1;

  $ostream->{WRITE}->($svec, $opt_large_s + 1);
  $header_size += $opt_large_s + 1;

  # chunk_start, chunk_next
  my ($width,$topval);

  if ($chunk_start == 0) {
    $ostream->{WRITE}->(Bit::Vector->new_Dec(8,0),1);
      $header_size += 1;
  } else {
    ($width,$topval)=(1,255);
    while ($chunk_start > $topval) {	# need another byte?
      ++$width; $topval = ($topval << 8) + 255;
    };
    $ostream->{WRITE}->(Bit::Vector->new_Dec(8,$width),1);
    $ostream->{WRITE}->(
	Bit::Vector->new_Dec(8 * $width,$chunk_start), $width);
    $header_size += 1 + $width;
  }

  if ($chunk_next == 0) {
    $ostream->{WRITE}->(Bit::Vector->new_Dec(8,0),1);
      $header_size += 1;
  } else {
    ($width,$topval)=(1,255);
    while ($chunk_next > $topval) {	# need another byte?
      ++$width; $topval = ($topval << 8) + 255;
    };
    $ostream->{WRITE}->(Bit::Vector->new_Dec(8,$width),1);
    $ostream->{WRITE}->(
        Bit::Vector->new_Dec(8*$width,$chunk_next),$width);
    $header_size += 1 + $width;
  }

  if ($opt_transform) {
    foreach my $elem (@$transform) {
      $ostream->{WRITE}->($elem,$s);
      $header_size += $s;
    }
  }

  return $header_size;
}

sub rabin_ida_split {
  my $opts=shift;
  my $rc;
  my $fail=0;

  $fail=check_encode_opts($opts);
  return $fail if $fail;

  # copy options into local variables
  my ($k,$n,$order,$istream,$ostreams,$transform,$helper,
      $range_start,$range_next,$timer, $quiet) =
       map {
	exists($opts->{$_}) ? $opts->{$_} : undef;
      } qw(k n order istream sharestreams transform helper 
	   range_start range_next timer quiet);

  my $sec_level=int($order/8);
  $quiet = 0 unless defined($quiet);


  # pre-supplied transform variables, or generate our own at random?
  if (defined($transform)) {
    check_transform($k,$n,$order,$transform);
  } else {
    $transform=gen_random_transform($k,$n,$order);
  }

  # Set up the irreducible polynomial of the appropriate $order
  my $polyref=$irreducibles[$sec_level-1];
  my $poly_spec=join ",", (@$polyref, 0); # set x^0 but not x^$order
  #print "sec_level= $sec_level; poly_spec = $poly_spec\n";
  my $poly=Bit::Vector->new_Enum($order,$poly_spec);

  # Create the actual transform matrix from the transform array
  my @matrix=();
  for my $row (0 .. $n-1) {
    my $matrix_row=[];
    for my $col (0 .. $k-1) {
      my $x=$transform->[$row];
      my $y=$transform->[$n+$col];
      my $sum=$x->Shadow;
      $sum->Xor($x,$y);
      push @$matrix_row,gf2_mult_inv($poly,$sum);
    }
    push @matrix,$matrix_row;
  }

  # If range_start, range_next are not defined, then set them to
  # (0,filesize). Also set up opt_final
  my $filesize=-s ($istream->{FILENAME}->());
  my $opt_final=0;
  $range_start=0 unless defined $range_start;
  if (defined ($range_next)) {
    if ($range_next == $filesize) {
      $opt_final=1;
    } elsif ($range_next > $filesize) {
      die "Range end is beyond end of file\n";
    }
  } else {
    $range_next=$filesize;
    $opt_final=1;
  }

  # Write header for each ostream
  my $header_size=undef;
  for my $i (0..scalar(@$ostreams)-1) {
    my $header_info=
      {
       version => 1, opt_final => $opt_final,
       k => $k, s => $sec_level,
       chunk_start => $range_start, chunk_next => $range_next,
       transform => $matrix[$i]
      };
    my $wrote=write_ida_header($ostreams->[$i],$header_info);
    if ($wrote == 0) {
      die "Failed to write header for share $i\n";
    }
    if (defined($header_size) and $wrote != $header_size) {
      # this shouldn't really happen
      die "Some shares had different numbers of header bytes\n";
    } else {
      $header_size=$wrote;
    }
  }

  print "header size back from write_ida_header is $header_size\n";

  # multiply matrix x istream matrix, one istream matrix column at a time.
  my $zero=Bit::Vector->new($order);            # used for padding at eof
  if (defined($helper)) {
    my @sharefiles=map { $_->{FILENAME}->() } @$ostreams;
    $helper->{PREPARE}->($n,$k,$sec_level,$poly,$header_size,
			 $istream->{FILENAME}->(),undef,\@sharefiles,
			 [($zero) x ($k - 1)],undef,$timer);
    $helper->{MATRIX}->(\@matrix);
    if (defined $range_start and defined $range_next) {
      $helper->{RANGE}->("$range_start-$range_next");
    }
  }

  if (defined($helper)) {

    $helper->{SPLIT}->("0-". ($n-1));
    my $line;
    while (1) {
      $|=1;
      $line=$helper->{READ}->();
      last unless defined $line;
      if ($line=~/^OK/) {
	print "$line";
	$rc = 0;	 	# OK
	last;
      }	elsif ($line=~/^ERROR/) {
	print "$line";
	$rc = 1;		# NOK
	last;
      } elsif ($line=~/^(WARN)/) {
	print "$line";
      } else {
	print $line unless $quiet;
      }
    }

  } else {

    # Perl implementation is about 25 times slower than C ...
    #
    my $first;
    while ($first=$istream->{READ}->()) {
      my @col=($first,map { $istream->{READ}->() or $zero } (1..$k-1));

      for my $row (0 .. $n - 1) {
	my $total=gf2_mult($poly, $matrix[$row]->[0], $col[0]);
	for my $column (1 .. $k -1) {
	  $total->Xor($total,
		      gf2_mult($poly,
			       $matrix[$row]->[$column], $col[$column]));
	}
	$ostreams->[$row]->{WRITE}->($total);
      }
    }
  }
  return $rc;
}

sub rabin_ida_recombine {
  my ($istreams,$ostream,$helper,$quiet,@junk)=@_;

  $quiet = 0 unless defined($quiet);

  # Information about k, security level, transform rows and chunk
  # range should be stored in each share header, so we don't need to
  # have them passed to us explicitly

  my ($k,$sec_level,$width,$filesize,$order)=((undef) x 5);
  my $rc = 0;
  my @matrix=();

  # Read in headers from each istream
  my $shares=0;
  my $header_info;
  my $header_size=undef;
  my ($range_start,$range_next);
  foreach my $istream (@$istreams) {

    $header_info=read_ida_header($istream,$k,$sec_level,$range_start,
				 $range_next,$header_size);

    if ($header_info->{error}) {
      die $header_info->{error_message};
    }

    # These values must be consistent across all shares
    $k           = $header_info->{k};
    $sec_level   = $header_info->{s};
    $range_start = $header_info->{chunk_start};
    $range_next   = $header_info->{chunk_next};
    $header_size = $header_info->{header_size};

    unless ($header_info->{opt_transform}) {
      die "Share file contains no transform data. Can't proceed\n";
    }

    if (++$shares <= $k) {
      push @matrix, $header_info->{transform};
    } else {
      warn "Redundant share detected\n";
      last;
    }
  }

  $header_size=$header_info->{header_length};

  $order=$header_info->{security} * 8;
  my $polyref=$irreducibles[$sec_level-1];
  my $poly_spec=join ",", (@$polyref, 0); # set x^0 but not x^$order
  my $poly=Bit::Vector->new_Enum($order,$poly_spec);

  # Now that the header has been read in and all the streams agree on
  # k, sec_level we proceed to build the inverse matrix using
  # Gauss-Jordan elimination
  gauss_jordan_invert(\@matrix,$k,$order,$poly);

  # At this point, we should have an inverse matrix in @matrix...  We
  # should be able to read in one word from each stream to generate a
  # new input column. Multiplying inverse x column will give us k
  # output words.

  my ($n)=$k;
  my $zero=Bit::Vector->new($order);
  if (defined($helper)) {
    my @sharefiles=map { $_->{FILENAME}->() } @$istreams;
    $helper->{PREPARE}->($n,$k,$sec_level,$poly,$header_size,
			 undef,$ostream->{FILENAME}->(),\@sharefiles,
			 [($zero) x ($k - 1)],undef,undef);
    $helper->{INVERSE}->(\@matrix);
    if (defined $range_start and defined $range_next) {
      $helper->{RANGE}->("$range_start-$range_next");
    }
  }


  if (defined($helper)) {

    $helper->{COMBINE}->("0-". ($n-1));
    my $line;
    while (1) {
      $|=1;
      $line=$helper->{READ}->();
      last unless defined $line;
      if ($line=~/^OK/) {
	print "$line";
	$rc = 0;	 	# OK
	last;
      }	elsif ($line=~/^ERROR/) {
	print "$line";
	$rc = 1;		# NOK
	last;
      } elsif ($line=~/^(WARN)/) {
	print "$line";
      } else {
	print $line unless $quiet;
      }
    }

  } else {

    # Perl implementation is about 25 times slower than C ...
    #
    my $eof=0;
    while (1) {
      my @col=();
      for  (0..$k-1)  {
	my $word=$istreams->[$_]->{READ}->($sec_level);
	if (defined($word)) {
	  push @col,$word;
	} else {
	  ++$eof;
	}
      }

      # did all input files end just now?
      last if ($eof == $k);

      if ($eof > 0 and $eof < $k) {
	die "Input streams are of different lengths. Output truncated.\n";
      }

      # perform matrix multiplication on this column
      for my $row (0 .. $k - 1) {
	my $total=gf2_mult($poly, $matrix[$row]->[0], $col[0]);
	for my $column (1 .. $k -1) {
	  $total->Xor($total,
		      gf2_mult($poly,
			       $matrix[$row]->[$column], $col[$column]));
	}
	$ostream->{WRITE}->($total,$sec_level);
      }
    }
  }

  # If this is a final chunk, chop off any extraneous padding that may
  # have been added during split (SPE helper does this already)
  if ($header_info->{opt_final}) {
    my $of=$ostream->{FILENAME}->();
    print "Truncating output file '$of' to $header_info->{chunk_next} bytes\n";
    truncate $of, $header_info->{chunk_next};
  }

  return $rc;
}

#
# Test routines
#

sub test_gf2_mult {


  my $poly_spec="4,3,1,0";
  my $poly=Bit::Vector->new_Enum(8,$poly_spec);

  my $x=Bit::Vector->new_Hex(8,"53"); # these two values are
  my $y=Bit::Vector->new_Hex(8,"CA"); # multiplicative inverses

  # expect z to be 1
  my $z=gf2_mult($poly,$x,$y);

  print $x->to_Bin, " x ", $y->to_Bin, " = ",
    $z->to_Bin, " (mod 1", $poly->to_Bin, ")\n";

  $z=gf2_mult($poly,$y,$x);

  print $y->to_Bin, " x ", $x->to_Bin, " = ",
    $z->to_Bin, " (mod 1", $poly->to_Bin, ")\n";

  $x=Bit::Vector->new_Hex(16,"01b1");
  $y=Bit::Vector->new_Hex(16,"c350");
  $poly=Bit::Vector->new_Hex(16,"100b");
  $z=gf2_mult($poly,$x,$y);
  print $y->to_Hex, " x ", $x->to_Hex, " = ",
    $z->to_Hex, " (mod 1", $poly->to_Hex, ") (expected {b07f})\n";

}

sub test_split_recombine {
  open OUTPUT, ">/tmp/rabin-c-secret.txt";
  print OUTPUT "The quick brown fox jumps over the slow lazy dog\n";
  close OUTPUT;

  my ($k,$n,$order)=(8,8,8);

  # symmetric test cases
  #my ($k,$n,$order)=(8,8,8);
  #my ($k,$n,$order)=(8,8,16);
  #my ($k,$n,$order)=(8,8,128);

  # larger test cases
  #my ($k,$n,$order)=(8,16,16);
  #my ($k,$n,$order)=(8,16,128);

#  my $helper=mk_helper_process("/home/dec/src/Crypto-IDA/mylib/rabin-ida");
#  my $helper=mk_helper_process("tee /dev/tty | /home/dec/src/Crypto-IDA/mylib/rabin-ida");
#  my $helper=mk_helper_process("/home/dec/src/rabin");
  my $helper=
    mk_helper_process(
		      "tee ./split_combine.cmd ".
		      "| /home/dec/src/learn-spe2/07-shebang/host");

  #$helper=undef;

  SPLIT: {
      my $istream=mk_file_istream("/tmp/32kb.pak",$order/8);

      die "Failed to open istream\n" unless $istream;

      print "#k=$k; n=$n; order=$order\n";

      my $ostreams=[];
      for my $i (0..$n-1) {
	my $ostream=mk_file_ostream("/tmp/rabin-c-share-$i.txt",$order/8);
	die "Failed to create ostream\n" unless $ostream;
	push @$ostreams, $ostream;
      }

      rabin_ida_split( {
			header_version => 1,
			k=>$k, n=>$n, order=>$order, istream=>$istream,
			sharestreams=>$ostreams, helper=>$helper, timer=>5
		       } );
    }

  $helper->{RESET}->() if defined($helper);

 RECOMBINE: {

      my $istreams=[];
      for my $i (0..$n-1) {
	my $istream=mk_file_istream("/tmp/rabin-c-share-$i.txt",$order/8);
	die "Failed to read istream\n" unless $istream;
	push @$istreams, $istream;
      }

      # pick k of the n input streams to use
      fisher_yates_shuffle($istreams,$k);

      my $ostream=mk_file_ostream("/tmp/rabin-c-recombine.txt",$order/8);
      die "Failed to create ostream\n" unless $ostream;

      rabin_ida_recombine($istreams,$ostream,$helper);
    }

  $helper->{RESET}->() if defined($helper);

}


sub test_gf2_mult_inv {

  my $poly_spec="4,3,1,0";
  my $poly=Bit::Vector->new_Enum(8,$poly_spec);

  my $x=Bit::Vector->new_Hex(8,"53");

  my $y=gf2_mult_inv($poly,$x,1);

  print $x->to_Bin, " x ", $y->to_Bin, " = 1 (mod 1", $poly->to_Bin, ")\n";

  $x=gf2_mult_inv($poly,$y);

  print $y->to_Bin, " x ", $x->to_Bin, " = 1 (mod 1", $poly->to_Bin, ")\n";

}

sub test_gcd {
  my ($a,$b)=@ARGV;

  print "GCD:  ", gcd($a,$b), "\n";
  my $inverse=multiplicative_inverse($a,$b);
  print "INV:  $inverse\n";
}

sub test_chunky_split_recombine {

  my $word=Bit::Vector->new_Enum(16,0); # 0x0001
  my $test_stream= mk_file_ostream("/tmp/rabin-c-secret.txt",2);
  my $i;

  die "Oops: didn't create ostream\n" unless defined($test_stream);

  for $i (1..16384) {
    $test_stream->{WRITE}->($word);
    $word->increment();
  }
  $test_stream->{CLOSE}->();
  $test_stream=undef;

  my ($k,$n,$order)=(3,7,32);

  #my ($k,$n,$order)=(8,8,8);

  # symmetric test cases
  #my ($k,$n,$order)=(8,8,8);
  #my ($k,$n,$order)=(8,8,16);
  #my ($k,$n,$order)=(8,8,128);

  # larger test cases
  #my ($k,$n,$order)=(8,16,16);
  #my ($k,$n,$order)=(8,16,128);

  my $chunk_size=3;

  # if chunk_size is too low, then rounding down to zero is possible
  # below, so we might have to round back up afterwards
  if (($chunk_size % ($k * $order /8))) {
    print "Rounding down chunk size from $chunk_size to be a multiple of ",
      ($k * $order /8), "\n";
    $chunk_size-=($chunk_size % ($k * $order /8));
    print "New Chunk size is $chunk_size\n";
  }
  unless ($chunk_size) {
    $chunk_size = $k * $order / 8;
    print "Rounding chunk size of 0 back up to k * w = $chunk_size\n";
  }


  # As an alternative to specifying a chunk size, we could also
  # calculate chunk size as a fraction of the input file size, or
  # start with a target chunk size. If we use the latter, we have to
  # take the length of the file header into account in the output
  # share files. In all cases, we have to round the chunk size to a
  # multiple of k * sec_level, ie the length in bytes of one column of
  # the input matrix.

#  my $helper=mk_helper_process("/home/dec/src/Crypto-IDA/mylib/rabin-ida");
#  my $helper=mk_helper_process("/home/dec/src/rabin");

  my $helper=
    mk_helper_process(
		      "tee ./split_combine.cmd ".
		      "| /home/dec/src/learn-spe2/07-shebang/host");

  my ($chunk,$chunk_start,$chunk_next)=(0,0,$chunk_size);

  #$helper=undef;

  SPLIT: {
      my $istream=mk_file_istream("/tmp/32kb.pak",$order/8);

      die "Failed to open istream\n" unless $istream;

      print "#k=$k; n=$n; order=$order\n";

      my $filesize=-s $istream->{FILENAME}->();

      while ($chunk_start < $filesize) {
	my $ostreams=[];
	for my $i (0..$n-1) {
	  my $ostream=
	    mk_file_ostream("/tmp/rabin-c-chunk-$chunk-share-$i.txt",
			    $order/8);
	  die "Failed to create ostream\n" unless $ostream;
	  push @$ostreams, $ostream;
	}

	rabin_ida_split(
          {
	   range_start => $chunk_start, range_next => $chunk_next,
	   header_version => 1,
	   k=>$k, n=>$n, order=>$order, istream=>$istream,
	   sharestreams=>$ostreams, helper=>$helper, timer=>5,
	  } );

	# close all files in this batch
	foreach my $ostream (@$ostreams) {
	  $ostream->{CLOSE}->();
	}

	# increment range counters for next chunk
	++$chunk;
	$chunk_start+=$chunk_size;
	$chunk_next  +=$chunk_size;
	$chunk_next=$filesize if $chunk_next > $filesize;

	# clear any data stored by the helper process
	$helper->{RESET}->() if defined($helper);
      }

      print "Created ", --$chunk, " chunks\n";

    }


  $helper->{RESET}->() if defined($helper);

 RECOMBINE: {

    # Now do the reverse. We know how many chunks were created, so we
    # can generate the filenames and be sure that they match up with
    # each other.

    my @chunklist=(0..$chunk);

    my $ostream=mk_file_ostream("/tmp/rabin-c-recombine.txt",$order/8);
    die "Failed to create ostream\n" unless $ostream;

    # we can shuffle the list if we want, but for simple testing, we
    # might as well process them in order.

    fisher_yates_shuffle(\@chunklist);

    for my $chunk (@chunklist) {

      my $istreams=[];
      for my $i (0..$n-1) {
	my $istream=
	  mk_file_istream("/tmp/rabin-c-chunk-$chunk-share-$i.txt",$order/8);
	die "Failed to read istream\n" unless $istream;
	push @$istreams, $istream;
      }

      print "Attempting to recombine chunk $chunk of file\n";

      # pick k of the n input streams to use
      #fisher_yates_shuffle($istreams,$k);

      for my $stream (@$istreams) {
	print "Using share: ", $stream->{FILENAME}->(), "\n";
      }

      rabin_ida_recombine($istreams,$ostream,$helper);

      # close all files in this batch
      foreach my $istream (@$istreams) {
	$istream->{CLOSE}->();
      }

      $helper->{RESET}->() if defined($helper);

    }
  }
}

sub benchmark_multiplication {

  my $bufsize=4096;

  for my $bytes (1,2,4) {

    my $poly;
    my @b1=();			# buffers to fill with random values
    my @b2=();			# then multiply
    my $count=0;
    my $time_up=0;
    my $result;

    my $rng=rng_init($bytes);

    unless (defined($rng)) {
      warn "Failed to init random number generator to create $bytes-bytes words\n";
      return;
    }
    for (1..$bufsize) {
      push @b1,$rng->();
      push @b2,$rng->();
    }

    my $polyref=$irreducibles[$bytes-1];
    my $poly_spec=join ",", (@$polyref, 0); # set x^0 but not x^$order

    $poly=Bit::Vector->new_Enum($bytes*8,$poly_spec);

    print "poly is ", $poly->to_Hex, "\n";

    local $SIG{ALRM}=sub { $time_up=1; };
    alarm(10);

    until ($time_up) {
      for (0..$bufsize-1) {
	$result=gf2_mult($poly,$b1[$_],$b2[$_]);
      }
      $count+=4096;
    }

    print "Speed test on $bytes-byte words completed. Performed ";
    print "". (($count /10.0 / 1024.0) / 1024.0) . " M*/s\n";

    $rng->("begone!");

  }
}

#test_poly_84310;
#test_gf2_mult_inv;
#test_gf2_mult;
#test_mk_file_istream;
#test_rng_init;
#test_fisher_yates_shuffle;
#test_mk_file_ostream;
#test_gen_and_check_transform;
#test_split_recombine;
#test_chunky_split_recombine;
#test_gauss_jordan_invert;
#benchmark_multiplication;

# Re-implementation of basic split/combine based on command-line
# options. Doesn't implement chunking.
sub cmdline_split {

  my %opts = (
	      infile => undef,
	      k => undef,
	      n => undef,
	      w => undef,
	      filespec => undef,
	      helper => undef,
	      quiet => 0,
	      @_,
	     );


  my $infile   = $opts{infile};
  my $k        = $opts{k};
  my $n        = $opts{n};
  my $w        = $opts{w};
  my $filespec = $opts{filespec};
  my $helper   = undef;
  my $quiet    = $opts{quiet};

  if (defined($opts{helper})) {
    $helper=mk_helper_process($opts{helper});
  }

  # if the filespec contains a %s as part of a directory name, create
  # the relevant directory names before making ostreams below. Also
  # declare some other variables needed for converting filespec to an
  # actual file name.
  my $create_dirs = 0;
  my ($dir_name, $share_name, $share_num);
  my $share_digits = length("" . ($n-1));
  if ($filespec =~ m|.*\%s.*/|) {
    $create_dirs  = 1;
  }

  my $istream=mk_file_istream($infile,$w);

  die "Failed to open istream\n" unless $istream;

  print "#k=$k; n=$n; w=$w\n";

  my $ostreams=[];
  for my $i (0..$n-1) {
    $share_num = sprintf("%0*d", $share_digits, $i); # zero-pad
    $share_name = $filespec;
    # expand filespec: do %s first in case infile contains that pattern
    $share_name =~ s|\%s|$share_num|g;
    $share_name =~ s|\%f|$infile|g;
    if ($create_dirs) {
      $dir_name = $share_name;
      $dir_name =~ s|(.*)/(.*)|$1|;
      unless (scalar (mkpath ($dir_name))) {
	die "Failed to create directory '$dir_name'\n";
      }
    }
    my $ostream=mk_file_ostream($share_name,$w);
    die "Failed to create ostream '$share_name'\n" unless $ostream;
    push @$ostreams, $ostream;
  }

  my $rc =
    rabin_ida_split( {
		      header_version => 1,
		      k=>$k, n=>$n, order=>$w * 8, istream=>$istream,
		      sharestreams=>$ostreams, helper=>$helper, timer=>5,
		      quiet => $quiet,
		     } );

  $helper->{QUIT}->() if defined($helper);

  return $rc;
}

sub cmdline_combine {

  my %opts = (
	      outfile => undef,
	      helper => undef,
	      quiet => 0,
	      sharefiles => undef,
	      @_,
	     );

  my $outfile    = $opts{outfile};
  my $helper     = undef;
  my $quiet      = $opts{quiet};
  my $sharefiles = $opts{sharefiles};

  if (defined($opts{helper})) {
    $helper=mk_helper_process($opts{helper});
  }

  my $istreams=[];
  foreach my $sharefile (@$sharefiles) {
    # combine always overrides how many bytes we set below ...
    #    print "input share file: $sharefile\n";
    my $istream=mk_file_istream($sharefile,4);
    die "Failed to read istream\n" unless $istream;
    push @$istreams, $istream;
  }

  my $ostream=mk_file_ostream($outfile,4);
  die "Failed to create ostream\n" unless $ostream;

  rabin_ida_recombine($istreams,$ostream,$helper,$quiet);

}

# Main routine. Just a simple getopt-based command-arg handler

# Options
my $mode      = shift || "";
my $prog      = $0; $prog =~ s|.*/||;

# Split opts: required / no default
my $infile    = undef;
my $quorum    = undef;
my $shares    = undef;

# Split opts: optional / with default
my $width     = 1;
my $filespec  = '%f-%s.sf';

# Combine opts: optional / with default
my $outfile   = 'ida-combine.out';

# Common opts: optional / with default
my $need_help = 0;
my $tee_file  = undef;
my $go_slow   = 0;
my $helper    = $0; $helper =~ s|(.*)/.*|$1/ida-helper-ps3|;
my $quiet     = 0;

my $usage = <<HELP;
$prog : split/combine file using Rabin's IDA (PS3 version)

Usage:

 $prog split   [split-opts]   infile
 $prog combine [combine-opts] share0 share1 ...

Split options (* = required):

 -i file  --infile file       Set input file (alternative method)
 -k int   --quorum int      * Set quorum ("threshold") value to int
 -n int   --shares int      * Set number of shares to int
 -w int   --width int,        Set field width to 1, 2 or 4 bytes
          --security int      (default: 1)
 -P patt  --filespec patt     Name sharefiles using pattern

 Pattern for naming output sharefiles (default: "$filespec"):

    \%f   original (input) filename
    \%s   share number (0 .. shares - 1)

Combine options:

 -o file  --outfile file      Set output file (default: "$outfile")

Common options:

 -h       --help              View this help message and exit
 -t file  --tee file          Save helper command script to file
 -S       --slow, --nohelper  Use Perl-only codec (very slow)
 -H prog  --helper prog       Path to user-supplied helper program
 -q       --quiet             Suppress (most) helper program messages

Default helper program:

  $helper

HELP

# get different options depending on mode

Getopt::Long::Configure ("bundling");
if ($mode eq "split") {

  my $r=GetOptions ( "i|infile=s"           => \$infile,
		     "k|quorum=i"           => \$quorum,
		     "n|shares=i"           => \$shares,
		     "w|width|s|security=i" => \$width,
		     "P|filespec=s"         => \$filespec,
		     ## common options ##
		     "h|help"               => \$need_help,
		     "t|tee=s"              => \$tee_file,
		     "S|slow|nohelper"      => \$go_slow,
		     "H|helper=s"           => \$helper,
		     "q|quiet"              => \$quiet,
		   );
  $infile=shift unless defined $infile;

} elsif ($mode eq "combine") {

  my $r=GetOptions ( "o|outfile=s"          => \$outfile,
		     ## common options ##
		     "h|help"               => \$need_help,
		     "t|tee=s"              => \$tee_file,
		     "S|slow|nohelper"      => \$go_slow,
		     "H|helper=s"           => \$helper,
		     "q|quiet"              => \$quiet,
		   );
} else {
  ++ $need_help;
}


# Check common options
die $usage if $need_help;

if ($go_slow) {
  warn "$prog: warning: using slow mode as instructed\n";
  $helper = undef;
  if (defined($tee_file)) {
    warn "$prog: warning: --tee has no effect with --slow option\n";
    $tee_file = undef;
  }
} else {
  die "$prog: helper program '$helper' does not exist\n"
    unless -f $helper;
  die "$prog: helper program '$helper' is not an executable\n"
    unless -x $helper;
}

if (defined($tee_file)) {
  if (defined($infile) and $tee_file eq $infile) {
    die "$prog: argument to --tee is the same as the input file\n";
  }
  if (defined($outfile) and $tee_file eq $outfile) {
    die "$prog: argument to --tee is the same as the output file\n";
  }
  if ($tee_file eq $helper) {
    die "$prog: argument to --tee is the same as the helper program!\n";
  }
  $helper = "tee '$tee_file' | '$helper'";
}


if ($mode eq "split") {

  unless (defined($quorum) and defined($shares) and
	  defined($infile)) {
    die "$prog: Not all required parameters were supplied\n";
  }
  unless ($filespec =~ m|\%s|) {
    die "$prog: filespec pattern must contain '\%s' for share no.\n";
  }


  my $rc =
    cmdline_split( infile => $infile,
		   k => $quorum,
		   n => $shares,
		   w => $width,
		   filespec => $filespec,
		   slow => $go_slow,
		   helper => $helper,
		   quiet => $quiet,
		 );
  exit ($rc);

} elsif ($mode eq "combine") {


  my $rc =
    cmdline_combine( outfile => $outfile,
		     slow => $go_slow,
		     helper => $helper,
		     quiet => $quiet,
		     sharefiles => [@ARGV],
		   );
  exit ($rc);


} else {

  die "Shouldn't get here\n";
}



1;
__END__

