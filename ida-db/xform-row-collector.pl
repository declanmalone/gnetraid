#!/usr/bin/env perl

use strict;
use warnings;

use File::Find;
use File::ExtAttr qw(:all);;
use Digest::SHA;

#use Crypt::IDA ":default";
use Crypt::IDA::ShareFile;

my ($debug,$trace);

my $usage = <<"EOT";
$0 : Scan shares directory and collect shares' transform row data

Usage:

  $0 sharefile_dir/ > report.txt

EOT


# The code for scanning trees comes from scan-tree3.pl, with option to
# (re)create and save hash tags removed.

# This is new to this file: extract xform row

sub get_sharefile_xform_row {
    my $filename = shift;
    my $source = Crypt::IDA::ShareFile->sf_mk_file_istream($filename, 1);

    #warn "Source $source (ref " . ref($source) . ")\n";
    die "$filename: failed making istream\n" unless ref $source;

    my $header = Crypt::IDA::ShareFile::sf_read_ida_header($source);

    die "$filename: Failed to read header\n" unless ref $header;

    # we have to convert the transform row to hex or else we have
    # problems with reading file in line by line (thanks to "\n")

    my $hex = join "", map {sprintf("%02x",$_)} @{$header->{transform}};
    return $hex;
    
    if ($debug) {
	warn "Read transform row: ["
	    . (join ", ", map
	       {sprintf("%02x",$_) } @{
		   $header->{transform}
	       }) 
	    .  "]\n";
    }

    return pack "C*", @{$header->{transform}};
}

# Return the sha256 tag from a file, or '' if it is missing or too old
my $shatag = "shatag.sha256";
my $sha_ts = "shatag.ts";
sub get_shatag {

    my ($fullname, $mtime) = @_;
    my ($sum, $tag_time);

    $tag_time = getfattr($fullname,$sha_ts);
    return '' unless defined($tag_time);
    chomp $tag_time;		# strip trailing ".0"
    chomp $tag_time;		# from attribute value
    
    return '' if $mtime > $tag_time;
    
    $sum = getfattr($fullname,$shatag) || '';

    return $sum;
}

# In order to bottom-up hashing of directory contents, we need to
# either use a stack or something to emulate one. Here, I'm using a
# hash since it's easier to understand what's going on.
my %dir_entries = ();
my %dir_size = ();
sub scan_file {
  my $dir      = $File::Find::dir;
  my $fullname = $File::Find::name;

  return if -l  "$fullname";
  return unless -f $fullname or -d $fullname;
  
  warn "Getting stat info\n" if $debug;
  my @statinfo;
  unless (@statinfo = stat $fullname) {
      warn "failed to stat $fullname\n";
      return;
  }
  warn "Testing file $fullname succeeded\n" if $debug;
  
  my ($inum, $uid, $gid, $size, $mtime) = @statinfo[1,4,5,7,9];
  
  warn "Getting shasum\n" if $debug;
  
  my $shasum = get_shatag($fullname, $mtime);
  
  warn "shasum is [$shasum]\n" if $debug;

  if (-f "$fullname") {
  
      # don't bother calculating SHA256 hash, but warn if out of date
      if ($shasum eq '') {
	  warn "$fullname: file hash tag is missing or out of date\n";
      }

      # read xform data as a C array of bytes/chars
      my $xform = get_sharefile_xform_row($fullname);
      
      warn "printing results\n" if $debug;
      print join("\0", $fullname,$size,$shasum,$xform) . "\n";

      # Save directory entries
      s|.*/||;
      $dir_entries{"$dir"}.= "$_: $shasum\n";
      $dir_size{"$dir"}   += $size;
      return;
  }

  # Process directory entries

  # also use SHA256 for hashing $dir_list
  my $sha = Digest::SHA->new('sha256') ||
      die "Failed to create Digest::SHA object. Aborting\n";
  $sha->add($dir_entries{"$_"});
  $shasum = $sha->hexdigest;

  print "fullname $fullname, dir $dir, entry $_\n" if $trace;
  print "Dir has contents:\n$dir_entries{$_}\n"  if $trace;

  $size = $dir_size{$_};
  delete $dir_size{$_};
  $dir_size{"$dir"}   += $size;  

  delete $dir_entries{$_};
  s|.*/||;
  $dir_entries{$dir} .= "$_/: $shasum\n";

  # need to update SHA256 hash
  my $shatag = get_shatag($fullname, $mtime);
  if ($shatag ne $shasum) {
      warn "$fullname: dir hash tag is missing or out of date\n";
  }

  # print same format entry as regular file, except for trailing / on filename
  print join("\0", "$fullname/", $size, $shasum) . "\n";
  
}

die $usage if ($ARGV[0] eq "-h");
die "Unknown option $ARGV[0]\n" if $ARGV[0] =~ /^-/;

my $root = shift || die "Specify a directory to scan\n";

die "Must give a directory argument\n" unless -d $root;

finddepth ({ wanted => \&scan_file,
	     no_chdir => 1,
	     preprocess => sub {
		 # Put in some arbitrary text. Don't use empty
		 # string so that we can distinguish between hashes
		 # of empty files and empty dirs
		 $dir_entries{$File::Find::dir} = "Directory\n";
		 $dir_size   {$File::Find::dir} = 0; 
		 print "preprocessing $File::Find::dir\n" if $trace;
		 return sort { $a cmp $b} @_ },
	   }, ($root));
