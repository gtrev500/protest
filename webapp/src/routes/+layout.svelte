<script lang="ts">
	import '../app.css';

	let { children } = $props();
</script>

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
						<a href="/" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
							Home
						</a>
						<a href="/form" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
							Submit
						</a>
						<a href="/dashboard" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
							Dashboard
						</a>
					</div>
				</div>
			</div>
		</div>
	</nav>

	<!-- Main content -->
	<main>
		{@render children()}
	</main>

	<!-- Footer -->
	<footer class="bg-white mt-auto">
		<div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
			<p class="text-center text-sm text-gray-500">
				© 2024 Protest Tracker. A tool for documenting civic engagement.
			</p>
		</div>
	</footer>
</div>
