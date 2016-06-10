package LIFinder::FileLister;

use strict;
use File::Find;
use File::Basename;

sub new {
    my ($class, %args) = @_;

    my $self = bless({}, $class);

    die "parameter 'input_dirs_ref' is mandatory" unless exists $args{input_dirs_ref};
    die "parameter 'dbm' is mandatory" unless exists $args{dbm};
    die "parameter 'file_types' is mandatory" unless exists $args{file_types};

    $self->{input_dirs_ref} = $args{input_dirs_ref};
    $self->{file_types} = $args{file_types};
    $self->{dbm} = $args{dbm};

    return $self;
}

sub execute {
    my ($self) = @_;

    my @types = split /,/, $self->{file_types};
    my @dirs = @{ $self->{input_dirs_ref} };
    my $dbm = $self->{dbm};

    my $file_id = 0;
    for (my $i = 0; $i < scalar(@dirs); $i++) {

        # insert dir data into database
        $dbm->execute('i_dir', $i, $dirs[$i]);

        my @files = @{ _get_files_under($dirs[$i], \@types) };
        for my $f (@files) {
            # $f =~ /\.[^.]+$/; # split path and extension
            # my $base = $`;
            # my $ext = $&;
            my ($filename, $dirs, $suffix) = fileparse($f, qr/\.[^.]*$/);

            # insert file data into database
            $dbm->execute('i_file', $file_id, $dirs . $filename, $suffix, $i);

            $file_id++;
        }
    }

    $dbm->commit();
}

sub _get_files_under {
    my ($root_dir, $types_ref) = @_;
    my @types = @{$types_ref};
    my $pattern = '(' . join('|', @types) . ')$'; # file extension filter

    # print "Extension filter is : $pattern\n";

    my @files;
    find(sub {
        return unless -f;
        return unless /$pattern/i;
        my $name = $File::Find::name;
        my $file_path = substr $name, length $root_dir; # substract root part
        push @files, $file_path;
    }, $root_dir);

    return \@files;
}

1;

__END__