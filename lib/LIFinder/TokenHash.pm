package LIFinder::TokenHash;

use strict;
use Digest::MD5 qw(md5_hex);
# use Digest::SHA1 qw(sha1 sha1_hex);
use LIFinder::Tokenizor::CCFinderX;
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

    my $select_file = q(SELECT files.id, dirs.path, files.path FROM
        files, dirs WHERE files.dir_id = dirs.id AND files.ext = ?;);
    my $insert_token = q(INSERT OR IGNORE INTO token_info 
        (hash, length, occurance) VALUES (?, ?, 0););
    my $update_token = q(UPDATE token_info SET occurance = occurance+1 
        WHERE hash = ?;);
    my $update_file = q(UPDATE files SET token_info_id = 
        (SELECT id FROM token_info WHERE hash=?) WHERE id = ?;);

    my $sel_sth = $db->prepare($select_file);
    my $ins_tkn_sth = $db->prepare($insert_token);
    my $upd_tkn_sth = $db->prepare($update_token);
    my $upd_file_sth = $db->prepare($update_file);

    my $token_info_id = 0;
    foreach my $ext (@exts) {
        my @file_list;

        $sel_sth->execute($ext) or die $DBI::errstr;

        while (my @row = $sel_sth->fetchrow_array()) {
            my ($f_id, $dir, $path) = @row;
            my $full_path = join('', $dir, $path, $ext);

            # print "$full_path\n";
            my %file_item = (
                id => $f_id,
                path => $full_path,
                );
            push @file_list, \%file_item;
        }

        # remove leading dot, convert to lowercase
        my $normalized_ext = substr($ext, 1) if (substr($ext, 0, 1) eq '.');
        $normalized_ext = lc $normalized_ext;

        LIFinder::Tokenizor::CCFinderX::get_token_hash(\@file_list, 
            $normalized_ext, \&_digester);

        foreach my $file_item_ref (@file_list) {
            my %item = %{$file_item_ref};
            $ins_tkn_sth->execute($item{hash}, $item{length});
            $upd_tkn_sth->execute($item{hash});
            $upd_file_sth->execute($item{hash}, $item{id})
        }

    }
    $sel_sth->finish();
    $ins_tkn_sth->finish();
    $upd_tkn_sth->finish();
    $upd_file_sth->finish();
    $db->commit();
}

sub _digester {
    my $str = ${+shift}; # dereference
    return md5_hex($str);
    # return sha1_hex($str);
}


1;

__END__