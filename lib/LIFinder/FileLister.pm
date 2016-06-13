package LIFinder::FileLister;

use 5.010;
use strict;
use File::Find;
use File::Basename;

sub new {
    my ( $class, $args ) = @_;

    my $self = bless( {}, $class );

    die "parameter 'input_dirs_ref' is mandatory"
      unless exists $args->{input_dirs_ref};
    die "parameter 'dbm' is mandatory"        unless exists $args->{dbm};
    die "parameter 'file_types' is mandatory" unless exists $args->{file_types};

    $self->{input_dirs_ref} = $args->{input_dirs_ref};
    $self->{file_types}     = $args->{file_types};
    $self->{dbm}            = $args->{dbm};

    return $self;
}

sub get_desc {
    return "List files";
}

sub execute {
    my ($self) = @_;

    my @types = split /,/, $self->{file_types};
    my @dirs  = @{ $self->{input_dirs_ref} };
    my $dbm   = $self->{dbm};

    foreach my $dir (@dirs) {

        # insert dir data into database
        $dbm->execute( 'i_dir', $dir );

        my @files = @{ _get_files_under( $dir, \@types ) };

        # say "Files under [$dir]:\n" . join "\n", @files;

        for my $f (@files) {

            # $f =~ /\.[^.]+$/; # split path and extension
            # my $base = $`;
            # my $ext = $&;
            my ( $filename, $dir_middle, $suffix ) =
              fileparse( $f, qr/\.[^.]*$/ );

            # insert file data into database
            $dbm->execute( 'i_file', $dir_middle . $filename, $suffix, $dir );
        }
    }

    $dbm->commit();
}

sub _get_files_under {
    my ( $root_dir, $types_ref ) = @_;
    my @types = @{$types_ref};
    my $pattern = '\.(' . join( '|', @types ) . ')$';    # file extension filter

    # print "Extension filter is : $pattern\n";

    my @files;
    find(
        sub {
            return unless -f;
            return unless /$pattern/i;

            my $name = $File::Find::name;

            # TODO: whether dir ends with '/', unify them
            my $file_path = substr $name,
              length $root_dir;    # substract root part
            push @files, $file_path;
        },
        $root_dir
    );

    return \@files;
}

1;

__END__
