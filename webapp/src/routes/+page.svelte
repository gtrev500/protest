<svelte:head>
	<title>Protest Sourcebook</title>
</svelte:head>

{#snippet actionButton(href, isPrimary, text)}
	<a
		href={href}
		class="w-full flex items-center justify-center px-8 py-3 border border-transparent text-base font-medium rounded-md {isPrimary ? 'text-white bg-blue-600 hover:bg-blue-700' : 'text-blue-600 bg-white hover:bg-gray-50'} md:py-4 md:text-lg md:px-10"
	>
		{text}
	</a>
{/snippet}

{#snippet featureCard(iconPath, title, description)}
	<div class="bg-white overflow-hidden shadow rounded-lg">
		<div class="px-4 py-5 sm:p-6">
			<div class="flex items-center">
				<div class="flex-shrink-0">
					<svg class="h-8 w-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={iconPath} />
					</svg>
				</div>
				<div class="ml-5">
					<h3 class="text-lg font-medium text-gray-900">{title}</h3>
					<p class="mt-2 text-sm text-gray-500">
						{description}
					</p>
				</div>
			</div>
		</div>
	</div>
{/snippet}

<div class="min-h-screen bg-gray-100">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
		<div class="text-center">
			<h1 class="text-4xl font-bold text-gray-900 sm:text-5xl md:text-6xl">
				Protest Sourcebook
			</h1>
			<p class="mt-3 max-w-md mx-auto text-base text-gray-500 sm:text-lg md:mt-5 md:text-xl md:max-w-3xl">
				Document and track protests for the historical record. Help us build a comprehensive database of protests.
			</p>
			<div class="mt-5 max-w-md mx-auto sm:flex sm:justify-center md:mt-8">
				<div class="rounded-md shadow">
					{@render actionButton('/form', true, 'Submit a Protest')}
				</div>
				<div class="mt-3 rounded-md shadow sm:mt-0 sm:ml-3">
					{@render actionButton('/log', false, 'View Log')}
				</div>
			</div>
		</div>

		<!-- Features -->
		<div class="mt-20">
			<div class="grid grid-cols-1 gap-8 md:grid-cols-2">
				{@render featureCard(
					'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z',
					'Document Events',
					'Submit detailed information about protests including location, participants, and outcomes.'
				)}

				{@render featureCard(
					'M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m9.032 4.026a9 9 0 10-13.432 0m13.432 0A9 9 0 0112 21m0 0a9 9 0 01-5.432-1.795m5.432 1.795a9 9 0 005.432-1.795',
					'Public Access',
					'All protest data is publicly accessible to researchers, journalists, and citizens.'
				)}
			</div>
		</div>
	</div>
</div>
