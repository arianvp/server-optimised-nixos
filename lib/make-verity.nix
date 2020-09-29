{ runCommand, cryptsetup }:
data: runCommand "${data.name}.verity" {} ''
  mkdir -p $out
  ${cryptsetup}/bin/veritysetup format ${data} $out/verity | awk 'END{print $3}' > $out/hash
''
