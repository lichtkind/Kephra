use v5.12;
use warnings;
use Wx;

package Kephra::Document;
use Kephra::API qw(app_window doc_bar document editor);
use Kephra::Document::Stash;
use Kephra::Document::Session;
use Kephra::Document::SyntaxMode;
use Kephra::IO::LocalFile; # use Kephra::IO;


sub has_file { shift->{'file_path'} }
sub has_text { shift->{'editor'}->GetText() }
sub is_saved { not shift->{'editor'}->GetModify }
sub get_attribute_hash {
	my $self = shift;
	my %attr;
	$attr{$_} = $self->{$_} for qw/file_path syntaxmode encoding/;
	$attr{'change_pos'} = $self->{'editor'}->{'change_pos'};
	$attr{'cursor_pos'} = $self->{'editor'}->GetCurrentPos;
	return \%attr;
}

sub new {
	my $class = shift // '';
	my $file_path = shift // '';
	$file_path = $class if $class ne __PACKAGE__;
	my $attr;
	if (ref $file_path eq 'HASH') {$attr = $file_path}
	else          { $attr->{'file_path'} = $file_path}
	my $self = document();
	if (not ref $self or $self->has_file() or $self->has_text()) {
		$self = bless { };
		my $doc_bar = doc_bar();
		my $panel = $self->{'panel'} = Kephra::App::Panel->new( $doc_bar );
		my $ed = $self->{'editor'}  = Kephra::App::Editor->new( $panel );
		#$doc->{'panel'}{$doc_bar} = $panel;
		#$doc->{'editor'}{$doc_bar} = $ed;
		$panel->append_expanded( $ed );
		Kephra::Document::Stash::subscribe_doc($self, $attr->{'file_path'});
		Kephra::Document::Stash::set_active_doc($self);    # now its in active docs stack
		$doc_bar->add_page( $panel, $self->{'title'}, -1, 0);

		#Kephra::Document::SyntaxMode::guess_mode_file_ending($ed);
		if ($attr->{'syntaxmode'}) {$self->{'syntaxmode'} = $attr->{'syntaxmode'}}
		else {
			$self->{'syntaxmode'} = 'no';
			 for (qw/pod pl pm plx pl6/)
				{$self->{'syntaxmode'} = 'perl' if $self->{'file_ending'} eq $_}
		}
		Kephra::Document::SyntaxMode::set($ed, $self->{'syntaxmode'});
		app_window()->SetStatusText( $self->{'syntaxmode'}, 1);

		$self->{'encoding'} = $attr->{'encoding'} || '';
		my ($text) = ('');
		if ($attr->{'file_path'} and -r $attr->{'file_path'}){
			($text, $self->{'encoding'}) = Kephra::IO::LocalFile::read( $attr->{'file_path'}, $self->{'encoding'});
			$self->{'editor'}->reset_text( $text);
		}
		$self->{'encoding'} = 'utf-8' unless $self->{'encoding'};

		$self->{'editor'}->SetSelection($attr->{'cursor_pos'}, $attr->{'cursor_pos'}) if $attr->{'cursor_pos'};

		$doc_bar->raise_page( $panel );
	} 
	else { $self->open($file_path) }
}


sub open {
	my $self = shift;
	my $file_path = shift;
	my $dir = document()->{'file_dir'};
	$file_path = Kephra::App::Dialog::get_file_open(-1, $dir)
		unless defined $file_path and -r $file_path;
	return unless $file_path and -r $file_path;
	my $already_opened_doc = Kephra::Document::Stash::find_doc_by_attr('file_path', $file_path);
	return Kephra::Document::Stash::set_active_doc($already_opened_doc) if $already_opened_doc;
	return Kephra::Document::new($file_path) if $self->has_file() or $self->has_text();

	my ($content, $encoding) = Kephra::IO::LocalFile::read( $file_path );
	$self->{'editor'}->reset_text( $content );
	$self->{'encoding'} = $encoding; 
	$self->{'encoding'} = 'utf-8' unless defined $encoding; # highlighter drives mad on //

	Kephra::Document::Stash::subscribe_file($self, $file_path);
	doc_bar()->set_page_title($self->{'title'}, $self->{'panel'});
	app_window()->default_title_update();
	app_window()->SetStatusText( $self->{'encoding'}, 2);
	Wx::Window::SetFocus( $self->{'editor'} );

	return $file_path;
}

sub reopen {
	my $self = shift;
	return unless $self->has_file();
	my ($text) = Kephra::IO::LocalFile::read( $self->{'file_path'} );
	$self->{'editor'}->SetText($text);
	$self->{'editor'}->SetSavePoint;
}


sub save {
	my $self = shift;
	my $ed = $self->{'editor'};
	return if $self->is_saved();
	return $self->save_as() unless $self->has_file();
	Kephra::IO::LocalFile::write( $self->{'file_path'}, $self->{'encoding'}, $ed->GetText() );
	$ed->SetSavePoint;
}

sub save_as {
	my $self = shift;
	my $file_path = shift;
	$file_path = Kephra::App::Dialog::get_file_save(-1, document()->{'file_dir'}) 
		unless defined $file_path and -w $file_path;
	return unless $file_path;
	my $ed = $self->{'editor'};
	Kephra::Document::Stash::subscribe_file($self, $file_path);
	Kephra::IO::LocalFile::write( $file_path, $self->{'encoding'}, $ed->GetText() );
	$ed->SetSavePoint;
}


sub close {
	my $self = shift;
	if (not $self->is_saved()){
		my $answer = Kephra::App::Dialog::yes_no_cancel('Save changes before closing?');
		return &Wx::wxCANCEL if $answer == &Wx::wxCANCEL;
		save($self) if $answer == &Wx::wxYES;
	}
	if (Kephra::Document::Stash::doc_count() == 1) { # just reset the last open doc
		return unless $self->has_text();
		$self->{'title'} = Kephra::Document::Stash::get_anon_title();
		$self->{'editor'}->reset_text( '' );
		if ($self->has_file() ){
			Kephra::Document::Stash::unsubscribe_file($self->{'file_path'});
			delete $self->{'file_path'};
		}
		$self->{'encoding'} = 'utf-8';
		app_window()->SetStatusText( $self->{'encoding'}, 2);
	} 
	else {                                           # real close doc
		doc_bar()->remove_page( $self->{'panel'} );
		$self->{'editor'}->Destroy();
		$self->{'panel'}->Destroy();
		Kephra::Document::Stash::unsubscribe_doc( $self );
	}
	Wx::Window::SetFocus( editor() );
	app_window()->default_title_update();
}

################################################################################

sub rot_syntaxmode {
	my $self = shift;
	$self->{'syntaxmode'} = $self->{'syntaxmode'} eq 'perl' ? 'no' : 'perl';
	Kephra::Document::SyntaxMode::set($self->{'editor'}, $self->{'syntaxmode'});
	app_window()->SetStatusText( $self->{'syntaxmode'}, 1);
}

1;