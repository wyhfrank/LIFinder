package LIFinder::TokenHash;

use strict;

sub new {
    my ($class, %args) = @_;

    my $self = bless({}, $class);

    die "parameter 'db' is mandatory" unless exists $args{db};
    die "parameter 'file_types' is mandatory" unless exists $args{file_types};

    $self->{db} = $args{db};
    $self->{file_types} = $args{file_types};

    return $self;
}

sub execute {
    my ($self) = @_;

    my $db = $self->{db};
    my @types = split /,/, $self->{file_types};
    my @exts = map { '.' . $_ } @types;

    my $select_file = q(SELECT dirs.path, files.path, files.ext FROM
        files, dirs WHERE files.dir_id = dirs.id AND files.ext = ?;);
    my $sth = $db->prepare($select_file);

    my %file_table = ();

    foreach my $ext (@exts) {
        my @file_list;
        $sth->execute($ext) or die $DBI::errstr;
        while (my @row = $sth->fetchrow_array()) {
            my ($dir, $path, $ext) = @row;
            my $full_path = join('', @row);
            print "$full_path\n";
            push @file_list, $full_path;
            $file_table{$ext} = \@file_list;
        }
    }
    $sth->finish();
}



1;

__END__