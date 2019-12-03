set -x
 (
      build_pwd=$(pwd)
      patch_list=(opp_run_dbg eventlogtool opp_run_release opp_run)
      cd bin
      for bin in ${patch_list[@]}; do
        patchelf \
          --set-rpath \
          $(patchelf --print-rpath $bin                                   | \
            sed -E s,:?/lib\(64\)?:?,,g                                   | \
            sed -E s,:?$build_pwd/lib\(64\)?:?,,g                         | \
            sed -E s,:?\\.:?,,g                                           | \
            sed -E s,$out/lib,$dev/lib,g                                  | \
            sed -E s,$out/lib64,$dev/lib64,g)                               \
          $bin
      done
)
