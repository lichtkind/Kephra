#!usr/bin/perl
use v5.12;
use warnings;

FileBrowser->new->MainLoop;

package FileBrowser;
use Wx qw/ :everything /;
use base qw(Wx::App);
use Wx::STC;
use Encode::Guess;

sub OnInit {
	my $app   = shift;
	my $frame = Wx::Frame->new( undef, wxDEFAULT, __PACKAGE__. 'Kephra xp testbed step 1', [-1,-1], [1000,800]);

	my $ed = Wx::StyledTextCtrl->new($frame, -1);
	my $list = Wx::ListCtrl->new($frame, -1);
	my $sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	$sizer->Add($list, 1, &Wx::wxGROW );
	$sizer->Add($ed, 2, &Wx::wxGROW );
	$frame->SetSizer($sizer);

	#$list

	my ($file, $encoding);
	Wx::Event::EVT_KEY_DOWN($ed , sub {
		my ($ed, $event) = @_;
		my $code = $event->GetUnicodeKey;
		if ($code == 79 and $event->ControlDown){
			$file = Wx::FileSelector('Open File ...', '.', '', '', '(*)|*', &Wx::wxFD_OPEN, $frame);
			return unless $file and -r $file;
			open my $FH, '<', $file;
			binmode($FH);
			my $content = do { local $/; <$FH> };
			if ($content) {
				my $guess = Encode::Guess::guess_encoding( $content, qw/utf-8 iso8859-1 latin1/ );
				if ( ref($guess) and ref($guess) =~ m/^Encode::/ ) { $encoding = $guess->name }
				elsif                   ( $guess =~ m/utf8/ )      { $encoding = 'utf-8' }
				elsif                   ( $guess =~ m/or/ )        { $encoding = ( split(/\sor\s/, $guess) )[0] } 
				else { $encoding = 'utf-8' }
				$ed->SetText( Encode::decode( $encoding,  $content ) );
			}
		}
		elsif ($code == 81 and $event->ControlDown){ $frame->Close }
		elsif ($code == 83 and $event->ControlDown){
			return unless $file and -w $file;
			open my $FH, '> :raw :encoding('.$encoding.')', $file;
			print $FH $ed->GetText();
		} 
		else { $event->Skip }
	});

	$frame->Show(1);
	$app->SetTopWindow($frame);
	1;
}