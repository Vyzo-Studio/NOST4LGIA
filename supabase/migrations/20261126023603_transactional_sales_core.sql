alter table public.orders add column request_id uuid unique;
alter table public.order_items add column request_id uuid unique;
create unique index orders_one_unpaid_table on public.orders(table_session_id) where table_session_id is not null and status not in ('paid','cancelled');
create index order_items_product_idx on public.order_items(product_id);
create index orders_created_by_idx on public.orders(created_by);
create index cash_sessions_operator_idx on public.cash_sessions(operator_id);
create index table_sessions_opened_by_idx on public.table_sessions(opened_by);
create index payments_actor_idx on public.payments(actor_id);
create index inventory_movements_actor_idx on public.inventory_movements(actor_id);
create index customers_created_by_idx on public.customers(created_by);
create index order_items_created_by_idx on public.order_items(created_by);
create index cash_movements_actor_idx on public.cash_movements(actor_id);

create function nost_private.create_customer(p_name text,p_phone text,p_email text,p_street text,p_number text,p_neighborhood text,p_city text,p_state text,p_postal text,p_complement text)
returns uuid language plpgsql security definer set search_path='' as $$
declare v uuid;
begin
 if auth.uid() is null or not public.has_permission('customers.create') then raise exception 'Acesso negado' using errcode='42501'; end if;
 if p_name is null or length(trim(p_name)) not between 1 and 150 then raise exception 'Nome inválido'; end if;
 insert into public.customers(name,phone,email,created_by) values(trim(p_name),nullif(trim(p_phone),''),nullif(trim(p_email),''),auth.uid()) returning id into v;
 if nullif(trim(p_street),'') is not null then
 insert into public.customer_addresses(customer_id,street,number,neighborhood,city,state,postal_code,complement) values(v,trim(p_street),p_number,p_neighborhood,p_city,p_state,p_postal,p_complement);
 end if;
 insert into public.audit_events(actor_id,action,target_type,target_id) values(auth.uid(),'customers.create','customer',v::text);return v;
end;$$;
create function public.create_customer(p_name text,p_phone text default null,p_email text default null,p_street text default null,p_number text default null,p_neighborhood text default null,p_city text default null,p_state text default null,p_postal text default null,p_complement text default null)
returns uuid language sql security invoker set search_path='' as $$select nost_private.create_customer(p_name,p_phone,p_email,p_street,p_number,p_neighborhood,p_city,p_state,p_postal,p_complement);$$;

create function nost_private.create_order(p_channel text,p_table uuid,p_customer uuid,p_name text,p_fee bigint,p_request uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare v uuid;o public.orders%rowtype; t public.table_sessions%rowtype; v_name text;
begin
 if auth.uid() is null or not public.has_permission('orders.create') then raise exception 'Acesso negado' using errcode='42501';end if;
 if p_request is null or p_channel is null or p_channel not in ('mesa','balcao','retirada','delivery') or p_fee is null or p_fee<0 or p_fee>100000000 or (p_channel<>'delivery' and p_fee<>0) or (p_channel='mesa')<>(p_table is not null) then raise exception 'Pedido inválido';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_request::text,0));
 select * into o from public.orders where request_id=p_request;
 if found then
 if o.created_by<>auth.uid() or o.channel<>p_channel or o.table_session_id is distinct from p_table or o.customer_id is distinct from p_customer or o.delivery_fee_cents<>p_fee then raise exception 'Identificador já utilizado';end if;
 return o.id;end if;
 if p_table is not null then
 select * into t from public.table_sessions where id=p_table and closed_at is null for update;
 if not found then raise exception 'Mesa não está aberta';end if;
 end if;
 v_name:=nullif(trim(p_name),'');
 if p_customer is not null then select name into v_name from public.customers where id=p_customer;if not found then raise exception 'Cliente inválido';end if;end if;
 if p_channel='mesa' then v_name:=coalesce(v_name,t.customer_name);end if;
 insert into public.orders(channel,table_session_id,customer_id,customer_name,created_by,service_accepted,delivery_fee_cents,request_id)
 values(p_channel,p_table,p_customer,v_name,auth.uid(),p_channel='mesa',p_fee,p_request) returning id into v;
 insert into public.audit_events(actor_id,action,target_type,target_id,transaction_ref) values(auth.uid(),'orders.create','order',v::text,p_request);return v;
end;$$;
create function public.create_order(p_channel text,p_table uuid default null,p_customer uuid default null,p_name text default null,p_fee bigint default 0,p_request uuid default null)
returns uuid language sql security invoker set search_path='' as $$select nost_private.create_order(p_channel,p_table,p_customer,p_name,p_fee,p_request);$$;

create function nost_private.add_order_item(p_order uuid,p_product uuid,p_quantity int,p_notes text,p_request uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare v uuid;o public.orders%rowtype;p public.products%rowtype;i public.order_items%rowtype;
begin
 if auth.uid() is null or not public.has_permission('orders.update') then raise exception 'Acesso negado' using errcode='42501';end if;
 if p_request is null or p_quantity is null or p_quantity not between 1 and 100000 then raise exception 'Quantidade inválida';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_request::text,0));
 select * into i from public.order_items where request_id=p_request;
 if found then
 if i.order_id<>p_order or i.product_id<>p_product or i.quantity<>p_quantity or i.created_by<>auth.uid() or i.notes is distinct from nullif(trim(p_notes),'') then raise exception 'Identificador já utilizado';end if;
 return i.id;end if;
 select * into o from public.orders where id=p_order for update;
 if not found or o.status in ('paid','cancelled') or exists(select 1 from public.payments where order_id=p_order) then raise exception 'Pedido não pode ser alterado';end if;
 select * into p from public.products where id=p_product and active;
 if not found then raise exception 'Produto indisponível';end if;
 insert into public.order_items(order_id,product_id,product_name,quantity,unit_price_cents,service_eligible,notes,created_by,request_id)
 values(p_order,p_product,p.name,p_quantity,p.price_cents,p.service_eligible,nullif(trim(p_notes),''),auth.uid(),p_request) returning id into v;
 update public.orders set status='draft' where id=p_order;
 return v;
end;$$;
create function public.add_order_item(p_order uuid,p_product uuid,p_quantity int,p_notes text default null,p_request uuid default null)
returns uuid language sql security invoker set search_path='' as $$select nost_private.add_order_item(p_order,p_product,p_quantity,p_notes,p_request);$$;

create function nost_private.remove_draft_item(p_item uuid) returns void language plpgsql security definer set search_path='' as $$
declare o uuid;
begin
 if auth.uid() is null or not public.has_permission('orders.update') then raise exception 'Acesso negado' using errcode='42501';end if;
 select order_id into o from public.order_items where id=p_item;
 if not found then raise exception 'Item inválido';end if;
 perform 1 from public.orders where id=o and status not in ('paid','cancelled') for update;
 if not found or exists(select 1 from public.payments where order_id=o) then raise exception 'Pedido bloqueado';end if;
 delete from public.order_items where id=p_item and state='draft';
 if not found then raise exception 'Item confirmado exige autorização';end if;
end;$$;
create function public.remove_draft_item(p_item uuid) returns void language sql security invoker set search_path='' as $$select nost_private.remove_draft_item(p_item);$$;

create function nost_private.confirm_order(p_order uuid) returns void language plpgsql security definer set search_path='' as $$
declare o public.orders%rowtype;r record;
begin
 if auth.uid() is null or not public.has_permission('orders.update') then raise exception 'Acesso negado' using errcode='42501';end if;
 select * into o from public.orders where id=p_order for update;
 if not found or o.status in ('paid','cancelled') or exists(select 1 from public.payments where order_id=p_order) then raise exception 'Pedido bloqueado';end if;
 if not exists(select 1 from public.order_items where order_id=p_order and state<>'cancelled') then raise exception 'Pedido vazio';end if;
 for r in select product_id,sum(quantity) qty from public.order_items where order_id=p_order and state='draft' group by product_id order by product_id loop
 update public.inventory_balances set reserved=reserved+r.qty where product_id=r.product_id and physical-reserved>=r.qty;
 if not found then raise exception 'Estoque disponível insuficiente';end if;
 end loop;
 update public.order_items set state='reserved' where order_id=p_order and state='draft';
 update public.orders set status=case when exists(select 1 from public.order_items where order_id=p_order and state='reserved') then 'confirmed' else 'fulfilled' end where id=p_order;
 insert into public.audit_events(actor_id,action,target_type,target_id) values(auth.uid(),'orders.confirm','order',p_order::text);
end;$$;
create function public.confirm_order(p_order uuid) returns void language sql security invoker set search_path='' as $$select nost_private.confirm_order(p_order);$$;

create function nost_private.fulfill_order(p_order uuid) returns void language plpgsql security definer set search_path='' as $$
declare o public.orders%rowtype;r record;v_old numeric;v_new numeric;
begin
 if auth.uid() is null or not public.has_permission('orders.update') then raise exception 'Acesso negado' using errcode='42501';end if;
 select * into o from public.orders where id=p_order for update;
 if not found or o.status not in ('confirmed','fulfilled') then raise exception 'Confirme os itens primeiro';end if;
 if o.status='fulfilled' then return;end if;
 if exists(select 1 from public.order_items where order_id=p_order and state='draft') then raise exception 'Há itens não confirmados';end if;
 for r in select product_id,sum(quantity) qty from public.order_items where order_id=p_order and state='reserved' group by product_id order by product_id loop
 select physical into v_old from public.inventory_balances where product_id=r.product_id and reserved>=r.qty for update;
 if not found then raise exception 'Reserva de estoque inconsistente';end if;
 update public.inventory_balances set physical=physical-r.qty,reserved=reserved-r.qty where product_id=r.product_id returning physical into v_new;
 insert into public.inventory_movements(product_id,actor_id,kind,quantity_delta,previous_balance,new_balance,reason,request_id) values(r.product_id,auth.uid(),'sale',-r.qty,v_old,v_new,'Entrega do pedido '||o.number,gen_random_uuid());
 end loop;
 update public.order_items set state='fulfilled' where order_id=p_order and state='reserved';
 update public.orders set status='fulfilled' where id=p_order;
 insert into public.audit_events(actor_id,action,target_type,target_id) values(auth.uid(),'orders.fulfill','order',p_order::text);
end;$$;
create function public.fulfill_order(p_order uuid) returns void language sql security invoker set search_path='' as $$select nost_private.fulfill_order(p_order);$$;

create function public.order_summary(p_order uuid) returns jsonb language sql stable security invoker set search_path='' as $$
 select jsonb_build_object('subtotal',s.subtotal,'service',s.service,'delivery',o.delivery_fee_cents,'total',s.subtotal+s.service+o.delivery_fee_cents,'paid',coalesce((select sum(amount_cents) from public.payments where order_id=o.id),0),'status',o.status)
 from public.orders o cross join lateral (select coalesce(sum(i.quantity::numeric*i.unit_price_cents),0)::bigint subtotal,case when o.channel='mesa' and o.service_accepted then round(coalesce(sum(i.quantity::numeric*i.unit_price_cents) filter(where i.service_eligible),0)/10)::bigint else 0 end service from public.order_items i where i.order_id=o.id and i.state<>'cancelled') s where o.id=p_order;
$$;
create function nost_private.set_service_charge(p_order uuid,p_accepted boolean) returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or not public.has_permission('orders.update') then raise exception 'Acesso negado' using errcode='42501';end if;
 if p_accepted is null then raise exception 'Escolha inválida';end if;
 perform 1 from public.orders where id=p_order and channel='mesa' and status not in ('paid','cancelled') for update;
 if not found or exists(select 1 from public.payments where order_id=p_order) then raise exception 'Taxa bloqueada após pagamento';end if;
 update public.orders set service_accepted=p_accepted where id=p_order;
end;$$;
create function public.set_service_charge(p_order uuid,p_accepted boolean) returns void language sql security invoker set search_path='' as $$select nost_private.set_service_charge(p_order,p_accepted);$$;

create function nost_private.pay_order(p_order uuid,p_cash uuid,p_method text,p_received bigint,p_request uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare o public.orders%rowtype;s public.cash_sessions%rowtype;p public.payments%rowtype;v_sub bigint;v_service bigint;v_due bigint;v_paid bigint;v_apply bigint;v_change bigint;v_id uuid;
begin
 if auth.uid() is null or not public.has_permission('payments.create') then raise exception 'Acesso negado' using errcode='42501';end if;
 if p_request is null or p_method is null or p_method not in ('cash','pix','debit','credit') or p_received is null or p_received<=0 then raise exception 'Pagamento inválido';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_request::text,0));
 select * into p from public.payments where request_id=p_request;
 if found then
 if p.order_id<>p_order or p.cash_session_id<>p_cash or p.actor_id<>auth.uid() or p.method<>p_method or p.received_cents<>p_received then raise exception 'Identificador já utilizado';end if;
 return jsonb_build_object('id',p.id,'applied',p.amount_cents,'change',p.change_cents,'duplicate',true);end if;
 select * into o from public.orders where id=p_order for update;
 if not found or o.status<>'fulfilled' or not exists(select 1 from public.order_items where order_id=p_order and state='fulfilled') then raise exception 'Entregue todos os itens antes de receber';end if;
 select * into s from public.cash_sessions where id=p_cash for update;
 if not found or s.closed_at is not null or s.operator_id<>auth.uid() then raise exception 'Abra seu próprio caixa';end if;
 select coalesce(sum(quantity::numeric*unit_price_cents),0)::bigint,case when o.channel='mesa' and o.service_accepted then round(coalesce(sum(quantity::numeric*unit_price_cents) filter(where service_eligible),0)/10)::bigint else 0 end into v_sub,v_service from public.order_items where order_id=p_order and state='fulfilled';
 select coalesce(sum(amount_cents),0) into v_paid from public.payments where order_id=p_order;
 v_due:=v_sub+v_service+o.delivery_fee_cents-v_paid;
 if v_due<=0 then raise exception 'Não há saldo a receber';end if;
 if p_method<>'cash' and p_received>v_due then raise exception 'Pagamento eletrônico excede saldo';end if;
 v_apply:=least(p_received,v_due);v_change:=p_received-v_apply;
 insert into public.payments(order_id,cash_session_id,actor_id,method,amount_cents,received_cents,change_cents,request_id) values(p_order,p_cash,auth.uid(),p_method,v_apply,p_received,v_change,p_request) returning id into v_id;
 if v_apply=v_due then update public.orders set status='paid' where id=p_order;end if;
 insert into public.audit_events(actor_id,action,target_type,target_id,transaction_ref) values(auth.uid(),'payments.create','order',p_order::text,p_request);
 return jsonb_build_object('id',v_id,'applied',v_apply,'change',v_change,'remaining',v_due-v_apply,'duplicate',false);
end;$$;
create function public.pay_order(p_order uuid,p_cash uuid,p_method text,p_received bigint,p_request uuid)
returns jsonb language sql security invoker set search_path='' as $$select nost_private.pay_order(p_order,p_cash,p_method,p_received,p_request);$$;

create function nost_private.close_table(p_table uuid) returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or not public.has_permission('tables.close') then raise exception 'Acesso negado' using errcode='42501';end if;
 perform 1 from public.table_sessions where id=p_table and closed_at is null for update;
 if not found then raise exception 'Mesa já encerrada ou inválida';end if;
 if exists(select 1 from public.orders where table_session_id=p_table and status not in ('paid','cancelled')) then raise exception 'Existem pedidos em aberto';end if;
 update public.table_sessions set closed_at=now() where id=p_table;
 insert into public.audit_events(actor_id,action,target_type,target_id) values(auth.uid(),'tables.close','table_session',p_table::text);
end;$$;
create function public.close_table(p_table uuid) returns void language sql security invoker set search_path='' as $$select nost_private.close_table(p_table);$$;

create function nost_private.close_cash(p_cash uuid,p_counted bigint) returns jsonb language plpgsql security definer set search_path='' as $$
declare s public.cash_sessions%rowtype;v_expected bigint;v_receipts bigint;v_movements bigint;
begin
 if auth.uid() is null or not public.has_permission('cash.close') then raise exception 'Acesso negado' using errcode='42501';end if;
 if p_counted is null or p_counted<0 then raise exception 'Valor contado inválido';end if;
 select * into s from public.cash_sessions where id=p_cash for update;
 if not found or s.closed_at is not null or s.operator_id<>auth.uid() then raise exception 'Caixa indisponível';end if;
 select coalesce(sum(amount_cents),0) into v_receipts from public.payments where cash_session_id=p_cash and method='cash';
 select coalesce(sum(case when kind='addition' then amount_cents else -amount_cents end),0) into v_movements from public.cash_movements where cash_session_id=p_cash;
 v_expected:=s.opening_cents+v_receipts+v_movements;
 update public.cash_sessions set closed_at=now(),counted_cents=p_counted,expected_cents=v_expected where id=p_cash;
 insert into public.audit_events(actor_id,action,target_type,target_id) values(auth.uid(),'cash.close','cash_session',p_cash::text);
 return jsonb_build_object('expected',v_expected,'counted',p_counted,'difference',p_counted-v_expected);
end;$$;
create function public.close_cash(p_cash uuid,p_counted bigint) returns jsonb language sql security invoker set search_path='' as $$select nost_private.close_cash(p_cash,p_counted);$$;
revoke all on function public.create_customer(text,text,text,text,text,text,text,text,text,text) from public,anon,authenticated;
grant execute on function public.create_customer(text,text,text,text,text,text,text,text,text,text) to authenticated;
revoke all on function nost_private.create_customer(text,text,text,text,text,text,text,text,text,text) from public,anon,authenticated;
grant execute on function nost_private.create_customer(text,text,text,text,text,text,text,text,text,text) to authenticated;
revoke all on function public.create_order(text,uuid,uuid,text,bigint,uuid) from public,anon,authenticated;
grant execute on function public.create_order(text,uuid,uuid,text,bigint,uuid) to authenticated;
revoke all on function nost_private.create_order(text,uuid,uuid,text,bigint,uuid) from public,anon,authenticated;
grant execute on function nost_private.create_order(text,uuid,uuid,text,bigint,uuid) to authenticated;
revoke all on function public.add_order_item(uuid,uuid,int,text,uuid) from public,anon,authenticated;
grant execute on function public.add_order_item(uuid,uuid,int,text,uuid) to authenticated;
revoke all on function nost_private.add_order_item(uuid,uuid,int,text,uuid) from public,anon,authenticated;
grant execute on function nost_private.add_order_item(uuid,uuid,int,text,uuid) to authenticated;
revoke all on function public.remove_draft_item(uuid) from public,anon,authenticated;
grant execute on function public.remove_draft_item(uuid) to authenticated;
revoke all on function nost_private.remove_draft_item(uuid) from public,anon,authenticated;
grant execute on function nost_private.remove_draft_item(uuid) to authenticated;
revoke all on function public.confirm_order(uuid) from public,anon,authenticated;
grant execute on function public.confirm_order(uuid) to authenticated;
revoke all on function nost_private.confirm_order(uuid) from public,anon,authenticated;
grant execute on function nost_private.confirm_order(uuid) to authenticated;
revoke all on function public.fulfill_order(uuid) from public,anon,authenticated;
grant execute on function public.fulfill_order(uuid) to authenticated;
revoke all on function nost_private.fulfill_order(uuid) from public,anon,authenticated;
grant execute on function nost_private.fulfill_order(uuid) to authenticated;
revoke all on function public.set_service_charge(uuid,boolean) from public,anon,authenticated;
grant execute on function public.set_service_charge(uuid,boolean) to authenticated;
revoke all on function nost_private.set_service_charge(uuid,boolean) from public,anon,authenticated;
grant execute on function nost_private.set_service_charge(uuid,boolean) to authenticated;
revoke all on function public.pay_order(uuid,uuid,text,bigint,uuid) from public,anon,authenticated;
grant execute on function public.pay_order(uuid,uuid,text,bigint,uuid) to authenticated;
revoke all on function nost_private.pay_order(uuid,uuid,text,bigint,uuid) from public,anon,authenticated;
grant execute on function nost_private.pay_order(uuid,uuid,text,bigint,uuid) to authenticated;
revoke all on function public.close_table(uuid) from public,anon,authenticated;
grant execute on function public.close_table(uuid) to authenticated;
revoke all on function nost_private.close_table(uuid) from public,anon,authenticated;
grant execute on function nost_private.close_table(uuid) to authenticated;
revoke all on function public.close_cash(uuid,bigint) from public,anon,authenticated;
grant execute on function public.close_cash(uuid,bigint) to authenticated;
revoke all on function nost_private.close_cash(uuid,bigint) from public,anon,authenticated;
grant execute on function nost_private.close_cash(uuid,bigint) to authenticated;
revoke all on function public.order_summary(uuid) from public,anon,authenticated;
grant execute on function public.order_summary(uuid) to authenticated;
