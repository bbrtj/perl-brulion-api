package BrulionAPI::Schema::Note;

use v5.40;
use Data::ULID qw(ulid);

use parent 'BrulionAPI::Schema';

__PACKAGE__->meta->setup
	(
		table => 'brulion_notes',
		columns => [
			qw(
				id lane_id sequence content
			)
		],
		pk_columns => 'id',

		foreign_keys => [
			lane => {
				class => 'BrulionAPI::Schema::Lane',
				key_columns => {lane_id => 'id'},
			},
		],
	);

__PACKAGE__->meta->make_manager_class('notes');

sub searchable
{
	return qw(lane_id);
}

sub orderable
{
	return qw(sequence);
}

sub prepare_and_save ($self)
{
	$self->id(ulid) unless defined $self->id;
	return $self->save;
}

sub prepare_and_dump ($self)
{
	return $self->column_value_pairs;
}

