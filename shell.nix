{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    nativeBuildInputs = with pkgs; [
      nasm
      gnumake
      qemu
      vim
      mtools    
      dosfstools
    ];
}
