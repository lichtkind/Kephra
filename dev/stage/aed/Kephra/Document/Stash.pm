use v5.12;
use warnings;

package Kephra::Document::Stash;
use Scalar::Util qw(blessed looks_like_number weaken);
use Kephra::API qw(app_window doc_bar :cmp);

my %doc_by_attr;             # backref: doc attr => doc
my %anon_docs;               # nr => doc
my $lowest_free_anon_NR = 1; # for untitled docs
my @doc_usage_queue;         # order of last usage
my %used_ed_panels = (with_sci_refs =>[], without_sci_refs =>[]);


sub active_doc         { $doc_usage_queue[0] }
sub active_editor      { $doc_usage_queue[0]->{'editor'} }
sub active_panel       { $doc_usage_queue[0]->{'panel'} }
sub previous_doc       { $doc_usage_queue[1] }
sub all_docs           { @doc_usage_queue }
sub doc_count          { scalar @doc_usage_queue }
sub file_loaded        { 1 if $doc_by_attr{'file_path'}{shift} }
sub find_doc_by_attr   { $doc_by_attr{ $_[0] }{ $_[1] } }
sub subscribe_doc_attr { $doc_by_attr{ $_[1] }{ $_[2] } = $_[0] if is_document( $_[0] )}
sub unsubscribe_doc_attr{delete $doc_by_attr{ $_[0] }{ $_[1] } }

sub subscribe_doc {
	my ($doc, $active) = @_;
	return unless is_document( $doc );
	subscribe_doc_attr($doc, $_, $doc->{$_}) for qw/panel editor/;

	if ($doc->{'file_path'}){
		subscribe_doc_attr($doc, 'file_path', $doc->{'file_path'});
	} else {
		subscribe_anon_doc($doc) if not $doc->{'file_anon_nr'};
	}
	$active ? set_active_doc($doc) : set_passive_doc($doc);
}

sub unsubscribe_doc {
	my $doc = shift;
	return unless is_document( $doc );
	for (qw(panel editor file_path)) {
		delete $doc_by_attr{$_}{ $doc->{$_} } if defined $doc->{$_};
	}
	pop_doc( $doc );
}

sub subscribe_anon_doc { 
	$anon_docs{ 
		$_[0]->{'file_anon_nr'} = $lowest_free_anon_NR++ 
	} = $_[0] if is_document( $_[0] )
}
sub unsubscribe_anon_doc {
	delete $anon_docs{ $_[0]->{'file_anon_nr'} } if is_document( $_[0] ) and $_[0]->{'file_anon_nr'}
}


################################################################################
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
		#doc_panel()->set_active_bar($bar) unless $bar eq doc_bar();
		#$doc->{'active_editor'} = $doc->{'editor'}{ $bar };
		set_active_doc($doc);
	}
	doc_bar()->raise_page( $doc->{'panel'} );
	return $doc;
}

sub set_passive_doc { 
	my $obj = shift;
	if (is_document($obj)) {
		pop_doc($obj);
		push @doc_usage_queue, $obj;
	}
	return $obj;
}

sub pop_doc {
	my $doc = shift;
	return unless is_document($doc);
	for (0 .. $#doc_usage_queue){ splice (@doc_usage_queue, $_, 1) if exists $doc_usage_queue[$_] and $doc_usage_queue[$_] eq $doc }
}


################################################################################

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


1;
