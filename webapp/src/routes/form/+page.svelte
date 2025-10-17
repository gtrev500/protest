<script lang="ts">
  import ProtestForm from '$lib/components/ProtestForm.svelte';
  import { enhance } from '$app/forms';
  import type { FormActionResult } from './+page.server';

  // Data injected by the server-side load() function
  export let data;
  export let form: FormActionResult | null;

  const { states, eventTypes, participantTypes, participantMeasures, policeMeasures, notesOptions, submissionTypes, countMethods } = data;
</script>

<svelte:head>
  <title>Submit a Protest | Protest Sourcebook</title>
</svelte:head>

<ProtestForm
  {states}
  {eventTypes}
  {participantTypes}
  {participantMeasures}
  {policeMeasures}
  {notesOptions}
  {submissionTypes}
  {countMethods}
  {form}
  {enhance}
/>