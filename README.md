# NOST4LGIA — Sistema de Gestão Comercial

Desenvolvido por VYZO STUDIO.

## Estado inicial

Em 25/11/2026 o repositório foi verificado vazio (sem branches ou commits) e a conexão Supabase denominada Nost4lgia retornou zero projetos acessíveis. O esqueleto mencionado no briefing não estava disponível no repositório. Nenhum banco alternativo foi criado ou selecionado.

Este repositório começa como uma fundação de desenvolvimento, não como um ERP operacional. Não contém catálogo público, dados de clientes, credenciais ou confirmação fictícia de pagamentos.

## Escopo

Aplicação privada para administração e funcionários: mesas, comandas, balcão, estoque, clientes, caixa, pedidos, financeiro e auditoria. A taxa sugerida de 10% é opcional e exclusiva de mesas. O estoque e os valores definitivos deverão ser validados no servidor com transações e controle de permissões.

## Bloqueios

- Conceder acesso ao projeto Supabase existente Nost4lgia e confirmar seu project reference.
- Disponibilizar o esqueleto original do site, se houver trabalho fora deste repositório.
- Incorporar o arquivo oficial da marca sem redesenho.
- Auditar schema, Auth, RLS, permissões, migrations e configuração de implantação antes de alterações no banco.

Não executar migrações em outro projeto. Não publicar o ERP como operacional sem testes de integração e autorização.

## Referências funcionais

- https://consumer.com.br/recursos
- https://ajuda.programaconsumer.com.br/como-fazer-a-abertura-e-o-fechamento-do-caixa-gaveta/
- https://ajuda.programaconsumer.com.br/como-fazer-a-divisao-da-conta-entre-varios-clientes-na-mesa/
- https://supabase.com/docs/guides/database/postgres/row-level-security
- https://supabase.com/changelog.md

O Consumer é referência de fluxo, não de código ou identidade visual.

## Desenvolvimento

A fundação independente do banco utiliza módulos JavaScript ES e testes com Node.js, sem dependências externas. Os cálculos locais não constituem autorização de pagamento ou persistência.

Execute `node --test` após a inclusão dos testes. O servidor e a interface ainda precisam ser integrados ao projeto autorizado.

Site pretendido (não publicado/verificado): https://vyzo-studio.github.io/NOST4LGIA/
