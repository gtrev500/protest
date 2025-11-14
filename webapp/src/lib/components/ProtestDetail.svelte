<!-- ProtestDetail.svelte -->
<script lang="ts">
  import { page } from '$app/stores';
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase';

  let protest: any | null = null;
  let loading = true;
  let referencedProtest: any | null = null;
  let corrections: any[] = [];

  async function loadProtest() {
    const id = $page.params.id;

    try {
      // Get protest details
      const { data, error } = await supabase
        .from('protest_details')
        .select('*')
        .eq('id', id)
        .single();

      if (error) throw error;

      protest = data;

      // Load related records
      await loadRelatedRecords();
    } catch (error) {
      console.error('Error loading protest:', error);
    } finally {
      loading = false;
    }
  }

  async function loadRelatedRecords() {
    if (!protest) return;

    try {
      // Check if this is a data correction
      const isCorrection = protest.submission_types?.includes('data correction');

      if (isCorrection) {
        // Fetch the original protest this corrects
        const { data: originalData } = await supabase
          .from('protests')
          .select('referenced_protest_id')
          .eq('id', protest.id)
          .single();

        if (originalData?.referenced_protest_id) {
          const { data: refData } = await supabase
            .from('protest_details')
            .select('id, title, date_of_event, locality, state_code, submission_types')
            .eq('id', originalData.referenced_protest_id)
            .single();

          referencedProtest = refData;
        }
      } else {
        // Fetch any corrections that reference this protest
        const { data: correctionsData } = await supabase
          .from('protests')
          .select('id')
          .eq('referenced_protest_id', protest.id);

        if (correctionsData && correctionsData.length > 0) {
          const correctionIds = correctionsData.map(c => c.id);

          const { data: correctionDetails } = await supabase
            .from('protest_details')
            .select('id, title, date_of_event, locality, state_code, submission_types, created_at')
            .in('id', correctionIds)
            .order('created_at', { ascending: false });

          corrections = correctionDetails || [];
        }
      }
    } catch (error) {
      console.error('Error loading related records:', error);
    }
  }

  // Reactive effect to reload when the route parameter changes
  $: if ($page.params.id) {
    // Reset state before loading new data
    loading = true;
    referencedProtest = null;
    corrections = [];
    loadProtest();
  }

  function formatDate(dateStr: string): string {
    if (!dateStr) return '';
    // Add 'T00:00:00' to ensure the date is parsed as local time, not UTC
    // This prevents the date from shifting due to timezone differences
    return new Date(dateStr + 'T00:00:00').toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  }

  function formatNumber(num: number): string {
    if (!num) return '0';
    return new Intl.NumberFormat().format(num);
  }
</script>

<div class="max-w-4xl mx-auto p-6">
  {#if loading}
    <div class="text-center py-12">
      <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-brand-600"></div>
      <p class="mt-1 text-gray-500">Loading protest details...</p>
    </div>
  {:else if !protest}
    <div class="text-center py-12">
      <h2 class="text-2xl font-bold text-gray-900">Protest not found</h2>
      <p class="mt-1 text-gray-500">The protest you're looking for doesn't exist.</p>
      <a href="/log" class="mt-4 inline-block text-brand-600 hover:text-brand-900">
        ← Back to Log
      </a>
    </div>
  {:else}
    <!-- Header -->
    <div class="mb-6">
      <a href="/log" class="text-brand-600 hover:text-brand-900 mb-4 inline-block">
        ← Back to Log
      </a>
      <h1 class="text-3xl font-bold text-gray-900">{protest.title}</h1>
      <p class="text-lg text-gray-600 mt-1">
        {formatDate(protest.date_of_event)} • {protest.locality}, {protest.state_code}
      </p>
    </div>

    <!-- Main Info Card -->
    <div class="bg-white shadow rounded-lg p-6 mb-6">
      <h2 class="text-xl font-semibold mb-4">Basic Information</h2>
      
      <dl class="grid grid-cols-1 md:grid-cols-2 gap-4">
        {#if protest.location_name}
          <div>
            <dt class="text-sm font-medium text-gray-500">Specific Location</dt>
            <dd class="mt-1 text-sm text-gray-900">{protest.location_name}</dd>
          </div>
        {/if}
        
        {#if protest.organization_name}
          <div>
            <dt class="text-sm font-medium text-gray-500">Organization</dt>
            <dd class="mt-1 text-sm text-gray-900">{protest.organization_name}</dd>
          </div>
        {/if}
        
        <div>
          <dt class="text-sm font-medium text-gray-500">Online Event</dt>
          <dd class="mt-1 text-sm text-gray-900">{protest.is_online ? 'Yes' : 'No'}</dd>
        </div>
        {#if protest.crowd_size_low || protest.crowd_size_high}
          <div>
            <dt class="text-sm font-medium text-gray-500">Estimated Attendance</dt>
            <dd class="mt-1 text-sm text-gray-900">
              {formatNumber(protest.crowd_size_low)} - {formatNumber(protest.crowd_size_high)} participants
            </dd>
          </div>
        {/if}
        {#if protest.count_methods && protest.count_methods.length > 0}
          <div>
            <dt class="text-sm font-medium text-gray-500">Crowd Counting Methods</dt>
            <dd class="mt-1 text-sm text-gray-900">
              {protest.count_methods.join(', ')}
            </dd>
          </div>
        {/if}

        {#if protest.macroevent}
          <div class="col-span-2">
            <dt class="text-sm font-medium text-gray-500">Part of Larger Event</dt>
            <dd class="mt-1 text-sm text-gray-900">{protest.macroevent}</dd>
          </div>
        {/if}
      </dl>
    </div>

    <!-- Event Types -->
    {#if protest.event_types && protest.event_types.length > 0}
      <div class="bg-white shadow rounded-lg p-6 mb-6">
        <h2 class="text-xl font-semibold mb-4">Event Types</h2>
        <div class="flex flex-wrap gap-2">
          {#each protest.event_types as type}
            <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-brand-100 text-brand-800">
              {type}
            </span>
          {/each}
        </div>
      </div>
    {/if}

    <!-- Claims and Messaging -->
    <div class="bg-white shadow rounded-lg p-6 mb-6">
      <h2 class="text-xl font-semibold mb-4">Claims and Messaging</h2>
      
      {#if protest.targets}
        <div class="mb-4">
          <dt class="text-sm font-medium text-gray-500">Targets</dt>
          <dd class="mt-1 text-sm text-gray-900">{protest.targets}</dd>
        </div>
      {/if}
      
      {#if protest.claims_summary}
        <div class="mb-4">
          <dt class="text-sm font-medium text-gray-500">Claims Summary</dt>
          <dd class="mt-1 text-sm text-gray-900">{protest.claims_summary}</dd>
        </div>
      {/if}
      
      {#if protest.claims_verbatim}
        <div>
          <dt class="text-sm font-medium text-gray-500">Signs and Chants</dt>
          <dd class="mt-1 text-sm text-gray-900 whitespace-pre-wrap">{protest.claims_verbatim}</dd>
        </div>
      {/if}
    </div>

    <!-- Participants -->
    <div class="bg-white shadow rounded-lg p-6 mb-6">
      <h2 class="text-xl font-semibold mb-4">Participants</h2>
      
      {#if protest.notable_participants}
        <div class="mb-4">
          <dt class="text-sm font-medium text-gray-500">Notable Participants</dt>
          <dd class="mt-1 text-sm text-gray-900">{protest.notable_participants}</dd>
        </div>
      {/if}
      
      {#if protest.participant_types && protest.participant_types.length > 0}
        <div>
          <dt class="text-sm font-medium text-gray-500 mb-2">Participant Types</dt>
          <dd class="flex flex-wrap gap-2">
            {#each protest.participant_types as type}
              <span class="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-green-100 text-green-800">
                {type}
              </span>
            {/each}
          </dd>
        </div>
      {/if}
    </div>

    <!-- Actions and Measures -->
    {#if (protest.participant_measures_list && protest.participant_measures_list.length > 0) || 
         (protest.police_measures_list && protest.police_measures_list.length > 0)}
      <div class="bg-white shadow rounded-lg p-6 mb-6">
        <h2 class="text-xl font-semibold mb-4">Actions and Response</h2>
        
        {#if protest.participant_measures_list && protest.participant_measures_list.length > 0}
          <div class="mb-4">
            <dt class="text-sm font-medium text-gray-500 mb-2">Participant Actions</dt>
            <dd class="flex flex-wrap gap-2">
              {#each protest.participant_measures_list as measure}
                <span class="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-purple-100 text-purple-800">
                  {measure}
                </span>
              {/each}
            </dd>
          </div>
        {/if}
        
        {#if protest.police_measures_list && protest.police_measures_list.length > 0}
          <div>
            <dt class="text-sm font-medium text-gray-500 mb-2">Police Response</dt>
            <dd class="flex flex-wrap gap-2">
              {#each protest.police_measures_list as measure}
                <span class="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-danger-100 text-danger-800">
                  {measure}
                </span>
              {/each}
            </dd>
          </div>
        {/if}
      </div>
    {/if}

    <!-- Incidents -->
    <div class="bg-white shadow rounded-lg p-6 mb-6">
      <h2 class="text-xl font-semibold mb-4">Incident Report</h2>
      
      <dl class="grid grid-cols-2 gap-4">
        <div>
          <dt class="text-sm font-medium text-gray-500">Participant Injuries</dt>
          <dd class="mt-1">
            <span class={`inline-flex px-2 py-1 text-xs rounded-full ${
              protest.participant_injury === 'yes' ? 'bg-danger-100 text-danger-800' : 'bg-green-100 text-green-800'
            }`}>
              {protest.participant_injury === 'yes' ? 'Yes' : 'No'}
            </span>
            {#if protest.participant_injury_details}
              <p class="text-sm text-gray-600 mt-1">{protest.participant_injury_details}</p>
            {/if}
          </dd>
        </div>
        
        <div>
          <dt class="text-sm font-medium text-gray-500">Police Injuries</dt>
          <dd class="mt-1">
            <span class={`inline-flex px-2 py-1 text-xs rounded-full ${
              protest.police_injury === 'yes' ? 'bg-danger-100 text-danger-800' : 'bg-green-100 text-green-800'
            }`}>
              {protest.police_injury === 'yes' ? 'Yes' : 'No'}
            </span>
            {#if protest.police_injury_details}
              <p class="text-sm text-gray-600 mt-1">{protest.police_injury_details}</p>
            {/if}
          </dd>
        </div>
        
        <div>
          <dt class="text-sm font-medium text-gray-500">Arrests</dt>
          <dd class="mt-1">
            <span class={`inline-flex px-2 py-1 text-xs rounded-full ${
              protest.arrests === 'yes' ? 'bg-yellow-100 text-yellow-800' : 'bg-green-100 text-green-800'
            }`}>
              {protest.arrests === 'yes' ? 'Yes' : 'No'}
            </span>
            {#if protest.arrests_details}
              <p class="text-sm text-gray-600 mt-1">{protest.arrests_details}</p>
            {/if}
          </dd>
        </div>
        
        <div>
          <dt class="text-sm font-medium text-gray-500">Property Damage</dt>
          <dd class="mt-1">
            <span class={`inline-flex px-2 py-1 text-xs rounded-full ${
              protest.property_damage === 'yes' ? 'bg-orange-100 text-orange-800' : 'bg-green-100 text-green-800'
            }`}>
              {protest.property_damage === 'yes' ? 'Yes' : 'No'}
            </span>
            {#if protest.property_damage_details}
              <p class="text-sm text-gray-600 mt-1">{protest.property_damage_details}</p>
            {/if}
          </dd>
        </div>
      </dl>
    </div>

    <!-- Sources -->
    {#if protest.sources}
      <div class="bg-white shadow rounded-lg p-6 mb-6">
        <h2 class="text-xl font-semibold mb-4">Sources</h2>
        <div class="text-sm text-gray-900 whitespace-pre-wrap break-words">{protest.sources}</div>
      </div>
    {/if}

    <!-- Notes -->
    {#if protest.notes_list && protest.notes_list.length > 0}
      <div class="bg-white shadow rounded-lg p-6 mb-6">
        <h2 class="text-xl font-semibold mb-4">Additional Notes</h2>
        <ul class="list-disc list-inside space-y-1">
          {#each protest.notes_list as note}
            <li class="text-sm text-gray-900">{note}</li>
          {/each}
        </ul>
      </div>
    {/if}

    <!-- Related Records -->
    {#if referencedProtest}
      <!-- If this is a data correction, show the original record -->
      <a
        href="/protest/{referencedProtest.id}"
        class="block bg-brand-50 rounded-lg border-2 border-brand-200 p-6 mb-6 hover:bg-brand-100 hover:border-brand-300 transition-all"
      >
        <div class="flex items-start gap-3">
          <svg class="w-6 h-6 text-brand-600 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 15l-3-3m0 0l3-3m-3 3h8M3 12a9 9 0 1118 0 9 9 0 01-18 0z" />
          </svg>
          <div class="flex-1">
            <h3 class="text-sm font-semibold text-brand-900 mb-3">
              This correction updates the following record:
            </h3>
            <div class="font-medium text-brand-900 text-lg">{referencedProtest.title}</div>
            <div class="text-sm text-brand-700 mt-2">
              {formatDate(referencedProtest.date_of_event)} • {referencedProtest.locality}, {referencedProtest.state_code}
            </div>
            <div class="flex items-center gap-2 mt-3 text-sm text-brand-600 font-medium">
              <span>View original record</span>
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </div>
          </div>
        </div>
      </a>
    {/if}

    {#if corrections.length > 0}
      <!-- If this is a new record, show any corrections -->
      <div class="bg-white shadow rounded-lg p-6 mb-6">
        <h2 class="text-xl font-semibold mb-4 flex items-center gap-2">
          <svg class="w-5 h-5 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
          {corrections.length === 1 ? 'This record has been corrected' : `This record has ${corrections.length} corrections`}
        </h2>
        <div class="space-y-3">
          {#each corrections as correction}
            <a
              href="/protest/{correction.id}"
              class="block p-4 bg-amber-50 rounded-lg border border-amber-200 hover:bg-amber-100 hover:border-amber-300 transition-all"
            >
              <div class="font-medium text-amber-900">{correction.title}</div>
              <div class="text-sm text-amber-700 mt-1">
                {formatDate(correction.date_of_event)} • {correction.locality}, {correction.state_code}
              </div>
              <div class="flex items-center gap-2 mt-2 text-sm text-amber-600 font-medium">
                <span>View correction</span>
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
              </div>
            </a>
          {/each}
        </div>
      </div>
    {/if}

    <!-- Share Section -->
    <div class="bg-gray-50 rounded-lg p-6 text-center">
      <h3 class="text-lg font-semibold mb-2">Share This Protest</h3>
      <p class="text-sm text-gray-600 mb-4">
        Public URL: <code class="bg-gray-200 px-2 py-1 rounded">{$page.url.origin}/protest/{protest.id}</code>
      </p>
      <button
        on:click={() => navigator.clipboard.writeText(`${$page.url.origin}/protest/${protest.id}`)}
        class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-brand-600 hover:bg-brand-700"
      >
        Copy Link
      </button>
    </div>
  {/if}
</div>