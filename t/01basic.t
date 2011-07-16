use Test::More tests => 4;
use DateTimeX::Auto ':auto';

is(ref('2000-01-01'), 'DateTime', 'yyyy-mm-dd');

is(ref('2000-01-01T12:00:00'), 'DateTime', 'yyyy-mm-ddThh:mm:ss');

{
	no DateTimeX::Auto;
	DateTimeX::Auto->import('d');
	
	is(ref(&d), 'DateTime', '&d works with no argument.');
	
	ok(d('2000-01-01T12:00:00.1234567891') eq '2000-01-01T12:00:00.1234567890',
		'Precision past nanoseconds supported');
}
