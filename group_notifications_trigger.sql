create or replace function public.create_group_update_notifications()
returns trigger
language plpgsql
security definer
as $$
begin
  if tg_op = 'UPDATE' then
    if old.current_members is not null
       and new.current_members is not null
       and new.max_members is not null
       and old.current_members < new.max_members
       and new.current_members >= new.max_members
       and new.group_status = 'pending'
       and new.created_by is not null then
      insert into public.notifications (
        user_id,
        actor_user_id,
        group_id,
        round,
        type,
        title,
        message,
        is_read,
        read_at,
        metadata
      )
      select
        new.created_by,
        null,
        new.id,
        new.current_round,
        'group_ready_to_start',
        'Group Ready to Start',
        coalesce(new.name, 'Your group') || ' is now full and ready to start.',
        false,
        null,
        jsonb_build_object(
          'group_name', new.name,
          'current_members', new.current_members,
          'max_members', new.max_members,
          'status', new.status,
          'group_status', new.group_status
        )
      where not exists (
        select 1
        from public.notifications n
        where n.user_id = new.created_by
          and n.group_id = new.id
          and n.type = 'group_ready_to_start'
      );
    end if;

    if old.group_status is distinct from new.group_status
       and new.group_status = 'active' then
      insert into public.notifications (
        user_id,
        actor_user_id,
        group_id,
        round,
        type,
        title,
        message,
        is_read,
        read_at,
        metadata
      )
      select
        gm.user_id,
        null,
        new.id,
        new.current_round,
        'group_started',
        'Group Started',
        coalesce(new.name, 'Your group') || ' is now active.',
        false,
        null,
        jsonb_build_object(
          'group_name', new.name,
          'current_round', new.current_round,
          'current_members', new.current_members,
          'max_members', new.max_members,
          'status', new.status,
          'group_status', new.group_status
        )
      from public.group_members gm
      where gm.group_id = new.id
        and not exists (
          select 1
          from public.notifications n
          where n.user_id = gm.user_id
            and n.group_id = new.id
            and n.type = 'group_started'
        );
    end if;

    if old.current_round is not null
       and new.current_round is not null
       and new.current_round > old.current_round
       and old.current_round >= 1 then
      insert into public.notifications (
        user_id,
        actor_user_id,
        group_id,
        round,
        type,
        title,
        message,
        is_read,
        read_at,
        metadata
      )
      select
        gm.user_id,
        null,
        new.id,
        new.current_round,
        'round_advanced',
        'New Round Started',
        'Round ' || new.current_round || ' is now active in ' || coalesce(new.name, 'your group') || '.',
        false,
        null,
        jsonb_build_object(
          'group_name', new.name,
          'current_round', new.current_round,
          'previous_round', old.current_round,
          'status', new.status,
          'group_status', new.group_status
        )
      from public.group_members gm
      where gm.group_id = new.id
        and not exists (
          select 1
          from public.notifications n
          where n.user_id = gm.user_id
            and n.group_id = new.id
            and n.round = new.current_round
            and n.type = 'round_advanced'
        );
    end if;

    if old.status is distinct from new.status
       and new.status = 'completed' then
      insert into public.notifications (
        user_id,
        actor_user_id,
        group_id,
        round,
        type,
        title,
        message,
        is_read,
        read_at,
        metadata
      )
      select
        gm.user_id,
        null,
        new.id,
        new.current_round,
        'group_completed',
        'Group Completed',
        coalesce(new.name, 'Your group') || ' has completed all rounds.',
        false,
        null,
        jsonb_build_object(
          'group_name', new.name,
          'current_round', new.current_round,
          'status', new.status,
          'group_status', new.group_status
        )
      from public.group_members gm
      where gm.group_id = new.id
        and not exists (
          select 1
          from public.notifications n
          where n.user_id = gm.user_id
            and n.group_id = new.id
            and n.round is not distinct from new.current_round
            and n.type = 'group_completed'
        );
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists tr_create_group_update_notifications on public.groups;

create trigger tr_create_group_update_notifications
after update on public.groups
for each row
execute function public.create_group_update_notifications();
