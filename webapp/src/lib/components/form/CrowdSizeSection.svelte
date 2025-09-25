<script lang="ts">
  import NumberField from './NumberField.svelte';

  interface Props {
    required: boolean;
    crowdSizeLow?: string;
    crowdSizeHigh?: string;
  }

  let {
    required,
    crowdSizeLow = $bindable(''),
    crowdSizeHigh = $bindable('')
  }: Props = $props();

  // Convert string to number for NumberField and vice versa
  let lowNum = $state(crowdSizeLow ? parseInt(crowdSizeLow) : null);
  let highNum = $state(crowdSizeHigh ? parseInt(crowdSizeHigh) : null);

  // Sync string values with numbers
  $effect(() => {
    lowNum = crowdSizeLow ? parseInt(crowdSizeLow) : null;
  });

  $effect(() => {
    highNum = crowdSizeHigh ? parseInt(crowdSizeHigh) : null;
  });

  $effect(() => {
    crowdSizeLow = lowNum?.toString() || '';
  });

  $effect(() => {
    crowdSizeHigh = highNum?.toString() || '';
  });
</script>

<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
  <NumberField
    name="crowd_size_low"
    label="Lower End Estimate of Crowd Size"
    required={required}
    bind:value={lowNum}
  />

  <NumberField
    name="crowd_size_high"
    label="Higher End Estimate of Crowd Size"
    required={required}
    bind:value={highNum}
  />
</div>