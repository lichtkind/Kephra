#!usr/bin/perl
use v5.18;
use warnings;

App->new->MainLoop;

package App;
use File::Find;
use File::Spec;
use FindBin qw($RealBin);
use Wx;

use base qw(Wx::App);
sub OnInit {
	my $app   = shift;
	my $frame = Wx::Frame->new( undef, -1, __PACKAGE__ , [-1,-1], [1000,800]);
	my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    # my $lbl = Wx::StaticText($frame, -1, 'Solved:');
    # $sizer->Add( $lbl, 0, &Wx::wxLEFT|&Wx::wxBOTTOM|&Wx::wxEXPAND, 5 );
    my $text = Wx::TextCtrl->new( $frame, -1, "",[-1,-1] ,[-1,-1], &Wx::wxTE_READONLY|&Wx::wxTE_LEFT|&Wx::wxNO_FULL_REPAINT_ON_RESIZE );
    
    

	$frame->SetSizer($sizer);
	$frame->Show(1);
	$app->SetTopWindow($frame);
	1;
}
