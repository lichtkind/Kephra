use v5.20;
use warnings;

# validate and serialize method definition
# 0103_Base-Class-Definition-Method.t

package Kephra::Base::Class::Definition::Method;
our $VERSION = 0.2;
#use Kephra::Base::Class::Definition::Method::Signature;
use Kephra::Base::Class::Definition::Scope;

sub new           { # ~name %sig_def ~code >@keywords               --> _
    my ($pkg, $name, $sig_def, $code, $scope, $help) = (@_);
    return "need a name (string), signature definition (hash ref), code (string) and keywords to create a method definition" unless ref $sig_def eq 'HASH' and defined $code;
    
    my $error_start = "definition of class attribute '$name'";

    return "need a name (string), signature definition (hash ref), code (string) and keywords to create a method definition" unless ref $sig_def eq 'HASH' and defined $code;
    my $self = (kind => '', scope => '', multi => '');
    for my $kw (@keywords){
        return "unknown keyword $kw in method definition" unless exists $keyword_category{$kw};
        return "method keyword $kw in definition is in conflict with previous a keyword" if $self{ $keyword_category{$kw} };
        $self{ $keyword_category{$kw} } = $kw;
    }
    $self{'kind'}  ||= 'basic';
    $self{'scope'} ||= $keyword_scope{$kind};
    $self{'signature'} = Kephra::Base::Class::Definition::Method::Signature->new($sig_def);
    return "method $name ".$self{'signature'} unless ref $self{'signature'};
    $self{'code'} = $code;
    bless $self;
}


################################################################################
sub state       { $_[0] }
sub restate     { bless shift }
################################################################################
sub code        {$_[0]->{'code'}}
sub help        {$_[0]->{'help'}}
sub scope       {$_[0]->{'scope'}}
sub signature   {$_[0]->{'signature'}}

1;

__END__

help: ~
code: ~
scope : 'build' | 'access' | 'private' | 'public'
signature: [reqin, optin, reqout, optout, [arg] ....]  ; 
    arg = kind ?subkind ~name ?type sectype .....
    kind: FF                     (foreward ... to attr) 
          SLURP array(default)/hash, arrayref, hashref
          ATTR  ~name
          ARG   ~name
