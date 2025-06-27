{
	'+modules' => [qw(Logger::Simple)],
	modules_init => {
		Routes => {
			base => 'BrulionAPI',
		},
	},

	resources => {
		'Resource::Boards' => {
			path => '/boards',
			name => 'CRUD for Brulion boards',
		},
		'Resource::Lanes' => {
			path => '/lanes',
			name => 'CRUD for Brulion lanes',
		},
		'Resource::Notes' => {
			path => '/notes',
			name => 'CRUD for Brulion notes',
		},
	},

	openapi => {
		path => '/openapi.json',
		info => {
			info => {
				title => 'Brulion API',
				description => 'REST API for Brulion',
				version => '1.00',
			}
		}
	},
}

