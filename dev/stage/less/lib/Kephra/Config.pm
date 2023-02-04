use v5.12;
use warnings;

package Kephra::Config;

use File::HomeDir;
use File::Spec;
use YAML;

use Kephra::Config::Default;

my $file_name = File::Spec->catfile( File::HomeDir->my_home, '.config', 'kephra');

sub new {
    my $default = Kephra::Config::Default::get();
    my $data = {};
    if (-r $file_name){
        $data = (YAML::LoadFile( $file_name ))[0];
say $data;
say $data->{'session'};
        check( $data, $default);
    } else { $data = $default; }
    return bless {data => $data};
}

sub write {
    my ($self) = @_;
    YAML::DumpFile( $file_name, $self->{'data'} );
}

sub reload {
    my ($self) = @_;

}

sub set_value {
    my ($self, $value, @keys) = @_;
}

sub get_value {
    my ($self, @keys) = @_;
}


sub check {
    my ($data, $default) = @_;


}

1;
