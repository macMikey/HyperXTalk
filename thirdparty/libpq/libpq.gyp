{
	'includes':
	[
		'../../common.gypi',
	],

	'targets':
	[
		{
			'target_name': 'libpq',

			# Use prebuilt libpq.a installed by
			# prebuilt/scripts/build-libpq-mac-arm64.sh from Homebrew.
			# On macOS, config/mac.gypi sets use_system_libpq=1 so this
			# 'none' target is always selected on that platform.
			'type': 'none',

			'link_settings':
			{
				'libraries':
				[
					'../../prebuilt/lib/mac/libpq.a',
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
