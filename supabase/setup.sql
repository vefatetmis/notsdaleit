-- ============================================================
-- notsdaleit — Canlı Ortak Not sunucu kurulumu (Supabase)
-- Bu betiği Supabase Dashboard → SQL Editor'e yapıştırıp RUN'a basın.
-- Tekrar çalıştırmak güvenlidir (create or replace / if not exists).
-- ============================================================

-- 1) Tablolar ------------------------------------------------

create table if not exists public.shared_notes (
  id          uuid primary key default gen_random_uuid(),
  share_code  text unique not null,
  title       text not null default '',
  body        text not null default '',          -- Quill Delta JSON
  page_size   text not null default 'a4',
  page_color  text not null default 'beyaz',
  page_count  int  not null default 1,
  created_by  uuid not null references auth.users (id),
  updated_by  uuid,
  updated_at  timestamptz not null default now()
);

create table if not exists public.note_members (
  note_id   uuid not null references public.shared_notes (id) on delete cascade,
  user_id   uuid not null references auth.users (id),
  joined_at timestamptz not null default now(),
  primary key (note_id, user_id)
);

create table if not exists public.shared_strokes (
  id         uuid primary key,                    -- istemci üretir (yankı önleme)
  note_id    uuid not null references public.shared_notes (id) on delete cascade,
  page       int  not null default 0,
  tool       text not null default 'kalem',
  color      bigint not null default 4280558628,  -- 0xFF262626
  width      double precision not null default 5,
  points     text not null default '[]',          -- normalize JSON [[x,y],...]
  created_by uuid not null references auth.users (id),
  created_at timestamptz not null default now()
);

create index if not exists shared_strokes_note_idx
  on public.shared_strokes (note_id, created_at);

-- 2) updated_at tetikleyicisi --------------------------------

create or replace function public.tg_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists shared_notes_updated_at on public.shared_notes;
create trigger shared_notes_updated_at
  before update on public.shared_notes
  for each row execute function public.tg_set_updated_at();

-- 3) Üyelik denetimi (RLS'te döngüsüz kullanım için) ----------

create or replace function public.is_note_member(p_note uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from note_members
    where note_id = p_note and user_id = auth.uid()
  );
$$;

-- 4) Satır seviyesi güvenlik (RLS) ---------------------------
-- Varsayılan: her şey kapalı; yalnızca aşağıdaki izinler geçerli.

alter table public.shared_notes  enable row level security;
alter table public.note_members  enable row level security;
alter table public.shared_strokes enable row level security;

drop policy if exists shared_notes_select on public.shared_notes;
create policy shared_notes_select on public.shared_notes
  for select using (public.is_note_member(id));

drop policy if exists shared_notes_update on public.shared_notes;
create policy shared_notes_update on public.shared_notes
  for update using (public.is_note_member(id));

drop policy if exists shared_notes_delete on public.shared_notes;
create policy shared_notes_delete on public.shared_notes
  for delete using (created_by = auth.uid());

drop policy if exists note_members_select on public.note_members;
create policy note_members_select on public.note_members
  for select using (user_id = auth.uid() or public.is_note_member(note_id));

drop policy if exists note_members_delete on public.note_members;
create policy note_members_delete on public.note_members
  for delete using (user_id = auth.uid());

drop policy if exists shared_strokes_select on public.shared_strokes;
create policy shared_strokes_select on public.shared_strokes
  for select using (public.is_note_member(note_id));

drop policy if exists shared_strokes_insert on public.shared_strokes;
create policy shared_strokes_insert on public.shared_strokes
  for insert with check (
    public.is_note_member(note_id) and created_by = auth.uid()
  );

drop policy if exists shared_strokes_delete on public.shared_strokes;
create policy shared_strokes_delete on public.shared_strokes
  for delete using (public.is_note_member(note_id));

-- 5) RPC: not paylaş (kod üretir + sahibi üye yapar) ----------

create or replace function public.create_shared_note(
  p_title text,
  p_body text,
  p_page_size text,
  p_page_color text,
  p_page_count int
) returns public.shared_notes
language plpgsql security definer set search_path = public as $$
declare
  v_code text;
  v_note public.shared_notes;
  -- Karışan karakterler yok: I, L, O, 0, 1 dışlandı.
  v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
begin
  if auth.uid() is null then
    raise exception 'auth_required';
  end if;

  loop
    v_code := '';
    for i in 1..6 loop
      v_code := v_code ||
        substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from shared_notes where share_code = v_code);
  end loop;

  insert into shared_notes (share_code, title, body, page_size, page_color,
                            page_count, created_by, updated_by)
  values (v_code, coalesce(p_title, ''), coalesce(p_body, ''),
          coalesce(p_page_size, 'a4'), coalesce(p_page_color, 'beyaz'),
          coalesce(p_page_count, 1), auth.uid(), auth.uid())
  returning * into v_note;

  insert into note_members (note_id, user_id) values (v_note.id, auth.uid());
  return v_note;
end $$;

-- 6) RPC: koda katıl -----------------------------------------

create or replace function public.join_note(p_code text)
returns public.shared_notes
language plpgsql security definer set search_path = public as $$
declare
  v_note public.shared_notes;
begin
  if auth.uid() is null then
    raise exception 'auth_required';
  end if;

  select * into v_note
  from shared_notes
  where share_code = upper(trim(p_code));

  if not found then
    raise exception 'code_not_found';
  end if;

  insert into note_members (note_id, user_id)
  values (v_note.id, auth.uid())
  on conflict do nothing;

  return v_note;
end $$;

-- 7) Gerçek zamanlı yayın ------------------------------------
-- (Tablo zaten yayındaysa hata verir; o satırı atlayıp devam edin.)

alter publication supabase_realtime add table public.shared_notes;
alter publication supabase_realtime add table public.shared_strokes;
