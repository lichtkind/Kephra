use v5.18;
use warnings;
use YAML;           # dependencies
use Wx;
use Sereal;
use Digest::MD5;

# central starter
# name, version, important dir retrieval or setting

package Kephra;

our $NAME = 'Kephra outline';
our $VERSION = '0.4.1.1';

# create pipes
# fork;

# if main program
require Kephra::App;

# else
require Kephra::Worker;

1;
