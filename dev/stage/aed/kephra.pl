#!usr/bin/perl
use v5.12;
use warnings;
BEGIN { unshift @INC, '.' }
use Wx;

use Kephra::App;
$Kephra::NAME = 'View Edit KephraCP step 3 - ';
Kephra::App->new->MainLoop;
