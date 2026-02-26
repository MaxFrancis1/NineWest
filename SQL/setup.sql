-- =============================================================
-- Run this in your Supabase project: SQL Editor → New query
-- =============================================================

-- Shopping list (shared between all authenticated users)
create table if not exists public.shopping_list (
    id          uuid        primary key default gen_random_uuid(),
    created_by  uuid        not null references auth.users (id) on delete cascade,
    name        text        not null,
    quantity    text,
    is_checked  boolean     not null default false,
    created_at  timestamptz not null default now()
);

-- Enable Row Level Security
alter table public.shopping_list enable row level security;

-- Any signed-in user can read every item (shared couple list)
create policy "Authenticated users can read"
    on public.shopping_list for select
    to authenticated
    using (true);

-- Any signed-in user can add items
create policy "Authenticated users can insert"
    on public.shopping_list for insert
    to authenticated
    with check (auth.uid() = created_by);

-- Any signed-in user can update any item (check things off together)
create policy "Authenticated users can update"
    on public.shopping_list for update
    to authenticated
    using (true);

-- Any signed-in user can delete any item
create policy "Authenticated users can delete"
    on public.shopping_list for delete
    to authenticated
    using (true);
