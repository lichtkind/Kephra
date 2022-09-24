use v5.12;
use warnings;

package Kephra::App::Window;
use base qw(Wx::Frame);

use Kephra::App::Dialog;
use Kephra::App::Editor;
use Kephra::App::SearchBar;
use Kephra::App::ReplaceBar;
use Kephra::IO::LocalFile;
our $VERSION = 0.51;

sub new {
    my($class, $parent) = @_;
    my $self = $class->SUPER::new( undef, -1, '', [-1,-1], [1000,800] );
    $self->CreateStatusBar(3);
    $self->SetStatusWidths(100, 50, -1);
    $self->SetStatusBarPane(2);
    
    $self->{'ed'} = Kephra::App::Editor->new($self, -1);
    $self->{'sb'} = Kephra::App::SearchBar->new($self, -1);
    $self->{'rb'} = Kephra::App::ReplaceBar->new($self, -1);
    
    my $sizer = Wx::BoxSizer->new( &Wx::wxVERTICAL );
    $sizer->Add( $self->{'ed'}, 1, &Wx::wxEXPAND, 0);
    $sizer->Add( $self->{'sb'}, 0, &Wx::wxGROW, 0);
    $sizer->Add( $self->{'rb'}, 0, &Wx::wxGROW, 0);

    $self->SetSizer($sizer);

    Wx::Window::SetFocus( $self->{'ed'} );
    Wx::Event::EVT_CLOSE( $self, sub {
        my ($self, $event) = @_;
        if ($self->{'ed'}->GetModify()){
            my $ret = Kephra::App::Dialog::yes_no_cancel( "\n".' save file ?  ');
            return                   if $ret ==  &Wx::wxCANCEL;
            $self->{'ed'}->save_file if $ret ==  &Wx::wxYES;
        }
        $event->Skip(1) 
    });

    Wx::Event::EVT_CLOSE( $self,       sub { $_[1]->Skip(1) });
    Wx::Event::EVT_MENU( $self, 11100, sub { $self->new_file });
    Wx::Event::EVT_MENU( $self, 11200, sub { $self->open_file });
    Wx::Event::EVT_MENU( $self, 11300, sub { $self->reopen_file });
    Wx::Event::EVT_MENU( $self, 11400, sub { $self->save_file });
    Wx::Event::EVT_MENU( $self, 11500, sub { $self->save_as_file });
    Wx::Event::EVT_MENU( $self, 11900, sub { $self->Close });
    Wx::Event::EVT_MENU( $self, 12100, sub { $self->{'ed'}->Undo });
    Wx::Event::EVT_MENU( $self, 12110, sub { $self->{'ed'}->Redo });
    Wx::Event::EVT_MENU( $self, 12200, sub { $self->{'ed'}->cut });
    Wx::Event::EVT_MENU( $self, 12210, sub { $self->{'ed'}->copy });
    Wx::Event::EVT_MENU( $self, 12220, sub { $self->{'ed'}->Paste });
    Wx::Event::EVT_MENU( $self, 12230, sub { $self->{'ed'}->replace });
    Wx::Event::EVT_MENU( $self, 12240, sub { $self->{'ed'}->Clear });
    Wx::Event::EVT_MENU( $self, 12300, sub { $self->{'ed'}->SelectAll });
    Wx::Event::EVT_MENU( $self, 12400, sub { $self->{'ed'}->toggle_block_comment() });
    Wx::Event::EVT_MENU( $self, 12410, sub { $self->{'ed'}->toggle_comment() });
    Wx::Event::EVT_MENU( $self, 13110, sub { $self->{'sb'}->enter });
    Wx::Event::EVT_MENU( $self, 13120, sub { $self->{'sb'}->find_prev });
    Wx::Event::EVT_MENU( $self, 13130, sub { $self->{'sb'}->find_next });
    Wx::Event::EVT_MENU( $self, 13210, sub { $self->{'rb'}->enter });
    Wx::Event::EVT_MENU( $self, 13220, sub { $self->{'rb'}->replace_prev });
    Wx::Event::EVT_MENU( $self, 13230, sub { $self->{'rb'}->replace_next });
    Wx::Event::EVT_MENU( $self, 13300, sub { $self->{'ed'}->goto_last_edit });

    my $file_menu = Wx::Menu->new();
    $file_menu->Append( 11100, "&New\tCtrl+N", "complete a sketch drawing" );
    $file_menu->AppendSeparator();
    $file_menu->Append( 11200, "&Open\tCtrl+O", "save currently displayed image" );
    $file_menu->Append( 11300, "&Reload\tCtrl+Shift+O", "save currently displayed image" );
    $file_menu->AppendSeparator();
    $file_menu->Append( 11400, "&Save\tCtrl+S", "save currently displayed image" );
    $file_menu->Append( 11500, "&Save As\tCtrl+Shift+S", "save currently displayed image" );
    $file_menu->AppendSeparator();
    $file_menu->Append( 11900, "&Quit\tCtrl+Q", "close program" );
    
    my $edit_menu = Wx::Menu->new();
    $edit_menu->Append( 12100, "&Undo\tCtrl+Z",       "undo last text change" );
    $edit_menu->Append( 12110, "&Redo\tCtrl+Y",       "undo last undo" );
    $edit_menu->AppendSeparator();                    
    $edit_menu->Append( 12200, "&Cut\tCtrl+X",        "delete selected text and move it into clipboard" );
    $edit_menu->Append( 12210, "&Copy\tCtrl+C",       "move selected text into clipboard" );
    $edit_menu->Append( 12220, "&Paste\tCtrl+V",      "insert clipboard content at cursor position" );
    $edit_menu->Append( 12230, "&Swap\tCtrl+Shift+V", "replace selected text with clipboard content" );
    $edit_menu->Append( 12240, "&Delete\tDel",        "delete selected text" );
    $edit_menu->AppendSeparator();
    $edit_menu->Append( 12300, "&Select All\tCtrl+A", "select entire text" );
    $edit_menu->Append( 12310, "&Double\tCtrl+D",     "copy and paste selected text or current line" );
    $edit_menu->AppendSeparator();
    $edit_menu->Append( 12400, "&Toggle Block Comment\tCtrl+K", "insert or remove script comment with #~" );
    $edit_menu->Append( 12410, "&Toggle Comment\tCtrl+Shift+K", "insert or remove script comment with #" );

    my $search_menu = Wx::Menu->new();
    $search_menu->Append( 13110, "&Find\tCtrl+F",            "enter search phrase into search bar" );
    $search_menu->Append( 13120, "&Find Prev\tCtrl+Shift+G", "jump to previous match of search term" );
    $search_menu->Append( 13130, "&Find Next\tCtrl+G",       "jump to next match of search text" );
    $search_menu->AppendSeparator();
    $search_menu->Append( 13210, "&Replace\tCtrl+Shift+F",            "enter replace term into replace bar" );
    $search_menu->Append( 13220, "&Replace Prev\tCtrl+Shift+H", "replace selection and go to previous match" );
    $search_menu->Append( 13230, "&Replace Next\tCtrl+H",       "replace selection and go to next match" );
    $search_menu->AppendSeparator();
    $search_menu->Append( 13300, "&Goto Edit\tCtrl+E", "move cursor position of last change" );
    
    my $help_menu = Wx::Menu->new();
    $help_menu->Append( 14100, "&Usage\tAlt+U",  "Dialog with information usage" );
    $help_menu->Append( 14200, "&About\tAlt+A",  "Dialog with some general information" );

    my $menu_bar = Wx::MenuBar->new();
    $menu_bar->Append( $file_menu,   '&File' );
    $menu_bar->Append( $edit_menu,   '&Edit' );
    $menu_bar->Append( $search_menu, '&Search' );
    $menu_bar->Append( $help_menu,   '&Help' );
    $self->SetMenuBar($menu_bar);
    $self->set_title();
    $self->{'rb'}->show(0);
    
    $self->read_file( __FILE__);
    
    return $self;
}


sub new_file { 
    my $self = shift;
    $self->{'file'} = '';
    $self->{'ed'}->new_text( '' );
    $self->{'encoding'} = 'utf-8';
    $self->set_title();
    $self->SetStatusText(  $self->{'encoding'}, 1);
}

sub open_file   { $_[0]->read_file( Kephra::App::Dialog::get_file_open() ) }

sub reopen_file { $_[0]->read_file( $_[0]->{'file'}, 1) }

sub read_file {
    my ($self, $file, $soft) = @_;
    return unless defined $file and -r $file;
    my ($content, $encoding) = Kephra::IO::LocalFile::read( $file );
    $self->{'encoding'} = $encoding;
    $self->{'ed'}->new_text( $content, $soft );
    $self->{'file'} = $file;
    $self->set_title();
    $self->SetStatusText(  $self->{'encoding'}, 1);
}

sub save_file {
    my $self = shift;
    $self->{'file'} = Kephra::App::Dialog::get_file_save() unless $self->{'file'};
    Kephra::IO::LocalFile::write( $self->{'file'},  $self->{'encoding'}, $self->{'ed'}->GetText() );
    $self->{'ed'}->SetSavePoint;
}

sub save_as_file {
    my $self = shift;
    $self->{'file'} = Kephra::App::Dialog::get_file_save();
    $self->save_file;
}


sub set_title {
    my ($self) = @_;
    my $title = "Kephra $VERSION  -  ";
    $title .=  $self->{'file'} ? $self->{'file'} : '<unnamed>';
    $title .= ' *' if $self->{'ed'}->GetModify();
    $self->SetTitle($title);
}

1;
