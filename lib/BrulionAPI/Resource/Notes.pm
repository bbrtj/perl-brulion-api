package BrulionAPI::Resource::Notes;

use v5.40;
use utf8;

use My::Whelk::Rules;
use BrulionAPI::Schema::Note;
use List::Util qw(max);

use Kelp::Base 'BrulionAPI';

sub schemas
{
	my %common_note_properties = (
		lane_id => \'brulion_id',
		content => {
			type => 'string',
		},
	);

	Whelk::Schema->build(
		brulion_note_insert => {
			type => 'object',
			strict => true,
			properties => {
				%common_note_properties,
			},
		}
	);

	Whelk::Schema->build(
		brulion_note_update => [
			\'brulion_note_insert',
			properties => {
				lane_id => {
					required => false,
				},
				content => {
					required => false,
				},
			},
		]
	);

	Whelk::Schema->build(
		brulion_note_full => {
			type => 'object',
			strict => true,
			properties => {
				id => \'brulion_id',
				sequence => {
					type => 'integer',
				},
				%common_note_properties,
			},
		}
	);

	Whelk::Schema->build(
		brulion_note_list => {
			type => 'object',
			properties => {
				data => {
					type => 'array',
					items => \'brulion_note_full'
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
		[GET => '/lane/:id'] => {
			to => 'action_list',
			check => {
				id => '\w{26}'
			},
		},
		summary => 'List notes',
		parameters => {
			path => {
				id => \'brulion_id',
			},
			query => {
				%pagination_params,
			},
		},
		response => \'brulion_note_list',
	);

	$self->add_endpoint(
		[GET => '/:id'] => {
			to => 'action_show',
			check => {
				id => '\w{26}'
			},
		},
		summary => 'Show a note',
		parameters => {
			path => {
				id => \'brulion_id',
			},
		},
		response => \'brulion_note_full',
	);

	$self->add_endpoint(
		[POST => '/'] => {
			to => 'action_add',
		},
		summary => 'Add a new note',
		request => \'brulion_note_insert',
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
		summary => 'Update a note',
		request => \'brulion_note_update',
	);

	$self->add_endpoint(
		[PUT => '/move/:id'] => {
			to => 'action_move',
			check => {
				id => '\w{26}'
			},
		},
		summary => 'Move a note (change order)',
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
		summary => 'Delete a note',
		parameters => {
			path => {
				id => \'brulion_id',
			},
		},
	);
}

sub _find ($self, $id)
{
	my $note = BrulionAPI::Schema::Note->new(id => $id);

	Whelk::Exception->throw(404, hint => 'No such note')
		unless $note->load(speculative => 1);

	return $note;
}

sub action_list ($self, $lane_id)
{
	return $self->paginated_query(
		(map { $_ => $self->req->query_param($_) } qw(sort_field sort_order bookmark count)),
		orderable => [BrulionAPI::Schema::Note->orderable],
		bookmark_query => sub ($bookmark) { $self->_find($bookmark) },
		query => sub (%params) {
			push $params{query}->@*, lane_id => $lane_id;
			return BrulionAPI::Schema::Note::Manager->get_notes(%params);
		},
	);
}

sub action_show ($self, $id)
{
	my $note = $self->_find($id);

	return scalar $note->prepare_and_dump;
}

sub action_add ($self)
{
	my $data = $self->request_body;

	my $created = BrulionAPI::Schema::Note->new(%$data);
	my $all = $created->lane->notes;
	my $sequence = max map { $_->sequence } $all->@*;
	$created->sequence(($sequence // -1) + 1);
	$created->prepare_and_save;

	return {
		id => $created->id,
	};
}

sub action_update ($self, $id)
{
	my $note = $self->_find($id);
	my $data = $self->request_body;

	foreach my $key (keys $data->%*) {
		$note->$key($data->{$key});
	}

	$note->prepare_and_save;
	return undef;
}

sub action_move ($self, $id)
{
	my $lane = $self->_find($id)->lane;
	my $after = $self->request_body->{after};
	my @all = $lane->notes->@*;

	Whelk::Exception->throw(422, hint => 'No such "after" note')
		unless grep { $_->id eq $after } @all;

	my ($note) = grep { $_->id eq $id } @all;
	@all = grep { $_ != $note } @all;
	@all = sort { $a->sequence <=> $b->sequence } @all;

	# reorder the notes
	my $sequence = 0;
	if (!defined $after) {
		$after = '';    # no undefined warnings
		$note->sequence($sequence++);
	}

	foreach my $item (@all) {
		$item->sequence($sequence++);
		$item->save;

		$note->sequence($sequence++)
			if $item->id eq $after;
	}

	$note->save;
	return undef;
}

sub action_delete ($self, $id)
{
	my $note = $self->_find($id);
	$note->delete;

	return undef;
}

