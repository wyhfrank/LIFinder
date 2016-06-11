package LIFinder::LicenseIndentifier;

use 5.010;
use strict;
use File::Find;
use File::Basename;

my $ninka_default_cmd = 'ninka';

sub new {
    my ($class, %args) = @_;

    my $self = bless({}, $class);

    die "parameter 'dbm' is mandatory" unless exists $args{dbm};

    $self->{dbm} = $args{dbm};
    $self->{occurance_threshold} = exists $args{occurance_threshold} ?
        $args{occurance_threshold} : 2;

    $self->{ninka_cmd} = $ENV{NINKA} ?
        $ENV{NINKA} : $ninka_default_cmd;

    return $self;
}

sub execute {
    my ($self) = @_;

    my $dbm = $self->{dbm};

    my $token_sth = $dbm->execute('s_token', $self->{occurance_threshold});

    while (my @token_row = $token_sth->fetchrow_array) {
        my ($token_id) = @token_row;
        my $file_sth = $dbm->execute('s_file_with_token_id', $token_id);

        while (my @file_row = $file_sth->fetchrow_array) {
            my ($file_id, $dir_path, $file_path, $file_ext) = @file_row;
            my $full_path = join('', $dir_path, $file_path, $file_ext);

            # detect license
            my $cmd = $self->{ninka_cmd} . " '$full_path' 2>/dev/null";
            my $ninka_result = `$cmd`; chomp $ninka_result;

            my (undef, $license) = split /;/, $ninka_result;

            say $license;
            $dbm->execute('u_file_license', $license, $file_id);
        }
        $dbm->commit();
    }

}


1;

__END__