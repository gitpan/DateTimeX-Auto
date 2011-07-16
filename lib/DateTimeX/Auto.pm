package DateTimeX::Auto;

use 5.008;
use strict;
use base qw[DateTime Exporter];
use overload '""' => \&_dtxa_stringify;
use UNIVERSAL::ref;

use Carp qw[];
use DateTime::Format::Strptime qw[];

our %_const_handlers = (
	q  => sub {return __PACKAGE__->new($_[0]) || $_[1]}
);
our @EXPORT_OK = qw[d dt];

our $VERSION = '0.001';

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
	my $package = __PACKAGE__;
	
	return DateTime->now unless @_;
	
	my $dt = $package->new("$string");
	return $dt if $dt;
	
	Carp::croak("Could not turn '$string' into a DateTime.");
}

*dt = \&d;

sub new
{
	my ($class, $string) = @_;

	if ($string =~ /^(\d{4})-(0[1-9]|1[0-2])-([0-3][0-9])$/)
	{
		my $dt;
		eval {
			$dt = $class->SUPER::new( year => $1, month=>$2, day=>$3, hour=>0, minute=>0, second=>0 );
			$dt->{$class}{format} = 'D';
		};
		return $dt if $dt;
	}

	if ($string =~ /^(\d{4})-(0[1-9]|1[0-2])-([0-3][0-9])T([0-1][0-9]|2[0-4]):([0-5][0-9]):([0-5][0-9]|60)(\.[0-9]+)?$/)
	{
		my $dt;
		my $nano = $7;
		eval {
			$dt = $class->SUPER::new( year => $1, month=>$2, day=>$3, hour=>$4, minute=>$5, second=>$6 );
			$dt->{$class}{format} = 'DT';
			if (length $nano and defined $dt)
			{
				$dt->{$class}{format} = length($nano) - 1;
				$dt->{rd_nanosecs} = substr($nano.('0' x 9), 1, 9) + 0;
			}
		};
		return $dt if $dt;
	}

	return undef;
}

sub _dtxa_stringify
{
	my ($self) = @_;
	my $class = ref $self;
	
	if ($self->{$class}{format} eq 'D')
	{
		return $self->ymd('-');
	}

	elsif ($self->{$class}{format} eq 'DT')
	{
		return sprintf('%sT%s', $self->ymd('-'), $self->hms(':'));
	}

	else
	{
		my $nano = substr(
			$self->strftime('%N') . ('0' x $self->{$class}{format}),
			0,
			$self->{$class}{format},
			);
		return sprintf('%sT%s.%s', $self->ymd('-'), $self->hms(':'), $nano);
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
 yyyy-mm-ddThh:mm:ss

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

=head1 SEE ALSO

L<DateTime>, L<DateTimeX::Easy>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

