<script lang="ts">
  import RadioGroup from './RadioGroup.svelte';

  interface Props {
    participantInjury?: string;
    participantInjuryDetails?: string;
    policeInjury?: string;
    policeInjuryDetails?: string;
    arrests?: string;
    arrestsDetails?: string;
    propertyDamage?: string;
    propertyDamageDetails?: string;
    participantCasualties?: string;
    participantCasualtiesDetails?: string;
    policeCasualties?: string;
    policeCasualtiesDetails?: string;
  }

  let {
    participantInjury = $bindable('no'),
    participantInjuryDetails = $bindable(''),
    policeInjury = $bindable('no'),
    policeInjuryDetails = $bindable(''),
    arrests = $bindable('no'),
    arrestsDetails = $bindable(''),
    propertyDamage = $bindable('no'),
    propertyDamageDetails = $bindable(''),
    participantCasualties = $bindable('no'),
    participantCasualtiesDetails = $bindable(''),
    policeCasualties = $bindable('no'),
    policeCasualtiesDetails = $bindable('')
  }: Props = $props();
</script>

<RadioGroup
  name="participant_injury"
  label="Participant Injury"
  bind:value={participantInjury}
  bind:detailsValue={participantInjuryDetails}
/>

<RadioGroup
  name="police_injury"
  label="Police Injury"
  bind:value={policeInjury}
  bind:detailsValue={policeInjuryDetails}
/>

<RadioGroup
  name="arrests"
  label="Arrests"
  bind:value={arrests}
  bind:detailsValue={arrestsDetails}
/>

<RadioGroup
  name="property_damage"
  label="Property Damage"
  bind:value={propertyDamage}
  bind:detailsValue={propertyDamageDetails}
/>

<RadioGroup
  name="participant_casualties"
  label="Participant Casualties"
  bind:value={participantCasualties}
  bind:detailsValue={participantCasualtiesDetails}
/>

<RadioGroup
  name="police_casualties"
  label="Police Casualties"
  bind:value={policeCasualties}
  bind:detailsValue={policeCasualtiesDetails}
/>