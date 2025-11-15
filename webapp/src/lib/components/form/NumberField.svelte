<script lang="ts">
  interface Props {
    name: string;
    label: string;
    value?: number | null;
    error?: string | null;
    required?: boolean;
    min?: number;
    max?: number;
    placeholder?: string;
    class?: string;
  }

  let {
    name,
    label,
    value = $bindable(),
    error = null,
    required = false,
    min = 0,
    max,
    placeholder = '',
    class: className = ''
  }: Props = $props();

  function handleKeypress(e: KeyboardEvent) {
    if (!/[0-9]/.test(e.key) && !['Backspace', 'Delete', 'Tab', 'ArrowLeft', 'ArrowRight'].includes(e.key)) {
      e.preventDefault();
    }
  }
</script>

<div class={className}>
  <label for={name} class="block text-sm font-medium text-gray-700">
    {label} {#if required}<span class="text-danger-500">*</span>{/if}
  </label>
  <input
    type="number"
    id={name}
    {name}
    bind:value
    {required}
    {min}
    {max}
    {placeholder}
    step="1"
    pattern="[0-9]*"
    onkeypress={handleKeypress}
    class="mt-1 block w-full h-10 px-3 rounded-md border border-gray-400 focus:border-brand-500 focus:ring-1 focus:ring-brand-500"
    class:border-danger-400={error}
    class:focus:border-danger-500={error}
    class:focus:ring-danger-500={error}
  />
  {#if error}
    <p class="mt-1 text-sm text-danger-600">{error}</p>
  {/if}
</div>