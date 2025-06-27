package My::Whelk::Rules;

use v5.40;
use utf8;

use Exporter qw(import);
use List::Util qw(any);

our @EXPORT = qw(whelk_rule);

my %rules = (
	string => {
		url => sub () {
			return {
				hint => '(url)',
				code => sub ($value) {
					return scalar($value =~ /^https?:/);
				},
			};
		},

		alnum => sub () {
			return {
				hint => '(alphanumeric)',
				code => sub ($value) {
					return scalar($value =~ /^(\w|\s)+$/);
				},
			};
		},

		max_len => sub ($config) {
			return {
				openapi => {
					maxLength => $config,
				},
				hint => "(maxLength)",
				code => sub ($value) {
					return length $value <= $config;
				},
			};
		},
	},

	number => {
		gt => sub ($config) {
			return {
				openapi => {
					minimum => $config,
					exclusiveMinimum => true,
				},
				hint => "(exclusiveMinimum)",
				code => sub ($value) {
					return $value > $config;
				},
			};
		},
	},

	common => {
		enum => sub ($config) {
			return {
				openapi => {
					enum => $config,
				},
				hint => "(enum)",
				code => sub ($value) {
					return any { $value eq $_ } @$config;
				},
			};
		},
	},
);

sub whelk_rule ($area, $name, @args)
{
	my $rule = $rules{$area}{$name} // die 'no such rule';
	return $rule->(@args);
}

