<script lang="ts">
  import CheckboxGroup from './CheckboxGroup.svelte';
  import type { NotesOption } from '$lib/types/database';

  interface Props {
    notesOptions: NotesOption[];
    notesOther?: string;
    selectedNotes?: string[];
  }

  let {
    notesOptions,
    notesOther = $bindable(''),
    selectedNotes = $bindable([])
  }: Props = $props();
</script>

<CheckboxGroup
  name="notes"
  label="Notes"
  options={notesOptions}
  showOther
  bind:otherValue={notesOther}
  bind:values={selectedNotes}
  otherPlaceholder="Specify other note"
/>
