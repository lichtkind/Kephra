use v5.20;
use warnings;
use utf8;

# definition and set (namespace) of standard data type checker objects

package Kephra::Base::Data::Type::Standard;
our $VERSION = 2.91;
use Kephra::Base::Data::Type::Set;

my $dummy_type = Kephra::Base::Data::Type::Basic->new('dummy', 'dummy', 1, undef, 1);
my $is_type = 'Kephra::Base::Data::Type::Factory::is_type';
my $std_set = 'Kephra::Base::Data::Type::Standard::set';

our @basic_type_definitions = (
  {name=> 'any',        help=> 'anything',             code=> '1',                                                 default=> '' },
  {name=> 'value',      help=> 'defined value',        code=> 'defined $value',                                    default=> '',     },#
  {name=> 'no_ref',     help=> 'not a reference',      code=> 'not ref $value',             parent=> 'value',                       symbol => '$' },
  {name=> 'bool',       help=> '0 or 1',               code=> '$value eq 0 or $value eq 1', parent=> 'no_ref',     default=> 0,     symbol => '?' },
  {name=> 'num',        help=> 'number',               code=> 'looks_like_number($value)',  parent=> 'no_ref',     default=> 0,     symbol => '+' },
  {name=> 'num_pos',    help=> 'greater equal zero',   code=> '$value >= 0',                parent=> 'num'                          },
  {name=> 'num_spos',   help=> 'greater equal zero',   code=> '$value > 0',                 parent=> 'num',        default=> 1  },
  {name=> 'int',        help=> 'integer',              code=> 'int($value) eq $value',      parent=> 'no_ref',     default=> 0,     symbol => 'Z' },
  {name=> 'int_pos',    help=> 'greater equal zero',   code=> '$value >= 0',                parent=> 'int',                         symbol => 'N' },
  {name=> 'int_spos',   help=> 'strictly positive',    code=> '$value > 0',                 parent=> 'int',        default=> 1  },
  {name=> 'str',        help=> 'character string',                                          parent=> 'no_ref',                      symbol => '~' },
  {name=> 'str_ne',     help=> 'none empty string',    code=> '$value or ~$value',          parent=> 'no_ref',     default=> ' '},
  {name=> 'str_lc',     help=> 'lower case string',    code=> 'lc $value eq $value',        parent=> 'str_ne',     default=> 'a'},
  {name=> 'str_uc',     help=> 'upper case string',    code=> 'uc $value eq $value',        parent=> 'str_ne',     default=> 'A'},
  {name=> 'word',       help=> 'word character',       code=> '$value =~ /^\w+$/',          parent=> 'str_ne',     default=> 'A'},
  {name=> 'word_lc',    help=> 'lower case name',      code=> 'lc $value eq $value',        parent=> 'word',       default=> 'a'},
  {name=> 'identifier', help=> 'begin with char',      code=> '$value =~ /^[a-z_]/',        parent=> 'word_lc',                     },
  {name=> 'pkg_name',   help=> 'package name',         code=> '$value =~ /^[A-Z][\w:]*$/',  parent=> 'str_ne',     default=> 'Pkg'},
  {name=> 'type_name',  help=> 'simple type name',     code=> __PACKAGE__.'::set->has_type($value)',
                                                                                            parent=>'identifier',  default=> 'any', },
  {name=> 'any_ref',    help=> 'reference of any sort',code=> q/ref $value/,                                       default=> [],    symbol => '\\' }, 
  {name=> 'scalar_ref', help=> 'array reference',      code=> q/ref $value eq 'SCALAR'/,                           default=> \1  },
  {name=> 'array_ref',  help=> 'array reference',      code=> q/ref $value eq 'ARRAY'/,                            default=> [],    symbol => '@'  },
  {name=> 'hash_ref',   help=> 'hash reference',       code=> q/ref $value eq 'HASH'/,                             default=> {},    symbol => '%'  },
  {name=> 'code_ref',   help=> 'code reference',       code=> q/ref $value eq 'CODE'/,                             default=> sub {}, symbol => '&'  },
  {name=> 'object',     help=> 'object reference',     code=> q/blessed($value)/,                                  default=> bless({}), symbol => '!'  },
  {name=> 'type',       help=> 'type checker object',  code=> $is_type.'($value)',                                 default=> $dummy_type, symbol => 'T' },
  {name=> 'element_type',help=>'basic type object',    code=> $is_type.q/($value,'basic')/,                        default=> $dummy_type},
);

our @parametric_type_definitions =  (
    {name => 'index',      help=> 'valid index of array',     code=> 'return "value $value is out of range" if $value >= @$param', 
                           parent=> 'int_pos',   default=>  0,     shortcut => 'I', 
                                           parameter => {   name => 'ne_array',     parent=> 'array_ref', default=> [1], help => 'none empty array' }, },
    {name =>'typed_array', help=> 'array with typed elements',     shortcut => '@',
     code=> 'for my $i(0..$#$value){my $error = $param->check_data($value->[$i]); return "array element $i $error" if $error}',
                                           parameter => 'element_type',          parent=> 'array_ref', default=> [1],   },
    {name =>'typed_array', help=> 'array with typed elements',                                             
     code => '$param = '.$std_set.'->get_type($param);for my $i(0..$#$value){my $error = $param->check_data($value->[$i]);'
                        .' return "array element $i $error" if $error}', 
                                           parameter => 'type_name',             parent=> 'array_ref', default=> [1],                },
    {name =>'typed_hash', help=> 'hash with typed values',         shortcut => '%',
     code=> 'for my $k(keys %$value){my $error = $param->check_data($value->{$k}); return "hash value of key $k $error" if $error}',
                                           parameter => 'element_type',          parent=> 'hash_ref',  default=> {''=>1},},
    {name =>'typed_hash', help=> 'hash with typed values',                       parent=> 'hash_ref',  default=> {''=>1}, parameter => 'type_name',
     code => '$param = '.$std_set.'->get_type($param);for my $k(keys %$value){my $error = $param->check_data($value->{$k});'
                        .' return "hash value of key $k $error" if $error}' },
    {name => 'named_ref', help=> 'reference of given type',  
     code=> 'return "value $value is not a $param reference" if ref $value ne $param',  parent=> 'value',     default=> [], 
                                           parameter => {   name => 'ref_name',  parent=> 'str',       default=> 'ARRAY', help => 'name of reference'}, },
);
our @forbidden_symbols = (qw/{ } ( ) < > - _ | = * ' "/,',');    # §    #  ^ ' " ! /  ;

my $set = set(); 
sub set {                                                               #    -->  .tset
    return $set if ref $set;
    $set = Kephra::Base::Data::Type::Set->new();
    $set->forbid_symbols(@forbidden_symbols);
    #     add_type( $_ = $typedef, no symbol[comes from type def], 1 = public [no owner] )
    $set->add_type( $_, undef, 1 ) for @basic_type_definitions, @parametric_type_definitions;
    $set->close();
    $set;
}

6;
