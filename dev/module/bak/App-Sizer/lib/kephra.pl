#!usr/bin/perl
use v5.12;
use warnings;
BEGIN { unshift @INC, '.', 'lib' }

use Kephra::App;
$Kephra::NAME = 'KephraCP - doc bar proto';
Kephra::App->new->MainLoop;
