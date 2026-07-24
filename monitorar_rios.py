import requests
import os
from datetime import datetime
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

GRAPHQL_URL = "https://redehidrometeorologica.defesacivil.rs.gov.br/graphql"

# ---------------------------------------------------------
# URL DO SEU WEB APP DO GOOGLE SHEETS
# ---------------------------------------------------------
GOOGLE_WEBAPP_URL = "https://script.google.com/macros/s/AKfycbyz85Dj2SZC9PBNY3KW_7HAhH77VHA9frpMfZU6CCb4WFHv2TAXOch7MlWv5D5WAbKX0Q/exec"

STATIONS = [
    {"code": "DCRS-00119", "sheet": "Esteio", "label": "Est. DCRS 119 - Esteio"},
    {"code": "DCRS-00070", "sheet": "São Leopoldo", "label": "Est. DCRS 070 - São Leopoldo"},
    {"code": "DCRS-00003", "sheet": "Araricá/Sapiranga/Taquara", "label": "Est. DCRS 003 - Araricá/Sapiranga/Taquara"}
]

QUERY = """
query Tags_data {
  tags_data(clients: ["casa-militar-defesa-civil-rs"]) {
    qualle_meteorologia {
      codigo
      timestamp
      data { rio { rio_nivel { value } rio_nivel_tendencia { value } } }
    }
  }
}
"""

def enviar_para_google():
    if GOOGLE_WEBAPP_URL == "COLE_A_URL_AQUI":
        print("ERRO: Você precisa colar a URL do Google Sheets dentro do arquivo monitorar_rios.py!")
        return

    print("Baixando dados da Defesa Civil RS (ignorando erro SSL)...")
    headers = {"Content-Type": "application/json"}
    
    try:
        response = requests.post(GRAPHQL_URL, json={"query": QUERY}, headers=headers, verify=False, timeout=20)
        response.raise_for_status()
    except Exception as e:
        print(f"Erro ao acessar Defesa Civil: {e}")
        return
        
    qualle = response.json().get("data", {}).get("tags_data", {}).get("qualle_meteorologia", [])
    stations_map = {item["codigo"]: item for item in qualle}
    
    dados_para_enviar = []
    
    for st in STATIONS:
        code = st["code"]
        if code in stations_map:
            st_info = stations_map[code]
            rio_info = st_info.get("data", {}).get("rio", {})
            
            nivel = rio_info.get("rio_nivel", {}).get("value")
            tendencia = rio_info.get("rio_nivel_tendencia", {}).get("value")
            
            ts_str = st_info.get("timestamp")
            if ts_str:
                ts_obj = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
                ts_br = ts_obj.strftime("%d/%m/%Y %H:%M:%S")
            else:
                ts_br = "Data Desconhecida"
            
            dados_para_enviar.append({
                "sheet": st["sheet"],
                "label": st["label"],
                "code": code,
                "time": ts_br,
                "nivel": str(round(float(nivel), 2)).replace('.', ',') if nivel else "N/A",
                "tendencia": str(round(float(tendencia), 4)).replace('.', ',') if tendencia else "N/A"
            })
            print(f"-> Dados encontrados para {st['label']}: {nivel}m")
            
    if dados_para_enviar:
        print("\nEnviando dados para a sua Planilha do Google...")
        try:
            r = requests.post(GOOGLE_WEBAPP_URL, json=dados_para_enviar, timeout=15)
            r.raise_for_status()
            resultado = r.json()
            if resultado.get("status") == "sucesso":
                print("SUCESSO! Os dados foram inseridos no Google Sheets perfeitamente.")
            else:
                print("O Google Sheets retornou um erro:", resultado.get("mensagem"))
        except Exception as e:
            print(f"Erro ao enviar para o Google Sheets: {e}")
    else:
        print("Nenhum dado encontrado para enviar.")

if __name__ == "__main__":
    enviar_para_google()
    input("\nConcluído! Pressione ENTER para sair...")
