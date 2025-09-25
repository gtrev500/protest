<script lang="ts">
  import ProtestReferenceSearch from './ProtestReferenceSearch.svelte';
  import type { SubmissionType } from '$lib/types/database';

  interface Props {
    submissionTypes: SubmissionType[];
    value?: string;
    otherValue?: string;
    referencedProtestId?: string;
    errors?: Record<string, string | string[]>;
  }

  let {
    submissionTypes,
    value = $bindable(''),
    otherValue = $bindable(''),
    referencedProtestId = $bindable(''),
    errors = {}
  }: Props = $props();

  // Find IDs for special types by checking the name
  // These should match your database:
  // - "Data correction" or similar for corrections
  // - "Updated or additional source for existing record" for updates
  const correctionType = $derived(
    submissionTypes.find(t =>
      t.name.toLowerCase().includes('correction') ||
      t.name.toLowerCase().includes('correct')
    )
  );

  const updateType = $derived(
    submissionTypes.find(t =>
      (t.name.toLowerCase().includes('update') ||
       t.name.toLowerCase().includes('additional')) &&
      t.name.toLowerCase().includes('source')
    )
  );

  // Check if current selection needs a reference
  const needsReference = $derived(
    value === correctionType?.id.toString() ||
    value === updateType?.id.toString()
  );

  // Check if "other" is selected (ID 0 is reserved for "other")
  const showOtherInput = $derived(value === '0');

  // Auto-select first option if none selected and we have submission types
  $effect(() => {
    if (!value && submissionTypes.length > 0) {
      const firstType = submissionTypes.find(t => t.id !== 0);
      if (firstType) {
        value = firstType.id.toString();
      }
    }
  });

  // Clear reference when switching away from correction/update
  $effect(() => {
    if (!needsReference && referencedProtestId) {
      referencedProtestId = '';
    }
  });

  // Helper to get description for submission types
  function getTypeDescription(type: SubmissionType): string | null {
    if (type === correctionType) {
      return 'Fix inaccurate information in an existing record';
    }
    if (type === updateType) {
      return 'Add new sources or update information for an existing entry';
    }
    if (type.name.toLowerCase().includes('new')) {
      return 'Submit a new protest event to the database';
    }
    return null;
  }

  // Get icon for submission type
  function getTypeIcon(type: SubmissionType): string {
    if (type === correctionType) return '🔧';
    if (type === updateType) return '📝';
    if (type.name.toLowerCase().includes('new')) return '➕';
    return '📋';
  }
</script>

<div class="space-y-4">
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-3">
      Submission Type *
    </label>

    <div class="space-y-2 bg-gray-50 rounded-lg p-4">
      {#each submissionTypes as type}
        {#if type.id !== 0}
          {@const description = getTypeDescription(type)}
          {@const icon = getTypeIcon(type)}
          <label class="flex items-start cursor-pointer hover:bg-white
                        rounded-lg p-3 transition-all duration-150
                        border border-transparent hover:border-gray-200
                        {value === type.id.toString() ? 'bg-white border-blue-200 shadow-sm' : ''}">
            <input
              type="radio"
              name="submission_type"
              value={type.id.toString()}
              bind:group={value}
              class="mt-0.5 text-blue-600 focus:ring-blue-500 border-gray-300"
              required
            />
            <div class="ml-3 flex-1">
              <div class="flex items-center">
                <span class="text-lg mr-2" aria-hidden="true">{icon}</span>
                <span class="text-sm font-medium text-gray-900">
                  {type.name}
                </span>
              </div>
              {#if description}
                <p class="text-xs text-gray-500 mt-1 ml-7">
                  {description}
                </p>
              {/if}
            </div>
          </label>
        {/if}
      {/each}

      <!-- Other option -->
      <label class="flex items-start cursor-pointer hover:bg-white
                    rounded-lg p-3 transition-all duration-150
                    border border-transparent hover:border-gray-200
                    {value === '0' ? 'bg-white border-blue-200 shadow-sm' : ''}">
        <input
          type="radio"
          name="submission_type"
          value="0"
          bind:group={value}
          class="mt-0.5 text-blue-600 focus:ring-blue-500 border-gray-300"
        />
        <div class="ml-3 flex-1">
          <div class="flex items-center">
            <span class="text-lg mr-2" aria-hidden="true">✏️</span>
            <span class="text-sm font-medium text-gray-900">Other</span>
          </div>
          {#if showOtherInput}
            <input
              type="text"
              name="submission_type_other"
              bind:value={otherValue}
              placeholder="Please specify the submission type..."
              class="mt-2 w-full text-sm border-gray-300 rounded-md
                     focus:ring-blue-500 focus:border-blue-500"
              required
            />
          {/if}
        </div>
      </label>
    </div>

    {#if errors?.submission_type}
      <p class="mt-1 text-sm text-red-600">
        {Array.isArray(errors.submission_type) ? errors.submission_type[0] : errors.submission_type}
      </p>
    {/if}
  </div>

  <!-- Conditional reference search -->
  {#if needsReference}
    <div class="mt-4 p-4 bg-amber-50 border border-amber-200 rounded-lg
                animate-in slide-in-from-top-2 duration-200">
      <div class="flex items-start mb-3">
        <svg class="w-5 h-5 text-amber-600 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
        </svg>
        <div class="ml-2">
          <p class="text-sm font-medium text-amber-800">
            {#if value === correctionType?.id.toString()}
              Please find and select the protest entry that needs correction
            {:else if value === updateType?.id.toString()}
              Please find and select the protest entry you're adding sources for
            {:else}
              Please select the related protest entry
            {/if}
          </p>
          <p class="text-xs text-amber-700 mt-1">
            Search by location, date, organization, or any keywords from the original entry
          </p>
        </div>
      </div>

      <ProtestReferenceSearch
        name="referenced_protest_id"
        bind:value={referencedProtestId}
        required={true}
        error={errors?.referenced_protest_id
          ? (Array.isArray(errors.referenced_protest_id)
              ? errors.referenced_protest_id[0]
              : errors.referenced_protest_id)
          : null}
      />
    </div>
  {/if}
</div>

<style>
  @keyframes slide-in-from-top-2 {
    from {
      transform: translateY(-0.5rem);
      opacity: 0;
    }
    to {
      transform: translateY(0);
      opacity: 1;
    }
  }

  .animate-in {
    animation-fill-mode: both;
  }

  .slide-in-from-top-2 {
    animation-name: slide-in-from-top-2;
  }

  .duration-200 {
    animation-duration: 200ms;
  }
</style>