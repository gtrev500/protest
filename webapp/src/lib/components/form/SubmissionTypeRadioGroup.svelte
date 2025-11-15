<script lang="ts">
  import ProtestReferenceSearch from './ProtestReferenceSearch.svelte';
  import type { SubmissionType } from '$lib/types/database';
  import { capitalize } from '$lib/utils/string';

  interface Props {
    submissionTypes: SubmissionType[];
    value?: string;
    referencedProtestId?: string;
    errors?: Record<string, string | string[]>;
  }

  let {
    submissionTypes,
    value = $bindable(''),
    referencedProtestId = $bindable(''),
    errors = {}
  }: Props = $props();

  // Find IDs for special types by checking the name
  // These match the database:
  // - ID 2: "data correction"
  const correctionType = $derived(
    submissionTypes.find(t =>
      t.name.toLowerCase().includes('correction') ||
      t.name.toLowerCase().includes('correct')
    )
  );

  // Check if current selection needs a reference (only correction type now)
  const needsReference = $derived(
    value === correctionType?.id.toString()
  );

  // Auto-select first option if none selected and we have submission types
  $effect(() => {
    if (!value && submissionTypes.length > 0) {
      value = submissionTypes[0].id.toString();
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
    Submission Type <span class="text-danger-500">*</span>
  </legend>

  <div class="space-y-2 border rounded p-2">
    {#each submissionTypes as type}
      <div>
        <label class="flex items-start">
          <input
            type="radio"
            name="submission_type"
            value={type.id.toString()}
            bind:group={value}
            class="mt-1 text-brand-600 focus:ring-brand-500 border-gray-300"
            required
          />
          <div class="ml-2 flex-1">
            <span class="text-sm">{capitalize(type.name)}</span>

            <!-- Inline reference search for correction type -->
            {#if value === type.id.toString() && type === correctionType}
              <div class="mt-2">
                <p class="text-xs text-gray-600 mb-2">
                  Select the protest entry that needs correction:
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
    {/each}
  </div>

  {#if errors?.submission_type}
    <p class="mt-1 text-sm text-danger-600">
      {Array.isArray(errors.submission_type) ? errors.submission_type[0] : errors.submission_type}
    </p>
  {/if}
</fieldset>