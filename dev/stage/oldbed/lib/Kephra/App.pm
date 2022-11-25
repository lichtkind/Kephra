use v5.12;
use warnings;
use Cwd;
use File::Spec;
use YAML::Tiny;
use Wx;

package Kephra::App;
use base qw(Wx::App);

use Kephra::API qw/doc_bar/;
use Kephra::App::Window;
use Kephra::Document;

our ($app, $win);

sub OnInit { shift->boot(); 1; }
sub OnExit { $app = shift;  1; }
sub close  { $win->Close()     }


sub boot{
	$app = shift;
	$win = Kephra::App::Window->new();
	Kephra::Document::Session::restore_auto();
	$win->Center();
	$win->Show(1);
	$app->SetTopWindow($win);
}


sub shut_down {
	Kephra::Document::Stash::do_with_all_doc( sub {
		my $doc = shift;
		return if $doc->is_saved();
		doc_bar()->raise_page($doc->{'panel'});
		my $answer = Kephra::App::Dialog::yes_no('Save changes before closing?');
		$doc->save() if $answer == &Wx::wxYES;
	});
	Kephra::Document::Session::save_auto();
	Wx::wxTheClipboard->Flush;
	$win->Destroy();
}

1;
