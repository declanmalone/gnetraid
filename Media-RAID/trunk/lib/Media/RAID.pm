package Media::RAID;

use warnings;
use strict;
use Carp;

=head1 NAME

Media::RAID - Implement a RAID-like backup system using Crypt::IDA::*

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module uses L<Crypt::IDA::ShareFile> to implement a flexible,
high-level RAID-like backup system. This is primarily designed for
working with removable hard drives, but can also be configured to
manage redundant backups on internal hard drives or network-accessible
mounts.

End users will probably want to use the media-raid script that comes
with this distribution instead of using this module directly, although
they may find some sections of this manual to be of some use in
understanding the overall design philosophy or creating configuration
files.

The general outline of using the module is outlined below:

   use Media::RAID;

   # initialise object and configure a RAID scheme
   my $raid = Media::RAID->new(global_opt => value, ...);
   $raid->add_scheme( <details of RAID scheme> );
   ...

   # various operations on files/backups
   $raid->scan(...); 	 # scan for 100% and RAID copies
   $raid->split(...); 	 # split files into RAID backup files
   $raid->compare(...);  # compare master files with RAID backup
   $raid->lint(...); 	 # report on orphaned files in RAID dirs
   $raid->delint(...);   # delete orphaned RAID files in dir
   $raid->move(...)      # move/rename original and RAID files
   ...

=head1 Setup Stage

=head2 Constructor

The constructor uses name => value pairs to set up any global options
that are effective across all RAID schemes. All options have default
values, as shown below:

   my $raid = Media::RAID->new
     (
       local_mount => "/media", # mount point for removable disks
       clobber     => 1,        # overwrite existing files?
       verbosity   => 0,        # level of verbosity
       dryrun      => 0,        # if set, warn instead of doing
                                # potentially destructive file ops
     );

On success, returns a Media::RAID object, or undef otherwise.

=cut

# Constructor

sub new {
  my $class = shift;
  my $self  = { options =>
		{
		 local_mount => "/media",
		 clobber     => 1,
		 verbosity   => 0,
		 dryrun      => 0,
		},
		schemes => {},
		hosts   => {},
	      };

  # read in global options
  # expect key => value pairs, so complain if we have an odd number of
  # args
  if ((0 + @_) & 1) {
    carp "Odd number of args passed to new; expected key => value args\n";
    return undef;
  }

  my %opts=(@_);
  while (my ($key,$value) = each %opts) {
    if ($key eq "clobber") {
      $self->{options}->{$key} = $value;
    } elsif ($key eq "verbosity") {
      $self->{options}->{$key} = $value;
    } elsif ($key eq "local_mount") {
      $self->{options}->{$key} = $value;
    } elsif ($key eq "dryrun") {
      $self->{options}->{$key} = $value;
    } else {
      carp "Unknown global option '$key'\n";
      # not fatal, so continue
    }
  }

  bless $self,$class;
  return $self;
}

=head2 Defining RAID schemes

=head3 Overview

Since this is the most complicated part of using the module, it is
broken up into several sections. The basic outline is:

  $rc = $raid->add_scheme
    (
      name => "(short,unique) name of this RAID scheme",
      description => "Human-readable description",
      master_dirs => { <details of dirs being managed> },
      raid => { <details of RAID scheme used to backup dirs> },
      # options local to this scheme:
      scan_others => 1,  # see scan method for details
    );

This defines a scheme for backing up all listed dirs using a
particular set of backup parameters. Multiple schemes may be set up,
each with their own parameters, eg, number of shares or backup
locations. As each scheme is defined by a call to add_scheme the
module does some checking to ensure that, for example, files from
different master directories cannot be mapped onto the same backup
RAID files.

As schemes are added, some working directories may be created or
updated based on the passed parameters. The contents of these
directories are subject to change and not documented here.

At the time of writing, the name assigned to the scheme is
unimportant, but future versions may allow for backing up the same
sets of master files using different, user-selectable backup schemes.
In anticipation of this, the module enforces uniqueness of scheme
names.

=head3 Specifying Master Directories

The master_dirs parameter is a (reference to a) hash of hashes, each
of which specifies the path of a master directory that is to be backed
up. There are two ways in which to specify master directories. The
first way is to specify a path on a removable hard disk:

  # directory resides on a (named) removable drive
  $raid->add_scheme
    (
      ...
      master_dirs => {
        "movies" =>                 # name of this group of files
          {
            drive => "Saturn",	    # volume label of drive
            path  => "video/movies" # path within drive
          },
          ...			# other dirs in this scheme
        }.
      ...  # other parameters to add_scheme
    );

This takes advantage of the fact that on most modern Unix/Linux
systems a removable hard disk can be given a volume label, and when it
is attached to the computer it will auto-mount at a predictable mount
point. The global option "local_mount" specifies the path where such
removable hard drives will be automounted, and defaults to "/media",
which is the standard location on Ubuntu systems.

Although not currently implemented, I intend to add the ability to
attempt to mount removable disks which are currently attached to other
computers on a LAN (or the internet) via protocols such as sshfs or
NFS. I intend for this abstraction to be applicable to both the master
files and the backed-up RAID system. (Thus, as well as providing
mathematical security for backed-up files (in the sense of having
redundant shares), physical security of backups could also be improved
(limiting the effect of things such as fires or break-ins).)

The second way to specify master directories is to give a path which
is normally available on the local machine, without needing any
special mount commands or the need to physically attach a disk:

  # OR: directory resides at a fixed path
  $raid->add_scheme
    (
      ...
      master_dirs => {
        "movies" =>
          {
            fixed => "/home/ida/Video", # absolute path
            path  => "/movies"          # relative to above path
          },
          ...			# other dirs in this scheme
        }.
      ...  # other parameters to add_scheme
    );

As with removable disks, the path to the directory being managed
(backed up) is broken into two parts. While not strictly necessary in
the case of fixed path names, repeating the pattern here allows for
better organisation of backup media. In fact, the path parameter is
used as part of the file name used for backup share files. As
mentioned previously, the add_scheme method checks for potential
filename clashes across all schemes, eliminating the possibility that
master files from two sets of backup schemes can end up writing to the
same backup file. It needs each "path" in each scheme to be
distinct. Therefore, although it is possible to setup a single scheme,
with a single master dir whose path is set to "/", it is inadvisable
to do so.

=head3 Specifying RAID Details

Although I have been describing this system as "RAID-like",
mathematically is it actually quite different. For a full explanation
of how files are split into shares, please consult the manual for
Crypt::IDA::ShareFile and Crypt::IDA. The "RAID" details comprise two
basic parts: a list of parameters governing the IDA transform, and a
list of distinct directories where share files are to be stored. A
couple more parameters are also needed for housekeeping, as
shown below:

  $raid->add_scheme
    (
      ...
      raid =>
        {
	  # IDA parameters
          nshares => 4,  # number of shares to create
          quorum  => 3,  # number of shares needed to combine
          width => 1,    # word size in bytes (1,2 or 4; 1=quickest)
	  # Storage "silos"; shares are spread across these
          share_stores => [
		     { drive => 'Jupiter' },
		     { fixed => '/var/media-raid/' },
		     { drive => 'Io' },
		     { drive => 'Ganymede' }
		    ],
	  # Housekeeping variables
          share_root => '/shares',    # appended to share_stores dirs
          working_dir => "$ENV{HOME}/.media-raid",
        },
      ...  # other parameters to add_scheme
    );

Most of these values should be fairly self-explanatory, but note:

=over

=item * the number of share_stores should match nshares;

=item * you can mix "drive" and "fixed" storage silos;

=item * share_root is appended to the base drive mount point/fixed
mount point directory within the backup directories;

=item * working_dir is needed to store various work files and it
should be distinct across all schemes.

=back

=cut

sub add_scheme {
  my $self = shift;

  # list of valid keys, including default values
  my %scheme_keys =
    (
     name        => undef,
     description => undef,
     master_dirs => { },
     raid        => { },
     scan_others => 1
    );

  my %raid_keys =
    (
     nshares      => undef,
     quorum       => undef,
     width        => 1,
     share_stores => [ ],
     share_root   => undef,
     working_dir  => undef,
   );

  # check for even number of args
  if ((0 + @_) & 1) {
    carp "Odd number of args passed to new; expected key => value args\n";
    return 0;			# failure
  }

  # basic validity checks on args
  my $ok = 1;
  my %args = (@_);
  while (my ($key,$value) = each %args) {

    if ($key eq "name" or $key eq "description" or $key eq "scan_others") {
      $scheme_keys{$key} = $value;

    } elsif ($key eq "master_dirs") {
      unless (ref($value) eq "ARRAY") {
	carp "master_dirs didn't point to an array ([...])\n";
	$ok = 0;
	next;
      }

      


    } elsif ($key eq "raid") {


    } else {

      carp "Unknown option passed to add_scheme: $key\n";
      $ok = 0;
    }

  }

}

# TODO: In future, it would be nice to have a generic object
# Media::Raid::Path encapsulating data such as { drive => foo, path =>
# foo}, and to allow this object to be passed into the add_scheme
# method. This would allow users to extend the basic class to
# implement other types of mountable shares. The code for this module
# would then interrogate the object to call the specific methods for,
# eg, checking whether the medium is mounted, mounting and unmounting
# it, and perhaps for things such as finding the amount of space used
# or available free space

=head1 SUBROUTINES/METHODS

=head2 function1

=cut


sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Declan Malone, C<< <idablack at sourceforge.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-media-raid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Media-RAID>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Media::RAID


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Media-RAID>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Media-RAID>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Media-RAID>

=item * Search CPAN

L<http://search.cpan.org/dist/Media-RAID/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Declan Malone.

This program is free software; you can redistribute it and/or modify
it under the terms the GNU General Public License version 2 or (at
your choice) any later version.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Media::RAID
