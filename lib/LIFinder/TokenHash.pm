package LIFinder::TokenHash;

use strict;
use File::Spec::Functions 'catfile';

my $ccfx_default_cmd = 'ccfx';
sub new {
    my ($class, %args) = @_;

    my $self = bless({}, $class);

    die "parameter 'db' is mandatory" unless exists $args{db};
    die "parameter 'file_types' is mandatory" unless exists $args{file_types};
    die "parameter 'output_dir' is mandatory" unless exists $args{output_dir};

    $self->{db} = $args{db};
    $self->{file_types} = $args{file_types};
    $self->{output_dir} = $args{output_dir};

    return $self;
}

sub execute {
    my ($self) = @_;

    my $db = $self->{db};
    my @types = split /,/, $self->{file_types};
    my @exts = map { '.' . $_ } @types;

    my $select_file = q(SELECT dirs.path, files.path FROM
        files, dirs WHERE files.dir_id = dirs.id AND files.ext = ?;);
    my $sth = $db->prepare($select_file);

    my %file_table = ();

    foreach my $ext (@exts) {
        my @file_list;
        $sth->execute($ext) or die $DBI::errstr;

        while (my @row = $sth->fetchrow_array()) {
            my ($dir, $path) = @row;
            my $full_path = join('', @row, $ext);
            print "$full_path\n";
            push @file_list, $full_path;
        }
        $file_table{$ext} = \@file_list;

        # TODO: ccfx bug: it can only read the list file under current dir
        my $tmp_file = catfile('.', $ext . '_list');
        # my $tmp_file = catfile($self->{output_dir}, $ext . '_list');

        open FILE, '>', $tmp_file or die "Cannot write file: $tmp_file\n";
        print FILE join("\n", @file_list);
        close FILE;

        _gen_tokens($tmp_file, $ext);

    }
    $sth->finish();
}

sub _gen_tokens {
    my ($list, $ext) = @_;

    my $ccfx_cmd = $ccfx_default_cmd;
    $ccfx_cmd = $ENV{CCFX} if (exists $ENV{CCFX});

    my $ccfx_type = _determine_type($ext);
    # print "$ccfx_cmd d $ccfx_type -p -i $list\n";
    system($ccfx_cmd, 'd', $ccfx_type, '-p', '-i', $list);

}

sub _determine_type {
    my $ext = shift;

    # remove leading dot, convert to lowercase
    $ext = substr($ext, 1) if (substr($ext, 0, 1) eq '.');
    $ext = lc $ext;

    my $ccfx_type = '';

    if ($ext eq 'c' || $ext eq 'ansic' || $ext eq 'c++' || $ext eq 'cpp') { 
        $ccfx_type = 'cpp'; 
    } elsif ($ext eq 'java') {
        $ccfx_type = 'java';
    } else {
        die "Unsupported source extension: $ext";
    }
    return $ccfx_type;
}

1;

__END__