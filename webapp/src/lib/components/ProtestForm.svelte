<!-- ProtestForm.svelte -->
<script lang="ts">
  import { createForm } from 'felte';
  import { validator } from '@felte/validator-zod';
  import { z } from 'zod';
  import { supabase } from '$lib/supabase';
  import { goto } from '$app/navigation';
  import type { State, EventType, ParticipantType, ParticipantMeasure, PoliceMeasure, NotesOption } from '$lib/types/database';

  // Fetch lookup data
  let states: State[] = [];
  let eventTypes: EventType[] = [];
  let participantTypes: ParticipantType[] = [];
  let participantMeasures: ParticipantMeasure[] = [];
  let policeMeasures: PoliceMeasure[] = [];
  let notesOptions: NotesOption[] = [];

  // Load option data on component mount
  async function loadLookupData() {
    try {
      const [statesRes, eventTypesRes, participantTypesRes, participantMeasuresRes, policeMeasuresRes, notesRes] = await Promise.all([
        supabase.from('states').select('*').order('name'),
        supabase.from('event_types').select('*').order('name'),
        supabase.from('participant_types').select('*').order('name'),
        supabase.from('participant_measures').select('*').order('name'),
        supabase.from('police_measures').select('*').order('name'),
        supabase.from('notes_options').select('*').order('name')
      ]);

      // Log any errors
      if (statesRes.error) console.error('Error loading states:', statesRes.error);
      if (eventTypesRes.error) console.error('Error loading event types:', eventTypesRes.error);
      if (participantTypesRes.error) console.error('Error loading participant types:', participantTypesRes.error);
      if (participantMeasuresRes.error) console.error('Error loading participant measures:', participantMeasuresRes.error);
      if (policeMeasuresRes.error) console.error('Error loading police measures:', policeMeasuresRes.error);
      if (notesRes.error) console.error('Error loading notes options:', notesRes.error);

      states = statesRes.data || [];
      eventTypes = eventTypesRes.data || [];
      participantTypes = participantTypesRes.data || [];
      participantMeasures = participantMeasuresRes.data || [];
      policeMeasures = policeMeasuresRes.data || [];
      notesOptions = notesRes.data || [];
    } catch (error) {
      console.error('Error in loadLookupData:', error);
    }
  }

  // Load data on component mount
  loadLookupData();

  // Form schema
  const schema = z.object({
    date_of_event: z.string().min(1, 'Date is required'),
    locality: z.string().min(1, 'City is required'),
    state_code: z.string().min(1, 'State is required'),
    location_name: z.string().optional(),
    title: z.string().min(1, 'Event title is required'),
    organization_name: z.string().optional(),
    notable_participants: z.string().optional(),
    targets: z.string().optional(),
    claims_summary: z.string().optional(),
    claims_verbatim: z.string().optional(),
    macroevent: z.string().optional(),
    is_online: z.boolean(),
    crowd_size_low: z.string().optional(),
    crowd_size_high: z.string().optional(),
    sources: z.string().optional()
  });

  // Track "other" values
  let eventTypeOthers = {};
  let participantMeasureOthers = {};
  let policeMeasureOthers = {};
  let notesOthers = {};

  // Debug: Log when form is being created
  console.log('Creating Felte form...');
  
  // Form handling
  const { form, errors, isSubmitting } = createForm({
    initialValues: {
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
    //extend: validator({ schema }), // Temporarily disable validation
    onSubmit: async (values) => {
      console.log('Form submitted with values:', values);
      try {
        // Prepare data for submission
        const protestData = {
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
          crowd_size_low: values.crowd_size_low ? parseInt(values.crowd_size_low) : null,
          crowd_size_high: values.crowd_size_high ? parseInt(values.crowd_size_high) : null,
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

        // Prepare junction table data
        const eventTypesData = values.event_types.map(id => ({
          id: id === 'other' ? null : id,
          other: id === 'other' ? eventTypeOthers[id] : null
        }));

        const participantTypesData = values.participant_types.map(id => ({ id }));

        const participantMeasuresData = values.participant_measures.map(id => ({
          id: id === 'other' ? null : id,
          other: id === 'other' ? participantMeasureOthers[id] : null
        }));

        const policeMeasuresData = values.police_measures.map(id => ({
          id: id === 'other' ? null : id,
          other: id === 'other' ? policeMeasureOthers[id] : null
        }));

        const notesData = values.notes.map(id => ({
          id: id === 'other' ? null : id,
          other: id === 'other' ? notesOthers[id] : null
        }));

        // Debug: Log the data being submitted
        console.log('Submitting protest data:', {
          protest_data: protestData,
          event_types_data: eventTypesData,
          participant_types_data: participantTypesData,
          participant_measures_data: participantMeasuresData,
          police_measures_data: policeMeasuresData,
          notes_data: notesData
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
        alert(`Error submitting form: ${error.message || 'Unknown error'}. Please check the console for details.`);
      }
    }
  });


  
</script>

<div class="max-w-4xl mx-auto p-6">
  <h1 class="text-3xl font-bold mb-2">Protest Crowd Counts & Information</h1>
  <p class="text-gray-600 mb-8">Help us document protests accurately for the historical record.</p>

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
          <label class="flex items-center">
            <input
              type="checkbox"
              name="event_types"
              value={eventType.id}
              class="rounded border-gray-300 text-blue-600"
            />
            <span class="ml-2 text-sm">{eventType.name}</span>
          </label>
        {/each}
        <label class="flex items-start">
          <input
            type="checkbox"
            name="event_types"
            value="other"
            class="rounded border-gray-300 text-blue-600 mt-1"
          />
          <div class="ml-2 flex-1">
            <span class="text-sm">Other:</span>
            <input
              type="text"
              bind:value={eventTypeOthers['other']}
              class="mt-1 block w-full text-sm rounded-md border-gray-300"
              placeholder="Specify other event type"
            />
          </div>
        </label>
      </div>
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
            <span class="ml-2 text-sm">{pType.name}</span>
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
          class="rounded border-gray-300 text-blue-600"
        />
        <span class="ml-2 text-sm font-medium">This was an online event</span>
      </label>
    </div>

    <!-- Crowd Size -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div>
        <label for="crowd_size_low" class="block text-sm font-medium text-gray-700">
          Lower End Estimate of Crowd Size
        </label>
        <input
          type="number"
          id="crowd_size_low"
          name="crowd_size_low"
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
          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
        />
      </div>
    </div>

    <!-- Participant Measures -->
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-2">
        Participant Measures
      </label>
      <div class="space-y-2 max-h-60 overflow-y-auto border rounded p-2">
        {#each participantMeasures as measure}
          <label class="flex items-center">
            <input
              type="checkbox"
              name="participant_measures"
              value={measure.id}
              class="rounded border-gray-300 text-blue-600"
            />
            <span class="ml-2 text-sm">{measure.name}</span>
          </label>
        {/each}
        <label class="flex items-start">
          <input
            type="checkbox"
            name="participant_measures"
            value="other"
            class="rounded border-gray-300 text-blue-600 mt-1"
          />
          <div class="ml-2 flex-1">
            <span class="text-sm">Other:</span>
            <input
              type="text"
              bind:value={participantMeasureOthers['other']}
              class="mt-1 block w-full text-sm rounded-md border-gray-300"
              placeholder="Specify other measure"
            />
          </div>
        </label>
      </div>
    </div>

    <!-- Police Measures -->
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-2">
        Police Measures
      </label>
      <div class="space-y-2 max-h-60 overflow-y-auto border rounded p-2">
        {#each policeMeasures as measure}
          <label class="flex items-center">
            <input
              type="checkbox"
              name="police_measures"
              value={measure.id}
              class="rounded border-gray-300 text-blue-600"
            />
            <span class="ml-2 text-sm">{measure.name}</span>
          </label>
        {/each}
        <label class="flex items-start">
          <input
            type="checkbox"
            name="police_measures"
            value="other"
            class="rounded border-gray-300 text-blue-600 mt-1"
          />
          <div class="ml-2 flex-1">
            <span class="text-sm">Other:</span>
            <input
              type="text"
              bind:value={policeMeasureOthers['other']}
              class="mt-1 block w-full text-sm rounded-md border-gray-300"
              placeholder="Specify other measure"
            />
          </div>
        </label>
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
          <label class="flex items-center">
            <input
              type="checkbox"
              name="notes"
              value={note.id}
              class="rounded border-gray-300 text-blue-600"
            />
            <span class="ml-2 text-sm">{note.name}</span>
          </label>
        {/each}
        <label class="flex items-start">
          <input
            type="checkbox"
            name="notes"
            value="other"
            class="rounded border-gray-300 text-blue-600 mt-1"
          />
          <div class="ml-2 flex-1">
            <span class="text-sm">Other:</span>
            <input
              type="text"
              bind:value={notesOthers['other']}
              class="mt-1 block w-full text-sm rounded-md border-gray-300"
              placeholder="Specify other note"
            />
          </div>
        </label>
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
        on:click={() => console.log('Submit button clicked!')}
        class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:bg-gray-400"
      >
        {$isSubmitting ? 'Submitting...' : 'Submit Protest Information'}
      </button>
    </div>
  </form>
  
</div>
