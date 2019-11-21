use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use FindBin qw($Bin);
use lib "$Bin/../lib";

my $t = Test::Mojo->new('IDA::Daemon');
$t->get_ok('/')->status_is(200)->content_like(qr/Mojolicious/i);

done_testing();
