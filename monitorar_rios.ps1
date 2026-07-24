[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13

$graphqlUrl = "https://redehidrometeorologica.defesacivil.rs.gov.br/graphql"
$googleAppUrl = "https://script.google.com/macros/s/AKfycbzfKv9v2-XLH5L6fsYEigb_KvDs4ikdqBx6uVLs_7fxGd842KFFdTs93McOexs4FmmAUQ/exec"

$query = @"
query Tags_data {
  tags_data(clients: ["casa-militar-defesa-civil-rs"]) {
    qualle_meteorologia {
      codigo
      timestamp
      data { rio { rio_nivel { value } rio_nivel_tendencia { value } } }
    }
  }
}
"@

$stations = @(
    @{code="DCRS-00119"; sheet="Esteio"; label="Est. DCRS 119 - Esteio"},
    @{code="DCRS-00070"; sheet="Sao Leopoldo"; label="Est. DCRS 070 - Sao Leopoldo"},
    @{code="DCRS-00003"; sheet="Ararica/Sapiranga/ Taquara"; label="Est. DCRS 003 - Ararica/Sapiranga/ Taquara"}
)

Write-Host "Baixando dados da Defesa Civil RS (ignorando erro SSL)..."

$body = @{ query = $query } | ConvertTo-Json -Depth 10

try {
    $res = Invoke-RestMethod -Uri $graphqlUrl -Method Post -Body $body -ContentType "application/json" -TimeoutSec 20
    
    $stationsMap = @{}
    foreach ($item in $res.data.tags_data.qualle_meteorologia) {
        $stationsMap[$item.codigo] = $item
    }
    
    $dadosParaEnviar = @()
    
    foreach ($st in $stations) {
        $code = $st.code
        if ($stationsMap.Contains($code)) {
            $stInfo = $stationsMap[$code]
            
            $nivel = $stInfo.data.rio.rio_nivel.value
            $tendencia = $stInfo.data.rio.rio_nivel_tendencia.value
            
            $tsBr = "Data Desconhecida"
            if ($stInfo.timestamp) {
                $tsDate = [datetime]::Parse($stInfo.timestamp).ToLocalTime()
                $tsBr = $tsDate.ToString("dd/MM/yyyy HH:mm:ss")
            }
            
            $nivelStr = if ($nivel) { ([math]::Round([double]$nivel, 2)).ToString().Replace('.', ',') } else { "N/A" }
            $tendenciaStr = if ($tendencia) { ([math]::Round([double]$tendencia, 4)).ToString().Replace('.', ',') } else { "N/A" }
            
            $dadosParaEnviar += @{
                sheet = $st.sheet
                label = $st.label
                code = $code
                time = $tsBr
                nivel = $nivelStr
                tendencia = $tendenciaStr
            }
            Write-Host "-> Dados encontrados para $($st.label): $($nivelStr)m"
        }
    }
    
    if ($dadosParaEnviar.Count -gt 0) {
        Write-Host "`nEnviando dados para a sua Planilha do Google..."
        $googleBody = $dadosParaEnviar | ConvertTo-Json -Depth 10
        
        $gRes = Invoke-RestMethod -Uri $googleAppUrl -Method Post -Body $googleBody -ContentType "application/json" -TimeoutSec 20
        
        if ($gRes.status -eq "sucesso") {
            Write-Host "SUCESSO! Os dados foram inseridos no Google Sheets perfeitamente."
        } else {
            Write-Host "O Google Sheets retornou um erro:" $gRes.mensagem
        }
    } else {
        Write-Host "Nenhum dado encontrado para enviar."
    }
    
} catch {
    Write-Host "Erro ao executar script: $_"
}

Read-Host "`nConcluido! Pressione ENTER para sair..."
