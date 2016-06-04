package LIFinder::DB;

use strict;
use DBI;
use File::Spec::Functions 'catfile';

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

    my $stmt;
    $stmt = qq(CREATE TABLE IF NOT EXISTS files
           (id INIT, path TEXT, ext TEXT, token_info_id INT, group_id INT, 
           license TEXT, dir_id INT,
           PRIMARY KEY(id)););
    $dbh->do($stmt);
    $stmt = qq(CREATE TABLE IF NOT EXISTS groups
           (id INT, all_same_license INT, none INT, unknow INT,
           PRIMARY KEY(id)););
    $dbh->do($stmt);
    $stmt = qq(CREATE TABLE IF NOT EXISTS token_info
           (id INTEGER PRIMARY KEY AUTOINCREMENT, hash TEXT UNIQUE, 
           length INT, occurance INT););
    $dbh->do($stmt);
    $stmt = qq(CREATE TABLE IF NOT EXISTS dirs
           (id INT, path TEXT,
           PRIMARY KEY(id)););
    $dbh->do($stmt);

    $dbh->commit;

    $self->{dbh} = $dbh;
}

sub do {
    my ($self, $stmt) = @_;

    $self->{dbh}->do($stmt);
}

sub prepare {
    my ($self, $stmt) = @_;

    return $self->{dbh}->prepare($stmt);
}

sub commit {
    my ($self) = @_;

    $self->{dbh}->commit();    
}

sub closedb {
    my ($self) = @_;

    $self->{dbh}->disconnect();
}

1;

__END__