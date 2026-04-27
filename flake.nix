{
  description = "Docker Sandboxes flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      version = "0.27.0";
    in
    {
      packages.${system}.default = pkgs.runCommandLocal "docker-sbx-${version}" {
        src = pkgs.fetchzip {
          url = "https://github.com/docker/sbx-releases/releases/download/v${version}/DockerSandboxes-linux.tar.gz";
          hash = "sha256-6ttpG+daTY/7Ims4sHI7BmlDnVQPlicSmdfYRRyUIEQ=";
          stripRoot = true;
        };

        nativeBuildInputs = with pkgs; [
          makeWrapper
          patchelf
        ];

        meta = with pkgs.lib; {
          description = "Docker Sandboxes CLI";
          homepage = "https://github.com/docker/sbx-releases";
          license = licenses.asl20;
          platforms = [ system ];
          mainProgram = "sbx";
        };
      } ''
        mkdir -p "$out/bin" "$out/libexec/lib" "$out/share/doc/docker-sbx"

        install -m755 "$src/sbx" "$out/bin/sbx"
        install -m755 "$src/containerd-shim-nerdbox-v1" "$out/libexec/containerd-shim-nerdbox-v1"
        install -m755 "$src/mkfs.erofs" "$out/libexec/mkfs.erofs"
        install -m755 "$src/libkrun.so" "$out/libexec/lib/libkrun.so"
        install -m644 "$src"/nerdbox-kernel-* "$out/libexec/"
        install -m644 "$src"/nerdbox-initrd-* "$out/libexec/"
        install -m644 "$src/LICENSE" "$src/THIRD-PARTY-NOTICES" "$out/share/doc/docker-sbx/"
        if [ -f "$src/apparmor-profile" ]; then
          install -m644 "$src/apparmor-profile" "$out/libexec/apparmor-profile"
        fi

        rpath=${pkgs.lib.makeLibraryPath [
          pkgs.stdenv.cc.cc.lib
          pkgs.lz4
          pkgs.xxhash
          pkgs.zlib
          pkgs.zstd
        ]}

        patchelf --set-rpath "$rpath" "$out/libexec/mkfs.erofs"
        patchelf --set-rpath "$rpath" "$out/libexec/containerd-shim-nerdbox-v1"
        patchelf --set-rpath "$rpath" "$out/libexec/lib/libkrun.so"

        wrapProgram "$out/bin/sbx" \
          --set LIBKRUN_PATH "$out/libexec" \
          --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.e2fsprogs ]}
      '';

      apps.${system}.default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/sbx";
      };
    };
}
