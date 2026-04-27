# nix-docker-sbx

This repository packages [Docker Sandboxes](https://github.com/docker/sbx-releases) for Nix.

## Usage

Build it:

```bash
nix build
```

Run it:

```bash
nix run
```

The package currently targets `x86_64-linux` and uses the upstream `DockerSandboxes-linux.tar.gz` release asset.

## NixOS

Add it to `configuration.nix` via flake inputs:

```nix
{
  inputs.nix-docker-sbx.url = "github:acomagu/nix-docker-sbx";

  outputs = { self, nixpkgs, nix-docker-sbx, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            nix-docker-sbx.packages.x86_64-linux.default
          ];
        })
      ];
    };
  };
}
```
