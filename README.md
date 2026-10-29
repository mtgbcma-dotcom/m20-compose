# Bookstore - Docker Compose com PostgreSQL

Atividade do Módulo 20 de Continuação Back-End Python da EBAC.

Configurei o Docker Compose para orquestrar a API Django REST Framework e o banco PostgreSQL em serviços separados. A API mantém categorias, produtos, pedidos, paginação de 5 registros e autenticação por token somente nos pedidos.


## Consulta pública de produtos

Apliquei a orientação do tutor e a correção do módulo 17: a listagem `GET /api/products/` e o detalhe `GET /api/products/{id}/` são públicos, sem necessidade de login ou token. Preservei a paginação de 5 registros, os links para as páginas seguintes e a categoria na representação dos produtos.

Mantive o cadastro, a alteração e a exclusão de produtos restritos à equipe por sessão ou Basic Authentication. Os pedidos continuam protegidos por TokenAuthentication e retornam HTTP 401 sem token. Mantive também a permissão de categorias e o Poetry, com o manifesto e o lock sem alterações nesta correção.

Acrescentei testes de consulta anônima da listagem e dos detalhes, paginação sem login e bloqueio de todas as operações de escrita de produtos para visitantes e usuários comuns. Registrei a validação em [docs/CONTINUIDADE.md](docs/CONTINUIDADE.md).

## Continuidade do projeto e do ambiente

Dei continuidade ao [módulo 19 — Docker](https://github.com/mtgbcma-dotcom/m19-docker/pull/1). Mantive os modelos, serializers, migração inicial, paginação, autenticação e testes da API Bookstore.

Mantive **Poetry** como gerenciador do projeto, com `pyproject.toml` e `poetry.lock` versionados. Preservei a identificação `m57-bookstore` e as dependências da base corrigida do módulo 17. Acrescentei ao manifesto somente as dependências necessárias para esta etapa e atualizei o lock pelo Poetry.

Configurei o Dockerfile para instalar Poetry 2.5.1, conferir o lock e instalar as dependências com `poetry install --only main --no-root`. O pip instala apenas a ferramenta Poetry na imagem; as dependências da aplicação são instaladas pelo Poetry a partir do lock.

Os arquivos `requirements*.txt` são exportações de compatibilidade do mesmo lock, utilizadas quando uma plataforma exige esse formato. A fonte de dependências desta entrega é o manifesto e o lock do Poetry. Registrei a continuidade e a validação em [docs/CONTINUIDADE.md](docs/CONTINUIDADE.md).

Para conferir o manifesto no computador com Poetry 2.5.1 instalado:

```powershell
poetry check --lock
poetry install --no-root --no-interaction
```

Nos módulos com PostgreSQL, executei os testes nos serviços Docker descritos abaixo, onde o banco está configurado. No contêiner, utilizei `poetry run python manage.py test` no mesmo ambiente instalado pelo Poetry.

## Implementação

- `docker-compose.yml` com os serviços `web` e `db`.
- Serviço `web` construído pelo Dockerfile com Python 3.13 e dependências do projeto.
- Serviço `db` com a imagem oficial `postgres:17-alpine`.
- Conexão Django/PostgreSQL pelo driver `psycopg` e pelo nome de serviço `db` na rede do Compose.
- Configurações compartilhadas por variáveis de ambiente, com `.env.example` como modelo.
- `healthcheck` no banco e `depends_on` com `condition: service_healthy` para iniciar o Django somente quando o PostgreSQL estiver pronto.
- Migrações aplicadas automaticamente antes de iniciar o servidor.
- Volume nomeado `postgres_data` para persistir os dados do PostgreSQL.
- API disponível no computador pela porta 8001; o banco é acessado pela rede interna do Compose.
- Código e dependências na imagem; Git, ambientes virtuais e arquivos `.env` excluídos pelo `.dockerignore`.

O ambiente utiliza o servidor de desenvolvimento do Django para a execução local da atividade.

## Executar no Windows

Mantenha o Docker Desktop aberto e use o PowerShell na pasta que contém `docker-compose.yml`.

### 1. Preparar as configurações

Na primeira execução, copie o modelo:

```powershell
Copy-Item .env.example .env
```

O modelo contém valores para estudo local. Abra `.env` no editor e ajuste `POSTGRES_PASSWORD` antes de iniciar o banco. Mantenha a mesma senha nas próximas execuções: o PostgreSQL usa essas variáveis para criar o banco e o usuário apenas quando o volume está vazio.

O arquivo `.env` é ignorado pelo Git e pelo build da imagem. O arquivo `.env.example` acompanha o projeto para documentar as variáveis. Não repita a cópia sobre um `.env` já configurado.

### 2. Construir e iniciar os serviços

```powershell
docker compose config --quiet
docker compose up -d --build --wait
```

O primeiro comando verifica o arquivo Compose e as variáveis; sem erros, não mostra saída. O segundo baixa as imagens necessárias, constrói a API, inicia o PostgreSQL, aplica as migrações e aguarda os serviços ficarem saudáveis.

Confira:

```powershell
docker compose ps
```

Os serviços `web` e `db` devem aparecer em execução e com estado `healthy`.

Para consultar os registros de inicialização:

```powershell
docker compose logs --tail 60 web db
```

### 3. Criar o administrador

```powershell
docker compose exec web poetry run python manage.py createsuperuser
```

Preencha seu usuário, e-mail e senha. A senha não aparece durante a digitação. Este banco é independente dos módulos anteriores, portanto é necessário criar um administrador nele.

### 4. Criar os produtos de exemplo

```powershell
docker compose exec web poetry run python manage.py seed_demo
```

São criadas 12 categorias e 12 produtos para conferir a paginação. Executar novamente não duplica os mesmos registros. O comando não cria pedidos nem usuários.

### 5. Abrir a aplicação

- Raiz da API: http://127.0.0.1:8001/api/
- Administração: http://127.0.0.1:8001/admin/
- Categorias: http://127.0.0.1:8001/api/categories/
- Produtos: http://127.0.0.1:8001/api/products/
- Pedidos: http://127.0.0.1:8001/api/orders/

Consulte a listagem e os detalhes de produtos sem fazer login. Para acessar categorias ou cadastrar, alterar e excluir produtos, use **Log in** com o administrador criado. A listagem de produtos preserva `count`, `next`, `previous` e `results`.

Pedidos exigem o cabeçalho de token. Acessar `/api/orders/` diretamente no navegador sem esse cabeçalho retorna HTTP 401, mesmo com sessão de login.

O valor `APP_PORT=8001` evita conflito com o MD19 na porta 8000. Se mudar `APP_PORT` no `.env`, atualize também a porta dos endereços utilizados nos testes e execute novamente `docker compose up -d --wait`.

## Verificar o PostgreSQL e os testes

Confira a conexão com o servidor de banco de dados:

```powershell
docker compose exec web poetry run python manage.py shell -c "from django.db import connection; cursor = connection.cursor(); cursor.execute('SELECT version()'); print(cursor.fetchone()[0])"
```

A saída deve informar PostgreSQL 17. A aplicação está configurada para usar PostgreSQL, incluindo o banco temporário criado pelo Django durante os testes.

```powershell
docker compose exec web poetry run python manage.py check
docker compose exec web poetry run python manage.py makemigrations --check --dry-run
docker compose exec web poetry run python manage.py test --verbosity 2
```

A suíte contém 89 testes de serializers, operações da API, permissões, paginação e autenticação por token. O esperado é terminar com `Ran 89 tests` e `OK`. O banco temporário dos testes é removido ao concluir, preservando os produtos e usuários cadastrados para a demonstração.

## Testar pedidos com token no PowerShell

```powershell
$credencialMD20 = Get-Credential -Message "Informe o administrador criado no MD20"
$corpoMD20 = @{
    username = $credencialMD20.UserName
    password = $credencialMD20.GetNetworkCredential().Password
} | ConvertTo-Json

$autenticacaoMD20 = Invoke-RestMethod -Uri "http://127.0.0.1:8001/api/token/" -Method Post -ContentType "application/json" -Body $corpoMD20 -ErrorAction Stop
$cabecalhosMD20 = @{ Authorization = "Token $($autenticacaoMD20.token)" }
Remove-Variable credencialMD20, corpoMD20

(Invoke-WebRequest -Uri "http://127.0.0.1:8001/api/orders/" -Headers $cabecalhosMD20 -UseBasicParsing).StatusCode

Invoke-RestMethod -Uri "http://127.0.0.1:8001/api/orders/" -Headers $cabecalhosMD20 | ConvertTo-Json -Depth 8
```

O esperado é HTTP 200 e a resposta paginada. Se não houver pedidos, `count` será 0 e `results` será uma lista vazia. Não inclua o token nem as credenciais em prints ou commits.

## Parar e executar novamente

Para parar os dois serviços mantendo os contêineres e os dados:

```powershell
docker compose stop
docker compose up -d --wait
```

Para remover os contêineres e a rede e, depois, recriá-los usando o mesmo banco:

```powershell
docker compose down
docker compose up -d --wait
```

`docker compose down` preserva o volume nomeado e os dados do PostgreSQL. Não acrescente `-v` quando quiser manter os cadastros: essa opção exclui os volumes.

## Atualizar a aplicação após alterar arquivos

```powershell
docker compose up -d --build --wait
```

O Compose reconstrói a imagem e atualiza o serviço da API. O banco permanece no volume nomeado.

## Makefile opcional

Incluí atalhos `make up`, `make down`, `make logs`, `make check`, `make test`, `make migrate`, `make superuser` e `make seed` para ambientes que tenham GNU Make instalado. No PowerShell, use diretamente os comandos Docker Compose documentados acima.

## Tecnologias

Python 3.13, Django 5.2, Django REST Framework, PostgreSQL 17, psycopg, Docker e Docker Compose.

## Referências

- [Docker Compose de referência da atividade](https://gist.github.com/drsantos20/c15b99d946fab65a56bcb7f8867c2ef1)
- [Ordem de inicialização dos serviços - Docker](https://docs.docker.com/compose/how-tos/startup-order/)
- [Imagem oficial PostgreSQL](https://hub.docker.com/_/postgres)
- [PostgreSQL no Django](https://docs.djangoproject.com/en/5.2/ref/databases/#postgresql-notes)

## Autor

Bruno Costa Macedo de Almeida
