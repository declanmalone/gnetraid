package Crypt::IDA::ShareFile;

use 5.008008;
use strict;
use warnings;
use Carp;

use Crypt::IDA;

use Fcntl qw(:DEFAULT :seek);

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'DEFAULT' => [ qw( sf_calculate_chunk_sizes
					sf_split sf_combine) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'DEFAULT'} } );
our @EXPORT = qw( );

our $VERSION = '0.01';
our $classname="Crypt::IDA::ShareFile";

# I could eliminate the use of closures below, but it makes for a
# convenient wrapper for handling byte order issues, and also for
# implementing the "dry run" parameter to sf_write_ida_header later.
sub sf_mk_file_istream {
  my ($self,$class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self=shift;
    $class=ref($self);
  } else {
    $self=$classname;
  }
  my ($filename,$default_bytes_per_read)=@_;
  my ($fh,$eof)=(undef,0);

  # basic checking of args
  if (!defined($filename) or !defined($default_bytes_per_read) or
      $default_bytes_per_read <= 0 or $default_bytes_per_read > 8 or
      int($default_bytes_per_read) != $default_bytes_per_read) {
    return undef;
  }
  die "using istream with >32 bits would lead to precision errors\n"
    if $default_bytes_per_read > 4;

  # try opening the file; use sysopen to match better with later sysreads
  return undef unless sysopen $fh,$filename,O_RDONLY;

  # Use closure/callback technique to provide an iterator for this file
  my $methods=
    {
     FILENAME => sub { $filename },
     FH => sub { $fh },
     READ => sub {
       # This reads words from the file in network (big-endian) byte
       # order, with zero padding in the least significant bytes. So,
       # for example, if we are using 2-byte chunks and the file
       # contains three bytes 0d fe 2d, then two reads on the file
       # will return the values 0dfe and 2d00. Return values are
       # integers or undef on eof.

       my ($override_bytes,$bytes_to_read);

       if ($override_bytes=shift) {
	 $bytes_to_read=$override_bytes;
	 die "Invalid bytes to read $bytes_to_read" if
	   int($bytes_to_read) != $bytes_to_read or $bytes_to_read <= 0;
	 die "using istream with >32 bits would lead to precision errors\n"
	   if $bytes_to_read > 4;
       } else {
	 $bytes_to_read=$default_bytes_per_read;
       }

       my $buf="";
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

       # Convert these bytes into a number (first byte is high byte )
       $buf=pack "a$bytes_to_read", $buf; # pad zeroes on right
       #$buf.="\0" x ($bytes_to_read - length $buf);

       # hex() can only handle values up to 32 bits, but perl scalars
       # can handle up to 64 bits (they're upgraded to floats
       # internally after 32 bits, though). I'm disabling this since I
       # don't think it's acceptable. The only upshot for the rest of
       # the program is that file size is now limited to 4Gb - 1 byte.
       my $val=0;
#       while ($bytes_to_read > 4) {
#	 $val=unpack "N", (substr $buf,0,4,"");
#	 $bytes_to_read-=4;
#	 $val <<= 32;
#       }
       my $hex_format="H" . ($bytes_to_read * 2); # count nibbles
       return hex unpack $hex_format, $buf;

     },
     EOF => sub {
       return $eof;
     },
     SEEK => sub {
       seek $fh, shift, 0;
     },
     TELL => sub {
       tell $fh;
     },
     CLOSE => sub {
       close $fh;
     }
    };
  return $methods;
}

sub sf_mk_file_ostream {
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
     FILENAME => sub { $filename },
     FH => sub { $fh },
     WRITE => sub {
       my $num=shift;

       my ($override_bytes,$bytes_to_write);

       if ($override_bytes=shift) {
	 $bytes_to_write=$override_bytes;
       } else {
	 $bytes_to_write=$default_bytes_per_write;
       }

       # Writing is a little easier than reading, but we have to take
       # care if the number passed is too large to fit in the
       # requested number of bytes.  If it's too large a warning will
       # be emitted and we discard any extra *high* bits.

       my $buf="";

       if ($num >= 256 ** $bytes_to_write) {
	 warn "ostream: Number too large. Discarded high bits.\n";
	 $num %= (256 ** ($bytes_to_write) - 1);
       }

       my $hex_format="H" . ($bytes_to_write * 2);
       $buf=pack $hex_format, sprintf "%0*x", $bytes_to_write*2, $num;
       syswrite $fh,$buf,$bytes_to_write;

     },
     EOF => sub {
       0;
     },
     FILENAME => sub {
       return $filename;
     },
     FLUSH => sub {
       0; # syswrite doesn't buffer, so no need to flush
     },
     SEEK => sub {
       seek $fh, shift, 0;
     },
     TELL => sub {
       tell $fh;
     },
     CLOSE => sub {
       close $fh;
     }
    };
  return $methods;		# be explicit
}


# Routines to read/write share file header
#
# header version 1
#
# bytes  name           value
# 2      magic          marker for "Share File" format; "SF" = {5346}
# 1      version        file format version = 1
# 1      options        options bits (see below)
# 1-2    k,quorum       quorum k-value (set both names on read)
# 1-2    s,security     security level s-value (width in bytes)
# var    chunk_start    absolute offset of chunk in file
# var    chunk_next     absolute offset of next chunk in file
# var    transform      transform matrix row
#
# The options bits are as follows:
#
# Bit    name           Settings
# 0      opt_large_k    Large (2-byte) k value?
# 1 	 opt_large_s    Large (2-byte) s value?
# 2 	 opt_final      Final chunk in file? (1=full file/final chunk)
# 3 	 opt_transform  Is transform data included?
#
# Note that the chunk_next field is 1 greater than the actual offset
# of the chunk end. In other words, the chunk ranges from the byte
# starting at chunk_start up to, but not including the byte at
# chunk_next. That's why it's called chunk_next rather than chunk_end.
#
# More on this: it might seem that it's ok to refuse to split a
# zero-length file, but if we're using this for backups, it's not a
# good idea to fail just because we don't like zero-length
# files. Also, splitting a zero-length file might be useful in some
# cases, since we might be interested in just creating and storing a
# transform matrix for later use, or maybe generating test cases or
# debugging a matrix inverse routine.

sub sf_read_ida_header {
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
  my ($k,$s,$start,$next,$hdr)=@_;

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
    if ($vec=$istream->{READ}->($bytes), defined($vec)) {
      if (defined ($conversion)) {
	if ($conversion eq "hex") {
	  $vec=sprintf "%*x", $bytes, $vec;
	} elsif ($conversion eq "dec") {
	  $vec=$vec;		# istream already returns integers
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
  if ($offset_width > 4) {
    return header_error("File size must be less than 4Gb!\n");
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
  if ($offset_width > 4) {
    return header_error("File size must be less than 4Gb!\n");
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
  if (defined($next) and $next != $header_info->{chunk_next}) {
    return header_error("Inconsistent chunk_next values read from streams\n");
  } else {
    $next=$header_info->{chunk_next};
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
sub sf_write_ida_header {
  my ($self,$class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self=shift;
    $class=ref($self);
  } else {
    $self=$classname;
  }
  my %header_info=(
		   dry_run => 0,
		   @_
		  );
  my $header_size=0;		

  # save to local variables
  my ($ostream,$version,$k,$s,$chunk_start,$chunk_next,
      $transform,$opt_final,$dry_run) =
    map {
      exists($header_info{$_}) ? $header_info{$_} : undef
    } qw(ostream version quorum width chunk_start chunk_next transform
	 opt_final dry_run);

  return 0 unless defined($version) and $version == 1;
  return 0 unless defined($k) and defined($s) and
    defined($chunk_start) and defined($chunk_next);

  return 0 if defined($transform) and scalar(@$transform) != $k;

  if ($dry_run) {
    $ostream={
	      WRITE => sub { "do nothing" },
	     };
  }

  # magic
  $ostream->{WRITE}->(0x5346,2);
  $header_size += 2;

  # version
  $ostream->{WRITE}->($version,1);
  $header_size += 1;

  # Set up and write options byte
  my ($opt_large_k,$opt_large_s,$opt_transform);

  if ($k < 256) {
    $opt_large_k=0;
  } elsif ($k < 65536) {
    $opt_large_k=1;
  } else {
    return 0;
  }

  if ($s < 256) {
    $opt_large_s=0;
  } elsif ($s < 65536) {
    $opt_large_s=1;
  } else {
    return 0;
  }

  $opt_transform=(defined($transform) ? 1 : 0);

  $ostream->{WRITE}->((
		       ($opt_large_k)        |
		       ($opt_large_s)   << 1 |
		       ($opt_final)     << 2 |
		       ($opt_transform) << 3),
		      1);
  $header_size += 1;

  # write k and s values
  $ostream->{WRITE}->($k, $opt_large_k + 1);
  $header_size += $opt_large_k + 1;

  $ostream->{WRITE}->($s, $opt_large_s + 1);
  $header_size += $opt_large_s + 1;

  # chunk_start, chunk_next
  my ($width,$topval);

  if ($chunk_start == 0) {
    $ostream->{WRITE}->(0,1);
    $header_size += 1;
  } else {
    ($width,$topval)=(1,255);
    while ($chunk_start > $topval) {	# need another byte?
      ++$width; $topval = ($topval << 8) + 255;
    };
    $ostream->{WRITE}->($width,1);
    $ostream->{WRITE}->($chunk_start, $width);
    $header_size += 1 + $width;
  }

  if ($chunk_next == 0) {
    $ostream->{WRITE}->(0,1);
    $header_size += 1;
  } else {
    ($width,$topval)=(1,255);
    while ($chunk_next > $topval) {	# need another byte?
      ++$width; $topval = ($topval << 8) + 255;
    };
    $ostream->{WRITE}->($width,1);
    $ostream->{WRITE}->($chunk_next,$width);
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

# The following routine is exportable, since the caller may wish to
# know how large chunks are going to be before actually generating
# them. This could be useful, for example, if the caller needs to know
# how large the chunks are before deciding where to put them, or for
# trying out a different chunk size/strategy if the first one didn't
# suit their requirements.
#
sub sf_calculate_chunk_sizes {
  my ($self,$class);
  my %o;

  # despite the routine name, we'll calculate several different values
  # relating to each chunk:
  #  chunk_start
  #  chunk_next
  #  chunk_size   (chunk_next - chunk_start)
  #  file_size    (including header)
  #  final        (is the last chunk in the file?)
  #  padding      (how many bytes of padding are needed? final chunk only)
  #
  # We store these in a hash, and return a list of references to
  # hashes, one for each chunk.

  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self=shift;
    $class=ref($self);
  } else {
    $self=$classname;
  }
  %o=(
      quorum => undef,
      width => undef,
      filename => undef,
      # misc options
      version => 1,		# header version
      save_transform => 1,	# whether to store transform in header
      # pick one method of calculating chunk size. The file is not
      # broken into chunks unless one of these is defined.
      n_chunks => undef,
      in_chunk_size => undef,
      out_chunk_size => undef,
      out_file_size => undef,
      @_,
      dry_run => 1,		# for call to sf_write_ida_header
     );
  my @chunks=();
  my ($hs,$cb,$cn,$cs,$nc);

  # Copy options into local variables
  my ($k, $w, $filename, $version, $save_transform,
      $n_chunks, $in_chunk_size, $out_chunk_size, $out_file_size) =
    map {
      exists($o{$_}) ? $o{$_} : undef
    } qw(quorum width filename version
	 n_chunks in_chunk_size out_chunk_size out_file_size);

  # Check some input values (more checks later)
  unless ($w == 1 or $w == 2 or $w == 4) {
    carp "Invalid width value";
    return undef;
  }
  if ($k < 1 or $k >= 256 ** $w) {
    carp "quorum value out of range";
    return undef;
  }
  # leave version check until call to sf_write_ida_header

  # In all cases, we'll try to make all non-final chunks align to
  # $quorum x $width bytes. Whichever method is used, we need to know
  # what the total file size with/without padding will be.
  my $file_size=-s $filename;
  unless (defined($file_size)) {
    return undef;
  }
  my $padded_file_size=$file_size;
  while ($padded_file_size % ($k * $w)) {
    ++$padded_file_size;	# not very efficient, but it is easy
  }

  # We'll pass %o onto sf_write_ida_header later, so we need a dummy
  # value for transform if "save_transform" is set.
  if (defined($save_transform) and $save_transform) {
    $o{"transform"} = " " x ($k * $w);
  } else {
    $o{"transform"} = undef;
  }

  # Check that no more than one chunking method is set
  my $defined_methods=0;
  ++$defined_methods if (defined($n_chunks));
  ++$defined_methods if (defined($in_chunk_size));
  ++$defined_methods if (defined($out_chunk_size));
  ++$defined_methods if (defined($out_file_size));

  if ($defined_methods > 1) {
    carp "please select at most one method of calculating chunk sizes";
    return undef;
  } elsif ($file_size == 0 or $defined_methods == 0) {
    # we can also handle the special case where $file_size == 0 here
    unless ($file_size) {
      carp "warning: zero-sized file $filename; will use single chunk";
    }
    ($cb,$cn,$cs)=(0,$padded_file_size,$padded_file_size);
    $o{"chunk_start"} = $cb;
    $o{"chunk_next"}  = $cn;
    $hs=sf_write_ida_header(%o);
    unless (defined ($hs) and $hs > 0) {
      carp "Something wrong with header parameters.";
      return undef;
    }
    return ( {
	      "chunk_start" => $cb,
	      "chunk_next"  => $cn,
	      "chunk_size"  => $cs,
	      "file_size"   => $hs + $cs,
	      "final"       => 1,
	      "padding"     => $padded_file_size - $file_size,
	     } );
  }

  # on to the various multi-chunk methods ...
  if (defined($n_chunks)) {

    unless ($n_chunks > 0) {
      carp "Number of chunks must be greater than zero!";
      return undef;
    }
    my $max_n_chunks=$padded_file_size / ($k * $w);
    if ( $n_chunks > $max_n_chunks) {
      carp "File is too small for n_chunks=$n_chunks; using " .
	"$max_n_chunks instead";
      $n_chunks=$max_n_chunks;
    }

    # creating chunks of exactly the same size may not be possible
    # since we have to round to matrix column size. Rounding down
    # means we'll end up with a larger chunk at the end, while
    # rounding up means we might produce some zero-sized chunks at the
    # end. The former option is most likely the Right Thing. Even
    # though it might be nice to make the first chunk bigger, it's
    # easier to code if we let the last chunk take up any excess. To
    # do this we can round the chunk size up to the nearest multiple
    # of $n_chunks first, then round down to the nearest column
    # size. We should end up with a non-zero value since we've imposed
    # a limit on the maximum size of $n_chunks above.
    $cs  = int(($padded_file_size + $n_chunks - 1) / $n_chunks);
    $cs -= $cs % ($k * $w);
    die "Got chunk size of zero with file_size $padded_file_size, " .
      "n_chunks=$n_chunks (this shouldn't happen)\n" unless $cs;
    ($cb,$cn)=(0,$cs);
    for my $i (0 .. $n_chunks - 1) {
      $o{"chunk_start"} = $cb;
      $o{"chunk_next"}  = $cn;
      $hs=sf_write_ida_header(%o);
      unless (defined ($hs) and $hs > 0) {
	carp "Something wrong with header parameters for chunk $i.";
	return undef;
      }
      push @chunks, {
		     "chunk_start" => $cb,
		     "chunk_next"  => $cn,
		     "chunk_size"  => $cs,
		     "file_size"   => $hs + $cs,
		     "final"       => 1,
		     "padding"     => 0,
		    };
      $cb += $cs;
      $cn += $cs;
    }
    # Now fix up the details of the final chunk ...
    $chunks[$n_chunks - 1]->{"chunk_next"} = $padded_file_size;
    $chunks[$n_chunks - 1]->{"chunk_size"} = $padded_file_size - $cb;
    $chunks[$n_chunks - 1]->{"final"}      = 1;
    $chunks[$n_chunks - 1]->{"padding"}    = $padded_file_size - $file_size;

    die "last chunk starts beyond eof (this shouldn't happen)\n" if
      $cb >= $padded_file_size;

    # ... and return the array
    return @chunks;

  } elsif (defined($in_chunk_size)) {

    # this can actually be rolled into the above n_chunks method

    carp "not implemented yet\n";
    return undef;

  } elsif (defined($out_chunk_size)) {

    # this can actually be rolled into the above n_chunks method

    carp "not implemented yet\n";
    return undef;

  } elsif (defined($out_chunk_size)) {

    carp "not implemented yet\n";
    return undef;

  } else {
    die "problem deciding chunking method (shouldn't get here)\n";
  }

}



sub sf_split {

  my ($self,$class);
  my %o;

  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self=shift;
    $class=ref($self);
  } else {
    $self=$classname;
  }
  %o=(
      shares => undef,
      quorum => undef,
      width => undef,
      filename => undef,
      # supply a key, a matrix or neither
      key => undef,
      matrix => undef,
      # misc options
      version => 1,		# header version
      rand => "/dev/urandom",
      bufsize => 4096,
      # pick at most one chunking method. The file is not broken into
      # chunks unless one of these is defined.
      n_chunks => undef,
      in_chunk_size => undef,
      out_chunk_size => undef,
      out_file_size => undef,
      # allow creation of a subset of shares, chunks
      sharelist => undef,
      chunklist => undef,
      # specify pattern to use for share filenames
      filespec => undef,
      @_,
     );


  #my ($k,$n,$order)=(3,8,16);

  # symmetric test cases
  my ($k,$n,$order)=(8,8,8);
  #my ($k,$n,$order)=(8,8,16);
  #my ($k,$n,$order)=(8,8,128);

  # larger test cases
  #my ($k,$n,$order)=(8,16,16);
  #my ($k,$n,$order)=(8,16,128);

  my $chunk_size=4096;

  if ($chunk_size % ($k * $order /8)) {
    print "Rounding down chunk size from $chunk_size to be a multiple of ",
      ($k * $order /8), "\n";
    $chunk_size-=($chunk_size % ($k * $order /8));
    print "New Chunk size is $chunk_size\n";
  }

  # As an alternative to specifying a chunk size, we could also
  # calculate chunk size as a fraction of the input file size, or
  # start with a target chunk size. If we use the latter, we have to
  # take the length of the file header into account in the output
  # share files. In all cases, we have to round the chunk size to a
  # multiple of k * sec_level, ie the length in bytes of one column of
  # the input matrix.

  my ($chunk,$chunk_start,$chunk_next)=(0,0,$chunk_size);

  SPLIT: {
      my $istream=sf_mk_file_istream("/tmp/32kb.pak",$order/8);

      die "Failed to open istream\n" unless $istream;

      print "#k=$k; n=$n; order=$order\n";

      my $filesize=-s $istream->{FILENAME}->();

      while ($chunk_start < $filesize) {
	my $ostreams=[];
	for my $i (0..$n-1) {
	  my $ostream=
	    sf_mk_file_ostream("/tmp/rabin-c-chunk-$chunk-share-$i.txt",
			    $order/8);
	  die "Failed to create ostream\n" unless $ostream;
	  push @$ostreams, $ostream;
	}

	rabin_ida_split(
          {
	   chunk_start => $chunk_start, chunk_next => $chunk_next,
	   version => 1,
	   k=>$k, n=>$n, order=>$order, istream=>$istream,
	   sharestreams=>$ostreams,
	  } );

	# close all files in this batch
	foreach my $ostream (@$ostreams) {
	  $ostream->{CLOSE}->();
	}

	# increment range counters for next chunk
	++$chunk;
	$chunk_start += $chunk_size;
	$chunk_next  += $chunk_size;
	$chunk_next=$filesize if $chunk_next > $filesize;
      }

      print "Created ", --$chunk, " chunks\n";

    }

}

sub sf_combine {

  my ($chunk,$order,$n);;

  my @chunklist=(0..$chunk);

  my $ostream=sf_mk_file_ostream("/tmp/rabin-c-recombine.txt",$order/8);
  die "Failed to create ostream\n" unless $ostream;

  # we can shuffle the list if we want, but for simple testing, we
  # might as well process them in order.

  #    fisher_yates_shuffle(\@chunklist);

  for my $chunk (@chunklist) {

    my $istreams=[];
    for my $i (0..$n-1) {
      my $istream=
	sf_mk_file_istream("/tmp/rabin-c-chunk-$chunk-share-$i.txt",$order/8);
      die "Failed to read istream\n" unless $istream;
      push @$istreams, $istream;
    }

    print "Attempting to recombine chunk $chunk of file\n";

    # pick k of the n input streams to use
    #fisher_yates_shuffle($istreams,$k);

    for my $stream (@$istreams) {
      print "Using share: ", $stream->{FILENAME}->(), "\n";
    }

    rabin_ida_recombine($istreams,$ostream);

    # close all files in this batch
    foreach my $istream (@$istreams) {
      $istream->{CLOSE}->();
    }

  }
}

1;

__END__

=head1 NAME

Crypt::IDA::ShareFile - Archive file format for Crypt::IDA module

=head1 SYNOPSIS

  use Crypt::IDA::ShareFile ":DEFAULT";

=head1 DESCRIPTION

This module implements a file format for creating, storing and
distributing shares created with Crypt::IDA. Created files contain
share data and (by default) the corresponding transform matrix row
used to split the input file. This means that share files are
stand-alone in the sense that they may recombined later without
needing any other stored key or the involvement of the original
issuer.

In addition to creating a number of shares, the module can also handle
breaking the input file into several chunks before processing, in a
similar way to multi-volume PKZIP, ARJ or RAR archives. Each of the
chunks may be split into shares using a different transform matrix.
Individual groups of chunks may be re-assembled independently, as they
are collected and the quorum satisfied, or all shares of all chunks
may be combined at once.

=head2 EXPORT

No methods are exported by default. All methods may be called by
prefixing the method names with the module name, eg:

 $foo=Crypt::IDA::ShareFile::sf_split(...)

Alternatively, routines can be exported by adding ":DEFAULT" to the
"use" line, in which case the routine names do not need to be prefixed
with the module name, ie:

  use Crypt::IDA::ShareFile ":DEFAULT";
 
  $foo=Crypt::IDA::ShareFile::sf_split(...)
  # ...

Some extra ancillary routines can also be exported with the ":extras"
(just the extras) or ":all" (":extras" plus ":DEFAULT") parameters to
the use line. See the section L<ANCILLARY ROUTINES> for details.

=head1 SPLIT OPERATION

The template for a call to C<sf_split>, showing all default values,
is as follows:


The function returns ...

=head1 COMBINE OPERATION

The template for a call to C<sf_combine> is as follows:

The return value is ...

=head1 ANCILLARY ROUTINES

The extra routines are exported by using the ":extras" or ":all"
parameter with the initial "use" module line. The extra routines are
as follows:


=head1 KEY MANAGEMENT


=head2 Adding extra shares at a later time


=head2 In the event of lost or stolen shares


=head1 TECHNICAL DETAILS

=head2 File Format

Each share file consists of a header and some share data. For the
current version of the file format (version 1), the header format is
as follows:

  Bytes   Name           Value
  2       magic          marker for "Share File" format; "SF" = {5346}
  1       version        file format version = 1
  1       options        options bits (see below)
  1-2     k,quorum       quorum k-value (set both names on read)
  1-2     s,security     security level (ie, field width, in bytes)
  var     chunk_start    absolute offset of chunk in file
  var     chunk_next     absolute offset of next chunk in file
  var     transform      transform matrix row (optional)

All values stored in the header file (and the share data) are stored
in network (big-endian) byte order.

The options bits are as follows:

  Bit     name           Settings
  0       opt_large_k    Large (2-byte) k value?
  1 	  opt_large_s    Large (2-byte) s value?
  2 	  opt_final      Final chunk in file? (1=full file/final chunk)
  3 	  opt_transform  Is transform data included?

All file offsets are stored in a variable-width format. They are
stored as the concatenation of two values:

=over

=item * the number of bytes required to store the offset, and

=item * the actual file offset.

=back

So, for example, the offset "0" would be represented as the single
byte "0". An offset of 0x0321 would be represented as the hex bytes
"02", "03", "31".

Note that the chunk_next field is 1 greater than the actual offset of
the chunk end. In other words, each chunk ranges from the byte starting
at chunk_start up to, but not including the byte at chunk_next. That's
why it's called chunk_next rather than chunk_end.

=head1 LIMITATIONS

The current implementation is limited to handling input files less
than 4Gb in size. This is merely a limitation of the current header
handling code, and this restriction may by removed in a later version.

=head1 SEE ALSO

See the documentation for L<Crypt::IDA> for more details of the
underlying algorithm for creating and combining shares.

=head1 FUTURE VERSIONS

It is possible that the following changes/additions will be made in
future versions:

=head1 AUTHOR

Declan Malone, idablack@sourceforge.net

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Declan Malone

This package is free software; you can redistribute it and/or modify
it under the terms of version 2 (or, at your discretion, any later
version) of the "GNU General Public License" ("GPL").

Please refer to the file "GNU_GPL.txt" in this distribution for
details.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
