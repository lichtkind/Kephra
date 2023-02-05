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
        cursor_pos => -1,
        marker => [],
    },
    view => {
        right_margin => 1,
    },


}}

1;
