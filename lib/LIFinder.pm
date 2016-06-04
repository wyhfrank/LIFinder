package LIFinder;

use strict;
use warnings;
use LIFinder::DB;
use LIFinder::FileLister;
use LIFinder::TokenHash;
use File::Spec::Functions 'catfile';

=head1 NAME

LIFinder - License Inconsistency Finder

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use LIFinder;

    my $foo = LIFinder->new();
    ...

=cut

sub process {
	my ($input_dirs_ref, $output_dir, $file_types) = @_;
	my @input_dirs = @{ $input_dirs_ref };

	my %common_parameters = ();

	# step 0: create output dir, initialize database
	$output_dir = _init_output_dir($output_dir);
	my %parameter_step0 = (%common_parameters, 
		output_dir => $output_dir);
	my $db = LIFinder::DB->new(%parameter_step0);

	$db->createdb();
	$common_parameters{db} = $db;

	# step 1: list files in specified directories
	my %parameter_step1 = (%common_parameters, 
		input_dirs_ref => $input_dirs_ref,
		file_types => $file_types);
	LIFinder::FileLister->new(%parameter_step1)->execute();

	# step 2: tokenize the files and save the hash value
	#	of the normalized tokens
	my %parameter_step2 = (%common_parameters,
		file_types => $file_types,
		output_dir => $output_dir);
	LIFinder::TokenHash->new(%parameter_step2)->execute();

	$db->closedb();
}

sub _init_output_dir {
	my $output_root = shift;

	die "Directory does not exist: $output_root\n"
		if !-d $output_root;

	my $output_dir = catfile($output_root, 'output');
	mkdir $output_dir;
	return $output_dir;
}


=head1 AUTHOR

Yuhao Wu, C<< <wyhfrank at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Yuhao Wu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA


=cut

1; # End of LIFinder
