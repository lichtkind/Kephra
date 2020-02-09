use v5.12;
use warnings;
use Cwd;
use File::Spec;
use Wx;

package Kephra::App;
use base qw(Wx::App);

use Kephra::API qw/doc_bar/;
use Kephra::App::Window;
use Kephra::Document;

our ($app, $win);

sub OnInit {
	$app = shift;
	$win = Kephra::App::Window->new();
	Kephra::Document->new();
	$win->Center();
	$win->Show(1);
	$app->SetTopWindow($win);
	1;
}

sub OnExit { $app = shift; 1;  }
sub close  { $win->Close()     }


sub shut_down {
	Wx::wxTheClipboard->Flush;
	$win->Destroy();
}

1;
