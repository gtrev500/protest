<script lang="ts">
  import CheckboxGroup from './CheckboxGroup.svelte';
  import TextArea from './TextArea.svelte';
  import type { NotesOption } from '$lib/types/database';

  interface Props {
    notesOptions: NotesOption[];
    notesOther?: string;
  }

  let { notesOptions, notesOther = $bindable('') }: Props = $props();
</script>

<CheckboxGroup
  name="notes"
  label="Notes"
  options={notesOptions}
  showOther
  bind:otherValue={notesOther}
  otherPlaceholder="Specify other note"
/>

<TextArea
  name="sources"
  label="Sources"
  placeholder="Include links to news articles, social media posts, etc."
/>