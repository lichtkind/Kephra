use v5.20;
use warnings;
use utf8;

# definitions of standard data type checker objects

package Kephra::Base::Data::Type::Standard;
our $VERSION = 2.2;
use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;

our @forbidden_shortcuts = (qw/{ } ( ) < > -/, ",");
our %basic_shortcuts = (   str => '~', bool => '?', num => '+', int => '#', pos_int => '=', #  ^ ' " ! . /  §;
                          value => '$', array_ref => '@', hash_ref => '%', code_ref => '&', any_ref => '\\', 
                           type => '|', arg_name => ':',  object => '!');
our %parametric_shortcuts = ( typed_array => '@', typed_hash => '%');
our @basic_types = (
    {name => 'any',       help=> 'anything',             code=> '1',                                                default=> '' },
    {name => 'value',     help=> 'defined value',        code=> 'defined $value',                                   default=> '' },
    {name => 'no_ref',    help=> 'not a reference',      code=> 'not ref $value',             parent=> 'value',                  },
    {name => 'bool',      help=> '0 or 1',               code=> '$value eq 0 or $value eq 1', parent=> 'no_ref',    default=> 0  },
    {name => 'num',       help=> 'number',               code=> 'looks_like_number($value)',  parent=> 'no_ref',    default=> 0  },
    {name => 'num_pos',   help=> 'greater equal zero',   code=> '$value >= 0',                parent=> 'num'                     },
    {name => 'num_spos',  help=> 'greater equal zero',   code=> '$value > 0',                 parent=> 'num',       default=> 1  },
    {name => 'int',       help=> 'integer',              code=> 'int($value) eq $value',      parent=> 'no_ref',    default=> 0  },
    {name => 'int_pos',   help=> 'greater equal zero',   code=> '$value >= 0',                parent=> 'int'                     },
    {name => 'int_spos',  help=> 'strictly positive',    code=> '$value > 0',                 parent=> 'int',       default=> 1  },
    {name => 'str',                                                                           parent=> 'no_ref',                 },
    {name => 'str_ne',    help=> 'none empty string',    code=> '$value or ~$value',          parent=> 'no_ref',    default=> ' '},
    {name => 'str_lc',    help=> 'lower case string',    code=> 'lc $value eq $value',        parent=> 'str_ne',    default=> 'a'},
    {name => 'str_uc',    help=> 'upper case string',    code=> 'uc $value eq $value',        parent=> 'str_ne',    default=> 'A'},
    {name => 'word',      help=> 'word character',       code=> '$value =~ /^\w+$/',          parent=> 'str_ne',    default=> 'a'},
    {name => 'arg_name',  help=> 'argument name',        code=> 'lc $value eq $value',        parent=> 'word',      default=> 'a'},
    {name => 'type_name', help=> 'simple type name',     code=> 'ref Kephra::Base::Data::Type::Standard::get($value)',                          
                                                                                              parent=> 'arg_name',  default=> 'no_ref'},
    {name => 'scalar_ref',help=> 'array reference',      code=> q/ref $value eq 'SCALAR'/,                          default=> \1  },
    {name => 'array_ref', help=> 'array reference',      code=> q/ref $value eq 'ARRAY'/,                           default=> []   },
    {name => 'hash_ref',  help=> 'hash reference',       code=> q/ref $value eq 'HASH'/,                            default=> {}    },
    {name => 'code_ref',  help=> 'code reference',       code=> q/ref $value eq 'CODE'/,                            default=> sub {} },
    {name => 'type',      help=> 'code reference',       code=> q/ref $value eq 'Kephra::Base::Data::Type::Basic'/, default=> Kephra::Base::Data::Type::Basic->new('t','test',3,undef,4) },
    {name => 'object',    help=> 'object reference',     code=> q/blessed($value)/,                                 default=> bless {} },
#   {name => 'kb_object', help=> 'kephra base object',   code=> q/blessed($value)/,                                 default=> bless {} },
    {name => 'any_ref',   help=> 'reference of any sort',code=> q/ref $value/,                                      default=> [] }, 
    );

our @parametric_types =  ( # standard simple types - no package can delete them
    {name => 'typed_ref', help=> 'reference of given type',  code=> 'return "value $value is not a $param reference" if ref $value ne $param',  parent=> 'value',     default=> [], 
                                                                                                          parameter => {   name => 'refname',   parent=> 'str',       default=> 'ARRAY'}, },
    {name => 'index',     help=> 'valid index of array',     code=> 'return "value $value is out of range" if $value >= @$param',               parent=> 'int_pos',   default=>  0, 
                                                                                                          parameter => {   name => 'array',     parent=> 'array_ref', default=> [1]    }, },
    {name =>'typed_array',help=> 'array with typed elements',code=> 'for my $i(0..$#$value){my $error = $param->check($value->[$i]); return "aray element $i $error" if $error}',
                                                                                                                                                parent=> 'array_ref', default=> [1],
                                                                                                          parameter => {  name =>'element_type',parent=> 'type',                       }, },
);

sub init {
}
my $standard_types = Kephra::Base::Data::Type::Store->new(''); 



5;
