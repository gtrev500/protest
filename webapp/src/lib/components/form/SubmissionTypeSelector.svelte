<script lang="ts">
  interface Props {
    values?: string[];
    otherValue?: string;
  }

  let {
    values = $bindable([]),
    otherValue = $bindable('')
  }: Props = $props();

  // Define submission types
  const submissionTypes = [
    {
      id: 'new_record',
      name: 'New record'
    },
    {
      id: 'update_source',
      name: 'Updated or additional source for existing record'
    },
    {
      id: 'data_correction',
      name: 'Data correction'
    }
  ];

  let otherChecked = $state(false);
</script>

<div>
  <label class="block text-sm font-medium text-gray-700 mb-2">
    Submission Type
  </label>
  <div class="space-y-2 max-h-60 overflow-y-auto border rounded p-2">
    {#each submissionTypes as type}
      <label class="flex items-center">
        <input
          type="checkbox"
          name="submission_type"
          value={type.id}
          bind:group={values}
          class="rounded border-gray-300 text-blue-600"
        />
        <span class="ml-2 text-sm">{type.name}</span>
      </label>
    {/each}
    <label class="flex items-start">
      <input
        type="checkbox"
        name="submission_type"
        value="other"
        bind:checked={otherChecked}
        class="rounded border-gray-300 text-blue-600 mt-1"
      />
      <div class="ml-2 flex-1">
        <span class="text-sm">Other:</span>
        {#if otherChecked}
          <input
            type="text"
            name="submission_type_other"
            bind:value={otherValue}
            class="mt-1 block w-full text-sm rounded-md border-gray-300"
            placeholder="Specify other"
          />
        {/if}
      </div>
    </label>
  </div>
  <p class="mt-1 text-xs text-gray-500 italic">
    Check all that apply
  </p>
</div>
