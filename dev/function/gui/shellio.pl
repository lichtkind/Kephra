#!usr/bin/perl
use v5.12;
use warnings;

ShellIO->new->MainLoop;

package ShellIO;
use File::Find;
use File::Spec;
use FindBin qw($RealBin);
use Wx;
use Wx::STC;
use Wx::Perl::ProcessStream;
use base qw(Wx::App);

sub OnInit {
	my $app   = shift;
	my $frame = Wx::Frame->new( undef, -1, __PACKAGE__ , [-1,-1], [1000,800]);
	my $i = Wx::StyledTextCtrl->new($frame, -1, [-1,-1],[-1,20]);
	my $o = Wx::StyledTextCtrl->new($frame, -1, );
	$i->SetScrollWidth(100);
	$o->SetScrollWidth(100);
	Wx::Window::SetFocus( $i );
	
	Wx::Event::EVT_KEY_DOWN($i , sub {
		my ($ed, $event) = @_;
		return $event->Skip unless $event->GetUnicodeKey() == 13;
		$o->InsertText(0, $i->GetText() . "\n");
		$i->ClearAll();
	});
	
	my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	$sizer->Add($i, 0, &Wx::wxGROW);
	$sizer->Add($o, 1, &Wx::wxGROW);
	$frame->SetSizer($sizer);
	$frame->Show(1);
	$app->SetTopWindow($frame);
	1;
}