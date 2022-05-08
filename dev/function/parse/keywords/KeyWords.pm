use v5.16;
package KeyWords;
 
use Keyword::Simple;
 
sub import {
    Keyword::Simple::define 'burb', sub {
        my ($ref) = @_;   # burb is already removed
        substr($$ref, 0, 0) = 'say'; 
#        say $$ref;
    };
}
 
sub unimport {
    Keyword::Simple::undefine 'burb';
}
 
'ok'

__END__
