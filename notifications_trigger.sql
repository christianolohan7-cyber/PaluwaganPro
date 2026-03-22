create or replace function public.create_payment_proof_notification()
returns trigger
language plpgsql
security definer
as $$
begin
  if tg_op = 'INSERT' and new.status = 'pending' then
    insert into public.notifications (
      user_id,
      actor_user_id,
      group_id,
      payment_proof_id,
      contribution_id,
      round,
      type,
      title,
      message,
      is_read,
      read_at,
      metadata
    )
    values (
      new.recipient_id,
      new.sender_id,
      new.group_id,
      new.id,
      new.contribution_id,
      new.round,
      'payment_proof_submitted',
      'Payment Receipt Submitted',
      coalesce(new.sender_name, 'A member') || ' submitted a payment receipt for Round ' || new.round || ' and it is waiting for your verification.',
      false,
      null,
      jsonb_build_object(
        'sender_name', new.sender_name,
        'recipient_name', new.recipient_name,
        'transaction_no', new.transaction_no,
        'amount', new.amount,
        'status', new.status
      )
    )
    on conflict (user_id, payment_proof_id, type) where payment_proof_id is not null
    do update
    set actor_user_id = excluded.actor_user_id,
        group_id = excluded.group_id,
        contribution_id = excluded.contribution_id,
        round = excluded.round,
        title = excluded.title,
        message = excluded.message,
        metadata = excluded.metadata,
        is_read = false,
        read_at = null,
        created_at = timezone('utc', now());
  elsif tg_op = 'UPDATE' and old.status is distinct from new.status then
    if new.status = 'pending' then
      insert into public.notifications (
        user_id,
        actor_user_id,
        group_id,
        payment_proof_id,
        contribution_id,
        round,
        type,
        title,
        message,
        is_read,
        read_at,
        metadata
      )
      values (
        new.recipient_id,
        new.sender_id,
        new.group_id,
        new.id,
        new.contribution_id,
        new.round,
        'payment_proof_submitted',
        'Payment Receipt Resubmitted',
        coalesce(new.sender_name, 'A member') || ' resubmitted a payment receipt for Round ' || new.round || ' and it is waiting for your verification.',
        false,
        null,
        jsonb_build_object(
          'sender_name', new.sender_name,
          'recipient_name', new.recipient_name,
          'transaction_no', new.transaction_no,
          'amount', new.amount,
          'status', new.status
        )
      )
      on conflict (user_id, payment_proof_id, type) where payment_proof_id is not null
      do update
      set actor_user_id = excluded.actor_user_id,
          group_id = excluded.group_id,
          contribution_id = excluded.contribution_id,
          round = excluded.round,
          title = excluded.title,
          message = excluded.message,
          metadata = excluded.metadata,
          is_read = false,
          read_at = null,
          created_at = timezone('utc', now());
    elsif new.status = 'rejected' then
      insert into public.notifications (
        user_id,
        actor_user_id,
        group_id,
        payment_proof_id,
        contribution_id,
        round,
        type,
        title,
        message,
        is_read,
        read_at,
        metadata
      )
      values (
        new.sender_id,
        new.recipient_id,
        new.group_id,
        new.id,
        new.contribution_id,
        new.round,
        'payment_proof_rejected',
        'Payment Rejected',
        coalesce(new.recipient_name, 'The recipient') || ' rejected your payment for Round ' || new.round || '. Please review the reason and resubmit.',
        false,
        null,
        jsonb_build_object(
          'sender_name', new.sender_name,
          'recipient_name', new.recipient_name,
          'transaction_no', new.transaction_no,
          'amount', new.amount,
          'status', new.status,
          'rejection_reason', new.rejection_reason
        )
      )
      on conflict (user_id, payment_proof_id, type) where payment_proof_id is not null
      do update
      set actor_user_id = excluded.actor_user_id,
          group_id = excluded.group_id,
          contribution_id = excluded.contribution_id,
          round = excluded.round,
          title = excluded.title,
          message = excluded.message,
          metadata = excluded.metadata,
          is_read = false,
          read_at = null,
          created_at = timezone('utc', now());
    elsif new.status = 'verified' then
      insert into public.notifications (
        user_id,
        actor_user_id,
        group_id,
        payment_proof_id,
        contribution_id,
        round,
        type,
        title,
        message,
        is_read,
        read_at,
        metadata
      )
      values (
        new.sender_id,
        new.recipient_id,
        new.group_id,
        new.id,
        new.contribution_id,
        new.round,
        'payment_proof_verified',
        'Payment Verified',
        coalesce(new.recipient_name, 'The recipient') || ' verified your payment for Round ' || new.round || '.',
        false,
        null,
        jsonb_build_object(
          'sender_name', new.sender_name,
          'recipient_name', new.recipient_name,
          'transaction_no', new.transaction_no,
          'amount', new.amount,
          'status', new.status,
          'verified_at', new.verified_at,
          'verified_by_id', new.verified_by_id
        )
      )
      on conflict (user_id, payment_proof_id, type) where payment_proof_id is not null
      do update
      set actor_user_id = excluded.actor_user_id,
          group_id = excluded.group_id,
          contribution_id = excluded.contribution_id,
          round = excluded.round,
          title = excluded.title,
          message = excluded.message,
          metadata = excluded.metadata,
          is_read = false,
          read_at = null,
          created_at = timezone('utc', now());
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists tr_create_payment_proof_notification on public.payment_proofs;

create trigger tr_create_payment_proof_notification
after insert or update on public.payment_proofs
for each row
execute function public.create_payment_proof_notification();
