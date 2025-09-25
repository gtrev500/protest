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
  }: Props = $props();

  let otherChecked = $state(values.includes('0'));
</script>

<div class={className}>
  <label class="block text-sm font-medium text-gray-700 mb-2">
    {label}
  </label>
  <div class="space-y-2 max-h-60 overflow-y-auto border rounded p-2">
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
              class="mt-1 block w-full text-sm rounded-md border-gray-300"
              placeholder={otherPlaceholder}
            />
          {/if}
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