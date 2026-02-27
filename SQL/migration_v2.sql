-- =============================================================
-- Migration v2 — Groups, Recipes, Meal Plans, Todos
-- Run this in your Supabase project: SQL Editor → New query
-- Prerequisites: setup.sql must have been executed first
--                (shopping_list table already exists)
-- =============================================================

-- -----------------------------------------------
-- 1. groups — Household groups (couples, families)
-- -----------------------------------------------
create table if not exists public.groups (
    id          uuid        primary key default gen_random_uuid(),
    name        text        not null,
    invite_code text        unique not null default (substring(md5(random()::text) from 1 for 8)),
    created_by  uuid        not null references auth.users(id) on delete cascade,
    created_at  timestamptz not null default now()
);

alter table public.groups enable row level security;

-- NOTE: This permissive SELECT policy allows any authenticated user to look up
-- groups by invite_code (required for the join-by-code flow).  For a large-scale
-- deployment, replace with a Supabase RPC function that accepts an invite code
-- and returns only the matching group, then restrict SELECT to group members only.
create policy "Authenticated users can read groups"
    on public.groups for select
    to authenticated
    using (true);

-- Any authenticated user can create a group
create policy "Authenticated users can create groups"
    on public.groups for insert
    to authenticated
    with check (auth.uid() = created_by);

-- Only the group owner can update
create policy "Group owner can update"
    on public.groups for update
    to authenticated
    using (created_by = auth.uid());

-- Only the group owner can delete
create policy "Group owner can delete"
    on public.groups for delete
    to authenticated
    using (created_by = auth.uid());

-- -----------------------------------------------
-- 2. group_members — Link users to groups (M:N)
-- -----------------------------------------------
create table if not exists public.group_members (
    id        uuid        primary key default gen_random_uuid(),
    group_id  uuid        not null references public.groups(id) on delete cascade,
    user_id   uuid        not null references auth.users(id) on delete cascade,
    role      text        not null default 'member' check (role in ('owner', 'member')),
    joined_at timestamptz not null default now(),
    unique (group_id, user_id)
);

alter table public.group_members enable row level security;

-- Users can see members of groups they belong to
create policy "Members can read group members"
    on public.group_members for select
    to authenticated
    using (
        group_id in (select group_id from public.group_members where user_id = auth.uid())
    );

-- Users can join groups (insert themselves)
create policy "Users can join groups"
    on public.group_members for insert
    to authenticated
    with check (auth.uid() = user_id);

-- Users can remove themselves from a group
create policy "Users can leave groups"
    on public.group_members for delete
    to authenticated
    using (user_id = auth.uid());

-- Indexes
create index if not exists idx_group_members_group_id on public.group_members(group_id);
create index if not exists idx_group_members_user_id  on public.group_members(user_id);

-- -----------------------------------------------
-- 3. recipes — Recipe storage
-- -----------------------------------------------
create table if not exists public.recipes (
    id                 uuid        primary key default gen_random_uuid(),
    group_id           uuid        references public.groups(id) on delete cascade,
    created_by         uuid        not null references auth.users(id) on delete cascade,
    title              text        not null,
    description        text,
    servings           int,
    prep_time_minutes  int,
    cook_time_minutes  int,
    instructions       text,
    image_url          text,
    created_at         timestamptz not null default now(),
    updated_at         timestamptz not null default now()
);

alter table public.recipes enable row level security;

-- Users can read recipes belonging to their group or created by them
create policy "Users can read own or group recipes"
    on public.recipes for select
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select group_id from public.group_members where user_id = auth.uid())
    );

create policy "Users can insert recipes"
    on public.recipes for insert
    to authenticated
    with check (
        auth.uid() = created_by
        and (
            group_id is null
            or group_id in (select group_id from public.group_members where user_id = auth.uid())
        )
    );

create policy "Users can update own or group recipes"
    on public.recipes for update
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select group_id from public.group_members where user_id = auth.uid())
    );

create policy "Users can delete own or group recipes"
    on public.recipes for delete
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select group_id from public.group_members where user_id = auth.uid())
    );

-- Indexes
create index if not exists idx_recipes_group_id   on public.recipes(group_id);
create index if not exists idx_recipes_created_by  on public.recipes(created_by);

-- -----------------------------------------------
-- 4. recipe_ingredients
-- -----------------------------------------------
create table if not exists public.recipe_ingredients (
    id         uuid primary key default gen_random_uuid(),
    recipe_id  uuid not null references public.recipes(id) on delete cascade,
    name       text not null,
    quantity   text,
    unit       text,
    sort_order int  not null default 0
);

alter table public.recipe_ingredients enable row level security;

-- Access scoped through the parent recipe's ownership / group membership
create policy "Users can read recipe ingredients"
    on public.recipe_ingredients for select
    to authenticated
    using (
        recipe_id in (
            select r.id from public.recipes r
            where r.created_by = auth.uid()
               or r.group_id in (select gm.group_id from public.group_members gm where gm.user_id = auth.uid())
        )
    );

create policy "Users can insert recipe ingredients"
    on public.recipe_ingredients for insert
    to authenticated
    with check (
        recipe_id in (
            select r.id from public.recipes r
            where r.created_by = auth.uid()
               or r.group_id in (select gm.group_id from public.group_members gm where gm.user_id = auth.uid())
        )
    );

create policy "Users can update recipe ingredients"
    on public.recipe_ingredients for update
    to authenticated
    using (
        recipe_id in (
            select r.id from public.recipes r
            where r.created_by = auth.uid()
               or r.group_id in (select gm.group_id from public.group_members gm where gm.user_id = auth.uid())
        )
    );

create policy "Users can delete recipe ingredients"
    on public.recipe_ingredients for delete
    to authenticated
    using (
        recipe_id in (
            select r.id from public.recipes r
            where r.created_by = auth.uid()
               or r.group_id in (select gm.group_id from public.group_members gm where gm.user_id = auth.uid())
        )
    );

-- Indexes
create index if not exists idx_recipe_ingredients_recipe_id on public.recipe_ingredients(recipe_id);

-- -----------------------------------------------
-- 5. meal_plans — Weekly meal planning
-- -----------------------------------------------
create table if not exists public.meal_plans (
    id           uuid        primary key default gen_random_uuid(),
    group_id     uuid        references public.groups(id) on delete cascade,
    created_by   uuid        not null references auth.users(id) on delete cascade,
    recipe_id    uuid        references public.recipes(id) on delete set null,
    meal_date    date        not null,
    meal_type    text        not null check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack')),
    custom_title text,
    notes        text,
    created_at   timestamptz not null default now()
);

alter table public.meal_plans enable row level security;

create policy "Users can read own or group meal plans"
    on public.meal_plans for select
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select group_id from public.group_members where user_id = auth.uid())
    );

create policy "Users can insert meal plans"
    on public.meal_plans for insert
    to authenticated
    with check (
        auth.uid() = created_by
        and (
            group_id is null
            or group_id in (select group_id from public.group_members where user_id = auth.uid())
        )
    );

create policy "Users can update own or group meal plans"
    on public.meal_plans for update
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select group_id from public.group_members where user_id = auth.uid())
    );

create policy "Users can delete own or group meal plans"
    on public.meal_plans for delete
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select group_id from public.group_members where user_id = auth.uid())
    );

-- Indexes
create index if not exists idx_meal_plans_group_id   on public.meal_plans(group_id);
create index if not exists idx_meal_plans_created_by  on public.meal_plans(created_by);
create index if not exists idx_meal_plans_recipe_id   on public.meal_plans(recipe_id);
create index if not exists idx_meal_plans_meal_date   on public.meal_plans(meal_date);

-- -----------------------------------------------
-- 6. todos — General todo list
-- -----------------------------------------------
create table if not exists public.todos (
    id           uuid        primary key default gen_random_uuid(),
    group_id     uuid        references public.groups(id) on delete cascade,
    created_by   uuid        not null references auth.users(id) on delete cascade,
    title        text        not null,
    is_completed boolean     not null default false,
    priority     int         not null default 0 check (priority between 0 and 3),
    due_date     date,
    created_at   timestamptz not null default now()
);

alter table public.todos enable row level security;

create policy "Users can read own or group todos"
    on public.todos for select
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select group_id from public.group_members where user_id = auth.uid())
    );

create policy "Users can insert todos"
    on public.todos for insert
    to authenticated
    with check (
        auth.uid() = created_by
        and (
            group_id is null
            or group_id in (select group_id from public.group_members where user_id = auth.uid())
        )
    );

create policy "Users can update own or group todos"
    on public.todos for update
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select group_id from public.group_members where user_id = auth.uid())
    );

create policy "Users can delete own or group todos"
    on public.todos for delete
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select group_id from public.group_members where user_id = auth.uid())
    );

-- Indexes
create index if not exists idx_todos_group_id    on public.todos(group_id);
create index if not exists idx_todos_created_by   on public.todos(created_by);
create index if not exists idx_todos_due_date     on public.todos(due_date);
create index if not exists idx_todos_is_completed on public.todos(is_completed);

-- -----------------------------------------------
-- 7. Alter shopping_list — Add group_id column
-- -----------------------------------------------
alter table public.shopping_list
    add column if not exists group_id uuid references public.groups(id) on delete cascade;

create index if not exists idx_shopping_list_group_id on public.shopping_list(group_id);

-- Drop the old open-to-all policies and replace with group-scoped ones.
-- Use DROP … IF EXISTS so the migration is re-runnable.
drop policy if exists "Authenticated users can read"   on public.shopping_list;
drop policy if exists "Authenticated users can insert"  on public.shopping_list;
drop policy if exists "Authenticated users can update"  on public.shopping_list;
drop policy if exists "Authenticated users can delete"  on public.shopping_list;

create policy "Users can read own or group shopping items"
    on public.shopping_list for select
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select group_id from public.group_members where user_id = auth.uid())
    );

create policy "Users can insert shopping items"
    on public.shopping_list for insert
    to authenticated
    with check (
        auth.uid() = created_by
        and (
            group_id is null
            or group_id in (select group_id from public.group_members where user_id = auth.uid())
        )
    );

create policy "Users can update own or group shopping items"
    on public.shopping_list for update
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select group_id from public.group_members where user_id = auth.uid())
    );

create policy "Users can delete own or group shopping items"
    on public.shopping_list for delete
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select group_id from public.group_members where user_id = auth.uid())
    );
