{ stdenv, runCommand, systemd, makeVerity, utillinux }:

# makeEFI :: { esp :: drv, root ::: drv} -> drv
{ esp, root }:
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

  verity = makeVerity root;

  espType = partitionType.esp;
  inherit (stdenv.hostPlatform) system;
  rootType = partitionType.root.${system};
  verityType = partitionType.verity.${system};
in

runCommand "efi" {
  nativeBuildInputs = [ utillinux ];
  passthru.verity = verity;
}
  ''
    function size {
      du --block-size 512 --apparent-size $1 | awk '{ print $1}'
    }
    espSize=$(size ${esp})
    echo $espSize
    rootSize=$(size ${root})
    echo $rootSize
    veritySize=$(size ${verity}/verity)
    echo $veritySize

    reserved1=2048
    reserved2=2048

    fullSize=$(($reserved1+$reserved2+$espSize+$rootSize+$veritySize))
    echo $fullSize
    truncate --size $(( $fullSize * 512 )) $out

    hash=$(cat ${verity}/hash)
    hash1=$(cat ${verity}/hash | cut -c1-32  | sed 's/./&-/8;s/./&-/13;s/./&-/18;s/./&-/23')
    hash2=$(cat ${verity}/hash | cut -c33-64 | sed 's/./&-/8;s/./&-/13;s/./&-/18;s/./&-/23')

    sfdisk $out <<EOF
    label: gpt
    start=$reserved1,                         size=$espSize,    type=${espType},    name=${esp}
    start=$(($reserved1+$espSize)),           size=$rootSize,   type=${rootType},   name=${root},   uuid=$hash1, attrs=GUID:60
    start=$(($reserved1+$espSize+$rootSize)), size=$veritySize, type=${verityType}, name=${verity}, uuid=$hash2, attrs=GUID:60
    EOF


    eval $(partx $out --output START,SECTORS --nr 1 --pairs)
    dd conv=notrunc if=${esp}           of=$out seek=$START count=$SECTORS conv=notrunc

    eval $(partx $out --output START,SECTORS --nr 2 --pairs)
    dd conv=notrunc if=${root}          of=$out seek=$START count=$SECTORS conv=notrunc

    eval $(partx $out --output START,SECTORS --nr 3 --pairs)
    dd conv=notrunc if=${verity}/verity of=$out seek=$START count=$SECTORS conv=notrunc

  ''
