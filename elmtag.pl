#!/usr/local/bin/perl
#       $Id: elmtag.pl,v 1.9 1998/12/12 23:34:47 cinar Exp $
#
# Elmtag.pl to insert tag lines to your e-mail messages.
# Copyright (C) 1998 Ali Onur Cinar <root@zdo.com>
#
# Latest version can be downloaded from:
#
#   ftp://hun.ece.drexel.edu/pub/cinar/elmtag*
#   ftp://ftp.cpan.org/pub/CPAN/authors/id/A/AO/AOCINAR/elmtag*
#   ftp://sunsite.unc.edu/pub/Linux/system/admin/time/elmtag*
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version. And also
# please DO NOT REMOVE my name, and give me a CREDIT when you use
# whole or a part of this program in an other program.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

# location of tag database
$tag_file = '/home/cinar/personel/documents/tags';

# your prefered editor
$your_editor = 'vi';

# do you want an alphabeticaly ordered list? (1=on, 0=off)
$alphabetical = 1;

# User interface coordinates
$xcord = 2;
$ycord = 4;
$uiheight = 10;
$uiweight = 76;

# what's my version
$verraw  = '$Revision: 1.9 $'; $verraw =~ /.{11}(.{4})/g; $elmtagver = "1.$1";

# terminal controls
%scr = (	'f'		=> 3,
		'b'		=> 4,
		'black'		=> 0,
		'red'		=> 1,
		'green'		=> 2,
		'yellow'	=> 3,
		'blue'		=> 4,
		'magenta'	=> 5,
		'cyan'		=> 6,
		'white'		=> 7,
		'normal'	=> 0,
		'bold'		=> 1,
		'rev'		=> 7,
		'invisible'	=> 8,
		'clear'		=> '2J',
		'clrline'	=> 'K',
		'savepos'	=> 's',
		'returnpos'	=> 'r',
		'mvup'		=> 'A',
		'mvdn'		=> 'B',
		'mvfr'		=> 'C',
		'mvbk'		=> 'D');


sub svid		# clr,(f/b) or mode,x	
{
	print "\x1B[$scr{$_[1]}$scr{$_[0]}m";
}

sub sgoto		# x,y
{
	print "\x1B[$_[1];$_[0]H";
}

sub scurs		# code, num
{
	printf ("\x1B[%s$scr{$_[0]}",$_[1]);
}

sub scenter		# y, string
{
	my ($y);
	$y = ($uiweight-length($_[1]));
	sgoto((($y-($y%2))/2),$_[0]);
	print $_[1];
}

sub BufferTags
{
	open Tags, $tag_file;
	undef @Taglines;
	undef @TaglinesS;

	while (<Tags>)
	{
		chomp;
		push(@Taglines, $_);
	}

	close Tags;

	if ($alphabetical == 1)
	{
		@Taglines = sort(@Taglines);
	}

	foreach (@Taglines)
	{
		push(@TaglinesS, substr($_,0,$uiweight-2));
	}
}

sub ShwTag
{
	print " $TaglinesS[$_[0]]", ' ' x ($uiweight-length($TaglinesS[$_[0]])-1);
}

sub ShowTags
{
	local($stl_line=0, $stl_pointer=0, $stl_end=$#Taglines, $m, $n, $SelectedTag);
	undef $key;

	if ($BSD_STYLE)
	{
		system "stty cbreak </dev/tty >/dev/tty 2>&1";
	}
	else
	{
		system "stty", '-icanon', 'eol', "\001";
	}
	system "stty -echo";

	while (($key ne 'e') && ($key ne 's') && ($key ne 'q'))
	{
		$m = $stl_pointer - $stl_line;

		svid(normal);
		for ($n=0; $n<=$uiheight; $n++)
		{
			if ($n != $stl_pointer)
			{
				sgoto($xcord,$n+$ycord);
				ShwTag($m+$n);
			}
		}

		svid(rev);
		sgoto($xcord,$stl_line+$ycord);
		ShwTag($stl_pointer);

		$key = getc(STDIN);
		if ($key == 27)
		{
			$key = getc(STDIN);
			if (($key eq '[') || ($key eq 'O'))
			{
				$key = getc(STDIN);
			}
		}

# Case DN ARROW
		if ((($key eq 'B') || ($key eq 'r')) && ($stl_pointer < $stl_end))
		{
			if ($stl_line < $uiheight)
			{
				$stl_line ++;
				$stl_pointer ++;
			}

			elsif ($stl_line == $uiheight)
			{
				$stl_pointer ++;
			}
		}

# Case UP ARROW
		elsif (($key eq 'A') || ($key eq 'x'))
		{
			if ($stl_line > 0)
			{
				$stl_line --;
				$stl_pointer --;
			}

			elsif (($stl_line == 0) && ($stl_pointer > 0))
			{
				$stl_pointer --;
			}
		}
	}
	
	svid(normal);
	print ".\n";

       	if ($BSD_STYLE)
	{
		system "stty -cbreak </dev/tty >/dev/tty 2>&1";
	}
	else
	{
		system "stty", '-icanon', 'eol', '^@';
	}

	system "stty echo";
}

sub DrawUI
{
	my($k);
	$k=$#Taglines+1;
	svid(normal);scurs(clear);
	scenter($ycord-2,"Tagline database has $k taglines.");
	scenter($ycord+$uiheight+2,"Use arrow keys to move, (s)elect, (e)dit");
	scenter($ycord+$uiheight+3,"or just press (q) if you don't want to use a tagline at this time.");
	scenter($ycord+$uiheight+4,"Elmtag.pl v$elmtagver (c) '98 by Ali Onur Cinar <root\@zdo.com>");

}

sub Evaluate
{
	if ($key eq 's')
	{
		$SelectedTag = "\"\\n$Taglines[$stl_pointer]\\n\"";
		system "echo $SelectedTag >> $ARGV[0]";
		exec $your_editor, $ARGV[0];
	}
	elsif ($key eq 'e')
	{
		system $your_editor, $tag_file;
		goto main;
	}
	elsif ($key eq 'q')
	{
		scurs(clear);
		if ($ARGV[0] ne '')
		{
			exec $your_editor, $ARGV[0];
		}
	}
}

# main
main:
BufferTags;
DrawUI;
ShowTags;
Evaluate;
