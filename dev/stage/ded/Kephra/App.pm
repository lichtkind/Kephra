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
my $session_file = File::Spec->catfile(Cwd::cwd(),'session.yml');

sub OnInit {
	$app = shift;
	$win = Kephra::App::Window->new();
	Kephra::Document->new();
	for (@{YAML::Tiny->read( $session_file )}){ Kephra::Document->new($_) if $_ };

	$win->Center();
	$win->Show(1);
	$app->SetTopWindow($win);
	1;
}
sub OnExit { $app = shift; 1;  }
sub close  { $win->Close()     }


sub shut_down {
	Kephra::Document::Stash::do_with_all_doc( sub {
		my $doc = shift;
		return if $doc->is_saved();
		doc_bar()->raise_page($doc->{'panel'});
		my $answer = Kephra::App::Dialog::yes_no('Save changes before closing?');
		$doc->save() if $answer == &Wx::wxYES;
	});
	my $yaml = YAML::Tiny->new( Kephra::Document::Stash::get_doc_data() );
	$yaml->write( $session_file );
	Wx::wxTheClipboard->Flush;
	$win->Destroy();
}

1;
