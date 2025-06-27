use Test::More;
use Test::Deep qw(re array_each supersetof ignore);
use Kelp::Test;
use HTTP::Request::Common qw(GET POST PUT DELETE);
use Whelk;
use BrulionAPI::DB;

BrulionAPI::DB->default_domain('test');
my $app = Whelk->new(mode => 'test');
my $t = Kelp::Test->new(app => $app);

my $board_id;
my %board_data = (
	name => 'Test_' . time,
);

subtest 'testing boards functionality' => sub {
	$t->request(
		POST '/boards',
		Content_Type => 'application/json',
		Content => $app->get_encoder('json')->encode(\%board_data)
	)->code_is(201)
		->json_cmp({id => re(qr/^\w{26}$/)});

	$board_id = $t->json_content->{id};

	$t->request(GET '/boards')
		->code_is(200)
		->json_cmp(
			{
				count => re(qr/^\d+$/),
				bookmark => ignore,
				data => array_each(
					{
						id => ignore(),
						name => ignore(),
					}
				),
			}
		);

	$t->request(GET "/boards/$board_id")
		->code_is(200)
		->json_cmp(
			{
				id => $board_id,
				%board_data,
			}
		);
};

my @lane_ids;
my %lane_data = (
	name => 'test lane',
	board_id => $board_id,
);

subtest 'testing lanes functionality' => sub {
	for (1 .. 3) {
		$t->request(
			POST '/lanes',
			Content_Type => 'application/json',
			Content => $app->get_encoder('json')->encode(\%lane_data)
		)->code_is(201)
			->json_cmp({id => re(qr/^\w{26}$/)});

		push @lane_ids, $t->json_content->{id};
	}

	$t->request(
		PUT "/lanes/$lane_ids[0]",
		Content_Type => 'application/json',
		Content => $app->get_encoder('json')->encode({name => 'ALTERED'})
	)->code_is(204);

	$t->request(GET "/lanes/$lane_ids[0]")
		->code_is(200)
		->json_cmp(
			{
				id => $lane_ids[0],
				%lane_data,
				name => 'ALTERED',
				sequence => 0,
			}
		);

	$t->request(GET "/lanes/$lane_ids[-1]")
		->code_is(200)
		->json_cmp(
			{
				id => $lane_ids[-1],
				%lane_data,
				sequence => @lane_ids - 1,
			}
		);

	$t->request(
		PUT "/lanes/move/$lane_ids[0]",
		Content_Type => 'application/json',
		Content => $app->get_encoder('json')->encode({after => $lane_ids[1]})
	)->code_is(204);

	$t->request(GET "/lanes/board/$board_id")
		->code_is(200)
		->json_cmp(
			{
				bookmark => ignore(),
				count => 3,
				data => [
					{
						id => $lane_ids[1],
						%lane_data,
						sequence => 0,
					},
					{
						id => $lane_ids[0],
						%lane_data,
						name => 'ALTERED',
						sequence => 1,
					},
					{
						id => $lane_ids[2],
						%lane_data,
						sequence => 2,
					},
				]
			}
		);
};

my @note_ids;
my %note_data = (
	content => 'test note',
	lane_id => $lane_ids[0],
);

subtest 'testing notes functionality' => sub {
	for (1 .. 3) {
		$t->request(
			POST '/notes',
			Content_Type => 'application/json',
			Content => $app->get_encoder('json')->encode(\%note_data)
		)->code_is(201)
			->json_cmp({id => re(qr/^\w{26}$/)});

		push @note_ids, $t->json_content->{id};
	}

	$t->request(
		PUT "/notes/$note_ids[0]",
		Content_Type => 'application/json',
		Content => $app->get_encoder('json')->encode({content => 'ALTERED'})
	)->code_is(204);

	$t->request(GET "/notes/$note_ids[0]")
		->code_is(200)
		->json_cmp(
			{
				id => $note_ids[0],
				%note_data,
				content => 'ALTERED',
				sequence => 0,
			}
		);

	$t->request(GET "/notes/$note_ids[-1]")
		->code_is(200)
		->json_cmp(
			{
				id => $note_ids[-1],
				%note_data,
				sequence => @note_ids - 1,
			}
		);

	$t->request(
		PUT "/notes/move/$note_ids[0]",
		Content_Type => 'application/json',
		Content => $app->get_encoder('json')->encode({after => $note_ids[1]})
	)->code_is(204);

	$t->request(GET "/notes/lane/$lane_ids[0]")
		->code_is(200)
		->json_cmp(
			{
				bookmark => ignore(),
				count => 3,
				data => [
					{
						id => $note_ids[1],
						%note_data,
						sequence => 0,
					},
					{
						id => $note_ids[0],
						%note_data,
						content => 'ALTERED',
						sequence => 1,
					},
					{
						id => $note_ids[2],
						%note_data,
						sequence => 2,
					},
				]
			}
		);
};

subtest 'testing deletion' => sub {
	$t->request(DELETE "/notes/$note_ids[0]")
		->code_is(204);

	$t->request(GET "/notes/lane/$lane_ids[0]")
		->code_is(200)
		->json_cmp(
			{
				bookmark => ignore(),
				count => 2,
				data => ignore(),
			}
		);

	$t->request(DELETE "/lanes/$lane_ids[0]")
		->code_is(204);

	$t->request(GET "/lanes/board/$board_id")
		->code_is(200)
		->json_cmp(
			{
				bookmark => ignore(),
				count => 2,
				data => ignore(),
			}
		);

	$t->request(DELETE "/boards/$board_id")
		->code_is(204);
};

done_testing;

