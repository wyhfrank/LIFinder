package LIFinder::Tokenizor::CCFinderX;

use strict;
use File::Spec::Functions 'catfile';

my $ccfx_default_cmd = 'ccfx';
my $ccfx_prep_suffix = '*.ccfxprep';

sub get_token_hash {
    my ($file_list_ref, $ext, $digester) = @_;

    my $tmp_list = _make_list($file_list_ref, $ext);
    _run_ccfx($tmp_list, $ext);

    foreach my $item_ref (@{ $file_list_ref}) {
        # my %item = %{$item_ref}; # This won't work! use ref directly.

        my $path = ${$item_ref}{path};

        my $lines_ref = _read_tokens($path);
        if ($lines_ref) {
            my @contents = @$lines_ref;
            my $token_length = scalar(@contents);
            my $hash = $digester->(_normalize_token(join("\n", @contents)));
            ${$item_ref}{hash} = $hash;
            ${$item_ref}{length} = $token_length;

            # print "$hash | $token_length\n";
        } else {
            print STDERR "Hash was not generated for: $path\n";
        }
    }

    return $file_list_ref;
}

sub _run_ccfx {
    my ($tmp_list, $ext) = @_;

    my $ccfx_cmd = $ccfx_default_cmd;
    $ccfx_cmd = $ENV{CCFX} if (exists $ENV{CCFX});

    my $ccfx_type = _determine_type($ext);
    # print "$ccfx_cmd d $ccfx_type -p -i $tmp_list\n";
    system($ccfx_cmd, 'd', $ccfx_type, '-p', '-i', $tmp_list);
}

sub _make_list {
    my ($file_list_ref, $ext) = @_;
    my @file_list = @{ $file_list_ref };

    # TODO: ccfx bug: it can only read the list file under current dir
    #   Maybe because I'm using its Windows version via Cygwin.
    my $tmp_file = $ext . '_list';
    # my $tmp_file = catfile($self->{output_dir}, $ext . '_list');

    open FILE, '>', $tmp_file or die "Cannot write file: $tmp_file\n";
    print FILE join("\n", map { ${$_}{path} } @file_list);
    close FILE;

    return $tmp_file;
}

sub _determine_type {
    my $ext = shift;

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

sub _read_tokens {
    my $src_file = shift;
    my @prep_files = glob($src_file . $ccfx_prep_suffix);

    my $prep_file = '';
    foreach my $pf (@prep_files) {
        $prep_file = $pf if $pf gt $prep_file;
    }
    # print "found prep file: $prep_file\n";

    return unless (-f $prep_file);
    open FILE, '<', $prep_file or die "Cannot read token file: $prep_file\n";
    my @lines = <FILE>;
    close FILE;

    return \@lines;
}

sub _normalize_token {
    my $tokens = shift;

    $tokens =~ s/^[^+]+[^ \t]+[ \t]+//mg; # 1. Remove leading line number etc.
    $tokens =~ s/\|.*$//mg; # 2. Remove identifier names
    # print "$tokens\n";

    return \$tokens;
}


1;

__END__