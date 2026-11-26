create function nost_private.order_summary(p_order uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
 if auth.uid() is null or not public.has_permission('orders.view') then raise exception 'Acesso negado' using errcode='42501';end if;
 select jsonb_build_object('subtotal',s.subtotal,'service',s.service,'delivery',o.delivery_fee_cents,'total',s.subtotal+s.service+o.delivery_fee_cents,'paid',coalesce((select sum(amount_cents) from public.payments where order_id=o.id),0),'status',o.status)
 into result from public.orders o cross join lateral (select coalesce(sum(i.quantity::numeric*i.unit_price_cents),0)::bigint subtotal,case when o.channel='mesa' and o.service_accepted then round(coalesce(sum(i.quantity::numeric*i.unit_price_cents) filter(where i.service_eligible),0)/10)::bigint else 0 end service from public.order_items i where i.order_id=o.id and i.state<>'cancelled') s where o.id=p_order;
 if result is null then raise exception 'Pedido inexistente';end if;
 return result;
end;$$;
create or replace function public.order_summary(p_order uuid) returns jsonb language sql stable security invoker set search_path='' as $$select nost_private.order_summary(p_order);$$;
revoke all on function nost_private.order_summary(uuid) from public,anon,authenticated;
grant execute on function nost_private.order_summary(uuid) to authenticated;

create function nost_private.cash_movement(p_cash uuid,p_kind text,p_amount bigint,p_reason text,p_request uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare s public.cash_sessions%rowtype;v public.cash_movements%rowtype;v_id uuid;v_available bigint;
begin
 if auth.uid() is null or not public.has_permission('cash.withdraw') then raise exception 'Autorização administrativa necessária' using errcode='42501';end if;
 if p_kind is null or p_kind not in ('addition','withdrawal') or p_amount is null or p_amount<=0 or p_reason is null or length(trim(p_reason))=0 or p_request is null then raise exception 'Dados inválidos';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_request::text,0));
 select * into v from public.cash_movements where request_id=p_request;
 if found then
 if v.cash_session_id<>p_cash or v.actor_id<>auth.uid() or v.kind<>p_kind or v.amount_cents<>p_amount or v.reason<>trim(p_reason) then raise exception 'Identificador já utilizado';end if;
 return v.id;end if;
 select * into s from public.cash_sessions where id=p_cash for update;
 if not found or s.closed_at is not null then raise exception 'Caixa fechado ou inexistente';end if;
 if s.operator_id<>auth.uid() and not public.has_permission('cash.view_all') then raise exception 'Caixa não autorizado';end if;
 select s.opening_cents+coalesce((select sum(amount_cents) from public.payments where cash_session_id=p_cash and method='cash'),0)+coalesce((select sum(case when kind='addition' then amount_cents else -amount_cents end) from public.cash_movements where cash_session_id=p_cash),0) into v_available;
 if p_kind='withdrawal' and p_amount>v_available then raise exception 'Saldo em dinheiro insuficiente';end if;
 insert into public.cash_movements(cash_session_id,actor_id,kind,amount_cents,reason,request_id) values(p_cash,auth.uid(),p_kind,p_amount,trim(p_reason),p_request) returning id into v_id;
 insert into public.audit_events(actor_id,action,target_type,target_id,reason,transaction_ref) values(auth.uid(),'cash.'||p_kind,'cash_session',p_cash::text,trim(p_reason),p_request);
 return v_id;
end;$$;
create function public.cash_movement(p_cash uuid,p_kind text,p_amount bigint,p_reason text,p_request uuid) returns uuid language sql security invoker set search_path='' as $$select nost_private.cash_movement(p_cash,p_kind,p_amount,p_reason,p_request);$$;
revoke all on function nost_private.cash_movement(uuid,text,bigint,text,uuid),public.cash_movement(uuid,text,bigint,text,uuid) from public,anon,authenticated;
grant execute on function nost_private.cash_movement(uuid,text,bigint,text,uuid),public.cash_movement(uuid,text,bigint,text,uuid) to authenticated;
