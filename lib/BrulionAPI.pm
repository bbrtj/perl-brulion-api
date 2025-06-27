package BrulionAPI;

use v5.40;

use Kelp::Base 'Whelk::Resource';
use Whelk::Schema;
use List::Util qw(any);
use Whelk::Exception;

Whelk::Schema->build(
	brulion_id => {
		type => 'string',
		description => 'ID',
		example => '01JR6AJA710KR4ZF34VTJ3VD8S',
	}
);

sub paginated_query ($self, %params)
{
	my $sort_order = $params{sort_order} // die 'sort_order is required';
	my $sort_field = $params{sort_field} // die 'sort_field is required';
	my $bookmark = $params{bookmark};
	my $count = $params{count} // die 'count is required';
	my $id_field = $params{id_field} // 'id';
	my @where = @{$params{where} // []};

	Whelk::Exception->throw(422, hint => 'invalid sort_field')
		unless any { $_ eq $sort_field } $params{orderable}->@*;

	if (defined $bookmark) {
		my $bookmark_item = $params{bookmark_query}->($bookmark);
		my $operator = $sort_order eq 'asc' ? 'ge' : 'le';
		push @where, $sort_field => {$operator => $bookmark_item->$sort_field};

		if ($sort_field ne $id_field) {
			push @where, or => [
				$sort_field => {ne => $bookmark_item->$sort_field},
				$id_field => {$operator => $bookmark_item->$id_field},
			];
		}
	}

	my $all = $params{query}->(
		query => \@where,
		sort_by => (
			join ', ',
			"$sort_field $sort_order",
			($id_field ne $sort_field ? "$id_field $sort_order" : ()),
		),
		limit => $count + 1,
	);

	my $next_bookmark = @$all > $count ? (pop @$all)->$id_field : undef;

	return {
		count => scalar @$all,
		data => [map { scalar $_->prepare_and_dump } @$all],
		bookmark => $next_bookmark,
	};
}

