create table public.roles (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^[a-z][a-z0-9_]*$'),
  name text not null,
  system_role boolean not null default false,
  created_at timestamptz not null default now()
);
create table public.permissions (
  code text primary key,
  description text not null
);
create table public.role_permissions (
  role_id uuid not null references public.roles(id),
  permission_code text not null references public.permissions(code),
  mode text not null check (mode in ('allowed','denied','approval')),
  primary key (role_id, permission_code)
);
create table public.profiles (
  id uuid primary key references auth.users(id) on delete restrict,
  full_name text not null check (length(trim(full_name)) between 1 and 150),
  role_id uuid not null references public.roles(id),
  active boolean not null default false,
  created_at timestamptz not null default now()
);
create index profiles_role_id_idx on public.profiles(role_id);
create index role_permissions_permission_code_idx on public.role_permissions(permission_code);
create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id),
  approving_actor_id uuid references public.profiles(id),
  action text not null,
  target_type text not null,
  target_id text,
  reason text,
  event_at timestamptz not null default now(),
  transaction_ref uuid,
  check (length(action)>0 and length(target_type)>0)
);
create index audit_events_actor_idx on public.audit_events(actor_id);
create index audit_events_approver_idx on public.audit_events(approving_actor_id);
create index audit_events_event_at_idx on public.audit_events(event_at desc);

alter table public.roles enable row level security;
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.profiles enable row level security;
alter table public.audit_events enable row level security;
revoke all on public.roles, public.permissions, public.role_permissions, public.profiles, public.audit_events from public, anon, authenticated;
grant select on public.roles, public.permissions, public.role_permissions, public.profiles to authenticated;
create policy profile_read_self on public.profiles for select to authenticated
  using (id = (select auth.uid()) and active);
create policy role_read_own on public.roles for select to authenticated
  using (exists (select 1 from public.profiles p where p.id=(select auth.uid()) and p.active and p.role_id=roles.id));
create policy role_permissions_read_own on public.role_permissions for select to authenticated
  using (exists (select 1 from public.profiles p where p.id=(select auth.uid()) and p.active and p.role_id=role_permissions.role_id));
create policy permissions_read_own on public.permissions for select to authenticated
  using (exists (select 1 from public.role_permissions rp where rp.permission_code=permissions.code));
insert into public.roles(code,name,system_role) values ('admin','Administrador',true),('employee','Funcionário',true);
insert into public.permissions(code,description) values
('orders.create','Criar pedidos'),('orders.view','Consultar pedidos'),('orders.update','Atualizar pedidos'),('orders.cancel','Cancelar pedidos confirmados'),('orders.cancel_item','Cancelar itens confirmados'),
('tables.open','Abrir mesa'),('tables.close','Fechar mesa paga'),('tables.deactivate','Desativar mesa'),
('products.view','Consultar produtos'),('products.create','Cadastrar produtos'),('products.update','Editar produtos'),('products.view_cost','Consultar custos'),
('inventory.view','Consultar estoque'),('inventory.receive','Registrar entrada'),('inventory.withdraw','Registrar saída manual'),('inventory.adjust','Ajustar estoque'),
('cash.open','Abrir caixa'),('cash.close','Fechar caixa'),('cash.view_own','Consultar próprio caixa'),('cash.view_all','Consultar todos os caixas'),('cash.withdraw','Registrar sangria'),('cash.reopen','Reabrir caixa'),
('payments.create','Registrar pagamento'),('payments.refund','Estornar pagamento'),
('customers.create','Cadastrar clientes'),('customers.view','Consultar clientes'),('customers.update','Editar clientes'),
('reports.operational','Consultar relatórios operacionais'),('reports.financial','Consultar relatórios financeiros'),
('users.create','Cadastrar funcionários'),('roles.manage','Gerenciar perfis'),('permissions.manage','Gerenciar permissões'),('approvals.authorize','Autorizar operações'),('audit.view','Consultar auditoria'),('settings.manage','Gerenciar configurações');
insert into public.role_permissions(role_id,permission_code,mode)
select r.id,p.code,case
when r.code='admin' then 'allowed'
when p.code in ('orders.create','orders.view','orders.update','tables.open','tables.close','products.view','inventory.view','cash.open','cash.close','cash.view_own','payments.create','customers.create','customers.view','customers.update','reports.operational') then 'allowed'
when p.code in ('orders.cancel','orders.cancel_item','tables.deactivate','cash.withdraw','cash.reopen','payments.refund') then 'approval'
else 'denied' end
from public.roles r cross join public.permissions p;
