use v5.12;
use warnings;

DoubleView->new->MainLoop;

package DoubleView;
use base qw(Wx::App);
use Wx;
use Wx::STC;

sub OnInit {
	my $app   = shift;
	my $win = Wx::Frame->new( undef, -1, 'Kephra DVD - STC Double View Demo - use Ctrl + Tab',[-1, -1],[600, 600]);
	my $ed1 = Wx::StyledTextCtrl->new($win, -1, );
	my $ed2 = Wx::StyledTextCtrl->new($win, -1, );
	$ed2->SetDocPointer( $ed1->GetDocPointer() ); 
	$ed1->AddRefDocument( $ed1->GetDocPointer() );
	Wx::Window::SetFocus( $ed1 );
	$ed2->AppendText("ctrl+space: print doc pointer\n".
                     "ctrl+tab:   switch edit panel\n".
                     "ctrl+c:     toggle: connect/disconnect panel\n".
                     "ctrl+'+':   zoom in\n".
                     "ctrl+'-':   zoom out\n"
	);

	my $sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL);
	$sizer->Add($ed1, 1, &Wx::wxGROW);
	$sizer->Add($ed2, 1, &Wx::wxGROW);
	$win->SetSizer($sizer);
	$ed1->SetZoom(3);
	$ed2->SetZoom(-7);


	Wx::Event::EVT_KEY_DOWN ($ed1, sub {
		my ($self, $event) = @_;
		my $code = $event->GetUnicodeKey;
		my $ctrl = $event->ControlDown ? 1 : 0;
		if($ctrl and $code == &Wx::WXK_TAB) { Wx::Window::SetFocus($ed2) }
		elsif($ctrl and $code == &Wx::WXK_SPACE) {
			$ed1->AppendText("Doc ref: ".$ed1->GetDocPointer(). ' '. $ed2->GetDocPointer()."\n") }
		elsif($ctrl and $code == ord('C')) {
			if ($ed1->GetDocPointer() eq $ed2->GetDocPointer()){
				$ed2->SetDocPointer( $ed2->CreateDocument() );
				$ed1->ReleaseDocument( $ed1->GetDocPointer());
				#$ed2->Show(0); #$sizer->Remove($ed2); $sizer->Layout(); #$ed2->Destroy; 
			} else {
				$ed2->SetDocPointer( $ed1->GetDocPointer() ); 
				$ed1->AddRefDocument( $ed1->GetDocPointer() );
				#$ed2->Show(1); #$sizer->Add($ed2,1, &Wx::wxGROW); $sizer->Layout(); 
			}
		}
		else {$event->Skip}
	});
	Wx::Event::EVT_KEY_DOWN ($ed2, sub {
		my ($self, $event) = @_;
		my $code = $event->GetUnicodeKey;
		my $ctrl = $event->ControlDown ? 1 : 0;
		if($ctrl and $code == &Wx::WXK_TAB) { Wx::Window::SetFocus($ed1) }
	});


	$win->Center();
	$win->Show(1);
	$app->SetTopWindow($win);
	1;
}
