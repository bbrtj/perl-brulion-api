package BrulionAPI::Schema::Lane;

use v5.40;
use Data::ULID qw(ulid);

use parent 'BrulionAPI::Schema';

__PACKAGE__->meta->setup
	(
		table => 'brulion_lanes',
		columns => [
			qw(
				id board_id sequence name
			)
		],
		pk_columns => 'id',

		foreign_keys => [
			board => {
				class => 'BrulionAPI::Schema::Board',
				key_columns => {board_id => 'id'},
			},
		],

		relationships => [
			notes =>
			{
				type => 'one to many',
				class => 'BrulionAPI::Schema::Note',
				column_map => {id => 'lane_id'},
			},
		],
	);

__PACKAGE__->meta->make_manager_class('lanes');

sub searchable
{
	return qw(board_id);
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

