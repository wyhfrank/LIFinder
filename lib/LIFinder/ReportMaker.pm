package LIFinder::ReportMaker;

use 5.010;
use strict;
use File::Spec::Functions 'catfile';

sub new {
    my ($class, $args) = @_;

    my $self = bless({}, $class);

    die "parameter 'dbm' is mandatory" unless exists $args->{dbm};
    die "parameter 'output_dir' is mandatory" unless exists $args->{output_dir};

    $self->{dbm} = $args->{dbm};
    $self->{output_dir} = $args->{output_dir};
    $self->{inter_dir} = $args->{inter_dir};
    $self->{num_of_lic_threshold} = exists $args->{num_of_lic_threshold} ?
        $args->{num_of_lic_threshold} : 2;
    $self->{min_token_len} = exists $args->{min_token_len} ?
        $args->{min_token_len} : 50;
    $self->{occurrence_threshold} = exists $args->{occurrence_threshold} ?
        $args->{occurrence_threshold} : 2;

    return $self;
}

sub get_desc {
    return "Report license inconsistencies";
}

sub execute {
    my ($self) = @_;

    my $results = $self->fetch_groups();

    $self->output_results($results);
}

sub fetch_groups {
    my ($self) = @_;

    my @results;

    my $dbm = $self->{dbm};
    my $sep = ';'; # Separator used to concat licenses
    my $group_sth = $dbm->execute('s_group', $sep, 
        $self->{min_token_len}, $self->{occurrence_threshold});

    foreach my $row_ref (@{$group_sth->fetchall_arrayref}) {
        my ($token_id, $licenses, $dir_count) = @$row_ref;

        my ($nol, $non, $nou) = calc_metrics($licenses, $sep);

        # skip groups that contain files under one directory, in inter_dir mode
        next if $self->{inter_dir} and $dir_count <= 1;

        push @results, [$token_id, $nol, $non, $nou, $licenses];
    }
    return \@results;
}

sub calc_metrics {
    my ($licenses_str, $sep) = @_;

    my @licenses = split /$sep/, $licenses_str;

    my $license_count_table = {};

    foreach my $lic (@licenses) {
        my $norm_lic = lc $lic;
        $license_count_table->{$norm_lic}++;
    }

    my $num_of_none = $license_count_table->{none} ? 
        $license_count_table->{none} : 0;
    my $num_of_unknown = $license_count_table->{unknown} ? 
        $license_count_table->{unknown} : 0;

    my $num_of_lic = keys %$license_count_table;
    $num_of_lic += $num_of_unknown - 1 if $num_of_unknown;

    return ($num_of_lic, $num_of_none, $num_of_unknown);
}

sub output_results {
    my ($self, $results) = @_;

    my $fh = $self->create_report_file();
    my @header = qw(TokenID #Licenses #None #Unknown Licenses);
    say $fh join_line(@header);

    foreach my $row_ref (@$results) {

        my $line = join_line(@$row_ref);
        say $fh $line;
    }

    $self->close_report_file();
}

sub join_line {
    return '"'. join('","', @_) . '"';
}

sub create_report_file {
    my ($self) = @_;

    my $group_report = catfile($self->{output_dir}, 'groups.csv');
    open FILE, '>', $group_report;
    $self->{grp_report_fh} = *FILE{IO};
    # $self->{grp_report_fh} = *STDOUT{IO}; # debug
    return $self->{grp_report_fh};
}

sub close_report_file {
    my ($self) = @_;

    close $self->{grp_report_fh};
}



1;

__END__