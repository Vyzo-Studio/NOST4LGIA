create function nost_private.update_product(p_id uuid,p_name text,p_price bigint,p_category uuid,p_sku text,p_barcode text,p_min numeric,p_active boolean,p_service boolean)
returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or not public.has_permission('products.update') then raise exception 'Acesso negado' using errcode='42501';end if;
 update public.products set name=trim(p_name),price_cents=p_price,category_id=p_category,sku=nullif(trim(p_sku),''),barcode=nullif(trim(p_barcode),''),minimum_stock=p_min,active=p_active,service_eligible=p_service where id=p_id;
 if not found then raise exception 'Produto inexistente';end if;
 insert into public.audit_events(actor_id,action,target_type,target_id) values(auth.uid(),'products.update','product',p_id::text);
end;$$;
create function public.update_product(p_id uuid,p_name text,p_price bigint,p_category uuid,p_sku text,p_barcode text,p_min numeric,p_active boolean,p_service boolean) returns void language sql security invoker set search_path='' as $$select nost_private.update_product(p_id,p_name,p_price,p_category,p_sku,p_barcode,p_min,p_active,p_service);$$;

create function nost_private.create_packaging(p_product uuid,p_name text,p_units numeric) returns uuid language plpgsql security definer set search_path='' as $$
declare v uuid;
begin
 if auth.uid() is null or not public.has_permission('products.update') then raise exception 'Acesso negado' using errcode='42501';end if;
 if p_name is null or length(trim(p_name))=0 or p_units is null or p_units<=0 or p_units<>round(p_units,3) then raise exception 'Embalagem inválida';end if;
 insert into public.packaging_units(product_id,name,base_quantity) values(p_product,trim(p_name),p_units) returning id into v;
 insert into public.audit_events(actor_id,action,target_type,target_id) values(auth.uid(),'products.packaging','product',p_product::text);
 return v;
end;$$;
create function public.create_packaging(p_product uuid,p_name text,p_units numeric) returns uuid language sql security invoker set search_path='' as $$select nost_private.create_packaging(p_product,p_name,p_units);$$;

create function nost_private.cash_summary(p_cash uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare s public.cash_sessions%rowtype;v_cash bigint;v_pix bigint;v_debit bigint;v_credit bigint;v_add bigint;v_out bigint;
begin
 if auth.uid() is null then raise exception 'Acesso negado' using errcode='42501';end if;
 select * into s from public.cash_sessions where id=p_cash;
 if not found or not(public.has_permission('cash.view_all') or (s.operator_id=auth.uid() and public.has_permission('cash.view_own'))) then raise exception 'Acesso negado' using errcode='42501';end if;
 select coalesce(sum(amount_cents) filter(where method='cash'),0),coalesce(sum(amount_cents) filter(where method='pix'),0),coalesce(sum(amount_cents) filter(where method='debit'),0),coalesce(sum(amount_cents) filter(where method='credit'),0) into v_cash,v_pix,v_debit,v_credit from public.payments where cash_session_id=p_cash;
 select coalesce(sum(amount_cents) filter(where kind='addition'),0),coalesce(sum(amount_cents) filter(where kind in ('withdrawal','refund')),0) into v_add,v_out from public.cash_movements where cash_session_id=p_cash;
 return jsonb_build_object('opening',s.opening_cents,'cash',v_cash,'pix',v_pix,'debit',v_debit,'credit',v_credit,'additions',v_add,'withdrawals',v_out,'expected',s.opening_cents+v_cash+v_add-v_out,'counted',s.counted_cents,'closed_at',s.closed_at);
end;$$;
create function public.cash_summary(p_cash uuid) returns jsonb language sql stable security invoker set search_path='' as $$select nost_private.cash_summary(p_cash);$$;

create function nost_private.delivery_guard() returns trigger language plpgsql security invoker set search_path='' as $$
begin
 if new.channel='delivery' then raise exception 'Delivery indisponível até validação de elegibilidade e endereço';end if;
 return new;
end;$$;
revoke all on function nost_private.delivery_guard() from public,anon,authenticated;
create trigger orders_delivery_guard before insert or update of channel on public.orders for each row execute function nost_private.delivery_guard();

create function nost_private.sales_dashboard(p_start timestamptz,p_end timestamptz) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
 if auth.uid() is null or not public.has_permission('reports.financial') then raise exception 'Acesso negado' using errcode='42501';end if;
 if p_start is null or p_end is null or p_end<=p_start or p_end-p_start>interval '366 days' then raise exception 'Período inválido';end if;
 select jsonb_build_object('received',coalesce(sum(amount_cents),0),'cash',coalesce(sum(amount_cents) filter(where method='cash'),0),'pix',coalesce(sum(amount_cents) filter(where method='pix'),0),'debit',coalesce(sum(amount_cents) filter(where method='debit'),0),'credit',coalesce(sum(amount_cents) filter(where method='credit'),0),'paid_orders',(select count(*) from public.orders o where o.status='paid' and exists(select 1 from public.payments p where p.order_id=o.id and p.created_at>=p_start and p.created_at<p_end))) into result from public.payments where created_at>=p_start and created_at<p_end;
 return result;
end;$$;
create function public.sales_dashboard(p_start timestamptz,p_end timestamptz) returns jsonb language sql stable security invoker set search_path='' as $$select nost_private.sales_dashboard(p_start,p_end);$$;
revoke all on function public.update_product(uuid,text,bigint,uuid,text,text,numeric,boolean,boolean) from public,anon,authenticated;
grant execute on function public.update_product(uuid,text,bigint,uuid,text,text,numeric,boolean,boolean) to authenticated;
revoke all on function nost_private.update_product(uuid,text,bigint,uuid,text,text,numeric,boolean,boolean) from public,anon,authenticated;
grant execute on function nost_private.update_product(uuid,text,bigint,uuid,text,text,numeric,boolean,boolean) to authenticated;
revoke all on function public.create_packaging(uuid,text,numeric) from public,anon,authenticated;
grant execute on function public.create_packaging(uuid,text,numeric) to authenticated;
revoke all on function nost_private.create_packaging(uuid,text,numeric) from public,anon,authenticated;
grant execute on function nost_private.create_packaging(uuid,text,numeric) to authenticated;
revoke all on function public.cash_summary(uuid) from public,anon,authenticated;
grant execute on function public.cash_summary(uuid) to authenticated;
revoke all on function nost_private.cash_summary(uuid) from public,anon,authenticated;
grant execute on function nost_private.cash_summary(uuid) to authenticated;
revoke all on function public.sales_dashboard(timestamptz,timestamptz) from public,anon,authenticated;
grant execute on function public.sales_dashboard(timestamptz,timestamptz) to authenticated;
revoke all on function nost_private.sales_dashboard(timestamptz,timestamptz) from public,anon,authenticated;
grant execute on function nost_private.sales_dashboard(timestamptz,timestamptz) to authenticated;
