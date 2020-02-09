use v5.12;
use warnings;
use Exporter;


package Kephra::Document::Edit;
our @ISA = qw(Exporter);
our @EXPORT = qw/get_cursor_pos move_cursor_to_pos start_changeset end_changeset/;


sub get_cursor_pos {
	my ($self) = @_;
	$self->{'editor'}->GetCurrentPos();
}
sub move_cursor_to_pos {
	my ($self, $pos) = @_;
	$self->{'editor'}->SetSelection($pos, $pos);
}
sub get_chars_from_to{ }
sub get_lines_from_to{ }
sub insert_text_at_pos{ }
sub insert_text_at_line{ }
sub delete_text_from_to { }
sub start_changeset{ }
sub end_changeset{ }

1;