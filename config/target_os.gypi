{
	'variables':
	{
		'mobile': 0,
		
		'uniform_arch%': '<(target_arch)',
		
		# Default intermediate directories for all platforms (MSVS defaults)
# uncommenting these gives an icu permissions error copying to /data
#		'INTERMEDIATE_DIR': '$(IntDir)',
#		'SHARED_INTERMEDIATE_DIR': '$(OutDir)obj/global_intermediate',
# uncommenting these keeps lc-bootstrap-compile from working
#		'PRODUCT_DIR': '$(OutDir)',
#		'LIB_DIR': '$(OutDir)lib',
		'STATIC_LIB_PREFIX': '',
		'SHARED_LIB_PREFIX': '',
		'STATIC_LIB_SUFFIX': '.lib',
#		'SHARED_LIB_SUFFIX': '.dll',
#		'EXECUTABLE_SUFFIX': '.exe',
	},
	
	'conditions':
	[
		[
			'OS == "mac"',
			{
				'includes':
				[
					'mac.gypi',
				],
			},
		],
		[
			'OS == "linux"',
			{
				'includes':
				[
					'linux.gypi',
				],
			},
		],
		[
			'OS == "android"',
			{
				'includes':
				[
					'android.gypi',
				],
			},
		],
		[
			'OS == "win"',
			{
				'includes':
				[
					'win32.gypi',
				],
			},
		],
		[
			'OS == "ios"',
			{
				'includes':
				[
					'ios.gypi',
				],
			},
		],
		[
			'OS == "emscripten"',
			{
				'includes':
				[
					'emscripten.gypi',
				],
			},
		],
	],
}
