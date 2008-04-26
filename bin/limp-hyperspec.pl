#!/usr/bin/perl

use File::Temp qw/ tempfile tempdir /;

# Last updated: Tue Jun 11 00:36:52 EDT 2002

# Point this to the location of your CLHS.  Must be a local copy -- no http://
# allowed.
$BASE = "/usr/share/doc/hyperspec";

#####################################################################
# Opera -- works

# the name of your browser -- must be in your $PATH
$browser_name = "opera";

# Arguments for your browser.  %s replaced with URL
@browser_args = ("-remote", "openURL(file://localhost%s,new-page)");

# Does your browser open a window of its own?  1 for yes, 0 for no
$external = 1;

# If I have to start a browser, do you want me to tell you so and make you
# press ENTER?
$READLINE_ON_BROWSER_START = 0;

# How long to wait for the browser to read a new page, so we can delete a
# generated index file (e.g. for a "grep" lookup).  In seconds.
$SLEEP_AFTER_NEW_PAGE= 60;

#####################################################################
# Lynx -- works, I think
# $browser_name = "lynx";
# @browser_args = ();
# $external = 0;


#####################################################################
# Konqueror -- probably doesn't work
# $browser_name = "konqueror";
# @browser_args = ();	# FIXME: How do I not start a new konqueror process
			# for each page viewed?
# $external = 1;


#####################################################################
# Netscape -- Works, I think
# $browser_name = "netscape";
# @browser_args = ( "-remote", "openURL(file://localhost%s)" );
# $external = 1;


######################################################################
# Functions


sub gen_browser_args
{
    my( $url, $browser_running ) = @_;
    my( $arg, @new_args );

    if ($browser_running)
    {
	@new_args = @browser_args;
	foreach $arg (@new_args)
	{
	    $arg = sprintf $arg, $url;
	}

	return( @new_args );
    }
    else
    {
	return( "file://localhost" . $url );
    }
}


sub gen_file
{
    my( $fh, $match_type, $orig_symbol, $match_on, $done) = @_;
    my( $url );

    # do preamble
    print $fh "<html>\n<head>\n<title>$match_type CLHS lookup of $orig_symbol</title>\n</head>\n";
    print $fh "<body>\n";

    foreach $url (sort { substr( $a, index( $a, '#' ) )
			 cmp
			 substr( $b, index( $b, '#' ) ) }
		    keys %$done)
    {
	my $cur_word = $$done{ $url };
	$cur_word =~ s/$match_on/<b>$match_on<\/b>/g;
	printf $fh "<a href=\"%s/Front/%s\">%s</a><br>\n", $BASE, $url, $cur_word;
    }
    print $fh "</body>\n</html>";

    close( $fh );
}


sub browse
{
    my( $browser_running, $match_type, $orig_symbol, $match_on, $pat, $make_page ) = @_;
    my( %done, $pid, $url, $word, $fh, $filename, $do_wait, $do_read, 
	@keys, $dummy, $started, $num_deleted, $sleep_time );

    while (<>)
    {
	if (/DEFINITION.*$pat/)
	{
	    ($url, $word) = (split( /["<>]/, $_ ))[ 2, 4 ];
	    # print "url is $url, word is $word\n";

	    $done{ $url } = $word;
	}
    }

    @keys = sort( { substr( $a, index( $a, '#' ) )
			 cmp
			 substr( $b, index( $b, '#' ) ) }
		    keys %done );

    $make_page = 0
	if (@keys <= 1);

    if ($make_page)
    {
	($fh, $filename) = tempfile( "/tmp/VIlisp-hyperspec.XXXXXX", SUFFIX => '.html' );
	&gen_file( $fh, $match_type, $orig_symbol, $match_on, \%done );
    }

    $do_read = 0;
    $do_wait = 1;
    if ($external)
    {
	if (!$browser_running)
	{
	    # print "no $browser_name found\n";
	    $do_wait = 0;
	    $do_read = $READLINE_ON_BROWSER_START;
	}
    }

    if ($make_page)
    {
	$started = time();
	if (($pid = fork()) == 0)
	{
	    # child
	    close( STDOUT );
	    close( STDERR );
	    exec( $browser_name,
		  &gen_browser_args( $filename, $browser_running ) );
	    exit;
	}
	else
	{
	    # parent
	    $browser_running = 1;
	    if ($do_read
		&& $external)
	    {
		print "Starting browser.  Press <enter>: ";
		$dummy = <>;
	    }
	}
	if ($external)
	{
	    # if browser already started, and we haven't forked to background
	    # already, do so now
	    if (!$forked_to_background
		&& 0 != fork())
	    {
		exit;
	    }
	    $forked_to_background = 1;

	    # give the browser time to start & read the file
	    $sleep_time = $SLEEP_AFTER_NEW_PAGE - (time() - $started);
	    # printf "sleeping %d seconds\n", $sleep_time;
	    sleep $sleep_time
		if $sleep_time > 0;
	}
	else
	{
	    # if not external (e.g. Lynx) wait for it to finish
	    waitpid( $pid, 0 );
	}

	# delete the made page
	$num_deleted = unlink $filename;
	# print "deleted $num_deleted files\n";
    }
    else
    {
	for ($n = 0; $n < @keys; $n++)
	{
	    $url = $keys[ $n ];

	    # print "url is $url\n";
	    if (($pid = fork()) == 0)
	    {
		# child
		close( STDOUT );
		close( STDERR );
		exec( $browser_name,
		      &gen_browser_args( "$BASE/Front/" . $url, $browser_running ) );
		exit;
	    }
	    else
	    {
		$browser_running = 1;
		if ($do_read
		    && $external
		    && !$forked_to_background)
		{
		    print "Starting browser.  Press <enter>: ";
		    $dummy = <>;
		    $do_read = 0;
		}

		if ($external
		    && !$forked_to_background)
		{
		    # if browser already started, and we haven't forked to background
		    # already, do so now
		    if (!$forked_to_background
			&& 0 != fork())
		    {
			exit;
		    }
		    $forked_to_background = 1;
		}

		if (!$external
		    || ($do_wait
			&& $n < @keys - 1))
		{
		    waitpid( $pid, 0 );

		    # Opera can't quite open pages fast enough when you do
		    # them one after the other.  Sleep a half second.
		    select( undef, undef, undef, 0.5 );
		}
		$do_wait = 1;
	    }
	}
    }
}


######################################################################
# Main procedure

sub main
{
    my( $type, $make_page, $symbol, $first, $browser_running );

    # global
    $forked_to_background = 
	$external && !$make_page && !$READLINE_ON_BROWSER_START;

    $| = 1;

    # fork to background immediately (maybe)
    exit
	if ($forked_to_background
	    && 0 != fork());

    $type = shift @ARGV;
    $make_page = shift @ARGV;
    $symbol = shift @ARGV;

    $browser_running = (0 == system( "ps -elf | grep -v grep | grep -q $browser_name" ));

    $orig_symbol = $symbol;

    if ($symbol =~ /\*$/) { $symbol =~ s/\*$/ST/; }
    elsif ($symbol =~ /\&/) { $symbol =~ s/\&/AM/g; }

    # print "symbol is $symbol\n";

    @ARGV = glob( "$BASE/Front/X_Perm_*.htm" );

    if    ($type eq "exact")  { &browse( $browser_running, $type, $orig_symbol, $symbol, "#$symbol\"", $make_page ); } 
    elsif ($type eq "prefix") { &browse( $browser_running, $type, $orig_symbol, $symbol, "#$symbol", $make_page ); } 
    elsif ($type eq "suffix") { &browse( $browser_running, $type, $orig_symbol, $symbol, "#[^\"]*" . $symbol . "\"", $make_page ); }
    elsif ($type eq "grep")   { &browse( $browser_running, $type, $orig_symbol, $symbol, "#[^\"]*" . $symbol . "[^\"]*\"", $make_page ); }
    elsif ($type eq "index")
    {
	$first = uc substr( $symbol, 0, 1 );
	if (!fork())
	{
	    # child
	    close( STDOUT );
	    close( STDERR );
	    exec( $browser_name,
		  &gen_browser_args( "$BASE/Front/X_Perm_$first.htm", $browser_running ) );
	    exit;
	}
	wait()
	    if !$external;
    }
    elsif ($type eq "index-page")
    {
	if (!fork())
	{
	    # child
	    close( STDOUT );
	    close( STDERR );
	    exec( $browser_name,
		  &gen_browser_args( "$BASE/Front/X_Symbol.htm", $browser_running ) );
	    exit;
	}
	wait()
	    if !$external;
    }
}

&main();

