<script lang="ts">
  import DateField from './DateField.svelte';
  import TextField from './TextField.svelte';
  import SelectField from './SelectField.svelte';
  import type { State } from '$lib/types/database';

  interface Props {
    states: State[];
    errors: Record<string, string | string[] | null>;
  }

  let { states, errors }: Props = $props();

  const stateOptions = states.map(state => ({
    value: state.code,
    label: `${state.name} (${state.code})`
  }));
</script>

<DateField
  name="date_of_event"
  label="Date of Event"
  required
  error={errors.date_of_event as string | null}
/>

<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
  <TextField
    name="locality"
    label="City"
    required
    error={errors.locality as string | null}
  />

  <SelectField
    name="state_code"
    label="State/Territory"
    required
    options={stateOptions}
    placeholder="Select a state or territory"
    error={errors.state_code as string | null}
  />
</div>


<TextField
  name="title"
  label="Title of Event"
/>

<TextField
  name="location_name"
  label="Location Name (specific place in city)"
/>
