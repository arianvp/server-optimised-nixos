{ stdenv, systemd, makeSquashfs, makeVerity, utillinux }:
# { boot, root, verity }:
let
  partitionType = {
    root = {
      "x86_64-linux" = "4f68bce3-e8cd-4db1-96e7-fbcaf984b709";
      "aarch64-linux" = "b921b045-1df0-41c3-af44-4c6f280d3fae";

    };
    verity = {
      "x86_64-linux" = "2c7357ed-ebd2-46d9-aec1-23d437ec2bf5";
      "aarch64-linux" = "df3300ce-d69f-4c92-978c-9bfb0f38d820";
    };
    esp = "c12a7328-f81f-11d2-ba4b-00a0c93ec93b";
  };

  contents = makeSquashfs { storeContents = systemd; };
  verity = makeVerity contents;

in

stdenv.mkDerivation {
  name = "efi";
  nativeBuildInputs = [
    utillinux
  ];
  buildCommand = ''
    squashfsSize=$(du -B 512 --apparent-size ${contents} | awk '{ print $1 }')
    truncate --size $(( (2048 + $squashfsSize + 4096 + 1024) * 512 )) $out
    du -h  --apparent-size $out
    sfdisk $out <<EOF
    label: gpt

    size=$squashfsSize type=${partitionType.root.${stdenv.targetPlatform.system}}
    size=4096 type=${partitionType.esp}
    EOF

    eval $(partx $out -o START,SECTORS --nr 1 --pairs)
    dd conv=notrunc if=${contents} of=$out seek=$START count=$SECTORS conv=notrunc

    # eval $(partx $out -o START,SECTORS --nr 2 --pairs)
    # dd conv=notrunc if=/dev/zero of=$out seek=$START count=$SECTORS conv=notrunc
  '';
}
