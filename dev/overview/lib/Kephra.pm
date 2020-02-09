use v5.16;
use warnings;

# central starter
# name, version, important dir retrieval or setting

package Kephra;

our $NAME = 'Kephra outline';
our $VERSION = '0.4.1';

# create pipes
# fork;

# if main program
require Kephra::App;

# else
require Kephra::Worker;

1;
