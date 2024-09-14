#!usr/bin/perl
use v5.12;
use warnings;

FindKephraLib->new->MainLoop;

package FindKephraLib;
use Cwd qw(abs_path);
use File::Spec;
use File::Find::Rule;
use FindBin qw($RealBin);
use Wx;
use base qw(Wx::App);

sub OnInit {
	my $app   = shift;
	my $frame = Wx::Frame->new( undef, -1, __PACKAGE__ , [-1,-1], [1000,800]);
	my $ed = Wx::TextCtrl->new($frame, -1, '',[-1,-1], [-1,-1], &Wx::wxTE_MULTILINE | &Wx::wxTE_READONLY);

	$frame->Show(1);
	$app->SetTopWindow($frame);

	my @dirs = File::Find::Rule->file->name('Kephra.pm')->in($ENV{'HOME'});
	$ed->AppendText( $_ . "\n") for @dirs;
	$ed->AppendText( "-----\n");
	for (@INC){
		my $file = File::Spec->catfile( $_, 'Kephra.pm' );
		$ed->AppendText( "$file\n") if -e $file;
	}

	
	1;
}
__END__

my @files;
my @ignore=(
  '/usr/bin/',
  '/home',
);
iterate_dirs(
  # entscheiden ob das Verzeichnis besucht werden soll
  sub{
   for(@ignore)
   { return 0 if( index($_[1],$_)==0 ); }
   return 1 if( -r $_[0] );
   return 0;
  },

  # Auswerten des Eintrags
  sub{
    push(@files, $_[1]) if( -f $_[0] and -r $_[0] and substr($_[0],-4,4) eq '.pod' );
  },

  # die zu durchsuchenden Verzeichnisse
  '/usr/lib/perl5'
);

print "$_\n" for( @files );

#################################

sub iterate_dirs {
  my ($decide_code, $each_code, @stack ) =@_ ;

  my $dir=getcwd;

  my ($p,$dh,$path,$tmp);
  while(@stack)
  {
    $path = pop(@stack);
    chdir( $path ) or die "chdir($path) failed: $!";;
    opendir( $dh, '.' ) or die "Unable to open $path: $!\n";
    for( readdir( $dh ) )
    {
      next if( $_ eq '.' or $_ eq '..' );
      $tmp=$path.'/'.$_;
      push(@stack, $tmp) if( -d $_ and $decide_code->( $_, $tmp ) );
      $each_code->( $_, $tmp );
    }
    closedir ($dh);
  }

  chdir ( $dir ) or die "chdir($dir) failed: $!\n";
  return 1;
}

use Cwd;

sub myfind {
    my $wd = shift;
    my @dirs = listdir($wd, "dirs", "fullname");
    foreach my $adir (@dirs) {
        print "$adir\n";
        # Printing files inside directories:
        my @fnames = listdir($adir, "all", "localname");
        foreach my $afile (@fnames) {
            print "$afile\n";
        }
        print "\n";
        myfind($adir);
    }
}

sub listdir {
    my $dir = shift;
    my $select = shift;
    my $basename = shift;
    my $filename;
    my @files;
    opendir(DIR, $dir) or die;
    while($filename = readdir(DIR)) {
        next if ($filename eq "." || $filename eq "..");
        my $fullfname = "$dir/$filename";
        next if ($select eq "dirs" && ! -d $fullfname);
        if ($basename eq "fullname") {
            push(@files, $fullfname);
        } else {
            push(@files, $filename);
        }
    }
    close(DIR);
    return @files;
}

myfind(getcwd());