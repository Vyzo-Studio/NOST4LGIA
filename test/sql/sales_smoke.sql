-- Integration smoke test. Run only in an empty development database.
-- Temporary fixtures rolled back on success and failure. PostgreSQL sequences can advance.
do $qa$
declare
  a uuid:=gen_random_uuid(); e uuid:=gen_random_uuid();
  pr uuid; tb uuid; ts uuid; cr uuid; cs uuid; ord uuid;
  request uuid:=gen_random_uuid(); payment_request uuid:=gen_random_uuid();
  r jsonb; n numeric; denied boolean;
begin
  if exists(select 1 from auth.users) or exists(select 1 from public.orders) or exists(select 1 from public.products) then
    raise exception 'QA requires empty development database';
  end if;
  begin
    insert into auth.users(id,email,role,aud) values(a,'qa-admin-'||a||'@example.invalid','authenticated','authenticated'),(e,'qa-employee-'||e||'@example.invalid','authenticated','authenticated');
    insert into public.profiles(id,full_name,role_id,active) select a,'QA admin',id,true from public.roles where code='admin';
    insert into public.profiles(id,full_name,role_id,active) select e,'QA employee',id,true from public.roles where code='employee';
    perform set_config('request.jwt.claim.sub',a::text,true);
    perform set_config('request.jwt.claims',jsonb_build_object('sub',a,'role','authenticated')::text,true);
    execute 'set local role authenticated';
    if not public.has_permission('products.create') then raise exception 'QA: admin permission';end if;
    pr:=public.create_product('QA product',1000,null,null,null,400,2);
    perform public.adjust_inventory(pr,10,'QA stock',gen_random_uuid());
    perform public.update_product(pr,'QA product edited',1000,null,null,null,2,true,true);
    perform public.create_packaging(pr,'QA pack',6);
    tb:=public.create_resource('table','QA table',4);
    cr:=public.create_resource('register','QA cash',null);
    perform set_config('request.jwt.claim.sub',e::text,true);
    perform set_config('request.jwt.claims',jsonb_build_object('sub',e,'role','authenticated')::text,true);
    denied:=false;
    begin perform public.adjust_inventory(pr,1,'QA forbidden',gen_random_uuid());exception when insufficient_privilege then denied:=true;end;
    if not denied then raise exception 'QA: employee inventory edit allowed';end if;
    denied:=false;
    begin update public.inventory_balances set physical=100 where product_id=pr;exception when insufficient_privilege then denied:=true;end;
    if not denied then raise exception 'QA: direct update allowed';end if;
    if exists(select 1 from public.product_costs where product_id=pr) then raise exception 'QA: cost leaked';end if;
    cs:=public.open_cash(cr,5000);
    ts:=public.open_table(tb,'QA customer',2);
    ord:=public.create_order('mesa',ts,null,'QA customer',0,request);
    if public.create_order('mesa',ts,null,'QA customer',0,request)<>ord then raise exception 'QA: order idempotency';end if;
    perform public.add_order_item(ord,pr,2,null,gen_random_uuid());
    perform public.confirm_order(ord);
    select reserved into n from public.inventory_balances where product_id=pr;
    if n<>2 then raise exception 'QA: wrong reservation';end if;
    perform public.confirm_order(ord);
    select reserved into n from public.inventory_balances where product_id=pr;
    if n<>2 then raise exception 'QA: duplicate reservation';end if;
    perform public.fulfill_order(ord);
    perform public.fulfill_order(ord);
    select physical into n from public.inventory_balances where product_id=pr;
    if n<>8 then raise exception 'QA: wrong stock deduction';end if;
    r:=public.order_summary(ord);
    if (r->>'total')::bigint<>2200 then raise exception 'QA: wrong service charge';end if;
    perform public.set_service_charge(ord,false);
    r:=public.order_summary(ord);
    if (r->>'total')::bigint<>2000 then raise exception 'QA: optional fee failed';end if;
    perform public.set_service_charge(ord,true);
    r:=public.pay_order(ord,cs,'pix',700,payment_request);
    if (r->>'remaining')::bigint<>1500 then raise exception 'QA: partial payment';end if;
    r:=public.pay_order(ord,cs,'pix',700,payment_request);
    if (r->>'duplicate')::boolean is not true then raise exception 'QA: payment idempotency';end if;
    r:=public.pay_order(ord,cs,'cash',2000,gen_random_uuid());
    if (r->>'change')::bigint<>500 or (r->>'remaining')::bigint<>0 then raise exception 'QA: change';end if;
    perform public.close_table(ts);
    r:=public.cash_summary(cs);
    if (r->>'expected')::bigint<>6500 or (r->>'pix')::bigint<>700 then raise exception 'QA: cash segregation';end if;
    r:=public.close_cash(cs,6500);
    if (r->>'difference')::bigint<>0 then raise exception 'QA: cash closing';end if;
    execute 'reset role';
    raise exception using errcode='ZX001',message='QA fixtures rollback';
  exception when sqlstate 'ZX001' then
    null;
  end;
end;
$qa$;
select 'PASS: SQL integration smoke test, temporary fixtures rolled back' as result;