#!/usr/bin/perl
use v5.12;
use Wx;
use Wx::AUI;


package MyApp;
use vars qw(@ISA); @ISA=qw(Wx::App);

sub OnInit {
	my( $this ) = @_;
	my( $frame ) = Wx::Frame->new(undef, -1, "Docbar Prototype", [-1,-1], [450, 350 ] );
	my $bar = Wx::AuiNotebook->new($frame, -1, [-1,-1], [-1,-1],
		&Wx::wxAUI_NB_TOP | &Wx::wxAUI_NB_TAB_MOVE | &Wx::wxAUI_NB_WINDOWLIST_BUTTON |
		&Wx::wxAUI_NB_SCROLL_BUTTONS | &Wx::wxAUI_NB_CLOSE_ON_ACTIVE_TAB
	);
	$bar->InsertPage( 1, Wx::Panel->new($bar), 'title 1', 1);
	$bar->InsertPage( 1, Wx::Panel->new($bar), 'title 3', 1);
	$bar->InsertPage( 1, Wx::Panel->new($bar), 'title 2', 1);
	#$bar->AdvanceSelection
	Wx::Event::EVT_LEFT_DOWN( $frame, sub {
		say "click " ;
	});
	Wx::Event::EVT_AUINOTEBOOK_DRAG_MOTION( $bar, $bar, sub {
		my ($bar, $event ) = @_;
		say "draging ", $event->GetSelection;
	});
	Wx::Event::EVT_AUINOTEBOOK_BEGIN_DRAG( $bar, $bar, sub {
		my ($bar, $event ) = @_;
		say "start drag ", $event->GetSelection;
	});
	Wx::Event::EVT_AUINOTEBOOK_END_DRAG($bar, $bar, sub {
		my ($bar, $event ) = @_;
		say "end drag ", $event->GetSelection;
	});
	Wx::Event::EVT_AUINOTEBOOK_DRAG_DONE($bar, $bar, sub {
		my ($bar, $event ) = @_;
		say "drag done ", $event->GetSelection;
	});
	Wx::Event::EVT_AUINOTEBOOK_PAGE_CHANGING( $bar, $bar, sub{
		my ($bar, $event ) = @_; 
		say "changing ",$event->GetSelection;
	});
	Wx::Event::EVT_AUINOTEBOOK_PAGE_CHANGED( $bar, $bar, sub{
		my ($bar, $event ) = @_; 
		say "changed ",$event->GetSelection;
	});
	Wx::Event::EVT_AUINOTEBOOK_PAGE_CLOSE( $bar, $bar,  sub {
		my ($bar, $event ) = @_; 
		say "pgclose";
		$event->Skip();
	});

	$frame->SetIcon( Wx::GetWxPerlIcon() );
	$frame->Centre( );

	$this->SetTopWindow( $frame );
	$frame->Show( 1 );
	1;
}

sub OnQuit {
    my( $this, $event ) = @_;
    $this->Close( 1 );
}


package main;
MyApp->new->MainLoop;

__END__
keep keyboard order after DND