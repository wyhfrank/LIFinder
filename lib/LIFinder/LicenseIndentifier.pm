package LIFinder::LicenseIndentifier;

use 5.010;
use strict;

my $ninka_default_cmd = 'ninka';

sub new {
    my ($class, %args) = @_;

    my $self = bless({}, $class);

    die "parameter 'dbm' is mandatory" unless exists $args{dbm};

    $self->{dbm} = $args{dbm};
    $self->{occurance_threshold} = exists $args{occurance_threshold} ?
        $args{occurance_threshold} : 2;

    my $ninka_cmd = $ENV{NINKA} ?
        $ENV{NINKA} : $ninka_default_cmd;
    
    die "Cannot find $ninka_cmd\n" unless `which $ninka_cmd 2>/dev/null`;
    
    $self->{ninka_cmd} = $ninka_cmd;

    return $self;
}

sub get_desc {
    return "Identify licenses";
}

sub execute {
    my ($self) = @_;

    my $dbm = $self->{dbm};

    my $token_sth = $dbm->execute('s_token', $self->{occurance_threshold});

    # for each token that occurred more than the threshold
    while (my @token_row = $token_sth->fetchrow_array) {
        my ($token_id) = @token_row;
        my $file_sth = $dbm->execute('s_file_with_token_id', $token_id);

        my $file_license_map = {};

        # identify the licenses of the files with this token
        while (my @file_row = $file_sth->fetchrow_array) {
            my ($file_id, $dir_path, $file_path, $file_ext) = @file_row;
            my $full_path = join('', $dir_path, $file_path, $file_ext);

            # identify license
            my $cmd = $self->{ninka_cmd} . " '$full_path' 2>/dev/null";
            my $ninka_result = `$cmd`; chomp $ninka_result;

            my (undef, $license) = split /;/, $ninka_result;

            $file_license_map->{$file_id} = $license;
        }

        my ($nol, $non, $nou) = calc_metrics($file_license_map);
        $dbm->execute('i_group', $token_id, $nol, $non, $nou);
        # say "i_group, $token_id, $nol, $non, $nou";

        foreach my $file_id (keys %$file_license_map) {

            $dbm->execute('u_file_license', $file_license_map->{$file_id}, 
                $file_id, $file_id);
        }

        $dbm->commit();
    }

}

sub calc_metrics {
    my ($file_license_map) = @_;

    my $license_count_table = {};

    foreach my $file_id (keys %$file_license_map) {
        my $norm_lic = lc $file_license_map->{$file_id};
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


1;

__END__
