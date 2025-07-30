<!-- ProtestForm.svelte -->
<script lang="ts">
  import { createForm } from 'felte';
  import { validator } from '@felte/validator-zod';
  import { supabase } from '$lib/supabase';
  import { goto } from '$app/navigation';
  import type { State, EventType, ParticipantType, ParticipantMeasure, PoliceMeasure, NotesOption, ProtestData, JunctionOption } from '$lib/types/database';
  import { protestFormSchema, type ProtestFormSchema } from '$lib/types/schemas';
  import OtherInput from '$lib/components/OtherInput.svelte';

  // Utility function to capitalize first letter
  function capitalize(str: string): string {
    return str.charAt(0).toUpperCase() + str.slice(1);
  }

  // Lookup data is provided via props from the page's load() function (SSR)
  export let states: State[] = [];
  export let eventTypes: EventType[] = [];
  export let participantTypes: ParticipantType[] = [];
  export let participantMeasures: ParticipantMeasure[] = [];
  export let policeMeasures: PoliceMeasure[] = [];
  export let notesOptions: NotesOption[] = [];

  // (client-side lookup fetching removed – now handled in +page.server.ts)

  // Track "other" values (use numeric key 0 instead of string "other")
  let eventTypeOthers: Record<number, string> = {};
  let participantMeasureOthers: Record<number, string> = {};
  let policeMeasureOthers: Record<number, string> = {};
  let notesOthers: Record<number, string> = {};

  // Track whether to show validation errors
  let showValidationErrors = false;
  
  // Track online event state to conditionally show crowd size
  let isOnline = false;
  
  // Form handling
  const { form, errors, isSubmitting } = createForm<ProtestFormSchema>({
    initialValues: {
      // Required fields
      date_of_event: '',
      locality: '',
      state_code: '',
      title: '',
      
      // Optional fields with defaults
      event_types: [],
      participant_types: [],
      participant_measures: [],
      police_measures: [],
      notes: [],
      is_online: false,
      participant_injury: 'no',
      police_injury: 'no',
      arrests: 'no',
      property_damage: 'no',
      participant_casualties: 'no',
      police_casualties: 'no'
    },
    extend: validator({ schema: protestFormSchema }),
    onSubmit: async (values) => {
      try {
        // Prepare data for submission
        const protestData: ProtestData = {
          date_of_event: values.date_of_event,
          locality: values.locality,
          state_code: values.state_code,
          location_name: values.location_name,
          title: values.title,
          organization_name: values.organization_name,
          notable_participants: values.notable_participants,
          targets: values.targets,
          claims_summary: values.claims_summary,
          claims_verbatim: values.claims_verbatim,
          macroevent: values.macroevent,
          is_online: values.is_online,
          crowd_size_low: values.crowd_size_low || null,
          crowd_size_high: values.crowd_size_high || null,
          participant_injury: values.participant_injury,
          participant_injury_details: values.participant_injury_details,
          police_injury: values.police_injury,
          police_injury_details: values.police_injury_details,
          arrests: values.arrests,
          arrests_details: values.arrests_details,
          property_damage: values.property_damage,
          property_damage_details: values.property_damage_details,
          participant_casualties: values.participant_casualties,
          participant_casualties_details: values.participant_casualties_details,
          police_casualties: values.police_casualties,
          police_casualties_details: values.police_casualties_details,
          sources: values.sources
        };

        // Prepare junction table data - convert string IDs to numbers
        const eventTypesData: JunctionOption[] = values.event_types.map((id) => {
          const numId = parseInt(id);
          return {
            id: numId,
            other: numId === 0 ? eventTypeOthers[0] : null
          };
        });

        const participantTypesData: { id: number }[] = values.participant_types.map(id => ({ 
          id: parseInt(id) 
        }));

        const participantMeasuresData: JunctionOption[] = values.participant_measures.map((id) => {
          const numId = parseInt(id);
          return {
            id: numId,
            other: numId === 0 ? participantMeasureOthers[0] : null
          };
        });

        const policeMeasuresData: JunctionOption[] = values.police_measures.map((id) => {
          const numId = parseInt(id);
          return {
            id: numId,
            other: numId === 0 ? policeMeasureOthers[0] : null
          };
        });

        const notesData: JunctionOption[] = values.notes.map((id) => {
          const numId = parseInt(id);
          return {
            id: numId,
            other: numId === 0 ? notesOthers[0] : null
          };
        });

        // Submit using the database function
        const { data, error } = await supabase.rpc('submit_protest', {
          protest_data: protestData,
          event_types_data: eventTypesData,
          participant_types_data: participantTypesData,
          participant_measures_data: participantMeasuresData,
          police_measures_data: policeMeasuresData,
          notes_data: notesData
        });

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
        //const message = error instanceof Error ? error.message : 'Unknown error';
        //alert(`Error submitting form: ${message}. Please check the console for details.`);
      }
    }
  });


  
</script>

<div class="max-w-4xl mx-auto p-6">
  <h1 class="text-3xl font-bold mb-2">Protest Crowd Counts & Information</h1>
  <p class="text-gray-600 mb-8">Help us document protests accurately for the historical record.</p>

  <!-- Show validation errors only after submit attempt -->
  {#if showValidationErrors && $errors && Object.keys($errors).length > 0}
    <div class="mb-4 p-4 bg-red-50 border border-red-200 rounded">
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
    <!-- Date of Event -->
    <div>
      <label for="date_of_event" class="block text-sm font-medium text-gray-700">
        Date of Event *
      </label>
      <input
        type="date"
        id="date_of_event"
        name="date_of_event"
        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
        required
      />
      {#if $errors.date_of_event}
        <p class="mt-1 text-sm text-red-600">{$errors.date_of_event}</p>
      {/if}
    </div>

    <!-- Location Fields -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div>
        <label for="locality" class="block text-sm font-medium text-gray-700">
          City *
        </label>
        <input
          type="text"
          id="locality"
          name="locality"
          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
          required
        />
        {#if $errors.locality}
          <p class="mt-1 text-sm text-red-600">{$errors.locality}</p>
        {/if}
      </div>

      <div>
        <label for="state_code" class="block text-sm font-medium text-gray-700">
          State/Territory *
        </label>
        <select
          id="state_code"
          name="state_code"
          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
          required
        >
          <option value="">Select a state</option>
          {#each states as state}
            <option value={state.code}>{state.name} ({state.code})</option>
          {/each}
        </select>
        {#if $errors.state_code}
          <p class="mt-1 text-sm text-red-600">{$errors.state_code}</p>
        {/if}
      </div>
    </div>

    <!-- Location Name -->
    <div>
      <label for="location_name" class="block text-sm font-medium text-gray-700">
        Location Name (specific place in city)
      </label>
      <input
        type="text"
        id="location_name"
        name="location_name"
        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
      />
    </div>

    <!-- Title -->
    <div>
      <label for="title" class="block text-sm font-medium text-gray-700">
        Title of Event *
      </label>
      <input
        type="text"
        id="title"
        name="title"
        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
        required
      />
      {#if $errors.title}
        <p class="mt-1 text-sm text-red-600">{$errors.title}</p>
      {/if}
    </div>

    <!-- Event Types -->
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-2">
        Event Type(s)
      </label>
      <div class="space-y-2 max-h-60 overflow-y-auto border rounded p-2">
        {#each eventTypes as eventType}
          {#if eventType.id !== 0}
          <label class="flex items-center">
            <input
              type="checkbox"
              name="event_types"
              value={eventType.id}
              class="rounded border-gray-300 text-blue-600"
            />
            <span class="ml-2 text-sm">{capitalize(eventType.name)}</span>
          </label>
          {/if}
        {/each}
        <OtherInput
          checkboxName="event_types"
          bind:otherText={eventTypeOthers[0]}
          placeholder="Specify other event type"
        />
      </div>
      <p class="mt-1 text-xs text-gray-500 italic">
        *These actions may qualify as long as participants articulate grievances around broader political issues.
      </p>
    </div>

    <!-- Organization Name -->
    <div>
      <label for="organization_name" class="block text-sm font-medium text-gray-700">
        Organization Name
      </label>
      <input
        type="text"
        id="organization_name"
        name="organization_name"
        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
      />
    </div>

    <!-- Participant Types -->
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-2">
        Participant Types
      </label>
      <div class="space-y-2 max-h-60 overflow-y-auto border rounded p-2">
        {#each participantTypes as pType}
          <label class="flex items-center">
            <input
              type="checkbox"
              name="participant_types"
              value={pType.id}
              class="rounded border-gray-300 text-blue-600"
            />
            <span class="ml-2 text-sm">{capitalize(pType.name)}</span>
          </label>
        {/each}
      </div>
    </div>

    <!-- Notable Participants -->
    <div>
      <label for="notable_participants" class="block text-sm font-medium text-gray-700">
        Notable Participants (public figures)
      </label>
      <input
        type="text"
        id="notable_participants"
        name="notable_participants"
        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
      />
    </div>

    <!-- Targets -->
    <div>
      <label for="targets" class="block text-sm font-medium text-gray-700">
        Targets (e.g., Trump, Musk, ICE, etc)
      </label>
      <input
        type="text"
        id="targets"
        name="targets"
        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
      />
    </div>

    <!-- Claims -->
    <div>
      <label for="claims_summary" class="block text-sm font-medium text-gray-700">
        Claims Summary
      </label>
      <input
        type="text"
        id="claims_summary"
        name="claims_summary"
        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
        placeholder="e.g., pro-democracy, against Trump, etc."
      />
    </div>

    <div>
      <label for="claims_verbatim" class="block text-sm font-medium text-gray-700">
        Claims Verbatim (signs and chants)
      </label>
      <textarea
        id="claims_verbatim"
        name="claims_verbatim"
        rows="4"
        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
      ></textarea>
    </div>

    <!-- Macroevent -->
    <div>
      <label for="macroevent" class="block text-sm font-medium text-gray-700">
        Macroevent (if part of a larger event)
      </label>
      <input
        type="text"
        id="macroevent"
        name="macroevent"
        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
        placeholder="e.g., Women's March, Trump Inauguration protests, etc."
      />
    </div>

    <!-- Online Event -->
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

    <!-- Crowd Size --> 
    {#if !isOnline}
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div>
        <label for="crowd_size_low" class="block text-sm font-medium text-gray-700">
          Lower End Estimate of Crowd Size
        </label>
        <input
          type="number"
          id="crowd_size_low"
          name="crowd_size_low"
          min="0"
          step="1"
          pattern="[0-9]*"
          on:keypress={(e) => {
            // Only allow digits
            if (!/[0-9]/.test(e.key) && e.key !== 'Backspace' && e.key !== 'Delete' && e.key !== 'Tab') {
              e.preventDefault();
            }
          }}
          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
        />
      </div>

      <div>
        <label for="crowd_size_high" class="block text-sm font-medium text-gray-700">
          Higher End Estimate of Crowd Size
        </label>
        <input
          type="number"
          id="crowd_size_high"
          name="crowd_size_high"
          min="0"
          step="1"
          pattern="[0-9]*"
          on:keypress={(e) => {
            // Only allow digits
            if (!/[0-9]/.test(e.key) && e.key !== 'Backspace' && e.key !== 'Delete' && e.key !== 'Tab') {
              e.preventDefault();
            }
          }}
          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
        />
      </div>
    </div>
    {/if}

    <!-- Participant Measures -->
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-2">
        Participant Measures
      </label>
      <div class="space-y-2 max-h-60 overflow-y-auto border rounded p-2">
        {#each participantMeasures as measure}
          {#if measure.id !== 0}
          <label class="flex items-center">
            <input
              type="checkbox"
              name="participant_measures"
              value={measure.id}
              class="rounded border-gray-300 text-blue-600"
            />
            <span class="ml-2 text-sm">{capitalize(measure.name)}</span>
          </label>
          {/if}
        {/each}
        <OtherInput
          checkboxName="participant_measures"
          bind:otherText={participantMeasureOthers[0]}
          placeholder="Specify other measure"
        />
      </div>
    </div>

    <!-- Police Measures -->
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-2">
        Police Measures
      </label>
      <div class="space-y-2 max-h-60 overflow-y-auto border rounded p-2">
        {#each policeMeasures as measure}
          {#if measure.id !== 0}
          <label class="flex items-center">
            <input
              type="checkbox"
              name="police_measures"
              value={measure.id}
              class="rounded border-gray-300 text-blue-600"
            />
            <span class="ml-2 text-sm">{capitalize(measure.name)}</span>
          </label>
          {/if}
        {/each}
        <OtherInput
          checkboxName="police_measures"
          bind:otherText={policeMeasureOthers[0]}
          placeholder="Specify other measure"
        />
      </div>
    </div>

    <!-- Incident Questions -->
    {#each ['participant_injury', 'police_injury', 'arrests', 'property_damage', 'participant_casualties', 'police_casualties'] as field}
      <div class="space-y-2">
        <label class="block text-sm font-medium text-gray-700 capitalize">
          {field.replace(/_/g, ' ')}
        </label>
        <div class="flex items-center space-x-4">
          <label class="flex items-center">
            <input type="radio" name={field} value="yes" class="mr-1" />
            <span class="text-sm">Yes</span>
          </label>
          <label class="flex items-center">
            <input type="radio" name={field} value="no" class="mr-1" checked />
            <span class="text-sm">No</span>
          </label>
          <input
            type="text"
            name={`${field}_details`}
            placeholder="Details (optional)"
            class="flex-1 text-sm rounded-md border-gray-300"
          />
        </div>
      </div>
    {/each}

    <!-- Notes -->
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-2">
        Notes
      </label>
      <div class="space-y-2 max-h-60 overflow-y-auto border rounded p-2">
        {#each notesOptions as note}
          {#if note.id !== 0}
          <label class="flex items-center">
            <input
              type="checkbox"
              name="notes"
              value={note.id}
              class="rounded border-gray-300 text-blue-600"
            />
            <span class="ml-2 text-sm">{capitalize(note.name)}</span>
          </label>
          {/if}
        {/each}
        <OtherInput
          checkboxName="notes"
          bind:otherText={notesOthers[0]}
          placeholder="Specify other note"
        />
      </div>
    </div>

    <!-- Sources -->
    <div>
      <label for="sources" class="block text-sm font-medium text-gray-700">
        Sources
      </label>
      <textarea
        id="sources"
        name="sources"
        rows="4"
        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
        placeholder="Include links to news articles, social media posts, etc."
      ></textarea>
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
