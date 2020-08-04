{ runCommand, cryptsetup, }: data: runCommand "${data.name}.verity" {} ''
  mkdir -p $out
  ${cryptsetup}/bin/veritysetup format ${data} $out/${data.name}.verity > $out/${data.name}.hash
''
