#!/usr/bin/perl

# you may want to change above to /opt/loca/bin/perl
# if you are using perl from Macports on Mac OS X
use ZOOM;

my $host = shift;
my $port = shift;
my $recordId = shift;
my $record_path = shift;
my $action = shift;
my $database = shift;
my $username = shift;
my $password = shift;


my $record;
open(FILE, $record_path) || die("Could not open file!");
    undef $/;
    $record=<FILE>;
close(FILE);

eval {
    $conn = new ZOOM::Connection($host, $port, user => $username, password => $password );
    # $conn->option(preferredRecordSyntax => "xml");

    if ($database) {
        $conn->option(databaseName => $database);
    }

    $p = $conn->package();
    $p->option(action => $action);
    $p->option(recordIdOpaque => $recordId);
    $p->option(record => $record);
    $p->send("update");
    $p->send("commit");
    $p->destroy();

};
if ($@ && $@->isa("ZOOM::Exception")) {
    print "Oops!  ", $@->message(), "\n";
    print $@->code();
}
