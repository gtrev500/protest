import type { ProtestData, JunctionOption } from '$lib/types/database';
import type { ProtestFormSchema } from '$lib/types/schemas';

export interface OtherValues {
  eventTypeOthers: Record<number, string>;
  participantMeasureOthers: Record<number, string>;
  policeMeasureOthers: Record<number, string>;
  notesOthers: Record<number, string>;
}

export function prepareProtestData(values: ProtestFormSchema): ProtestData {
  return {
    date_of_event: values.date_of_event,
    locality: values.locality,
    state_code: values.state_code,
    location_name: values.location_name,
    title: values.title,
    organization_name: values.organization_name,
    notable_participants: values.notable_participants,
    targets: values.targets,
    claims_summary: values.claims_summary,
    claims_verbatim: values.claims_verbatim,
    macroevent: values.macroevent,
    is_online: values.is_online,
    count_method: values.count_method,
    crowd_size_low: values.crowd_size_low || null,
    crowd_size_high: values.crowd_size_high || null,
    participant_injury: values.participant_injury,
    participant_injury_details: values.participant_injury_details,
    police_injury: values.police_injury,
    police_injury_details: values.police_injury_details,
    arrests: values.arrests,
    arrests_details: values.arrests_details,
    property_damage: values.property_damage,
    property_damage_details: values.property_damage_details,
    participant_casualties: values.participant_casualties,
    participant_casualties_details: values.participant_casualties_details,
    police_casualties: values.police_casualties,
    police_casualties_details: values.police_casualties_details,
    sources: values.sources
  };
}

export function prepareJunctionData(
  ids: string[],
  otherValues: Record<number, string>
): JunctionOption[] {
  return ids.map((id) => {
    const numId = parseInt(id);
    return {
      id: numId,
      other: numId === 0 ? otherValues[0] : null
    };
  });
}

export function prepareParticipantTypesData(ids: string[]): { id: number }[] {
  return ids.map(id => ({ id: parseInt(id) }));
}

export function prepareSubmissionData(
  values: ProtestFormSchema,
  otherValues: OtherValues
) {
  const protestData = prepareProtestData(values);
  
  const eventTypesData = prepareJunctionData(
    values.event_types,
    otherValues.eventTypeOthers
  );
  
  const participantTypesData = prepareParticipantTypesData(
    values.participant_types
  );
  
  const participantMeasuresData = prepareJunctionData(
    values.participant_measures,
    otherValues.participantMeasureOthers
  );
  
  const policeMeasuresData = prepareJunctionData(
    values.police_measures,
    otherValues.policeMeasureOthers
  );
  
  const notesData = prepareJunctionData(
    values.notes,
    otherValues.notesOthers
  );

  return {
    protest_data: protestData,
    event_types_data: eventTypesData,
    participant_types_data: participantTypesData,
    participant_measures_data: participantMeasuresData,
    police_measures_data: policeMeasuresData,
    notes_data: notesData
  };
}