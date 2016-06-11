package LIFinder::ReportMaker;

use 5.010;
use strict;
use File::Spec::Functions 'catfile';

sub new {
    my ($class, %args) = @_;

    my $self = bless({}, $class);

    die "parameter 'dbm' is mandatory" unless exists $args{dbm};
    die "parameter 'output_dir' is mandatory" unless exists $args{output_dir};

    $self->{dbm} = $args{dbm};
    $self->{output_dir} = $args{output_dir};
    $self->{inter_dir} = $args{inter_dir};
    $self->{num_of_lic_threshold} = exists $args{num_of_lic_threshold} ?
        $args{num_of_lic_threshold} : 1;

    return $self;
}

sub get_desc {
    return "Report license inconsistencies";
}

sub execute {
    my ($self) = @_;

    my $dbm = $self->{dbm};

    my $fh = $self->create_report_file();

    my $sep = ';'; # Seporator used to concat licenses
    my $group_sth = $dbm->execute('s_group', $sep, $self->{num_of_lic_threshold});

    my @header = qw(GroupID #Licenses #None #Unkown Licenses);
    say $fh join_line(@header);

    while (my @group_row = $group_sth->fetchrow_array) {

        # skip groups that contain files under one directory, in inter_dir mode
        my $dir_count = pop @group_row;
        next if $self->{inter_dir} and $dir_count <= 1;

        my $line = join_line(@group_row);
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