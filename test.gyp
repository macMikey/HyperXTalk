{
	'variables': {
		'test_version': "<!(perl -e 'print 42')",
	},
	'targets': [
		{
			'target_name': 'test',
			'type': 'executable',
			'sources': [ 'test.c' ],
		},
	],
}