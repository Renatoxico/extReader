# Noturno+ — implementação frontend

## Escopo e arquivos

- `extReader/Design/Noturno.swift` (novo): cores, fundos radiais, moeda pt-BR, datas, tipografia monetária escalável, cartões, ícones, estado pressionado e transição de zoom com fallback no iOS 17.
- `extReader/Utils/PreparedReport.swift` (novo): snapshots Sendable, IDs por índice da resposta, calendário gregoriano domingo-primeiro, datas sem deslocamento de fuso, agregação e cache mensal, destaques consistentes com os lançamentos, top-5/Outras, cores estáveis, quantis, ocorrências e intervalos, séries temporais e dados de detalhe.
- `extReader/Views/Pages/ReportView/ExpenseReportViewTabs.swift` (reescrito): NavigationStack, rotas, preparação em Task.detached, sheet de dia, compartilhamento de imagem com valores ocultos inicialmente e exportação CSV existente.
- `NightDashboard.swift`, `NightCalendar.swift`, `NightCharts.swift`, `NightDetails.swift`, `NightExpenseTimeline.swift` (novos no mesmo diretório): telas descritas abaixo.
- `extReader/Views/HomeView.swift` (alterado): quatro abas; upload e histórico abrem o relatório na aba Relatório; Conta mantém a tela existente.
- `extReader/Views/Components/BackgroundView.swift` (alterado): fundo centralizado Noturno+.
- `extReader/Views/Components/ExpenseDetailView.swift` (alterado): formatação monetária pt-BR no detalhe existente.
- `extReader/Views/Pages/UploadView/UploadExpenseView.swift` (alterado): apenas linha de confiança acrescentada ao layout. NoFilesView, SelectedFilesView, botões, DocumentPicker, tipos PDF, limites, validações e envio preservados.
- `extReader/Testing/PreviewFixtures.swift` (alterado) e `Testing/PreviewFixtures/sample-stress.json` (novo): previews curtos e de stress. Fixture inspecionado: declaração explícita de dados fictícios, nomes comerciais, nenhum CPF ou nome pessoal aparente.
- `Tests/Noturno/main.swift` (novo): verificações executáveis sem dependências externas.

Removidas as telas antigas de relatório (`CategoryChartViewDG`, `CategoryListView`, `ExpenseDashboardView`, `ExpensesView`, `TopExpensesView`) e os componentes que só elas usavam (`StatCard`, `GroupedExpenseCard`, `GroupedExpenseListItemView`, `ExpenseListItemView`). O app usa Swift Charts; nenhuma dependência foi adicionada. As referências de pacotes preexistentes do projeto não foram alteradas.

Serviços, autenticação, exclusão de conta, modelos/decodificação de rede, AppConfig e arquivos de segredos não foram alterados. Nenhum comando git foi executado diretamente.

## Mapa das telas

| Spec | Implementação |
|---|---|
| R01 | UploadExpenseView + NoFilesView/SelectedFilesView originais; BackgroundView + linha de confiança |
| R02 | NightDashboard: total animado, barra/legenda; NightCalendar: células acessíveis, seleção, quantis e maior compra |
| R03 | NightDashboard: cabeçalho compacto pelo deslocamento do hero, destaques, maiores despesas e Ver todas |
| R04 | NightCharts: ArcSegment, seleção por ângulo, primeira seleção/segundo toque navega, lista proporcional |
| R05 | NightCharts: BarMark por categoria, dias vazios, média por dia com gasto, seleção e cartão que abre sheet |
| R06 | NightCharts: AreaMark/LineMark, ritmo constante, seleção com callout e insight da metade do total |
| R07 | NightCategoryDetail: anel, estatísticas, gráfico, lançamentos, estabelecimentos e zoom no iOS 18 |
| R08 | NightDaySheet: medium/large, anterior/próximo dia com gasto, swipe, destaques, comparação, divisão por categoria e salto à timeline |
| R09 | NightMerchantDetail: total, recorrência, PointMark proporcional, eixo, intervalos, estatísticas e compras; detalhe original acessível |
| R10 | NightExpenseTimeline: busca de 200 ms, ordenação, chips, trilho, cabeçalhos de dia fixos em período curto, agrupadas/recorrentes/únicas, expansão e navegação |
| S01 | NightDashboard: Todos/meses e comparação mensal tocável |
| S02 | Cache FilteredReport mensal: totais, categorias, destaques e delta; parciais sem delta |
| S03 | NightCharts + PreparedReport: top-5 e Outras apenas acima de seis categorias, arco mínimo e cores estáveis |
| S04 | NightCharts: Outras expande no lugar, barra de composição, legenda condensada, cinzas e Recolher |
| S05 | NightCalendar: carrossel, vizinhos com opacidade/escala, pontos e resumo de cada mês; abre no último mês |
| S06 | NightCalendar: LazyHGrid de sete linhas, semanas domingo-primeiro, totais semanais, rolagem ao fim, seleção e toggle |
| S07 | NightCharts: Dia/Semana/Mês, escolha automática, barras agregadas, divisores e timeline limitada ao bucket |
| S08 | NightCharts: área acumulada, faixas/divisores mensais, pontos no fim do mês e chips mensais com delta |
| S09 | NightExpenseTimeline: seções mensais fixas com total/contagem, LazyVStack, nós por quantil e ocorrência por compra |

## Decisões e aproximações

- Destaques são calculados a partir de AllExpenses também em Todos, opção permitida no round 3 para evitar a contradição entre NotableDays e o gráfico.
- A linha opcional “Último relatório” do upload foi omitida; o Histórico continua abrindo os relatórios existentes.
- A soma acumulada mantém todos os dias nos dados, mas o desenho amostra no máximo 100 pontos em períodos extensos; seleção e valores consultam a série completa. Mudanças entre pontos amostrados são uma aproximação visual.
- Barras recebem buckets pré-agregados; na substituição manual para Dia em um período muito longo, e nos gráficos de detalhe, o número de marcas pode superar 100. O gráfico semanal habilita rolagem horizontal acima de 26 semanas. Essa parte ainda requer medição em dispositivo para definir virtualização sem perder seleção por data.
- Calendário usa alinhamento por cartão (`viewAligned`) no carrossel para permitir vizinhos visíveis. O indicador acompanha scrollPosition.
- O eixo de compras usa o conjunto de datas com rótulos automáticos e intervalo médio; a lista mostra o intervalo exato desde a compra anterior. Em comerciantes com mais de oito compras, valores acima dos pontos são omitidos para evitar sobreposição, permanecendo na lista e na acessibilidade.
- Não há screenshot de execução nem validação visual em iPhones: CoreSimulatorService e acesso ao seu diretório de dispositivos foram bloqueados pelo sandbox. Dynamic Type e layout precisam dessa conferência visual, especialmente acessibilidade máxima e muitas compras no mesmo dia.

## Validação

Tentativa de build:

```sh
xcodebuild -project extReader.xcodeproj -scheme extReader -destination 'generic/platform=iOS Simulator' ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO -derivedDataPath /tmp/somai-noturno-build -clonedSourcePackagesDirPath build/dd/SourcePackages -disableAutomaticPackageResolution build
```

Bloqueado antes da compilação pelas dependências preexistentes: `Could not resolve host: github.com`. O xcodebuild tentou resolver os pacotes mesmo com a resolução automática desabilitada; não houve adição de pacotes ou alterações deliberadas em suas versões.

Checagem independente com swiftc e SDK do simulador, alvo arm64 iOS 17.6: novos arquivos de relatório e integração com HomeView, upload, histórico e detalhe. Serviços substituídos somente em arquivos temporários de validação, sem alterar os serviços do app. Esta checagem não substitui o build completo/linkedição nem verifica Firebase/Google Sign-In.

Testes de dados:

```sh
xcrun swiftc -module-cache-path /tmp/noturno-host-cache extReader/Utils/ExpenseReport.swift extReader/Utils/PreparedReport.swift Tests/Noturno/main.swift -o /tmp/noturno-data-tests
/tmp/noturno-data-tests extReader/Testing/PreviewFixtures/sample-stress.json
```

Verificações: 144 lançamentos, R$ 14.521,10, setembro R$ 5.308,19, filtros, cores, top-N, destaques, 14 semanas, acumulado, duplicatas, meses parciais, relatório vazio, limite de seis/sete categorias e fixture gerado de 1.000 lançamentos ao longo de 500 dias.
