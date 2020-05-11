use v5.16;
use warnings;

# parse self made OO syntax and call the builder appropriately
# signature syntax handeled by K::B::Class::Method::Signature

package Kephra::Base::Class::Syntax::Parser;
our $VERSION = 0.01;
use Keyword::Simple;
use Kephra::Base::Class::Builder;
################################################################################
my %rules = (
    class      => {parse => [qw/name/]},
    type       => {parse => [qw/name HASH/], prefix => {'' =>1, object =>1} },
    object     => {store => 1},
    attribute  => {parse => [qw/name HASH/], prefix => {'' =>1, delegating =>1, wrapping =>1} },
    delegating => {store => 1},
    wrapping   => {store => 1},
    constructor=> {parse => [qw/name signature CODE/],  delete => qr/^\s*method\s*/},
    destructor => {parse => [qw/name signature CODE/],  delete => qr/^\s*method\s*/},
    getter     => {parse => [qw/name signature CODE/],  delete => qr/^\s*method\s*/},
    setter     => {parse => [qw/name signature CODE/],  delete => qr/^\s*method\s*/},
    delegator  => {parse => [qw/name signature CODE/],  delete => qr/^\s*method\s*/},
    wrapper    => {parse => [qw/name signature CODE/],  delete => qr/^\s*method\s*/},
    method     => {parse => [qw/name signature CODE/],  prefix => {'' =>1, public =>1, private =>1, multi =>1} },
    multi      => {store => 1,                          prefix => {'' =>1, public =>1, private =>1}},
    public     => {store => 1},
    private    => {store => 1},

);@_
my %parse = (name => qr/\s*([^\s;{]+)\s*/, signature => qr/\s*\(\s*([^)]*)\s*\)/, separator => qr/\s*(?:=>|,|;)\s*/);
my (%callback, %prefix, $previous_keyword, $current_class);
################################################################################
sub import   { Keyword::Simple::define($_, $callback{$_}) for keys %rules }
sub unimport { Keyword::Simple::undefine($_)              for keys %rules }
################################################################################
for my $rule_name (keys %rules){
    my $rule = $rules{$rule_name};
    $callback{$name} = sub {
        my ($ref) = @_; #say "=before, $name, $previous_keyword: ", substr($$ref, 0 ,100);
        die "syntax error: no keyword $name after $previous_keyword allowed!"
            if (($previous_keyword and not exists $rule->{'prefix'})
            or  (exists $rule->{'prefix'} and not exists $rule->{'prefix'}{$previous_keyword}));
        if ($rule->{'store'}) { $prefix{$previous_keyword = $rule_name}++ }
        else {
            my @build_parameter;
            if ($rule->{'delete'})              {$$ref =~ s/$rule->{delete}//}
            if (ref $rule->{'parse'} eq 'ARRAY'){
                for (@{$rule->{'parse'}}){# say  "== ",$_;
                   if ($_ eq 'name') {
                       $$ref =~ s/^$parse{name}//;
                       push @build_parameter, $1; # say "=== name = ", $1;
                   } elsif ($_ eq 'HASH') {
                       my $endpos = closing_brace_pos($ref)+1;
                       my $data = eval substr($$ref,0,$endpos);
                       die "malformed syntax of data hash in class $current_class on $rule_name ".$build_parameter[0].' - '.substr($$ref,0,$endpos)." : $@"
                           if $@ or ref $data ne 'HASH';
                       push @build_parameter, $data; # say  "=== HASH = ",$data,' ',substr($$ref,0,$endpos);
                       substr($$ref,0,$endpos) = '';
                   } elsif ($_ eq 'CODE') {
                       my $endpos = closing_brace_pos($ref)+1;
                       my $code = eval 'sub'.substr($$ref,0,$endpos);
                       die "malformed syntax of code block in class $current_class on $rule_name ".$build_parameter[0].' - '.substr($$ref,0,$endpos)." : $@"
                           if $@ or ref $code ne 'CODE';
                       push @build_parameter, $code; # say  "=== CODE = ",$code,' ',substr($$ref,0,$endpos);
                       substr($$ref,0,$endpos) = '';
                   } elsif ($_ eq 'signature') {
                       $$ref =~ s/^$parse{signature}//;
                       my $params = Kephra::Base::Class::Method::Signature::parse($1);
                       die "malformed syntax of signature in class $current_class on $rule_name ".$build_parameter[0]." : $1" unless ref $params eq 'HASH';
                       push @build_parameter, $params; #say  "=== sig = ",$params,' ', $1;
                   } else { die "unknown Kephra syntax parsing rule $_" }
                   $$ref =~ s/^$parse{separator}//;
                }
                if ($name eq 'class'){ # insert code trigger the completion (rendering) class
                    $current_class = shift @build_parameter;
                    substr($$ref, 0, 0) = "Kephra::Base::Class::Builder::make 'finalize','$current_class';"
                }
                if (ref $rule->{parse} and ref $rule->{prefix}){
                    my %pre = %prefix;    # previous keywords are parameters of the builder call
                    push @build_parameter, \%pre;
                }
                Kephra::Base::Class::Builder::make($name, $current_class, @build_parameter);
            }
            if ($rule->{'insert'})  {
                substr($$ref, 0, 0)                   = $rule->{insert}{front} if $rule->{insert}{front};
                substr($$ref, index($$ref, ';')+1, 0) = $rule->{insert}{back} if $rule->{insert}{back};
            }
            %prefix = (); $previous_keyword = '';
        }# say "==after: ", substr($$ref, 0 ,170);
    };
}

sub closing_brace_pos { # for parsing HASH and CODE
   my ($str, $bcc) = (shift, 0);
   my ($lpos, $rpos) = (index($$str,'{',0), index($$str,'}',0));
   while (1){
       if($bcc){ $rpos = index($$str,'}',$rpos+1);
                 if ($rpos == -1)                  {return -1} else {$bcc--}
       } else {  $lpos = index($$str,'{',$lpos+1);
                 if ($lpos == -1 or $lpos > $rpos) {return $rpos} else {$bcc++}
       }
   }
}
################################################################################
1;
