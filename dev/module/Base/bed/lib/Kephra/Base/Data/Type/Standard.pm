use v5.20;
use warnings;
use utf8;

# definition and store of standard data type checker objects

package Kephra::Base::Data::Type::Standard;
our $VERSION = 2.8;
use Kephra::Base::Data::Type::Util;

my $dummy_type = Kephra::Base::Data::Type::Basic->new('dummy','yes',3,undef,5);

our @basic_type_definitions = (
    {name=> 'any',        help=> 'anything',             code=> '1',                                                     default=> '' },
    {name=> 'value',      help=> 'defined value',        code=> 'defined $value',                                        default=> '' },
    {name=> 'no_ref',     help=> 'not a reference',      code=> 'not ref $value',             parent=> 'value',                       },
    {name=> 'bool',       help=> '0 or 1',               code=> '$value eq 0 or $value eq 1', parent=> 'no_ref',         default=> 0  },
    {name=> 'num',        help=> 'number',               code=> 'looks_like_number($value)',  parent=> 'no_ref',         default=> 0  },
    {name=> 'num_pos',    help=> 'greater equal zero',   code=> '$value >= 0',                parent=> 'num'                          },
    {name=> 'num_spos',   help=> 'greater equal zero',   code=> '$value > 0',                 parent=> 'num',            default=> 1  },
    {name=> 'int',        help=> 'integer',              code=> 'int($value) eq $value',      parent=> 'no_ref',         default=> 0  },
    {name=> 'int_pos',    help=> 'greater equal zero',   code=> '$value >= 0',                parent=> 'int'                          },
    {name=> 'int_spos',   help=> 'strictly positive',    code=> '$value > 0',                 parent=> 'int',            default=> 1  },
    {name=> 'str',                                                                            parent=> 'no_ref',                      },
    {name=> 'str_ne',     help=> 'none empty string',    code=> '$value or ~$value',          parent=> 'no_ref',         default=> ' '},
    {name=> 'str_lc',     help=> 'lower case string',    code=> 'lc $value eq $value',        parent=> 'str_ne',         default=> 'a'},
    {name=> 'str_uc',     help=> 'upper case string',    code=> 'uc $value eq $value',        parent=> 'str_ne',         default=> 'A'},
    {name=> 'word',       help=> 'word character',       code=> '$value =~ /^\w+$/',          parent=> 'str_ne',         default=> 'A'},
    {name=> 'word_lc',    help=> 'lower case name',      code=> 'lc $value eq $value',        parent=> 'word',           default=> 'a'},
    {name=> 'identifier', help=> 'begin with char',      code=> '$value =~ /^[a-z]/',         parent=> 'word_lc',                     },
    {name=> 'pkg_name',   help=> 'package name',         code=> '$value =~ /^[A-Z][\w:]*$/',  parent=> 'str_ne',         default=> 'Pkg'},
    {name=> 'type_name',  help=> 'simple type name',     code=> __PACKAGE__.'::store->is_type_known($value)',parent=>'identifier', default=> 'any', },
    {name=> 'any_ref',    help=> 'reference of any sort',code=> q/ref $value/,                                           default=> [] }, 
    {name=> 'scalar_ref', help=> 'array reference',      code=> q/ref $value eq 'SCALAR'/,                               default=> \1  },
    {name=> 'array_ref',  help=> 'array reference',      code=> q/ref $value eq 'ARRAY'/,                                default=> []   },
    {name=> 'hash_ref',   help=> 'hash reference',       code=> q/ref $value eq 'HASH'/,                                 default=> {}    },
    {name=> 'code_ref',   help=> 'code reference',       code=> q/ref $value eq 'CODE'/,                                 default=> sub {} },
    {name=> 'object',     help=> 'object reference',     code=> q/blessed($value)/,                                      default=> bless {} },
    {name=> 'type',       help=> 'type checker object',  code=> 'ref $value ~~ [@Kephra::Base::Data::Type::Util::type_class_names]', default=> $dummy_type},
    {name=> 'element_type',help=>'basic type object',    code=> q/ref $value eq 'Kephra::Base::Data::Type::Basic'/,      default=> $dummy_type},
    );

our @parametric_type_definitions =  (
    {name => 'index',     help=> 'valid index of array',     code=> 'return "value $value is out of range" if $value >= @$param',               parent=> 'int_pos',   default=>  0, 
                                                                                                          parameter => {   name => 'array',     parent=> 'array_ref', default=> [1]    }, },
    {name =>'typed_array',help=> 'array with typed elements',code=> 'for my $i(0..$#$value){my $error = $param->check($value->[$i]); return "array element $i $error" if $error}',
                                                                                                          parameter => 'element_type',          parent=> 'array_ref', default=> [1],   },
    {name =>'typed_array',help=> 'array with typed elements',                                             parameter => 'type_name',             parent=> 'array_ref', default=> [1],
     code => '$param = Kephra::Base::Data::Type::Standard::store->get_type($param);for my $i(0..$#$value){my $error = $param->check($value->[$i]); return "array element $i $error" if $error}' },
    {name =>'typed_hash', help=> 'hash with typed values',   code=> 'for my $k(keys %$value){my $error = $param->check($value->{$k}); return "hash value of key $k $error" if $error}',
                                                                                                          parameter => 'element_type',          parent=> 'hash_ref',  default=> {''=>1},},
    {name =>'typed_hash', help=> 'hash with typed values',                                                parameter => 'type_name',             parent=> 'hash_ref',  default=> {''=>1},
     code => '$param = Kephra::Base::Data::Type::Standard::store->get_type($param);for my $k(keys %$value){my $error = $param->check($value->{$k}); return "hash value of key $k $error" if $error}' },
    {name => 'named_ref', help=> 'reference of given type',  code=> 'return "value $value is not a $param reference" if ref $value ne $param',  parent=> 'value',     default=> [], 
                                                                                                          parameter => {   name => 'ref_name',  parent=> 'str',       default=> 'ARRAY'}, },
);
our @forbidden_shortcuts = (qw/{ } ( ) < > - _ | = * ' "/,','); # §
our %basic_type_shortcut = (  value => '$', str => '~', bool => '?', num => '+', int_pos => 'N', int => 'Z', #  ^ ' " ! /  ;
                          array_ref => '@', hash_ref => '%', code_ref => '&', any_ref => '\\', 
                            type => 'T', object => '!');
our %parametric_type_shortcut = ( index => 'I', typed_array => '@', typed_hash => '%', );

my $store = Kephra::Base::Data::Type::Store->new(); 
sub store      {$store}                                      #    -->  .tstore
sub init_store {                                             #    -->  .tstore
    return $store unless $store->is_open();
    $store = Kephra::Base::Data::Type::Store->new();
    $store->forbid_shortcuts(@forbidden_shortcuts);
    for (@basic_type_definitions, @parametric_type_definitions){
        Kephra::Base::Data::Type::Util::substitude_names($_, $store);
        $store->add_type( $_ );
    }
    $store->add_shortcut( 'basic', $_, $basic_type_shortcut{$_} )   for keys %basic_type_shortcut;
    $store->add_shortcut( 'param', $_, $parametric_type_shortcut{$_} ) for keys %parametric_type_shortcut;
    $store->close();
    $store;
}

6;
