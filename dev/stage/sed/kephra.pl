#!usr/bin/perl
use v5.12;
use warnings;
BEGIN { unshift @INC, '.' }
use Wx;
use Kephra::App::Window;

SingleEdit->new->MainLoop;

package SingleEdit;
use base qw(Wx::App);

sub OnInit {
	my $app   = shift;
	my $frame = Kephra::App::Window->new();
	$frame->Center();
	$frame->Show(1);
	$app->SetTopWindow($frame);
	1;
}
