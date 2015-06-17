#!/usr/bin/perl

#A simple toy script displaying the contents of an ELF file.

# (c) 2015 - Xavier G.
# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What The Fuck You Want
# To Public License, Version 2, as published by Sam Hocevar. See
# http://sam.zoy.org/wtfpl/COPYING for more details.

# About the naming of functions: this script use camel case for functions.
# I wish to quote a friend about that:
#   < gradator> c'est d'la merde le CamelCase
# That's it.

# Simple arguments parsing: require one and exactly one argument.
usage() if @ARGV != 1;

# That arguments is expected to be an existing, readable file.
our $elf_filepath = $ARGV[0];
unless (-f $elf_filepath && -r $elf_filepath) {
	exitWithMessage(120, sprintf('%s either does not exist or is not readable.', $elf_filepath));
}

# Open the file
our $elf_fh;
our $opening = open($elf_fh, '<' . $elf_filepath);
if (!$opening) {
	exitWithMessage(115, sprintf('Unable to open %s: %s', $elf_filepath, $!));
}
binmode($elf_fh);
walkELF($elf_fh);
close($elf_fh);

sub exitWithMessage {
	my $rc = $_[0];
	my $message = $_[1];
	print "Error: " unless ($rc == 0);
	print $message . "\n";
	exit($rc);
}

sub usage {
	print "Usage: ${0} file\n";
	exit(125);
}

sub walkELF {
	# long way from home
}

exit(0);
