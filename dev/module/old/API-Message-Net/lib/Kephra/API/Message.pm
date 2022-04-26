use v5.14;
use warnings;

package Kephra::API::Message;
our $VERSION = 0.02;
use parent      qw/Kephra::API::Object/;
use Kephra::API qw/:log date_time sub_caller/;

my @user_keys = qw/content topic comment/;

################################################################################

sub BUILD      {  # text/hash  --> obj
    my ($self, $msg) = @_;
    if    (ref $msg eq 'HASH') { $self->{$_}      = $msg->{$_} for @user_keys } 
    elsif (not ref $msg)       { $self->{content} = $msg                      }
    else                       { return warning('message data has to be text or hashref');}

    ($self->{'date'}, $self->{'time'}) = (date_time());
    my ($file, $line, $sub, $package) = sub_caller(2);
    $self->{sender} = $sub ? "$package::$sub" : $package;
    $self;
}

sub set_channel { # dir name   --> bool
    my ($self, $dir, $name) = @_;
    return error('need two parameter: direction (in or out) and name') if @_ != 3;
    return error('direction has to be in or out!') if lc $dir ne 'in' and lc $dir ne 'out';
    return 0 if $self->{"channel_$dir"}; # only once
    $self->{"channel_$dir"} = $name;
}

################################################################################

sub content    {  #            --> str
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{content};
}

sub topic      {  #            --> str
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{topic};
}

sub date       {  #            --> str
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{date};
}

sub time       {  #            --> str
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{time};
}

sub sender     {  #            --> obj
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{sender};
}

sub channel_in {  #            --> str
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{channel_in};
}

sub channel_out{  #            --> str
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{channel_out};
}

################################################################################

sub status     {  #            --> ref
    return error('need to be called as method with no parameter') if @_ != 1;
    my ($self) = @_;
    my $r = "$self:\n";

    $r;
}

1;
