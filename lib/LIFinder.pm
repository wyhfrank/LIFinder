package LIFinder;

use 5.010;
use strict;
use warnings;
use LIFinder::DBManager;
use LIFinder::FileLister;
use LIFinder::TokenHash;
use LIFinder::LicenseIndentifier;
use LIFinder::ReportMaker;

use File::Spec::Functions 'catfile';
use Time::HiRes qw(gettimeofday);

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
	my ($input_dirs_ref, $output_dir, $file_types, 
		$inter_dir, $min_token_len) = @_;

	my @input_dirs = @{ $input_dirs_ref };

	# only select tokens that occur more than
	my $occurance_threshold = 2;

	my $time_cost = 0;
	my %common_parameters = ();

	# step 0: create output dir, initialize database
	$output_dir = _init_output_dir($output_dir);
	my %parameter_step0 = (%common_parameters, 
		output_dir => $output_dir);

	my $dbm = LIFinder::DBManager->new(%parameter_step0);

	$dbm->createdb()->prepare_all();
	$common_parameters{dbm} = $dbm;

	# step 1: list files in specified directories
	my %parameter_step1 = (%common_parameters, 
		input_dirs_ref => $input_dirs_ref,
		file_types => $file_types);
	$time_cost += _execute_step('LIFinder::FileLister', \%parameter_step1);

	# step 2: tokenize the files and save the hash value
	#	of the normalized tokens
	my %parameter_step2 = (%common_parameters,
		file_types => $file_types,
		output_dir => $output_dir);
	$time_cost += _execute_step('LIFinder::TokenHash', \%parameter_step2);


	# step 3: identify license of files and calculate group metrics
	my %parameter_step3 = (%common_parameters,
		occurance_threshold => $occurance_threshold);
	$time_cost += _execute_step('LIFinder::LicenseIndentifier', \%parameter_step3);

	# step 4: make report about license inconsistency
	my %parameter_step4 = (%common_parameters,
		output_dir => $output_dir,
		inter_dir => $inter_dir,
		min_token_len => $min_token_len,
		);
	$time_cost += _execute_step('LIFinder::ReportMaker', \%parameter_step4);

	report_time_cost('Total', $time_cost);

	$dbm->closedb();
}

sub _init_output_dir {
	my $output_root = shift;

	die "Directory does not exist: $output_root\n"
		if !-d $output_root;

	my $output_dir = catfile($output_root, 'output');
	mkdir $output_dir;
	return $output_dir;
}

sub _execute_step {
	my ($class_name, $parameter) = @_;

	my $obj = $class_name->new(%$parameter);
	die "Class $class_name has no execute()\n" 
		unless $obj->can('execute');

	my $old_time = gettimeofday;
	
	$obj->execute();
	
	my $time_elapsed = gettimeofday - $old_time;

	my $desc = $obj->can('get_desc')?
		$obj->get_desc() : $class_name;

	report_time_cost($desc, $time_elapsed);

	return $time_elapsed;
}

sub report_time_cost {
	my ($desc, $time) = @_;

	say sprintf "%s: %.3fs", $desc, $time;	
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
