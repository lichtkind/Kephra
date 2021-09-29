use v5.20;
use warnings;

package Kephra::Base::Class::Definition::Method;
our $VERSION = 0.1;
use Kephra::Base::Class::Definition::Method::Signature;

sub new           { # ~name %sig_def ~code >@keywords               --> _
    my ($pkg, $name, $help, $sig_def, $code, $scope, $multi) = (@_);
    return "need a name (string), signature definition (hash ref), code (string) and keywords to create a method definition" unless ref $sig_def eq 'HASH' and defined $code;
    my $category = (kind => '', scope => '', multi => '');
    for my $kw (@keywords){
        return "unknown keyword $kw in method definition" unless exists $keyword_category{$kw};
        return "method keyword $kw in definition is in conflict with previous a keyword" if $category{ $keyword_category{$kw} };
        $category{ $keyword_category{$kw} } = $kw;
    }
    $category{'kind'}  ||= 'basic';
    $category{'scope'} ||= $keyword_scope{$kind};
    $category{'signature'} = Kephra::Base::Class::Definition::Method::Signature->new($sig_def);
    return "method $name ".$category{'signature'} unless ref $category{'signature'};
    $category{'code'} = $code;
    bless $category;
}
sub state         { # _                          --> %state
}
sub restate       { # %state                      --> _
}
################################################################################
sub adapt_to_class { # _                          --> ~errormsg

}


1;

__END__
