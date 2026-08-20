# Guia de Publicação — iPhone / App Store

## ⚠️ O requisito que não tem como contornar

**Exportar pra iOS exige um Mac com Xcode instalado.** Isso não é
limitação do Godot — é a Apple que só permite compilar/assinar apps iOS
através do Xcode, que só roda em macOS. Não existe caminho pelo Windows
ou Linux, nem com o projeto 100% pronto.

Se você não tem um Mac, as opções mais comuns são:
- Pedir emprestado ou comprar um Mac mini (é a opção mais barata da linha)
- Alugar um "Mac na nuvem" (MacStadium, MacinCloud, etc.)
- Usar GitHub Actions com runner `macos-latest` — dá pra automatizar todo
  o processo de export+build sem precisar logar num Mac manualmente (tem
  uma Action pronta pra isso: `dulvui/godot4-ios-export`)

## 1. Preparar o ambiente (no Mac)

1. Instale o **Xcode** mais recente pela Mac App Store (a Apple não aceita
   mais builds feitos com versões antigas — confirme que está numa versão
   atual antes de submeter).
2. No Godot: **Editor → Gerenciar Templates de Exportação** → baixa o
   template da mesma versão do engine.
3. Tenha em mãos, do [developer.apple.com](https://developer.apple.com)
   (conta de desenvolvedor Apple, US$99/ano):
   - **App Store Team ID** — código de 10 caracteres tipo `ABCDE12XYZ`
     (aparece do lado do seu nome, no canto superior direito do site)
   - **Bundle Identifier** — mesmo esquema do Android, domínio reverso
     único (ex: `br.com.therechocolates.chocolataria`) — cadastre em
     **Certificates, Identifiers & Profiles** antes de exportar

## 2. Exportar do Godot

Este pacote já vem com um `export_presets.cfg` inicial na raiz do projeto
(preset "iOS" configurado com o Bundle ID de vocês). **Mas antes de rodar
em CI (Codemagic, GitHub Actions), abra o projeto uma vez no Godot** — em
qualquer sistema operacional, não precisa ser Mac só pra esse passo — e:

1. **Projeto → Exportar...** → seleciona o preset "iOS"
2. Preenche o **App Store Team ID** (o código de 10 caracteres tipo
   `ABCDE12XYZ`, fica do lado do seu nome em developer.apple.com — não
   deixei preenchido porque é específico da conta de vocês)
3. Clica em **Fechar** (isso já salva o arquivo)
4. Commita esse `export_presets.cfg` atualizado e sobe pro repositório

Isso importa porque eu escrevi esse arquivo à mão (não tenho como abrir o
Godot aqui pra gerar oficialmente) — abrir e salvar uma vez deixa o
**próprio Godot** completar/corrigir qualquer chave que eu tenha errado ou
que sua versão específica espere diferente, em vez de confiar 100% no que
eu digitei às cegas.

Depois disso, **Projeto → Exportar → Adicionar... → iOS** (se quiser
confirmar que já está tudo certo) gera um **projeto Xcode**, não um app
pronto — o build de verdade acontece no passo seguinte.

## 3. Abrir e compilar no Xcode

1. Abre o `.xcodeproj` gerado.
2. Em **Signing & Capabilities**, seleciona seu Team e deixa o Xcode
   gerenciar o provisionamento automaticamente (mais simples que fazer na
   mão).
3. Escolhe **Any iOS Device** como destino → **Product → Archive**.
4. Na janela de Organizer que abre depois do archive, **Distribute App →
   App Store Connect**.

## 4. O arquivo de privacidade que a Apple exige (obrigatório desde 2024)

Toda submissão precisa de um arquivo **`PrivacyInfo.xcprivacy`** dentro
do projeto Xcode, declarando quais dados o app coleta e por quê. **O
Godot não gera isso sozinho** — é um passo manual seu, direto no Xcode:

1. No Xcode: **File → New → File... → App Privacy** (categoria Resource)
2. Adiciona ao target do app
3. Preenche as seções conforme o que o jogo realmente faz:
   - Se não tiver anúncios/IAP ainda: declara que não coleta dados de
     rastreamento
   - Se tiver AdMob: o SDK já vem com o próprio `PrivacyInfo.xcprivacy`
     dele — o Xcode combina automaticamente com o seu na hora do build,
     mas você ainda precisa ter o seu próprio arquivo pro que o *seu*
     código faz (ex: salvar o jogo localmente)

Sem esse arquivo, a Apple **rejeita a submissão automaticamente** — não
é um aviso, é bloqueio direto.

## 5. App Tracking Transparency (só se for usar anúncios personalizados)

Se integrar o AdMob com anúncios personalizados (usa o IDFA — identificador
de publicidade do iPhone), a Apple exige mostrar o prompt nativo de
permissão ("Allow tracking?") **antes** de pedir qualquer anúncio
rastreado. Sem esse prompt, a Apple rejeita. O jeito mais simples de evitar
essa complexidade inteira: configure o AdMob pra servir só **anúncios não
personalizados** no início — funciona sem precisar do prompt de rastreio,
embora pague um pouco menos por anúncio.

## 6. App Store Connect

1. Cria o app em [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   com o mesmo Bundle Identifier do passo 1.
2. Preenche a ficha: nome, descrição, categoria, screenshots (a Apple
   pede telas em vários tamanhos — pelo menos iPhone 6.9" e 6.5"; o
   simulador do Xcode gera essas capturas fácil).
3. **Classificação etária**: questionário parecido com o do Google Play.
4. **Privacidade** (App Privacy, na ficha do app): declare os mesmos
   dados do `PrivacyInfo.xcprivacy` — isso vira o "rótulo de privacidade"
   que aparece pro usuário na página do app.
5. Sobe o build (feito automaticamente pelo Xcode Organizer no passo 3).
6. **Recomendado**: manda primeiro pro **TestFlight** (é a mesma
   submissão, só marca "só teste" em vez de "produção") — a Apple libera
   TestFlight bem mais rápido que revisão de produção, e você testa no
   iPhone de verdade antes de liberar pra todo mundo.
7. Depois de validado no TestFlight, envia pra revisão de produção. A
   Apple costuma revisar em 24–48h (mas pode variar).

## Diferenças importantes vs. Android (que já fizemos)

| | Android | iOS |
|---|---|---|
| Onde exportar | Qualquer SO | **Só macOS** |
| Formato de build | `.aab` | Projeto Xcode → `.ipa` (feito no Xcode) |
| Loja de compras (IAP) | Google Play Billing | StoreKit — **veja MONETIZATION_GUIDE.md**, o plugin mudou |
| Arquivo de privacidade | Formulário dentro da Play Console | `PrivacyInfo.xcprivacy` dentro do projeto Xcode |
| Teste antes de produção | Teste interno | TestFlight |
| Taxa de conta | Única, US$25 | Anual, US$99 |

## Sobre o cabeçalho: já ajustei a UI pra iPhone

Aumentei as margens do layout principal (topo 52px, base 32px) pra dar
espaço de sobra pro notch/Dynamic Island e pra barra de gestos do iPhone —
isso é uma margem estática segura, não é cálculo dinâmico da área segura
do dispositivo. Teste no simulador do Xcode (ou num iPhone de verdade) e
ajuste esses números em `scenes/Main.tscn` → node `MarginContainer` se
sobrar ou faltar espaço no seu aparelho específico.
