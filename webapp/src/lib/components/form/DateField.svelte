<script lang="ts">
  interface Props {
    name: string;
    label: string;
    value?: string;
    error?: string | null;
    required?: boolean;
    class?: string;
  }

  let {
    name,
    label,
    value = $bindable(),
    error = null,
    required = false,
    class: className = ''
  }: Props = $props();
</script>

<div class={className}>
  <label for={name} class="block text-sm font-medium text-gray-700">
    {label} {required ? '*' : ''}
  </label>
  <input
    type="date"
    id={name}
    {name}
    bind:value
    {required}
    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
    class:border-red-300={error}
  />
  {#if error}
    <p class="mt-1 text-sm text-red-600">{error}</p>
  {/if}
</div>