# Celticstech - Sistema de Gestão e Recomendação Agrícola

## Sobre o Projeto

O Celticstech é uma plataforma desenvolvida para auxiliar associações agrícolas da região Nordeste do Brasil no gerenciamento de cultivos e na geração automatizada de recomendações técnicas para produtores rurais.

A aplicação foi construída utilizando arquitetura moderna baseada em APIs REST, banco de dados relacional e infraestrutura em nuvem, seguindo rigorosas práticas de DevOps, Conteinerização e Cloud Computing.

O objetivo principal é centralizar informações agrícolas e automatizar processos de tomada de decisão, permitindo maior eficiência operacional para associações e agricultores.

---

## Objetivos

* Centralizar informações agrícolas.
* Gerenciar associações e regiões agrícolas.
* Controlar cultivos cadastrados.
* Automatizar recomendações técnicas com base no tipo de cultivo.
* Garantir integridade dos dados através de restrições relacionais.
* Aplicar conceitos de DevOps, Infraestrutura como Código (IaC) e Cloud Computing.
* Disponibilizar uma API escalável, monitorável e segura.

---

## Arquitetura da Solução

```plaintext
┌─────────────────┐
│     Swagger     │
│  Interface Web  │
└────────┬────────┘
         │ HTTP (Porta 8080)
         ▼
┌─────────────────┐
│ Celticstech API │
│ ASP.NET Core 8  │
└────────┬────────┘
         │ EF Core (Porta 5432 Interna)
         ▼
┌─────────────────┐
│ PostgreSQL 16   │
│ Banco de Dados  │
└─────────────────┘
         ▲
         │
┌─────────────────┐
│ Docker Compose  │
│ Orquestração    │
└─────────────────┘
         ▲
         │
┌─────────────────┐
│ Azure VM Linux  │
│ Ubuntu 24.04    │
└─────────────────┘
```

---

## Tecnologias Utilizadas

### Backend

* C#
* .NET 8
* ASP.NET Core Web API

### Persistência de Dados

* Entity Framework Core (ORM)
* PostgreSQL 16

### Infraestrutura e DevOps

* Docker e Docker Compose
* Linux Ubuntu 24.04
* Microsoft Azure Virtual Machine (Azure CLI)

### Ferramentas e Versionamento

* Git e GitHub
* Swagger OpenAPI

---

## Práticas DevOps Aplicadas

### 1. Conteinerização e Padronização

Toda a aplicação foi encapsulada utilizando Docker, garantindo portabilidade, isolamento de recursos, reprodutibilidade exata do ambiente de desenvolvimento em produção e facilidade de implantação.

### 2. Multi-Stage Build

O Dockerfile utiliza a estratégia de múltiplos estágios para otimização da imagem:

**Build Stage:** Responsável por restaurar dependências, compilar o código-fonte e publicar os artefatos otimizados.

**Runtime Stage:** Contém apenas o ambiente de execução mínimo necessário do .NET, reduzindo drasticamente o tamanho da imagem, economizando recursos de rede e diminuindo a superfície de ataque.

### 3. Execução com Usuário Não Privilegiado (Segurança)

Por padrão, contêineres rodam como root, o que é um risco severo de segurança. O nosso Dockerfile possui a instrução `USER app`, forçando a aplicação a executar sob um usuário restrito e não privilegiado criado especificamente para o ambiente de runtime do ASP.NET.

### 4. Rede Privada Docker

Foi criada uma rede exclusiva (`celticstech-network`).

Essa rede garante que o PostgreSQL não fique exposto externamente (à internet), permitindo que apenas o contêiner da API tenha acesso ao banco de dados, estabelecendo uma comunicação interna e segura.

### 5. Persistência de Dados (Volumes Nomeados)

Os dados são armazenados em um volume Docker nomeado (`postgres_data`).

Isso garante que os registros persistam mesmo após a reinicialização, atualização ou destruição do contêiner do banco de dados, facilitando também rotinas de backup e disaster recovery.

### 6. Estratégia de Resiliência (Race Condition Mitigation)

Para evitar falhas na aplicação das migrações do Entity Framework (onde a API inicia antes do PostgreSQL estar pronto para aceitar conexões), foi implementado um mecanismo de espera programada (Delay) no startup da aplicação.

Isso garante que o banco de dados esteja totalmente operante antes da criação automática das tabelas.

---

## Provisionamento da Infraestrutura Azure (IaC)

A infraestrutura foi provisionada via linha de comando para garantir rastreabilidade.

### Criação do Resource Group

```bash
az group create --name Celticstech-GS --location southafricanorth
```

### Criação da Máquina Virtual (Ubuntu 24.04)

```bash
az vm create \
  --resource-group Celticstech-GS \
  --name vm-celticstech \
  --image Ubuntu2404 \
  --admin-username celticsadmin \
  --generate-ssh-keys \
  --public-ip-sku Standard
```

---

## Deploy da Aplicação (How-To)

### 1. Acesso à Máquina Virtual via SSH

```bash
ssh celticsadmin@<IP_PUBLICO_DA_VM>
```

### 2. Configuração do Ambiente (Instalação do Docker)

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install docker.io docker-compose -y
sudo systemctl start docker
```

### 3. Clonagem do Projeto

```bash
git clone https://github.com/joaovendrameto05/Celticstech.git
cd Celticstech
```

### 4. Construção e Inicialização em Background

É imperativo o uso da flag `-d` para que a aplicação rode como serviço (segundo plano), liberando o terminal.

```bash
sudo docker-compose up --build -d
```

### 5. Verificação do Status dos Contêineres

```bash
sudo docker ps
```

**Saída esperada:** Os contêineres `celticstech-api-561450` e `postgres-db-561450` devem constar com o status `Up`.

---

## Auditoria e Monitoramento

Parte fundamental do processo DevOps é a auditoria e análise de comportamento dos contêineres em execução.

### Monitoramento de Logs (Background)

```bash
sudo docker logs celticstech-api-561450
sudo docker logs postgres-db-561450
```

### Auditoria do Contêiner da API (.NET)

Acesso interativo para comprovar o diretório de trabalho e o usuário não privilegiado:

```bash
sudo docker exec -it celticstech-api-561450 bash

pwd       # Saída esperada: /app
ls -l     # Exibe os binários compilados (Celticstech.dll)
whoami    # Saída esperada: app

exit
```

### Auditoria do Contêiner do Banco de Dados (PostgreSQL)

```bash
sudo docker exec -it postgres-db-561450 bash

pwd       # Saída esperada: /
whoami    # Saída esperada: postgres

exit
```

---

## Testes da API (CRUD Completo via Swagger)

A documentação interativa está disponível na raiz da aplicação.

Acesse pelo navegador:

```text
http://<IP_PUBLICO_DA_VM>:8080
```

A ordem de inserção (POST) deve respeitar a integridade referencial do banco de dados na seguinte sequência:

### 1. Criar Região (POST /api/Regioes)

```json
{
  "nomeRegiao": "Nordeste",
  "ufRegiao": "NE"
}
```

### 2. Criar Associação (POST /api/Associacoes)

Depende do ID da Região criada no passo anterior.

```json
{
  "nomeAssociacao": "Agro Forte Brasil",
  "siglaAssociacao": "AGF",
  "idRegiao": 1,
  "cnpj": "12345678901234",
  "login": "agroadmin",
  "senha": "senhaSegura123"
}
```

### 3. Criar Cultivo (POST /api/Cultivos)

**Regra de Negócio:** O atributo `porteCultivo` aceita APENAS os valores `ARBUSTO`, `RAIZ`, `ARVORE` ou `HORTALICA`.

```json
{
  "nomeCultivo": "Milho Premium",
  "categoriaCultivo": "Cereal",
  "porteCultivo": "ARBUSTO",
  "tempoColheita": "90 dias",
  "vidaUtil": "1 ano",
  "intermitencia": "Sazonal"
}
```

### 4. Criar Recomendação (POST /api/Recomendacoes)

Depende do ID da Associação e do ID do Cultivo. A API processará automaticamente o tipo e a orientação.

```json
{
  "dataRecAsc": "2026-06-04T10:00:00Z",
  "idAssociacao": 1,
  "idCultivo": 1
}
```

---

## Validação Direta de Persistência (Banco de Dados)

Para comprovar que o sistema está persistindo os dados fisicamente no banco conteinerizado, execute os comandos SQL diretamente dentro do contêiner do PostgreSQL:

```bash
# Acessar o banco de dados interno
sudo docker exec -it postgres-db-561450 psql -U postgres -d CelticstechDb
```

Execute as consultas abaixo (as aspas duplas são obrigatórias na estrutura gerada pelo EF Core):

```sql
SELECT * FROM "Regioes";
SELECT * FROM "Associacoes";
SELECT * FROM "Cultivos";
SELECT * FROM "Recomendacoes";
```

Para sair do terminal do PostgreSQL, digite `\q` e pressione Enter.

---

## Escalabilidade

A arquitetura atual, por ser baseada em contêineres Docker isolados, permite expansão futura de forma nativa e aderente às tecnologias em nuvem, pavimentando o caminho para adoção de:

* Azure Container Apps ou Azure Kubernetes Service (AKS) para orquestração em larga escala.
* Azure Database for PostgreSQL (PaaS) para alta disponibilidade do banco de dados.
* Esteiras de CI/CD automatizadas via GitHub Actions.
* Monitoramento de telemetria utilizando Azure Monitor e Application Insights.

---

## Integrantes do Projeto

| Nome                           | RM        | Turma  |
| ------------------------------ | --------- | ------ |
| João Victor Vendrameto         | RM 563665 | 2TDSPV |
| Nicolas de Oliveira Jacob      | RM 564205 | 2TDSPX |
| Gabriel Ambrósio Saraiva       | RM 566552 | 2TDSPV |
| Vinicius Romaguera Cardozo     | RM 562308 | 2TDSPX |
| Yuri Fuzinatto Garzoli Barreto | RM 561450 | 2TDSPX |

---

## Projeto Acadêmico

Projeto desenvolvido para a disciplina de DevOps, Cloud Computing e Infraestrutura em Nuvem, aplicando e validando os conceitos de Infraestrutura como Código, Conteinerização, Redes Docker, Volumes, e Boas Práticas de Segurança em implantações de Produção.
