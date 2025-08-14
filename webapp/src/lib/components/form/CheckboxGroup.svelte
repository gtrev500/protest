<script lang="ts">
  import OtherInput from '../OtherInput.svelte';
  import { capitalize } from '$lib/utils/string';

  interface Option {
    id: number;
    name: string;
  }

  interface Props {
    name: string;
    label: string;
    options: Option[];
    values?: string[];
    otherValue?: string;
    showOther?: boolean;
    otherPlaceholder?: string;
    supplementalInformation?: string;
    autoCapitalize?: boolean;
    class?: string;
  }

  let {
    name,
    label,
    options,
    values = $bindable([]),
    otherValue = $bindable(''),
    showOther = false,
    otherPlaceholder = 'Specify other',
    supplementalInformation = '',
    autoCapitalize = true,
    class: className = ''
  }: Props = $props();
</script>

<div class={className}>
  <label class="block text-sm font-medium text-gray-700 mb-2">
    {label}
  </label>
  <div class="space-y-2 max-h-60 overflow-y-auto border rounded p-2">
    {#each options as option}
      {#if option.id !== 0}
        <label class="flex items-center">
          <input
            type="checkbox"
            {name}
            value={option.id}
            bind:group={values}
            class="rounded border-gray-300 text-blue-600"
          />
          <span class="ml-2 text-sm">{autoCapitalize ? capitalize(option.name) : option.name}</span>
        </label>
      {/if}
    {/each}
    {#if showOther}
      <OtherInput
        checkboxName={name}
        bind:otherText={otherValue}
        placeholder={otherPlaceholder}
      />
    {/if}
  </div>
  {#if supplementalInformation}
    <p class="mt-1 text-xs text-gray-500 italic">
      {supplementalInformation}
    </p>
  {/if}
</div>