package LIFinder::Tokenizor::TXL;

use strict;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';

my $txl_default_cmd    = 'txl';
my $txl_program_suffix = '.txl';
my $txl_program_dir    = 'Txl';
my $base_path          = dirname(__FILE__);

sub get_token_hash {
    my ( $file_list_ref, $ext, $digester ) = @_;

    foreach my $item_ref ( @{$file_list_ref} ) {

        # my %item = %{$item_ref}; # This won't work! use ref directly.

        my $path = ${$item_ref}{path};

        my $lines_ref = _run_txl( $path, $ext );
        if ($lines_ref) {
            my @contents     = @$lines_ref;
            my $token_length = scalar(@contents);
            my $str_content  = join( "\n", @contents );
            my $hash         = $digester->( \$str_content );
            ${$item_ref}{hash}   = $hash;
            ${$item_ref}{length} = $token_length;

            # print "$hash | $token_length\n";
        }
        else {
            print STDERR "Hash was not generated for: $path\n";
        }
    }

    return $file_list_ref;
}

sub _run_txl {
    my ( $input_file, $ext ) = @_;

    my $txl_cmd = $txl_default_cmd;
    $txl_cmd = $ENV{TXL} if ( exists $ENV{TXL} );

    die "Cannot find $txl_cmd\n." unless `which $txl_cmd 2>/dev/null`;

    my $txl_src =
      catfile( $base_path, $txl_program_dir, $ext . $txl_program_suffix );

    # print "`$txl_cmd '$input_file' $txl_src 2>/dev/null`\n";
    my @contents = `$txl_cmd '$input_file' $txl_src 2>/dev/null`;

    if ( $? != -1 and $? >> 8 == 0 ) {

        # print @contents;
        chomp @contents;

        return \@contents;
    }
    return undef;
}

1;

__END__
