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
    required = false, // Available for form validation even though not displayed
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

  // Extract UUID from various URL formats
  function extractProtestId(input: string): string | null {
    // Match patterns like:
    // - https://domain.com/protest/494f00e2-8c7d-49c2-a466-688b86de0b1c
    // - http://localhost:3000/protest/494f00e2-8c7d-49c2-a466-688b86de0b1c
    // - /protest/494f00e2-8c7d-49c2-a466-688b86de0b1c
    // - 494f00e2-8c7d-49c2-a466-688b86de0b1c (just the UUID)

    const patterns = [
      /\/protest\/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/i,
      /^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$/i
    ];

    for (const pattern of patterns) {
      const match = input.match(pattern);
      if (match) {
        return match[1];
      }
    }

    return null;
  }

  async function fetchProtestById(id: string) {
    isSearching = true;
    try {
      const response = await fetch(`/api/protests/${id}`);
      const data = await response.json();

      if (response.ok && data.protest) {
        const protest = data.protest;
        selectProtest({
          id: protest.id,
          title: protest.title || 'Untitled Event',
          date_of_event: protest.date_of_event,
          locality: protest.locality,
          state_code: protest.state_code,
          claims_summary: protest.claims_summary,
          organization_name: protest.organization_name
        });
      } else {
        console.error('Failed to fetch protest:', data.error);
        // Still perform regular search with the input
        await performSearch(searchQuery);
      }
    } catch (err) {
      console.error('Error fetching protest by ID:', err);
      // Fall back to regular search
      await performSearch(searchQuery);
    } finally {
      isSearching = false;
    }
  }

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

    // Check if input looks like a URL or UUID
    const protestId = extractProtestId(searchQuery);
    if (protestId) {
      // If we extracted a UUID, fetch it immediately
      fetchProtestById(protestId);
      return;
    }

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
                {formatDate(protest.date_of_event)} • {protest.locality}, {protest.state_code}
                {#if protest.organization_name}
                  • {protest.organization_name}
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
      {:else if !searchQuery}
        <p class="text-xs text-gray-500 mt-1">Tip: You can paste a protest page URL directly</p>
      {/if}
    </div>
  {:else}
    <div class="border rounded-md p-3 bg-gray-50">
      <div class="flex justify-between items-start">
        <div class="flex-1">
          <div class="font-medium text-gray-900">
            {selectedProtest.title}
          </div>
          <div class="text-sm text-gray-600 mt-1">
            {formatDate(selectedProtest.date_of_event)} • {selectedProtest.locality}, {selectedProtest.state_code}
            {#if selectedProtest.organization_name}
              • {selectedProtest.organization_name}
            {/if}
          </div>
          {#if selectedProtest.claims_summary}
            <div class="text-xs text-gray-500 mt-2">
              {selectedProtest.claims_summary}
            </div>
          {/if}
        </div>
        <button
          type="button"
          onclick={clearSelection}
          class="ml-4 text-blue-600 hover:text-blue-800 text-sm"
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