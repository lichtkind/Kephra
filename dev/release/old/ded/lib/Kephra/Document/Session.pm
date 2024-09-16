use v5.12;
use warnings;

package Kephra::Document::Session;

use Kephra::API qw/doc_bar/;

my $auto_session_file = File::Spec->catfile(Cwd::cwd(),'session.yml');

sub restore_auto {
	if (-r $auto_session_file){
		my $data = YAML::Tiny->read( $auto_session_file );
		for (@{$data->[0]{'docs'}}) { Kephra::Document->new($_) }
		doc_bar()->raise_page( $data->[0]{'current'} );
		Kephra::Document->new() unless scalar @{$data->[0]{'docs'}};
	} else {
		Kephra::Document->new();
	}
}


sub save_auto {
	my $bar = doc_bar();
	my %h;
	for ($bar->leftmost_page_pos() .. $bar->rightmost_page_pos()){
		$h{'docs'}[$_] = Kephra::Document::Stash::find_doc_by_attr
				('panel', $bar->get_page_by_vis_nr($_) )->get_attribute_hash()
	}
	$h{'current'} = $bar->raised_vis_nr();
	my $yaml = YAML::Tiny->new( \%h );
	$yaml->write( $auto_session_file );
}


1;

# print "Instance METHOD IS  " . Dumper( \%{ref ($current_Time )."::" } )