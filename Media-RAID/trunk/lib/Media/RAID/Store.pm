package Media::RAID::Store;

use Carp;
use Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(new_drive_store new_fixed_store);

# Generic constructor method (use Classname::new)
sub new {
  my $class = shift;
  my $self  = { path => undef, @_ };

  unless (defined($self->{path})) {
    carp "Media::RAID::Store objects require path key\n";
    return undef;
  }
  if (exists($self->{drive})) {
    $self->{type}       = "drive";
    $self->{id}         = $self->{drive};
    $self->{mount_root} = "";
    delete $self->{drive};
    return bless $self, 'Media::RAID::Store';
  }
  if (exists($self->{fixed})) {
    $self->{type} = "fixed";
    $self->{id}   = $self->{dixed};
    delete $self->{fixed};
    $self->{mount_root} = "";
    return bless $self, 'Media::RAID::Store';
  }
  carp "Media::RAID::Store objects require a drive or fixed key\n";
  return undef;
}

# Shortcut functions (don't call Classname::new_*_store)
sub new_drive_store {
  unless (@_ == 2) {
    carp "new_drive_store requires (drive,path) args\n";
    return undef;
  }
  my $self  = { id   => shift, path => shift, type => "drive" };
  bless($self,'Media::RAID::Store');
}

sub new_fixed_store {
  unless (@_ == 2) {
    carp "new_fixed_store requires (fixed,path) args\n";
    return undef;
  }
  my $self  = { id   => shift, path => shift, type => "fixed" };
  bless($self,'Media::RAID::Store');
}


# simple accessors
sub type      { my $self = shift; $shift->{type}; }
sub mountable { my $self = shift; $self->{type} eq "drive" ? 1 : 0 }

# get/update mount_root
sub mount_root {
  my $self = shift;
  unless ($self->mountable) {
    carp "Fixed store is not mountable\n";
    return undef;
  }
  my $new_mount = shift;
  $self->{mount_root} = $new_mount if defined $new_mount;
  $self->{mount_root};
}

# as_path doesn't take mount paths into account, so user must prepend it
sub as_path { "$self->{id}/$self->{path}"; }

1;
