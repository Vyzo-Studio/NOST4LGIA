# NOST4LGIA 2.0 — Checklist mestre

Atualizado em 26/11/2026. Base: docs/benchmark-consumer.md (239 imagens).
Legenda: [x] implementação registrada; validação indicada explicitamente. [ ] pendente ou ainda não comprovado. Não usar em produção até homologação.

## Fundação
- [x] GitHub e Supabase corretos; seis migrações versionadas.
- [x] Benchmark de 239 capturas registrado.
- [x] HTML, CSS e JavaScript separados.
- [x] CI configurada com checagem de sintaxe e testes de domínio.
- [ ] Confirmar execução da CI e publicação GitHub Pages.

## Segurança e acesso
- [x] Login por e-mail/senha integrado ao Auth; tela e controle de perfil existentes, teste de navegador pendente.
- [x] 21/21 tabelas com RLS; verificador de segurança retornou zero alertas.
- [x] Teste SQL: funcionário sem acesso aos custos e sem permissão para alteração manual/direta de estoque.
- [ ] Criar primeira conta ADM autorizada e vincular perfil ativo; ainda zero usuários.
- [ ] Validar login real, sessão, recuperação de senha e desativação.
- [ ] Cadastro de funcionários, perfis personalizados, aprovação administrativa específica por senha.
- [ ] Cancelamento, estorno e devolução autorizados; auditoria e testes de abuso.

## Identidade visual
- [x] Tema escuro/ciano e layout responsivo inicial.
- [x] Mapa de mesas e catálogo/carrinho lateral.
- [ ] Logotipo original, tema claro, menu retrátil, atalhos, refinamento visual e acessibilidade.
- [ ] Testar larguras de 360 a 1920 px e medir desempenho.

## Produtos e estoque
- [x] Cadastro de produtos e categorias; edição e desativação (RPC e formulário).
- [x] Cadastro de embalagens (RPC e formulário).
- [x] Entrada e saída manual; conversão em unidades base no formulário de movimentação.
- [x] Indicador de estoque crítico e busca por nome, SKU e código.
- [x] Reserva e baixa por pedido, verificada por teste SQL sequencial.
- [ ] Testar formulários autenticados e conversão; conversão e precificação de embalagens em vendas.
- [ ] Inventário em lote, importação, validade/lotes, perdas, custo médio, fornecedores e compras.

## Mesas e PDV
- [x] Mapa, abertura, nome de cliente, tempo de ocupação e consumo estimado.
- [x] Pedido de mesa/balcão/retirada, catálogo, comanda, inclusão e remoção de rascunho.
- [x] Confirmação e entrega de itens, taxa opcional de 10% exclusiva de mesa.
- [x] Encerramento de mesa; teste SQL de fluxo aprovado.
- [ ] Teste real pelo navegador; transferência/junção, desconto, impressão, divisão de conta por pessoa, atalhos.
- [ ] Paginação completa, validação de totais da grade em grandes volumes.

## Caixa
- [x] Abertura, registro de pagamento, pagamentos parciais/mistos, troco, fechamento.
- [x] Resumo separado dinheiro/PIX/débito/crédito; sangria e suprimento disponíveis apenas para permissão direta.
- [x] Teste SQL: pagamento parcial PIX, dinheiro com troco, idempotência, conciliação e fechamento.
- [ ] Testar sangria/suprimento, autorização delegada, concorrência e falhas de rede.
- [ ] Comprovantes, estornos, taxas e conciliação externa. Registro manual não comprova recebimento bancário.

## Clientes, entrega e agenda
- [x] Cadastro de clientes e endereço pela interface.
- [ ] Testar cadastro, edição, busca e histórico.
- [ ] Delivery bloqueado até validação de elegibilidade e endereço; agenda e entregadores pendentes.

## Gestão e diferenciais
- [x] Função de indicadores financeiros por período (backend).
- [ ] Dashboard financeiro e relatórios, despesas, contas a pagar/receber, compras, exportação.
- [ ] Sincronização em tempo real, PWA, contingência offline segura, painel de retirada e impressora.
- [ ] Backup/restauração, integrações oficiais, conformidade e homologação.

## Evidências da validação
- Migrações: initial_access_control, commercial_core_schema, controlled_core_operations, transactional_sales_core, cash_controls_and_order_totals, command_center_operations.
- test/sql/sales_smoke.sql executado no Supabase vazio, resultado PASS. Identidades simuladas via role authenticated e claims de teste, não login real. Fixtures revertidas; contagem posterior de usuários, perfis, pedidos, produtos, pagamentos, movimentos, caixa e auditoria igual a zero. Sequência de números de pedidos pode avançar mesmo com rollback.
- Checagem de sintaxe JavaScript concluída via compilação sem execução do código; teste CI node --check adicionado. Execução da CI não confirmada.
- Tentativa de abrir site e módulo JS publicado não acessível pela ferramenta de navegação. Não significa confirmação de indisponibilidade para o usuário.
- Pendente: testes E2E com conta real e testes de concorrência simultânea, segurança aprofundada, desempenho e responsividade. Não liberar para vendas reais.
