#!/usr/bin/perl

# Author: Sébastien Roux
# Mailto: roux.sebastien@gmail.com
# License: GPLv3, see attached license

# Modules include
use Getopt::Std;
use Strict;

# Set argument parameters
getopts( "i:o:d:f:h", \%opts ) or DisplayUsage();

# Verify arguments
DisplayHelp();
TestInputDirArg();
TestDateFormatArg();

$Directory = $opts{i};

opendir( DIRECTORY, $Directory )
  ;    #|| die  "Cannot open directory $Directory !\n" );
@DirContents = readdir(DIRECTORY);
closedir(DIRECTORY);

# Open specified output file
if ( $opts{o} ) {
	open( OUTPUT, ">$opts{o}" )
	  or die print "Error: could not open '$opts{o}'\n";
}

# Loop through specified directory
foreach $file (@DirContents) {
	if ( !( ( $file eq "." ) || ( $file eq ".." ) ) ) {
		if ( $file =~ /alg$/ ) {

			open( INPUT_ALG, $Directory . $file )
			  or die print "Error: could not open $file\n";

			$LCount = 1;
			while (<INPUT_ALG>) {

				if ( ( $LCount == 1 ) && (/^\[/) ) {
					chomp;
					$Line = $_;    # Current line

					ChangeDateFormat();

					# File output
					if ( $opts{o} ) {
						print OUTPUT "$Header\n";
					}
					else {
						print "$Header\n";
					}

				}
				elsif ( ( $LCount == 2 ) && (/^Create/) ) {
					chomp;
					$Line = $_;

					# File output
					if ( $opts{o} ) {
						print OUTPUT "$Line: $file\n\n";
					}
					else {
						print "$Line: $file\n\n";
					}
				}
				else {
					if (/^\[/) {
						chomp;
						$Line = $_;
						$Line =~ s/[\[\]]// for 1 .. 2;
						ChangeDateFormat();
					}
					else {
						$Line = $_;
						@desc = split / /, $Line;

						ChangeMonthString();

						$FullHeader = "$Header - @desc[5]";

						# Filtering
						unless ( $FullHeader !~ /.*$opts{f}.*$/ ) {

							# Header (date time - user) (atg)
							# File output
							if ( $opts{o} ) {
								print OUTPUT "$FullHeader\n";
							}
							else {
								print "$Header - @desc[5]\n";
							}

							# First row of data logs (atx)
							$frow = @desc[11];

							# Last row of data logs
							$lrow = ( @desc[11] + @desc[18] - 2 );

							#print "First row: $frow, last row: $lrow\n";

							# Matching rows in data logs (atx)
							@data = ();

							# Filename without extension
							$file2 = substr( $file, 0, ( length($file) - 3 ) );

							open( INPUT_ATX, $Directory . $file2 . "atx" )
							  or die print "Error: could not open atx\n";
							while (<INPUT_ATX>) {
								if ( $. >= $frow && $. <= $lrow ) {

									#$_ =~ s/ /\t/g;
									push( @data, $_ );
								}
							}
							close(INPUT_ATX);

							foreach (@data) {

								# File output
								if ( $opts{o} ) {
									print OUTPUT "$_";
								}

								#StdOut output
								else {
									print "$_";
								}
							}

							# File output
							if ( $opts{o} ) {
								print OUTPUT "\n";
							}

							#StdOut output
							else {
								print "\n";
							}
						}
					}
				}
				$LCount++;
			}
			close(INPUT_ALG);
			close(OUTPUT);
		}
	}
}

#--------------------------------
sub DisplayHelp {

	if ( $opts{h} || @ARGV > 0 ) {
		print "DESCRIPTION :\n"
		  . "Merge Essbase or Analytic Services( v .5 -v .9 ) SSAudit files (.ATX, .ATG)\n"
		  . "from specified directory.\n"    
		  . "Options available : advanced date formatting, filtering.\n";
		print "AUTHOR :\n"
		  . "Written by Sebastien Roux <roux.sebastien\@gmail.com>\n";
		print "LICENSE :\n"
		  . "GNU General Public License version 3 (GPLv3)\n";
		print "NOTES :\n"
		  . "Use at your own risk !\n"
		  . "You will be solely responsible for any damage\n"
		  . "to your computer system or loss of data\n"
		  . "that may result from the download\n"
		  . "or the use of the following application/script.\n";
		DisplayUsage();
	}
}

#--------------------------------
sub DisplayUsage {

	print "\nUSAGE: perl SSAP . pl -i <.atx & .atg directory> "
	  . "[-o <outputfile>, -d <arg>, -h]\n\n";
	print "USAGE: SSAP . exe -i <.atx & .atg directory> "
	  . "[-o <outputfile>, -d <arg>, -h]\n\n";
	print
"  -i   specify SSAudit logs' directory, args: <directory1[;directory2;...]>\n";
	print "  -o   specify output file, arg: <outputfile>\n";
	print "  -d   specify date format, arg: <ISO|EUR|US>\n";
	print "  -f   specify filter on headers (case sensitive), arg: <*>\n";
	print "  -h   display usage\n";
	exit;
}

#--------------------------------
sub TestInputDirArg {

	@i = split /;/, $opts{i};

	foreach $i (@i) {
		if ( !-d $i ) {
			print "Error: '$i' does not exists!\n";
			DisplayUsage();
		}
	}
}

#--------------------------------
sub TestDateFormatArg {

	if (   $opts{d}
		&& ( uc( $opts{d} ) ne "ISO" )
		&& ( uc( $opts{d} ) ne "EUR" )
		&& ( uc( $opts{d} ) ne "US" ) )
	{
		print "Error: '$opts{d}' is not a valid argument for date format!";
		DisplayUsage();
	}
}

#--------------------------------
sub ChangeDateFormat {

	ChangeMonthString();

	$Line =~ s/[\[\]]// for 1 .. 2;

	my @g = split / /, $Line;
	$lastg = scalar(@g);
	
	# Set date format to ISO 8601 extended style (YYYY-MM-DD)
	if ( uc( $opts{d} ) eq "ISO" ) {
		$Header = "@g[4]/@g[1]/@g[2] @g[3]";
	}

	# Set date format to US style (MM/DD/YYYY)
	elsif ( uc( $opts{d} ) eq "US" ) {
		$Header = "@g[1]/@g[2]/@g[4] @g[3]";
	}

	# Set date format to European style (DD/MM/YYYY)
	elsif ( uc( $opts{d} ) eq "EUR" ) {
		$Header = "@g[2]/@g[1]/@g[4] @g[3]";
	}
}

#--------------------------------
# Replace month label by month number
sub ChangeMonthString {

	my $MonthIndex;

	if ( $Line =~ m/(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)/ ) {
		if    ( lc($&) eq "jan" ) { $MonthIndex = "01"; }
		elsif ( lc($&) eq "feb" ) { $MonthIndex = "02"; }
		elsif ( lc($&) eq "mar" ) { $MonthIndex = "03"; }
		elsif ( lc($&) eq "apr" ) { $MonthIndex = "04"; }
		elsif ( lc($&) eq "may" ) { $MonthIndex = "05"; }
		elsif ( lc($&) eq "jun" ) { $MonthIndex = "06"; }
		elsif ( lc($&) eq "jul" ) { $MonthIndex = "07"; }
		elsif ( lc($&) eq "aug" ) { $MonthIndex = "08"; }
		elsif ( lc($&) eq "sep" ) { $MonthIndex = "09"; }
		elsif ( lc($&) eq "oct" ) { $MonthIndex = "10"; }
		elsif ( lc($&) eq "nov" ) { $MonthIndex = "11"; }
		elsif ( lc($&) eq "dec" ) { $MonthIndex = "12"; }
		$Line =~ s/$&/$MonthIndex/;
	}
}

#--------------------------------
sub TestDateFormatArg {

	if (   $opts{d}
		&& ( uc( $opts{d} ) ne "ISO" )
		&& ( uc( $opts{d} ) ne "EUR" )
		&& ( uc( $opts{d} ) ne "US" ) )
	{
		print "Error: '$opts{d}' is not a valid argument for date format!";
		DisplayUsage();
	}
}

__END__
