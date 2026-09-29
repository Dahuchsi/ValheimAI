# Installation design

The finished Windows release is intended to require only **Steam + Valheim** to be installed manually.

`Install-ValheimAI.ps1` currently:

- locates Steam through registry/default paths;
- parses `libraryfolders.vdf` so Valheim can live on another drive;
- verifies AppID 892970 is actually installed;
- detects the Valheim-specific BepInEx pack;
- if missing, downloads the latest `BepInExPack_Valheim` release from its GitHub release feed and installs it into the Valheim directory;
- creates `config/settings.json` without overwriting an existing configuration;
- detects the .NET SDK when building from source;
- builds a self-contained Windows controller when the SDK is available;
- creates `config/install.json` with the detected local paths;
- checks/deploys the ValheimAI plugin when a compiled plugin DLL is available.

## Release target

GitHub Releases will eventually contain a ZIP/installer with the self-contained controller and prebuilt plugin, so end users will not need the .NET SDK, Git, Python, Visual Studio or manual dependency installation.

## Credentials

Steam credentials are never requested. The AI PC should remain signed into its own Steam account. The OpenAI API key is read from `OPENAI_API_KEY` (or another explicitly configured environment-variable name), not committed to configuration.
