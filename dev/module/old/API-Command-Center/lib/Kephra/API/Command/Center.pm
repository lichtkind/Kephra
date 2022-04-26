use v5.14	;
use warnings;

package Kephra::API::Command::Center;

my %center;

sub create_command {}
sub delete_command {}


1;

__END__


sub has_call { ref $call{$_[0]} eq 'HASH' and ref $call{$_[0]}{'code'} eq 'CODE'}
sub run_call {
	my ($callID, @param) = @_;
	return warning("$callID is not created.") unless has_call( $callID );
	$call{$callID}{'code'}(@param) if ref $call{$callID};
}

sub run_all {
	my ($self, @param) = @_;
	$_->{'code'}(@param) for values %call;
}


sub add_call {
	my ($callID, $call, @deps) = @_;
	return warning("call $callID already created") if has_call( $callID );
	return warning("need at least 2 arguments") unless $call;
	if (not ref $call){
		$call{$callID}{'source'} = $call;
		eval '$call{$callID}{"code"} = sub { '.$call.' }';
	} elsif (ref $call eq 'CODE'){ 
		$call{$callID}{'source'} = '';
		$call{$callID}{'code'} = $call;
	}
	$call{$callID}{'deps'} = {};
	add_dependency($callID, $_) for @deps;
}

sub remove_call {
	my ($callID) = @_;
	return warning("$callID is not registered.") unless has_call( $callID );
	my @deps = keys %{$call{$callID}{'deps'}};
	delete $call{$callID};
	return @deps;
}


sub has_dependency {
	my ($callID, $dep) = @_;
	return warning("$callID is not registered.") unless has_call( $callID );
	return exists $call{$callID}{'deps'}{$dep};
}

sub add_dependency {
	my ($callID, @deps) = @_;
	return warning("$callID is not registered.") unless has_call( $callID );
	$call{$callID}{'deps'}{$_} = 1  for @deps;
}

sub remove_dependency {
	my ($callID, @deps) = @_;
	return warning("$callID is not registered.") unless has_call( $callID );
	return warning("not enough parameter.") unless @deps;
	for (@deps){
		warning("dependency $_ is not registered.") unless $call{$callID}{'deps'}{$_};
		delete $call{$callID}{'deps'}{$_};
	}
}


sub statusreport {
	my $status = "CallBank:\n";
	for my $ID (sort keys %call){
 	    $status .= "    - $ID:\n";
 	    for (qw/source code/){
            $status .= "       - $_: $call{$ID}{$_}\n" if $call{$ID}{$_};
 	    }
		$status .= '       - deps: '.(join ' ',(keys %{$call{$ID}{'deps'}}))."\n" if ref $call{$ID}{'deps'} eq 'HASH';
	}
	report($status);
}
