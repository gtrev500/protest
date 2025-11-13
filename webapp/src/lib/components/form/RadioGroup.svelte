<script lang="ts">
  interface Props {
    name: string;
    label: string;
    value?: string;
    detailsValue?: string;
    error?: string | null;
    showDetails?: boolean;
    detailsPlaceholder?: string;
    class?: string;
  }

  let {
    name,
    label,
    value = $bindable('no'),
    detailsValue = $bindable(),
    error = null,
    showDetails = true,
    detailsPlaceholder = 'Details (optional)',
    class: className = ''
  }: Props = $props();
</script>

<div class={`space-y-2 ${className}`}>
  <label class="block text-sm font-medium text-gray-700 capitalize">
    {label}
  </label>
  <div class="flex items-center space-x-4">
    <label class="flex items-center">
      <input type="radio" {name} bind:group={value} value="yes" class="mr-1" />
      <span class="text-sm">Yes</span>
    </label>
    <label class="flex items-center">
      <input type="radio" {name} bind:group={value} value="no" class="mr-1" />
      <span class="text-sm">No</span>
    </label>
    {#if showDetails}
      <input
        type="text"
        name={`${name}_details`}
        bind:value={detailsValue}
        placeholder={detailsPlaceholder}
        class="flex-1 h-10 px-3 text-sm rounded-md border border-gray-400 focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
      />
    {/if}
  </div>
  {#if error}
    <p class="mt-1 text-sm text-red-600">{error}</p>
  {/if}
</div>