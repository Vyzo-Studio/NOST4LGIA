# NOST4LGIA — Sistema de Gestão Comercial

Desenvolvido por VYZO STUDIO.

## Acesso

https://vyzo-studio.github.io/NOST4LGIA/

A página inicial está em index.html. A disponibilidade da última publicação deve ser confirmada no GitHub Pages.

## Estado atual

Projeto Supabase autorizado: Nost4lgia (msliegnljwggfjrgxmdh).
21 tabelas protegidas por RLS e seis migrações versionadas. Interface Command Center 2.0 com arquivos HTML, CSS e JavaScript independentes.

Disponível para validação: login e permissões, produtos e edição, embalagens, estoque, mesas e comandas, PDV de balcão/retirada, reservas, baixa na entrega, taxa opcional de mesa, registro de pagamentos, troco, abertura e fechamento de caixa, cadastro de clientes e consulta de auditoria.

O teste SQL integrado com identidades temporárias foi aprovado; dados de teste revertidos. A sintaxe do frontend foi verificada, mas testes reais no navegador e publicação ainda não estão confirmados. Nenhum usuário administrativo foi criado. Não usar para vendas reais antes de homologação.

Delivery está bloqueado até implementação de regras de elegibilidade e endereço. Aprovações administrativas, estornos, relatórios completos e outros módulos continuam pendentes.

- [Checklist mestre atualizado](docs/checklist.md)
- [Benchmark visual Consumer](docs/benchmark-consumer.md)
- [Teste SQL de integração](test/sql/sales_smoke.sql)

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

Execute `node --test` para as regras financeiras independentes. Consulte GitHub Actions para o resultado real. O teste SQL de integração foi executado com sucesso no banco vazio. Os testes autenticados no navegador, a execução da CI e a validação da página publicada continuam pendentes.

## Segurança

Não publique chaves privilegiadas, senhas, registros de clientes ou backups. O frontend utiliza somente a chave publicável do projeto. Não altere os dados diretamente para contornar o controle de permissões.

Referência funcional: https://consumer.com.br/recursos
Documentação Supabase: https://supabase.com/docs/guides/database/postgres/row-level-security
