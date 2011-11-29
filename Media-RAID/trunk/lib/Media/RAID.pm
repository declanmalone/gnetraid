package Media::RAID;

use warnings;
use strict;
use Carp;
use YAML::Any qw(Load LoadFile Dump);


our $VERSION = '0.01';

# forward declarations
sub validate_scheme;
sub validate_master_stores;

# List of all valid options and other keys, and whether they're
# required
our %required_options     = (local_mount => 1, clobber => 0,
			     verbosity   => 0, dryrun => 0);
our %required_keys        = (options => 1, schemes =>1, hosts => 0);
our %required_scheme_keys = (nshares => 1, quorum => 1, width => 1,
			     share_stores => 1, master_stores => 1,
			     working_dir => 1, description => 0,
			     scan_others => 0);

# encapsulate defaults so they're the same everywhere they're needed
our @default_options = (
			local_mount => "/media",
			clobber     => 1,
			verbosity   => 0,
			dryrun      => 0,
		       );

# Constructor
sub new {
  my $class = shift;
  my $self  = { options => { @default_options, @_ },
		schemes => {},
		hosts   => {},
	      };

  # do we know about all options passed in?  Allow user to set unknown
  # options beginning with '_' (to aid extensions), but delete all
  # others.
  for my $key (keys %{$self->{options}}) {
    unless (exists($required_options{$key}) or $key =~ /^_/) {
      carp "Unknown global option '$key'\n";
      delete $self->{option}->{$key};
    }
  }

  # do we have all required options?
  for my $key (%required_options) {
    next unless $required_options{$key}; # skip if not actually required
    unless (exists $self->{options}->{$key}) {
      carp "Required option '$key' not set\n";
      return undef;
    }
  }

  bless $self,$class;
}

# does basic validity checking on a single scheme
sub validate_scheme {
  my ($self,$schemekey) =(shift,shift);

  unless (defined ($schemekey) and exists $self->{schemes}->{$schemekey}) {
    carp "validate_scheme called on nonexistent scheme\n";
    return 0;
  }

  # basic validity checks on scheme keys

  my $scheme = $self->{schemes}->{$schemekey};

  unless (ref($scheme) eq "HASH") {
    carp "Scheme $schemekey is not a HASHREF ({...})\n";
    return 0;
  }

  my $ok = 1;

  # first delete all unknown keys
  for my $key (keys %{$scheme}) {
    unless (exists($required_scheme_keys {$key}) or $key =~ /^_/) {
      carp "scheme $schemekey: deleting unknown scheme option '$key'\n";
      delete $self->{option}->{$key};
    }
  }

  # do we have all required options?
  for my $key (%required_scheme_keys) {
    next unless $required_scheme_keys{$key}; # skip if not required
    unless (exists $scheme->{$key}) {
      carp "Required scheme option '$key' not set\n";
      return 0;
    }
  }

  unless (ref($scheme->{master_stores}) eq "HASH") {
    carp "scheme $schemekey: master_stores not a hash ref ({...})\n";
    return 0;
  }

  while (my ($group,$storeref) = each(%{$scheme->{master_stores}})) {
    unless (ref($storeref) =~ /^Media::RAID::Store/) {
      carp "scheme $schemekey: Directory group '$group' " .
	"not a Media::RAID::Store object\n";
      next;
    }
  }

  unless (keys %{$scheme->{master_stores}}) {
    carp "scheme $schemekey: No valid groups found in master_stores\n";
    return 0;
  }

  unless ($scheme->{nshares} >= 1) {
    carp "scheme $schemekey: nshares not a positive integer\n";
    return 0;
    next;
  }

  unless ($scheme->{quorum} >= 1) {
    carp "scheme $schemekey: raid quorum not a positive integer\n";
    return 0;
  }

  unless ($scheme->{width} == 1 or $scheme->{width} == 2 or
	  $scheme->{width} == 4) {
    carp "scheme $schemekey: raid width not 1, 2 or 4\n";
    return 0;
  }

  unless (ref($scheme->{share_stores}) eq "ARRAY") {
    carp "scheme $schemekey: raid share_stores not an array ref ([...])\n";
    return 0;
  }

  my $silo=0;		# incrementing silo number
  for my $siloref (@{$scheme->{share_stores}}) {
    unless (ref($siloref) =~ /^Media::RAID::Store/) {
      carp "scheme $schemekey: silo $silo not a Media::RAID::Store object\n";
      carp "(It's actually a " . ref($siloref) . "\n";
      return 0;
    }
    ++$silo;
  }

  unless (@{$scheme->{share_stores}}) {
    carp "scheme $schemekey: No valid share_stores found in raid\n";
    return 0;
  }

  # Some checks that can only be done after all values are in our
  # hashes
  unless ($scheme->{nshares} >= $scheme->{quorum}) {
    carp "raid nshares not >= quorum\n";
    $ok = 0;
  }
  unless ($scheme->{nshares} == (@{$scheme->{share_stores}})) {
    carp "raid nshares not equal to number of share_stores\n";
    $ok = 0;
  }

  return $ok;
}

sub new_from_yaml {

  my ($class,$type,$value) = @_;

  unless ($type eq "string" or $type eq "file") {
    carp "new_from_yaml needs 'string' or 'file' as 2nd argument\n";
    return undef;
  }
  unless (defined($value)) {
    carp "new_from_yaml needs a $type as 3rd argument\n";
    return undef;
  }

  my $self;
  $self = ($type eq "string") ? Load($value) : LoadFile($value);

  unless (ref($self) eq "$class") {
    if (ref($self) eq "HASH") {
      carp "Blessing incoming YAML data structure\n";
      bless $self,$class;
    } else {
      carp "Loaded YAML file didn't yield a hashref\n";
      return undef;
    }
  }

  # validate data (some bits copied from constructor)

  unless (ref($self->{options}) eq "HASH") {
    carp "options in loaded data not a hashref ({...})\n";
    return undef;
  }

  # put in default options if not set
  $self->{options} = { @default_options, %{$self->{options}} };

  # do we have all required options?
  for my $key (%required_options) {
    next unless $required_options{$key}; # skip if not actually required
    unless (exists $self->{options}->{$key}) {
      carp "Required option '$key' not set\n";
      return undef;
    }
  }

  # do we know about all options passed in?  Allow user to set unknown
  # options beginning with '_' (to aid extensions), but delete all
  # others.
  for my $key (keys %{$self->{options}}) {
    unless (exists($required_options{$key}) or $key =~ /^_/) {
      carp "Unknown global option '$key'\n";
      delete $self->{option}->{$key};
    }
  }

  unless (ref($self->{schemes}) eq "HASH") {
    carp "schemes in loaded data not a hashref ({...})\n";
    return undef;
  }

  foreach (keys %{$self->{schemes}}) {
    unless ($self->validate_scheme($_)) {
      carp "Deleted invalid scheme $_\n";
      delete $self->{schemes}->{$_};
    }
  }

  # TODO: Add check to make sure of no conflicts within/between
  # schemes

  return $self;

}

sub dumpconfig {
  my $self = shift;

  Dump($self);
}

sub validate_schemes;

sub add_scheme {
  my $self = shift;
  my $name;

  unless (defined($name=shift)) {
    carp "add_scheme needs scheme name as first argument\n";
    return 0;
  }

  if (exists($self->{schemes}->{$name})) {
    carp "Cannot add scheme '$name'; that name already exists\n";
    return 0;
  }

  # check for even number of args
  if ((0 + @_) & 1) {
    carp "Odd number of args passed to new; expected key => value args\n";
    return 0;			# failure
  }

  # list of valid keys, including default values
  my $scheme =
    {
     description   => undef,
     master_stores => { },
     scan_others   => 1,
     share_stores  => [ ],
     nshares       => undef,
     quorum        => undef,
     width         => 1,
     working_dir   => undef,
     @_				# bring in args
    };

  $self->{schemes}->{$name} = $scheme;
  unless ($self->validate_scheme($name)) {
    carp "deleted invalid scheme $name\n";
    delete $self->{schemes}->{$name};
    return 0;
  }

  # TODO: Also check this scheme against all other schemes to ensure
  # no conflicts.

  return 1;
}

#
# Some simple accessors to allow access to internal data
#

sub option {
  my $self = shift;
  my $option_name = shift;

  unless (defined($option_name)) {
    carp "option method requires an option name\n";
    return undef;
  }

  if (exists($self->{options}->{$option_name})) {
    return $self->{options}->{$option_name};
  }

  return undef;
}

sub scheme_names {
  my $self = shift;

  return keys %{$self->{schemes}};
}

sub master_names {
  my $self   = shift;
  my $scheme = shift;

  unless (exists($self->{schemes}->{$scheme})) {
    $scheme = "(undef)" unless defined $scheme;
    carp "Unknown scheme $scheme\n";
    return undef;
  }

  return keys %{$self->{schemes}->{$scheme}->{master_stores}};
}

sub master_store {
  my ($self,$scheme,$master) = @_;

  unless (@_ == 3) {
    carp "master_store requires (scheme,master name) as parameters\n";
    return undef;
  }

  unless (exists($self->{schemes}->{$scheme})) {
    $scheme = "(undef)" unless defined $scheme;
    carp "Unknown scheme $scheme\n";
    return undef;
  }

  unless (exists($self->{schemes}->{$scheme}->{master_stores}->{$master})) {
    carp "master store $master is not in scheme $scheme\n";
    return undef;
  }

  return $self->{schemes}->{$scheme}->{master_stores}->{$master};

}



# Just POD hereafter

=head1 NAME

Media::RAID - Implement a RAID-like backup system using Crypt::IDA::*

=head1 VERSION

Version 0.01

=cut


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
   use Media::RAID::Store qw(new_drive_store new_fixed_store);

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

=head2 Defining RAID schemes

=head3 Overview

Since this is the most complicated part of using the module, it is
broken up into several sections. The basic outline is:

  $rc = $raid->add_scheme ( "unique name for this scheme",
      description => "Human-readable description",
      master_stores => { <details of dirs being managed> },
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

The master_stores parameter is a (reference to a) hash of hashes, each
of which specifies the path of a master directory that is to be backed
up. There are two ways in which to specify master directories. The
first way is to specify a path on a removable hard disk:

  # directory resides on a (named) removable drive
  $raid->add_scheme
    (
      ...
      master_stores => {
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
      master_stores => {
        "movies" =>
          {
            fixed => "/home/ida",     # absolute path
            path  => "/Video/movies"  # relative to above path
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

=head3 RAID Parameters

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
      # IDA parameters
      nshares => 4,  # number of shares to create
      quorum  => 3,  # number of shares needed to combine
      width => 1,    # word size in bytes (1,2 or 4; 1=quickest)
      # Storage "silos"; shares are spread across these
      share_stores => [
	 new_drive_store ('Jupiter',        '/shares','/media'),
	 new_fixed_store ('/var/media-raid','/shares'         ),
	 new_drive_store ('Io',             '/shares','/media'),
	 new_drive_store ('Ganymede',       '/shares','/media'),
	],
      # Housekeeping variables
      working_dir => "$ENV{HOME}/.media-raid",
      ...
    );

Most of these values should be fairly self-explanatory, but note:

=over

=item * the number of share_stores should match nshares;

=item * you can mix "drive" and "fixed" storage silos;

=item * all drives include a local mount point, but fixed stores don't
use/accept this parameter.

=item * all shares will be stored in the '/shares' directory relateive
to the drive/fixed mount point directory within the backup
directories;

=item * working_dir is needed to store various work files and it
should be distinct across all schemes.

=back

=head1 SUBROUTINES/METHODS

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
