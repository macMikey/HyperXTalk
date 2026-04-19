{
	'includes':
	[
		'../../common.gypi',
	],

	'targets':
	[
		{
			'target_name': 'libmysql',

			# Use prebuilt libmysqlclient.a installed by
			# prebuilt/scripts/build-libmysql-mac-arm64.sh from Homebrew.
			# On macOS, config/mac.gypi sets use_system_libmysql=1 so this
			# 'none' target is always selected on that platform.
			'type': 'none',

			'link_settings':
			{
				'libraries':
				[
					'../../prebuilt/lib/mac/libmysql.a',
				],
			},

			'direct_dependent_settings':
			{
				'include_dirs':
				[
					'include',
				],
			},
		},
	],
}
