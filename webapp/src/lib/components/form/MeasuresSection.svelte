<script lang="ts">
  import CheckboxGroup from './CheckboxGroup.svelte';
  import type { ParticipantMeasure, PoliceMeasure } from '$lib/types/database';

  interface Props {
    participantMeasures: ParticipantMeasure[];
    policeMeasures: PoliceMeasure[];
    participantMeasureOther?: string;
    policeMeasureOther?: string;
    selectedParticipantMeasures?: string[];
    selectedPoliceMeasures?: string[];
  }

  let {
    participantMeasures,
    policeMeasures,
    participantMeasureOther = $bindable(''),
    policeMeasureOther = $bindable(''),
    selectedParticipantMeasures = $bindable([]),
    selectedPoliceMeasures = $bindable([])
  }: Props = $props();
</script>

<CheckboxGroup
  name="participant_measures"
  label="Participant Measures"
  options={participantMeasures}
  showOther
  bind:otherValue={participantMeasureOther}
  bind:values={selectedParticipantMeasures}
  otherPlaceholder="Specify other measure"
/>

<CheckboxGroup
  name="police_measures"
  label="Police Measures"
  options={policeMeasures}
  showOther
  bind:otherValue={policeMeasureOther}
  bind:values={selectedPoliceMeasures}
  otherPlaceholder="Specify other measure"
/>