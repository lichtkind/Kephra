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



=head1 DESCRIPTION

Kephra is an editor from and for programmers.
This page gives you a summary how to use it. 
For a more thorough documentation and lots of example code please visit the L<Chart::Manual>.


=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/Kephra/main/dev/img/sed.png"    alt="point chart"               width="300" height="225">
</p>

=head2 File IO

=head2 Editing 

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
