<!-- ProtestForm.svelte -->
<script lang="ts">
  import type { State, EventType, ParticipantType, ParticipantMeasure, PoliceMeasure, NotesOption, SubmissionType } from '$lib/types/database';
  import type { FormActionResult } from '$lib/types/forms';
  import { Turnstile } from 'svelte-turnstile';

  // Form sections
  import TextArea from './form/TextArea.svelte';
  import TextField from './form/TextField.svelte';
  import CheckboxGroup from './form/CheckboxGroup.svelte';
  import SubmissionTypeRadioGroup from './form/SubmissionTypeRadioGroup.svelte';
  import BasicInfoSection from './form/BasicInfoSection.svelte';
  import EventDetailsSection from './form/EventDetailsSection.svelte';
  import ClaimsSection from './form/ClaimsSection.svelte';
  import CrowdSizeSection from './form/CrowdSizeSection.svelte';
  import MeasuresSection from './form/MeasuresSection.svelte';
  import IncidentSection from './form/IncidentSection.svelte';
  import NotesSection from './form/NotesSection.svelte';

  // Lookup data is provided via props from the page's load() function (SSR)
  interface Props {
    states?: State[];
    eventTypes?: EventType[];
    participantTypes?: ParticipantType[];
    participantMeasures?: ParticipantMeasure[];
    policeMeasures?: PoliceMeasure[];
    notesOptions?: NotesOption[];
    submissionTypes?: SubmissionType[];
    form?: FormActionResult | null;
    enhance?: any;
  }

  let {
    states = [],
    eventTypes = [],
    participantTypes = [],
    participantMeasures = [],
    policeMeasures = [],
    notesOptions = [],
    submissionTypes = [],
    form = null,
    enhance
  }: Props = $props();

  // Comprehensive form data state
  let formData = $state({
    // Basic info
    date_of_event: '',
    locality: '',
    state_code: '',
    location_name: '',
    title: '',

    // Event details
    organization_name: '',
    notable_participants: '',
    targets: '',
    macroevent: '',

    // Claims
    claims_summary: '',
    claims_verbatim: '',

    // Crowd info
    is_online: false,
    crowd_size_low: '',
    crowd_size_high: '',
    count_method: '',

    // Incidents
    participant_injury: 'no',
    participant_injury_details: '',
    police_injury: 'no',
    police_injury_details: '',
    arrests: 'no',
    arrests_details: '',
    property_damage: 'no',
    property_damage_details: '',
    participant_casualties: 'no',
    participant_casualties_details: '',
    police_casualties: 'no',
    police_casualties_details: '',

    // Sources
    sources: '',

    // Multi-select arrays
    event_types: [] as string[],
    participant_types: [] as string[],
    participant_measures: [] as string[],
    police_measures: [] as string[],
    notes: [] as string[]
  });

  // Track "other" values
  let eventTypeOthers: Record<number, string> = { 0: '' };
  let participantMeasureOthers: Record<number, string> = { 0: '' };
  let policeMeasureOthers: Record<number, string> = { 0: '' };
  let notesOthers: Record<number, string> = { 0: '' };

  // Track online event state to conditionally show crowd size
  let isOnline = $derived(formData.is_online);

  // Track submission state
  let isSubmitting = $state(false);
  let isLoadingReference = $state(false);
  let referenceLoaded = $state(false);

  // Track single submission type and reference
  let selectedSubmissionType = $state('');
  let submissionTypeOther = $state('');
  let referencedProtestId = $state('');
  
  // Turnstile token
  let turnstileToken = $state('');
  let turnstileError = $state(false);
  // Ref to the Turnstile container for scrolling on validation failure
  let turnstileContainer: HTMLDivElement | null = null;
  
  // Get the site key with proper error handling
  const siteKey = import.meta.env.VITE_TURNSTILE_SITE_KEY;

  // Get errors from form action
  const errors = $derived(form?.errors || {});
  const errorMessage = $derived(form?.message || '');
  const hasErrors = $derived(Object.keys(errors).length > 0 || errorMessage);

  // Fetch and populate protest data when reference changes
  async function fetchAndPopulateProtestData(protestId: string) {
    if (!protestId) return;

    isLoadingReference = true;
    referenceLoaded = false;

    try {
      const response = await fetch(`/api/protests/${protestId}`);
      const data = await response.json();

      if (response.ok && data.protest) {
        const protest = data.protest;

        // Populate basic fields
        formData.date_of_event = protest.date_of_event || '';
        formData.locality = protest.locality || '';
        formData.state_code = protest.state_code || '';
        formData.location_name = protest.location_name || '';
        formData.title = protest.title || '';

        // Event details
        formData.organization_name = protest.organization_name || '';
        formData.notable_participants = protest.notable_participants || '';
        formData.targets = protest.targets || '';
        formData.macroevent = protest.macroevent || '';

        // Claims
        formData.claims_summary = protest.claims_summary || '';
        formData.claims_verbatim = protest.claims_verbatim || '';

        // Crowd info
        formData.is_online = protest.is_online || false;
        formData.crowd_size_low = protest.crowd_size_low?.toString() || '';
        formData.crowd_size_high = protest.crowd_size_high?.toString() || '';
        formData.count_method = protest.count_method || '';

        // Incidents
        formData.participant_injury = protest.participant_injury || 'no';
        formData.participant_injury_details = protest.participant_injury_details || '';
        formData.police_injury = protest.police_injury || 'no';
        formData.police_injury_details = protest.police_injury_details || '';
        formData.arrests = protest.arrests || 'no';
        formData.arrests_details = protest.arrests_details || '';
        formData.property_damage = protest.property_damage || 'no';
        formData.property_damage_details = protest.property_damage_details || '';
        formData.participant_casualties = protest.participant_casualties || 'no';
        formData.participant_casualties_details = protest.participant_casualties_details || '';
        formData.police_casualties = protest.police_casualties || 'no';
        formData.police_casualties_details = protest.police_casualties_details || '';

        // Sources
        formData.sources = protest.sources || '';

        // Handle junction table data (multi-selects)
        formData.event_types = protest.event_types?.map((e: any) => e.event_type_id?.toString()).filter(Boolean) || [];
        formData.participant_types = protest.participant_types?.map((p: any) => p.participant_type_id?.toString()).filter(Boolean) || [];
        formData.participant_measures = protest.participant_measures?.map((m: any) => m.measure_id?.toString()).filter(Boolean) || [];
        formData.police_measures = protest.police_measures?.map((m: any) => m.measure_id?.toString()).filter(Boolean) || [];
        formData.notes = protest.notes?.map((n: any) => n.note_id?.toString()).filter(Boolean) || [];

        // Handle "other" values from junction tables
        protest.event_types?.forEach((e: any) => {
          if (e.other_value) eventTypeOthers[0] = e.other_value;
        });
        protest.participant_measures?.forEach((m: any) => {
          if (m.other_value) participantMeasureOthers[0] = m.other_value;
        });
        protest.police_measures?.forEach((m: any) => {
          if (m.other_value) policeMeasureOthers[0] = m.other_value;
        });
        protest.notes?.forEach((n: any) => {
          if (n.other_value) notesOthers[0] = n.other_value;
        });

        referenceLoaded = true;
      }
    } catch (err) {
      console.error('Error fetching protest data:', err);
    } finally {
      isLoadingReference = false;
    }
  }

  // Clear form data
  function clearFormData() {
    formData.date_of_event = '';
    formData.locality = '';
    formData.state_code = '';
    formData.location_name = '';
    formData.title = '';
    formData.organization_name = '';
    formData.notable_participants = '';
    formData.targets = '';
    formData.macroevent = '';
    formData.claims_summary = '';
    formData.claims_verbatim = '';
    formData.is_online = false;
    formData.crowd_size_low = '';
    formData.crowd_size_high = '';
    formData.count_method = '';
    formData.participant_injury = 'no';
    formData.participant_injury_details = '';
    formData.police_injury = 'no';
    formData.police_injury_details = '';
    formData.arrests = 'no';
    formData.arrests_details = '';
    formData.property_damage = 'no';
    formData.property_damage_details = '';
    formData.participant_casualties = 'no';
    formData.participant_casualties_details = '';
    formData.police_casualties = 'no';
    formData.police_casualties_details = '';
    formData.sources = '';
    formData.event_types = [];
    formData.participant_types = [];
    formData.participant_measures = [];
    formData.police_measures = [];
    formData.notes = [];
    eventTypeOthers = { 0: '' };
    participantMeasureOthers = { 0: '' };
    policeMeasureOthers = { 0: '' };
    notesOthers = { 0: '' };
    referenceLoaded = false;
  }

  // Watch for reference changes
  $effect(() => {
    const needsReference = ['2', '3'].includes(selectedSubmissionType);

    if (referencedProtestId && needsReference) {
      fetchAndPopulateProtestData(referencedProtestId);
    } else if (!needsReference && referenceLoaded) {
      clearFormData();
    }
  });
</script>

<div class="max-w-4xl mx-auto p-6">
  <h1 class="text-3xl font-bold mb-2">Public Source Creator</h1>
  <p class="text-gray-600 mb-8">Help us document protests accurately for the historical record.</p>

  <!-- Show reference loading indicator -->
  {#if isLoadingReference}
    <div class="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-md">
      <div class="flex items-center">
        <div class="animate-spin h-5 w-5 border-2 border-blue-500 border-t-transparent rounded-full mr-3"></div>
        <p class="text-sm font-medium text-blue-800">Loading protest data...</p>
      </div>
    </div>
  {/if}

  <!-- Show reference loaded indicator -->
  {#if referenceLoaded && !isLoadingReference}
    <div class="mb-6 p-4 bg-green-50 border border-green-200 rounded-md">
      <div class="flex items-start">
        <svg class="w-5 h-5 text-green-600 mt-0.5 mr-2" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
        </svg>
        <div class="flex-1">
          <p class="text-sm font-medium text-green-800">
            Form populated with data from referenced protest
          </p>
          <p class="text-xs text-green-600 mt-1">
            {#if selectedSubmissionType === '2'}
              Make corrections to any fields that need updating.
            {:else if selectedSubmissionType === '3'}
              Add or update sources as needed.
            {/if}
          </p>
        </div>
        <button
          type="button"
          onclick={clearFormData}
          class="ml-4 text-green-600 hover:text-green-800 text-sm font-medium"
        >
          Clear
        </button>
      </div>
    </div>
  {/if}

  <!-- Show validation errors -->
  {#if hasErrors}
    <div class="mb-6 p-4 bg-red-50 border border-red-200 rounded-md">
      {#if errorMessage}
        <p class="text-sm font-medium text-red-800 mb-2">{errorMessage}</p>
      {/if}
      {#if Object.keys(errors).length > 0}
        <h3 class="text-sm font-medium text-red-800 mb-2">Please fix the following errors:</h3>
        <ul class="list-disc list-inside text-sm text-red-700">
          {#each Object.entries(errors) as [field, fieldErrors]}
            {#if fieldErrors}
              {#each Array.isArray(fieldErrors) ? fieldErrors : [fieldErrors] as error}
                <li>{field}: {error}</li>
              {/each}
            {/if}
          {/each}
        </ul>
      {/if}
    </div>
  {/if}

  <form 
    method="POST" 
    use:enhance={() => {
      isSubmitting = true;
      return async ({ result, update }: { result: any; update: () => Promise<void> }) => {
        isSubmitting = false;
        await update();
        // If the action failed due to CAPTCHA, show the inline error and scroll to the widget
        const message: string | undefined = result?.data?.message;
        if (result?.type === 'failure' && typeof message === 'string' && message.toLowerCase().includes('captcha')) {
          turnstileError = true;
          turnstileToken = '';
          // Scroll the CAPTCHA into view for the user
          turnstileContainer?.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
      };
    }}
    class="space-y-6"
  >
    <!-- Basic Information -->
    <BasicInfoSection
      {states}
      errors={errors}
      bind:dateOfEvent={formData.date_of_event}
      bind:locality={formData.locality}
      bind:stateCode={formData.state_code}
      bind:title={formData.title}
      bind:locationName={formData.location_name}
    />

    <!-- Submission Type -->
    <SubmissionTypeRadioGroup
      {submissionTypes}
      bind:value={selectedSubmissionType}
      bind:otherValue={submissionTypeOther}
      bind:referencedProtestId={referencedProtestId}
      errors={errors}
    />
    

    <!-- Event Details -->
    <EventDetailsSection
      {eventTypes}
      {participantTypes}
      bind:eventTypeOther={eventTypeOthers[0]}
      bind:selectedEventTypes={formData.event_types}
      bind:selectedParticipantTypes={formData.participant_types}
      bind:organizationName={formData.organization_name}
      bind:notableParticipants={formData.notable_participants}
      bind:targets={formData.targets}
      bind:macroevent={formData.macroevent}
    />

    <!-- Claims -->
    <ClaimsSection
      bind:claimsSummary={formData.claims_summary}
      bind:claimsVerbatim={formData.claims_verbatim}
    />

    <!-- Online Event Checkbox -->
    <div>
      <label class="flex items-center">
        <input
          type="checkbox"
          name="is_online"
          bind:checked={formData.is_online}
          class="rounded border-gray-300 text-blue-600"
        />
        <span class="ml-2 text-sm font-medium">This was an online event</span>
      </label>
    </div>

    <!-- Crowd Size (only show for non-online events) -->
    {#if !isOnline}
      <!-- Crowd Counting Method -->
      <TextField
        name="count_method"
        label="Crowd Counting Method"
        placeholder="e.g. sign-ins, counting through distributing flyers/handouts"
        required={!isOnline}
        bind:value={formData.count_method}
        error={errors.count_method?.[0] || null}
      />
      <CrowdSizeSection
        required={!isOnline}
        bind:crowdSizeLow={formData.crowd_size_low}
        bind:crowdSizeHigh={formData.crowd_size_high}
      />
    {/if}
    
    <!-- Measures -->
    <MeasuresSection
      {participantMeasures}
      {policeMeasures}
      bind:participantMeasureOther={participantMeasureOthers[0]}
      bind:policeMeasureOther={policeMeasureOthers[0]}
    />

    <!-- Incidents -->
    <IncidentSection />

    <!-- Notes -->
    <NotesSection
      {notesOptions}
      bind:notesOther={notesOthers[0]}
    />
    
    <TextArea
      name="sources"
      label="Source(s)"
      required
      placeholder="Include links to news articles, social media posts, etc."
      bind:value={formData.sources}
      error={errors.sources?.[0] || null}
      supplementalInformation="We discourage you from sharing any personal information like your name or email address. Information entered here will be publicly available."
    />

    <!-- Turnstile CAPTCHA -->
    <div class="pt-4" bind:this={turnstileContainer}>
      {#if siteKey}
        <Turnstile
          {siteKey}
          on:turnstile-callback={(e) => {
            turnstileToken = e.detail.token;
            turnstileError = false;
          }}
          on:turnstile-error={(e) => {
            console.error('Turnstile error:', e.detail);
            turnstileError = true;
            turnstileToken = '';
          }}
          on:turnstile-expired={() => {
            turnstileToken = '';
          }}
          theme="light"
          size="normal"
        />
        {#if turnstileError}
          <p class="mt-2 text-sm text-red-600">Please complete the CAPTCHA verification</p>
        {/if}
      {:else}
        <div class="p-4 bg-yellow-50 border border-yellow-200 rounded-md">
          <p class="text-sm text-yellow-800">CAPTCHA not configured. Please set VITE_TURNSTILE_SITE_KEY in your environment variables.</p>
        </div>
      {/if}
    </div>
    
    <!-- Hidden field to pass token to server -->
    <input type="hidden" name="turnstile_token" value={turnstileToken} />

    <!-- Submit Button -->
    <div class="pt-4">
      <button
        type="submit"
        disabled={isSubmitting}
        class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:bg-gray-400"
      >
        {isSubmitting ? 'Submitting...' : 'Submit Protest Information'}
      </button>
    </div>
  </form>
</div>