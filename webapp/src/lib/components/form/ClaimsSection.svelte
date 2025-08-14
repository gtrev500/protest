<script lang="ts">
  import TextField from './TextField.svelte';
  import TextArea from './TextArea.svelte';
</script>

<TextField
  name="claims_summary"
  label="Claims Summary"
  placeholder="e.g., pro-democracy, against Trump, etc."
/>

<TextArea
  name="claims_verbatim"
  label="Claims Verbatim (signs and chants)"
/>