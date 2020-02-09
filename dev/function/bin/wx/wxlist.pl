#!/usr/bin/perl
use v5.12;
use warnings;

use strict;
proto->new->MainLoop;

package proto;
use parent qw(Wx::App);
use Wx;
use Wx::STC;

sub OnInit {
	my( $app ) = @_;
	my( $frame ) = Wx::Frame->new(undef, -1, "Kephra CP proto", [-1,-1], [450, 350 ] );
	$frame->SetIcon( Wx::GetWxPerlIcon() );
	my $ed = Wx::TextCtrl->new($frame, -1,'',[-1,-1],[-1,-1], &Wx::wxTE_MULTILINE);
	my $list = Wx::ListCtrl->new($frame, -1, [-1,-1],[-1,-1], &Wx::wxLC_SMALL_ICON);
	my $item = Wx::ListItem->new();
	$item->SetText('yes');
	$list->InsertItem( $item );
	$item->SetText('no');
	$list->InsertItem( $item );
	Wx::Window::SetFocus($ed);

	Wx::Event::EVT_LIST_ITEM_ACTIVATED($list, -1, sub {
		my ($list, $event) = @_;
		
		$ed->AppendText('-'.$event->GetLabel())
	});

	my $sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL);
	$sizer->Add($ed, 1, &Wx::wxGROW);
	$sizer->Add($list, 0, &Wx::wxGROW);
	$frame->SetSizer($sizer);
	$frame->Centre( );
	$frame->Show( 1 );
	$app->SetTopWindow( $frame );
  1;
}

