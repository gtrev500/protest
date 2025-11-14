<script lang="ts">
  import DateField from './DateField.svelte';
  import TextField from './TextField.svelte';
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
      State/Territory <span class="text-danger-500">*</span>
    </label>
    <select
      id="state_code"
      name="state_code"
      bind:value={stateCode}
      required
      class="mt-1 block w-full h-10 px-3 rounded-md border border-gray-400 focus:border-brand-500 focus:ring-1 focus:ring-brand-500"
      class:border-danger-400={errors.state_code}
      class:focus:border-danger-500={errors.state_code}
      class:focus:ring-danger-500={errors.state_code}
    >
      <option value="">Select a state...</option>
      {#each states as state}
        <option value={state.code}>{state.name}</option>
      {/each}
    </select>
    {#if errors.state_code}
      <p class="mt-1 text-sm text-danger-600">{errors.state_code}</p>
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
