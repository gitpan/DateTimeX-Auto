package DateTimeX::Auto;

use 5.008;
use strict;
use base qw[DateTime Exporter];
use overload '""' => \&_dtxa_stringify;
use Object::AUTHORITY;
use UNIVERSAL::ref;

use Carp qw[];
use DateTime::Format::Strptime qw[];

our %_const_handlers = (
	q  => sub
	{
		return $_[1] unless $_[2] eq 'q';
		return (__PACKAGE__->new($_[0]) // $_[1]);
	},
);
our @EXPORT_OK = qw[d dt];

BEGIN {
	$DateTimeX::Auto::AUTHORITY = 'cpan:TOBYINK';
	$DateTimeX::Auto::VERSION   = '0.003';
}

sub import
{
	my $class   = shift;
	my $imports = join ' ', @_;
	
	if ($imports =~ /(?:\b|^)\:auto(?:\b|$)/)
	{
		overload::constant %_const_handlers;
	}
	
	while ($imports =~ /(?:\b|^)(d|dt)(?:\b|^)/g)
	{
		$class->export_to_level(1, undef, $1);
	}
}

sub unimport
{
	overload::remove_constant(q => undef);
}

sub ref
{
	return 'DateTime';
}

sub d
{
	my ($string) = @_;
	
	return DateTime->now unless @_;
	
	my $dt = __PACKAGE__->new("$string");
	return $dt if $dt;
	
	Carp::croak("Could not turn '$string' into a DateTime.");
}

*dt = \&d;

sub from_object
{
	my ($proto, %args) = @_;
	
	my %x;
	my $rv = $proto->SUPER::from_object(%args);
	$rv->{+__PACKAGE__} = { %x } if %x = %{ $args{object}->{+__PACKAGE__} };
	
	return $rv;
}

sub new
{
	if (scalar @_ > 2)
	{
		my $class = shift;
		return $class->SUPER::new(@_);
	}
	
	my ($class, $string) = @_;
	
	if ($string =~ /^(\d{4})-(0[1-9]|1[0-2])-([0-2][0-9]|30|31)(Z?)$/)
	{
		my $dt;
		my $z = $4 // '';
		eval {
			$dt = $class->SUPER::new( year => $1, month=>$2, day=>$3, hour=>0, minute=>0, second=>0 );
			$dt->{+__PACKAGE__}{format} = 'D';
			if ($z eq 'Z' and defined $dt)
			{
				$dt->set_time_zone('UTC');
				$dt->{+__PACKAGE__}{trailer} = $z;
			}
		};
		return $dt if $dt;
	}
	
	if ($string =~ /^(\d{4})-(0[1-9]|1[0-2])-([0-2][0-9]|30|31)T([0-1][0-9]|2[0-4]):([0-5][0-9]):([0-5][0-9]|60)(\.[0-9]+)?(Z?)$/)
	{
		my $dt;
		my $z    = $8 // '';
		my $nano = $7 // '';
		eval {
			$dt = $class->SUPER::new( year => $1, month=>$2, day=>$3, hour=>$4, minute=>$5, second=>$6 );
			$dt->{+__PACKAGE__}{format} = 'DT';
			if (length $nano and defined $dt)
			{
				$dt->{+__PACKAGE__}{format} = length($nano) - 1;
				$dt->{rd_nanosecs} = substr($nano.('0' x 9), 1, 9) + 0;
			}
			if ($z eq 'Z' and defined $dt)
			{
				$dt->set_time_zone('UTC');
				$dt->{+__PACKAGE__}{trailer} = $z;
			}
		};
		return $dt if $dt;
	}
	
	return undef;
}

sub set_time_zone
{
	my ($self, @args) = @_;
	delete $self->{+__PACKAGE__}{trailer};
	$self->SUPER::set_time_zone(@args);
}

sub _dtxa_stringify
{
	my ($self) = @_;
	
	unless (exists $self->{+__PACKAGE__})
	{
		return $self->SUPER::_stringify;
	}
	
	my $trailer = $self->{+__PACKAGE__}{trailer} // '';
	
	if ($self->{+__PACKAGE__}{format} eq 'D')
	{
		return $self->ymd('-').$trailer;
	}

	elsif ($self->{+__PACKAGE__}{format} eq 'DT')
	{
		return sprintf('%sT%s%s', $self->ymd('-'), $self->hms(':'), $trailer);
	}

	else
	{
		my $nano = substr(
			$self->strftime('%N') . ('0' x $self->{+__PACKAGE__}{format}),
			0,
			$self->{+__PACKAGE__}{format},
			);
		return sprintf('%sT%s.%s%s', $self->ymd('-'), $self->hms(':'), $nano, $trailer);
	}
}

1;

__END__

=head1 NAME

DateTimeX::Auto - use DateTime without needing to call constructors

=head1 SYNOPSIS

 use DateTimeX::Auto ':auto';
 
 my $ga_start = '2000-04-06';
 $ga_start->add(years => 10);
 printf("%s %s\n", $ga_start, ref $ga_start);  # 2010-04-06 DateTime
 
 {
   no DateTimeX::Auto;
   my $string = '2000-04-06';
   printf( "%s\n", ref($string)?'Ref':'NoRef' );  # NoRef
 }

=head1 DESCRIPTION

L<DateTime> is awesome, but constructing C<DateTime> objects can be
annoying. You often need to use one of the formatter modules, or call
C<< DateTime->new() >> with a bunch of values. If you've got a bunch of
constant dates in your code, then C<DateTimeX::Auto> makes all this a bit
simpler.

It uses L<overload> to overload the C<< q() >> operator, automatically
turning all string constants that match particular regular expressions
into C<DateTime> objects. It also overloads stringification to make sure
that C<DateTime> objects get stringified back to exactly the format they
were given in.

The date formats supported are:

 yyyy-mm-dd
 yyyy-mm-ddZ
 yyyy-mm-ddThh:mm:ss
 yyyy-mm-ddThh:mm:ssZ

The optional trailing 'Z' puts the datetime into the UTC timezone. Otherwise
the datetime will be in DateTime's default (floating) timezone.

Fractional seconds are also supported, to an arbitrary number of decimal
places. However, as C<DateTime> only supports nanosecond precision, any
digits after the ninth will be zeroed out.

 my $dt         ='1234-12-12T12:34:56.123456789123456789';
 print "$dt\n"; # 1234-12-12T12:34:56.123456789000000000

Objects are blessed into the C<DateTimeX::Auto> class which inherits
from C<DateTime>. They use L<UNIVERSAL::ref> to masquerade as plain
C<DateTime> objects.

 print ref('2000-01-01')."\n";   # DateTime

=head2 The C<< d >> and C<< dt >> Functions

As an alternative C<DateTimeX::Auto> can export a function called C<d>.
This might be useful if you'd prefer not to have every string constant in
your code turned into a C<DateTime>.

 use DateTimeX::Auto 'd';
 my $dt = d('2000-01-01');

If C<d> is called with a string that is in an unrecognised format, it
croaks. If called with no arguments, returns a C<DateTime> representing
the current time.

An alias C<dt> is also available. They're exactly the same.

=head2 Object-Oriented Interface

This somewhat negates the purpose of the module, but it's also possible
to use it without exporting anything, in the usual normal Perl object-oriented
fashion:

 use DateTimeX::Auto;
 
 my $dt1 = DateTimeX::Auto->new('2000-01-01T12:00:00.1234');
 
 # Traditional DateTime style
 my $dt2 = DateTimeX::Auto->new(
   year  => 2000,
   month => 2,
   day   => 3,
   );

Called in the traditional DateTime style, throws an exception if the date
isn't valid. Called in the DateTimeX::Auto stringy style, returns undef
if the date isn't in a recognised format, but throws if it's otherwise
invalid (e.g. 30th of February).

=head1 EXAMPLES

 use DateTimeX::Auto ':auto';
 
 my $date = '2000-01-01';
 while ($date < '2000-02-01')
 {
   print "$date\n";
   $date->add(days => 1);
 }

 use DateTimeX::Auto 'd';
 
 my $date = d('2000-01-01');
 while ($date < d('2000-02-01'))
 {
   print "$date\n";
   $date->add(days => 1);
 }

=head1 SEE ALSO

L<DateTime>, L<DateTimeX::Easy>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
