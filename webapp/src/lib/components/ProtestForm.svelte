<!-- ProtestForm.svelte -->
<script lang="ts">
  import { createForm } from 'felte';
  import { validator } from '@felte/validator-zod';
  import { supabase } from '$lib/supabase';
  import { goto } from '$app/navigation';
  import { Turnstile } from 'svelte-turnstile';
  import type { State, EventType, ParticipantType, ParticipantMeasure, PoliceMeasure, NotesOption } from '$lib/types/database';
  import { protestFormSchema, type ProtestFormSchema } from '$lib/types/schemas';
  import { prepareSubmissionData } from '$lib/utils/formDataPreparation';
  
  // Form sections
  import TextArea from './form/TextArea.svelte';
  import TextField from './form/TextField.svelte';
  import BasicInfoSection from './form/BasicInfoSection.svelte';
  import EventDetailsSection from './form/EventDetailsSection.svelte';
  import ClaimsSection from './form/ClaimsSection.svelte';
  import CrowdSizeSection from './form/CrowdSizeSection.svelte';
  import MeasuresSection from './form/MeasuresSection.svelte';
  import IncidentSection from './form/IncidentSection.svelte';
  import NotesSection from './form/NotesSection.svelte';

  // Lookup data is provided via props from the page's load() function (SSR)
  export let states: State[] = [];
  export let eventTypes: EventType[] = [];
  export let participantTypes: ParticipantType[] = [];
  export let participantMeasures: ParticipantMeasure[] = [];
  export let policeMeasures: PoliceMeasure[] = [];
  export let notesOptions: NotesOption[] = [];

  // Track "other" values (use numeric key 0 instead of string "other")
  let eventTypeOthers: Record<number, string> = { 0: '' };
  let participantMeasureOthers: Record<number, string> = { 0: '' };
  let policeMeasureOthers: Record<number, string> = { 0: '' };
  let notesOthers: Record<number, string> = { 0: '' };

  // Track whether to show validation errors
  let showValidationErrors = false;
  
  // Track online event state to conditionally show crowd size
  //let isOnline = $state(false);
  let isOnline = false;
  
  // Turnstile token
  let turnstileToken = '';
  let turnstileError = false;
  
  // Get the site key with proper error handling
  const siteKey = import.meta.env.VITE_TURNSTILE_SITE_KEY;  
  // Form handling
  const { form, errors, isSubmitting } = createForm<ProtestFormSchema>({
    initialValues: {
      // Required fields
      date_of_event: '',
      locality: '',
      state_code: '',
      title: '',
      
      // Optional fields
      location_name: '',
      organization_name: '',
      notable_participants: '',
      targets: '',
      claims_summary: '',
      claims_verbatim: '',
      macroevent: '',
      is_online: false,
      count_method: '',
      crowd_size_low: null,
      crowd_size_high: null,
      sources: '',
      
      // Checkboxes
      event_types: [],
      participant_types: [],
      participant_measures: [],
      police_measures: [],
      notes: [],
      
      // Incident fields with details
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
      police_casualties_details: ''
    },
    extend: validator({ schema: protestFormSchema }),
    onSubmit: async (values) => {
      try {
        // Validate Turnstile token first
        if (!turnstileToken) {
          turnstileError = true;
          throw new Error('Please complete the CAPTCHA verification');
        }

        // Validate the token with the server
        const turnstileValidation = await fetch('/api/validate-turnstile', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ token: turnstileToken }),
        });

        const turnstileResult = await turnstileValidation.json();
        
        if (!turnstileResult.success) {
          turnstileError = true;
          throw new Error('CAPTCHA verification failed. Please try again.');
        }

        // Prepare data for submission using the utility function
        const submissionData = prepareSubmissionData(values, {
          eventTypeOthers,
          participantMeasureOthers,
          policeMeasureOthers,
          notesOthers
        });

        // Submit using the database function
        const { data, error } = await supabase.rpc('submit_protest', submissionData);

        if (error) {
          console.error('Supabase RPC error:', error);
          console.error('Error details:', error.message, error.details, error.hint);
          throw error;
        }

        console.log('RPC response:', data);
        
        if (!data || !data.id) {
          throw new Error('No ID returned from submission');
        }

        // Redirect to success page with public URL
        goto(`/success?id=${data.id}`);
      } catch (error) {
        console.error('Error submitting protest:', error);
        // Show error to user - you might want to add error state here
      }
    }
  });
</script>

<div class="max-w-4xl mx-auto p-6">
  <h1 class="text-3xl font-bold mb-2">Protest Crowd Counts & Information</h1>
  <p class="text-gray-600 mb-8">Help us document protests accurately for the historical record.</p>

  <!-- Show validation errors only after submit attempt -->
  {#if showValidationErrors && $errors && Object.keys($errors).length > 0}
    <div class="mb-6 p-4 bg-red-50 border border-red-200 rounded-md">
      <h3 class="text-sm font-medium text-red-800 mb-2">Please fix the following errors:</h3>
      <ul class="list-disc list-inside text-sm text-red-700">
        {#each Object.entries($errors) as [field, error]}
          {#if error}
            <li>{field}: {error}</li>
          {/if}
        {/each}
      </ul>
    </div>
  {/if}

  <form use:form class="space-y-6">
    <!-- Basic Information -->
    <BasicInfoSection {states} errors={$errors} />

    <!-- Event Details -->
    <EventDetailsSection 
      {eventTypes} 
      {participantTypes}
      bind:eventTypeOther={eventTypeOthers[0]}
    />

    <!-- Claims -->
    <ClaimsSection />

    <!-- Online Event Checkbox -->
    <div>
      <label class="flex items-center">
        <input
          type="checkbox"
          name="is_online"
          bind:checked={isOnline}
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
        error={$errors.count_method as string | null}
      />
      <CrowdSizeSection />

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
      error={$errors.sources as string | null}
      supplementalInformation="We discourage you from sharing any personal information like your name or email address. Information entered here will be publicly available."
    />

    <!-- Turnstile CAPTCHA -->
    <div class="pt-4">
      {#if siteKey}
        <Turnstile
          siteKey={siteKey}
          on:turnstile-callback={(e) => {
            console.log('Turnstile callback received:', e.detail);
            turnstileToken = e.detail.token;
            turnstileError = false;
            console.log('Token set:', turnstileToken);
          }}
          on:turnstile-error={(e) => {
            console.error('Turnstile error:', e.detail);
            turnstileError = true;
            turnstileToken = '';
          }}
          on:turnstile-expired={() => {
            console.log('Turnstile expired');
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

    <!-- Submit Button -->
    <div class="pt-4">
      <button
        type="submit"
        disabled={$isSubmitting}
        on:click={() => {
          showValidationErrors = true;
        }}
        class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:bg-gray-400"
      >
        {$isSubmitting ? 'Submitting...' : 'Submit Protest Information'}
      </button>
    </div>
  </form>
</div>