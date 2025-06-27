package BrulionAPI::Resource::Boards;

use v5.40;
use utf8;

use My::Whelk::Rules;
use BrulionAPI::Schema::Board;

use Kelp::Base 'BrulionAPI';

sub schemas
{
	my %common_board_properties = (
		name => {
			type => 'string',
		},
	);

	Whelk::Schema->build(
		brulion_board_insert => {
			type => 'object',
			strict => true,
			properties => {
				%common_board_properties,
			},
		}
	);

	Whelk::Schema->build(
		brulion_board_full => {
			type => 'object',
			strict => true,
			properties => {
				id => \'brulion_id',
				%common_board_properties,
			},
		}
	);

	Whelk::Schema->build(
		brulion_board_list => {
			type => 'object',
			properties => {
				data => {
					type => 'array',
					items => \'brulion_board_full'
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
			default => 'name',
		},
		sort_order => {
			type => 'string',
			default => 'desc',
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
		[GET => '/'] => {
			to => 'action_list',
		},
		summary => 'List boards',
		parameters => {
			query => {
				%pagination_params,
			},
		},
		response => \'brulion_board_list',
	);

	$self->add_endpoint(
		[GET => '/:id'] => {
			to => 'action_show',
			check => {
				id => '\w{26}'
			},
		},
		summary => 'Show a board',
		parameters => {
			path => {
				id => \'brulion_id',
			},
		},
		response => \'brulion_board_full',
	);

	$self->add_endpoint(
		[POST => '/'] => {
			to => 'action_add',
		},
		summary => 'Add a new board',
		request => \'brulion_board_insert',
		response => {
			type => 'object',
			properties => {
				id => \'brulion_id',
			},
		},
		response_code => 201,
	);

	$self->add_endpoint(
		[DELETE => '/:id'] => {
			to => 'action_delete',
			check => {
				id => '\w{26}'
			},
		},
		summary => 'Delete a board',
		parameters => {
			path => {
				id => \'brulion_id',
			},
		},
		response_code => 204,
	);
}

sub _find ($self, $id)
{
	my $board = BrulionAPI::Schema::Board->new(id => $id);

	Whelk::Exception->throw(404, hint => 'No such board')
		unless $board->load(speculative => 1);

	return $board;
}

sub action_list ($self)
{
	return $self->paginated_query(
		(map { $_ => $self->req->query_param($_) } qw(sort_field sort_order bookmark count)),
		orderable => [BrulionAPI::Schema::Board->orderable],
		bookmark_query => sub ($bookmark) { $self->_find($bookmark) },
		query => sub (%params) { BrulionAPI::Schema::Board::Manager->get_boards(%params) },
	);
}

sub action_show ($self, $id)
{
	my $board = $self->_find($id);

	return scalar $board->prepare_and_dump;
}

sub action_add ($self)
{
	my $data = $self->request_body;

	my $created = BrulionAPI::Schema::Board->new(%$data);
	$created->prepare_and_save;

	return {
		id => $created->id,
	};
}

sub action_delete ($self, $id)
{
	my $board = $self->_find($id);
	$board->delete;

	return undef;
}

