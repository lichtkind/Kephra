use v5.12;
use warnings;

package Kephra::App::Splitter;
our @ISA = 'Wx::SplitterWindow';

use Scalar::Util qw(looks_like_number);
use Kephra::API qw(is_widget app_window);

sub new {
	my ($class, $parameter) = @_;
	my $parent;
	if (ref $parameter eq 'HASH') {$parent = $parameter->{'parent'} || app_window()}
	elsif (not defined $parameter){$parent = app_window()}
	elsif (is_widget($parameter)) {$parent = $parameter}
	else  { return Kephra::Log::error('need parent widget or parameter hash') }

	my $self = $class->SUPER::new($parent);

	Wx::Event::EVT_SPLITTER_DCLICK( $self, -1, sub { $_[1]->Veto} );
	Wx::Event::EVT_SPLITTER_SASH_POS_CHANGED( $self, -1, sub {
		$self->{'position'} = $self->GetSashPosition;
	} );

	$self->_eval_parameter($parameter) if ref $parameter eq 'HASH';
	$self;
}

sub _eval_parameter {
	my ($self, $parameter) = @_;
	# parameter: left=widget right=widget / top=widget bottom=widget (just one works too)
	#            dominant_child=1/2/left/right/top/bottom
	#            orientation=horizontal/vertical 
	#            gravity=0..1,left, right, top, bottom, equal 
	#            position=px size of child1
	#            split=yes/no/keep
	return Kephra::Log::error('need parameter as hash') unless ref $parameter eq 'HASH';
	return Kephra::Log::error('have no first child widget')
		unless is_widget( $parameter->{'top'} )
		or is_widget( $parameter->{'left'} ) or $self->{'child1'};
	return Kephra::Log::error('declare left/right or top/bottom children or none', 1) 
		unless (exists $parameter->{'top'} and not exists $parameter->{'left'} and not exists $parameter->{'right'})
		or (exists $parameter->{'left'} and not exists $parameter->{'top'} and not exists $parameter->{'bottom'})
		or (not exists $parameter->{'top'} and not exists $parameter->{'bottom'}
			and not exists $parameter->{'left'} and not exists $parameter->{'right'});

	$self->Reparent( $parameter->{'parent'} )
		if defined $parameter->{'parent'} and is_widget( $parameter->{'parent'} );

	$self->{'child1'} = $parameter->{'top'}   if exists $parameter->{'top'};
	$self->{'child2'} = $parameter->{'bottom'}if exists $parameter->{'bottom'};
	$self->{'child1'} = $parameter->{'left'}  if exists $parameter->{'left'};
	$self->{'child2'} = $parameter->{'right'} if exists $parameter->{'right'};

	$self->{'child1'}->Reparent($self) if $self->{'child1'};
	$self->{'child2'}->Reparent($self) if defined $self->{'child2'}
										and is_widget( $self->{'child2'} );


	$self->SetSplitMode( &Wx::wxSPLIT_HORIZONTAL )
		if exists $parameter->{'top'}
		or exists $parameter->{'orientation'} and $parameter->{'orientation'} eq 'horizontal';
	$self->SetSplitMode( &Wx::wxSPLIT_VERTICAL )
		if exists $parameter->{'left'}
		or exists $parameter->{'orientation'} and $parameter->{'orientation'} eq 'vertical';


	$self->{'dominant_child'} = exists $parameter->{'dominant_child'} 
		? $parameter->{'dominant_child'} : 1;
	$self->{'dominant_child'} = 1
		if $self->{'dominant_child'} eq 'left' or $self->{'dominant_child'} eq 'top';
	$self->{'dominant_child'} = 2
		if $self->{'dominant_child'} eq 'right' or $self->{'dominant_child'} eq 'bottom';
	$self->{'dominant_child'} = 1 if $self->{'dominant_child'} eq $self->{'child1'};
	$self->{'dominant_child'} = 2 if $self->{'child2'} and $self->{'dominant_child'} eq $self->{'child2'};
	$self->{'dominant_child'} = 1 
		unless $self->{'dominant_child'} eq 1 or $self->{'dominant_child'} eq 2;


	$self->{'position'} = 0 unless exists $self->{'position'};
	$self->{'position'} = $parameter->{'pos'}      if exists $parameter->{'pos'};
	$self->{'position'} = $parameter->{'position'} if exists $parameter->{'position'};


	$self->{'min_size'} = 70 unless exists $self->{'min_size'};
	$self->{'min_size'} = $parameter->{'min'}      if exists $parameter->{'min'};
	$self->{'min_size'} = $parameter->{'min_size'} if exists $parameter->{'min_size'};
	$self->SetMinimumPaneSize( $self->{'min_size'} );


	$self->{'gravity'} = $parameter->{'gravity'} if exists $parameter->{'gravity'};
	if (not exists $self->{'gravity'} and exists $parameter->{'dominant_child'}){
		$self->{'gravity'} = $self->{'dominant_child'} == 1 ? 1 : 0;
	}
	$self->{'gravity'} = 0.5 unless exists $self->{'gravity'};
	$self->{'gravity'} = 0.5 if $self->{'gravity'} eq 'equal';
	$self->{'gravity'} = 1 if $self->{'gravity'} eq 'top' or $self->{'gravity'} eq 'left';
	$self->{'gravity'} = 0 if $self->{'gravity'} eq 'bottom' or $self->{'gravity'} eq 'right';
	$self->SetSashGravity( $self->{'gravity'} ); # 1 is left/top - 0 is right/bottom

	return if defined $parameter->{'split'} and $parameter->{'split'} eq 'keep';
	return $self->unsplit()
		if not exists $self->{'child1'} or not $self->{'child1'}
		or not exists $self->{'child2'} or not $self->{'child2'}
		or exists $parameter->{'split'} and $parameter->{'split'} eq 'no';


	if ($self->{'child2'}) { $self->resplit()                       }
	else                   { $self->Initialize( $self->{'child1'} ) }
}

# call only if children or other property changes
sub set {
	my ($self, $parameter) = @_;
	$self->_eval_parameter( $parameter );
}

sub get {
	my ($self, $parameter) = @_;
	return unless $parameter and not ref $parameter;
	if ($parameter eq 'dominant_child'){
		if ($self->GetSplitMode() == &Wx::wxSPLIT_HORIZONTAL){
			return $self->{'dominant_child'} == 1 ? 'top' : 'bottom';
		}
		else {
			return $self->{'dominant_child'} == 1 ? 'left' : 'right';
		}
	}
}

sub resize {
	my ($self, $pos) = @_;
	return unless defined $pos;
	$pos = 0.5 if $pos eq 'equal';
	return unless looks_like_number($pos);

	# negative sizes are counted from right border
	# sizes between -1 and 1 are percentages of splitter size
	if ($pos <= 1 and $pos > -1){
		my $size = $self->GetSize;
		if ($self->GetSplitMode eq &Wx::wxSPLIT_HORIZONTAL){
			$self->SetSashPosition( $size->GetHeight * $pos, 1);
		} 
		elsif ($self->GetSplitMode eq &Wx::wxSPLIT_VERTICAL) {
			#say "resize $pos ",$size->GetHeight;
			$self->SetSashPosition( $size->GetWidth * $pos, 1);
		} 
		else { return; }
	} 
	else { $self->SetSashPosition($pos, 1) }

	$self->{'position'} = $self->GetSashPosition;
	$self;
}

sub resplit {
	my $self = shift;
	return if $self->IsSplit;
	return Kephra::Log::error("need at least one child", 0) unless $self->{'child1'};
	return Kephra::Log::warning("need a second child", 0) unless $self->{'child2'};
	if ($self->GetSplitMode eq &Wx::wxSPLIT_HORIZONTAL){
		$self->SplitHorizontally( $self->{'child1'}, $self->{'child2'}, $self->{'position'} )
	} else { 
		$self->SplitVertically( $self->{'child1'}, $self->{'child2'}, $self->{'position'} )
	}
}

sub unsplit {
	my $self = shift;
	$self->{'position'} = $self->GetSashPosition;
	$self->Unsplit if $self->IsSplit;
	return Kephra::Log::error("can't initialize with a not existing child widget")
		if $self->{'dominant_child'} == 1 and not $self->{'child1'}
		or $self->{'dominant_child'} == 2 and not $self->{'child2'};
	$self->Initialize( $self->{'child1'} ) if $self->{'dominant_child'} == 1;
	$self->Initialize( $self->{'child2'} ) if $self->{'dominant_child'} == 2;
	#Kephra::App::Focus::stay();
}

sub toggle_split {
	my $self = shift;
	$self->IsSplit ? $self->unsplit : $self->resplit;
}


# drop in if proper logging is missing
*{Kephra::Log::error} = sub {say ((caller 1)[3],': ', @_)} unless defined *{Kephra::Log::error}{CODE};

1;
