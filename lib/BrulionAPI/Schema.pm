package BrulionAPI::Schema;

use v5.40;

use BrulionAPI::DB;
use parent 'Rose::DB::Object';

use Rose::DB::Object::Helpers qw(column_value_pairs);

sub init_db
{
	BrulionAPI::DB->new_or_cached;
}

