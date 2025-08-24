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
    otherValue = $bindable(''),
    showOther = false,
    otherPlaceholder = 'Specify other',
    supplementalInformation = '',
    autoCapitalize = true,
    class: className = '',
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
            name={name}
            value={option.id}
            class="rounded border-gray-300 text-blue-600"
          />
          <span class="ml-2 text-sm">{autoCapitalize ? capitalize(option.name) : option.name}</span>
        </label>
      {/if}
    {/each}
    {#if showOther}
      <label class="flex items-start">
        <input
          type="checkbox"
          name={name}
          value="0"
          class="rounded border-gray-300 text-blue-600 mt-1"
        />
        <div class="ml-2 flex-1">
          <span class="text-sm">Other:</span>
          <input
            type="text"
            name={`${name}_other`}
            bind:value={otherValue}
            class="mt-1 block w-full text-sm rounded-md border-gray-300"
            placeholder={otherPlaceholder}
          />
        </div>
      </label>
    {/if}
  </div>
  {#if supplementalInformation}
    <p class="mt-1 text-xs text-gray-500 italic">
      {supplementalInformation}
    </p>
  {/if}
</div>