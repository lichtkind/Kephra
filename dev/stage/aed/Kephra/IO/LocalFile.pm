use v5.16;
use warnings;
use Encode;
use Encode::Guess;
use File::Spec;


package Kephra::IO::LocalFile;


sub normalize_path {
	my $file = shift;
	return unless defined $file and $file;

	$file = File::Spec->canonpath($file);
	local $/ = "\r\n";
	chomp($file);
	return $file;
}


sub guess_encoding {
	my $text    = shift // '';
	my $default = shift // 'utf-8';
	my $encoding;
	if ($text) {
		my @guesses = ($default, qw/utf-8 iso8859-1 iso8859-2 latin1/);
		my $guess = Encode::Guess::guess_encoding( $text, @guesses );
		if   (ref($guess) and ref($guess)=~ m/^Encode::/){ $encoding = $guess->name }
		elsif(                    $guess =~ m/utf8/     ){ $encoding = 'utf-8' }
		elsif(                    $guess =~ m/or/       ){
			my @suggest_encodings = split /\sor\s/, "$guess";
			$encoding = $suggest_encodings[0];
		} else  { $encoding = $default }
	} else      { $encoding = $default }
	return $encoding;
}


sub read_raw { read_with_encoding($_[0], 'raw')}
sub read_with_encoding {
	my $file = normalize_path( shift );
	my $encoding = shift;
	return say("can't load nonexising file") unless $file and -e $file;
	return say("can't read $file") unless -r $file;
	return say("need encoding") unless defined $encoding;
	open my $FH, '<' , $file;
	#binmode($FH, ":$encoding");
	return do { local $/; <$FH> }; # raw file content 
}

sub read {
	my ($file, $encoding) = @_;
	my $text = defined $encoding ? read_with_encoding($file, $encoding) : read_raw($file);
	$encoding = guess_encoding($text) if not defined $encoding
									  or not $encoding or $encoding eq 'no';
	$text = Encode::decode( $encoding,  $text ) if $text; 
	return $text, $encoding;
}


sub write {
	my ($file, $encoding, $text) = @_;
	$file = normalize_path( $file );
	$encoding = 'utf-8' if not defined $encoding or not $encoding or $encoding eq 'no';
	return say("need a file path") unless $file;
	return say("can't overwrite $file") if -e $file and not -w $file;
	open my $FH, "> :encoding($encoding)", $file; # :raw
	print $FH $text;
}


1;
