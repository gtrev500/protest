<!-- ProtestForm.svelte -->
<script lang="ts">
  import type { State, EventType, ParticipantType, ParticipantMeasure, PoliceMeasure, NotesOption, SubmissionType } from '$lib/types/database';
  import type { FormActionResult } from '$lib/types/forms';
  
  // Form sections
  import TextArea from './form/TextArea.svelte';
  import TextField from './form/TextField.svelte';
  import CheckboxGroup from './form/CheckboxGroup.svelte';
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

  // Track "other" values
  let eventTypeOthers: Record<number, string> = { 0: '' };
  let participantMeasureOthers: Record<number, string> = { 0: '' };
  let policeMeasureOthers: Record<number, string> = { 0: '' };
  let notesOthers: Record<number, string> = { 0: '' };
  let submissionTypeOthers: Record<number, string> = { 0: '' };
  
  // Track online event state to conditionally show crowd size
  let isOnline = $state(false);
  
  // Track submission state
  let isSubmitting = $state(false);
  
  // Initialize with first submission type selected
  let selectedSubmissionTypes = $state<string[]>([]);
  
  $effect(() => {
    if (submissionTypes.length > 0 && selectedSubmissionTypes.length === 0) {
      const firstValidOption = submissionTypes.find(option => option.id !== 0);
      if (firstValidOption) {
        selectedSubmissionTypes = [firstValidOption.id.toString()];
      }
    }
  });

  // Get errors from form action
  const errors = $derived(form?.errors || {});
  const errorMessage = $derived(form?.message || '');
  const hasErrors = $derived(Object.keys(errors).length > 0 || errorMessage);
</script>

<div class="max-w-4xl mx-auto p-6">
  <h1 class="text-3xl font-bold mb-2">Protest Crowd Counts & Information</h1>
  <p class="text-gray-600 mb-8">Help us document protests accurately for the historical record.</p>

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
      return async ({ result, update }) => {
        isSubmitting = false;
        await update();
      };
    }}
    class="space-y-6"
  >
    <!-- Basic Information -->
    <BasicInfoSection {states} errors={errors} />

    <!-- Submission Type -->
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-2">
        Submission Type
      </label>
      <div class="space-y-2 max-h-60 overflow-y-auto border rounded p-2">
        {#each submissionTypes as option}
          {#if option.id !== 0}
            <label class="flex items-center">
              <input
                type="checkbox"
                name="submission_types"
                value={option.id}
                checked={selectedSubmissionTypes.includes(option.id.toString())}
                onchange={(e) => {
                  const target = e.target as HTMLInputElement;
                  if (target.checked) {
                    selectedSubmissionTypes = [...selectedSubmissionTypes, option.id.toString()];
                  } else {
                    selectedSubmissionTypes = selectedSubmissionTypes.filter(id => id !== option.id.toString());
                  }
                }}
                class="rounded border-gray-300 text-blue-600"
              />
              <span class="ml-2 text-sm">{option.name}</span>
            </label>
          {/if}
        {/each}
        <!-- Other option -->
        <label class="flex items-start">
          <input
            type="checkbox"
            name="submission_types"
            value="0"
            class="rounded border-gray-300 text-blue-600 mt-1"
          />
          <div class="ml-2 flex-1">
            <span class="text-sm">Other:</span>
            <input
              type="text"
              name="submission_types_other"
              bind:value={submissionTypeOthers[0]}
              class="mt-1 block w-full text-sm rounded-md border-gray-300"
              placeholder="Specify other submission type"
            />
          </div>
        </label>
      </div>
      <p class="mt-1 text-xs text-gray-500 italic">Check all that apply</p>
    </div>

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
        error={errors.count_method?.[0] || null}
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
      error={errors.sources?.[0] || null}
      supplementalInformation="We discourage you from sharing any personal information like your name or email address. Information entered here will be publicly available."
    />

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