<p align="center">
<br/>
<a href="nixified.ai">
  <img src="https://github.com/nixified-ai/flake/blob/images/nixified.ai-text.png" width=60% height=60% title="nixified.ai"/>
</a>
</p>

---

## Discussion

Anyone interested in discussing nixified.ai in realtime can join our matrix channel

- In a Matrix client you can type `/join #nixified.ai:matrix.org`
- Via the web you can join via https://matrix.to/#/#nixified.ai:matrix.org

## The Goal

The goal of nixified.ai is to simplify and make available a large repository of
AI executable code that would otherwise be impractical to run yourself, due to
package management and complexity issues.

The outputs run primarily on Linux, but can also run on Windows via [NixOS-WSL](https://github.com/nix-community/NixOS-WSL). It is able to utilize the GPU of the Windows host automatically, as our wrapper script sets `LD_LIBRARY_PATH` to make use of the host drivers.

The main outputs of the `flake.nix` at the moment are as follows:

## [ComfyUI](https://github.com/comfyanonymous/ComfyUI) ( A modular, node-based Stable Diffusion WebUI )

If you want to quickly get up and running, you have the option of using the packages meant to serve the [Krita AI plugin](https://github.com/Acly/krita-ai-diffusion), but the flake also provides ways to customise your setup.

`export vendor=amd` or `export vendor=nvidia` depending on your GPU.

### Pre-configured server

If you want to quickly get started with a pre-configured setup, you can run these ones made to serve the Krita plugin (Krita is not required to use it):
- `nix run .#krita-comfyui-server-${vendor}-minimal` - includes the bare minimum requirements
- `nix run .#krita-comfyui-server-${vendor}` - a fully featured server to provide all functionality available through the plugin

Personal model sets and custom nodes can be easily defined by referencing [./projects/comfyui/](./projects/comfyui/){models,custom-nodes}/default.nix, using `mergeModels` to merge model sets and the `//` operator to merge custom nodes.

### Custom setup

You can use the following utilities from `legacyPackages.x86_64-linux.comfyui.${vendor}`:
- `withConfig` - a function which takes as an argument a function from available `models` and `customNodes` to a configuration, including which models and custom nodes you want to use - for example: `withConfig (plugins: { outputPath = "/tmp/comfyui-outputs"; customNodes = { inherit (plugins.customNodes) ultimate-sd-upscale; }; models.checkpoints = { inherit (plugins.models.checkpoints) pony-xl-v6; }; })`
- `kritaModels.required` - misc models expected by the plugin
- `kritaModels.optional` - misc models needed for all optional features of the plugin
- `kritaServerWithModels` - a function which takes as an argument a function from available `models` to models to include in the setup, e.g. `models: { checkpoints = { inherit (models.checkpoints) ...; }; ... }`
- `mergeModels` - a utility function to merge model sets, which can be used like so: `kritaServerWithModels (ms: mergeModels [ kritaModels.optional (import ./my-models.nix {inherit lib;}) ])`

and in the same attribute set you will also find these:
- `models` - the full model set included in this flake (see [./projects/comfyui/models/default.nix](./projects/comfyui/models/default.nix))
- `customNodes` - the full set of available custom nodes (see [./projects/comfyui/custom-nodes/default.nix](./projects/comfyui/custom-nodes/default.nix))
- `kritaCustomNodes` - the subset of `customNodes` relevant to the Krita plugin (see [./projects/comfyui/custom-nodes/krita-ai-plugin.nix](./projects/comfyui/custom-nodes/krita-ai-plugin.nix))

The options of `withConfig` (and their defaults) can be seen in [./projects/comfyui/package.nix](./projects/comfyui/package.nix):
```nix
{
  ...,
  basePath ? "/var/lib/comfyui",
  inputPath ? "${basePath}/input",
  outputPath ? "${basePath}/output",
  tempPath ? "${basePath}/temp",
  userPath ? "${basePath}/user",
}: ...
```

## [InvokeAI](https://github.com/invoke-ai/InvokeAI) ( A Stable Diffusion WebUI )

- `nix run .#invokeai-amd`
- `nix run .#invokeai-nvidia`

![invokeai](https://raw.githubusercontent.com/nixified-ai/flake/images/invokeai.webp)

## [textgen](https://github.com/oobabooga/text-generation-webui) ( Also called text-generation-webui: A WebUI for LLMs and LoRA training )

- `nix run .#textgen-amd`
- `nix run .#textgen-nvidia`

![textgen](https://raw.githubusercontent.com/nixified-ai/flake/images/textgen.webp)

## Install NixOS-WSL in Windows

If you're interested in running nixified.ai in the Windows Subsystem for Linux, you'll need to enable the WSL and then install NixOS-WSL via it. We provide a script that will do everything for you.

1. Execute the following in Powershell

   `Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/nixified-ai/flake/master/install.ps1'))`

The WSL must be installed via the Windows Store. The script will make an attempt to enable it automatically, but this only works on a fresh system, not one that has been modified manually.

See the following documentation from Microsoft for the details on how to enable and use the WSL manually

- https://learn.microsoft.com/en-us/windows/wsl/install

## Enable binary cache

To make the binary substitution work and save you some time building packages, you need to tell nix to trust nixified-ai's binary cache.
On nixos you can do that by adding these 2 lines to `/etc/nixos/configuration.nix` and rebuilding your system:

    nix.settings.trusted-substituters = ["https://ai.cachix.org"];
    nix.settings.trusted-public-keys = ["ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="];

If you are on another distro, just add these two lines to `/etc/nix/nix.conf`. In fact the line `trusted-public-keys = ...` should already be there and you only need to append the key for ai.cachix.org.

    trusted-substituters = https://ai.cachix.org
    trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc=


