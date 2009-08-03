package Crypt::IDA::ShareFile;

use 5.008008;
use strict;
use warnings;
use Carp;

use Crypt::IDA;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( sf_calculate_chunk_sizes
				    sf_split sf_combine) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '0.01';
our $classname="Crypt::IDA::ShareFile";

# I could eliminate the use of closures below, but it makes for a
# convenient wrapper for handling byte order issues, and also for
# implementing the "dry run" parameter to sf_write_ida_header later.
our $mk_file_istream = sub {
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
       # internally after 32 bits, though, so there may be possible
       # precision errors). I'm disabling this since I don't think
       # it's acceptable. The only upshot for the rest of the program
       # is that file size is now limited to 4Gb - 1 byte.
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

our $mk_file_ostream = sub {
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
# bytes   name          value
# 2       magic         marker for "Share File" format; "SF" = {5346}
# 1       version       file format version = 1
# 1       options       options bits (see below)
# 1-2     k,quorum      quorum k-value (set both names on read)
# 1-2     s,security    security level s-value (set both names on read)
# var     chunk_start   absolute offset of chunk in file
# var     chunk_next    absolute offset of next chunk in file
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

our  $sf_read_ida_header = sub {
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
our $sf_write_ida_header = sub {
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
      header_version => 1,
      # pick one method of calculating chunk size. The file is not
      # broken into chunks unless one of these is defined.
      n_chunks => undef,
      in_chunk_size => undef,
      out_chunk_size => undef,
      out_file_size => undef,
      @_,
     );

  


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
      # supply either a list of key parameters or a matrix
      key => undef,
      matrix => undef,
      # misc options
      header_version => 1,
      rand => "/dev/urandom",
      bufsize => 4096,
      # pick one method of calculating chunk size. The file is not
      # broken into chunks unless one of these is defined.
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
	   chunk_start => $chunk_start, chunk_next => $chunk_next,
	   header_version => 1,
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

    my @chunklist=(0..$chunk);

    my $ostream=mk_file_ostream("/tmp/rabin-c-recombine.txt",$order/8);
    die "Failed to create ostream\n" unless $ostream;

    # we can shuffle the list if we want, but for simple testing, we
    # might as well process them in order.

#    fisher_yates_shuffle(\@chunklist);

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

      rabin_ida_recombine($istreams,$ostream);

      # close all files in this batch
      foreach my $istream (@$istreams) {
	$istream->{CLOSE}->();
      }

    }
  }
}

