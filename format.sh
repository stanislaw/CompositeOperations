#!/bin/bash
#
## dot-clang-format
## version: 0.0.1

folders=("CompositeOperations", "Tests") # Example: ("App" "UnitTests" "IntegrationTests")

objc_files() {
  for folder in "${folders[@]}"
  do
    echo "Seaching for Objective-C files in: $folder/" 1>&2
    find "$folder" -type file -regex "^.*\.[hm]$"
  done
}

prepare() {
  tr "\n" "\0"
}

format() {
  xargs -0 clang-format -i -style=file
}

filter_by() {
  local exp=$@

  if [[ $* == *-e* ]]
  then
    grep $exp
  else
    grep "$exp"
  fi
}

print_found() {
  while read data; do
    echo $data | tee /dev/tty
  done
}

main() {
  if [ $# -eq 0 ]

  # ./format.sh
  then
    objc_files | print_found | prepare | format

  # ./format.sh expression
  else
    exp="$@"
    echo "Using expression: $exp"

    objc_files | filter_by $exp | print_found | prepare | format
  fi
}

main $@
