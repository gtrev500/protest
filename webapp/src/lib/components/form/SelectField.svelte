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
    class="mt-1 block w-full h-10 px-3 rounded-md border border-gray-400 focus:border-brand-500 focus:ring-1 focus:ring-brand-500"
    class:border-danger-400={error}
    class:focus:border-danger-500={error}
    class:focus:ring-danger-500={error}
  >
    <option value="">{placeholder}</option>
    {#each options as option}
      <option value={option.value}>{option.label}</option>
    {/each}
  </select>
  {#if error}
    <p class="mt-1 text-sm text-danger-600">{error}</p>
  {/if}
</div>