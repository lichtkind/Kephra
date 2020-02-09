use v5.16;
use warnings;
use experimental qw/smartmatch/;
use Cwd;
use File::Find;
use File::Spec;

# smoketest on all protos

my @stopdir = qw/Kephra lib bin doc data t/;
my $scriptdir = (File::Spec->splitpath(__FILE__))[1];
chdir $scriptdir if $scriptdir;
$scriptdir = cwd();

list_protos($_) for all_subdir('.');

sub all_subdir {
    my $dir = shift;
    return if not $dir and -d $dir;
    my $curdir =  cwd();
    chdir $dir;
    my @sd;
    for (<*>) {
        push @sd, $_ if -d;
    }
    chdir $curdir;
    return @sd;
}

sub list_protos {
    my $dir = shift;
    return if not $dir or not -d $dir;
    chdir $dir;
    say "$dir:";
    if ($dir eq 'function'){
       chdir 'bin';
       for my $funcdir (all_subdir('.')) {
            say "    $_" for <$funcdir/*.pl>;
       }
    } else {
        for (<*>) {
            next if $_ ~~  @stopdir;
            say "    $_" if -d;
        }
    }
    chdir $scriptdir;
}

sub subdir_map {
    my ($dir, $f) = @_;
    return if not $dir or not -d $dir or ref $f ne 'CODE';
}
