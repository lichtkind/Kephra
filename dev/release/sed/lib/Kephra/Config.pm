use v5.12;
use warnings;
use File::HomeDir;
use File::Spec;
use Kephra::Config::Default;
use YAML;

package Kephra::Config;

my $file = '.harmonograph';

sub new {
    my $self = {}; 
    bless $self;
    
    #~ for my $d ('.', File::HomeDir->my_home, File::HomeDir->my_documents){
        #~ my $path = File::Spec->catfile( $d, $file );
        #~ $dir = $d, last if -r $path;
    #~ }
    #~ my $data = $dir 
             #~ ? load( $pkg, File::Spec->catfile( $dir, $file ) )
             #~ : $default;
    #~ $dir ||= File::HomeDir->my_home;
    #~ bless { path => File::Spec->catfile( $dir, $file ), data => $data };


}

sub set {
}

sub get {
    
}


1;
