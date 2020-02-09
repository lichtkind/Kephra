use v5.12;
use warnings;

package Kephra::App::Sizer;

use Scalar::Util qw(looks_like_number);
use Kephra::API qw(is_widget is_sizer :log);
my %default = (orient => 'HORIZONTAL' );

sub new {
	my $class = shift;
	my $orient = shift || $default{'orient'};

	if    (lc substr($orient, 0, 1) eq 'v') { $orient = &Wx::wxVERTICAL }
	elsif (lc substr($orient, 0, 1) eq 'h') { $orient = &Wx::wxHORIZONTAL }

	else {
		return Kephra::Log::error
			("need h|horizontal or v|vertical as first parameter, not $orient", 1)
	}
	my $self = bless {
		'sizer'       => Wx::BoxSizer->new( $orient ),
		'child_sizer' => [] 
	}, $class;
	$self->append(@_);
	$self;
}

sub bare_sizer      { shift->{'sizer'} }
sub _bare_sizer     { shift->{'sizer'} }
sub child_sizer     { @{ shift->{'child_sizer'} } }

# syntax sugar for insert method, unless insert can take list of child items
# all these methods are ment to be chained, thatswhy the $self at the end
sub prepend         { shift->insert(  0, 0, @_ ) }
sub append          { shift->insert( -1, 0, @_ ) }
sub append_expanded { shift->insert( -1, 1, @_ ) }
sub insert_before   {
	my ($self) = shift;
	my ($mark_child) = shift;
	my $pos = $self->get_position($mark_child);
	return Kephra::Log::error("bookmark child $mark_child not found", 1) unless $pos > -1;
	$self->insert($pos, 0, @_);
}
sub insert_after   {
	my ($self) = shift;
	my ($mark_child) = shift;
	my $pos = $self->get_position($mark_child);
	return Kephra::Log::error("bookmark child $mark_child not found", 1) unless $pos > -1;
	$self->insert($pos+1, 0, @_);
}
sub insert          {
	my ($self) = shift;
	my ($position) = shift;
	my ($proportion)  = shift;
	for (@_) {
		$self->_insert( $self->_build_item($position, $proportion, $_) );
		$position++ unless $position == -1;
	}
	$self->bare_sizer->Layout;
	$self;
}

# accepted items : 
# - arrayref: sizer with crossing orientation holding the list of items in the array
# - widget: add widget without proportion
# - widgetref: add with proportion
# - int: spacer
# - intref: stretchspacer
sub _build_item {
	my ($self, $position, $proportion, $child) = @_;
	my $refcount;
	while (ref $child eq 'REF'){ $refcount++; $child = $$child; }

	if (ref $child eq 'ARRAY'){
		my $orient = $self->bare_sizer->GetOrientation;
		my $child_orient = 
			$refcount % 2                ? $orient
		  : $orient == &Wx::wxHORIZONTAL ? &Wx::wxVERTICAL
		  :                                &Wx::wxHORIZONTAL;
		my @subsizer_children = @$child;
		$child = __PACKAGE__->new( $child_orient, @subsizer_children );
	}

	my %item;
	if    (is_widget($child) or is_sizer($child))             { $item{'child'} = $child }
	elsif (looks_like_number($child) and int $child == $child){ $item{'child'} = 'space'}
	elsif (ref $child eq 'HASH'){ %item = %$child }           # already assembled
	else  { return Kephra::Log::error("got no proper widget, but $child", 2) }

	$item{'position'} = $position;
	$item{'proportion'} = $proportion if $proportion;
	$item{'proportion'} += $refcount if $refcount;

	my %presets = (
		position => -1, proportion => 0, style => &Wx::wxGROW, border => 0,
	);
	# fill with default settings (presets)
	for (qw/position proportion style border/)
		{ $item{$_} = $presets{$_} unless exists $item{$_} }
	$item{position} = $self->bare_sizer->GetChildren || 0 if $item{position} == -1;

	return \%item;
}

sub _insert { # only one item
	my ($self, $item) = @_;
	return Kephra::Log::error('got hash as item def') unless ref $item eq 'HASH';

	if ($item->{'child'} eq 'space'){
		if ($item->{'proportion'}){
			$self->bare_sizer->InsertStretchSpacer( $item->{'position'}, $item->{'proportion'} )
		} else {
			$self->bare_sizer->InsertSpacer(        $item->{'position'}, $item->{'border'} )
		}
	} 
	elsif (ref $item->{'child'} eq __PACKAGE__){
		push @{ $self->{'subsizer'} }, $item->{'child'};
		$self->bare_sizer->Insert(
			$item->{'position'},  $item->{'child'}->bare_sizer,  $item->{'proportion'},
			$item->{'style'},     $item->{'border'}
		);
	}
	else {
		$self->bare_sizer->Insert(
			$item->{'position'},  $item->{'child'},  $item->{'proportion'},
			$item->{'style'},     $item->{'border'}
		);
	}
	$item->{'position'};
}



sub show     {shift->_relayout( sub { $_[0]->Show(  $_[1],1) }, @_) }
sub hide     {shift->_relayout( sub { $_[0]->Hide(   $_[1] ) }, @_) }
sub detach   {shift->_relayout( sub { $_[0]->Detach( $_[1] ) }, @_) }
sub remove   {shift->_relayout( sub { $_[0]->Remove( $_[1] ) }, @_) } # del spacer & sizer
sub _relayout{
	my ($self) = shift;
	my ($call) = shift;
	return Kephra::Log::error('need a coderef, not $call', 2) unless ref $call eq 'CODE';
	for (@_){
		$_ = $_->bare_sizer if ref $_ eq __PACKAGE__;
		$call->( $self->bare_sizer, $_ );
	}
	$self->bare_sizer->Layout;
	$self->_remove_gone_subsizer;
	$self;
}
sub _remove_gone_subsizer {
	my ($self) = shift;
	my @child_sizer = $self->child_sizer();
	return unless @child_sizer;
	for my $nr (reverse 0 .. scalar @child_sizer ) {
		next if $self->is_child( $child_sizer[$nr]->bare_sizer );
		splice @child_sizer, $nr, 1;
	}
	$self->{'child_sizer'} = \@child_sizer;
}


# getter
sub get_position {                                        # number of that child
	my ($self, $child) = @_;
	my $pos = 0;
	if (is_widget($child)){
		for ($self->bare_sizer->GetChildren){
			return $pos if $_->IsWindow and $_->GetWindow eq $child;
			$pos++;
		}
	}
	elsif (is_sizer($child)){
		for ($self->bare_sizer->GetChildren){
			return $pos if $_->IsSizer and $_->GetSizer eq $child;
			$pos++;
		}
	} 
	else { return Kephra::Log::error("got no proper widget or sizer, but $child", 1) }
	Kephra::Log::error("$child is no child of $self", 1);
	return -1;
}
sub is_child     { $_[0]->child_item( $_[1] ) ne '' ? 1 : 0 }
sub child_item   { $_[0]->bare_sizer->GetItem($_[1]) }    # child with that number
sub child_widget { $_[0]->bare_sizer->GetItem($_[1])->GetWindow }
sub child_widgets{
	my ($self) = shift;
	my @widgets;
	for ($self->bare_sizer->GetChildren)
		{ push @widgets, $_->GetWindow if $_->IsWindow }
	@widgets;
}

sub sizer_items  { shift->_items( sub{ $_[0]->IsSizer  } ) }
sub space_items  { shift->_items( sub{ $_[0]->IsSpacer } ) }
sub widget_items { shift->_items( sub{ $_[0]->IsWindow } ) }
sub _items       {
	my ($self, $check) = @_;
	return Kephra::Log::error("no checker coderef as first parameter, only $check", 1)
		unless ref $check eq 'CODE';

	my @item;
	for ($self->bare_sizer->GetChildren){ push @item, $_ if $check->($_) }
	@item;
}

1;
