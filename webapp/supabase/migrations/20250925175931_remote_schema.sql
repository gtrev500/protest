

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."get_protest_stats"("start_date" "date" DEFAULT NULL::"date", "end_date" "date" DEFAULT NULL::"date") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  result jsonb;
BEGIN
  result := jsonb_build_object(
    'total_protests', (
      SELECT COUNT(*) FROM protests 
      WHERE (start_date IS NULL OR date_of_event >= start_date)
      AND (end_date IS NULL OR date_of_event <= end_date)
    ),
    'total_participants_low', (
      SELECT SUM(crowd_size_low) FROM protests 
      WHERE (start_date IS NULL OR date_of_event >= start_date)
      AND (end_date IS NULL OR date_of_event <= end_date)
    ),
    'total_participants_high', (
      SELECT SUM(crowd_size_high) FROM protests 
      WHERE (start_date IS NULL OR date_of_event >= start_date)
      AND (end_date IS NULL OR date_of_event <= end_date)
    ),
    'states_count', (
      SELECT COUNT(DISTINCT state_code) FROM protests 
      WHERE (start_date IS NULL OR date_of_event >= start_date)
      AND (end_date IS NULL OR date_of_event <= end_date)
    ),
    'protests_by_state', (
      SELECT jsonb_object_agg(state_code, count) FROM (
        SELECT state_code, COUNT(*) as count 
        FROM protests 
        WHERE (start_date IS NULL OR date_of_event >= start_date)
        AND (end_date IS NULL OR date_of_event <= end_date)
        GROUP BY state_code
      ) s
    ),
    'protests_by_month', (
      SELECT jsonb_agg(jsonb_build_object(
        'month', to_char(date_of_event, 'YYYY-MM'),
        'count', count
      )) FROM (
        SELECT date_trunc('month', date_of_event) as date_of_event, COUNT(*) as count
        FROM protests
        WHERE (start_date IS NULL OR date_of_event >= start_date)
        AND (end_date IS NULL OR date_of_event <= end_date)
        GROUP BY date_trunc('month', date_of_event)
        ORDER BY date_trunc('month', date_of_event)
      ) m
    )
  );
  
  RETURN result;
END;
$$;


ALTER FUNCTION "public"."get_protest_stats"("start_date" "date", "end_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."protests_search_trigger"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('english', coalesce(NEW.title, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(NEW.claims_summary, '')), 'B') ||
    setweight(to_tsvector('english', coalesce(NEW.claims_verbatim, '')), 'C') ||
    setweight(to_tsvector('english', coalesce(NEW.organization_name, '')), 'D');
  RETURN NEW;
END
$$;


ALTER FUNCTION "public"."protests_search_trigger"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."submit_protest"("protest_data" "jsonb", "submission_types_data" "jsonb" DEFAULT '[]'::"jsonb", "event_types_data" "jsonb" DEFAULT '[]'::"jsonb", "participant_types_data" "jsonb" DEFAULT '[]'::"jsonb", "participant_measures_data" "jsonb" DEFAULT '[]'::"jsonb", "police_measures_data" "jsonb" DEFAULT '[]'::"jsonb", "notes_data" "jsonb" DEFAULT '[]'::"jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  new_protest_id uuid;
  result jsonb;
BEGIN
  -- Insert the main protest record
  INSERT INTO protests (
    date_of_event,
    locality,
    state_code,
    location_name,
    title,
    organization_name,
    notable_participants,
    targets,
    claims_summary,
    claims_verbatim,
    macroevent,
    is_online,
    crowd_size_low,
    crowd_size_high,
    participant_injury,
    participant_injury_details,
    police_injury,
    police_injury_details,
    arrests,
    arrests_details,
    property_damage,
    property_damage_details,
    participant_casualties,
    participant_casualties_details,
    police_casualties,
    police_casualties_details,
    sources,
    count_method
  ) VALUES (
    (protest_data->>'date_of_event')::date,
    protest_data->>'locality',
    protest_data->>'state_code',
    protest_data->>'location_name',
    protest_data->>'title',
    protest_data->>'organization_name',
    protest_data->>'notable_participants',
    protest_data->>'targets',
    protest_data->>'claims_summary',
    protest_data->>'claims_verbatim',
    protest_data->>'macroevent',
    COALESCE((protest_data->>'is_online')::boolean, false),
    (protest_data->>'crowd_size_low')::integer,
    (protest_data->>'crowd_size_high')::integer,
    protest_data->>'participant_injury',
    protest_data->>'participant_injury_details',
    protest_data->>'police_injury',
    protest_data->>'police_injury_details',
    protest_data->>'arrests',
    protest_data->>'arrests_details',
    protest_data->>'property_damage',
    protest_data->>'property_damage_details',
    protest_data->>'participant_casualties',
    protest_data->>'participant_casualties_details',
    protest_data->>'police_casualties',
    protest_data->>'police_casualties_details',
    protest_data->>'sources',
    protest_data->>'count_method'
  ) RETURNING id INTO new_protest_id;

  -- Insert submission types
  IF jsonb_array_length(submission_types_data) > 0 THEN
    INSERT INTO protest_submission_types (protest_id, submission_type_id, other_value)
    SELECT 
      new_protest_id,
      CASE 
        WHEN (item->>'id') IS NOT NULL THEN (item->>'id')::integer
        ELSE NULL
      END,
      item->>'other'
    FROM jsonb_array_elements(submission_types_data) AS item
    WHERE (item->>'id') IS NOT NULL OR (item->>'other') IS NOT NULL;
  END IF;

  -- Insert event types
  IF jsonb_array_length(event_types_data) > 0 THEN
    INSERT INTO protest_event_types (protest_id, event_type_id, other_value)
    SELECT 
      new_protest_id,
      CASE 
        WHEN (item->>'id') IS NOT NULL THEN (item->>'id')::integer
        ELSE NULL
      END,
      item->>'other'
    FROM jsonb_array_elements(event_types_data) AS item
    WHERE (item->>'id') IS NOT NULL OR (item->>'other') IS NOT NULL;
  END IF;

  -- Insert participant types
  IF jsonb_array_length(participant_types_data) > 0 THEN
    INSERT INTO protest_participant_types (protest_id, participant_type_id)
    SELECT 
      new_protest_id,
      (item->>'id')::integer
    FROM jsonb_array_elements(participant_types_data) AS item
    WHERE (item->>'id') IS NOT NULL;
  END IF;

  -- Insert participant measures
  IF jsonb_array_length(participant_measures_data) > 0 THEN
    INSERT INTO protest_participant_measures (protest_id, measure_id, other_value)
    SELECT 
      new_protest_id,
      CASE 
        WHEN (item->>'id') IS NOT NULL THEN (item->>'id')::integer
        ELSE NULL
      END,
      item->>'other'
    FROM jsonb_array_elements(participant_measures_data) AS item
    WHERE (item->>'id') IS NOT NULL OR (item->>'other') IS NOT NULL;
  END IF;

  -- Insert police measures
  IF jsonb_array_length(police_measures_data) > 0 THEN
    INSERT INTO protest_police_measures (protest_id, measure_id, other_value)
    SELECT 
      new_protest_id,
      CASE 
        WHEN (item->>'id') IS NOT NULL THEN (item->>'id')::integer
        ELSE NULL
      END,
      item->>'other'
    FROM jsonb_array_elements(police_measures_data) AS item
    WHERE (item->>'id') IS NOT NULL OR (item->>'other') IS NOT NULL;
  END IF;

  -- Insert notes
  IF jsonb_array_length(notes_data) > 0 THEN
    INSERT INTO protest_notes (protest_id, note_id, other_value)
    SELECT 
      new_protest_id,
      CASE 
        WHEN (item->>'id') IS NOT NULL THEN (item->>'id')::integer
        ELSE NULL
      END,
      item->>'other'
    FROM jsonb_array_elements(notes_data) AS item
    WHERE (item->>'id') IS NOT NULL OR (item->>'other') IS NOT NULL;
  END IF;

  -- Return the result
  result := jsonb_build_object(
    'id', new_protest_id,
    'success', true,
    'public_url', '/protest/' || new_protest_id
  );
  
  RETURN result;
END;
$$;


ALTER FUNCTION "public"."submit_protest"("protest_data" "jsonb", "submission_types_data" "jsonb", "event_types_data" "jsonb", "participant_types_data" "jsonb", "participant_measures_data" "jsonb", "police_measures_data" "jsonb", "notes_data" "jsonb") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."event_types" (
    "id" integer NOT NULL,
    "name" "text" NOT NULL
);


ALTER TABLE "public"."event_types" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."event_types_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."event_types_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."event_types_id_seq" OWNED BY "public"."event_types"."id";



CREATE TABLE IF NOT EXISTS "public"."notes_options" (
    "id" integer NOT NULL,
    "name" "text" NOT NULL
);


ALTER TABLE "public"."notes_options" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."notes_options_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."notes_options_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."notes_options_id_seq" OWNED BY "public"."notes_options"."id";



CREATE TABLE IF NOT EXISTS "public"."participant_measures" (
    "id" integer NOT NULL,
    "name" "text" NOT NULL
);


ALTER TABLE "public"."participant_measures" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."participant_measures_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."participant_measures_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."participant_measures_id_seq" OWNED BY "public"."participant_measures"."id";



CREATE TABLE IF NOT EXISTS "public"."participant_types" (
    "id" integer NOT NULL,
    "name" "text" NOT NULL
);


ALTER TABLE "public"."participant_types" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."participant_types_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."participant_types_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."participant_types_id_seq" OWNED BY "public"."participant_types"."id";



CREATE TABLE IF NOT EXISTS "public"."police_measures" (
    "id" integer NOT NULL,
    "name" "text" NOT NULL
);


ALTER TABLE "public"."police_measures" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."police_measures_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."police_measures_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."police_measures_id_seq" OWNED BY "public"."police_measures"."id";



CREATE OR REPLACE VIEW "public"."protest_details" AS
SELECT
    NULL::"uuid" AS "id",
    NULL::"date" AS "date_of_event",
    NULL::"text" AS "locality",
    NULL::"text" AS "state_code",
    NULL::"text" AS "location_name",
    NULL::"text" AS "title",
    NULL::"text" AS "organization_name",
    NULL::"text" AS "notable_participants",
    NULL::"text" AS "targets",
    NULL::"text" AS "claims_summary",
    NULL::"text" AS "claims_verbatim",
    NULL::"text" AS "macroevent",
    NULL::boolean AS "is_online",
    NULL::integer AS "crowd_size_low",
    NULL::integer AS "crowd_size_high",
    NULL::"text" AS "participant_injury",
    NULL::"text" AS "participant_injury_details",
    NULL::"text" AS "police_injury",
    NULL::"text" AS "police_injury_details",
    NULL::"text" AS "arrests",
    NULL::"text" AS "arrests_details",
    NULL::"text" AS "property_damage",
    NULL::"text" AS "property_damage_details",
    NULL::"text" AS "participant_casualties",
    NULL::"text" AS "participant_casualties_details",
    NULL::"text" AS "police_casualties",
    NULL::"text" AS "police_casualties_details",
    NULL::"text" AS "sources",
    NULL::timestamp with time zone AS "created_at",
    NULL::timestamp with time zone AS "updated_at",
    NULL::"tsvector" AS "search_vector",
    NULL::"text" AS "count_method",
    NULL::"text"[] AS "event_types",
    NULL::"text"[] AS "participant_types",
    NULL::"text"[] AS "participant_measures_list",
    NULL::"text"[] AS "police_measures_list",
    NULL::"text"[] AS "notes_list";


ALTER VIEW "public"."protest_details" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."protest_event_types" (
    "protest_id" "uuid" NOT NULL,
    "event_type_id" integer NOT NULL,
    "other_value" "text"
);


ALTER TABLE "public"."protest_event_types" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."protest_notes" (
    "protest_id" "uuid" NOT NULL,
    "note_id" integer NOT NULL,
    "other_value" "text"
);


ALTER TABLE "public"."protest_notes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."protest_participant_measures" (
    "protest_id" "uuid" NOT NULL,
    "measure_id" integer NOT NULL,
    "other_value" "text"
);


ALTER TABLE "public"."protest_participant_measures" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."protest_participant_types" (
    "protest_id" "uuid" NOT NULL,
    "participant_type_id" integer NOT NULL
);


ALTER TABLE "public"."protest_participant_types" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."protest_police_measures" (
    "protest_id" "uuid" NOT NULL,
    "measure_id" integer NOT NULL,
    "other_value" "text"
);


ALTER TABLE "public"."protest_police_measures" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."protest_submission_types" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "protest_id" "uuid" NOT NULL,
    "submission_type_id" integer,
    "other_value" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."protest_submission_types" OWNER TO "postgres";


COMMENT ON TABLE "public"."protest_submission_types" IS 'Junction table linking protests to submission types with optional other values';



COMMENT ON COLUMN "public"."protest_submission_types"."other_value" IS 'Used when submission_type_id is 0 (Other) to store custom submission type';



CREATE TABLE IF NOT EXISTS "public"."protests" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "date_of_event" "date" NOT NULL,
    "locality" "text" NOT NULL,
    "state_code" "text" NOT NULL,
    "location_name" "text",
    "title" "text" NOT NULL,
    "organization_name" "text",
    "notable_participants" "text",
    "targets" "text",
    "claims_summary" "text",
    "claims_verbatim" "text",
    "macroevent" "text",
    "is_online" boolean DEFAULT false,
    "crowd_size_low" integer,
    "crowd_size_high" integer,
    "participant_injury" "text",
    "participant_injury_details" "text",
    "police_injury" "text",
    "police_injury_details" "text",
    "arrests" "text",
    "arrests_details" "text",
    "property_damage" "text",
    "property_damage_details" "text",
    "participant_casualties" "text",
    "participant_casualties_details" "text",
    "police_casualties" "text",
    "police_casualties_details" "text",
    "sources" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "search_vector" "tsvector",
    "count_method" "text"
);


ALTER TABLE "public"."protests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."states" (
    "code" "text" NOT NULL,
    "name" "text" NOT NULL
);


ALTER TABLE "public"."states" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."submission_types" (
    "id" bigint NOT NULL,
    "name" "text" NOT NULL
);


ALTER TABLE "public"."submission_types" OWNER TO "postgres";


ALTER TABLE "public"."submission_types" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."submission_type_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE ONLY "public"."event_types" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."event_types_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."notes_options" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."notes_options_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."participant_measures" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."participant_measures_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."participant_types" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."participant_types_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."police_measures" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."police_measures_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."event_types"
    ADD CONSTRAINT "event_types_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."event_types"
    ADD CONSTRAINT "event_types_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notes_options"
    ADD CONSTRAINT "notes_options_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."notes_options"
    ADD CONSTRAINT "notes_options_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."participant_measures"
    ADD CONSTRAINT "participant_measures_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."participant_measures"
    ADD CONSTRAINT "participant_measures_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."participant_types"
    ADD CONSTRAINT "participant_types_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."participant_types"
    ADD CONSTRAINT "participant_types_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."police_measures"
    ADD CONSTRAINT "police_measures_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."police_measures"
    ADD CONSTRAINT "police_measures_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."protest_event_types"
    ADD CONSTRAINT "protest_event_types_pkey" PRIMARY KEY ("protest_id", "event_type_id");



ALTER TABLE ONLY "public"."protest_notes"
    ADD CONSTRAINT "protest_notes_pkey" PRIMARY KEY ("protest_id", "note_id");



ALTER TABLE ONLY "public"."protest_participant_measures"
    ADD CONSTRAINT "protest_participant_measures_pkey" PRIMARY KEY ("protest_id", "measure_id");



ALTER TABLE ONLY "public"."protest_participant_types"
    ADD CONSTRAINT "protest_participant_types_pkey" PRIMARY KEY ("protest_id", "participant_type_id");



ALTER TABLE ONLY "public"."protest_police_measures"
    ADD CONSTRAINT "protest_police_measures_pkey" PRIMARY KEY ("protest_id", "measure_id");



ALTER TABLE ONLY "public"."protest_submission_types"
    ADD CONSTRAINT "protest_submission_types_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."protests"
    ADD CONSTRAINT "protests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."states"
    ADD CONSTRAINT "states_pkey" PRIMARY KEY ("code");



ALTER TABLE ONLY "public"."submission_types"
    ADD CONSTRAINT "submission_type_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."protest_submission_types"
    ADD CONSTRAINT "unique_protest_submission_type" UNIQUE ("protest_id", "submission_type_id");



CREATE INDEX "idx_protest_submission_types_protest_id" ON "public"."protest_submission_types" USING "btree" ("protest_id");



CREATE INDEX "idx_protest_submission_types_submission_type_id" ON "public"."protest_submission_types" USING "btree" ("submission_type_id");



CREATE INDEX "idx_protests_created_at" ON "public"."protests" USING "btree" ("created_at");



CREATE INDEX "idx_protests_date" ON "public"."protests" USING "btree" ("date_of_event");



CREATE INDEX "idx_protests_locality" ON "public"."protests" USING "btree" ("locality");



CREATE INDEX "idx_protests_state" ON "public"."protests" USING "btree" ("state_code");



CREATE INDEX "protests_search_idx" ON "public"."protests" USING "gin" ("search_vector");



CREATE OR REPLACE VIEW "public"."protest_details" AS
 SELECT "p"."id",
    "p"."date_of_event",
    "p"."locality",
    "p"."state_code",
    "p"."location_name",
    "p"."title",
    "p"."organization_name",
    "p"."notable_participants",
    "p"."targets",
    "p"."claims_summary",
    "p"."claims_verbatim",
    "p"."macroevent",
    "p"."is_online",
    "p"."crowd_size_low",
    "p"."crowd_size_high",
    "p"."participant_injury",
    "p"."participant_injury_details",
    "p"."police_injury",
    "p"."police_injury_details",
    "p"."arrests",
    "p"."arrests_details",
    "p"."property_damage",
    "p"."property_damage_details",
    "p"."participant_casualties",
    "p"."participant_casualties_details",
    "p"."police_casualties",
    "p"."police_casualties_details",
    "p"."sources",
    "p"."created_at",
    "p"."updated_at",
    "p"."search_vector",
    "p"."count_method",
    "array_agg"(DISTINCT "et"."name") FILTER (WHERE ("et"."name" IS NOT NULL)) AS "event_types",
    "array_agg"(DISTINCT "pt"."name") FILTER (WHERE ("pt"."name" IS NOT NULL)) AS "participant_types",
    "array_agg"(DISTINCT "pm"."name") FILTER (WHERE ("pm"."name" IS NOT NULL)) AS "participant_measures_list",
    "array_agg"(DISTINCT "plm"."name") FILTER (WHERE ("plm"."name" IS NOT NULL)) AS "police_measures_list",
    "array_agg"(DISTINCT "no"."name") FILTER (WHERE ("no"."name" IS NOT NULL)) AS "notes_list"
   FROM (((((((((("public"."protests" "p"
     LEFT JOIN "public"."protest_event_types" "pet" ON (("p"."id" = "pet"."protest_id")))
     LEFT JOIN "public"."event_types" "et" ON (("pet"."event_type_id" = "et"."id")))
     LEFT JOIN "public"."protest_participant_types" "ppt" ON (("p"."id" = "ppt"."protest_id")))
     LEFT JOIN "public"."participant_types" "pt" ON (("ppt"."participant_type_id" = "pt"."id")))
     LEFT JOIN "public"."protest_participant_measures" "ppm" ON (("p"."id" = "ppm"."protest_id")))
     LEFT JOIN "public"."participant_measures" "pm" ON (("ppm"."measure_id" = "pm"."id")))
     LEFT JOIN "public"."protest_police_measures" "pplm" ON (("p"."id" = "pplm"."protest_id")))
     LEFT JOIN "public"."police_measures" "plm" ON (("pplm"."measure_id" = "plm"."id")))
     LEFT JOIN "public"."protest_notes" "pn" ON (("p"."id" = "pn"."protest_id")))
     LEFT JOIN "public"."notes_options" "no" ON (("pn"."note_id" = "no"."id")))
  GROUP BY "p"."id";



CREATE OR REPLACE TRIGGER "protests_search_update" BEFORE INSERT OR UPDATE ON "public"."protests" FOR EACH ROW EXECUTE FUNCTION "public"."protests_search_trigger"();



ALTER TABLE ONLY "public"."protest_event_types"
    ADD CONSTRAINT "protest_event_types_event_type_id_fkey" FOREIGN KEY ("event_type_id") REFERENCES "public"."event_types"("id");



ALTER TABLE ONLY "public"."protest_event_types"
    ADD CONSTRAINT "protest_event_types_protest_id_fkey" FOREIGN KEY ("protest_id") REFERENCES "public"."protests"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."protest_notes"
    ADD CONSTRAINT "protest_notes_note_id_fkey" FOREIGN KEY ("note_id") REFERENCES "public"."notes_options"("id");



ALTER TABLE ONLY "public"."protest_notes"
    ADD CONSTRAINT "protest_notes_protest_id_fkey" FOREIGN KEY ("protest_id") REFERENCES "public"."protests"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."protest_participant_measures"
    ADD CONSTRAINT "protest_participant_measures_measure_id_fkey" FOREIGN KEY ("measure_id") REFERENCES "public"."participant_measures"("id");



ALTER TABLE ONLY "public"."protest_participant_measures"
    ADD CONSTRAINT "protest_participant_measures_protest_id_fkey" FOREIGN KEY ("protest_id") REFERENCES "public"."protests"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."protest_participant_types"
    ADD CONSTRAINT "protest_participant_types_participant_type_id_fkey" FOREIGN KEY ("participant_type_id") REFERENCES "public"."participant_types"("id");



ALTER TABLE ONLY "public"."protest_participant_types"
    ADD CONSTRAINT "protest_participant_types_protest_id_fkey" FOREIGN KEY ("protest_id") REFERENCES "public"."protests"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."protest_police_measures"
    ADD CONSTRAINT "protest_police_measures_measure_id_fkey" FOREIGN KEY ("measure_id") REFERENCES "public"."police_measures"("id");



ALTER TABLE ONLY "public"."protest_police_measures"
    ADD CONSTRAINT "protest_police_measures_protest_id_fkey" FOREIGN KEY ("protest_id") REFERENCES "public"."protests"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."protest_submission_types"
    ADD CONSTRAINT "protest_submission_types_protest_id_fkey" FOREIGN KEY ("protest_id") REFERENCES "public"."protests"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."protest_submission_types"
    ADD CONSTRAINT "protest_submission_types_submission_type_id_fkey" FOREIGN KEY ("submission_type_id") REFERENCES "public"."submission_types"("id");



CREATE POLICY "Enable read access for all users" ON "public"."event_types" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."notes_options" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."participant_measures" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."participant_types" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."police_measures" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."states" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."submission_types" FOR SELECT USING (true);



CREATE POLICY "Public can insert protest submission types" ON "public"."protest_submission_types" FOR INSERT WITH CHECK (true);



CREATE POLICY "Public can read protest submission types" ON "public"."protest_submission_types" FOR SELECT USING (true);



CREATE POLICY "Public can view protest event types" ON "public"."protest_event_types" FOR SELECT USING (true);



CREATE POLICY "Public can view protest notes" ON "public"."protest_notes" FOR SELECT USING (true);



CREATE POLICY "Public can view protest participant measures" ON "public"."protest_participant_measures" FOR SELECT USING (true);



CREATE POLICY "Public can view protest participant types" ON "public"."protest_participant_types" FOR SELECT USING (true);



CREATE POLICY "Public can view protest police measures" ON "public"."protest_police_measures" FOR SELECT USING (true);



CREATE POLICY "Public protests are viewable by everyone" ON "public"."protests" FOR SELECT USING (true);



ALTER TABLE "public"."event_types" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notes_options" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."participant_measures" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."participant_types" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."police_measures" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."protest_event_types" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."protest_notes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."protest_participant_measures" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."protest_participant_types" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."protest_police_measures" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."protest_submission_types" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."protests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."states" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."submission_types" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."get_protest_stats"("start_date" "date", "end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."get_protest_stats"("start_date" "date", "end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_protest_stats"("start_date" "date", "end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."protests_search_trigger"() TO "anon";
GRANT ALL ON FUNCTION "public"."protests_search_trigger"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."protests_search_trigger"() TO "service_role";



GRANT ALL ON FUNCTION "public"."submit_protest"("protest_data" "jsonb", "submission_types_data" "jsonb", "event_types_data" "jsonb", "participant_types_data" "jsonb", "participant_measures_data" "jsonb", "police_measures_data" "jsonb", "notes_data" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."submit_protest"("protest_data" "jsonb", "submission_types_data" "jsonb", "event_types_data" "jsonb", "participant_types_data" "jsonb", "participant_measures_data" "jsonb", "police_measures_data" "jsonb", "notes_data" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."submit_protest"("protest_data" "jsonb", "submission_types_data" "jsonb", "event_types_data" "jsonb", "participant_types_data" "jsonb", "participant_measures_data" "jsonb", "police_measures_data" "jsonb", "notes_data" "jsonb") TO "service_role";


















GRANT ALL ON TABLE "public"."event_types" TO "anon";
GRANT ALL ON TABLE "public"."event_types" TO "authenticated";
GRANT ALL ON TABLE "public"."event_types" TO "service_role";



GRANT ALL ON SEQUENCE "public"."event_types_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."event_types_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."event_types_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."notes_options" TO "anon";
GRANT ALL ON TABLE "public"."notes_options" TO "authenticated";
GRANT ALL ON TABLE "public"."notes_options" TO "service_role";



GRANT ALL ON SEQUENCE "public"."notes_options_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."notes_options_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."notes_options_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."participant_measures" TO "anon";
GRANT ALL ON TABLE "public"."participant_measures" TO "authenticated";
GRANT ALL ON TABLE "public"."participant_measures" TO "service_role";



GRANT ALL ON SEQUENCE "public"."participant_measures_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."participant_measures_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."participant_measures_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."participant_types" TO "anon";
GRANT ALL ON TABLE "public"."participant_types" TO "authenticated";
GRANT ALL ON TABLE "public"."participant_types" TO "service_role";



GRANT ALL ON SEQUENCE "public"."participant_types_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."participant_types_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."participant_types_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."police_measures" TO "anon";
GRANT ALL ON TABLE "public"."police_measures" TO "authenticated";
GRANT ALL ON TABLE "public"."police_measures" TO "service_role";



GRANT ALL ON SEQUENCE "public"."police_measures_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."police_measures_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."police_measures_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."protest_details" TO "anon";
GRANT ALL ON TABLE "public"."protest_details" TO "authenticated";
GRANT ALL ON TABLE "public"."protest_details" TO "service_role";



GRANT ALL ON TABLE "public"."protest_event_types" TO "anon";
GRANT ALL ON TABLE "public"."protest_event_types" TO "authenticated";
GRANT ALL ON TABLE "public"."protest_event_types" TO "service_role";



GRANT ALL ON TABLE "public"."protest_notes" TO "anon";
GRANT ALL ON TABLE "public"."protest_notes" TO "authenticated";
GRANT ALL ON TABLE "public"."protest_notes" TO "service_role";



GRANT ALL ON TABLE "public"."protest_participant_measures" TO "anon";
GRANT ALL ON TABLE "public"."protest_participant_measures" TO "authenticated";
GRANT ALL ON TABLE "public"."protest_participant_measures" TO "service_role";



GRANT ALL ON TABLE "public"."protest_participant_types" TO "anon";
GRANT ALL ON TABLE "public"."protest_participant_types" TO "authenticated";
GRANT ALL ON TABLE "public"."protest_participant_types" TO "service_role";



GRANT ALL ON TABLE "public"."protest_police_measures" TO "anon";
GRANT ALL ON TABLE "public"."protest_police_measures" TO "authenticated";
GRANT ALL ON TABLE "public"."protest_police_measures" TO "service_role";



GRANT ALL ON TABLE "public"."protest_submission_types" TO "anon";
GRANT ALL ON TABLE "public"."protest_submission_types" TO "authenticated";
GRANT ALL ON TABLE "public"."protest_submission_types" TO "service_role";



GRANT ALL ON TABLE "public"."protests" TO "anon";
GRANT ALL ON TABLE "public"."protests" TO "authenticated";
GRANT ALL ON TABLE "public"."protests" TO "service_role";



GRANT ALL ON TABLE "public"."states" TO "anon";
GRANT ALL ON TABLE "public"."states" TO "authenticated";
GRANT ALL ON TABLE "public"."states" TO "service_role";



GRANT ALL ON TABLE "public"."submission_types" TO "anon";
GRANT ALL ON TABLE "public"."submission_types" TO "authenticated";
GRANT ALL ON TABLE "public"."submission_types" TO "service_role";



GRANT ALL ON SEQUENCE "public"."submission_type_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."submission_type_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."submission_type_id_seq" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";






























RESET ALL;

