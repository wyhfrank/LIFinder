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
    $self->{num_of_lic_threshold} = exists $args{num_of_lic_threshold} ?
        $args{num_of_lic_threshold} : 1;

    return $self;
}

sub execute {
    my ($self) = @_;

    my $dbm = $self->{dbm};

    my $fh = $self->create_report_file();

    my $lic_sep = ';'; # Seporator between licenses
    my $group_sth = $dbm->execute('s_group', $lic_sep, $self->{num_of_lic_threshold});

    my @header = qw(GroupID #Licenses #None #Unkown Licenses);
    say $fh join_line(@header);

    while (my @group_row = $group_sth->fetchrow_array) {
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
    return $self->{grp_report_fh};
}

sub close_report_file {
    my ($self) = @_;

    close $self->{grp_report_fh};
}



1;

__END__