<script lang="ts">
  import DateField from './DateField.svelte';
  import TextField from './TextField.svelte';
  import SelectField from './SelectField.svelte';
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

  const stateOptions = states.map(state => ({
    value: state.code,
    label: `${state.name} (${state.code})`
  }));
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

  <SelectField
    name="state_code"
    label="State/Territory"
    required
    options={stateOptions}
    placeholder="Select a state or territory"
    bind:value={stateCode}
    error={errors.state_code as string | null}
  />
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
