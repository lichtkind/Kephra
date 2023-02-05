use v5.12;
use warnings;

package Kephra::Config::Default;

sub get {{
    file => '',
    session => {loaded => '', last => [] },
    document_default => {},
    editor => {
        change_pos => -1,
        change_prev => -1,
        caret_pos => -1,
        marker => [],
    },
    view => {
        whitespace    => 1,
        caret_line    => 1,
        eol           => 0,
        line_wrap => 0,
        line_nr_margin => 1,
        marker_margin => 1,
        right_margin  => 1,
        indent_guide  => 1,
        zoom_level => 0,
        full_screen => 0,
    },


}}

1;
