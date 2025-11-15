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
    {label} {#if required}<span class="text-danger-500">*</span>{/if}
  </label>
  <textarea
    id={name}
    {name}
    bind:value
    {required}
    {placeholder}
    {rows}
    class="mt-1 block w-full px-3 py-2 rounded-md border border-gray-400 focus:border-brand-500 focus:ring-1 focus:ring-brand-500"
    class:border-danger-400={error}
    class:focus:border-danger-500={error}
    class:focus:ring-danger-500={error}
  ></textarea>
  {#if error}
    <p class="mt-1 text-sm text-danger-600">{error}</p>
  {/if}
  {#if supplementalInformation}
    <p class="mt-1 text-xs text-gray-500 italic">
      {supplementalInformation}
    </p>
  {/if}
</div>