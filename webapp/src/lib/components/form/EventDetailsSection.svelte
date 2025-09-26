<script lang="ts">
  import CheckboxGroup from './CheckboxGroup.svelte';
  import TextField from './TextField.svelte';
  import type { EventType, ParticipantType } from '$lib/types/database';

  interface Props {
    eventTypes: EventType[];
    participantTypes: ParticipantType[];
    eventTypeOther?: string;
    selectedEventTypes?: string[];
    selectedParticipantTypes?: string[];
    organizationName?: string;
    notableParticipants?: string;
    targets?: string;
  }

  let {
    eventTypes,
    participantTypes,
    eventTypeOther = $bindable(''),
    selectedEventTypes = $bindable([]),
    selectedParticipantTypes = $bindable([]),
    organizationName = $bindable(''),
    notableParticipants = $bindable(''),
    targets = $bindable('')
  }: Props = $props();
</script>

<CheckboxGroup
  name="event_types"
  label="Event Type(s)"
  options={eventTypes}
  showOther
  bind:otherValue={eventTypeOther}
  bind:values={selectedEventTypes}
  otherPlaceholder="Specify other event type"
  supplementalInformation="*These actions may qualify as long as participants articulate grievances around broader political issues."
/>
<TextField
  name="organization_name"
  label="Organization(s) Name(s)"
  bind:value={organizationName}
/>

<CheckboxGroup
  name="participant_types"
  label="Participant Types"
  options={participantTypes}
  bind:values={selectedParticipantTypes}
/>

<TextField
  name="notable_participants"
  label="Notable Participants (public figures)"
  bind:value={notableParticipants}
/>

<TextField
  name="targets"
  label="Target(s) or Focal Point(s)"
  placeholder="e.g. Trump, Musk, ICE"
  bind:value={targets}
/>