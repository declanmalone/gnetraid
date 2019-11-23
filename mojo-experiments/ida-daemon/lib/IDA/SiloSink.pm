package IDA::SiloSink;
use Mojo::Base 'Mojo::EventEmitter';

use warnings;

use Mojo::File 'path';

# SiloSink is a class for writing to files in a restricted set of
# directories:
#
# "Silo" because it only writes to selected IDA share silo dirs
# "Sink" because it comes at the end of an EventEmitter chain

# Class variable and method (call during application config)
our @allowed_dirs = ();
sub config {
    my $class = shift;
    for (@_) {
	my $dirname = path($_)->to_abs->to_string;
	die "Directory $dirname doesn't exist\n" unless -d $dirname;
	push @allowed_dirs, $dirname;
    }
}

# In contrast to most constructors, this returns an error message
# instead of undef if there is a problem. I do this because it's
# easier to report errors over a websocket or in a chain of on(error)
# handlers.
#
# So make sure to check the return value before trying to do method
# calls on it. Otherwise the error message in the variable might turn
# out to be a valid class name, which could allow a remote execution
# bug.
#

# Arguments:
#
# $source    another EventEmitter that emits events
# $read      the name of the "read"-like event that signals us that
#            more data is available to read/process
# $close     the name of the "close"-like event that signals us that
#            no more data will be arriving (ie, eof)
#
# Although we don't do any special processing here on the on-close
# event, other classes that follow the same design pattern (eg, a sink
# that calculates a hash of a stream) may need to. For consistency's
# sake, I'll also include the on-close message name here, too.
#
# $filename  A file to sink the data into, which must be under one of
#            the allowed_dirs that are set up at config time.

sub new {
    my $class = shift;
    my ($source, $read, $close, $filename) = @_;
    my ($path) = path($filename)->to_abs; # a Mojo::File object
    my $self = bless {
	source   => $source,
	read     => $read,
	close    => $close,
	filename => $filename
    }, $class;

    warn "Testing path $$path\n";
    
    # Mojo::File's to_abs doesn't handle '..' properly/securely.
    # Maybe I should use Cwd::abs_path instead...

    # The below code will fail if symlinks are traversed, so don't use
    # any dir symlinks within any allowed dir!
    my @components = @{$path->to_array}; # list context needed!
    my @rebuild;
    for my $bit (@components) {
	warn "Testing bit $bit\n";
	if ($bit ne "..") {
	    push @rebuild, $bit if $bit ne ".";
	} else {
	    if (@rebuild) {
		pop @rebuild;
	    } else {
		# Could also probably safely ignore this
		return  ".. wandered out of file system";
	    }
	}
    }
    $path = path(@rebuild);
    my $dirname = $path->dirname;
    my $basename = $path->basename;

    # Check if dir is under one of the allowed roots
    my $allowed = 0;
    foreach my $silo (@allowed_dirs) {
	my $len = length $silo;
	next if ($silo ne substr $path->to_string, 0, $len);
	warn "$$path is under allowed dir $silo\n";
	$allowed = 1;
	last;
    }
    return "$$path not under an allowed directory" unless $allowed;
    return "$$path is a directory" if (-d $path);

    warn "We seem to be able to write to $basename in $dirname\n";

    # create dir if it doesn't exist
    $dirname->make_path unless -d $dirname->to_string;

    my $fh;
    unless(open $fh, ">", "$$path") {
	return "Failed to open file for writing: $!";
    }
    $self->{fh} = $fh;

    # using can rather than isa might be better style?
    return "\$source isn't a Mojo::EventEmitter"
	unless ($source->isa("Mojo::EventEmitter"));

    # The calling program should generally set up the full processing
    # chain before starting any Source objects (generally a
    # Mojo::IOLoop::Stream object) to feed the chain. Included in that
    # is stashing the constructed objects and subscribing to their
    # error events. Thus by the time any callbacks below get
    # triggered, we should be able to raise error events that can be
    # handled by the caller.

    $self;
}

1;
