<!-- ProtestDashboard.svelte -->
<script>
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase';

  let protests = [];
  let stats = null;
  let loading = true;
  let searchTerm = '';
  let selectedState = '';
  let startDate = '';
  let endDate = '';
  let page = 1;
  let pageSize = 20;
  let totalCount = 0;

  async function loadProtests() {
    loading = true;
    
    try {
      // Build query
      let query = supabase
        .from('protest_details')
        .select('*', { count: 'exact' });

      // Apply filters
      if (searchTerm) {
        query = query.textSearch('search_vector', searchTerm);
      }
      if (selectedState) {
        query = query.eq('state_code', selectedState);
      }
      if (startDate) {
        query = query.gte('date_of_event', startDate);
      }
      if (endDate) {
        query = query.lte('date_of_event', endDate);
      }

      // Pagination
      const from = (page - 1) * pageSize;
      const to = from + pageSize - 1;
      
      const { data, error, count } = await query
        .order('date_of_event', { ascending: false })
        .range(from, to);

      if (error) throw error;

      protests = data || [];
      totalCount = count || 0;

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
  let states = [];
  async function loadStates() {
    const { data } = await supabase.from('states').select('*').order('name');
    states = data || [];
  }

  onMount(() => {
    loadStates();
    loadProtests();
  });

  // Computed values
  $: totalPages = Math.ceil(totalCount / pageSize);
  
  function formatNumber(num) {
    if (!num) return '0';
    return new Intl.NumberFormat().format(num);
  }

  function formatDate(dateStr) {
    if (!dateStr) return '';
    return new Date(dateStr).toLocaleDateString();
  }

  // Reset page when filters change
  function handleFilterChange() {
    page = 1;
    loadProtests();
  }
</script>

<div class="max-w-7xl mx-auto p-6">
  <h1 class="text-3xl font-bold mb-8">Protest Tracker Log</h1>

  <!-- Statistics Cards
  {#if stats}
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
  {/if} -->

  <!-- Filters -->
  <div class="bg-white rounded-lg shadow p-6 mb-6">
    <h2 class="text-lg font-semibold mb-4">Filters</h2>
    
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
      <div>
        <label for="search" class="block text-sm font-medium text-gray-700 mb-1">
          Search
        </label>
        <input
          type="text"
          id="search"
          bind:value={searchTerm}
          on:input={handleFilterChange}
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
                Date
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