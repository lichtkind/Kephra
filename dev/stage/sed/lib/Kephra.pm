#!usr/bin/perl
use v5.12;
use warnings;
use Wx;
use Kephra::App::Window;

package Kephra;
use base qw(Wx::App);

sub OnInit {
    my $app  = shift;
    my $window = $app->{'win'} = Kephra::App::Window->new();
    $window->Center();
    $window->Show(1);
    $app->SetTopWindow( $window );
    1;
}

sub close  { $_[0]->{'frame'}->Close() }

sub OnExit {
    my $app = shift;
    Wx::wxTheClipboard->Flush;
    # $app->{'win'}->Destroy;
    1;
}

1;
