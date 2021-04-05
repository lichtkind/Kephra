use v5.20;
use warnings;

# parsing signatures into data structure to build definition object from

package Kephra::Base::Class::Syntax::Signature;
our $VERSION = 1.2;

sub parse {
    my $sig = shift // '';
    my ($opt, $ret) = ('','');
    $/ = ' ';
    if (rindex($sig, '=') > -1) {
        
    } else {
    }
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
    {in_required  => (   @$req ? [map {eval_special_syntax($_)} @$req] : ''),
     in_optional  => (ref $opt ? [map {eval_special_syntax($_)} @$opt] : ''),
     out_required => (ref $ret ? [map {eval_special_syntax($_)} @$ret] : ''),
     out_optional => (),
    };
}
sub parse_args {
    my $args = shift;
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
            if    ($sigil eq '.'){ splice (@$arg, 1, 0, '', 'Foreward') }
            else                 { splice (@$arg, 1, 0, $sigil)         }
        }
    } #say "mid:@$arg:";
    if (@$arg == 2){
        if    ($arg->[1] eq '>@'){ splice (@$arg, 1, 1, '', 'Slurpy') }
        elsif ($arg->[1] eq '_') { splice (@$arg, 1, 1, '', 'Self')     }
        else {
            my $sigil = substr($arg->[1], 0, 1);
            my $ord = ord $sigil;
            my $rest = substr($arg->[1], 1);
            splice (@$arg, 1, 1, $sigil, $rest) if ($ord > 122 or $ord < 97) and $rest;
        }  
    } elsif (@$arg == 3 and substr($arg->[2], 0, 1) eq '.'){
        splice (@$arg, 2, 1, 'Attr', substr($arg->[2], 1)  ) 
    } elsif (@$arg == 4){
        $arg->[2] = 'Arg' if $arg->[2] eq 'Argument';
        $arg->[2] = 'Attr' if $arg->[2] eq 'Attribute';
    }
    splice (@$arg, 2, 0, 'Type') if @$arg == 3 and $arg->[1]; #say "after:@$arg:";
    return $arg->[0] if @$arg == 1;
    $arg;
}

1;
__END__

 [~]   'name'                  1    # ~ means argument name
 [~ T? 'foreward']             3    # = constructor arg thats forewards to attribute
 [~ T? 'slurpy']               3    # a.k.a. *@ or *%; T? means most of time its empty = ''
 [~ T] 'typed'                 2    # T means argument main type
 [~ T? 'self']                 3    # a.k.a. _  ; typed_ref class
 [~ T  'complex' T  $def ]     4-5 
 [~ T  'arg'     ~  T!   $def] 5-6  # T! means Type of argument (parameter type of main type) will be added later by Definition::Method::Signature
 [~ T  'attr'    ~  T!   $def] 5-6  # T! means Type of attribute (parameter type of main type) will be added later by Definition::Method::Signature

# [~ T? 'pass']         3    # a.k.a. -->' ', now return => []