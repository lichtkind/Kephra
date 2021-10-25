use v5.20;
use warnings;

# parsing signatures into data structure to build definition object from

package Kephra::Base::Class::Syntax::Signature;
our $VERSION = 1.0;

sub parse              {} #   ~sig       --> @params  = [=req, =opt, =ret, @@par] @par = [~name T 'kind' ~name? T]
sub split_args         {} #   ','        --> @@arg_parts
sub eval_special_syntax{} #   @arg_parts --> @arg_parts_|~type_name

1;

__END__

Syntax Schema:

 (req arg -- opt arg --> req ret val -- opt ret val)

   
Sig features:

    required/optional args         ,sep by --
    required/optional return val   ,right of -->
                                   
    arg names (required)           ,symboled by '...'
    optional arg/val types         ,before name, vals have just types 
    default value (optional only)  ,assign with =, after name
    foreward args (copy to attr)   ,name start with sigil =, same name as attr
    slurpy args   (zip into array) ,start with *, last arg

Type Names:
            
            simple    parametric      param is attr
-----------------------------------------------------            
    name      ...    array of str    index of attr
   shortcut   T...      @~...            I:attr


Calling Syntax:

   ->method( =arg1, array of int arg2, @+arg3 -- ?arg4 = 0, index of .msg i, *sargs --> ?)
   ->method({name => arg, })



.Class
T
I:attr 

cloned args ?