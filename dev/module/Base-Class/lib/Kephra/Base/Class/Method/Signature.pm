use v5.16;
use warnings;

# handling everything about signatures

package Kephra::Base::Class::Method::Signature;

sub parse {
    my $sig = shift;
    return 'need a signature' unless defined $sig;
    my %params = (required_nr => 0, input => [], output => '');
    return \%params unless $sig;
    my $pos = rindex($sig,'-->',length $sig);
    if ($pos > -1){
        $params{output} = substr $sig, $pos+3;
        $params{output} =~ tr/ //d;
        $sig = substr $sig, 0, $pos;
    }
    $pos = rindex($sig,'-',length $sig);
    if ($pos > -1){
        for (split(',', substr($sig, $pos+1))){
            s/^\s+//; s/\s+$//;
            next unless $_;
            my @kv = split /\s+/, $_;
            next unless @kv == 2;
            push @{$params{input}}, \@kv;
        }
        $sig = substr $sig, 0, $pos;
    }
    for (reverse split(',', $sig)){
        s/^\s+//; s/\s+$//;
        next unless $_;
        my @kv = split /\s+/, $_;
        next unless @kv == 2;
        unshift @{$params{input}}, \@kv;
        $params{required_nr}++;
    }
    \%params;
}

sub types_needed {
    my ($params) = @_;
    my %types;
    $types{ $params->{output}}++ if $params->{output};
    $types{ $_->[0] }++ for @{$params->{input}};
    \%types;
}

sub create_type_check {
    my ($params, $class_types, $method_name) = @_;
    my ($req, $all) = ($params->{required_nr}, scalar(@{$params->{input}}));
    my %name;
    for (@{$params->{input}}) {
        return "more than one parameter with name $_->[1]" if $name{$_->[1]};
        $_->[2] = $class_types->check_callback($_->[0]);
        $name{$_->[1]}++;
        return "input type $_->[0] is not known in class ".$class_types->{class} unless ref $_->[2] eq 'CODE';
    }
    return "output type $_->[0] is not known in class ".$class_types->{class}
        if $params->{output} and not $class_types->is_known($params->{output});

    sub {my $ret = {}; my $error;
        my $access_scope_self = shift;
        if (@_ == 1 and ref $_[0] eq 'HASH') {
            my ($cc, $values) = (0, shift);
            for (@{$params->{input}}){
                my ($type, $name, $check) = @{$_};
                return "method $method_name needs value for parameter $name."
                    if $cc < $params->{required_nr} and not exists $values->{$name};
                $cc++;
                if (exists $values->{$name}){
                    my $msg = $check->($values->{$name}, $access_scope_self);
                    $error .= "parameter $name with value $msg" if $msg;
                    $ret->{$name} = $values->{$name};
                } else {$ret->{$name} = $class_types->default_value($name)}
            }
        } else {
            my $got = scalar @_;
            return "method $method_name got $got parameter, but need at least $req." if $got < $req;
            return "method $method_name got $got parameter, but can take only $all." if $got > $all;
            for (0 .. $all-1){
                my ($value, $par) = (shift, $params->{input}[$_]);
                my $parname = $par->[1];
                if (defined $value){
                    my $msg = $par->[2]->( $value, $access_scope_self);
                    $error .= "parameter $parname with value $msg" if $msg;
                    $ret->{$parname} = $value;
                } else {$ret->{$parname} = $class_types->default_value($par->[0])}
            }
        }
        $error ? "method $method_name input $error" : $ret;
    }, ($params->{output} ? $class_types->check_callback($params->{output}) : sub {''});
}

1;
