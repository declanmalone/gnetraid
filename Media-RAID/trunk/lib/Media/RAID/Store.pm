package Media::RAID::Store;

use Carp;
use Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(new_drive_store new_fixed_store);

# Generic constructor method (use Classname::new)
sub new {
  my $class = shift;
  my $self  = { path => undef, mount_root => "", @_ };

  unless (defined($self->{path})) {
    carp "Media::RAID::Store::new requires a path key\n";
    return undef;
  }
  unless (substr($self->{path},0,1) eq "/") {
    carp "path must begin with '/'\n";
    return undef;
  }
  if (exists($self->{drive})) {
    $self->{type}       = "drive";
    $self->{id}         = $self->{drive};
    delete $self->{drive};
    return bless $self, 'Media::RAID::Store';
  }
  if (exists($self->{fixed})) {
    $self->{type} = "fixed";
    $self->{id}   = $self->{dixed};
    delete $self->{fixed};
    return bless $self, 'Media::RAID::Store';
  }
  carp "Media::RAID::Store::new requires a drive or fixed key\n";
  return undef;
}

# Exported shortcut functions (don't call via $ref->* or Classname::*)
sub new_drive_store {
  unless (@_ >= 2) {
    carp "new_drive_store requires (drive,path[,mount_root]) args\n";
    return undef;
  }
  my $self = { id   => shift, path => shift, type => "drive",
	       mount_root => (shift or "")};
  unless (substr($self->{path},0,1) eq "/") {
    carp "path must begin with '/'\n";
    return undef;
  }
  bless($self,'Media::RAID::Store');
}

sub new_fixed_store {
  unless (@_ == 2) {
    carp "new_fixed_store requires (fixed,path) args\n";
    return undef;
  }
  my $self = { id=>shift, path=>shift, type=>"fixed", mount_root=>"" };
  unless (substr($self->{path},0,1) eq "/") {
    carp "path must begin with '/'\n";
    return undef;
  }
  bless($self,'Media::RAID::Store');
}


# simple accessors
sub type      { my $self = shift; $shift->{type}; }
sub mountable { my $self = shift; $self->{type} eq "drive" ? 1 : 0 }

# get/update mount_root
sub mount_root {
  my $self = shift;
  my $new_mount = shift;
  if (defined($new_mount)) {
    unless($self->mountable) {
      carp "Fixed store is not mountable (can't change mount_root)\n";
      return "";
    }
    $self->{mount_root} = $new_mount;
  }
  $self->{mount_root};
}

# check_mount returns true if we have a valid mount_root and can see
# at least the base dir (eg, '/fixed/path' or '/media/Disk'). This
# will generally be called once after setting up, or as a check after
# mounting a directory.
sub check_mount {
  my $self = shift;

  if ($self->mountable) {
    # note that the following assumes an automount scheme where the
    # directory for a labelled disk is created automatically when the
    # disk is mounted, and the dir is removed when it's unmounted. It
    # would probably be better to use Filesys::Df to check that it's
    # actually mounted.
    return (-d "$self->{mount_root}/$self->{id}"          ? 1 : 0);
  } else {
    return (-d $self->{id} and $self->{mount_root} eq "") ? 1 : 0;
  }
}

# as_path sticks together all the components to create a path name.
# If this store is mountable, but mount_root isn't set, we return
# undef.
sub as_path {
  my $self = shift;
  my $path = "";
  if ($self->mountable) {
    $path = "$self->{mount_root}/";
    return undef if ($path eq "/");
  }
  return "$path" . "$self->{id}" . "$self->{path}";
}

1;
