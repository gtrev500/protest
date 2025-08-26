<script lang="ts">
  import CheckboxGroup from './CheckboxGroup.svelte';
  import TextField from './TextField.svelte';
  import type { EventType, ParticipantType } from '$lib/types/database';

  interface Props {
    eventTypes: EventType[];
    participantTypes: ParticipantType[];
    eventTypeOther?: string;
  }

  let { eventTypes, participantTypes, eventTypeOther = $bindable('') }: Props = $props();
</script>

<CheckboxGroup
  name="event_types"
  label="Event Type(s)"
  options={eventTypes}
  showOther
  bind:otherValue={eventTypeOther}
  otherPlaceholder="Specify other event type"
  supplementalInformation="*These actions may qualify as long as participants articulate grievances around broader political issues."
/>
<TextField
  name="organization_name"
  label="Organization Name"
/>

<CheckboxGroup
  name="participant_types"
  label="Participant Types"
  options={participantTypes}
/>

<TextField
  name="notable_participants"
  label="Notable Participants (public figures)"
/>

<TextField
  name="targets"
  label="Target(s) or Focal Point(s)"
  placeholder="e.g. Trump, Musk, ICE"
/>

<TextField
  name="macroevent"
  label="Macroevent"
  placeholder="e.g., protest with counter-protest, rally with counter-demonstration, etc."
  supplementalInformation="See <a href='https://docs.google.com/document/d/1oaOf9s72FQnzQA8sbE8h0PwMIZLP6p0EDUV2ya065is/edit?tab=t.0#heading=h.8qik6d2y71b8' target='_blank' class='underline hover:no-underline'>here</a> for guidelines."
/>