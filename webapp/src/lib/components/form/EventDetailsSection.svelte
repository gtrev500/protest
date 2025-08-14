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
  label="Targets (e.g., Trump, Musk, ICE, etc)"
/>

<TextField
  name="macroevent"
  label="Macroevent (if part of a larger event)"
  placeholder="e.g., Women's March, Trump Inauguration protests, etc."
/>

<div>
  <label class="flex items-center">
    <input
      type="checkbox"
      name="is_online"
      class="rounded border-gray-300 text-blue-600"
    />
    <span class="ml-2 text-sm font-medium">This was an online event</span>
  </label>
</div>