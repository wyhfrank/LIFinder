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

my @step_class = (

    # step 1: list files in specified directories
    'LIFinder::FileLister',

    # step 2: tokenize the files and save the hash value
    #	of the normalized tokens
    'LIFinder::TokenHash',

    # step 3: identify license of files and calculate group metrics
    'LIFinder::LicenseIndentifier',

    # step 4: make report about license inconsistency
    'LIFinder::ReportMaker',
);

sub process {
    my ($params) = @_;

    # only select tokens that occur more than
    $params->{occurrence_threshold} = 2;

    my @step_switch =
      _step_switch( $params->{step_switch}, scalar(@step_class) );

    my $time_cost = 0;

    # step 0: create output dir, initialize database
    $params->{output_dir} = _init_output_dir( $params->{output_root} );

    my $dbm = LIFinder::DBManager->new($params);
    $dbm->createdb()->prepare_all();
    $params->{dbm} = $dbm;

    for ( my $i = 0 ; $i <= $#step_class ; $i++ ) {
        my $step = $step_class[$i];

        if ( $step_switch[$i] ) {

            $time_cost += _execute_step( $step, $params );

        }
        else {
            _skip_step($step);
        }
    }

    report_time_cost( 'Total', $time_cost );

    $dbm->closedb();
}

sub _init_output_dir {
    my $output_root = shift;

    die "Directory does not exist: $output_root\n"
      if !-d $output_root;

    my $output_dir = catfile( $output_root, 'output' );
    mkdir $output_dir;
    return $output_dir;
}

sub _step_switch {
    my ( $exp, $count ) = @_;

    my $sum = 0;
    map { $sum += $_ } split '\+', $exp;

    # say "Step switch sum: $sum";

    my @on_list;
    for ( my $i = 0 ; $i < $count ; $i++ ) {

        my $is_on = $sum & 1;
        push @on_list, $is_on;

        $sum = $sum >> 1;
    }
    return @on_list;
}

sub _execute_step {
    my ( $class_name, $parameter ) = @_;

    my $obj = $class_name->new($parameter);
    die "Class $class_name has no execute()\n"
      unless $obj->can('execute');

    my $old_time = gettimeofday;

    $obj->execute();

    my $time_elapsed = gettimeofday - $old_time;

    my $desc = $obj->can('get_desc') ? $obj->get_desc() : $class_name;

    report_time_cost( $desc, $time_elapsed );

    return $time_elapsed;
}

sub _skip_step {
    my ($class_name) = @_;

    my $desc = $class_name;

    # TODO: how to call class function dynamically
    # eval {
    # 	$desc = &$class_name::get_desc();
    # };

    say $desc . ' skipped.';
}

sub report_time_cost {
    my ( $desc, $time ) = @_;

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

1;    # End of LIFinder
