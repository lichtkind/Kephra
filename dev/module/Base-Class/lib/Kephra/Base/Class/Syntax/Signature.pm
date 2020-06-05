use v5.20;
use warnings;

# parsing signatures into data structure to build definition object from

package Kephra::Base::Class::Syntax::Signature;
our $VERSION = 1.0;

sub parse {
    my $sig = shift // '';
    my ($req, $opt, $ret) = ([],[],[]);
    $/ = ' ';
    my $pos = rindex($sig, '-->');
    if ($pos > -1) { 
        $ret = split_args(substr($sig, $pos+3));
        push @$ret, ['', 'pass'] unless @$ret;
        unshift @{$ret->[$_]}, 'return_value_'.($_+1) for 0..$#$ret;
        $sig = substr($sig, 0, $pos);
    }
    $pos = index($sig, '-');
    if ($pos > -1) {
        $opt = split_args(substr $sig, $pos+1);
        $sig = substr($sig, 0, $pos);
    }
    $req = split_args($sig);
    [int @$req, int @$opt, int @$ret,  map {eval_special_syntax($_)} @$req, @$opt, @$ret];
}


sub split_args {
    return [] unless defined $_[0];
    my $args = [];
    for (split ',', shift){
        my $arg = split_arg_parts($_);
        next unless @$arg;
        unshift @$arg, (pop @$arg);
        push @$args, $arg;
    }
    $args;
}

sub split_arg_parts {
    return [] unless $_[0];
    my $arg = shift;
    1 while chomp($arg);
    [split ' ', $arg];
}

sub eval_special_syntax {
    my $arg = shift;
    splice (@$arg, 2, 1) if @$arg > 3 and $arg->[2] eq 'of';    # remove of
    my $sigil = substr($arg->[0], 0, 1);
    if (ord $sigil < 97 or ord $sigil > 122){
        my $twigil = substr($arg->[0], 1, 1);
        if (ord $twigil < 97 or ord $twigil > 122){
            $arg->[0] = substr $arg->[0], 2;
            splice (@$arg, 1, 0, $sigil.$twigil);
        } else {
            $arg->[0] = substr $arg->[0], 1;
            if ($sigil eq '.'){ splice (@$arg, 1, 0, '', 'attr') }
            else              { splice (@$arg, 1, 0, $sigil)     }
        }
    }
    if (@$arg == 2){
        if ($arg->[1] eq '>@') { splice (@$arg, 1, 1, '', 'slurp') }
        else {
            my $sigil = substr($arg->[1], 0, 1);
            if (ord $sigil < 97 or ord $sigil > 122){
                $arg->[1] = substr $arg->[1], 1;
                if ($sigil eq '.'){ splice (@$arg, 2, 0, 'attr') }
                else              { splice (@$arg, 2, 0, $sigil) }
            }
        }  
    }
    if (@$arg == 4){
        $arg->[2] = 'arg' if $arg->[2] eq 'argument';
        $arg->[2] = 'attr' if $arg->[2] eq 'attribute';
    }
    splice (@$arg, 2, 0, 'type') if @$arg == 3 and $arg->[1];
    $arg;
}

1;
__END__

 [~]                   1    # ~ means argument name
 [~ T]                 2    # T means argument main type
 [~ T? 'slurp']        3    # a.k.a. >@ ; T? means most of time its empty = ''
 [~ T? 'pass']         3    # a.k.a. -->' '
 [~ T? 'attr']         3    # constructor arg thats forewards to attribute
 [~ T  'type'   T]     4 
 [~ T  'arg'    ~  T!] 5    # T! means Type of argument (parameter type of main type) will be added later by Definition::Method::Signature
 [~ T  'attr'   ~  T!] 5    # T! means Type of attribute (parameter type of main type) will be added later by Definition::Method::Signature
