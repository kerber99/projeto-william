# Monitoramento de Rios - Defesa Civil (Projeto William)

Este é um sistema de automação e monitoramento do nível de rios, criado para auxiliar nas ações preventivas (como as da Defesa Civil). O projeto coleta dados atualizados e integra essas informações automaticamente em planilhas para controle e histórico.

## Principais Componentes e Funcionalidades

- **Coleta de Dados (Web Scraping / APIs)**: Scripts desenvolvidos em **Python** (`monitorar_rios.py`) e **PowerShell** (`monitorar_rios.ps1`) para realizar a busca e o monitoramento contínuo dos níveis fluviais.
- **Integração com Planilhas**: Uso de Google Apps Script (`script_google_apps_script.txt`) para atualizar os dados diretamente na nuvem (Google Sheets).
- **Automação Local**: Arquivos Batch (`.bat`) como `LIGAR_AUTOMACAO.bat`, `ATUALIZAR_RIOS.bat` e `ATUALIZAR_PLANILHA.bat` criados para inicializar facilmente as rotinas sem precisar abrir o terminal manualmente.
