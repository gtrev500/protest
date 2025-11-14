<script lang="ts">
  /** Name attribute for the checkbox group (e.g., 'event_types') */
  export let checkboxName: string;
  /** Two-way bound text for the free-form 'other' value */
  export let otherText: string;
  /** Placeholder shown when the text input is displayed */
  export let placeholder: string = 'Specify other';
  /** Value submitted for the "other" checkbox. Defaults to '0' to match DB schema. */
  export let checkboxValue: string | number = '0';

  // Internal state of whether the checkbox is checked
  let checked = false;

  import { fade } from 'svelte/transition';

  // Reference to the input element to manipulate after it appears
  let inputEl: HTMLInputElement | null = null;

  // When the checkbox is checked, ensure the input is visible and focused
  $: if (checked && inputEl) {
    // Scroll into view within the scrolling container (nearest block)
    inputEl.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    // Give focus so the user can start typing immediately
    inputEl.focus();
  }
</script>

<label class="flex items-start">
  <input
    type="checkbox"
    name={checkboxName}
    value={checkboxValue}
    class="rounded border-gray-300 text-brand-600 mt-1"
    bind:checked
  />

  <div class="ml-2 flex-1">
    <span class="text-sm">Other:</span>
    {#if checked}
      <input
        type="text"
        bind:value={otherText}
        class="mt-1 block w-full text-sm rounded-md border-gray-300"
        {placeholder}
        bind:this={inputEl}
        transition:fade={{ duration: 150 }}
      />
    {/if}
  </div>
</label> 