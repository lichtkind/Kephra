#!usr/bin/perl
use v5.12;
use warnings;
use Wx;
use Kephra::App::Window;

package Kephra;

our $VERSION = 0.41;
our $NAME = 'Kephra';

use base qw(Wx::App);

sub OnInit {
    my $app  = shift;
    my $window = $app->{'win'} = Kephra::App::Window->new();
    $window->Center();
    $window->Show(1);
    $app->SetTopWindow( $window );
    1;
}

sub close  { $_[0]->{'frame'}->Close() }

sub OnExit {
    my $app = shift;
    Wx::wxTheClipboard->Flush;
    # $app->{'win'}->Destroy;
    1;
}

1;

__END__

=pod

=head1 NAME

Kephra - small but effective and beautiful coding editor

=head1 SYNOPSIS 

    kephra [file_name]

Small single file editor for perl with max editing comfort.

=head1 DESCRIPTION

Kephra is an editor from and for programmers, currently at start of rewrite.
This page gives you a summary how to use it. 
For a more thorough documentation and lots of example code please visit the L<Chart::Manual>.


=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/Kephra/main/dev/img/sed.png"    alt="point chart"               width="300" height="225">
</p>

=head2 File IO

Currently just the basics: ASCII and UTF-8 coding. Open, reload, save and
saving under different file name. See the menu for key kombos.

=head2 Editing 

Basic editing as expected: undo redo, cut copy paste delete. 
When nothing is selected Ctrl+C copies current line.

Slightly more advanced is swapping selection and clipboard (Ctrl+Shift+V)
and duplicate current line or selection with Ctrl+D. Ctrl+A grows selection
from word to expression to line, block, sub until all is selected and
shrink selection is just the opposite (Ctrl+Shift+A).

Holding Ctrl allows you no navigate with left and right as expected word
wise, up and down block wise and page up and page down subroutine wise.
If the cursor is next to round a brace character you will navigate the its
partner.

Holding Alt moves the selected or current line up or down. Left and right
indent and dedents char wise in this mode. Normal indent/dedent listens
to Tab and Shift+Tab.

Bracing characters (including '' and "") are always created in pairs and
will embrace the selection.

=head2 Search and Replace

=head1 PLAN

For more please check the TODO file.

=head1 AUTHOR

Herbert Breunung (lichtkind@cpan.org)

=back

=head1 COPYRIGHT

Copyright(c) 2022 by Herbert Breunung

All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the GPL version 3.

=cut
