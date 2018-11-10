#!/usr/bin/perl

use Socket;
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

sub get_work($)
{
	my ($dbh) = @_;
	my @temp;
	my $sth = $dbh->prepare("select hostname from hostname where live is true and track is true");
	if($sth->execute)
	{
		while(my $row = $sth->fetchrow_hashref())
		{
			print $row->{hostname} . "\n";
			push(@temp,$row->{hostname});
		}
	}
	$sth->finish();
	return @temp;
}

sub check_if_present($$$)
{
	my ($dbh,$ip,$hostname) = @_;
	#print "Checking if $ip is Present\n";
	my $sth = $dbh->prepare("select count(*) as t from node where ip = '$ip' and hostname = '$hostname'");
	if($sth->execute())
	{
		my $row = $sth->fetchrow_hashref();
		if($row->{t})
		{
			$sth->finish();
			return 0;
		}
		else
		{
			$sth->finish();
			return 1;
		}
	}
	else
	{
		die $sth->errstr;
	}
}

sub insert_node($$$)
{
	my ($dbh,$ip,$hostname) = @_;
	#print "$hostname\t $ip\n";
	if(check_if_present($dbh,$ip,$hostname))
	{
	print "$ip\t$hostname Inserted\n";
	my $time = time();
	my $sth = $dbh->prepare("insert into node (ip,hostname,time) values ('$ip','$hostname',$time)");
	$sth->execute();
		$sth->finish();
	}
	else
	{
		#print "$ip\t$hostname not inserted\n";
	}
}

sub update_hostname_status($$)
{
	my($dbh,$hostname) = @_;
	my $sth = $dbh->prepare("update hostname set live = false where hostname = '$hostname'");
	$sth->execute or die $sth->errstr;
}

sub recheck_status($)
{
	my ($dbh) = @_;
	my @temp;
	print "Checking Domains that have been set to inactive\n";
	my $sth = $dbh->prepare("select hostname from hostname where live is false and track is true");
	if($sth->execute)
	{
		while(my $row = $sth->fetchrow_hashref())
		{
			my $st = scalar gethostbyname ($row->{hostname});
			if($st)
			{
				push(@temp,$row->{hostname});
			}
		}
		$sth->finish();
	}
	else
	{
	die $sth->errstr;
	}
	$sth->finish();
	foreach my $host(@temp)
	{
		my $sth = $dbh->prepare("update hostname set live = true where hostname = '$host'");
		$sth->execute or die $sth->errstr;
		$sth->finish();
	}
}

sub track_hosts($@)
{
	my ($dbh, @hosts) = @_;
	my $have_work =1;my $inc =0;
	while(1)
	{
		foreach my $host(@hosts)
		{
			my $st = scalar gethostbyname($host);
			if($st)
			{
			my $address = inet_ntoa($st);
			insert_node($dbh,$address,$host);
			}
			else
			{
			update_hostname_status($dbh,$host);	
			}
		}	
		$inc++;
		if($inc == 200)
		{
			recheck_status($dbh);
			print "Getting New Work\n";
			@hosts = get_work($dbh);
			print scalar @hosts ."\n";
			$inc =0;
		}
	}
}

sub main()
{
	my $dbh = connect_db();
	my @hosts = get_work($dbh);
	track_hosts($dbh,@hosts);

}

if(-e '/var/lock/flux.lock')
{
	print "Already Running\n";
	exit(0);
}

`touch /var/lock/flux.lock`;

main();

unlink "/varlock/flux.lock";
exit(0);
