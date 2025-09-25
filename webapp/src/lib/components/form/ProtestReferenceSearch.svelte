<script lang="ts">
  interface SearchResult {
    id: string;
    title: string;
    date_of_event: string;
    locality: string;
    state_code: string;
    claims_summary: string | null;
    organization_name: string | null;
  }

  interface Props {
    name: string;
    value?: string;
    required?: boolean;
    error?: string | null;
  }

  let {
    name,
    value = $bindable(),
    required = false,
    error = null
  }: Props = $props();

  let searchQuery = $state('');
  let searchResults = $state<SearchResult[]>([]);
  let selectedProtest = $state<SearchResult | null>(null);
  let isSearching = $state(false);
  let showResults = $state(false);
  let searchTimeout: number;
  let searchContainer: HTMLDivElement;

  // Initialize selected protest if value is provided
  $effect(() => {
    if (value && !selectedProtest) {
      // Could fetch the protest details here if needed
    }
  });

  async function performSearch(query: string) {
    if (query.length < 3) {
      searchResults = [];
      showResults = false;
      return;
    }

    isSearching = true;

    try {
      const response = await fetch(`/api/protests/search?q=${encodeURIComponent(query)}`);
      const data = await response.json();

      if (response.ok) {
        searchResults = data.results || [];
        showResults = searchResults.length > 0 || query.length >= 3;
      } else {
        console.error('Search error:', data.error, data.details);
        searchResults = [];
        // Still show the "no results" message even on error
        showResults = query.length >= 3;
      }
    } catch (err) {
      console.error('Search failed:', err);
      searchResults = [];
      showResults = false;
    } finally {
      isSearching = false;
    }
  }

  function handleSearchInput(e: Event) {
    const input = e.target as HTMLInputElement;
    searchQuery = input.value;

    // Clear any pending search
    clearTimeout(searchTimeout);

    // Show loading state immediately for better UX
    if (searchQuery.length >= 3) {
      isSearching = true;
    }

    // Debounce the actual search
    searchTimeout = window.setTimeout(() => {
      performSearch(searchQuery);
    }, 300);
  }

  function selectProtest(protest: SearchResult) {
    selectedProtest = protest;
    value = protest.id;
    showResults = false;
    searchQuery = '';
  }

  function clearSelection() {
    selectedProtest = null;
    value = undefined;
    searchQuery = '';
    searchResults = [];
    showResults = false;
  }

  function formatDate(dateStr: string) {
    return new Date(dateStr).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  }

  // Handle clicking outside to close results
  function handleClickOutside(e: MouseEvent) {
    if (searchContainer && !searchContainer.contains(e.target as Node)) {
      showResults = false;
    }
  }

  // Handle keyboard navigation
  function handleKeyDown(e: KeyboardEvent) {
    if (!showResults || searchResults.length === 0) return;

    if (e.key === 'Escape') {
      showResults = false;
      e.preventDefault();
    }
    // Add arrow key navigation if needed
  }

  $effect(() => {
    if (showResults) {
      document.addEventListener('click', handleClickOutside);
      document.addEventListener('keydown', handleKeyDown);
      return () => {
        document.removeEventListener('click', handleClickOutside);
        document.removeEventListener('keydown', handleKeyDown);
      };
    }
  });
</script>

<div class="space-y-2" bind:this={searchContainer}>
  <label class="block text-sm font-medium text-gray-700">
    Select the protest entry to reference {required ? '*' : ''}
  </label>

  {#if !selectedProtest}
    <div class="relative">
      <input
        type="text"
        value={searchQuery}
        oninput={handleSearchInput}
        onfocus={() => { if (searchResults.length > 0) showResults = true; }}
        placeholder="Search by location, date, organization, or keywords..."
        class="w-full px-4 py-2 pr-10 border rounded-md shadow-sm
               focus:ring-blue-500 focus:border-blue-500 transition-colors
               {error ? 'border-red-300 focus:ring-red-500 focus:border-red-500' : 'border-gray-300'}"
      />

      {#if isSearching}
        <div class="absolute right-3 top-2.5">
          <div class="animate-spin h-5 w-5 border-2 border-blue-500
                      border-t-transparent rounded-full"></div>
        </div>
      {:else if searchQuery.length >= 3 && !showResults}
        <div class="absolute right-3 top-2.5">
          <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </div>
      {/if}

      {#if showResults && searchResults.length > 0}
        <div class="absolute z-10 mt-1 w-full bg-white rounded-md
                    shadow-lg max-h-72 overflow-auto border border-gray-200">
          {#each searchResults as protest}
            <button
              type="button"
              onclick={() => selectProtest(protest)}
              class="w-full text-left px-4 py-3 hover:bg-gray-50
                     focus:bg-blue-50 focus:outline-none border-b border-gray-100
                     transition-colors last:border-b-0"
            >
              <div class="font-medium text-gray-900">
                {protest.title}
              </div>
              <div class="text-sm text-gray-600 mt-1">
                <span class="inline-flex items-center">
                  <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                  {formatDate(protest.date_of_event)}
                </span>
                <span class="mx-1">•</span>
                <span class="inline-flex items-center">
                  <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                  {protest.locality}, {protest.state_code}
                </span>
                {#if protest.organization_name}
                  <span class="mx-1">•</span>
                  <span>{protest.organization_name}</span>
                {/if}
              </div>
              {#if protest.claims_summary}
                <div class="text-xs text-gray-500 mt-1 line-clamp-2">
                  {protest.claims_summary}
                </div>
              {/if}
            </button>
          {/each}
        </div>
      {/if}

      {#if showResults && searchQuery.length >= 3 && searchResults.length === 0 && !isSearching}
        <div class="absolute z-10 mt-1 w-full bg-white rounded-md
                    shadow-lg border border-gray-200 p-4">
          <div class="text-gray-500 text-sm">
            <p class="font-medium">No matching protests found</p>
            <p class="mt-2 text-xs">Try searching by:</p>
            <ul class="mt-1 list-disc list-inside text-xs space-y-1">
              <li>City or state name (e.g., "New York" or "NY")</li>
              <li>Organization name</li>
              <li>Keywords from the event description</li>
              <li>Date in YYYY-MM-DD format</li>
            </ul>
          </div>
        </div>
      {/if}

      {#if searchQuery.length > 0 && searchQuery.length < 3}
        <p class="text-xs text-gray-500 mt-1">Enter at least 3 characters to search</p>
      {/if}
    </div>
  {:else}
    <div class="bg-blue-50 border border-blue-200 rounded-md p-4">
      <div class="flex justify-between items-start">
        <div class="flex-1">
          <div class="font-medium text-gray-900 flex items-center">
            <svg class="w-4 h-4 text-blue-600 mr-2" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
            </svg>
            {selectedProtest.title}
          </div>
          <div class="text-sm text-gray-600 mt-1 ml-6">
            <span class="inline-flex items-center">
              <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              {formatDate(selectedProtest.date_of_event)}
            </span>
            <span class="mx-1">•</span>
            <span class="inline-flex items-center">
              <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              {selectedProtest.locality}, {selectedProtest.state_code}
            </span>
          </div>
          {#if selectedProtest.organization_name}
            <div class="text-sm text-gray-600 ml-6">
              Organization: {selectedProtest.organization_name}
            </div>
          {/if}
          {#if selectedProtest.claims_summary}
            <div class="text-xs text-gray-500 mt-2 ml-6">
              {selectedProtest.claims_summary}
            </div>
          {/if}
        </div>
        <button
          type="button"
          onclick={clearSelection}
          class="ml-4 text-blue-600 hover:text-blue-800 text-sm font-medium
                 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500
                 rounded px-2 py-1 transition-colors"
        >
          Change
        </button>
      </div>
    </div>
    <input type="hidden" {name} value={selectedProtest.id} />
  {/if}

  {#if error}
    <p class="text-sm text-red-600 mt-1">{error}</p>
  {/if}
</div>