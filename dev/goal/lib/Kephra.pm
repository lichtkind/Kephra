use v5.20;
use warnings;
use YAML;           # dependencies
use Sereal;
use Digest::MD5;
use Wx;
use Wx::STC;

# central starter
# name, version, important dir retrieval or setting

package Kephra;

our $NAME = 'Kephra goal';
our $VERSION = '0.4.1.2';

# create pipes
# fork;

# if main program
require Kephra::App;

# else
require Kephra::Worker;

1;
