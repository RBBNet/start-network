# rbb-network

## Histórico

Atualmente, existe um ambiente com nodes besu/hyperledger na DMZ, conectados com nodes de outras entidades, formando uma rede RBB "LAB". Esses nodes são acessados pelas seguintes aplicações, que executam no Docker Swarm de DSV:
- rbb-explorer
- rbb-permissionamento
- rbb-identificacao

Essas aplicações consultam informações da blockchain através da interface JSON-RPC/HTTPS dos nodes, com autenticação IP/BasicAuth.
Os nodes besu desse ambiente foram implantados com apoio do BID, utilizando playbooks ansible do projeto LACChain, customizados internamente para nossa infraestrutura.

Foi criado um novo ambiente de nodes besu, com acesso exclusivamente interno, para desenvolvimento de aplicações.
Esse novo ambiente roda inteiramente no Docker Swarm DSV, com scripts desenvolvidos internamente.

## Estrutura

O seguinte grafo expressa "conexões naturais", que tendem a ocorrer por disponibilidade de informações para isso. Não existe garantia de que realmente vão ocorrer todas essas conexões, pois o besu tenta balancear conectividade e uso de banda, dentro dos limites configurados.

```nomnoml
[rbb-network-dsv|
  [bootnodes|
    [boot1]--[boot2]
  ]

  [validators/static-nodes|
    [validator1]
    [validator2]
    [validator3]
    [validator4]
    [validator1]--[validator2]
    [validator3]--[validator4]
    [validator1]--[validator3]
    [validator2]--[validator4]
    [validator1]--[validator4]
    [validator2]--[validator3]
  ]

  [bootnodes]--[writer1]
  [bootnodes]--[writer2]
  [bootnodes]--[validators/static-nodes]
]
```

O arquivo `genesis.json` é populado automaticamente com os endereços dos bootnodes, que também podem ser definidos por variável de ambiente. Dessa forma, todos os nodes tem acesso a lista de bootnodes, e através deles podem encontrar outros nodes para se conectarem.
O arquivo `static-nodes.json` é populado automaticamente com os endereços dos validadores, e esse arquivo é utilizado pelos próprios validadores. Dessa forma, os validadores possuem uma lista estática de todos validadores, e conseguem se conectar entre eles sem necessidade de comunicação para discovery de outros peers. 

## Utilização

### Inicializar uma blockchain local

Execute o seguinte comando:
```bash
commands/blockchain-init
```

Esse comando inicializa a blockchain criando os seguintes arquivos:
- `${VOLUMES_ROOT}/*/key{,.pub}`
  
  Esses são os arquivos com as chaves privadas e públicas dos validadores e boot nodes, que serão inseridos no `genesis.json` e `static-nodes.json`.
  
- `.env.configs/genesis.json`

  Gerado a partir do `.env.configs/init/genesis-config.json`, inserindo automaticamente as chaves públicas dos validadores iniciais no campo `extraData`, e os endereços dos bootnodes no campo `config.discovery.bootnodes`.

- `.env.configs/static-nodes.json`

  Esse arquivo contém a lista de validadores.

Para alterar o número de validadores e boot nodes iniciais, é necessário definir as respectivas variáveis de ambiente, como no comando a seguir:
```bash
env VALIDATOR_COUNT=4 BOOT_COUNT=2 commands/blockchain-init
```
Também é necessário alterar o arquivo `docker-swarm.yml` de acordo.

### Executar métodos RPC em um dos nodes

Execute da seguinte forma:
```bash
# commands/node-rpc <NODE> <MÉTODO> <PARÂMETROS>
# Exemplos:

# consulta informações do node
commands/node-rpc boot1 admin_nodeInfo

# consulta peers conectados
commands/node-rpc writer2 admin_peers

# consulta métricas de assinadores dos blocos
commands/node-rpc validator1 ibft_getSignerMetrics

# consulta votos para novos validadores pendentes
commands/node-rpc validator2 ibft_getPendingVotes

# propõe validador
commands/node-rpc validator3 ibft_proposeValidatorVote '["42d4287eac8078828cf5f3486cfe601a275a49a5", true]'

# consulta validadores que assinaram blocos listados
commands/node-rpc validator4 ibft_getValidatorsByBlockNumber '["485568"]'
```

### Subir os nodes

Execute os seguintes comandos:
```bash
set -a
source .env.defaults
set +a

docker stack deploy -c docker-swarm.yml ${STACK_NAME}
```
