<script lang="ts">
  import DateField from './DateField.svelte';
  import TextField from './TextField.svelte';
  import { Combobox } from 'bits-ui';
  import type { State } from '$lib/types/database';

  interface Props {
    states: State[];
    errors: Record<string, string | string[] | null>;
    dateOfEvent?: string;
    locality?: string;
    stateCode?: string;
    title?: string;
    locationName?: string;
  }

  let {
    states,
    errors,
    dateOfEvent = $bindable(''),
    locality = $bindable(''),
    stateCode = $bindable(''),
    title = $bindable(''),
    locationName = $bindable('')
  }: Props = $props();

  let searchValue = $state('');

  // Filter states based on search input
  const filteredStates = $derived(
    searchValue === ''
      ? states
      : states.filter((state) =>
          state.name.toLowerCase().includes(searchValue.toLowerCase()) ||
          state.code.toLowerCase().includes(searchValue.toLowerCase())
        )
  );

  // Computed class for error states
  const inputClasses = $derived(
    `block w-full h-10 px-3 pr-10 rounded-md border focus:border-blue-500 focus:ring-1 focus:ring-blue-500 ${
      errors.state_code ? 'border-red-400 focus:border-red-500 focus:ring-red-500' : 'border-gray-400'
    }`
  );
</script>

<DateField
  name="date_of_event"
  label="Date of Event"
  required
  bind:value={dateOfEvent}
  error={errors.date_of_event as string | null}
/>

<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
  <TextField
    name="locality"
    label="City"
    required
    bind:value={locality}
    error={errors.locality as string | null}
  />

  <div>
    <label for="state_code" class="block text-sm font-medium text-gray-700">
      State/Territory <span class="text-red-500">*</span>
    </label>
    <Combobox.Root
      type="single"
      bind:value={stateCode}
      onOpenChange={(isOpen) => {
        if (!isOpen) searchValue = '';
      }}
    >
      <div class="relative mt-1">
        <Combobox.Input
          id="state_code"
          name="state_code"
          placeholder="Search states..."
          oninput={(e) => (searchValue = e.currentTarget.value)}
          required
          class={inputClasses}
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
    {#if errors.state_code}
      <p class="mt-1 text-sm text-red-600">{errors.state_code}</p>
    {/if}
  </div>
</div>


<TextField
  name="title"
  label="Title of Event"
  bind:value={title}
/>

<TextField
  name="location_name"
  label="Location Name or Address (specific place in city)"
  bind:value={locationName}
/>
