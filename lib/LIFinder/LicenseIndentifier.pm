package LIFinder::LicenseIndentifier;

use 5.010;
use strict;

my $ninka_default_cmd = 'ninka';

sub new {
    my ($class, $args) = @_;

    my $self = bless({}, $class);

    die "parameter 'dbm' is mandatory" unless exists $args->{dbm};

    $self->{dbm} = $args->{dbm};
    $self->{occurrence_threshold} = exists $args->{occurrence_threshold} ?
        $args->{occurrence_threshold} : 2;

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

    my $token_sth = $dbm->execute('s_token', $self->{occurrence_threshold});

    # for each token that occurred more than the threshold
    while (my @token_row = $token_sth->fetchrow_array) {
        my ($token_id) = @token_row;
        my $file_sth = $dbm->execute('s_file_by_token_id', $token_id);

        my $file_license_map = {};

        # identify the licenses of the files with this token
        while (my @file_row = $file_sth->fetchrow_array) {
            my ($file_id, $license, $dir_path, $file_path, $file_ext) = @file_row;
            my $full_path = join('', $dir_path, $file_path, $file_ext);

            unless ($license) {
                # identify license
                my $cmd = $self->{ninka_cmd} . " '$full_path' 2>/dev/null";
                my $ninka_result = `$cmd`; chomp $ninka_result;

                (undef, $license) = split /;/, $ninka_result;

                $dbm->execute('u_file_license', $license, $file_id);
            }
        }

        $dbm->commit();
    }
}


1;

__END__
