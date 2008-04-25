#!/usr/bin/perl

$BASEDIR = "/usr/share/doc/hyperspec";
$INPUT = "$BASEDIR/Front/X_AllSym.htm";
$MAX_LINE = 510;
$MIN_WORD_LEN = 3;

sub process_word
{
    my( $word ) = @_;
    my( 
	$n, 
	$len,
	$substr
    );

    push @words, $word;

    # generate e.g. "&allow-other-keys" from "&a-o-k"
    if ($word =~ /-/
	&& $word ne "-")
    {
	$substr = $word;
	$substr =~ s/(\W)?([^-])([^-]+)-/$1$2-/g;
	$substr =~ s/-([^-])[^-]+$/-$1/;
	# print "$substr -> $word\n";
	push @{ $matches{ $substr } }, $word
	    if $substr ne $word;

	if ($substr =~ /^\W/)
	{
	    $substr =~ s/^.//;
	    push @{ $matches{ $substr } }, $word
		if $substr ne $word;
	}
    }
}


sub main
{
    open( IN, "<$INPUT" )
	or die "Couldn't open $INPUT for input: $!";
    while (<IN>)
    {
	next
	    if !/DEFINITION/;
	chomp;

	s/^.*htm#//;
	s/".*//;

	s/AM/\&/g;
	s/ST/\*/g;
	s/PL/\+/g;
	s/SL/\//g;
	s/EQ/=/g;
	s/LT/</g;
	s/GT/>/g;

	$word = $_;
	&process_word( $word );
    }

    foreach $word (sort( { length( $a ) <=> length( $b ) 
			   || $a cmp $b }
			 @words ))
    {
	print $word, "\n"
	    if (length( $word ) > $MIN_WORD_LEN);
    }

    foreach $key (sort keys %matches)
    {
	$out = join( " ", 
		     $key, 
		     sort( { length( $a ) <=> length( $b ) 
			     || $a cmp $b } 
			   @{ $matches{ $key } } ) );
	print $out, "\n"
	    if (length( $out ) <= $MAX_LINE);
    }
}

&main();

