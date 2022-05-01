use v5.12;
use warnings;

package Kephra::Document::Stash;
use Scalar::Util qw(blessed looks_like_number weaken);
use Kephra::API qw(app_window doc_bar :cmp);

my %document;   # backref: doc attr => doc
my @doc_usage_queue;      # order of last usage
my $lowest_free_anon_NR = 1; # for untitled docs
my %used_ed_panels = (with_sci_refs =>[], without_sci_refs =>[]);
my $max_title_width = 25;


sub active_doc      { $doc_usage_queue[0] }
sub active_editor   { $doc_usage_queue[0]->{'editor'} }
sub active_panel    { $doc_usage_queue[0]->{'panel'} }
sub previous_doc    { $doc_usage_queue[1] }
sub all_docs        { @doc_usage_queue }
sub doc_count       { scalar @doc_usage_queue }
sub file_loaded     { 1 if $document{'file_path'}{shift} }
sub find_doc_by_attr{ $document{$_[0]}{$_[1]} }

sub set_active_doc {
	my $obj = shift;
	my $doc;
	if (is_document($obj)) {
		$doc = $obj;
		pop_doc($doc);
		unshift @doc_usage_queue, $doc;
	} elsif (is_panel($obj)) {
		my $panel = $obj;
		$doc = find_doc_by_attr('panel', $panel);
		return unless $doc;
		my $bar = $panel->GetParent;
		doc_panel()->set_active_bar($bar) unless $bar eq doc_bar();
		$doc->{'active_editor'} = $doc->{'editor'}{ $bar };
		set_active_doc($doc);
	}
	return $doc;
}

sub pop_doc {
	my $doc = shift;
	return unless is_document($doc);
	for (0 .. $#doc_usage_queue){ splice (@doc_usage_queue, $_, 1) if exists $doc_usage_queue[$_] and $doc_usage_queue[$_] eq $doc }
}


sub get_anon_title { 'untitled ' . $lowest_free_anon_NR++ }


sub subscribe_doc {
	my ($doc, $file_path) = @_;
	return unless is_document( $doc );

	$document{'panel'}{ $doc->{'panel'} } = $doc;
	$document{'editor'}{ $doc->{'editor'} } = $doc;

	if (defined $file_path and -r $file_path) { subscribe_file($doc, $file_path) }
	else                                      { $doc->{'title'} = get_anon_title() }
}
sub subscribe_file {
	my ($doc, $file_path) = @_;
	unsubscribe_file($doc) if defined $doc->{'file_path'};

	my @path_parts = File::Spec->splitpath( $file_path );
	$doc->{'file_dir'} = $path_parts[1];
	$doc->{'file_name'} = $path_parts[2];
	my $title = $doc->{'file_name'};
	$title = substr( $title, 0, $max_title_width - 2 ) . '..'
		if length($title) > $max_title_width and $max_title_width > 7;
	$doc->{'title'} = $title;

	$document{'file_path'}{$file_path} = $doc;
	$doc->{'file_path'} = $file_path;

}

sub unsubscribe_file {
	my $doc = shift;
	return unless is_document( $doc );
	delete $document{'file_path'}{ $doc->{'file_path'} };
}
sub unsubscribe_doc {
	my $doc = shift;
	return unless is_document( $doc );
	for (qw(panel editor file_path)) {
		delete $document{$_}{ $doc->{$_} } if defined $doc->{$_};
	}
	pop_doc( $doc );
}



sub do_with_all_doc {
	my $callback = shift;
	return unless ref $callback eq 'CODE';
	for (@doc_usage_queue) { &$callback( $_ ) };
}

################################################################################

sub refresh_doc_label {
	my $ed = shift;
	my $doc = find_doc_by('editor', $ed);
	return unless defined $doc;
	my $title = $doc->{'title'};
	$title .= ' *' unless $doc->saved();
	#for my $doc_bar (doc_panel()->all_doc_bar()){
		#$doc_bar->set_page_title($title, $doc->{'panel'});
	#}
}

sub get_doc_data {
	my @files;
	my $bar = doc_bar();
	for (0 .. @doc_usage_queue - 1){
		 push @files, find_doc_by_attr('panel', $bar->get_page_by_vis_nr($_))->{'file_path' } 
	};
	return @files;
}

1;
