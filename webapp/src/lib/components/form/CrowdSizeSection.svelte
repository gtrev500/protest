<script lang="ts">
  import NumberField from './NumberField.svelte';
</script>

<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
  <NumberField
    name="crowd_size_low"
    label="Lower End Estimate of Crowd Size"
  />

  <NumberField
    name="crowd_size_high"
    label="Higher End Estimate of Crowd Size"
  />
</div>