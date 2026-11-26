# Benchmark visual — NOST4LGIA / VYZO STUDIO

Data da análise: 26/11/2026. Fonte: 239 capturas PNG fornecidas pelo responsável do projeto, numeradas de frame_0001 a frame_0239. Todas foram recuperadas e examinadas em sequência por folhas de contato; telas-chave foram abertas em resolução original para conferir campos. Não houve acesso a código ou banco do Consumer. A análise não comprova recursos não demonstrados, desempenho ou funcionamento de integrações. Nenhuma imagem de terceiros, informação pessoal ou credencial foi publicada.

## Princípio de produto

Consumer como referência de fluxos, não de interface, código ou identidade visual. NOST4LGIA deve ser um ERP/PDV web original e adaptado à distribuidora: atendimento rápido, inventário por unidade/embalagem, operação de mesa/balcão e caixa coerentes. Preservar o Supabase autorizado e o repositório existente.

## Inventário de evidências

| Quadros | Fluxo observado | Requisitos propostos para NOST4LGIA |
|---|---|---|
| 0001–0030 | Caixa fechado/aberto, saldo inicial, observação, movimentos, categorias, resumo e fechamento | Abertura por operador; painel com saldo, entradas e saídas; sangria/suprimento com motivo e autorização; contagem e divergência; dinheiro separado de recebimentos eletrônicos |
| 0031–0058 | Grade de mesas, comanda com pesquisa e seletor de produtos, vinculação de cliente, bloqueio de pedido, pedido de balcão identificado | Mapa configurável; total e tempo na mesa; comanda lateral; busca por nome/SKU/código; pedido por nome; itens confirmados protegidos; taxa de mesa opcional; fechamento sem perder histórico |
| 0059–0080 | Lista delivery; dados do cliente, entregador, status iniciado/preparando/pronto/em rota/finalizado, observações, taxa e agendamento | Quadro de entregas de produtos elegíveis, endereço selecionável, status com histórico, taxa própria, acesso limitado do entregador |
| 0081–0097 | Tela caixa livre, fila de atendimento e configurações de integração | PDV em tela cheia; fila centralizada; mostrar estado real de conexão; integrações somente mediante autorização e API oficial |
| 0098–0114 | Calendário de pedidos agendados, opções de integração, cadastro/lista de clientes | Agenda diária/semanal/mensal; alertas de pedidos; CRM com busca por telefone e endereços; integração externa opcional |
| 0115–0139 | Catálogo; formulário de produto com abas principal, estoque, ficha técnica, perguntas e complementos | Cadastro em etapas, imagem, preço, código, estoque mínimo e histórico; receitas e modificadores quando aplicáveis; edição de produto sem alterar histórico de vendas |
| 0140–0157 | Observações, tipos e tamanhos, insumos, movimentação em lote com filtros, custo médio, quantidade final | Variantes, unidades de venda e conversões; histórico de movimentos; entrada em lote com revisão antes da confirmação e cálculo de custo; importação fiscal opcional e validada |
| 0158–0168 | Menus de marketing/financeiro, formas de pagamento, bandeiras, dias para recebimento e taxa | Configuração de pagamentos e taxas; contas a pagar/receber e fornecedores; conciliação; fiado somente se autorizado; promoções apenas de produtos elegíveis |
| 0169–0193 | Mais vendidos, histórico de pedidos e itens, ranking de atendimentos, histórico de caixa, dashboard Meu Negócio, recebimentos, receitas/despesas, central de ações | KPIs com dados reais; filtros por período e canal; histórico por operador; faturamento separado de recebimento e lucro; relatórios e exportação autorizada |
| 0194–0217 | Menu apps, painel eletrônico de senha com chamada, som e voz, opções de mobile/integrações/totem | Painel de retirada opcional; recursos mobile; impressão e integrações reais condicionadas a hardware, contratos e APIs |
| 0218–0239 | Configurações do estabelecimento, numeração, impressora, colaboradores, funções, acesso ao programa, backup e logs no menu | Configuração central, identidade original, perfis granulares, credencial de aprovação, auditoria, diagnóstico, backup e recuperação testáveis |

## Direção visual original

- Tema escuro premium e modo claro opcional; ciano #4CDCFC, fundo #080B0F, superfícies #101820 e #16212C, bordas #253644, texto claro; vermelho como acento de marca/alerta, não como decoração indiscriminada.
- Logotipo original fornecido pelo cliente, sem redesenho. Inter ou fonte equivalente; números tabulares; ícones vetoriais consistentes e acessíveis.
- Navegação por grupos: Operação (visão geral, mesas, balcão, pedidos, entregas, agenda); Gestão (produtos, estoque, inventário, compras, clientes); Financeiro (caixa, recebimentos, despesas, relatórios); Administração (equipe, permissões, auditoria, configurações).
- Evitar janelas sobrepostas para tarefas recorrentes. Usar painel de comanda persistente, modal somente para confirmação curta, tela cheia de PDV, busca e atalhos de teclado. Interface responsiva e acessível, sem controles decorativos.
- Dashboard ADM com indicadores financeiros; dashboard funcionário com ações operacionais, sem custos e margens.

## Diferenciais propostos (não comprovados como exclusivos do mercado)

- Mesa em uma visão: status textual e cor, total, tempo aberto, cliente/operador e ações contextuais.
- PDV com catálogo de pesquisa rápida, favoritos, estoque disponível, carrinho persistente, quantidade e total.
- Conversão consistente de caixa/fardo/unidade e prevenção de estoque negativo; revisão de entrada em lote; validade e perdas.
- Caixa com resumo de dinheiro, PIX e cartão, recebimentos mistos/parciais, troco, taxa opcional de 10% somente nas mesas, conciliação e fechamento cego opcional.
- Painel de ação: estoque crítico, mesa aguardando pagamento, entrega atrasada, divergência de caixa; dados reais e permissões aplicadas.
- Operação em múltiplos dispositivos com sincronização autorizada, controle de conflitos, estado offline visível e sem falsas confirmações.
- Fluxo de aprovação do ADM específico à ação e com registro do solicitante e aprovador, sem troca da sessão do funcionário.
- Módulos adicionais só quando realmente úteis: agenda, painel de retirada, importação CSV, relatórios, impressão, integração fiscal e pagamentos mediante requisitos reais.

## Checklist de implementação a validar

- [ ] P0: login real com primeiro ADM e funcionário; autorização direta via API e RLS; recuperação de senha; verificar estados de sessão.
- [ ] P0: integrar catálogo, estoque, criação de pedido, comanda, confirmação, entrega, pagamentos, fechamento de mesa/caixa à interface e testar cenário completo.
- [ ] P0: aprovação administrativa por operação, cancelamento/estorno, devolução ou perda de estoque; testes de duplicidade, concorrência e permissão.
- [ ] P0: aplicar identidade NOST4LGIA original e layout de operação desktop/touch/mobile; testar sem overflow ou bloqueio de controles.
- [ ] P1: cadastro e edição de produtos, embalagens, lotes, inventário e importação em lote; alertas de reposição.
- [ ] P1: CRM e agenda, entregas elegíveis, endereços, estados e permissões do entregador.
- [ ] P1: compras, fornecedores, contas a pagar/receber, despesas, taxas de pagamento e conciliação; relatórios.
- [ ] P1: sincronização em tempo real, paginação, busca, performance e acessibilidade.
- [ ] P2: impressão não fiscal, painel de retirada, PWA e contingência offline segura.
- [ ] P2: integrações externas, fiscal, hardware e pagamentos verificados apenas mediante autorização, viabilidade técnica e conformidade.
- [ ] Homologação: validar publicação, backup/restore, segurança e testes de ponta a ponta. Não considerar pronto antes da verificação.

## Critérios comparáveis de preferência do cliente

Metas de projeto, não resultados medidos: abrir mesa em até duas ações após entrar no módulo; incluir um produto em até duas ações após localizá-lo; mostrar busca em até 200 ms e operação comum confirmada em até 500 ms quando a infraestrutura permitir; testar larguras 360, 390, 768, 1024, 1366 e 1920 px; zero duplicações em testes de estoque e pagamento; usuário não autorizado bloqueado mesmo via API. Comparar os mesmos cenários, equipamento, dados e conexão com Consumer e obter avaliação do cliente antes de alegar superioridade. Não sacrificar segurança ou legibilidade para reduzir cliques.
