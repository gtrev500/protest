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
  
  // Define submission types with icons for better visual hierarchy
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
      icon: '✏️'
    }
  ];
</script>

<div class="bg-blue-50 border-2 border-blue-200 rounded-lg p-4 mb-6">
  <div class="flex items-start mb-3">
    <span class="text-blue-600 mr-2 text-lg">ℹ️</span>
    <div class="flex-1">
      <label class="block text-base font-semibold text-gray-800">
        Which best describes your submission?
      </label>
      <p class="text-sm text-gray-600 mt-1">Check all that apply</p>
    </div>
  </div>
  
  <div class="space-y-3 bg-white rounded-lg p-3">
    {#each submissionTypes as type}
      <label class="flex items-start p-2 rounded hover:bg-gray-50 transition-colors cursor-pointer">
        <input
          type="checkbox"
          name="submission_type"
          value={type.id}
          bind:group={values}
          class="rounded border-gray-300 text-blue-600 mt-1"
        />
        <div class="ml-3 flex-1">
          <div class="flex items-center">
            <span class="mr-2 text-lg">{type.icon}</span>
            <span class="font-medium text-gray-900">{type.name}</span>
          </div>
          <p class="text-xs text-gray-500 mt-0.5 ml-7">{type.description}</p>
        </div>
      </label>
    {/each}
    
    <div class="border-t pt-3 mt-3">
      <OtherInput
        checkboxName="submission_type"
        bind:otherText={otherValue}
        placeholder="Please describe your submission type"
        class="bg-gray-50"
      />
    </div>
  </div>
</div>