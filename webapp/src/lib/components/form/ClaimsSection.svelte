<script lang="ts">
  import TextField from './TextField.svelte';
  import TextArea from './TextArea.svelte';

  interface Props {
    claimsSummary?: string;
    claimsVerbatim?: string;
  }

  let {
    claimsSummary = $bindable(''),
    claimsVerbatim = $bindable('')
  }: Props = $props();
</script>

<TextField
  name="claims_summary"
  label="Claims Summary"
  placeholder="e.g., pro-democracy, against Trump, etc."
  bind:value={claimsSummary}
/>

<TextArea
  name="claims_verbatim"
  label="Claims Verbatim (unique phrases from signs, chants, and banners)"
  bind:value={claimsVerbatim}
/>