#!/usr/bin/perl

sub Usage {
print 
"Usage: makeindex xhtmldir xmldir
   where xhtmldir contains a directory full of OpenGL .xml XHTML man pages -AND-
   where xmldir contains a directory full of OpenGL .xml source XML man pages

   probably want to redirect output into a file like
   ./makeindex.pl . .. > ./index.html
"
}

sub PrintHeader {
print '<html>
<head>
<link rel="stylesheet" type="text/css" href="../../mancommon/opengl-man.css" />
<title>OpenGL Shading Language Reference Pages</title>
</head>
<body>
<a name="top"></a>
<center><h1>OpenGL Shading Language Reference Pages</h1></center>
<br/><br/>

';
}

sub PrintFooter {
print '
<P>
<center>
<small>OpenGL Shading Language (GLSL) Reference Pages Copyright &copy 2011 Khronos Group, Inc.</small>
</center>
</P>
</body>
</html>
';
}

sub TableElementForFilename {
	my $name = shift;

	my $strippedname = $name;
	$strippedname =~ s/\.xml//;
	print "\t";
	print '<tr><td><a target="pagedisp" href="' , $name , '">';
	print "$strippedname";
	print "</a></td></tr>\n";
}

sub BeginTable {
	my $letter = shift;
	print "<a name=\"$letter\"></a><br/><br/>\n";
	print '<table width="200" class="sample">';
	print "\t<th>";
	print "$letter</th>\n";
}

sub EndTable {
	print "\t";
	print '<tr><td align="right"><a href="#top">Top</a></td></tr>';
	print "\n</table>\n\n";
}



##############
#  main
##############

if (@ARGV != 2)
{
	Usage();
	die;
}

# grab list of generated XHTML files
opendir(DIR,$ARGV[0]) or die "couldn't open directory";

@files = readdir(DIR);
close(DIR);
@files = sort {uc($a) cmp uc($b)} @files;

PrintHeader();

my @glsl;
my @builtins;

my @realEntrypoints;
my @pageNames;

#pre-create list of all true entrypoint names

foreach (@files)
{
	if (/xml/)
	{
		$parentName = $ARGV[1] . '/' . $_;
		if (open(PARENT, $parentName))
		{
			@funcs = <PARENT>;
			@funcs = grep(/<funcdef>/, @funcs);
			foreach (@funcs)
			{
				$func = $_;
				$func =~ s/.*<function>//;
				$func =~ s/<\/function>.*\n//;

				push (@realEntrypoints, $func);
			}
			close(PARENT);
		}
	}
}

#pre-create list of page names

foreach (@files)
{
	if (/xml/)
	{
		$parentName = $ARGV[1] . '/' . $_;
		if (open(PARENT, $parentName))
		{
        	        my $entrypoint = $_;
                	$entrypoint =~ s/\.xml//;

			push (@pageNames, $entrypoint);

			close(PARENT);
		}
	}
}

#sort the files into gl, glut, glu, and glX

foreach (@files)
{
	if (/xml/)
	{
                # filter out entrypoint variations that don't have their own man pages
		my $needIndexEntry = 0;

                # continue only if parent page exists (e.g. glColor) OR 
                # different parent page exists with matching entrypoint (e.g. glEnd)
                my $entrypoint = $_;
                $entrypoint =~ s/\.xml//;

		foreach (@pageNames)
		{
			if ($_ eq $entrypoint)
			{
				# it has its own man page
				$needIndexEntry = 1;
			}
		}

		if ($needIndexEntry == 0)
		{
			foreach (@realEntrypoints)
			{
				if ($_ eq $entrypoint)
				{
					# it's a real entrypoint, but make sure not a variation
					$needIndexEntry = 1;

					foreach (@pageNames)
					{
						my $alteredEntrypoint = $entrypoint;
						$alteredEntrypoint =~ s/$_//;

						if (!($alteredEntrypoint eq $entrypoint))
						{
							$needIndexEntry = 0;
						}
					}
				}
			}
		}

		#if ($needIndexEntry)
		if (substr($_, 0, 3) eq "gl_")
		{
    		push (@builtins, $_);
	    }
	    else
		{
			push (@glsl, $_);
		}
	}
}


#output the table of contents

my @toc;

if ($#glsl > 0)
{
	$currentletter = "";
	$opentable = 0;
	
	foreach (@glsl)
	{
		$name = $_;
		$firstletter = uc(substr($name, 0, 1));
		if ($firstletter ne $currentletter)
		{
			push (@toc, $firstletter);
			$currentletter = $firstletter;
		}
	}
}


print '<center>';
print '<div id="container">';
foreach (@toc)
{
	print '<b><a href="#';
	print $_;
	print '" style="text-decoration:none"> ';
	print $_;
	print " </a></b> &nbsp; ";
}
if ($#builtins > 0)
{
    print '<br/><b><a href="#Built-in Variables" style="text-decoration:none">Built-in Variables</a></b>';
}
print "</div>\n\n\n";
print '</center>';

# output the tables

if ($#glsl > 0)
{
	$currentletter = "";
	$opentable = 0;

	foreach (@glsl)
	{
		$name = $_;
		$firstletter = uc(substr($name, 0, 1));
		if ($firstletter ne $currentletter)
		{
			if ($opentable == 1)
			{
				EndTable();
			}
			BeginTable($firstletter);
			$opentable =1;
			$currentletter = $firstletter;
		}
		TableElementForFilename($_);
	}
	if ($opentable)
	{
		EndTable();
	}
}

if ($#builtins > 0)
{
    BeginTable("Built-in Variables");
    foreach (@builtins)
    {
        TableElementForFilename($_);
    }
    EndTable();
}

PrintFooter();
