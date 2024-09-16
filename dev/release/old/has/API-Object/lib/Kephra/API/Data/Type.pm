use v5.14;
use warnings;

package Kephra::API::Data::Type;
our $VERSION = 0.1;
use Scalar::Util qw/blessed looks_like_number/;
use Exporter 'import';

our @test = qw/is_bool is_num is_pos_num is_int is_pos_int is_ne_string is_uc_string is_lc_string
               is_object is_call is_dynacall is_template is_dynatemplate
               is_widget is_panel is_sizer is_color is_font/;

our @EXPORT_OK = (@test, qw/blessed verify get_ref_type get_data_type/);
our %EXPORT_TAGS = (test => [@test], all => [@EXPORT_OK]);

our %check = (num => \&is_num,  'num+' => \&is_pos_num, int => \&is_int, 'int+' => \&is_pos_int,
        uc_string => \&is_uc_string, lc_string => \&is_lc_string,  string => \&is_string, 'string+' => \&is_ne_string);
our @name = keys %check;

################################################################################

sub get_ref_type {  #   val          --> class ref
    my ($val) = @_;
    return ('','') unless ref $val;
    my ($class, $ref);
    if ($class = blessed($val) || '') {
        $ref = "$val";
        $ref = substr $ref, 1 + length($class), index($ref, '(' ) - length($class) - 1;
    } else {
        $ref = ref $val;
    }
    ($class, $ref);
}

sub get_data_type { #   val          --> type
    my ($val) = @_;
    return 'undef' unless defined $val;
    return 'ref' if ref $val;
    if (looks_like_number($val)){
        if (int $val == $val)  { return $val >= 0 ? 'int+' : 'int' }
        else                   { return $val >= 0 ? 'num+' : 'num' }
    } else {
        return is_uc_string($val) ? 'uc_string' :
               is_lc_string($val) ? 'lc_string' : 'string';
    }
}


sub verify        { #   val type ref --> bool
    my ($val, $type, $ref, @defs) = @_;
    return unless defined $type;
    if (defined $ref and $ref){
        return 0 unless $ref eq ref $val;        # ref type doesnt fit
        return 1 unless defined $type and $type; # good because no data to check
        return 0 unless $check{$type};           # unknown data type
        if ($ref eq 'ARRAY'){
            for (@$val)       { return 0 if ref $_ or not $check{$type}->($_) }
        } elsif ($ref eq 'HASH'){
            for (values %$val){ return 0 if ref $_ or not $check{$type}->($_) }
        }
        return 1;
    } else {
        return ref $val ? 0 : $check{$type} ? $check{$type}->($val) : 0;
    }
}

################################################################################

sub is_bool        {(defined($_[0]) and ($_[0] eq 0 or $_[0] eq 1))               ? 1 : 0}
sub is_num         { looks_like_number($_[0])                                     ? 1 : 0}
sub is_pos_num     {(looks_like_number($_[0]) and $_[0] >= 0)                     ? 1 : 0}
sub is_int         {(defined($_[0]) and int $_[0] == $_[0])                       ? 1 : 0}
sub is_pos_int     {(defined($_[0]) and abs(int($_[0])) == $_[0])                 ? 1 : 0}
sub is_string      { defined($_[0])                                               ? 1 : 0}
sub is_ne_string   {(defined($_[0]) and $_[0])                                    ? 1 : 0}
sub is_uc_string   {(defined($_[0]) and uc $_[0] eq $_[0])                        ? 1 : 0}
sub is_lc_string   {(defined($_[0]) and lc $_[0] eq $_[0])                        ? 1 : 0}

sub is_object      { blessed($_[0])                                               ? 1 : 0}
sub is_call        {(blessed($_[0]) and $_[0]->isa('Kephra::API::Call')         ) ? 1 : 0}
sub is_dynacall    {(blessed($_[0]) and $_[0]->isa('Kephra::API::Call::Dynamic')) ? 1 : 0}
sub is_template    {(blessed($_[0]) and $_[0]->isa('Kephra::API::Call::Template'))? 1 : 0}
sub is_dynatemplate{(blessed($_[0]) and $_[0]->isa('Kephra::API::Call::Dynamic::Template'))? 1 : 0}
sub is_widget      {(blessed($_[0]) and $_[0]->isa('Wx::Window')                ) ? 1 : 0}
sub is_panel       {(blessed($_[0]) and $_[0]->isa('Wx::Panel')                 ) ? 1 : 0}
sub is_sizer       {(blessed($_[0]) and $_[0]->isa('Wx::Sizer')                 ) ? 1 : 0}
sub is_color       {(blessed($_[0]) and $_[0]->isa('Wx::Colour') and $_[0]->IsOk) ? 1 : 0}
sub is_font        {(blessed($_[0]) and $_[0]->isa('Wx::Font') and $_[0]->IsOk  ) ? 1 : 0}

################################################################################

1;
