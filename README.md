This application helps to delete all own messages for all group members in a selected telegram group.

# Requirements

- Ruby 2.4+
- Compiled [TDLib](https://github.com/tdlib/td)

# How to build TDLib

Get instructions for your platform at https://tdlib.github.io/td/build.html?language=Ruby

For Ubuntu 18:
```
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install make git zlib1g-dev libssl-dev gperf php cmake clang-6.0 libc++-dev libc++abi-dev
git clone https://github.com/tdlib/td.git
cd td
git checkout v1.6.0 # <--- (optional) checkout to a stable release
rm -rf build
mkdir build
cd build
export CXXFLAGS="-stdlib=libc++"
CC=/usr/bin/clang-6.0 CXX=/usr/bin/clang++-6.0 cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=../tdlib -DTD_ENABLE_LTO=ON -DCMAKE_AR=/usr/bin/llvm-ar-6.0 -DCMAKE_NM=/usr/bin/llvm-nm-6.0 -DCMAKE_OBJDUMP=/usr/bin/llvm-objdump-6.0 -DCMAKE_RANLIB=/usr/bin/llvm-ranlib-6.0 ..
cmake --build . --target install
cd ..
cd ..
ls -l td/tdlib
```
Then move `libtdjson.so` and `libtdjson.so.[1.6.0]` to `lib/libtdjson`
