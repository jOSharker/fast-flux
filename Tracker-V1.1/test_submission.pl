#!/usr/bin/perl
use DBI;
use Socket;

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

sub get_work($)
{
	my ($dbh) = @_;
	my @temp;
	my $sth = $dbh->prepare("select hostname from input");
	if($sth->execute)
	{
		while(my $row = $sth->fetchrow_hashref())
		{
			push(@temp, $row->{hostname});
		}
	}
	else
	{
		die $sth->errstr;
	}
	return @temp;
}

sub remove_host($$)
{
	my ($dbh,$host) = @_;
	my $sth = $dbh->prepare("delete from input where hostname = '$host'");
	$sth->execute or die $sth->errstr;
}

sub insert_host($$)
{
	my ($dbh,$host) = @_;
	my $sth = $dbh->prepare("insert into hostname (hostname,submit_date,last_seen,live,track) values ('$host',current_date,current_date,true,true)");
	$sth->execute or warn $sth->errstr;
}

sub main()
{
	my $dbh = connect_db();
	my $passmark = 10;
	my @hosts;
		if($dbh)
		{
			print "Looking for new work to do\n";
			@hosts = get_work($dbh);
			foreach my $host(@hosts)
			{
				print "Testing Host $host\n";
				my $distinct_cnt = 0;
				my %t;
				my $test_time = time();
				my $test_period = $test_time + 5;
				#so either add to the table after 10 distinct hosts, OR after 2 mins of testing.
			while(($distinct_cnt < $passmark) & ($test_time < $test_period))
			{
				my $st = scalar gethostbyname($host);
				if($st)
				{
					$address = inet_ntoa($st);
				#	print $address ."\n";
					$t{$address} =0;
					$test_time = time();
				}
				else
				{
					#host is no longer live.
					print "Host is no longer Live\n";
					$test_time = $test_period + 1;
					remove_host($dbh,$host);
				}
				$distinct_cnt = keys(%t);
			}

			print $distinct_cnt . " Distinct cnt\n";
			if($distinct_cnt >=$passmark)
				{
					print "Inserting Host $host as its classified as on a fast-flux network\n";
					insert_host($dbh,$host);
					print "Removing Host $host from the input Table\n";
					remove_host($dbh,$host);
				}
				else
				{
					print "Removing Host $host from the input Table\n";
					remove_host($dbh,$host);
				}
			}			
		}
	$dbh->disconnect();
}

main();
exit(0);



