#!/usr/bin/perl

use DBI;

sub connect_db()
{
        my $dbname = 'fast_flux';
		my $host = '127.0.0.1';
		my $port = '5432';
        my $username = '';my $password = '';

        my $dbh = DBI->connect("dbi:PgPP:dbname=$dbname;host=$host;port=$port",
        $username,$password,{RaiseError => 0});
        $dbh or die "Database Error\n";
        return $dbh;
}

sub add_nodes($@)
{
	my ($dbh,@array) = @_;
	foreach my $host(@array)
	{
		print "$host\t";
		my $sth = $dbh->prepare("insert into input (hostname,date_submit) values ('$host',current_date)");
		if($sth->execute)
		{
			print " Inserted\n";
		}else{print " already present\n";}
		$sth->finish();
	}
}

sub main()
{
	my $dbh = connect_db();
	my @input;
	while(<>)
	{
		chomp $_;
		push(@input,$_);
	}
	add_nodes($dbh,@input);
	$dbh->disconnect();
}


main();
exit(0);
