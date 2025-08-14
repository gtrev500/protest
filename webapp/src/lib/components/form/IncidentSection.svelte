<script lang="ts">
  import RadioGroup from './RadioGroup.svelte';

  const incidentFields = [
    { name: 'participant_injury', label: 'Participant Injury' },
    { name: 'police_injury', label: 'Police Injury' },
    { name: 'arrests', label: 'Arrests' },
    { name: 'property_damage', label: 'Property Damage' },
    { name: 'participant_casualties', label: 'Participant Casualties' },
    { name: 'police_casualties', label: 'Police Casualties' }
  ];
</script>

{#each incidentFields as field}
  <RadioGroup
    name={field.name}
    label={field.label}
  />
{/each}