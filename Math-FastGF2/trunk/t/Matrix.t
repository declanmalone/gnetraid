# -*- Perl -*-

use Test::More tests => 109;
BEGIN { use_ok('Math::FastGF2::Matrix', ':all') };

my $failed;
my $class="Math::FastGF2::Matrix";

# Create a 1x1 square matrix?
my $onesquare;
for my $w (1,2,4) {
  $onesquare=Math::FastGF2::Matrix->new(rows=>1, cols =>1, width=>$w);
  ok((defined($onesquare) and ref($onesquare) eq $class),
     "Create 1x1 matrix, width $w?");
}

# Create a 2x2 matrix and do some tests on it
my $m=Math::FastGF2::Matrix->new(rows=>2, cols =>2, width=>1);

ok(ref($m) eq $class,    "new returns correct class?");
ok($m->ROWS == 2,        "ROWS returns correct value?");
ok($m->COLS == 2,        "COLS returns correct value?");
ok($m->WIDTH == 1,       "WIDTH returns correct value?");
ok($m->ORG eq "rowwise", "ORG returns correct value?");

$failed=0;
map { ++$failed if $m->getval($_/2, $_ & 1) } 0..3;
ok (!$failed,  "All values initialised to zero?");

$failed=0;
map { ++$failed if $_ * 7 + 1 != $m->setval($_/2, $_ & 1, $_ * 7 + 1) } 0..3;
ok (!$failed,  "setval returns set value?");

$failed=0;
map { ++$failed if $_ * 7 + 1 != $m->getval($_/2, $_ & 1) } 0..3;
ok (!$failed,  "setval/getval returns same value?");

# Now on to a bigger matrix, and do multiply/inverse/
# equality/getvals/setvals tests
my @mat8x8 = (
	      ["35","36","82","7A","D2","7D","75","31"],
	      ["0E","76","C3","B0","97","A8","47","14"],
	      ["F4","42","A2","7E","1C","4A","C6","99"],
	      ["3D","C6","1A","05","30","B6","42","0F"],
	      ["81","6E","F2","72","4E","BC","38","8D"],
	      ["5C","E5","5F","A5","E4","32","F8","44"],
	      ["89","28","94","3C","4F","EC","AA","D6"],
	      ["54","4B","29","B8","D5","A4","0B","2C"],
	     );
my @inv8x8 = (
	      ["3E","02","23","87","8C","C0","4C","79"],
	      ["5D","2B","2A","5B","7E","FE","25","36"],
	      ["F2","A9","B5","57","A2","F6","A2","7D"],
	      ["11","5E","E4","61","59","F4","B9","42"],
	      ["D5","16","B8","5B","30","85","1E","72"],
	      ["3B","F7","1B","5B","4C","55","35","04"],
	      ["58","95","73","33","8A","77","1C","F4"],
	      ["59","C0","7B","13","9F","8B","BE","E3"],
	     );
my @identity8x8 = (
		   [1,0,0,0,0,0,0,0],
		   [0,1,0,0,0,0,0,0],
		   [0,0,1,0,0,0,0,0],
		   [0,0,0,1,0,0,0,0],
		   [0,0,0,0,1,0,0,0],
		   [0,0,0,0,0,1,0,0],
		   [0,0,0,0,0,0,1,0],
		   [0,0,0,0,0,0,0,1],
		  );

# in-place conversion of hex strings to decimal values
map { map { $_ = hex } @$_ } @mat8x8;
map { map { $_ = hex } @$_ } @inv8x8;

my ($r,$c,$m8x8,$i8x8,$r8x8,$id8x8);
$m8x8 = Math::FastGF2::Matrix->new(rows=>8, cols =>8, width=>1);
$i8x8 = Math::FastGF2::Matrix->new(rows=>8, cols =>8, width=>1);
$id8x8= Math::FastGF2::Matrix->new(rows=>8, cols =>8, width=>1);

ok(ref($m8x8)  eq "Math::FastGF2::Matrix", "Create 8x8 matrix OK?");
ok(ref($i8x8)  eq "Math::FastGF2::Matrix", "Create 8x8 inverse matrix OK?");
ok(ref($id8x8) eq "Math::FastGF2::Matrix", "Create 8x8 result matrix OK?");

# Before we write any values to the matrices below, we can check to
# make sure that they were created with all values initially set to
# zero.
$failed=0;
for $r (0..7) {
  for $c (0..7) {
    ++$failed if $m8x8->getval($r,$c) or $i8x8->getval($r,$c) 
      or $id8x8->getval($r,$c);
    $m8x8 ->setval($r,$c,$mat8x8[$r][$c]);
    $i8x8 ->setval($r,$c,$inv8x8[$r][$c]);
    $id8x8->setval($r,$c,$identity8x8[$r][$c]);
  }
}

ok ($failed == 0, "8x8 matrix values all initialised to zero on init?");

# multiply without supplying a result matrix
$r8x8=$m8x8->multiply($i8x8);
ok(defined($r8x8),   "multiply method returns some value?");
ok(ref($r8x8) eq "Math::FastGF2::Matrix", "multiply returns correct class?");

# multiply with a supplied result matrix
my $r2=$m8x8->multiply($i8x8,$r8x8);
ok(defined($r2),  "multiply returns value with supplied result matrix?");
ok($r2 eq $r8x8,  "multiply returns supplied result matrix?");

# Checking equality
ok($r8x8->eq($r2),   "Equality test on same matrix?");
ok($r8x8->ne($m),    "Inequality test on differently-sized matrices?");
ok($r8x8->ne($m8x8), "Inequality test on differently-valued matrices?");

# is matrix x inverse = identity?
ok($r8x8->eq($id8x8), "Matrix x Inverse == Identity?");

# Test getvals in scalar context
my $row="3536827AD27D7531";	  # first row of m8x8
my $got= $m8x8->getvals(0,0,8); # get first 8 values
my $packed_row=pack "H16", $row;
ok (length $got == 8, "Scalar return from getvals of correct length?");
ok ($got eq $packed_row,  "Correct scalar return from getvals?");

# Test getvals in list context
my @row=$m8x8->getvals(0,0,8); # get first 8 values
ok (scalar(@row) == 8,  "number of returned items in getvals list?");
$failed=0;
map { ++$failed if $row[$_] != $m8x8->getval(0, $_) } 0..7;
ok (!$failed,  "Correct list return from getvals?");

# Test setvals... using ROWWISE
$m=Math::FastGF2::Matrix->new(rows => 2, cols => 2, width => 1,
			      org=> "rowwise"); # be explicit
my @vals=(65, 66, 67, 68);
my $str=$m->setvals(0,0,\@vals);
ok (length $str == 4, "setvals returns string of correct length, given list?");

my $str2=$m->getvals(0,0,4);

ok ($str eq $str2, "getvals ($str2) == setvals ($str)?");

ok ($m->getval(0,0) == $vals[0],  "setvals (rowwise) sets (0,0) correctly?");
ok ($m->getval(0,1) == $vals[1],  "setvals (rowwise) sets (0,1) correctly?");
ok ($m->getval(1,0) == $vals[2],  "setvals (rowwise) sets (1,0) correctly?");
ok ($m->getval(1,1) == $vals[3],  "setvals (rowwise) sets (1,1) correctly?");

# Test setvals... using COLWISE
$m=Math::FastGF2::Matrix->new(rows => 2, cols => 2, width => 1,
			      org=> "colwise"); # be explicit
ok (ref($m) eq $class,  "Created colwise matrix OK?");
$str=$m->setvals(0,0,\@vals);
ok (length $str == 4, "setvals returns string of correct length, given list?");

$str2=$m->getvals(0,0,4);

ok ($str eq $str2, "getvals ($str2) == setvals ($str)?");

ok ($m->getval(0,0) == $vals[0],  "setvals ([], colwise) sets (0,0) correctly?");
ok ($m->getval(1,0) == $vals[1],  "setvals ([], colwise) sets (1,0) correctly?");
ok ($m->getval(0,1) == $vals[2],  "setvals ([], colwise) sets (0,1) correctly?");
ok ($m->getval(1,1) == $vals[3],  "setvals ([], colwise) sets (1,1) correctly?");

# setvals with a string..
$m=Math::FastGF2::Matrix->new(rows => 2, cols => 2, width => 1,
			      org=> "colwise");
$str=$m->setvals(0,0,$str);
ok ($m->getval(0,0) == $vals[0],  "setvals (\$\$, colwise) sets (0,0) correctly?");
ok ($m->getval(1,0) == $vals[1],  "setvals (\$\$, colwise) sets (1,0) correctly?");
ok ($m->getval(0,1) == $vals[2],  "setvals (\$\$, colwise) sets (0,1) correctly?");
ok ($m->getval(1,1) == $vals[3],  "setvals (\$\$, colwise) sets (1,1) correctly?");

# Checking equality #2... rowwise vs colwise matrix
my @by_row=(65,66,67,68);
my @by_col=(65,67,66,68);
my $m_by_row=Math::FastGF2::Matrix->new(rows => 2, cols => 2, width => 1,
					 org=> "rowwise");
my $m_by_col=Math::FastGF2::Matrix->new(rows => 2, cols => 2, width => 1,
					 org=> "colwise");
$m_by_row->setvals(0,0,\@by_row);
$m_by_col->setvals(0,0,\@by_col);

ok ($m_by_row->eq($m_by_col),        "rowwise-to-colwise compare eq?");
$m_by_col->setval(1,1,69);
ok ($m_by_row->ne($m_by_col),        "rowwise-to-colwise compare ne?");

# Check rowcol_to_offset and offset_to_rowcol
my ($offset);

ok (((($r,$c)=$m_by_col->offset_to_rowcol(0)),
    $r==0 and $c==0),      "Offset 0 -> (0,0) (colwise)?");
ok (((($r,$c)=$m_by_col->offset_to_rowcol(1)),
     $r==1 and $c==0),      "Offset 1 -> (1,0) (colwise)?");
ok (((($r,$c)=$m_by_col->offset_to_rowcol(2)),
    $r==0 and $c==1),      "Offset 2 -> (0,1) (colwise)?");
ok (((($r,$c)=$m_by_col->offset_to_rowcol(3)),
     $r==1 and $c==1),      "Offset 3 -> (1,1) (colwise)?");

ok (((($r,$c)=$m_by_row->offset_to_rowcol(0)),
     $r==0 and $c==0),      "Offset 0 -> (0,0) (rowwise)?");
ok (((($r,$c)=$m_by_row->offset_to_rowcol(1)),
     $r==0 and $c==1),      "Offset 1 -> (0,1) (rowwise)?");
ok (((($r,$c)=$m_by_row->offset_to_rowcol(2)),
     $r==1 and $c==0),      "Offset 2 -> (1,0) (rowwise)?");
ok (((($r,$c)=$m_by_row->offset_to_rowcol(3)),
     $r==1 and $c==1),      "Offset 3 -> (1,1) (rowwise)?");

ok ($m_by_row->rowcol_to_offset(0,0) == 0,
                              "(0,0) -> Offset 0  (rowwise)?");
ok ($m_by_row->rowcol_to_offset(0,1) == 1,
                              "(0,1) -> Offset 1  (rowwise)?");
ok ($m_by_row->rowcol_to_offset(1,0) == 2,
                              "(1,0) -> Offset 2  (rowwise)?");
ok ($m_by_row->rowcol_to_offset(1,1) == 3,
                              "(1,1) -> Offset 3  (rowwise)?");

ok ($m_by_col->rowcol_to_offset(0,0) == 0,
                              "(0,0) -> Offset 0  (colwise)?");
ok ($m_by_col->rowcol_to_offset(0,1) == 2,
                              "(0,1) -> Offset 2  (colwise)?");
ok ($m_by_col->rowcol_to_offset(1,0) == 1,
                              "(1,0) -> Offset 1  (colwise)?");
ok ($m_by_col->rowcol_to_offset(1,1) == 3,
                              "(1,1) -> Offset 3  (colwise)?");

# Some tests using non-square matrices (similar to previous tests)
$m=Math::FastGF2::Matrix->new(rows => 3, cols => 7, width => 1,
			      org=> "colwise");
ok ($m->rowcol_to_offset(0,0) == 0,
                              "(0,0) -> Offset 0  (colwise)?");
ok ($m->rowcol_to_offset(0,6) == 18,
                              "(0,6) -> Offset 18  (colwise)?");
ok ($m->rowcol_to_offset(2,0) == 2,
                              "(2,0) -> Offset 2  (colwise)?");
ok ($m->rowcol_to_offset(2,6) == 20,
                              "(2,6) -> Offset 20  (colwise)?");

ok (((($r,$c)=$m->offset_to_rowcol(0)),
    $r==0 and $c==0),      "Offset 0 -> (0,0) (colwise)?");
ok (((($r,$c)=$m->offset_to_rowcol(2)),
     $r==2 and $c==0),     "Offset 2 -> (2,0) (colwise)?");
ok (((($r,$c)=$m->offset_to_rowcol(18)),
    $r==0 and $c==6),      "Offset 18 -> (0,6) (colwise)?");
ok (((($r,$c)=$m->offset_to_rowcol(20)),
     $r==2 and $c==6),     "Offset 20 -> (2,6) (colwise)?");

# Some more checks on (set|get)val(s?) for multi-byte words
my @wide_values=(0x4142,0x41424344);
# pack/unpack formats for unsigned short (16-bit) or unsigned long
# (32-bit)
my @native_pack=(undef,undef,"S*",undef,"L*");

for my $test_width (2,4) {

  my $wide_mat=Math::FastGF2::Matrix->new(rows => 2, cols => 2,
					  org => "rowwise",
					  width => $test_width);

  # need extra parentheses below because ',' binds tighter than 'and'
  ok ((defined ($wide_mat) and ref ($wide_mat) eq $class),
      "Create 2x2 rowwise matrix with width $test_width?");

  my $wide_value=shift @wide_values;

  #warn "wide value is ". (sprintf "%0*x", $test_width,
  #			  $wide_value) ."\n";

  # First, check that basic getval/setval work as advertised with
  # multi-byte words
  $wide_mat->setval(0,0,$wide_value);
  ok ($wide_mat->getval(0,0) == $wide_value,
      "getval/setval works with $test_width-byte words?");
  ok ($wide_mat->getval(0,1) == 0,
      "setval with $test_width-byte words overruns!");

  # zero matrix again in case error above causes spurious message for
  # next tests.
  $wide_mat->setval(0,0,0);
  $wide_mat->setval(0,1,0);
  $wide_mat->setval(1,0,0);
  $wide_mat->setval(1,1,0);

  # test that setvals doesn't write more or less than it should
  # list write method first
  $wide_mat->setvals(0,0,[$wide_value]);
  ok ($wide_mat->getval(0,0) == $wide_value,
      "Writing $test_width-byte word as string?");
  #warn "---> got back value " . (sprintf "%0*x", $test_width,
  #			$wide_mat->getval(0,0)) . "\n";
  ok ($wide_mat->getval(0,1) == 0,
      "Writing $test_width-byte word as string overruns!");

  # zero matrix again in case error above causes spurious message for
  # next tests.
  $wide_mat->setval(0,0,0);
  $wide_mat->setval(0,1,0);
  $wide_mat->setval(1,0,0);
  $wide_mat->setval(1,1,0);

  # setvals with string method. Use native byte order (other byte
  # order tests are handled later)
  $wide_mat->setvals(0,0,
		     pack $native_pack[$test_width], $wide_value);
  ok ($wide_mat->getval(0,0) == $wide_value,
      "Writing $test_width-byte word as list?");
  #warn "---> got back value " . (sprintf "%0*x", $test_width,
  #			$wide_mat->getval(0,0)) . "\n";
  ok ($wide_mat->getval(0,1) == 0,
      "Writing $test_width-byte word as list overruns!");
}


# Test transpose matrix function

# Test byte order flags for getvals, setvals
#
# The module doesn't export any functions or data which can be used to
# detect the byte order on this machine. This is a design decision--
# the user shouldn't have to worry about such things and they
# shouldn't be made to query/save/check the byte order. The ability to
# set an explicit byte order for given data is all that's needed.
# However, for testing, it'll help if we can divine this machine's
# actual byte order so that we only have to write one set of tests
# (otherwise we'd have to keep two sets of tests, and be sure that
# they're always consistent with each other).

# The values of these variables don't matter, only that they're the
# reverse of each other. Array is indexed by width in bytes.
my @native_vals=(undef,undef,0x0201,undef,0x04030201);
my @reverse_vals=(undef,undef,0x0102,undef,0x01020304);

# similar array to @native_pack. See manpage for pack
my @big_pack=(undef,undef,"n*",undef,"N*");
my @little_pack=(undef,undef,"v*",undef,"V*");

for my $test_width (2,4) {

  # Use the same numbering for storing our endian-ness as the module
  # does: 1=little endian, 2=big endian
  my $endian;			# our endian
  my $oendian;			# the "other" endian

  # first create a a 1x1 test matrix
  my $emat=Math::FastGF2::Matrix->new(rows => 1, cols => 1,
				      org  => "rowwise",
				      width => $test_width);
  ok ((defined ($emat) and ref($emat) eq $class),
      "Create 1x1 matrix with width $test_width?");

  # the getval and setval routines all deal with native-endian values
  $emat->setval(0,0,$native_vals[$test_width]);

  # But we need to test getvals, setvals. First make sure that when we
  # don't set a byte order that the value matches what was put
  # in. Need to check for return in both list and string context.
  my (@got_back,$got_back_string,$got_back_value);

  @got_back=$emat->getvals(0,0,1);
  ok ($got_back[0] == $native_vals[$test_width],
      "no byteorder flag, got back same value as put in (list context)?");

  $got_back_string=$emat->getvals(0,0,1);
  $got_back_value=unpack $native_pack[$test_width], $got_back_string;
  ok ($got_back_value == $native_vals[$test_width],
      "no byteorder flag, got back same value as put in (string context)?");

  # Since we haven't explictly tested setting byteorder to zero yet, do it here
  @got_back=$emat->getvals(0,0,1,0);
  ok ($got_back[0] == $native_vals[$test_width],
      "byteorder 0, got back same value as put in (list context)?");

  $got_back_string=$emat->getvals(0,0,1,0);
  $got_back_value=unpack $native_pack[$test_width], $got_back_string;
  ok ($got_back_value == $native_vals[$test_width],
      "byteorder 0, got back same value as put in (string context)?");

  # Now we can check byte order settings...
  my ($string1,$string2,$val1,$val2);

  # evaluate getvals in list context
  ($val1)=$emat->getvals(0,0,1,1);
  ($val2)=$emat->getvals(0,0,1,2);

  ok ($val1 ne $val2,
      "different order for w=$test_width returns the same values!");

  $failed=0;
  if ($val1 eq $native_vals[$test_width]) {
    $endian=1;
    ++$failed unless $val2 eq $reverse_vals[$test_width];
  } elsif ($val1 eq $reverse_vals[$test_width]) {
    $endian=2;
    ++$failed unless $val2 eq $native_vals[$test_width];
  } else {
    ++$failed;
  }
  ok ($failed==0,
      "$test_width-byte order doesn't return either val or reverse!");

  $oendian= 3 - $endian;	# 3 - 1 = 2, 3 - 1 = 2

  # now we can check calling getval in string string context since now
  # that we know our endian value, we can figure out how to unpack the
  # returned strings.

  # Firstly, using S (native unsigned 16 bit) or L (native unsigned 32
  # bit) should always work if we set endian to our native endian
  # value.
  $string1=pack $native_pack[$test_width], $native_vals[$test_width];
  ok ($emat->getvals(0,0,1,$endian) eq $string1,
      "$test_width-byte word doesn't unpack to same as native unpack!");
  # and the reverse ...
  $string2=pack $native_pack[$test_width], $reverse_vals[$test_width];
  ok ($emat->getvals(0,0,1,$oendian) eq $string2,
      "$test_width-byte word doesn't unpack to reverse of alien unpack!");

  # The next check might be redundant, but we can test that explicitly
  # setting the order parameter to our endian-ness gives similar
  # results to calling pack/unpack with the same explicit template.
  $string1=pack $endian == 1 ? 
    $little_pack[$test_width] : $big_pack[$test_width],
      $native_vals[$test_width];
  ok ($emat->getvals(0,0,1,$endian) eq $string1,
      "$test_width-byte word doesn't unpack to same with our endian");

  # Finally, we've been doing all these checks for getvals. Rather
  # than rewriting all the tests to check setvals in a similar way, we
  # can rely on previous multi-byte tests that showed that values for
  # getvals/setvals matched and only check for correspondence when we
  # pass an explicit byte order flag.
  $emat->setvals(0,0,[$native_vals[$test_width]],$endian);
  ok ($emat->getval(0,0) == $native_vals[$test_width],
      "setvals on native $test_width-byte word equals getval?");
  $emat->setvals(0,0,[$native_vals[$test_width]],$oendian);
  ok ($emat->getval(0,0) == $reverse_vals[$test_width],
      "setvals on native $test_width-byte word reverses getval?");
}

		
