<script lang="ts">
  import OtherInput from '../OtherInput.svelte';
  
  interface Props {
    values?: string[];
    otherValue?: string;
  }
  
  let {
    values = $bindable([]),
    otherValue = $bindable('')
  }: Props = $props();
  
  // Define submission types with subtle icons
  const submissionTypes = [
    {
      id: 'new_record',
      name: 'New record',
      description: 'Submit a new protest event to the database',
      icon: '➕'
    },
    {
      id: 'update_source',
      name: 'Updated or additional source for existing record',
      description: 'Add new sources or update information for an existing entry',
      icon: '📝'
    },
    {
      id: 'data_correction',
      name: 'Data correction',
      description: 'Correct inaccurate information in an existing record',
      icon: '🔧'
    }
  ];
</script>

<div class="bg-blue-50/50 rounded-lg p-4 mb-6">
  <div class="flex items-center mb-3">
    <span class="text-blue-600 mr-2">ℹ️</span>
    <div>
      <label class="text-sm font-medium text-gray-700">
        Which best describes your submission?
      </label>
      <span class="text-sm text-gray-500 ml-2">Check all that apply</span>
    </div>
  </div>
  
  <div class="bg-white rounded p-3 border-1
  ">
    {#each submissionTypes as type}
      <label class="flex items-start py-2 hover:bg-gray-50 rounded cursor-pointer">
        <input
          type="checkbox"
          name="submission_type"
          value={type.id}
          bind:group={values}
          class="rounded border-gray-300 text-blue-600 mt-0.5"
        />
        <div class="ml-3">
          <div class="flex items-center">
            <span class="text-sm mr-1.5">{type.icon}</span>
            <span class="text-sm text-gray-900">{type.name}</span>
          </div>
          <p class="text-xs text-gray-500 mt-0.5 ml-5">{type.description}</p>
        </div>
      </label>
    {/each}
    
    <div class="border-t mt-3 pt-3">
      <label class="flex items-start">
        <input
          type="checkbox"
          name="submission_type_other"
          class="rounded border-gray-300 text-blue-600 mt-0.5"
        />
        <div class="ml-3 flex-1">
          <span class="text-sm text-gray-900">Other:</span>
          {#if !!otherValue || values.includes('other')}
            <input
              type="text"
              bind:value={otherValue}
              placeholder="Please describe"
              class="mt-1 w-full text-sm border-gray-300 rounded-md"
            />
          {/if}
        </div>
      </label>
    </div>
  </div>
</div>
