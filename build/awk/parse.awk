BEGIN {
  scan_armed=0
}

{
  if ($0 == "--------------------------------------") {
      # do something
      scan_armed=1
  }
  else {
      # do something other
      if (scan_armed) {
        # then-body
        if($0 ~ "^[^ \t]"&&$0 !~ ":" && $0 !~ "system-images" && $0 !~ "sources" && $0 !~ "emulator" && $0 !~ "docs" && $0 !~ "ndk-bundle"){
          if($0 !~ "platforms;android-1[01234]" && $0 !~ "platforms;android-P" && $0 !~ "platforms;android-[123456789]$" && $0 !~ "build-tools;1[789]"){
              print($0)
          }
        }
      }
  }
}