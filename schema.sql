-- ============================================================
-- Database voor het onderzoek islam & zingeving (Supabase / PostgreSQL)
-- Plak dit in Supabase > SQL Editor en klik op Run.
-- Veilig om opnieuw uit te voeren: bestaande data blijft staan.
-- ============================================================

-- Antwoorden (anoniem)
create table if not exists public.responses (
  id         uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  lang       text not null check (lang in ('nl', 'en')),
  answers    jsonb not null check (jsonb_typeof(answers) = 'object' and pg_column_size(answers) < 30000)
);
alter table public.responses add column if not exists survey text not null default 'converts';
alter table public.responses add column if not exists src    text not null default 'direct';
alter table public.responses drop constraint if exists responses_survey_check;
alter table public.responses add constraint responses_survey_check check (survey in ('converts', 'nonmuslims'));
alter table public.responses drop constraint if exists responses_src_check;
alter table public.responses add constraint responses_src_check check (src ~ '^[a-z0-9_-]{1,30}$');

-- E-mailadressen voor vervolginterviews (los van de antwoorden, alleen datum, geen tijd)
create table if not exists public.contacts (
  id         uuid primary key default gen_random_uuid(),
  created_on date not null default current_date,
  lang       text check (lang in ('nl', 'en')),
  email      text not null check (char_length(email) between 5 and 254 and email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);
alter table public.contacts add column if not exists survey text not null default 'converts';
alter table public.contacts drop constraint if exists contacts_survey_check;
alter table public.contacts add constraint contacts_survey_check check (survey in ('converts', 'nonmuslims'));

-- Vrijwilligers (NIET anoniem, staat volledig los van de onderzoeksantwoorden)
create table if not exists public.volunteers (
  id         uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  lang       text check (lang in ('nl', 'en')),
  src        text not null default 'direct' check (src ~ '^[a-z0-9_-]{1,30}$'),
  name       text not null check (char_length(name) between 1 and 120),
  email      text not null check (char_length(email) between 5 and 254 and email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  phone      text check (phone is null or char_length(phone) <= 40),
  share_ok   boolean not null default false,
  data       jsonb not null default '{}' check (jsonb_typeof(data) = 'object' and pg_column_size(data) < 30000),
  status     text not null default 'nieuw'   -- voor jezelf: nieuw / gesproken / actief / gestopt
);
alter table public.volunteers enable row level security;
drop policy if exists "anon insert volunteers" on public.volunteers;
create policy "anon insert volunteers" on public.volunteers for insert to anon with check (status = 'nieuw');
revoke all on public.volunteers from anon, authenticated;
grant insert (lang, src, name, email, phone, share_ok, data) on public.volunteers to anon;

-- Beveiliging: bezoekers mogen alleen toevoegen, nooit lezen, wijzigen of verwijderen.
alter table public.responses enable row level security;
alter table public.contacts  enable row level security;

drop policy if exists "anon insert responses" on public.responses;
create policy "anon insert responses" on public.responses for insert to anon with check (true);

drop policy if exists "anon insert contacts" on public.contacts;
create policy "anon insert contacts" on public.contacts for insert to anon with check (true);

revoke all on public.responses, public.contacts from anon, authenticated;
grant insert on public.responses, public.contacts to anon;

-- ============================================================
-- Analyse-query's (los uitvoeren in de SQL Editor)
-- ============================================================

-- Aantal reacties per vragenlijst, taal en kanaal (welke werving werkt?)
-- select survey, lang, src, count(*) from public.responses group by 1,2,3 order by 4 desc;

-- Alles in lang formaat (één regel per antwoord), voor export naar Excel
-- select r.id, r.survey, r.created_at, r.lang, r.src, a.key as vraag, a.value as antwoord
-- from public.responses r, jsonb_each(r.answers) a
-- order by r.created_at, a.key;

-- ---------- Bekeerlingen ----------
-- Wat hield hen tegen (q15)
-- select v as drempel, count(*) from public.responses, jsonb_array_elements_text(answers->'q15') v
-- where survey = 'converts' group by v order by 2 desc;

-- Wie bracht de boodschap het best over (q28) en via welk kanaal had het eerder gekund (q17)
-- select answers->>'q28' as boodschapper, count(*) from public.responses where survey='converts' and answers ? 'q28' group by 1 order by 2 desc;
-- select answers->>'q17' as kanaal, count(*) from public.responses where survey='converts' and answers ? 'q17' group by 1 order by 2 desc;

-- Bezwaren en wat ze wegnam (q27), en wat ze eerder hadden willen tegenkomen (q16)
-- select lang, answers->>'q27' as bezwaren, answers->>'q16' as eerder_willen from public.responses where survey='converts';

-- Gemiddelde score vóór vs. nu (q19)
-- select avg((answers->>'q19_family_before')::int) as familie_voor, avg((answers->>'q19_family_now')::int) as familie_nu,
--        avg((answers->>'q19_lonely_before')::int) as eenzaam_voor, avg((answers->>'q19_lonely_now')::int) as eenzaam_nu
-- from public.responses where survey='converts';

-- ---------- Niet-moslims ----------
-- Wat schrikt af (n13)
-- select v as afschrikker, count(*) from public.responses, jsonb_array_elements_text(answers->'n13') v
-- where survey = 'nonmuslims' group by v order by 2 desc;

-- Wat spreekt aan (n12)
-- select v as spreekt_aan, count(*) from public.responses, jsonb_array_elements_text(answers->'n12') v
-- where survey = 'nonmuslims' group by v order by 2 desc;

-- Voorkeurskanaal (n16) en vertrouwde boodschapper (n17), per levensbeschouwing (n4)
-- select answers->>'n4' as levensbeschouwing, answers->>'n16' as kanaal, answers->>'n17' as boodschapper, count(*)
-- from public.responses where survey='nonmuslims' group by 1,2,3 order by 4 desc;

-- Indruk (n7) naar persoonlijk contact met moslims (n5)
-- select answers->>'n5' as contact, round(avg((answers->>'n7')::int),2) as indruk, count(*)
-- from public.responses where survey='nonmuslims' and answers ? 'n7' group by 1 order by 2;

-- Alle open vragen die niet-moslims beantwoord willen zien (n14) en wat afschrikt in de toon (n18)
-- select lang, answers->>'n14' as vraag, answers->>'n18' as afschrikkende_toon from public.responses where survey='nonmuslims';

-- ---------- Vrijwilligers ----------
-- Overzicht: wie, welk beroep, hoeveel tijd
-- select created_at, name, email, data->>'v_profession' as beroep, data->>'v_sector' as sector,
--        data->>'v_hours' as tijd, data->>'v_mode' as waar, status
-- from public.volunteers order by created_at desc;

-- Wie heeft een bepaalde vaardigheid (bijv. design, video, it, translation, legal, coaching)
-- select name, email, data->>'v_profession' as beroep from public.volunteers where data->'v_skills' ? 'design';

-- Wie wil buddy/mentor zijn voor nieuwe moslims, en spreekt Turks
-- select name, email, data->>'v_city' as plaats from public.volunteers
-- where data->'v_roles' ? 'buddy' and data->'v_langs' ? 'tr';

-- Telling: welke vaardigheden zijn er in het netwerk, en wat ontbreekt
-- select v as vaardigheid, count(*) from public.volunteers, jsonb_array_elements_text(data->'v_skills') v group by v order by 2 desc;

-- Status bijwerken nadat je iemand hebt gesproken
-- update public.volunteers set status = 'gesproken' where email = 'naam@voorbeeld.nl';

-- Iemand verwijderen op verzoek (AVG)
-- delete from public.volunteers where email = 'naam@voorbeeld.nl';
