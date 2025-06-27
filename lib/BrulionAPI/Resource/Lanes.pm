package BrulionAPI::Resource::Lanes;

use v5.40;
use utf8;

use My::Whelk::Rules;
use BrulionAPI::Schema::Lane;
use List::Util qw(max);

use Kelp::Base 'BrulionAPI';

sub schemas
{
	my %common_lane_properties = (
		board_id => \'brulion_id',
		name => {
			type => 'string',
		},
	);

	Whelk::Schema->build(
		brulion_lane_insert => {
			type => 'object',
			strict => true,
			properties => {
				%common_lane_properties,
			},
		}
	);

	Whelk::Schema->build(
		brulion_lane_update => [
			\'brulion_lane_insert',
			properties => {
				board_id => {
					required => false,
				},
				name => {
					required => false,
				},
			},
		]
	);

	Whelk::Schema->build(
		brulion_lane_full => {
			type => 'object',
			strict => true,
			properties => {
				id => \'brulion_id',
				sequence => {
					type => 'integer',
				},
				%common_lane_properties,
			},
		}
	);

	Whelk::Schema->build(
		brulion_lane_list => {
			type => 'object',
			properties => {
				data => {
					type => 'array',
					items => \'brulion_lane_full'
				},
				count => {
					type => 'integer',
				},
				bookmark => [
					\'brulion_id',
					nullable => true,
				],
			}
		}
	);
}

sub api ($self)
{
	my %pagination_params = (
		sort_field => {
			type => 'string',
			default => 'sequence',
		},
		sort_order => {
			type => 'string',
			default => 'asc',
			rules => [
				whelk_rule(common => 'enum', [qw(desc asc)]),
			],
		},
		bookmark => [
			\'brulion_id',
			required => false,
		],
		count => {
			type => 'integer',
			default => 10,
			rules => [
				whelk_rule(number => 'gt', 0),
			],
		},
	);

	$self->add_endpoint(
		[GET => '/board/:id'] => {
			to => 'action_list',
			check => {
				id => '\w{26}'
			},
		},
		summary => 'List lanes',
		parameters => {
			path => {
				id => \'brulion_id',
			},
			query => {
				%pagination_params,
			},
		},
		response => \'brulion_lane_list',
	);

	$self->add_endpoint(
		[GET => '/:id'] => {
			to => 'action_show',
			check => {
				id => '\w{26}'
			},
		},
		summary => 'Show a lane',
		parameters => {
			path => {
				id => \'brulion_id',
			},
		},
		response => \'brulion_lane_full',
	);

	$self->add_endpoint(
		[POST => '/'] => {
			to => 'action_add',
		},
		summary => 'Add a new lane',
		request => \'brulion_lane_insert',
		response => {
			type => 'object',
			properties => {
				id => \'brulion_id',
			},
		},
		response_code => 201,
	);

	$self->add_endpoint(
		[PUT => '/:id'] => {
			to => 'action_update',
			check => {
				id => '\w{26}'
			},
		},
		summary => 'Update a lane',
		request => \'brulion_lane_update',
	);

	$self->add_endpoint(
		[PUT => '/move/:id'] => {
			to => 'action_move',
			check => {
				id => '\w{26}'
			},
		},
		summary => 'Move a lane (change order)',
		request => {
			type => 'object',
			properties => {
				after => [
					\'brulion_id',
					nullable => true,
				],
			},
		},
	);

	$self->add_endpoint(
		[DELETE => '/:id'] => {
			to => 'action_delete',
			check => {
				id => '\w{26}'
			},
		},
		summary => 'Delete a lane',
		parameters => {
			path => {
				id => \'brulion_id',
			},
		},
	);
}

sub _find ($self, $id)
{
	my $lane = BrulionAPI::Schema::Lane->new(id => $id);

	Whelk::Exception->throw(404, hint => 'No such lane')
		unless $lane->load(speculative => 1);

	return $lane;
}

sub action_list ($self, $board_id)
{
	return $self->paginated_query(
		(map { $_ => $self->req->query_param($_) } qw(sort_field sort_order bookmark count)),
		orderable => [BrulionAPI::Schema::Lane->orderable],
		bookmark_query => sub ($bookmark) { $self->_find($bookmark) },
		query => sub (%params) {
			push $params{query}->@*, board_id => $board_id;
			return BrulionAPI::Schema::Lane::Manager->get_lanes(%params);
		},
	);
}

sub action_show ($self, $id)
{
	my $lane = $self->_find($id);

	return scalar $lane->prepare_and_dump;
}

sub action_add ($self)
{
	my $data = $self->request_body;

	my $created = BrulionAPI::Schema::Lane->new(%$data);
	my $all = $created->board->lanes;
	my $sequence = max map { $_->sequence } $all->@*;
	$created->sequence(($sequence // -1) + 1);
	$created->prepare_and_save;

	return {
		id => $created->id,
	};
}

sub action_update ($self, $id)
{
	my $lane = $self->_find($id);
	my $data = $self->request_body;

	foreach my $key (keys $data->%*) {
		$lane->$key($data->{$key});
	}

	$lane->prepare_and_save;
	return undef;
}

sub action_move ($self, $id)
{
	my $board = $self->_find($id)->board;
	my $after = $self->request_body->{after};
	my @all = $board->lanes->@*;

	Whelk::Exception->throw(422, hint => 'No such "after" lane')
		unless grep { $_->id eq $after } @all;

	my ($lane) = grep { $_->id eq $id } @all;
	@all = grep { $_ != $lane } @all;
	@all = sort { $a->sequence <=> $b->sequence } @all;

	# reorder the lanes
	my $sequence = 0;
	if (!defined $after) {
		$after = '';    # no undefined warnings
		$lane->sequence($sequence++);
	}

	foreach my $item (@all) {
		$item->sequence($sequence++);
		$item->save;

		$lane->sequence($sequence++)
			if $item->id eq $after;
	}

	$lane->save;
	return undef;
}

sub action_delete ($self, $id)
{
	my $lane = $self->_find($id);
	$lane->delete;

	return undef;
}

