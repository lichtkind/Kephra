use v5.12;
use warnings;
use Wx;
use Exporter;



package Kephra::Document;
our @ISA = qw(Exporter);
our @EXPORT = qw/default/;

use Kephra::API qw(app_window doc_bar document editor);
use Kephra::IO::LocalFile; # use later Kephra::IO;?
use Kephra::Document::Edit;
use Kephra::Document::File;
use Kephra::Document::SyntaxMode;
use Kephra::Document::Session;
use Kephra::Document::Stash;


sub has_file { shift->{'file_path'} }
sub has_text { shift->{'editor'}->GetText() }
sub is_saved { not shift->{'editor'}->GetModify }
sub get_attribute_hash {
	my $self = shift;
	my %attr;
	$attr{$_} = $self->{$_} for qw/syntaxmode encoding file_path/;
	$attr{'change_pos'} = $self->{'editor'}->{'change_pos'};
	$attr{'cursor_pos'} = $self->get_cursor_pos();
	return \%attr;
}

our %default = (syntaxmode => 'no', encoding => 'utf-8');


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

		for (keys %$attr)   { $self->{$_} = $attr->{$_}                       }
		#for (keys %default) { $self->{$_} = $default->{$_} unless $self->{$_} }
		my $doc_bar = doc_bar();
		my $panel = $self->{'panel'} = Kephra::App::Panel->new( $doc_bar );
		my $ed = $self->{'editor'}  = Kephra::App::Editor->new( $panel );
		#$doc->{'panel'}{$doc_bar} = $panel;
		#$doc->{'editor'}{$doc_bar} = $ed;
		$panel->append_expanded( $ed );
		$self->{'file_path'} ||= '';                                            # hack to get untitled label in case no file
		$self->set_file( $self->{'file_path'});

		Kephra::Document::Stash::subscribe_doc($self, 'active');
		$doc_bar->add_page( $panel, $self->{'title'}, -1, 0);                   # $page, $title, $position, $raise_focus

		my $text = ($self->{'file_path'} and -r $self->{'file_path'})
			? Kephra::IO::LocalFile::read_raw( $self->{'file_path'}) : '';
		$self->{'encoding'} = $self->{'encoding'}
						   || Kephra::IO::LocalFile::guess_encoding($text, $default{'encoding'});
		$text = Encode::decode( $self->{'encoding'},  $text ) if $text;
		$self->{'editor'}->reset_text( $text) if $text;

		$self->{'syntaxmode'}
			? $self->set_mode                 ( $self->{'syntaxmode'} )
			: $self->set_mode_from_file_ending( $default{'syntaxmode'} );

		$self->move_cursor_to_pos($attr->{'cursor_pos'}) if $attr->{'cursor_pos'};
		$doc_bar->raise_page( $panel );
		Wx::Window::SetFocus( $self->{'editor'} );
	} 
	else { $self->open($file_path) }
}


sub _restore_from_config {
	my ($self, $attr) = @_;
	return unless ref $attr eq 'HASH';
	$self->{$_} = $attr->{$_} for keys %$attr;
}

sub _load_new_file {
	my $self = shift;
	my $file_path = shift // '';
	return unless $file_path and -r $file_path;
	$self->set_file( $file_path );

	my $text = ($file_path and -r $file_path)? Kephra::IO::LocalFile::read_raw( $file_path) : '';
		$self->{'encoding'} = $self->{'encoding'}
						   || Kephra::IO::LocalFile::guess_encoding($text, $default{'encoding'});
	$text = Encode::decode( $self->{'encoding'},  $text ) if $text;
	$self->{'editor'}->reset_text( $text) if $text;

	$self->set_mode_from_file_ending();
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

	$self->_load_new_file( $file_path );
	doc_bar()->set_page_title($self->{'title'}, $self->{'panel'});
	app_window()->default_title_update();
	app_window()->SetStatusText( $self->{'encoding'}, 2);
	Wx::Window::SetFocus( $self->{'editor'} );

	return $file_path;
}

sub reopen {
	my $self = shift;
	return unless $self->has_file();
	my ($text) = Kephra::IO::LocalFile::read( $self->{'file_path'}, $self->{'encoding'} );
	my $ed = $self->{'editor'};
	$ed->SetText($text);
	$ed->SetSavePoint;
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
	$self->set_file( $file_path );
	Kephra::IO::LocalFile::write( $file_path, $self->{'encoding'}, $ed->GetText() );
	$ed->SetSavePoint;
}


sub close {
	my $self = shift;
	if (not $self->is_saved()){
		my $answer = Kephra::App::Dialog::yes_no_cancel('Save changes before closing?');
		return &Wx::wxCANCEL if $answer == &Wx::wxCANCEL;
		save_file($self) if $answer == &Wx::wxYES;
	}
	if (Kephra::Document::Stash::doc_count() == 1) { # just reset the last open doc
		return unless $self->has_text();
		$self->{'editor'}->reset_text( '' );
		$self->set_mode( 'no' );
		$self->set_file( '' ) if $self->has_file();
		$self->{'encoding'} = $default{'encoding'};
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


1;
