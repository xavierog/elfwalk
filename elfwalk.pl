#!/usr/bin/perl -w

# A simple toy script displaying the contents of an ELF file.

# (c) 2015 - Xavier G.
# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What The Fuck You Want
# To Public License, Version 2, as published by Sam Hocevar. See
# http://sam.zoy.org/wtfpl/COPYING for more details.

# About the naming of functions: this script uses camel case for functions.
# I wish to quote a friend of mine about that:
#   < gradator> c'est d'la merde le CamelCase
# That's it.

use strict;
use Fcntl;
use Data::Dumper;

# Constants
use constant {
	UNSIGNED => 0,
	SIGNED => 1,
	LITTLE_ENDIAN => 0,
	BIG_ENDIAN => 1,
};

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

my $default_endianess = LITTLE_ENDIAN;

sub setDefaultEndianess {
	$default_endianess = shift;
}

# Expected arguments:
#   - file descriptor
#   - amount of bytes to read and parse
#   - 0 for unsigned, 1 for signed
#   - endianess: either LITTLE_ENDIAN or BIG_ENDIAN
sub readValue {
	my $fd = shift;
	my $size = shift;
	my $signed = shift;
	my $endianess = shift;

	# Default values.
	$signed = UNSIGNED if (!defined($signed));
	if (!defined($endianess) || $endianess != LITTLE_ENDIAN || $endianess != BIG_ENDIAN) {
		$endianess = $default_endianess;
	}

	my $data;
	read($fd, $data, $size);
	# TODO check the read
	my $unpack_arg;
	if ($size == 2 || $size == 4) {
		# n stands for "network" (i.e. big-endian)
		# v stands for "VAX" (i.e. little-endian)
		$unpack_arg = $endianess ? 'n' : 'v';
		# lowercase is 16 bits, uppercase is 32 bits
		$unpack_arg = uc($unpack_arg) if ($size == 4);
		$unpack_arg .= '!' if ($signed);
	}
	elsif ($size == 8) {
		$unpack_arg = ($signed ? 'q' : 'Q') . ($endianess ? '>' : '<');
	}
	return unpack($unpack_arg, $data);
	# Unpack cheat sheet:
	#   n  An unsigned short (16-bit) in "network" (big-endian) order.
	#   N  An unsigned long (32-bit) in "network" (big-endian) order.
	#   v  An unsigned short (16-bit) in "VAX" (little-endian) order.
	#   V  An unsigned long (32-bit) in "VAX" (little-endian) order
	#   n! A signed short (16-bit) in "network" (big-endian) order.
	#   N! A signed long (32-bit) in "network" (big-endian) order.
	#   v! A signed short (16-bit) in "VAX" (little-endian) order.
	#   V! A signed long (32-bit) in "VAX" (little-endian) order
	#   q> A signed quad (64-bit) value (big-endian).
	#   Q> An unsigned quad (64-bit) value (big-endian).
	#   q< A signed quad (64-bit) value (little-endian).
	#   Q< An unsigned quad (64-bit) value (little-endian).
}

sub walkELF {
	my $elf_fh = shift;

	my %elf_data = ();
	print "Parsing file header\n";
	walkELFHeaderMagicNumber($elf_fh, \%elf_data);
	walkELFHeaderIdent($elf_fh, \%elf_data);
	walkELFHeaderFields($elf_fh, \%elf_data);
}

sub walkELFHeaderMagicNumber {
	my $elf_fh = shift;
	my $elf_data = shift;
	my $data;

	# 0x7f, E, L, F
	read($elf_fh, $data, 1);
	if ($data eq "\x7f") {
		print "    EI_MAG0 is 0x7f (127) as expected\n";
	}
	else {
		exitWithMessage(100, "EI_MAG0 is not 0x7f as expected, aborting.");
	}

	read($elf_fh, $data, 1);
	if ($data eq 'E') {
		print "    EI_MAG1 is 'E' as expected\n";
	}
	else {
		exitWithMessage(100, "EI_MAG1 is not 'E' as expected, aborting.");
	}

	read($elf_fh, $data, 1);
	if ($data eq 'L') {
		print "    EI_MAG2 is 'L' as expected\n";
	}
	else {
		exitWithMessage(100, "EI_MAG2 is not 'L' as expected, aborting.");
	}

	read($elf_fh, $data, 1);
	if ($data eq 'F') {
		print "    EI_MAG3 is 'F' as expected\n";
	}
	else {
		exitWithMessage(100, "EI_MAG3 is not 'F' as expected, aborting.");
	}
}

sub walkELFHeaderIdent {
	my $elf_fh = shift;
	my $elf_data = shift;
	my $data;

	read($elf_fh, $data, 1);
	if ($data eq "\x1") {
		print "    EI_CLASS is 1, i.e. ELFCLASS32: 32-bit objects\n";
	}
	elsif ($data eq "\x2") {
		print "    EI_CLASS is 2, i.e. ELFCLASS64: 64-bit objects\n";
	}
	else {
		exitWithMessage(100, "EI_CLASS is neither 1 nor 2 as expected, aborting.");
	}

	read($elf_fh, $data, 1);
	if ($data eq "\x1") {
		print "    EI_DATA is 1, i.e. ELFDATA2LSB: object file data structures are little-endian\n";
		setDefaultEndianess(LITTLE_ENDIAN);
	}
	elsif ($data eq "\x2") {
		print "    EI_DATA is 1, i.e. ELFDATA2MSB: object file data structures are big-endian\n";
		setDefaultEndianess(BIG_ENDIAN);
	}
	else {
		exitWithMessage(100, "EI_DATA is neither 1 nor 2 as expected, aborting.");
	}

	read($elf_fh, $data, 1);
	if ($data eq "\x1") {
		print "    EI_VERSION is 1, i.e. EV_CURRENT.\n";
	}
	else {
		printf("    EI_VERSION is 0x%X, i.e. not EV_CURRENT, ignoring.\n", ord($data));
	}

	read($elf_fh, $data, 1);
	if ($data eq "\x0") {
		print "    EI_OSABI is 0, i.e. ELFOSABI_SYSV: System V ABI\n";
	}
	elsif ($data eq "\x1") {
		print "    EI_OSABI is 1, i.e. ELFOSABI_HPUX: HP-UX operating system\n";
	}
	elsif ($data eq "\xff") {
		print "    EI_OSABI is 255, i.e. ELFOSABI_STANDALONE: standalone (embedded) application\n";
	}
	else {
		printf("    EI_OSABI is 0x%02X, which is unexpected, ignoring.\n", ord($data));
	}

	read($elf_fh, $data, 1);
	printf("    EI_ABIVERSION is 0x%02X.\n", ord($data));

	print "    Seeking to offset EI_NIDENT (16).\n";
	seek($elf_fh, 16, Fcntl::SEEK_SET);
}

sub walkELFHeaderFields {
	my $elf_fh = shift;
	my $elf_data = shift;
	my $data;

	my $e_type = $elf_data->{'e_type'} = readValue($elf_fh, 2, UNSIGNED);
	if ($e_type >= 0 && $e_type < 5) {
		my @types = ('ET_NONE', 'ET_REL', 'ET_EXEC', 'ET_DYN', 'ET_CORE');
		my @explanations= ('no file type', 'relocatable object file', 'executable file', 'shared object file', 'core file');
		printf("  e_type is %d, i.e. %s, i.e. %s.\n", $e_type, $types[$e_type], $explanations[$e_type]);
	}
	elsif ($e_type >= 0xFE00 && $e_type <= 0xFEFF) {
		printf("  e_type is 0x%04X, between ET_LOOS (0xFE00) and ET_HIOS (0xFEFF), which represents an environment-specific use.\n", $e_type);
	}
	elsif ($e_type >= 0xFF00 && $e_type <= 0xFFFF) {
		printf("  e_type is 0x%04X, between ET_LOPROC (0xFF00) and ET_HIPROC (0xFFFF), which represents a processor-specific use.\n", $e_type);
	}
	else {
		exitWithMessage(100, sprintf("e_type is 0x%04X, which is unexpected, aborting.\n", $e_type));
	}

	my $e_machine = $elf_data->{'e_machine'} = readValue($elf_fh, 2, UNSIGNED);
	printf("  e_machine is 0x%04X -- this is the target architecture.\n", $e_machine);

	my $e_version = $elf_data->{'e_version'} = readValue($elf_fh, 4, UNSIGNED);
	if ($e_version == 1) {
		print "  e_version is 1, i.e. EV_CURRENT.\n";
	}
	else {
		printf("  e_version is 0x%04X, i.e. not EV_CURRENT, ignoring.\n", $e_version);
	}

	my $e_entry = $elf_data->{'e_entry'} = readValue($elf_fh, 8, UNSIGNED);
	printf("  e_entry is 0x%016X -- this is the virtual address of the program entry point.\n", $e_entry);
	print "    Here, zero means there is no entry point." if (!$e_entry);

	my $e_phoff = $elf_data->{'e_phoff'} = readValue($elf_fh, 8, UNSIGNED);
	printf("  e_phoff is 0x%016X -- this is the file offset, in bytes, of the program header table.\n", $e_phoff);

	my $e_shoff = $elf_data->{'e_shoff'} = readValue($elf_fh, 8, UNSIGNED);
	printf("  e_shoff is 0x%016X -- this is the file offset, in bytes, of the section header table.\n", $e_shoff);

	my $e_flags = $elf_data->{'e_flags'} = readValue($elf_fh, 4, UNSIGNED);
	printf("  e_flags is 0x%08X.\n", $e_flags);

	my $e_ehsize = $elf_data->{'e_ehsize'} = readValue($elf_fh, 2, UNSIGNED);
	printf("  e_ehsize is %d -- this is the size, in bytes, of the ELF header.\n", $e_ehsize);

	my $e_phentsize = $elf_data->{'e_phentsize'} = readValue($elf_fh, 2, UNSIGNED);
	printf("  e_phentsize is %d -- this is the size, in bytes, of a program header table entry.\n", $e_phentsize);

	my $e_phnum = $elf_data->{'e_phnum'} = readValue($elf_fh, 2, UNSIGNED);
	printf("  e_phnum is %d -- this is the number of entries in the program header table.\n", $e_phnum);
	printf("    conclusion: the program header table is %d x %d = %d bytes\n", $e_phentsize, $e_phnum, $e_phentsize * $e_phnum);

	my $e_shentsize = $elf_data->{'e_shentsize'} = readValue($elf_fh, 2, UNSIGNED);
	printf("  e_shentsize is %d -- this is the size, in bytes, of a section header table entry.\n", $e_shentsize);

	my $e_shnum = $elf_data->{'e_shnum'} = readValue($elf_fh, 2, UNSIGNED);
	printf("  e_shnum is %d -- this is the number of entries in the section header table.\n", $e_shnum);
	printf("    conclusion: sections are indexed from 0 (this index is reserved though) to %d.\n", $e_shnum - 1);
	printf("    conclusion: the section header table is %d x %d = %d bytes\n", $e_shentsize, $e_shnum, $e_shentsize * $e_shnum);

	my $e_shstrndx = $elf_data->{'e_shstrndx'} = readValue($elf_fh, 2, UNSIGNED);
	printf("  e_shstrndx is %d -- this is, within the section header table, the index of the section containing the section names.\n", $e_shstrndx);
}

exit(0);
