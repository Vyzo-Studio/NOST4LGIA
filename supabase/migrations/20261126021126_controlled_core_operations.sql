create schema if not exists nost_private;
revoke all on schema nost_private from public,anon,authenticated;
grant usage on schema nost_private to authenticated;

create function nost_private.create_product(p_name text,p_price bigint,p_category uuid,p_sku text,p_barcode text,p_cost bigint,p_min numeric)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
 if auth.uid() is null or not public.has_permission('products.create') then raise exception 'Acesso negado' using errcode='42501';end if;
 if p_cost is null or p_min is null then raise exception 'Dados obrigatórios';end if;
 insert into public.products(name,price_cents,category_id,sku,barcode,minimum_stock)
 values(trim(p_name),p_price,p_category,nullif(trim(p_sku),''),nullif(trim(p_barcode),''),p_min) returning id into v_id;
 insert into public.product_costs values(v_id,p_cost);
 insert into public.inventory_balances(product_id) values(v_id);
 insert into public.audit_events(actor_id,action,target_type,target_id) values(auth.uid(),'products.create','product',v_id::text);
 return v_id;
end;$$;
create function public.create_product(p_name text,p_price bigint,p_category uuid default null,p_sku text default null,p_barcode text default null,p_cost bigint default 0,p_min numeric default 0)
returns uuid language sql security invoker set search_path='' as $$select nost_private.create_product(p_name,p_price,p_category,p_sku,p_barcode,p_cost,p_min);$$;

create function nost_private.adjust_inventory(p_product uuid,p_delta numeric,p_reason text,p_request uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_old numeric;v_reserved numeric;v_id uuid;v_existing public.inventory_movements%rowtype;
begin
 if auth.uid() is null or p_delta is null or p_delta=0 or p_delta<>round(p_delta,3) or p_request is null then raise exception 'Dados inválidos';end if;
 if not public.has_permission(case when p_delta>0 then 'inventory.receive' else 'inventory.withdraw' end) then raise exception 'Acesso negado' using errcode='42501';end if;
 if p_reason is null or length(trim(p_reason))=0 then raise exception 'Motivo obrigatório';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_request::text,0));
 select * into v_existing from public.inventory_movements where request_id=p_request;
 if found then
 if v_existing.actor_id<>auth.uid() or v_existing.product_id<>p_product or v_existing.quantity_delta<>p_delta or v_existing.reason<>trim(p_reason) then raise exception 'Identificador de operação já utilizado';end if;
 return v_existing.id;end if;
 select physical,reserved into v_old,v_reserved from public.inventory_balances where product_id=p_product for update;
 if not found or v_old+p_delta<v_reserved then raise exception 'Estoque insuficiente ou produto inválido';end if;
 update public.inventory_balances set physical=v_old+p_delta where product_id=p_product;
 insert into public.inventory_movements(product_id,actor_id,kind,quantity_delta,previous_balance,new_balance,reason,request_id)
 values(p_product,auth.uid(),case when p_delta>0 then 'receipt' else 'withdrawal' end,p_delta,v_old,v_old+p_delta,trim(p_reason),p_request) returning id into v_id;
 insert into public.audit_events(actor_id,action,target_type,target_id,reason,transaction_ref) values(auth.uid(),'inventory.adjust','product',p_product::text,trim(p_reason),p_request);
 return v_id;
end;$$;
create function public.adjust_inventory(p_product uuid,p_delta numeric,p_reason text,p_request uuid)
returns uuid language sql security invoker set search_path='' as $$select nost_private.adjust_inventory(p_product,p_delta,p_reason,p_request);$$;

create function nost_private.open_table(p_table uuid,p_name text,p_guests int)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
 if auth.uid() is null or not public.has_permission('tables.open') then raise exception 'Acesso negado' using errcode='42501';end if;
 perform 1 from public.tables where id=p_table and active for update;
 if not found then raise exception 'Mesa indisponível';end if;
 insert into public.table_sessions(table_id,opened_by,customer_name,guest_count) values(p_table,auth.uid(),nullif(trim(p_name),''),p_guests) returning id into v_id;
 insert into public.audit_events(actor_id,action,target_type,target_id) values(auth.uid(),'tables.open','table_session',v_id::text);
 return v_id;
end;$$;
create function public.open_table(p_table uuid,p_name text default null,p_guests int default 1)
returns uuid language sql security invoker set search_path='' as $$select nost_private.open_table(p_table,p_name,p_guests);$$;

create function nost_private.open_cash(p_register uuid,p_opening bigint)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
 if auth.uid() is null or not public.has_permission('cash.open') then raise exception 'Acesso negado' using errcode='42501';end if;
 perform 1 from public.cash_registers where id=p_register and active for update;
 if not found then raise exception 'Caixa indisponível';end if;
 insert into public.cash_sessions(register_id,operator_id,opening_cents) values(p_register,auth.uid(),p_opening) returning id into v_id;
 insert into public.audit_events(actor_id,action,target_type,target_id) values(auth.uid(),'cash.open','cash_session',v_id::text);
 return v_id;
end;$$;
create function public.open_cash(p_register uuid,p_opening bigint)
returns uuid language sql security invoker set search_path='' as $$select nost_private.open_cash(p_register,p_opening);$$;

create function nost_private.create_resource(p_kind text,p_name text,p_capacity int)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
 if auth.uid() is null or not public.has_permission('settings.manage') then raise exception 'Acesso negado' using errcode='42501';end if;
 if p_name is null or length(trim(p_name))=0 then raise exception 'Nome obrigatório';end if;
 case p_kind
 when 'table' then insert into public.tables(name,capacity) values(trim(p_name),p_capacity) returning id into v_id;
 when 'register' then insert into public.cash_registers(name) values(trim(p_name)) returning id into v_id;
 when 'category' then insert into public.categories(name) values(trim(p_name)) returning id into v_id;
 else raise exception 'Tipo inválido';end case;
 insert into public.audit_events(actor_id,action,target_type,target_id) values(auth.uid(),'settings.create',p_kind,v_id::text);
 return v_id;
end;$$;
create function public.create_resource(p_kind text,p_name text,p_capacity int default null)
returns uuid language sql security invoker set search_path='' as $$select nost_private.create_resource(p_kind,p_name,p_capacity);$$;
revoke all on function public.create_product(text,bigint,uuid,text,text,bigint,numeric) from public,anon,authenticated;
grant execute on function public.create_product(text,bigint,uuid,text,text,bigint,numeric) to authenticated;
revoke all on function nost_private.create_product(text,bigint,uuid,text,text,bigint,numeric) from public,anon,authenticated;
grant execute on function nost_private.create_product(text,bigint,uuid,text,text,bigint,numeric) to authenticated;
revoke all on function public.adjust_inventory(uuid,numeric,text,uuid) from public,anon,authenticated;
grant execute on function public.adjust_inventory(uuid,numeric,text,uuid) to authenticated;
revoke all on function nost_private.adjust_inventory(uuid,numeric,text,uuid) from public,anon,authenticated;
grant execute on function nost_private.adjust_inventory(uuid,numeric,text,uuid) to authenticated;
revoke all on function public.open_table(uuid,text,int) from public,anon,authenticated;
grant execute on function public.open_table(uuid,text,int) to authenticated;
revoke all on function nost_private.open_table(uuid,text,int) from public,anon,authenticated;
grant execute on function nost_private.open_table(uuid,text,int) to authenticated;
revoke all on function public.open_cash(uuid,bigint) from public,anon,authenticated;
grant execute on function public.open_cash(uuid,bigint) to authenticated;
revoke all on function nost_private.open_cash(uuid,bigint) from public,anon,authenticated;
grant execute on function nost_private.open_cash(uuid,bigint) to authenticated;
revoke all on function public.create_resource(text,text,int) from public,anon,authenticated;
grant execute on function public.create_resource(text,text,int) to authenticated;
revoke all on function nost_private.create_resource(text,text,int) from public,anon,authenticated;
grant execute on function nost_private.create_resource(text,text,int) to authenticated;
