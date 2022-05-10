# Projeto rbb-network.deployment-dkr

Arquivo gerado automaticamente ao configurar o repositório. É exibido automaticamente ao se acessar a página do projeto no GitLab.

Edite-o livremente para registrar informações sobre o projeto e seu ambiente de desenvolvimento.


## Git
Você encontra dicas práticas de Git na página [Git Flight Rules](https://github.com/k88hudson/git-flight-rules).


## Integração Contínua
O arquivo pipeline.yml é utilizado para configurar jobs pipeline do seu sistema.
Versione esse arquivo  no diretório raiz do repositório no Gitlab [ver instruções de configuração](https://gitlab.bndes.net/PADROES-GER-CONFIGURACAO/artefatos/wikis/configuracao-pipeline-para-integracao-continua).

Após dar _push_ do arquivo `pipeline.yml` do projeto, use o seguinte autosserviço do RunDeck para [criar os jobs Jenkins de Integração contínua](https://rundeck.bndes.net/project/Apoio_Desenvolvimento_ATI/job/show/d132e837-9995-4307-9d20-0f876e63a39b).

Abaixo linkamos os jobs de _integração contínua_ no [Jenkins](https://jenkins.bndes.net/):

### [Job Snapshot](https://jenkins.bndes.net/job/APS-rbb-network.deployment-dkr-Snapshot)
Job que é executado automaticamente a cada commit. Compila o código e executa os testes JUnit. Envia e-mails para os desenvolvedores quando o build quebra, e quando volta a funcionar. Caso o build quebre, deve ser consertado o mais rapidamente possível para que não atrapalhar o trabalho dos demais desenvolvedores. Copia a versão snapshot gerada para o repositório Nexus.
Caso sua mensagem de commit tenha na primeira linha a tag _#deploy_, o job de snapshot
automaticamente fará o deploy do binário gerado para o servidor Liberty de DSV.
### [Job Release](https://jenkins.bndes.net/job/APS-rbb-network.deployment-dkr-Release)
Executar quando for gerar novo release. 

Gera uma tag git para marcar a versão do projeto no repositório. Incrementa automaticante o número de versão. Verifica se versão a ser gerada está atualizada com todas as modificações já colocadas em produção, isto é, se o branch em que está sendo gerado o release está sincronizado com o branch _master_. Copia a versão do release para o repositório Nexus. Pode ainda instalar a versão gerada nos ambientes de DSV, HOM e PRD.
Por motivos de auditoria, falhará caso se tente gerar binários com um número de versão já existente. 

### [Job Passagem Produção](https://jenkins.bndes.net/job/APS-rbb-network.deployment-dkr-ProducaoPipeline)
Executar para realizar uma passagem de versão para produção, implantará e criará mudança.
Faz merge de todas as modificações do release para o branch _master_, garantindo assim que a versão mais recente no _master_ é a versão que está em produção e que nenhum código já passado para produção será perdido. Efetiva passagens de aplicações para produção automaticamente após aprovação de gestores do projeto.


## Liberty e RunDeck
### [RunDeck para colocar sistema no ar](https://rundeck.bndes.net/project/Liberty_v2/jobs)
Há um job RunDeck para [implantar um serviço em DSV/TST manualmente](https://rundeck.bndes.net/project/Liberty_v2/job/show/75f38aa2-0c17-447b-980d-dca068e353d2), e outro para [publicar em homologação](https://rundeck.bndes.net/job/show/e59172ac-c210-4685-898d-9215203a0790).

## [Sonar](http://vrt0764:8380/)

O [job do Sonar](https://jenkins.bndes.net/job/APS-rbb-network.deployment-dkr-Sonar/) executa uma vez por dia e executa validações estáticas no código fonte. Assim bugs podem ser identificados antes de acontecerem. 

### Receba notificações do Sonar por email

Você pode configurar o Sonar para te enviar notificações quando um commit seu gerar débitos técnicos. Faça isto em 2 passos. Primeiro selecione os projetos para receber notificações:

![Selecione os projetos](https://gitlab.bndes.net/PADROES-GER-CONFIGURACAO/artefatos/uploads/30fe47b3ac7b1aa8893ea5f2718e591e/image.png)

Depois escolha as notificações a receber:
![Notificações a receber](https://gitlab.bndes.net/PADROES-GER-CONFIGURACAO/artefatos/uploads/eadf929e2266d3cf74cf61d29b0eccde/image.png)
