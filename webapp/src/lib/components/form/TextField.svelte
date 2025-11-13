<script lang="ts">
  interface Props {
    name: string;
    label: string;
    value?: string;
    error?: string | null;
    required?: boolean;
    placeholder?: string;
    type?: 'text' | 'email' | 'tel';
    class?: string;
    supplementalInformation?: string;
  }

  let {
    name,
    label,
    value = $bindable(),
    error = null,
    required = false,
    placeholder = '',
    type = 'text',
    class: className = '',
    supplementalInformation = ''
  }: Props = $props();
</script>

<div class={className}>
  <label for={name} class="block text-sm font-medium text-gray-700">
    {@html label} {required ? '*' : ''}
  </label>
  <input
    {type}
    id={name}
    {name}
    bind:value
    {required}
    {placeholder}
    class="mt-1 block w-full h-10 px-3 rounded-md border border-gray-400 focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
    class:border-red-400={error}
    class:focus:border-red-500={error}
    class:focus:ring-red-500={error}
  />
  {#if error}
    <p class="mt-1 text-sm text-red-600">{error}</p>
  {/if}
  {#if supplementalInformation}
    <p class="mt-1 text-sm text-gray-500">{@html supplementalInformation}</p>
  {/if}
</div>