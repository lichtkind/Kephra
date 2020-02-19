use v5.20;
use warnings;

# self made data types, standards + defined by any class

package Kephra::Base::Data::Type::Relative;
use Kephra::Base::Data::Type;

sub add            {} # ~type ~help &check - .default ~parent ~shortcut -->  bool
sub delete         {} # ~type                                           -->  bool
sub list_names     {} #                                                 -->  @~type

sub is_known           {} # ~type                -->  bool
sub is_standard        {} # ~type                -->  bool
sub is_owned           {} # ~type ~package ~file -->  bool

sub get_default_value  {} # ~type                -->  .default|undef
sub get_checks         {} # ~type                -->  @checks  = [[~help, &check]]
sub get_callback       {} # ~type                -->  &callback

sub check          {} # ~type .val               -->  ~errormsg|''    = "reason .val"
sub guess          {} # .val                     -->  @~type

1;

# example = bool  => {check => ['boolean', sub{$_[0] eq 0 or $_[0] eq 1}],  parent => 'value', default=>0},
