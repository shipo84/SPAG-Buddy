-- Integration checks for the schema, pupil_join and Row Level Security. Run by scripts/test-db.sh.
\set ON_ERROR_STOP on

insert into auth.users (id, email) values
  ('11111111-1111-4111-8111-111111111111', 'teacher.one@school.sch.uk'),
  ('22222222-2222-4222-8222-222222222222', 'teacher.two@school.sch.uk');
insert into public.schools (id, name) values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Oak Primary');
insert into public.teachers (id, school_id, display_name) values
  ('11111111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Ms One'),
  ('22222222-2222-4222-8222-222222222222', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Mr Two');
insert into public.classes (id, name, year_group, class_code) values
  ('c1111111-1111-4111-8111-111111111111', 'Year 4 Oak', 4, 'ELM4BZ'),
  ('c2222222-2222-4222-8222-222222222222', 'Year 6 Ash', 6, 'ASH6CD');
insert into public.class_teachers (class_id, teacher_id, role) values
  ('c1111111-1111-4111-8111-111111111111', '11111111-1111-4111-8111-111111111111', 'owner'),
  ('c2222222-2222-4222-8222-222222222222', '22222222-2222-4222-8222-222222222222', 'owner');
insert into public.pupils (id, class_id, display_name, avatar_key, pin_hash) values
  ('d1111111-1111-4111-8111-111111111111', 'c1111111-1111-4111-8111-111111111111', 'Amara', 'fox', public.hash_pin('4821')),
  ('d2222222-2222-4222-8222-222222222222', 'c1111111-1111-4111-8111-111111111111', 'Ben', 'cat', public.hash_pin('7302')),
  ('d3333333-3333-4333-8333-333333333333', 'c2222222-2222-4222-8222-222222222222', 'Cleo', 'owl', public.hash_pin('5190'));

-- pupil_join ---------------------------------------------------------------
do $$
declare
  v_status text;
begin
  select status into v_status from public.pupil_join('NOPE22', 'fox', '4821', 'h0');
  assert v_status = 'not_found', 'unknown class should be not_found, got ' || v_status;

  select status into v_status from public.pupil_join('elm4bz', 'fox', '0000', 'h1');
  assert v_status = 'wrong_details', 'wrong PIN should fail, got ' || v_status;

  select status into v_status from public.pupil_join('elm4bz', 'fox', '4821', 'h2');
  assert v_status = 'ok', 'correct details should join, got ' || v_status;
  assert (select count(*) from public.devices where token_hash = 'h2') = 1, 'device token should be stored';
  assert (select failed_logins from public.pupils where avatar_key = 'fox') = 0, 'successful login resets failures';

  for i in 1..5 loop
    perform public.pupil_join('ELM4BZ', 'cat', '1111', 'x' || i);
  end loop;
  select status into v_status from public.pupil_join('ELM4BZ', 'cat', '7302', 'h3');
  assert v_status = 'locked', 'pupil should be locked after 5 wrong PINs, got ' || v_status;
  assert (select count(*) from public.devices where token_hash = 'h3') = 0, 'locked pupil gets no device';
  raise notice 'pupil_join: ok';
end;
$$;

-- Content and attempts --------------------------------------------------------
insert into public.attempts (client_attempt_id, pupil_id, class_id, question_id, objective_code, strand, correct, answer_given, session_id, session_kind, answered_at)
select gen_random_uuid(), 'd1111111-1111-4111-8111-111111111111', 'c1111111-1111-4111-8111-111111111111',
  'y4-fa-01', 'Y4-G-fronted-adverbials', 'grammar', i % 3 <> 0, case when i % 3 = 0 then 'Sam fed the cat before breakfast.' else '' end,
  '99999999-9999-4999-8999-999999999999', 'daily', now() - (i || ' hours')::interval
from generate_series(1, 12) as i;

insert into public.attempts (client_attempt_id, pupil_id, class_id, question_id, objective_code, strand, correct, session_id, session_kind, answered_at)
values (gen_random_uuid(), 'd3333333-3333-4333-8333-333333333333', 'c2222222-2222-4222-8222-222222222222',
  'spell-y56-statutory-yacht', 'Y56-S-statutory-words', 'spelling', true, '99999999-9999-4999-8999-999999999998', 'spelling-list', now());

do $$
begin
  begin
    insert into public.attempts (client_attempt_id, pupil_id, class_id, question_id, objective_code, strand, correct, session_id, session_kind, answered_at)
    values (gen_random_uuid(), 'd1111111-1111-4111-8111-111111111111', 'c1111111-1111-4111-8111-111111111111',
      'not-a-question', 'Y4-G-fronted-adverbials', 'grammar', true, gen_random_uuid(), 'daily', now());
    raise exception 'unknown question should be rejected';
  exception when foreign_key_violation then
    null;
  end;
  raise notice 'constraints: ok';
end;
$$;

-- Row Level Security as teacher one -----------------------------------------------
set role authenticated;
select set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}', false);

do $$
declare
  v_count bigint;
begin
  select count(*) into v_count from public.classes;
  assert v_count = 1, 'teacher one should see 1 class, saw ' || v_count;

  select count(*) into v_count from public.pupils;
  assert v_count = 2, 'teacher one should see 2 pupils, saw ' || v_count;

  select count(*) into v_count from public.attempts;
  assert v_count = 12, 'teacher one should see only their class attempts, saw ' || v_count;

  select count(*) into v_count from public.class_objective_stats('c2222222-2222-4222-8222-222222222222', now() - interval '1 day', now() + interval '1 hour');
  assert v_count = 0, 'analytics for another class must be empty';

  select attempts into v_count from public.class_objective_stats('c1111111-1111-4111-8111-111111111111', now() - interval '1 day', now() + interval '1 hour');
  assert v_count = 12, 'analytics should count 12 attempts, got ' || v_count;

  select recent_attempts into v_count from public.class_objective_stats('c1111111-1111-4111-8111-111111111111', now() - interval '1 day', now() + interval '1 hour');
  assert v_count = 10, 'recent window should be 10, got ' || v_count;

  select count(*) into v_count from public.class_misconceptions('c1111111-1111-4111-8111-111111111111', 'Y4-G-fronted-adverbials', now() - interval '1 day', now() + interval '1 hour');
  assert v_count = 1, 'one common wrong answer expected, got ' || v_count;

  select count(*) into v_count from public.devices;
  assert v_count = 0, 'teachers must not read device tokens';

  update public.classes set name = 'Hijacked' where id = 'c2222222-2222-4222-8222-222222222222';
  assert (select count(*) from public.classes where name = 'Hijacked') = 0, 'cannot rename another teacher''s class';

  begin
    perform pin_hash from public.pupils limit 1;
    raise exception 'teachers must not read PIN hashes';
  exception when insufficient_privilege then
    null;
  end;

  begin
    insert into public.attempts (client_attempt_id, pupil_id, class_id, question_id, objective_code, strand, correct, session_id, session_kind, answered_at)
    values (gen_random_uuid(), 'd1111111-1111-4111-8111-111111111111', 'c1111111-1111-4111-8111-111111111111',
      'y4-fa-01', 'Y4-G-fronted-adverbials', 'grammar', true, gen_random_uuid(), 'daily', now());
    raise exception 'teachers must not insert attempts directly';
  exception when insufficient_privilege then
    null;
  end;

  begin
    perform public.pupil_join('ELM4BZ', 'fox', '4821', 'teacher-token');
    raise exception 'pupil_join must only be callable by the service role';
  exception when insufficient_privilege then
    null;
  end;

  insert into public.assignments (class_id, created_by, title, objective_codes)
  values ('c1111111-1111-4111-8111-111111111111', '11111111-1111-4111-8111-111111111111', 'Commas', '{Y4-P-comma-after-fronted-adverbial}');
  begin
    insert into public.assignments (class_id, created_by, title, objective_codes)
    values ('c2222222-2222-4222-8222-222222222222', '11111111-1111-4111-8111-111111111111', 'Sneaky', '{Y6-P-colons}');
    raise exception 'cannot set work for another teacher''s class';
  exception when insufficient_privilege then
    null;
  end;

  raise notice 'row level security: ok';
end;
$$;

reset role;

-- Deleting a pupil removes their results ----------------------------------------------------
delete from public.pupils where id = 'd1111111-1111-4111-8111-111111111111';
do $$
begin
  assert (select count(*) from public.attempts where pupil_id = 'd1111111-1111-4111-8111-111111111111') = 0, 'attempts should cascade';
  assert (select count(*) from public.devices where pupil_id = 'd1111111-1111-4111-8111-111111111111') = 0, 'devices should cascade';
end;
$$;

-- Retention: see docs/privacy/retention-policy.md -----------------------------------------------
insert into public.classes (id, name, year_group, class_code, archived_at) values
  ('c3333333-3333-4333-8333-333333333333', 'Left 13 months ago', 6, 'LFT6AA', now() - interval '13 months'),
  ('c4444444-4444-4444-8444-444444444444', 'Left 11 months ago', 6, 'LFT6BB', now() - interval '11 months');
insert into public.pupils (id, class_id, display_name, avatar_key, pin_hash) values
  ('d4444444-4444-4444-8444-444444444444', 'c3333333-3333-4333-8333-333333333333', 'Dev', 'fox', 'x'),
  ('d5555555-5555-4555-8555-555555555555', 'c4444444-4444-4444-8444-444444444444', 'Eve', 'fox', 'x');
insert into public.attempts (client_attempt_id, pupil_id, class_id, question_id, objective_code, strand, correct, session_id, session_kind, answered_at)
values
  ('e0000000-0000-4000-8000-000000000001', 'd4444444-4444-4444-8444-444444444444', 'c3333333-3333-4333-8333-333333333333',
    'y4-fa-01', 'Y4-G-fronted-adverbials', 'grammar', true, gen_random_uuid(), 'daily', now() - interval '14 months'),
  ('e0000000-0000-4000-8000-000000000002', 'd2222222-2222-4222-8222-222222222222', 'c1111111-1111-4111-8111-111111111111',
    'y4-fa-01', 'Y4-G-fronted-adverbials', 'grammar', true, gen_random_uuid(), 'daily', now() - interval '25 months'),
  ('e0000000-0000-4000-8000-000000000003', 'd2222222-2222-4222-8222-222222222222', 'c1111111-1111-4111-8111-111111111111',
    'y4-fa-01', 'Y4-G-fronted-adverbials', 'grammar', true, gen_random_uuid(), 'daily', now() - interval '23 months');
insert into public.devices (pupil_id, token_hash, created_at, last_seen_at, revoked_at) values
  ('d2222222-2222-4222-8222-222222222222', 'revoked-long-ago', now() - interval '60 days', null, now() - interval '31 days'),
  ('d2222222-2222-4222-8222-222222222222', 'revoked-recently', now() - interval '60 days', null, now() - interval '3 days'),
  ('d2222222-2222-4222-8222-222222222222', 'unused-for-a-year', now() - interval '400 days', now() - interval '13 months', null),
  ('d2222222-2222-4222-8222-222222222222', 'in-use', now() - interval '400 days', now() - interval '1 day', null);
insert into public.audit_log (teacher_id, action, target_type, target_id, created_at) values
  ('11111111-1111-4111-8111-111111111111', 'old', 'class', 'x', now() - interval '25 months'),
  ('11111111-1111-4111-8111-111111111111', 'recent', 'class', 'x', now() - interval '1 month');

do $$
begin
  perform public.purge_expired_data();
  assert not exists (select 1 from public.classes where id = 'c3333333-3333-4333-8333-333333333333'), 'class archived 13 months ago should be deleted';
  assert not exists (select 1 from public.pupils where id = 'd4444444-4444-4444-8444-444444444444'), 'its pupils should be deleted';
  assert not exists (select 1 from public.attempts where client_attempt_id = 'e0000000-0000-4000-8000-000000000001'), 'its answers should be deleted';
  assert exists (select 1 from public.classes where id = 'c4444444-4444-4444-8444-444444444444'), 'class archived 11 months ago should be kept';
  assert exists (select 1 from public.pupils where id = 'd5555555-5555-4555-8555-555555555555'), 'pupils in a recently archived class should be kept';

  assert not exists (select 1 from public.attempts where client_attempt_id = 'e0000000-0000-4000-8000-000000000002'), 'answers older than 24 months should be deleted';
  assert exists (select 1 from public.attempts where client_attempt_id = 'e0000000-0000-4000-8000-000000000003'), 'answers younger than 24 months should be kept';

  assert not exists (select 1 from public.devices where token_hash = 'revoked-long-ago'), 'devices revoked over 30 days ago should be deleted';
  assert exists (select 1 from public.devices where token_hash = 'revoked-recently'), 'recently revoked devices should be kept';
  assert not exists (select 1 from public.devices where token_hash = 'unused-for-a-year'), 'devices unused for 12 months should be deleted';
  assert exists (select 1 from public.devices where token_hash = 'in-use'), 'devices in use should be kept';

  assert not exists (select 1 from public.audit_log where action = 'old'), 'audit entries older than 24 months should be deleted';
  assert exists (select 1 from public.audit_log where action = 'recent'), 'recent audit entries should be kept';
  raise notice 'deletion and retention: ok';
end;
$$;
