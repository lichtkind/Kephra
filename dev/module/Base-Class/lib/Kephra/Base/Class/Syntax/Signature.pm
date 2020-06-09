use v5.20;
use warnings;

# parsing signatures into data structure to build definition object from

package Kephra::Base::Class::Syntax::Signature;
our $VERSION = 1.0;

sub parse {
    my $sig = shift // '';
    my ($opt, $ret) = ('','');
    $/ = ' ';
    my $pos = rindex($sig, '-->');
    if ($pos > -1) { 
        $ret = split_args(substr($sig, $pos+3));
        push @{$ret->[$_]}, 'return_value_'.($_+1) for 0..$#$ret;
        $sig = substr($sig, 0, $pos);
    }
    $pos = index($sig, '-');
    if ($pos > -1) {
        $opt = split_args(substr $sig, $pos+1);
        $opt = '' unless @$opt;
        $sig = substr($sig, 0, $pos);
    }
    my $req = split_args($sig);
    {req => (   @$req ? [map {eval_special_syntax($_)} @$req] : ''),
     opt => (ref $opt ? [map {eval_special_syntax($_)} @$opt] : ''),
     ret => (ref $ret ? [map {eval_special_syntax($_)} @$ret] : ''),
    };
}


sub split_args {
    return [] unless defined $_[0];
    [ map {[split ' ', $_]} grep {$_} map {1 while chomp($_);$_} split ',', $_[0] ];
}

sub eval_special_syntax {
    my $arg = shift;  #$" = ':';#say "before:@$arg:";
    unshift @$arg, (pop @$arg);
    splice (@$arg, 2, 1) if @$arg > 3 and $arg->[2] eq 'of';    # remove of
    my $sigil = substr($arg->[0], 0, 1);
    my $ord = ord $sigil;
    if ($ord > 122 or ($ord < 97 and $ord)){
        my $twigil = substr($arg->[0], 1, 1);
        if (ord $twigil < 97 or ord $twigil > 122){
            $arg->[0] = substr $arg->[0], 2;
            splice (@$arg, 1, 0, $sigil.$twigil);
        } else {
            $arg->[0] = substr($arg->[0], 1);
            if ($sigil eq '.'){ splice (@$arg, 1, 0, '', 'foreward') }
            else              { splice (@$arg, 1, 0, $sigil)     }
        }
    } #say "mid:@$arg:";
    if (@$arg == 2){
        if ($arg->[1] eq '>@') { splice (@$arg, 1, 1, '', 'slurp') }
        else {
            my $sigil = substr($arg->[1], 0, 1);
            my $ord = ord $sigil;
            my $rest = substr($arg->[1], 1);
            splice (@$arg, 1, 1, $sigil, $rest) if ($ord > 122 or $ord < 97) and $rest;
        }  
    } elsif (@$arg == 3 and substr($arg->[2], 0, 1) eq '.'){
        splice (@$arg, 2, 1, 'attr', substr($arg->[2], 1)  ) 
    } elsif (@$arg == 4){
        $arg->[2] = 'arg' if $arg->[2] eq 'argument';
        $arg->[2] = 'attr' if $arg->[2] eq 'attribute';
    }
    splice (@$arg, 2, 0, 'type') if @$arg == 3 and $arg->[1]; #say "after:@$arg:";
    return $arg->[0] if @$arg == 1;
    $arg;
}

1;
__END__

 [~]                   1    # ~ means argument name
 [~ T]                 2    # T means argument main type
 [~ T? 'foreward']     3    # constructor arg thats forewards to attribute
 [~ T? 'slurp']        3    # a.k.a. >@ ; T? means most of time its empty = ''
 [~ T  'type'   T]     4 
 [~ T  'arg'    ~  T!] 5    # T! means Type of argument (parameter type of main type) will be added later by Definition::Method::Signature
 [~ T  'attr'   ~  T!] 5    # T! means Type of attribute (parameter type of main type) will be added later by Definition::Method::Signature

# [~ T? 'pass']         3    # a.k.a. -->' '
