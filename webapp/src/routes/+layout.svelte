<script lang="ts">
	import '../app.css';

	let { children } = $props();
	let isOpen = $state(false);

	function closeMenu() {
		isOpen = false;
	}

	const navLinks = [
		{ href: '/', label: 'Home' },
		{ href: '/form', label: 'Submit' },
		{ href: '/log', label: 'Submission Log' }
	];
</script>

<!-- Desktop Navigation -->
{#snippet desktopNavLink(link: typeof navLinks[0])}
	<a 
		href={link.href} 
		class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
	>
		{link.label}
	</a>
{/snippet}

<!-- Mobile Navigation -->
{#snippet mobileNavLink(link: typeof navLinks[0])}
	<a
		href={link.href}
		class="block px-3 py-2 rounded-md text-base font-medium text-gray-700 hover:bg-gray-50"
		onclick={closeMenu}
	>
		{link.label}
	</a>
{/snippet}

<div class="min-h-screen bg-gray-50">
	<!-- Navigation -->
	<nav class="bg-white shadow">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between h-16">
				<div class="flex">
					<div class="flex-shrink-0 flex items-center">
						<a href="/" class="text-xl font-bold text-gray-900">Protest Tracker</a>
					</div>
					<div class="hidden sm:ml-6 sm:flex sm:space-x-8">
						{#each navLinks as link}
							{@render desktopNavLink(link)}
						{/each}
					</div>
				</div>
				<!-- Mobile menu button -->
				<div class="flex items-center sm:hidden">
					<button
						type="button"
						class="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-blue-500"
						aria-controls="mobile-menu"
						aria-expanded={isOpen}
						onclick={() => (isOpen = !isOpen)}
					>
						<span class="sr-only">Open main menu</span>
						{#if !isOpen}
							<!-- Hamburger icon -->
							<svg class="block h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
							</svg>
						{:else}
							<!-- Close icon -->
							<svg class="block h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
							</svg>
						{/if}
					</button>
				</div>
			</div>
		</div>
	</nav>
	{#if isOpen}
		<div class="sm:hidden" id="mobile-menu">
			<div class="px-2 pt-2 pb-3 space-y-1">
				{#each navLinks as link}
					{@render mobileNavLink(link)}
				{/each}
			</div>
		</div>
	{/if}

	<!-- Main content -->
	<main>
		{@render children()}
	</main>

	<!-- Footer -->
	<footer class="bg-white mt-auto">
		<div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
			<p class="text-center text-sm text-gray-500">
				2025 Protest Tracker. A tool for documenting civic engagement.
			</p>
		</div>
	</footer>
</div>
