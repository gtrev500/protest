<script lang="ts">
  interface Props {
    name: string;
    label: string;
    value?: string;
    error?: string | null;
    required?: boolean;
    placeholder?: string;
    rows?: number;
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
    rows = 4,
    class: className = '',
    supplementalInformation = ''
  }: Props = $props();
</script>

<div class={className}>
  <label for={name} class="block text-sm font-medium text-gray-700">
    {label} {required ? '*' : ''}
  </label>
  <textarea
    id={name}
    {name}
    bind:value
    {required}
    {placeholder}
    {rows}
    class="mt-1 block w-full px-3 py-2 rounded-md border border-gray-400 focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
    class:border-red-400={error}
    class:focus:border-red-500={error}
    class:focus:ring-red-500={error}
  ></textarea>
  {#if error}
    <p class="mt-1 text-sm text-red-600">{error}</p>
  {/if}
  {#if supplementalInformation}
    <p class="mt-1 text-xs text-gray-500 italic">
      {supplementalInformation}
    </p>
  {/if}
</div>