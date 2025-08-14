<script lang="ts">
  interface Option {
    value: string | number;
    label: string;
  }

  interface Props {
    name: string;
    label: string;
    value?: string | number;
    error?: string | null;
    required?: boolean;
    options: Option[];
    placeholder?: string;
    class?: string;
  }

  let {
    name,
    label,
    value = $bindable(),
    error = null,
    required = false,
    options,
    placeholder = 'Select an option',
    class: className = ''
  }: Props = $props();
</script>

<div class={className}>
  <label for={name} class="block text-sm font-medium text-gray-700">
    {label} {required ? '*' : ''}
  </label>
  <select
    id={name}
    {name}
    bind:value
    {required}
    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
    class:border-red-300={error}
  >
    <option value="">{placeholder}</option>
    {#each options as option}
      <option value={option.value}>{option.label}</option>
    {/each}
  </select>
  {#if error}
    <p class="mt-1 text-sm text-red-600">{error}</p>
  {/if}
</div>