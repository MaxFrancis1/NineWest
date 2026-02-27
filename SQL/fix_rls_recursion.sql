-- =============================================================
-- fix_rls_recursion.sql
-- Fixes: "infinite recursion detected in policy for relation group_members"
--
-- Root cause: the group_members SELECT policy subqueries group_members
-- itself, which re-evaluates the policy on every row → infinite loop.
-- The same recursion fires from every other table whose policies also
-- subquery group_members.
--
-- Fix: a SECURITY DEFINER function reads group_members as the table
-- owner (no RLS evaluation). All policies swap in this function.
--
-- Run this in Supabase: SQL Editor → New query → Run
-- Safe to re-run (uses CREATE OR REPLACE / DROP IF EXISTS).
-- =============================================================

-- -----------------------------------------------
-- Step 1: Helper function — bypasses RLS entirely
-- -----------------------------------------------
create or replace function public.get_my_group_ids()
returns setof uuid
language sql
security definer   -- runs as table owner, no RLS
stable
set search_path = public
as $$
    select group_id
    from   public.group_members
    where  user_id = auth.uid();
$$;

-- -----------------------------------------------
-- Step 2: group_members — fix the self-referencing policy
-- -----------------------------------------------
drop policy if exists "Members can read group members" on public.group_members;

create policy "Members can read group members"
    on public.group_members for select
    to authenticated
    using (
        group_id in (select public.get_my_group_ids())
    );

-- -----------------------------------------------
-- Step 3: recipes
-- -----------------------------------------------
drop policy if exists "Users can read own or group recipes"   on public.recipes;
drop policy if exists "Users can insert recipes"              on public.recipes;
drop policy if exists "Users can update own or group recipes" on public.recipes;
drop policy if exists "Users can delete own or group recipes" on public.recipes;

create policy "Users can read own or group recipes"
    on public.recipes for select
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select public.get_my_group_ids())
    );

create policy "Users can insert recipes"
    on public.recipes for insert
    to authenticated
    with check (
        auth.uid() = created_by
        and (
            group_id is null
            or group_id in (select public.get_my_group_ids())
        )
    );

create policy "Users can update own or group recipes"
    on public.recipes for update
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select public.get_my_group_ids())
    );

create policy "Users can delete own or group recipes"
    on public.recipes for delete
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select public.get_my_group_ids())
    );

-- -----------------------------------------------
-- Step 4: recipe_ingredients
-- -----------------------------------------------
drop policy if exists "Users can read recipe ingredients"   on public.recipe_ingredients;
drop policy if exists "Users can insert recipe ingredients" on public.recipe_ingredients;
drop policy if exists "Users can update recipe ingredients" on public.recipe_ingredients;
drop policy if exists "Users can delete recipe ingredients" on public.recipe_ingredients;

create policy "Users can read recipe ingredients"
    on public.recipe_ingredients for select
    to authenticated
    using (
        recipe_id in (
            select r.id from public.recipes r
            where  r.created_by = auth.uid()
            or     r.group_id   in (select public.get_my_group_ids())
        )
    );

create policy "Users can insert recipe ingredients"
    on public.recipe_ingredients for insert
    to authenticated
    with check (
        recipe_id in (
            select r.id from public.recipes r
            where  r.created_by = auth.uid()
            or     r.group_id   in (select public.get_my_group_ids())
        )
    );

create policy "Users can update recipe ingredients"
    on public.recipe_ingredients for update
    to authenticated
    using (
        recipe_id in (
            select r.id from public.recipes r
            where  r.created_by = auth.uid()
            or     r.group_id   in (select public.get_my_group_ids())
        )
    );

create policy "Users can delete recipe ingredients"
    on public.recipe_ingredients for delete
    to authenticated
    using (
        recipe_id in (
            select r.id from public.recipes r
            where  r.created_by = auth.uid()
            or     r.group_id   in (select public.get_my_group_ids())
        )
    );

-- -----------------------------------------------
-- Step 5: meal_plans
-- -----------------------------------------------
drop policy if exists "Users can read own or group meal plans"   on public.meal_plans;
drop policy if exists "Users can insert meal plans"              on public.meal_plans;
drop policy if exists "Users can update own or group meal plans" on public.meal_plans;
drop policy if exists "Users can delete own or group meal plans" on public.meal_plans;

create policy "Users can read own or group meal plans"
    on public.meal_plans for select
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select public.get_my_group_ids())
    );

create policy "Users can insert meal plans"
    on public.meal_plans for insert
    to authenticated
    with check (
        auth.uid() = created_by
        and (
            group_id is null
            or group_id in (select public.get_my_group_ids())
        )
    );

create policy "Users can update own or group meal plans"
    on public.meal_plans for update
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select public.get_my_group_ids())
    );

create policy "Users can delete own or group meal plans"
    on public.meal_plans for delete
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select public.get_my_group_ids())
    );

-- -----------------------------------------------
-- Step 6: todos
-- -----------------------------------------------
drop policy if exists "Users can read own or group todos"   on public.todos;
drop policy if exists "Users can insert todos"              on public.todos;
drop policy if exists "Users can update own or group todos" on public.todos;
drop policy if exists "Users can delete own or group todos" on public.todos;

create policy "Users can read own or group todos"
    on public.todos for select
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select public.get_my_group_ids())
    );

create policy "Users can insert todos"
    on public.todos for insert
    to authenticated
    with check (
        auth.uid() = created_by
        and (
            group_id is null
            or group_id in (select public.get_my_group_ids())
        )
    );

create policy "Users can update own or group todos"
    on public.todos for update
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select public.get_my_group_ids())
    );

create policy "Users can delete own or group todos"
    on public.todos for delete
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select public.get_my_group_ids())
    );

-- -----------------------------------------------
-- Step 7: shopping_list
-- -----------------------------------------------
drop policy if exists "Users can read own or group shopping items"   on public.shopping_list;
drop policy if exists "Users can insert shopping items"              on public.shopping_list;
drop policy if exists "Users can update own or group shopping items" on public.shopping_list;
drop policy if exists "Users can delete own or group shopping items" on public.shopping_list;

create policy "Users can read own or group shopping items"
    on public.shopping_list for select
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select public.get_my_group_ids())
    );

create policy "Users can insert shopping items"
    on public.shopping_list for insert
    to authenticated
    with check (
        auth.uid() = created_by
        and (
            group_id is null
            or group_id in (select public.get_my_group_ids())
        )
    );

create policy "Users can update own or group shopping items"
    on public.shopping_list for update
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select public.get_my_group_ids())
    );

create policy "Users can delete own or group shopping items"
    on public.shopping_list for delete
    to authenticated
    using (
        created_by = auth.uid()
        or group_id in (select public.get_my_group_ids())
    );
