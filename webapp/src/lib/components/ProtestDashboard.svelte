<!-- ProtestDashboard.svelte -->
<script>
  import { onMount, onDestroy } from 'svelte';
  import { supabase } from '$lib/supabase';

  let { showMetrics = false } = $props();

  let protests = $state([]);
  let stats = $state(null);
  let loading = $state(true);
  let searchTerm = $state('');
  let selectedState = $state('');
  let startDate = $state('');
  let endDate = $state('');
  let page = $state(1);
  let pageSize = 20;
  let totalCount = $state(0);
  let sortField = $state('date_of_event');
  let sortOrder = $state('desc');
  let searchDebounceTimer;

  async function loadProtests() {
    loading = true;

    try {
      // Use the new RPC function for proper search handling
      const { data, error } = await supabase.rpc('search_protest_dashboard', {
        query_text: searchTerm || null,
        state_filter: selectedState || null,
        start_date_filter: startDate || null,
        end_date_filter: endDate || null,
        sort_field: sortField,
        sort_order: sortOrder,
        limit_count: pageSize,
        offset_count: (page - 1) * pageSize
      });

      if (error) throw error;

      protests = data || [];
      // Get total count from the first row (added via COUNT(*) OVER())
      totalCount = protests.length > 0 ? protests[0].total_count : 0;

      // Load stats
      const { data: statsData } = await supabase.rpc('get_protest_stats', {
        start_date: startDate || null,
        end_date: endDate || null
      });

      stats = statsData;
    } catch (error) {
      console.error('Error loading protests:', error);
    } finally {
      loading = false;
    }
  }

  // Load states for filter
  let states = $state([]);
  async function loadStates() {
    const { data } = await supabase.from('states').select('*').order('name');
    states = data || [];
  }

  onMount(() => {
    loadStates();
    loadProtests();
  });

  onDestroy(() => {
    clearTimeout(searchDebounceTimer);
  });

  // Computed values
  let totalPages = $derived(Math.ceil(totalCount / pageSize));
  
  function formatNumber(num) {
    if (!num) return '0';
    return new Intl.NumberFormat().format(num);
  }

  function formatDate(dateStr) {
    if (!dateStr) return '';
    // Check if it's already a timestamp with time (contains 'T')
    if (dateStr.includes('T')) {
      return new Date(dateStr).toLocaleDateString();
    }
    // Add 'T00:00:00' to ensure the date is parsed as local time, not UTC
    // This prevents the date from shifting due to timezone differences
    return new Date(dateStr + 'T00:00:00').toLocaleDateString();
  }

  // Reset page when filters change
  function handleFilterChange() {
    page = 1;
    loadProtests();
  }

  // Debounced search handler for search input
  function handleSearchInput() {
    clearTimeout(searchDebounceTimer);
    searchDebounceTimer = window.setTimeout(() => {
      page = 1;
      loadProtests();
    }, 300); // 300ms debounce
  }

  // Handle sort change
  function handleSortChange() {
    page = 1;
    loadProtests();
  }

  // Handle column header click for sorting
  function handleColumnSort(field) {
    if (sortField === field) {
      // Toggle sort order if clicking same column
      sortOrder = sortOrder === 'asc' ? 'desc' : 'asc';
    } else {
      // Default to descending when switching columns
      sortField = field;
      sortOrder = 'desc';
    }
    handleSortChange();
  }

  // Get sort icon for column header
  function getSortIcon(field) {
    if (sortField !== field) return ''; // No icon when not sorted
    return sortOrder === 'asc' ? '↑' : '↓';
  }
</script>

<div class="max-w-7xl mx-auto p-6">
  <h1 class="text-3xl font-bold mb-8">WeCountProject Form Submission Log</h1>

  <!-- Statistics Cards -->
  {#if showMetrics && stats}
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
      <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-sm font-medium text-gray-500">Total Protests</h3>
        <p class="text-3xl font-bold text-blue-600">{formatNumber(stats.total_protests)}</p>
      </div>
      
      <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-sm font-medium text-gray-500">Total Participants (Low)</h3>
        <p class="text-3xl font-bold text-green-600">{formatNumber(stats.total_participants_low)}</p>
      </div>
      
      <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-sm font-medium text-gray-500">Total Participants (High)</h3>
        <p class="text-3xl font-bold text-green-600">{formatNumber(stats.total_participants_high)}</p>
      </div>
      
      <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-sm font-medium text-gray-500">States Involved</h3>
        <p class="text-3xl font-bold text-purple-600">{formatNumber(stats.states_count)}</p>
      </div>
    </div>
  {/if}

  <!-- Filters -->
  <div class="bg-white rounded-lg shadow p-6 mb-6">
    <h2 class="text-lg font-semibold mb-4">Filters</h2>
    
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
      <div>
        <label for="search" class="block text-sm font-medium text-gray-700 mb-1">
          Search
          <span class="relative inline-block group">
            <svg class="inline-block w-4 h-4 ml-1 text-gray-400 cursor-help" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
            </svg>
            <span class="invisible group-hover:visible opacity-0 group-hover:opacity-100 transition-all duration-200 absolute z-50 bottom-full left-1/2 -translate-x-1/2 mb-2 px-3 py-2 bg-gray-800 text-white text-sm rounded-md shadow-lg w-72 pointer-events-none">
              <strong class="block mb-1">Advanced Search:</strong>
              • Phrases: "exact phrase"<br/>
              • OR: term1 OR term2<br/>
              • Exclude: -unwanted<br/>
              • Example: "police reform" Seattle -2020
              <span class="absolute top-full left-1/2 -translate-x-1/2 border-4 border-transparent border-t-gray-800"></span>
            </span>
          </span>
        </label>
        <input
          type="text"
          id="search"
          bind:value={searchTerm}
          on:input={handleSearchInput}
          placeholder="Search protests..."
          class="w-full rounded-md border-gray-300"
        />
      </div>

      <div>
        <label for="state" class="block text-sm font-medium text-gray-700 mb-1">
          State
        </label>
        <select
          id="state"
          bind:value={selectedState}
          on:change={handleFilterChange}
          class="w-full rounded-md border-gray-300"
        >
          <option value="">All States</option>
          {#each states as state}
            <option value={state.code}>{state.name}</option>
          {/each}
        </select>
      </div>

      <div>
        <label for="start_date" class="block text-sm font-medium text-gray-700 mb-1">
          Start Date
        </label>
        <input
          type="date"
          id="start_date"
          bind:value={startDate}
          on:change={handleFilterChange}
          class="w-full rounded-md border-gray-300"
        />
      </div>

      <div>
        <label for="end_date" class="block text-sm font-medium text-gray-700 mb-1">
          End Date
        </label>
        <input
          type="date"
          id="end_date"
          bind:value={endDate}
          on:change={handleFilterChange}
          class="w-full rounded-md border-gray-300"
        />
      </div>
    </div>
  </div>

  <!-- Protests Table -->
  <div class="bg-white rounded-lg shadow overflow-hidden">
    {#if loading}
      <div class="p-8 text-center">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        <p class="mt-2 text-gray-500">Loading protests...</p>
      </div>
    {:else if protests.length === 0}
      <div class="p-8 text-center text-gray-500">
        No protests found matching your criteria.
      </div>
    {:else}
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                <button
                  on:click={() => handleColumnSort('date_of_event')}
                  class="flex items-center gap-1 hover:text-gray-700 transition-colors"
                >
                  Event Date
                  <span class="text-gray-400">{getSortIcon('date_of_event')}</span>
                </button>
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                <button
                  on:click={() => handleColumnSort('created_at')}
                  class="flex items-center gap-1 hover:text-gray-700 transition-colors"
                >
                  Submitted
                  <span class="text-gray-400">{getSortIcon('created_at')}</span>
                </button>
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Title
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Location
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Participants
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Event Types
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            {#each protests as protest}
              <tr class="hover:bg-gray-50">
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {formatDate(protest.date_of_event)}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {formatDate(protest.created_at)}
                </td>
                <td class="px-6 py-4 text-sm text-gray-900">
                  <div class="font-medium">{protest.title}</div>
                  {#if protest.organization_name}
                    <div class="text-gray-500">{protest.organization_name}</div>
                  {/if}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {protest.locality}, {protest.state_code}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {#if protest.crowd_size_low || protest.crowd_size_high}
                    {formatNumber(protest.crowd_size_low)} - {formatNumber(protest.crowd_size_high)}
                  {:else}
                    <span class="text-gray-400">Not reported</span>
                  {/if}
                </td>
                <td class="px-6 py-4 text-sm text-gray-900">
                  <div class="flex flex-wrap gap-1">
                    {#if protest.event_types}
                      {#each protest.event_types.slice(0, 3) as type}
                        <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                          {type}
                        </span>
                      {/each}
                      {#if protest.event_types.length > 3}
                        <span class="text-xs text-gray-500">
                          +{protest.event_types.length - 3} more
                        </span>
                      {/if}
                    {/if}
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <a
                    href="/protest/{protest.id}"
                    class="text-blue-600 hover:text-blue-900"
                  >
                    View Details
                  </a>
                </td>
              </tr>
            {/each}
          </tbody>
        </table>
      </div>

      <!-- Pagination -->
      <div class="bg-gray-50 px-4 py-3 flex items-center justify-between sm:px-6">
        <div class="flex-1 flex justify-between sm:hidden">
          <button
            on:click={() => { page--; loadProtests(); }}
            disabled={page === 1}
            class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50"
          >
            Previous
          </button>
          <button
            on:click={() => { page++; loadProtests(); }}
            disabled={page === totalPages}
            class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50"
          >
            Next
          </button>
        </div>
        <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
          <div>
            <p class="text-sm text-gray-700">
              Showing <span class="font-medium">{(page - 1) * pageSize + 1}</span> to
              <span class="font-medium">{Math.min(page * pageSize, totalCount)}</span> of
              <span class="font-medium">{formatNumber(totalCount)}</span> results
            </p>
          </div>
          <div>
            <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px">
              <button
                on:click={() => { page = 1; loadProtests(); }}
                disabled={page === 1}
                class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
              >
                First
              </button>
              <button
                on:click={() => { page--; loadProtests(); }}
                disabled={page === 1}
                class="relative inline-flex items-center px-3 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50"
              >
                Previous
              </button>
              <span class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700">
                Page {page} of {totalPages}
              </span>
              <button
                on:click={() => { page++; loadProtests(); }}
                disabled={page === totalPages}
                class="relative inline-flex items-center px-3 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50"
              >
                Next
              </button>
              <button
                on:click={() => { page = totalPages; loadProtests(); }}
                disabled={page === totalPages}
                class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
              >
                Last
              </button>
            </nav>
          </div>
        </div>
      </div>
    {/if}
  </div>
</div>

<style>
  /* Custom styles if needed */
</style>