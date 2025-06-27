package BrulionAPI::Schema::Board;

use v5.40;
use Data::ULID qw(ulid);

use parent 'BrulionAPI::Schema';

__PACKAGE__->meta->setup
	(
		table => 'brulion_boards',
		columns => [
			qw(
				id name
			)
		],
		pk_columns => 'id',

		relationships => [
			lanes =>
			{
				type => 'one to many',
				class => 'BrulionAPI::Schema::Lane',
				column_map => {id => 'board_id'},
			},
		],
	);

__PACKAGE__->meta->make_manager_class('boards');

sub searchable
{
	return qw(name);
}

sub orderable
{
	return qw(name);
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

