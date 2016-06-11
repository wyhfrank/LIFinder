package LIFinder::DBManager;

use strict;
use DBI;
use File::Spec::Functions 'catfile';


my @creat_list = (
    # IF, file: /dir/to/file/name.cpp
    # AND dir is: /dir
    # THEN file path: /to/file/name
    # dir path: /dir
    # ext: .cpp
	q{CREATE TABLE IF NOT EXISTS files
		(path TEXT, ext TEXT, token_info_id INT, group_id INT, 
		license TEXT, dir_id INT,
        FOREIGN KEY(token_info_id) REFERENCES token_info(oid),
        FOREIGN KEY(group_id) REFERENCES groups(oid),
        FOREIGN KEY(dir_id) REFERENCES dirs(oid),
		PRIMARY KEY(path, ext, dir_id));},
	q{CREATE TABLE IF NOT EXISTS groups
		(token_info_id INT, all_same_license INT, none INT, unknow INT,
        FOREIGN KEY(token_info_id) REFERENCES token_info(oid)
		);},
	q{CREATE TABLE IF NOT EXISTS token_info
		(hash TEXT PRIMARY KEY, 
		length INT, occurance INT);},
	q{CREATE TABLE IF NOT EXISTS dirs
		(path TEXT PRIMARY KEY
		);},
	);

my %sth_table = (
    # dir_path
    i_dir => q{INSERT OR IGNORE INTO dirs (path) VALUES (?);},
    # file_path, ext, dir_path
    i_file => q{INSERT OR IGNORE INTO files (path, ext, dir_id) 
            VALUES (?, ?, (SELECT oid FROM dirs WHERE path = ?));},

    # file_ext => (file_id, dir_path, file_path)
    s_file => q{SELECT files.oid, dirs.path, files.path FROM
        files INNER JOIN dirs ON files.dir_id = dirs.oid WHERE files.ext = ?;},
    # hash, length
    i_token => q{INSERT OR IGNORE INTO token_info 
        (hash, length, occurance) VALUES (?, ?, 0);},
    # hash
    u_token => q{UPDATE token_info SET occurance = occurance+1 
        WHERE hash = ?;},
    # hash, file_id
    u_file => q{UPDATE files SET token_info_id = 
        (SELECT oid FROM token_info WHERE hash = ?) WHERE oid = ?;},

    # occurance => (token_info_id)
    s_token => q{SELECT oid FROM token_info WHERE occurance >= ?;},
    # token_id => (file_id, dir_path, file_path, file_ext)
    s_file_with_token_id => q{SELECT f.oid, d.path, f.path, f.ext FROM files f 
        INNER JOIN dirs d ON f.dir_id = d.oid WHERE f.token_info_id = ?;},
    # license, file_id
    u_file_license => q{UPDATE files SET license = ?
        WHERE oid = ?;},
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