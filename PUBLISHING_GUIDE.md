# Guia de Publicação — Exportar pro Google Play

## 1. Preparar o ambiente (uma vez só)

1. **JDK 17** — Godot 4.3+ precisa do Java 17 pra build do Android. Instale o
   [Eclipse Temurin JDK 17](https://adoptium.net/) (ou o Java que vem junto
   do Android Studio).
2. **Android Studio** (mais fácil) ou só o **Android SDK Command-line Tools**
   — o Studio já vem com SDK Manager, `adb`, build tools, tudo pronto.
3. No Godot: **Editor → Gerenciar Templates de Exportação** → baixa/instala
   o template da MESMA versão do seu Godot (4.7.1).
4. No Godot: **Editor → Configurações do Editor → Exportação → Android** —
   aponta o caminho do Android SDK e do JDK 17.

## 2. Instalar o template de build customizado (obrigatório pra usar plugins)

Anúncios e compras exigem plugins nativos Android, que só funcionam com
**Custom Build**:

**Projeto → Instalar Modelo de Build do Android** (`Project → Install
Android Build Template`). Isso cria uma pasta `res://android/build/` no
projeto — é ali que os plugins (AdMob, Billing) se instalam.

## 3. Configurar o preset de exportação

**Projeto → Exportar...** → **Adicionar...** → Android:

| Campo | O que colocar |
|---|---|
| Package Name | domínio reverso único, ex: `br.com.therechocolates.chocolataria` — depois de publicado, **nunca muda** |
| Version Code | número inteiro, sobe a cada envio (1, 2, 3...) |
| Version Name | texto visível pro usuário (ex: "1.0.0") |
| Target SDK | use o mais recente que o Godot oferecer — o Google exige o SDK-alvo mais recente possível; se a Play Console recusar no upload, ela avisa exatamente qual API mínima aceita naquele momento |
| Ícones | configure o adaptive icon (foreground + background) — pode usar a arte do `logo_game.png` como base |
| Gradle Build → Use Gradle Build | ✅ ativado (obrigatório pros plugins) |

## 4. Assinatura (keystore)

Pro **primeiro envio**, gere uma keystore de upload:

```bash
keytool -genkeypair -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Guarde esse arquivo e a senha **em local seguro** — se perder, não
consegue mais atualizar o app na Play Store com esse pacote. Configure o
caminho dela em **Projeto → Exportar → Android → Keystore de Release**.

> A Play Store usa "Play App Signing": você assina com essa chave de
> *upload*, e o Google gerencia a chave de assinatura final internamente.
> Isso é o padrão recomendado — não precisa se preocupar em perder a chave
> "de verdade", só a de upload.

## 5. Exportar como AAB (não APK)

A Play Store exige **Android App Bundle (.aab)** pra apps novos, não `.apk`.
No preset de exportação do Godot, escolha o formato **`.aab`** na hora de
exportar (`Export Project`).

## 6. Google Play Console

1. Crie uma conta de desenvolvedor (taxa única de US$25) em
   [play.google.com/console](https://play.google.com/console).
2. **Criar app** → preenche nome, idioma padrão, se é grátis ou pago.
3. **Ficha da loja**: título, descrição curta/longa, ícone (512×512),
   gráfico de destaque (1024×500), screenshots (celular obrigatório).
4. **Classificação de conteúdo**: questionário obrigatório (o jogo não tem
   violência/conteúdo adulto, deve classificar como Livre/todos).
5. **Formulário de segurança de dados**: obrigatório — declare que o app
   coleta/usa dados (se for usar AdMob, ele coleta dados pra anúncios;
   declare isso aqui, o próprio Google te guia pelas perguntas).
6. **Preços e distribuição**: marque **"Contém anúncios"** se for usar
   AdMob, escolha os países.
7. Suba o `.aab` primeiro na trilha de **Teste interno** (Internal
   testing) — mais rápido de liberar, só pra você e uma lista de testadores
   testarem antes de ir pro público.
8. Depois de validado, promove pra **Teste fechado/aberto** e por fim
   **Produção**.

## ⚠️ Um ponto de atenção pro visual do jogo

O Estopa (mascote) e o estilo fofo/carinha do jogo têm apelo bem infantil.
Se esse público for intencional, o Google tem uma política específica pra
apps que atraem crianças (**Families Policy**) — restringe tipos de
anúncio (nada de anúncios comportamentais/personalizados pra menores) e
tem regras extras de dados. Vale revisar
[a política de Famílias do Google Play](https://play.google.com/console/about/families/)
antes de configurar o AdMob, pra escolher o tipo de anúncio certo desde o
início — evita ter que reconfigurar tudo depois de publicado.
