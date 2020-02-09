use v5.12;
use warnings;
use Exporter;

package Kephra::Document::File;
our @ISA = qw(Exporter);
our @EXPORT = qw/set_file/;
use Kephra::API qw(app_window doc_bar);

my $max_title_width = 25;
my $anon_title = 'untitled ';

sub set_file {
	my ($self, $file_path) = @_;
	return say ('need at least empty value as new file path') unless defined $file_path;
	# no path is deleting

	Kephra::Document::Stash::unsubscribe_doc_attr('file_path', $self->{'file_path'})
		if defined $self->{'file'}{'path'};
	Kephra::Document::Stash::unsubscribe_anon_doc($self);
	delete $self->{'file_anon_nr'};

	if ($file_path){
		$self->{'file_path'} = $file_path;
		Kephra::Document::Stash::subscribe_doc_attr('file_path', $file_path);
		my @path_parts = File::Spec->splitpath( $file_path );
		$self->{'file_dir'} = $path_parts[1];
		$self->{'file_name'} = $path_parts[2];
		$self->{'file_ending'} = (split('\.', $self->{'file_name'}))[-1];

		my $title = $self->{'file_name'};
		$title = substr( $title, 0, $max_title_width - 2 ) . '..'
			if length($title) > $max_title_width and $max_title_width > 7;
		$self->{'title'} = $title;
	}
	else {
		$self->{$_} = '' for qw/file_path file_dir file_name file_ending file_anon_nr/;
		Kephra::Document::Stash::subscribe_anon_doc($self);
		$self->{'title'} = 'untitled ' . $self->{'file_anon_nr'};
	}
}

1;