<script lang="ts">
  import ProtestForm from '$lib/components/ProtestForm.svelte';

  // Data injected by the server-side load() function
  export let data;

  const { states, eventTypes, participantTypes, participantMeasures, policeMeasures, notesOptions, submissionTypes } = data;
</script>

<svelte:head>
  <title>Submit a Protest | Protest Tracker</title>
</svelte:head>

<ProtestForm
  {states}
  {eventTypes}
  {participantTypes}
  {participantMeasures}
  {policeMeasures}
  {notesOptions}
  {submissionTypes}
/>