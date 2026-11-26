# NOST4LGIA — Sistema de Gestão Comercial

Desenvolvido por VYZO STUDIO.

## Acesso

https://vyzo-studio.github.io/NOST4LGIA/

A página inicial está em index.html. A disponibilidade da última publicação deve ser confirmada no GitHub Pages.

## Estado atual

Projeto Supabase autorizado: Nost4lgia (msliegnljwggfjrgxmdh).
Banco inicial com 21 tabelas protegidas por RLS e três migrações versionadas. A interface inicial utiliza login por e-mail e senha, permissões reais e operações RPC do banco, sem dados demonstrativos.

Disponível para validação: catálogo e cadastro de produtos, movimentação de estoque, cadastro de categorias, mesas e caixas, abertura de mesas e caixas, consulta de pedidos, clientes e auditoria.

Ainda não liberado para uso comercial: criação e confirmação de pedidos, baixa automática por venda, pagamentos, fechamento de caixa, cadastro de clientes pela interface, autorização por senha administrativa, recuperação de senha e gerenciamento de funcionários. A integração e os testes autenticados ainda precisam ser realizados. O logotipo original ainda precisa ser incorporado.

## Primeiro administrador

Crie uma conta individual no painel Supabase em Authentication > Users e confirme o e-mail de acordo com a configuração da conta. O administrador do projeto deve vincular o UUID dessa conta ao perfil administrativo pelo SQL Editor. Não permita autoatribuição de funções administrativas pelo navegador.

Exemplo (substitua o UUID e o nome pelo usuário autorizado; não inclua senhas):
```sql
insert into public.profiles (id,full_name,role_id,active)
select id, 'Nome do administrador', (select id from public.roles where code='admin'), true
from auth.users
where id = '00000000-0000-0000-0000-000000000000'::uuid;
```

A conta inicial não foi criada automaticamente. Não há credenciais padrão.

## Testes

Execute `node --test` para as regras financeiras independentes. Consulte GitHub Actions para o resultado real. A execução de testes de integração e a validação da página publicada continuam pendentes.

## Segurança

Não publique chaves privilegiadas, senhas, registros de clientes ou backups. O frontend utiliza somente a chave publicável do projeto. Não altere os dados diretamente para contornar o controle de permissões.

Referência funcional: https://consumer.com.br/recursos
Documentação Supabase: https://supabase.com/docs/guides/database/postgres/row-level-security
