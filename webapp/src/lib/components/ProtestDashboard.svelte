<!-- ProtestDashboard.svelte -->
<script lang="ts">
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase';
  import { Tooltip, DateRangePicker, Combobox, type DateRange } from 'bits-ui';
  import { CalendarDate } from '@internationalized/date';

  let { showMetrics = false } = $props();

  let protests = $state<any[]>([]);
  let stats = $state<any>(null);
  let loading = $state(true);
  let searchTerm = $state('');
  let selectedState = $state('');
  let dateRange = $state<DateRange | undefined>(undefined);
  let page = $state(1);
  let pageSize = 20;
  let totalCount = $state(0);
  let sortField = $state('date_of_event');
  let sortOrder = $state('desc');
  let searchDebounceTimer: number | undefined;
  let showSearchHelp = $state(false);
  let searchValue = $state('');

  // Derived values for date range (convert CalendarDate to string for API)
  let startDate = $derived(
    dateRange?.start
      ? `${dateRange.start.year}-${String(dateRange.start.month).padStart(2, '0')}-${String(dateRange.start.day).padStart(2, '0')}`
      : ''
  );

  let endDate = $derived(
    dateRange?.end
      ? `${dateRange.end.year}-${String(dateRange.end.month).padStart(2, '0')}-${String(dateRange.end.day).padStart(2, '0')}`
      : ''
  );

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
  let states = $state<any[]>([]);
  async function loadStates() {
    const { data } = await supabase.from('states').select('*').order('name');
    states = data || [];
  }

  // Filter states based on search input for Combobox
  const filteredStates = $derived(
    searchValue === ''
      ? states
      : states.filter((state) =>
          state.name.toLowerCase().includes(searchValue.toLowerCase()) ||
          state.code.toLowerCase().includes(searchValue.toLowerCase())
        )
  );

  // Watch for date range changes and trigger filter
  $effect(() => {
    if (dateRange !== undefined) {
      handleFilterChange();
    }
  });

  onMount(() => {
    loadStates();
    loadProtests();

    return () => {
      clearTimeout(searchDebounceTimer);
    };
  });

  // Computed values
  let totalPages = $derived(Math.ceil(totalCount / pageSize));
  
  function formatNumber(num: number) {
    if (!num) return '0';
    return new Intl.NumberFormat().format(num);
  }

  function formatDate(dateStr: string) {
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
  function handleColumnSort(field: string) {
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
  function getSortIcon(field: string) {
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
          <Tooltip.Provider delayDuration={200}>
            <Tooltip.Root bind:open={showSearchHelp}>
              <Tooltip.Trigger
                class="relative inline-flex items-center group align-middle ml-1 focus:outline-none focus:ring-2 focus:ring-blue-500 rounded"
                aria-label="Toggle advanced search help"
              >
                <svg class="inline-block w-4 h-4 text-gray-400 hover:text-gray-600" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
                </svg>
              </Tooltip.Trigger>

              <Tooltip.Portal>
                <Tooltip.Content
                  side="top"
                  sideOffset={8}
                  class="px-3 py-2 bg-gray-800 text-white text-sm rounded-md shadow-lg max-w-[90vw] sm:w-72 break-words z-50"
                >
                  <strong class="block mb-1">Search Tips:</strong>
                  "exact phrase"<br/>
                  term1 OR term2<br/>
                  -excludeTerm<br/>
                  <span class="text-xs text-gray-300 mt-1 block">Ex: "No Kings" CT -Granby</span>
                  <Tooltip.Arrow class="fill-gray-800" />
                </Tooltip.Content>
              </Tooltip.Portal>
            </Tooltip.Root>
          </Tooltip.Provider>
        </label>
        <input
          type="text"
          id="search"
          bind:value={searchTerm}
          oninput={handleSearchInput}
          placeholder="Search protests..."
          class="w-full rounded-md border-gray-300"
        />
      </div>

      <div>
        <label for="state-combobox" class="block text-sm font-medium text-gray-700 mb-1">
          State
        </label>
        <Combobox.Root
          type="single"
          bind:value={selectedState}
          onOpenChange={(isOpen) => {
            if (!isOpen) searchValue = '';
            if (!isOpen && selectedState !== '') handleFilterChange();
          }}
        >
          <div class="relative">
            <Combobox.Input
              id="state-combobox"
              placeholder="Search states..."
              oninput={(e) => (searchValue = e.currentTarget.value)}
              class="w-full rounded-md border-gray-300 pr-10 focus:ring-blue-500 focus:border-blue-500"
              aria-label="Search states"
            />

            <Combobox.Trigger
              class="absolute right-0 top-0 h-full px-3 flex items-center text-gray-400 hover:text-gray-600"
              aria-label="Toggle state dropdown"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
              </svg>
            </Combobox.Trigger>
          </div>

          <Combobox.Portal>
            <Combobox.Content
              class="bg-white border border-gray-200 rounded-md shadow-lg mt-1 z-50 max-h-60 overflow-hidden"
              sideOffset={4}
            >
              <Combobox.Viewport class="p-1">
                <Combobox.Item
                  value=""
                  label="All States"
                  class="px-3 py-2 text-sm cursor-pointer rounded hover:bg-blue-50 focus:bg-blue-50 focus:outline-none data-[highlighted]:bg-blue-100 data-[selected]:bg-blue-600 data-[selected]:text-white"
                >
                  {#snippet children({ selected })}
                    <div class="flex items-center justify-between">
                      <span>All States</span>
                      {#if selected}
                        <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                          <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                        </svg>
                      {/if}
                    </div>
                  {/snippet}
                </Combobox.Item>

                {#each filteredStates as state}
                  <Combobox.Item
                    value={state.code}
                    label={state.name}
                    class="px-3 py-2 text-sm cursor-pointer rounded hover:bg-blue-50 focus:bg-blue-50 focus:outline-none data-[highlighted]:bg-blue-100 data-[selected]:bg-blue-600 data-[selected]:text-white"
                  >
                    {#snippet children({ selected })}
                      <div class="flex items-center justify-between">
                        <span>{state.name} ({state.code})</span>
                        {#if selected}
                          <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                          </svg>
                        {/if}
                      </div>
                    {/snippet}
                  </Combobox.Item>
                {:else}
                  <div class="px-3 py-2 text-sm text-gray-500 text-center">
                    No states found
                  </div>
                {/each}
              </Combobox.Viewport>

              <Combobox.ScrollDownButton class="flex justify-center py-1">
                <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
                </svg>
              </Combobox.ScrollDownButton>
            </Combobox.Content>
          </Combobox.Portal>
        </Combobox.Root>
      </div>

      <div class="md:col-span-2">
        <label class="block text-sm font-medium text-gray-700 mb-1">
          Date Range
        </label>

        <DateRangePicker.Root
          bind:value={dateRange}
          weekdayFormat="short"
          class="flex flex-col gap-1.5"
        >
          <div class="flex gap-2 items-center border border-gray-300 rounded-md px-3 py-2 bg-white hover:border-gray-400 focus-within:ring-2 focus-within:ring-blue-500 focus-within:border-transparent">
            {#each ["start", "end"] as type}
              <DateRangePicker.Input type={type as "start" | "end"} class="flex items-center">
                {#snippet children({ segments })}
                  <div class="flex items-center gap-0.5">
                    {#each segments as { part, value }}
                      <DateRangePicker.Segment
                        {part}
                        class="px-0.5 rounded focus:bg-blue-100 focus:outline-none tabular-nums text-sm"
                      >
                        {value}
                      </DateRangePicker.Segment>
                    {/each}
                  </div>
                {/snippet}
              </DateRangePicker.Input>
              {#if type === "start"}
                <span class="text-gray-400">→</span>
              {/if}
            {/each}

            <DateRangePicker.Trigger
              class="ml-auto text-gray-400 hover:text-gray-600 focus:outline-none focus:ring-2 focus:ring-blue-500 rounded p-1"
              aria-label="Open date picker"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </DateRangePicker.Trigger>
          </div>

          <DateRangePicker.Content
            side="bottom"
            sideOffset={8}
            class="bg-white border border-gray-200 rounded-lg shadow-lg p-4 z-50"
          >
            <DateRangePicker.Calendar class="flex flex-col gap-4">
              {#snippet children({ months, weekdays })}
                <DateRangePicker.Header class="flex items-center justify-between mb-2">
                  <DateRangePicker.PrevButton class="p-2 hover:bg-gray-100 rounded focus:outline-none focus:ring-2 focus:ring-blue-500">
                    <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clip-rule="evenodd" />
                    </svg>
                  </DateRangePicker.PrevButton>
                  <DateRangePicker.Heading class="font-semibold text-gray-900" />
                  <DateRangePicker.NextButton class="p-2 hover:bg-gray-100 rounded focus:outline-none focus:ring-2 focus:ring-blue-500">
                    <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd" />
                    </svg>
                  </DateRangePicker.NextButton>
                </DateRangePicker.Header>

                {#each months as month}
                  <DateRangePicker.Grid class="border-collapse">
                    <DateRangePicker.GridHead>
                      <DateRangePicker.GridRow class="flex mb-1">
                        {#each weekdays as day}
                          <DateRangePicker.HeadCell class="w-10 text-center text-xs font-medium text-gray-500">
                            {day.slice(0, 2)}
                          </DateRangePicker.HeadCell>
                        {/each}
                      </DateRangePicker.GridRow>
                    </DateRangePicker.GridHead>

                    <DateRangePicker.GridBody>
                      {#each month.weeks as weekDates}
                        <DateRangePicker.GridRow class="flex">
                          {#each weekDates as date}
                            <DateRangePicker.Cell
                              {date}
                              month={month.value}
                              class="w-10 h-10 p-0"
                            >
                              <DateRangePicker.Day
                                class="w-full h-full flex items-center justify-center rounded hover:bg-blue-50 text-sm
                                       data-[selected]:bg-blue-600 data-[selected]:text-white
                                       data-[selection-start]:bg-blue-600 data-[selection-start]:text-white
                                       data-[selection-end]:bg-blue-600 data-[selection-end]:text-white
                                       data-[highlighted]:bg-blue-100
                                       data-[disabled]:text-gray-300 data-[disabled]:cursor-not-allowed
                                       data-[outside-month]:text-gray-400"
                              >
                                {date.day}
                              </DateRangePicker.Day>
                            </DateRangePicker.Cell>
                          {/each}
                        </DateRangePicker.GridRow>
                      {/each}
                    </DateRangePicker.GridBody>
                  </DateRangePicker.Grid>
                {/each}
              {/snippet}
            </DateRangePicker.Calendar>
          </DateRangePicker.Content>
        </DateRangePicker.Root>
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
                onclick={() => handleColumnSort('date_of_event')}
                  class="flex items-center gap-1 hover:text-gray-700 transition-colors"
                >
                  Event Date
                  <span class="text-gray-400">{getSortIcon('date_of_event')}</span>
                </button>
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                <button
                onclick={() => handleColumnSort('created_at')}
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
            onclick={() => { page--; loadProtests(); }}
            disabled={page === 1}
            class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50"
          >
            Previous
          </button>
          <button
            onclick={() => { page++; loadProtests(); }}
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
                onclick={() => { page = 1; loadProtests(); }}
                disabled={page === 1}
                class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
              >
                First
              </button>
              <button
                onclick={() => { page--; loadProtests(); }}
                disabled={page === 1}
                class="relative inline-flex items-center px-3 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50"
              >
                Previous
              </button>
              <span class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700">
                Page {page} of {totalPages}
              </span>
              <button
                onclick={() => { page++; loadProtests(); }}
                disabled={page === totalPages}
                class="relative inline-flex items-center px-3 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50"
              >
                Next
              </button>
              <button
                onclick={() => { page = totalPages; loadProtests(); }}
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