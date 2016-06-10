package LIFinder::DBManager;

use strict;
use DBI;
use File::Spec::Functions 'catfile';


my @creat_list = (
	qq(CREATE TABLE IF NOT EXISTS files
		(id INT, path TEXT, ext TEXT, token_info_id INT, group_id INT, 
		license TEXT, dir_id INT,
		PRIMARY KEY(id));),
	qq(CREATE TABLE IF NOT EXISTS groups
		(id INT, all_same_license INT, none INT, unknow INT,
		PRIMARY KEY(id));),
	qq(CREATE TABLE IF NOT EXISTS token_info
		(id INT PRIMARY KEY, hash TEXT UNIQUE, 
		length INT, occurance INT);),
	qq(CREATE TABLE IF NOT EXISTS dirs
		(id INT, path TEXT,
		PRIMARY KEY(id));),
	);

my %sth_table = (
    i_file => q(INSERT INTO files (id, path, ext, dir_id) 
                    VALUES (?, ?, ?, ?);),
    i_dir => q(INSERT INTO dirs (id, path) VALUES (?, ?);),

    s_file => q(SELECT files.id, dirs.path, files.path FROM
        files, dirs WHERE files.dir_id = dirs.id AND files.ext = ?;),
    i_token => q(INSERT OR IGNORE INTO token_info 
        (hash, length, occurance) VALUES (?, ?, 0);),
    u_token => q(UPDATE token_info SET occurance = occurance+1 
        WHERE hash = ?;),
    u_file => q(UPDATE files SET token_info_id = 
        (SELECT id FROM token_info WHERE hash=?) WHERE id = ?;),
    );

sub new {
    my ($class, %args) = @_;

    my $self = bless({}, $class);

    die "parameter 'output_dir' is mandatory" unless exists $args{output_dir};

    $self->{output_dir} = $args{output_dir};

    return $self;
}

sub createdb {
    my ($self) = @_;

    if (defined $self->{dbh}) {
        return 0;
    }

    my $db_name = 'result.db';
    my $database = catfile($self->{output_dir}, $db_name);

    # TODO: add option for deleting
    unlink $database if -f $database;

    my $driver   = "SQLite";
    my $dsn = "DBI:$driver:dbname=$database";
    my $userid = "";
    my $password = "";
    my $dbh = DBI->connect($dsn, $userid, $password,
        { AutoCommit => 0, RaiseError => 1 }) or die $DBI::errstr;

    foreach my $stmt (@creat_list) {
        $dbh->do($stmt);
    }

    $dbh->commit;

    $self->{dbh} = $dbh;
    return $self;
}

sub do {
    my ($self, $stmt) = @_;

    $self->{dbh}->do($stmt);
}

sub prepare_all {
    my ($self) = @_;

    foreach my $name (keys %sth_table) {
      my $sth = $self->{dbh}->prepare($sth_table{$name});
      $self->{sth}->{$name} = $sth;
    }
    return $self;
}

sub execute {
    my ($self, $sth_name, @arg) = @_;

    my $sth = $self->{sth}->{$sth_name};

    if ($sth) {
      $sth->execute(@arg);
      return $sth;
    } else {
      die "No sth found: $sth_name\n";
    }
    return undef;
}

sub commit {
    my ($self) = @_;

    $self->{dbh}->commit();    
}

sub closedb {
    my ($self) = @_;

    foreach my $sth_name (keys %sth_table) {
      my $sth = $self->{sth}->{$sth_name};
      if ($sth) {
          $sth->finish;
        } else {
          print STDERR "No sth found: $sth_name\n";
        }
    }

    $self->{dbh}->disconnect();
}

1;

__END__