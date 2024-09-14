#!/usr/bin/perl
use v5.12;
use warnings;

package proto;
use parent qw(Wx::App);
use File::Spec;
use Wx;
our $icon_directory = '/icon';

sub OnInit {
	my( $app ) = @_;
	my( $frame ) = Wx::Frame->new(undef, -1, "Kephra CP toolbar demo prototype ", [-1,-1], [500, 350 ] );
	Wx::InitAllImageHandlers();
	$frame->SetIcon( Wx::GetWxPerlIcon() );
	my $version_string = "WxPerl $Wx::VERSION ".&Wx::wxVERSION_STRING;
	my $ed = Wx::TextCtrl->new($frame, -1, "push any button\n",[-1,-1],[-1,-1], &Wx::wxTE_MULTILINE);
	my ($upid, $leftid, $downid) = (1000, 1100, 1200);

	my $textb = $frame->CreateToolBar(&Wx::wxTB_TEXT|&Wx::wxTB_NOICONS,-1); #$frame->SetToolBar( $tb );
	$textb->AddTool($upid++, 'Size',   &Wx::wxNullBitmap, 'toggle bar size');
	$textb->AddTool($upid++, 'Margin', &Wx::wxNullBitmap, 'toggle margin size');
	$textb->AddTool($upid++,'Seperate',&Wx::wxNullBitmap, 'toggle seperators');
	$textb->AddTool($upid++, 'Enable', &Wx::wxNullBitmap, 'CheckButton');
	$textb->AddTool($upid++, 'Check',  &Wx::wxNullBitmap, 'CheckButton'); #tool->Command()
	$textb->AddTool($upid++, 'Radio',  &Wx::wxNullBitmap, 'advance radio group');
	$textb->AddTool($upid++, 'Close',  &Wx::wxNullBitmap, 'Tip');

	my $img_button = DI_Toolbar->new({
		parent => $frame, ID_base => $leftid, checked => 1, radio_pos => 1, 
		orient => 'vertical', img_size => 32, margin => 0, separator => 1,
		img_file => [qw/application-blue application-resize-full application-dock-tab application-dock-180 application-dock-090 application-dock/],
	});

	my $ctrlb = Wx::ToolBar->new($frame,-1,[-1,-1],[-1,-1],  &Wx::wxTB_HORIZONTAL|&Wx::wxTB_HORZ_LAYOUT);
    my $combo = Wx::ComboBox->new($ctrlb, -1, 'text', [-1,-1],[220,22]);
    #$combo->
	$ctrlb->SetToolBitmapSize([16,16]);
	$ctrlb->AddControl(Wx::TextCtrl->new($ctrlb, -1, $version_string, [-1,-1],[220,22], &Wx::wxTE_READONLY));
	$ctrlb->AddControl( $combo );
	$ctrlb->Realize();

	Wx::Window::SetFocus($ed);
	my $vsizer = Wx::BoxSizer->new( &Wx::wxVERTICAL);
	$vsizer->Add($ed, 1, &Wx::wxGROW);
	$vsizer->Add($ctrlb, 0, &Wx::wxGROW);
	my $hsizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL);
	$hsizer->Add($img_button->{'bar'}, 0, &Wx::wxGROW);
	$hsizer->Add($vsizer, 1, &Wx::wxGROW);

	Wx::Event::EVT_TOOL($frame, 1000, sub{$img_button->recreate({img_size => $img_button->{'img_size'} == 16 ? 32 : 16}, 'retach') });
	Wx::Event::EVT_TOOL($frame, 1001, sub{$img_button->recreate({margin => $img_button->{'margin'} + 4}, 'retach') });
	Wx::Event::EVT_TOOL($frame, 1002, sub{$img_button->recreate({separator => !$img_button->{'separator'}}, 'retach') });
	Wx::Event::EVT_TOOL($frame, 1003, sub{$img_button->{'bar'}->EnableTool(1102, ! $img_button->{'bar'}->GetToolEnabled(1102))});
	Wx::Event::EVT_TOOL($frame, 1004, sub{$img_button->{'bar'}->ToggleTool(1102, ! $img_button->{'bar'}->GetToolState(1102))  });
	Wx::Event::EVT_TOOL($frame, 1005, sub{ 
		$img_button->{'bar'}->GetToolState(1103) ? $img_button->{'bar'}->ToggleTool(1104, 1) :
		$img_button->{'bar'}->GetToolState(1104) ? $img_button->{'bar'}->ToggleTool(1105, 1) :
		$img_button->{'bar'}->GetToolState(1105) ? $img_button->{'bar'}->ToggleTool(1103, 1) : 0;
	} );
	Wx::Event::EVT_TOOL($frame, 1006, sub{$frame->Close() } );
	Wx::Event::EVT_TOOL($frame, 1100, sub{$ed->AppendText("pushed normal tool button\n") });
	Wx::Event::EVT_TOOL($frame, 1102, sub{$ctrlb->Show( $img_button->{'checked'} = ! $img_button->{'checked'}); $vsizer->Layout() });
	Wx::Event::EVT_TOOL($frame, 1103, sub{$img_button->recreate({radio_pos => 1, orient => 'vertical'}, 'retach') });
	Wx::Event::EVT_TOOL($frame, 1104, sub{$img_button->recreate({radio_pos => 2, orient => 'horizontal'},'retach') });
	Wx::Event::EVT_TOOL($frame, 1105, sub{$img_button->recreate({radio_pos => 3, orient => 'vertical'}, 'retach') });

	$frame->SetSizer($hsizer);
	$frame->Centre( );
	$frame->Show( 1 );
	$app->SetTopWindow( $frame );
	1;
}


package DI_Toolbar;

sub new {
	my ($class, $para) = @_;
	die 'Toolbar needs inits parameters as a hashref 'unless ref $para eq 'HASH';
	my $self = bless $para;
	$self->recreate();
	return $self;
}

sub recreate {
	my $self = shift;
	my $para = shift;
	my $retach = shift;
	if (defined $para){
		die 'parameters need to be in a hashref 'unless ref $para eq 'HASH';
		for (keys %$para){ $self->{$_} = $para->{$_} if exists $self->{$_}}
		$self->{'radio_pos'} = 1 if $self->{'radio_pos'} > 3;
	}
	$self->detach() if $retach;
	$self->{'bar'}->Destroy() if defined $self->{'bar'} and ref $self->{'bar'};
	my $style = &Wx::wxNO_BORDER | &Wx::wxTB_FLAT;
	$style|= $self->{'orient'} eq 'horizontal' ? &Wx::wxTB_HORIZONTAL : &Wx::wxTB_VERTICAL;
	$self->{'bar'} = Wx::ToolBar->new($self->{'parent'}, -1,[-1,-1],[-1,-1], $style);
	$self->{'bar'}->SetToolBitmapSize( Wx::Size->new($self->{'img_size'}, $self->{'img_size'})); # &Wx::wxIMAGE_QUALITY_NORMAL
	$self->{'bar'}->SetMargins( $self->{'margin'}, $self->{'margin'});
	#$self->{'bar'}->SetToolSeparation( $self->{'separator'} );
	$self->{'running_ID'} = $self->{'ID_base'};
	$self->add_tool(0,  &Wx::wxITEM_NORMAL);
	$self->add_tool(1,  &Wx::wxITEM_NORMAL); #DROPDOWN
	$self->add_tool(2,  &Wx::wxITEM_CHECK); 
	$self->add_tool($_, &Wx::wxITEM_RADIO) for 3..5;
	if ($self->{'separator'})
		{$self->{'bar'}->InsertSeparator($_) for reverse 1 .. 3}
	$self->{'bar'}->ToggleTool($self->{'ID_base'} + 2, $self->{'checked'});
	$self->{'bar'}->ToggleTool($self->{'ID_base'} + 2 + $self->{'radio_pos'}, 1);
	$self->{'bar'}->Realize();
	$self->attach() if $retach;
	$self;
}

sub add_tool {
	my ($self, $img_nr, $type) = @_;
	my $img_file = $self->{'img_file'}[$img_nr];
	$self->{'bar'}->AddTool(
		$self->{'running_ID'}++, $img_file, 
		Wx::Bitmap->new(
			Wx::Image->new(
				File::Spec->catfile($proto::icon_directory, "$img_file.png"),
				&Wx::wxBITMAP_TYPE_PNG
			)->Scale($self->{'img_size'}, $self->{'img_size'}) 
		),
		&Wx::wxNullBitmap, $type, $img_file
	);
}

sub attach {
	my $self = shift;
	return unless $self->{'parent'}->GetSizer;
	my $hsizer = $self->{'parent'}->GetSizer;
	my $vsizer = $hsizer->GetItem(0)->IsSizer 
		? $hsizer->GetItem(0)->GetSizer 
		: $hsizer->GetItem(1)->GetSizer;
	if ($self->{'radio_pos'} == 1) {$hsizer->Prepend($self->{'bar'}, 0)}
	if ($self->{'radio_pos'} == 2) {$vsizer->Prepend($self->{'bar'}, 0)}
	if ($self->{'radio_pos'} == 3) {$hsizer->Add    ($self->{'bar'}, 0)}
	$hsizer->Layout();
}

sub detach {
	my $self = shift;
	$self->{'bar'}->GetContainingSizer()->Detach($self->{'bar'})
		if $self->{'bar'} and $self->{'bar'}->GetContainingSizer();
}

package main;
proto->new->MainLoop;
