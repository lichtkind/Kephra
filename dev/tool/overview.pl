use v5.20;
use warnings;
use lib 'lib';

use Cwd;
use File::Find;
use File::Spec;
use FindBin qw($Bin);

BEGIN { chdir $Bin }
use CPutils qw/has_status list_subdir read_index/;

my $name = 'Kephra CP';


chdir '..';

my @stages = read_index('stage');
say " = $name stages";
say "   - $_" for @stages;
say '';

say " = $name modules";
for my $mod_dir (list_subdir('module')){
    say "   - $mod_dir";
    for my $md (list_subdir(File::Spec->catdir('module', $mod_dir))){
        say "       - $md" if has_status($md);
    }
}
say '';

say " = $name features";
say "   - $_" for list_subdir('feature');
say '';

say " = $name functions";
say "   - $_" for list_subdir('function');
say '';


# File::Spec->catdir($Bin, 
#my @dir = list_subdir ('.');
