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

</script>

<fieldset>
  <legend class="block text-sm font-medium text-gray-700 mb-2">
    Submission Type *
  </legend>

  <div class="space-y-2 border rounded p-2">
    {#each submissionTypes as type}
      {#if type.id !== 0}
        <div>
          <label class="flex items-start">
            <input
              type="radio"
              name="submission_type"
              value={type.id.toString()}
              bind:group={value}
              class="mt-1 text-blue-600 focus:ring-blue-500 border-gray-300"
              required
            />
            <div class="ml-2 flex-1">
              <span class="text-sm">{type.name}</span>

              <!-- Inline reference search for correction/update types -->
              {#if value === type.id.toString() && (type === correctionType || type === updateType)}
                <div class="mt-2">
                  <p class="text-xs text-gray-600 mb-2">
                    {#if type === correctionType}
                      Select the protest entry that needs correction:
                    {:else if type === updateType}
                      Select the protest entry you're adding sources for:
                    {/if}
                  </p>
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
          </label>
        </div>
      {/if}
    {/each}

    <!-- Other option -->
    <label class="flex items-start">
      <input
        type="radio"
        name="submission_type"
        value="0"
        bind:group={value}
        class="mt-1 text-blue-600 focus:ring-blue-500 border-gray-300"
      />
      <div class="ml-2 flex-1">
        <span class="text-sm">Other</span>
        {#if showOtherInput}
          <input
            type="text"
            name="submission_type_other"
            bind:value={otherValue}
            placeholder="Specify other"
            class="mt-1 block w-full text-sm rounded-md border-gray-300"
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
</fieldset>