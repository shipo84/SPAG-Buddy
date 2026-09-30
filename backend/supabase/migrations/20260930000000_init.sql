-- SPAG Buddy initial schema.
--
-- Data protection notes:
--   * Pupils are identified by first name or nickname plus a random id. No email, photo or date of birth.
--   * Teachers can only see classes they teach (Row Level Security, see bottom of file).
--   * Pupil devices never talk to the database directly. The `api` Edge Function checks the device
--     token and writes with the service role.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------------
-- People and classes
-- ---------------------------------------------------------------------------

create table public.schools (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 120),
  -- DfE Unique Reference Number, optional.
  urn text check (urn ~ '^[0-9]{6,7}$'),
  created_at timestamptz not null default now()
);

create table public.teachers (
  id uuid primary key references auth.users (id) on delete cascade,
  school_id uuid references public.schools (id) on delete set null,
  display_name text not null check (char_length(display_name) between 1 and 80),
  created_at timestamptz not null default now()
);

create table public.classes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid references public.schools (id) on delete set null,
  name text not null check (char_length(name) between 1 and 60),
  year_group smallint not null check (year_group between 1 and 6),
  class_code text not null unique check (class_code ~ '^[A-HJ-NP-Z2-9]{6}$'),
  join_failures integer not null default 0,
  join_failures_since timestamptz,
  archived_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.class_teachers (
  class_id uuid not null references public.classes (id) on delete cascade,
  teacher_id uuid not null references public.teachers (id) on delete cascade,
  role text not null default 'teacher' check (role in ('owner', 'teacher')),
  primary key (class_id, teacher_id)
);

create table public.pupils (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes (id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 30),
  avatar_key text not null,
  -- bcrypt hash of the 4-digit PIN printed on the pupil's login card.
  pin_hash text not null,
  failed_logins integer not null default 0,
  locked_until timestamptz,
  created_at timestamptz not null default now(),
  unique (class_id, avatar_key)
);

create table public.devices (
  id uuid primary key default gen_random_uuid(),
  pupil_id uuid not null references public.pupils (id) on delete cascade,
  -- SHA-256 of the bearer token held in the iPad's Keychain. The token itself is never stored.
  token_hash text not null unique,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz,
  revoked_at timestamptz
);

-- ---------------------------------------------------------------------------
-- Curriculum content (seeded from the app's content JSON by scripts/generate-seed.mjs)
-- ---------------------------------------------------------------------------

create table public.objectives (
  code text primary key,
  year_group smallint not null check (year_group between 1 and 6),
  strand text not null check (strand in ('spelling', 'punctuation', 'grammar', 'vocabulary')),
  title text not null,
  child_title text not null,
  rule text not null
);

create table public.spelling_lists (
  id text primary key,
  title text not null,
  objective_code text not null references public.objectives (code),
  year_groups smallint[] not null,
  word_count integer not null
);

create table public.questions (
  id text primary key,
  objective_code text not null references public.objectives (code),
  spelling_list_id text references public.spelling_lists (id),
  type text not null check (type in ('multipleChoice', 'multiSelect', 'spelling', 'tapGap', 'rewrite')),
  prompt text not null,
  answers jsonb not null,
  sats_style boolean not null default false,
  content_version text not null
);

create index questions_objective_idx on public.questions (objective_code);

-- ---------------------------------------------------------------------------
-- Work and results
-- ---------------------------------------------------------------------------

create table public.assignments (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes (id) on delete cascade,
  created_by uuid references public.teachers (id) on delete set null,
  title text not null check (char_length(title) between 1 and 80),
  objective_codes text[] not null default '{}',
  spelling_list_id text references public.spelling_lists (id),
  -- null means the whole class; otherwise a group of pupils.
  pupil_ids uuid[],
  due_date date,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  check (cardinality(objective_codes) > 0 or spelling_list_id is not null)
);

create index assignments_class_idx on public.assignments (class_id) where archived_at is null;

create table public.attempts (
  id uuid primary key default gen_random_uuid(),
  -- Generated on the iPad. Makes uploads idempotent when a batch is retried.
  client_attempt_id uuid not null unique,
  pupil_id uuid not null references public.pupils (id) on delete cascade,
  class_id uuid not null references public.classes (id) on delete cascade,
  question_id text not null references public.questions (id),
  objective_code text not null references public.objectives (code),
  strand text not null,
  correct boolean not null,
  answer_given text not null default '' check (char_length(answer_given) <= 200),
  time_taken_ms integer not null default 0 check (time_taken_ms >= 0),
  hint_used boolean not null default false,
  session_id uuid not null,
  session_kind text not null,
  assignment_id uuid references public.assignments (id) on delete set null,
  answered_at timestamptz not null,
  received_at timestamptz not null default now()
);

create index attempts_class_time_idx on public.attempts (class_id, answered_at);
create index attempts_pupil_time_idx on public.attempts (pupil_id, answered_at);
create index attempts_class_objective_idx on public.attempts (class_id, objective_code);

create table public.audit_log (
  id bigint generated always as identity primary key,
  teacher_id uuid references public.teachers (id) on delete set null,
  action text not null,
  target_type text not null,
  target_id text not null,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Helper functions
-- ---------------------------------------------------------------------------

-- security definer so RLS policies can call it without recursing into class_teachers' own policy.
create or replace function public.is_class_teacher(p_class_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.class_teachers
    where class_id = p_class_id and teacher_id = auth.uid()
  );
$$;

-- Checks a pupil's login card details and registers a device token.
-- Locks a pupil for 15 minutes after 5 wrong PINs, and a whole class after 30 failures in 15 minutes.
create or replace function public.pupil_join(
  p_class_code text,
  p_avatar_key text,
  p_pin text,
  p_token_hash text
)
returns table (
  status text,
  pupil_id uuid,
  display_name text,
  avatar_key text,
  year_group smallint,
  class_name text,
  class_code text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
#variable_conflict use_column
declare
  v_class public.classes;
  v_pupil public.pupils;
  v_pupil_found boolean;
begin
  select * into v_class from public.classes c
  where c.class_code = upper(p_class_code) and c.archived_at is null;
  if not found then
    return query select 'not_found'::text, null::uuid, null::text, null::text, null::smallint, null::text, null::text;
    return;
  end if;

  if v_class.join_failures_since is not null and v_class.join_failures_since < now() - interval '15 minutes' then
    update public.classes set join_failures = 0, join_failures_since = null where id = v_class.id;
    v_class.join_failures := 0;
  end if;
  if v_class.join_failures >= 30 then
    return query select 'locked'::text, null::uuid, null::text, null::text, null::smallint, null::text, null::text;
    return;
  end if;

  select * into v_pupil from public.pupils p
  where p.class_id = v_class.id and p.avatar_key = p_avatar_key;
  v_pupil_found := found;

  if v_pupil_found and v_pupil.locked_until is not null and v_pupil.locked_until > now() then
    return query select 'locked'::text, null::uuid, null::text, null::text, null::smallint, null::text, null::text;
    return;
  end if;

  if not v_pupil_found or v_pupil.pin_hash <> crypt(p_pin, v_pupil.pin_hash) then
    update public.classes
    set join_failures = join_failures + 1, join_failures_since = coalesce(join_failures_since, now())
    where id = v_class.id;
    if v_pupil_found then
      update public.pupils
      set failed_logins = failed_logins + 1,
          locked_until = case when failed_logins + 1 >= 5 then now() + interval '15 minutes' else null end
      where id = v_pupil.id;
    end if;
    return query select 'wrong_details'::text, null::uuid, null::text, null::text, null::smallint, null::text, null::text;
    return;
  end if;

  update public.pupils set failed_logins = 0, locked_until = null where id = v_pupil.id;
  insert into public.devices (pupil_id, token_hash, last_seen_at) values (v_pupil.id, p_token_hash, now());

  return query select 'ok'::text, v_pupil.id, v_pupil.display_name, v_pupil.avatar_key,
    v_class.year_group, v_class.name, v_class.class_code;
end;
$$;

create or replace function public.hash_pin(p_pin text)
returns text
language sql
volatile
set search_path = public, extensions
as $$
  select crypt(p_pin, gen_salt('bf', 8));
$$;

-- ---------------------------------------------------------------------------
-- Analytics (security invoker, so RLS limits results to the caller's classes)
-- ---------------------------------------------------------------------------

-- One row per pupil and objective. recent_* covers the pupil's last 10 attempts on that objective,
-- matching MasteryLevel in the iOS app and web/lib/mastery.ts.
create or replace function public.class_objective_stats(p_class_id uuid, p_from timestamptz, p_to timestamptz)
returns table (
  pupil_id uuid,
  objective_code text,
  attempts bigint,
  correct bigint,
  recent_attempts bigint,
  recent_correct bigint,
  last_answered_at timestamptz
)
language sql
stable
security invoker
set search_path = public
as $$
  with ranked as (
    select a.pupil_id, a.objective_code, a.correct, a.answered_at,
      row_number() over (partition by a.pupil_id, a.objective_code order by a.answered_at desc) as rn
    from public.attempts a
    where a.class_id = p_class_id and a.answered_at >= p_from and a.answered_at < p_to
  )
  select r.pupil_id, r.objective_code,
    count(*),
    count(*) filter (where r.correct),
    count(*) filter (where r.rn <= 10),
    count(*) filter (where r.rn <= 10 and r.correct),
    max(r.answered_at)
  from ranked r
  group by r.pupil_id, r.objective_code;
$$;

create or replace function public.class_question_stats(
  p_class_id uuid, p_objective_code text, p_from timestamptz, p_to timestamptz
)
returns table (question_id text, prompt text, attempts bigint, correct bigint, pupils bigint)
language sql
stable
security invoker
set search_path = public
as $$
  select a.question_id, q.prompt, count(*), count(*) filter (where a.correct), count(distinct a.pupil_id)
  from public.attempts a
  join public.questions q on q.id = a.question_id
  where a.class_id = p_class_id and a.objective_code = p_objective_code
    and a.answered_at >= p_from and a.answered_at < p_to
  group by a.question_id, q.prompt
  order by count(*) filter (where a.correct)::numeric / count(*) asc, count(*) desc;
$$;

-- Most common wrong answers: these point to misconceptions worth teaching to the whole class.
create or replace function public.class_misconceptions(
  p_class_id uuid, p_objective_code text, p_from timestamptz, p_to timestamptz, p_limit integer default 20
)
returns table (question_id text, prompt text, answer_given text, times bigint, pupils bigint)
language sql
stable
security invoker
set search_path = public
as $$
  select a.question_id, q.prompt, a.answer_given, count(*), count(distinct a.pupil_id)
  from public.attempts a
  join public.questions q on q.id = a.question_id
  where a.class_id = p_class_id and a.objective_code = p_objective_code and not a.correct
    and a.answer_given <> '' and a.answered_at >= p_from and a.answered_at < p_to
  group by a.question_id, q.prompt, a.answer_given
  order by count(distinct a.pupil_id) desc, count(*) desc
  limit p_limit;
$$;

create or replace function public.pupil_daily_stats(p_pupil_id uuid, p_from timestamptz, p_to timestamptz)
returns table (day date, attempts bigint, correct bigint)
language sql
stable
security invoker
set search_path = public
as $$
  select (a.answered_at at time zone 'Europe/London')::date, count(*), count(*) filter (where a.correct)
  from public.attempts a
  where a.pupil_id = p_pupil_id and a.answered_at >= p_from and a.answered_at < p_to
  group by 1
  order by 1;
$$;

create or replace function public.pupil_sessions(p_pupil_id uuid, p_limit integer default 20)
returns table (session_id uuid, session_kind text, started_at timestamptz, attempts bigint, correct bigint, strands text[])
language sql
stable
security invoker
set search_path = public
as $$
  select a.session_id, min(a.session_kind), min(a.answered_at), count(*), count(*) filter (where a.correct),
    array_agg(distinct a.strand)
  from public.attempts a
  where a.pupil_id = p_pupil_id
  group by a.session_id
  order by min(a.answered_at) desc
  limit p_limit;
$$;

-- A spelling word counts as mastered when the pupil's most recent attempt at it was correct.
create or replace function public.pupil_spelling_mastery(p_pupil_id uuid)
returns table (spelling_list_id text, words_attempted bigint, words_mastered bigint)
language sql
stable
security invoker
set search_path = public
as $$
  with latest as (
    select distinct on (a.question_id) a.question_id, a.correct
    from public.attempts a
    where a.pupil_id = p_pupil_id
    order by a.question_id, a.answered_at desc
  )
  select q.spelling_list_id, count(*), count(*) filter (where l.correct)
  from latest l
  join public.questions q on q.id = l.question_id
  where q.spelling_list_id is not null
  group by q.spelling_list_id;
$$;

create or replace function public.class_sats_stats(p_class_id uuid, p_from timestamptz, p_to timestamptz)
returns table (pupil_id uuid, strand text, attempts bigint, correct bigint)
language sql
stable
security invoker
set search_path = public
as $$
  select a.pupil_id, a.strand, count(*), count(*) filter (where a.correct)
  from public.attempts a
  join public.questions q on q.id = a.question_id
  where a.class_id = p_class_id and q.sats_style and a.answered_at >= p_from and a.answered_at < p_to
  group by a.pupil_id, a.strand;
$$;

create or replace function public.class_assignment_progress(p_class_id uuid)
returns table (assignment_id uuid, pupils_started bigint, attempts bigint, correct bigint)
language sql
stable
security invoker
set search_path = public
as $$
  select a.assignment_id, count(distinct a.pupil_id), count(*), count(*) filter (where a.correct)
  from public.attempts a
  where a.class_id = p_class_id and a.assignment_id is not null
  group by a.assignment_id;
$$;

-- ---------------------------------------------------------------------------
-- Retention (see docs/privacy/retention-policy.md)
-- ---------------------------------------------------------------------------

create or replace function public.purge_expired_data()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Classes archived for more than 12 months are deleted with all pupils and results.
  delete from public.classes where archived_at < now() - interval '12 months';
  -- Results older than 2 academic years are deleted even for active classes.
  delete from public.attempts where answered_at < now() - interval '24 months';
  -- Revoked or unused device tokens.
  delete from public.devices
  where revoked_at < now() - interval '30 days'
     or coalesce(last_seen_at, created_at) < now() - interval '12 months';
  delete from public.audit_log where created_at < now() - interval '24 months';
end;
$$;

do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    perform cron.schedule('spag-buddy-purge', '30 2 * * *', 'select public.purge_expired_data()');
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.schools enable row level security;
alter table public.teachers enable row level security;
alter table public.classes enable row level security;
alter table public.class_teachers enable row level security;
alter table public.pupils enable row level security;
alter table public.devices enable row level security;
alter table public.objectives enable row level security;
alter table public.spelling_lists enable row level security;
alter table public.questions enable row level security;
alter table public.assignments enable row level security;
alter table public.attempts enable row level security;
alter table public.audit_log enable row level security;

create policy "Teachers read their school" on public.schools
  for select to authenticated
  using (id in (select school_id from public.teachers where id = auth.uid()));

create policy "Teachers read themselves" on public.teachers
  for select to authenticated using (id = auth.uid());
create policy "Teachers update themselves" on public.teachers
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy "Teachers read their classes" on public.classes
  for select to authenticated using (public.is_class_teacher(id));
create policy "Teachers update their classes" on public.classes
  for update to authenticated using (public.is_class_teacher(id)) with check (public.is_class_teacher(id));

create policy "Teachers read class membership" on public.class_teachers
  for select to authenticated using (teacher_id = auth.uid() or public.is_class_teacher(class_id));

create policy "Teachers read their pupils" on public.pupils
  for select to authenticated using (public.is_class_teacher(class_id));
create policy "Teachers update their pupils" on public.pupils
  for update to authenticated using (public.is_class_teacher(class_id)) with check (public.is_class_teacher(class_id));
create policy "Teachers delete their pupils" on public.pupils
  for delete to authenticated using (public.is_class_teacher(class_id));

create policy "Content is readable" on public.objectives for select to authenticated using (true);
create policy "Spelling lists are readable" on public.spelling_lists for select to authenticated using (true);
create policy "Questions are readable" on public.questions for select to authenticated using (true);

create policy "Teachers read assignments" on public.assignments
  for select to authenticated using (public.is_class_teacher(class_id));
create policy "Teachers create assignments" on public.assignments
  for insert to authenticated with check (public.is_class_teacher(class_id) and created_by = auth.uid());
create policy "Teachers update assignments" on public.assignments
  for update to authenticated using (public.is_class_teacher(class_id)) with check (public.is_class_teacher(class_id));

create policy "Teachers read their pupils' attempts" on public.attempts
  for select to authenticated using (public.is_class_teacher(class_id));

-- devices and audit_log have no policies: only the service role (Edge Function) can use them.

-- Column-level protection: teachers never see PIN hashes or lockout counters through the API.
revoke select on public.pupils from authenticated;
grant select (id, class_id, display_name, avatar_key, created_at, locked_until) on public.pupils to authenticated;
revoke update on public.pupils from authenticated;
grant update (display_name) on public.pupils to authenticated;
revoke select on public.classes from authenticated;
grant select (id, school_id, name, year_group, class_code, archived_at, created_at) on public.classes to authenticated;
revoke update on public.classes from authenticated;
grant update (name, year_group, archived_at) on public.classes to authenticated;

revoke execute on function public.pupil_join(text, text, text, text) from public, anon, authenticated;
revoke execute on function public.purge_expired_data() from public, anon, authenticated;
