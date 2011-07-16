use strict;
use warnings;

use inc::Module::Install;

my $dist = 'DateTimeX-Auto';
my $fn   = "lib/$dist.pm"; $fn =~ s#-#/#g;

name                $dist;
perl_version_from   $fn;
version_from        $fn;
abstract_from       $fn;
readme_from         $fn;
author              'Toby Inkster <tobyink@cpan.org>';
license             'perl';

requires            'Carp'               => 0;
requires            'DateTime'           => 0;
requires            'DateTime::Format::Strptime'  => 0;
test_requires       'Test::More'         => '0.61';
requires            'UNIVERSAL::ref'     => 0;

resources(
	'homepage'   => "http://search.cpan.org/dist/$dist/",
	'repository' => "http://goddamn.co.uk/viewvc/perlmods/$dist/",
	'bugtracker' => "http://rt.cpan.org/Dist/Display.html?Queue=$dist",
	);

keywords(qw[Perl DateTimeX overload constant]);
	
write_doap_changes;
write_doap_changes_xml;

auto_install;
WriteAll(
	'meta' => 1,
	'sign' => 1,
	);
