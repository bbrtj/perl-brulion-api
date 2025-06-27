use Kelp::Base -strict;
use Kelp::Test;
use Test::More;
use Test::Deep;
use HTTP::Request::Common;
use Whelk;
use BrulionAPI::DB;

BrulionAPI::DB->default_domain('test');
my $app = Whelk->new(mode => 'test');
my $t = Kelp::Test->new(app => $app);

$t->request(GET '/openapi.json')
	->code_is(200)
	->json_cmp(
		superhashof({
			paths => {
				'/boards' => ignore(),
				'/boards/{id}' => ignore(),
				'/lanes' => ignore(),
				'/lanes/board/{id}' => ignore(),
				'/lanes/{id}' => ignore(),
				'/lanes/move/{id}' => ignore(),
				'/notes' => ignore(),
				'/notes/lane/{id}' => ignore(),
				'/notes/{id}' => ignore(),
				'/notes/move/{id}' => ignore(),
			}
		})
	);

done_testing;

