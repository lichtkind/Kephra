use v5.20;
use warnings;
use File::Find;
use File::Spec;

package CPutils;
our $VERSION = 0.2;
use Cwd;
use Exporter 'import';
our @EXPORT_OK = qw(has_status read_index list_subdir extract_version);


my $file_ending = 'cp.txt';

sub index_file { defined $_[0] ? File::Spec->catdir($_[0], 'index.'.$file_ending) : 'index.'.$file_ending}
sub status_file { defined $_[0] ? File::Spec->catdir($_[0], 'status.'.$file_ending) : 'status.'.$file_ending}

sub has_index { -e index_file($_[0]) }
sub has_status { -e status_file($_[0]) }


sub list_subdir {
    my $dir = shift;
    return if not $dir and -d $dir;
    my $curdir =  getcwd();
    chdir $dir;
    my @sd = grep { -d } <*>;
    chdir $curdir;
    @sd;
}


sub read_status {
    my $file = status_file(shift);

}

sub read_index {
    my $file = index_file(shift);
    return unless defined $file and -r $file;
    my @subs;
    open my $FH, '<', $file or die "could not open file $file: $!";
    my $sec_nr = 0;
    while (<$FH>){
       if (substr( $_, 0, 3) eq '---'){
           $sec_nr++;
           next;
       }
       last if $sec_nr == 3;
       next if $sec_nr < 2 or /^\s+/;
       /^(\w+)/;
       push @subs, $1;
    }
    @subs;

}

sub extract_version {
    my $file = shift;
    return unless defined $file and -r $file;
    open my $FH, '<', $file or die "could not open file $file: $!";
    while (<$FH>){
        return $1 if /^our \$VERSION\s*=\s*v?([0-9\.]+)/i;
    }
}


1;