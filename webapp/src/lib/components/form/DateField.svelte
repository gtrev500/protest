<script lang="ts">
  import { DatePicker } from 'bits-ui';
  import { CalendarDate, parseDate, getLocalTimeZone, today } from '@internationalized/date';

  interface Props {
    name: string;
    label: string;
    value?: string;
    error?: string | null;
    required?: boolean;
    class?: string;
    min?: string;
    max?: string;
  }

  let {
    name,
    label,
    value = $bindable(),
    error = null,
    required = false,
    class: className = '',
    min = '2000-01-01',
    max = new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10)
  }: Props = $props();

  // Convert string to CalendarDate
  function stringToCalendarDate(dateStr: string | undefined): CalendarDate | undefined {
    if (!dateStr) return undefined;
    try {
      return parseDate(dateStr);
    } catch {
      return undefined;
    }
  }

  // Convert CalendarDate to string
  function calendarDateToString(date: CalendarDate | undefined): string {
    if (!date) return '';
    return date.toString();
  }

  // Internal state for Bits UI
  let internalValue = $state<CalendarDate | undefined>(stringToCalendarDate(value));

  // Sync internal value to external value
  $effect(() => {
    value = calendarDateToString(internalValue);
  });

  // Sync external value to internal value (when form is reset or value changes externally)
  $effect(() => {
    const newDate = stringToCalendarDate(value);
    if (newDate?.toString() !== internalValue?.toString()) {
      internalValue = newDate;
    }
  });

  // Parse min/max constraints
  const minValue = $derived(stringToCalendarDate(min));
  const maxValue = $derived(stringToCalendarDate(max));

  // Default placeholder to today (calendar opens to today's date)
  const placeholder = $derived(today(getLocalTimeZone()));

  // Computed classes for error states
  const inputClasses = $derived(
    `mt-1 flex h-10 w-full items-center rounded-md border bg-white px-3 py-2 text-sm shadow-sm transition-colors hover:border-gray-400 focus-within:outline-none focus-within:ring-2 focus-within:border-transparent ${
      error
        ? 'border-red-300 focus-within:ring-red-500'
        : 'border-gray-300 focus-within:ring-blue-500'
    }`
  );
</script>

<div class={className}>
  <label for={name} class="block text-sm font-medium text-gray-700 mb-1">
    {label} {required ? '*' : ''}
  </label>

  <DatePicker.Root
    bind:value={internalValue}
    {minValue}
    {maxValue}
    {placeholder}
    {required}
  >
    <DatePicker.Input class={inputClasses}>
      {#snippet children({ segments })}
        {#each segments as { part, value: segmentValue }}
          <DatePicker.Segment
            {part}
            class="inline-block select-none rounded px-0.5 py-1 focus:bg-blue-100 focus:text-blue-900 focus:outline-none"
          >
            {segmentValue}
          </DatePicker.Segment>
        {/each}
        <DatePicker.Trigger
          class="ml-auto inline-flex h-8 w-8 items-center justify-center rounded-md text-gray-500 transition-colors hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
            <line x1="16" y1="2" x2="16" y2="6"></line>
            <line x1="8" y1="2" x2="8" y2="6"></line>
            <line x1="3" y1="10" x2="21" y2="10"></line>
          </svg>
        </DatePicker.Trigger>
      {/snippet}
    </DatePicker.Input>

    <DatePicker.Content
      class="z-50 mt-2 min-w-[280px] rounded-md border border-gray-200 bg-white p-3 shadow-lg"
    >
      <DatePicker.Calendar class="w-full">
        {#snippet children({ months, weekdays })}
          <DatePicker.Header class="mb-4 flex items-center justify-between">
            <DatePicker.PrevButton
              class="inline-flex h-8 w-8 items-center justify-center rounded-md text-gray-700 transition-colors hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <polyline points="15 18 9 12 15 6"></polyline>
              </svg>
            </DatePicker.PrevButton>

            <DatePicker.Heading class="text-sm font-semibold text-gray-900" />

            <DatePicker.NextButton
              class="inline-flex h-8 w-8 items-center justify-center rounded-md text-gray-700 transition-colors hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <polyline points="9 18 15 12 9 6"></polyline>
              </svg>
            </DatePicker.NextButton>
          </DatePicker.Header>

          {#each months as month}
            <DatePicker.Grid class="w-full border-collapse">
              <DatePicker.GridHead>
                <DatePicker.GridRow class="mb-1 flex justify-between">
                  {#each weekdays as day}
                    <DatePicker.HeadCell class="w-8 text-xs font-medium text-gray-500">
                      {day.slice(0, 2)}
                    </DatePicker.HeadCell>
                  {/each}
                </DatePicker.GridRow>
              </DatePicker.GridHead>

              <DatePicker.GridBody>
                {#each month.weeks as weekDates}
                  <DatePicker.GridRow class="mb-1 flex w-full justify-between">
                    {#each weekDates as date}
                      <DatePicker.Cell
                        {date}
                        month={month.value}
                        class="flex h-8 w-8 items-center justify-center"
                      >
                        <DatePicker.Day
                          class="flex h-8 w-8 items-center justify-center rounded-md text-sm transition-colors hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500 data-[selected]:bg-blue-600 data-[selected]:text-white data-[selected]:hover:bg-blue-700 data-[disabled]:text-gray-300 data-[disabled]:hover:bg-transparent data-[outside-month]:text-gray-400"
                        >
                          {date.day}
                        </DatePicker.Day>
                      </DatePicker.Cell>
                    {/each}
                  </DatePicker.GridRow>
                {/each}
              </DatePicker.GridBody>
            </DatePicker.Grid>
          {/each}
        {/snippet}
      </DatePicker.Calendar>
    </DatePicker.Content>
  </DatePicker.Root>

  {#if error}
    <p class="mt-1 text-sm text-red-600">{error}</p>
  {/if}

  <!-- Hidden input for form submission -->
  <input type="hidden" {name} {value} {required} />
</div>
