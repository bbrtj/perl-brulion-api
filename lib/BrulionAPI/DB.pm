package BrulionAPI::DB;

use v5.40;

use parent 'Rose::DB';

use constant SQLITE_TWEAKS => {
	sqlite_unicode => 1,
	post_connect_sql => [
		"PRAGMA foreign_keys = ON",
	],
};

__PACKAGE__->use_private_registry;

__PACKAGE__->register_db(
	domain => 'brulion',
	type => 'default',
	driver => 'SQLite',
	database => 'brulion.db',
	%{(SQLITE_TWEAKS)}
);

__PACKAGE__->register_db(
	domain => 'test',
	type => 'default',
	driver => 'SQLite',
	database => 'test.db',
	%{(SQLITE_TWEAKS)}
);

__PACKAGE__->default_domain('brulion');

