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
    {label} {required ? '*' : ''}
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
    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
    class:border-red-300={error}
  />
  {#if error}
    <p class="mt-1 text-sm text-red-600">{error}</p>
  {/if}
</div>