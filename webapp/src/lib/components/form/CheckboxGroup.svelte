<script lang="ts">
  import OtherInput from '$lib/components/OtherInput.svelte';
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
    firstOptionIsChecked?: boolean;
    values?: string[];
    class?: string;
    required?: boolean;
    error?: string | null;
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
    firstOptionIsChecked = false,
    values = $bindable([]),
    class: className = '',
    required = false,
    error = null,
  }: Props = $props();

  let otherChecked = $state(values.includes('0'));
  let containerElement: HTMLDivElement;
  let otherInputElement = $state<HTMLInputElement>();

  // Scroll to this field when there's an error
  $effect(() => {
    if (error && containerElement) {
      containerElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  });

  // Focus and scroll to the Other text input when it becomes visible
  $effect(() => {
    if (otherChecked && otherInputElement) {
      // Use 'nearest' to only scroll within the container, not the entire page
      otherInputElement.scrollIntoView({
        behavior: 'smooth',
        block: 'nearest',
        inline: 'nearest'
      });
      otherInputElement.focus();
    }
  });
</script>

<div class={className} bind:this={containerElement}>
  <fieldset>
    <legend class="block text-sm font-medium text-gray-700 mb-2">
      {label}
      {#if required}
        <span class="">*</span>
      {/if}
    </legend>
    <div class="space-y-2 max-h-60 overflow-y-auto border rounded p-2 {error ? 'border-black' : 'border-gray-300'}">
    {#each options as option, index}
      {#if option.id !== 0}
        <label class="flex items-center">
          <input
            type="checkbox"
            name={name}
            value={option.id}
            checked={values.includes(option.id.toString()) || (firstOptionIsChecked && index === 1)}
            onchange={(e) => {
              const target = e.target as HTMLInputElement;
              const value = target.value;
              if (target.checked) {
                if (!values.includes(value)) {
                  values = [...values, value];
                }
              } else {
                values = values.filter(v => v !== value);
              }
            }}
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
          checked={otherChecked || values.includes('0')}
          onchange={(e) => {
            const target = e.target as HTMLInputElement;
            otherChecked = target.checked;
            if (target.checked) {
              if (!values.includes('0')) {
                values = [...values, '0'];
              }
            } else {
              values = values.filter(v => v !== '0');
              otherValue = '';
            }
          }}
          class="rounded border-gray-300 text-blue-600 mt-1"
        />
        <div class="ml-2 flex-1">
          <span class="text-sm">Other:</span>
          {#if otherChecked || values.includes('0')}
            <input
              type="text"
              name={`${name}_other`}
              bind:value={otherValue}
              bind:this={otherInputElement}
              class="mt-1 block w-full h-10 px-3 text-sm rounded-md border border-gray-400 focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
              placeholder={otherPlaceholder}
            />
          {/if}
        </div>
      </label>
    {/if}
    </div>
  </fieldset>
  {#if supplementalInformation}
    <p class="mt-1 text-xs text-gray-500 italic">
      {supplementalInformation}
    </p>
  {/if}
  {#if error}
    <p class="mt-1 text-sm text-red-600">
      {error}
    </p>
  {/if}
</div>