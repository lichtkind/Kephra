#!usr/bin/perl
use v5.12;
use warnings;

InlineXPM->new->MainLoop;

package InlineXPM;
use Wx;
use base qw(Wx::App);

sub OnInit {
        my $app   = shift;
        my $frame = Wx::Frame->new( undef, -1, __PACKAGE__, [-1,-1], [1000,800]);
        Wx::InitAllImageHandlers();
        my $file = '../data/proton.xpm';
        open my $FH, '<', $file; 
        binmode($FH);
        my @xpmfile = <$FH>;
        @xpmfile = map { s/\r|\n|"|,//g; $_} @xpmfile;
        shift @xpmfile;
        shift @xpmfile;
        my @xpmdata = <DATA>;
        @xpmdata = map { s/\r|\n//g; $_} @xpmdata;
        my $xpmhere = <<'EOB';
32 32 5 1
        c None
.       c #808080
+       c #FFFFFF
@       c #000000
#       c #000080
................................
................................
..++++++++++++++++++++++++++++@.
..++++++++++++++++++++++++++++@.
..++++++++++++++++++++++++++++@.
..++++++++++++++++++++++++++++@.
..+++#################++++++++@.
..+++#################++++++++@.
..++++++++++++++++++++++++++++@.
..++++++++++++++++++++++++++++@.
..+++###################++++++@.
..+++###################++++++@.
..++++++++++++++++++++++++++++@.
..++++++++++++++++++++++++++++@.
..+++###############++++++++++@.
..+++###############++++++++++@.
..++++++++++++++++++++++++++++@.
..++++++++++++++++++++++++++++@.
..+++###################++++++@.
..+++###################++++++@.
..++++++++++++++++++++++++++++@.
..++++++++++++++++++++++++++++@.
..+++################+++++++++@.
..+++################+++++++++@.
..++++++++++++++++++++++++++++@.
..++++++++++++++++++++++++++++@.
..+++##################+++++++@.
..+++##################+++++++@.
..++++++++++++++++++++++++++++@.
..++++++++++++++++++++++++++++@.
..@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.
................................
EOB

        my @bitmap;
        push @bitmap, Wx::Bitmap->newFromXPM( \@xpmfile ),
                      Wx::Bitmap->newFromXPM( \@xpmdata ),
                      Wx::Bitmap->newFromXPM( [split("\r|\n", $xpmhere)] );
        #my $bitmap = Wx::Bitmap->new($file, &Wx::wxBITMAP_TYPE_XPM);
        my $ed = Wx::TextCtrl->new($frame, -1,'',[-1,-1],[-1,-1],&Wx::wxTE_MULTILINE);
        #$ed->AppendText($_) for @xpmdata;
        $ed->AppendText($xpmhere) ;

        my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
        $sizer->Add(Wx::StaticText->new($frame, -1, 'Icons from 1.) filtered file data 2.) __DATA__ section 3.)  Heredoc:'), 0);
        $sizer->Add(Wx::StaticBitmap->new($frame, -1, $bitmap[$_]), 0) for 0..2;
        $sizer->Add($ed, 1, &Wx::wxGROW);
        $frame->SetSizer($sizer);
        $frame->Show(1);
        $app->SetTopWindow($frame);
        1;
}

__DATA__
32 32 5 1
        c None
.       c #808080
+       c #FFFFFF
@       c #000000
#       c #000080
................................
................................
..++++++++++++++++++++++++++++@.
..++++++++++++++++++++++++++++@.
..++++++++++++++++++++++++++++@.
..++++++++++++++++++++++++++++@.
..+++#################++++++++@.
..+++#################++++++++@.
..++++++++++++++++++++++++++++@.
..++++++++++++++++++++++++++++@.
..+++###################++++++@.
..+++###################++++++@.
..++++++++++++++++++++++++++++@.
..++++++++++++++++++++++++++++@.
..+++###############++++++++++@.
..+++###############++++++++++@.
..++++++++++++++++++++++++++++@.
..++++++++++++++++++++++++++++@.
..+++###################++++++@.
..+++###################++++++@.
..++++++++++++++++++++++++++++@.
..++++++++++++++++++++++++++++@.
..+++################+++++++++@.
..+++################+++++++++@.
..++++++++++++++++++++++++++++@.
..++++++++++++++++++++++++++++@.
..+++##################+++++++@.
..+++##################+++++++@.
..++++++++++++++++++++++++++++@.
..++++++++++++++++++++++++++++@.
..@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.
................................