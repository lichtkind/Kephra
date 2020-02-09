#!usr/bin/perl
use v5.12;
use warnings;
BEGIN { unshift @INC, '.', 'lib' }

use Kephra::App;
$Kephra::NAME = 'Doc Edit KephraCP stage 2 -';
Kephra::App->new->MainLoop;
