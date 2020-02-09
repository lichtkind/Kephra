use v5.16;
package OOKeyWords;
 
use Keyword::Simple;
 
sub import {  # create keyword 'provided', expand it to 'if' at parse time
    Keyword::Simple::define 'class', sub {
        my ($ref) = @_;
        my $nr = substr($$ref, 3, 1);
        print "- code before: class$$ref|\n";
        substr($$ref, 3, 1) = '';
        substr($$ref, index($$ref, ';')+1, 0) = 'use parent qw(Base);';
        substr($$ref, 0, 0) = "sub before {$nr} package";
        chomp $$ref;
        print "= code after: $$ref|\n";
    };

    Keyword::Simple::define 'method', sub {
        my ($ref) = @_;
        print "- code before: method$$ref|\n";
        substr($$ref, 0, 0) = "sub";
        chomp $$ref;
        print "= code after: $$ref|\n";
    };
}
 
sub unimport { # lexically disable keyword again
    Keyword::Simple::undefine 'class';
}
 
'ok'
