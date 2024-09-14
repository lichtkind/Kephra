use v5.12;
use English;
use Cwd;
use File::Spec;
use File::HomeDir;
use File::ShareDir ':ALL';

say "cwd: ", Cwd::cwd();
say "now in Dir: ", File::Spec->curdir();
say "this file is in Dir: ", (File::Spec->splitpath(__FILE__))[1];
say "home_dir: \t", File::HomeDir->my_home;
say "home_data: \t", File::HomeDir->my_data;
say "home_data_kephra: \t", File::HomeDir->my_dist_data('Kephra');
say "home_config: \t", File::HomeDir->my_dist_config('Kephra');
say "dist_dir: \t", dist_dir('Kephra');
#say "module_dir: \t", module_dir('Kephra');