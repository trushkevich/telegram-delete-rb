This application helps to delete all of your own messages for all group members in a selected telegram group
(without clearing the history, so all the others group members' messages will stay in place -
for that you can just clear the history in your Telegram app).

For now the app is raw and there can be some warnings and errors here and there, in you encounter
something critical pls create a new issue.

# Requirements

- Ruby 2.4+
- Compiled [TDLib](https://github.com/tdlib/td)

# How to build TDLib

Get instructions for your platform at https://tdlib.github.io/td/build.html?language=Ruby

Instructions are being generated with php going to be installed, but it is needed only if you
want to build TDLib documentation locally, so I removed it from the below instructions.

For Ubuntu 18:
```
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install make git zlib1g-dev libssl-dev gperf cmake clang-6.0 libc++-dev libc++abi-dev
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

# How to use

First, you need to create a Telegram app at https://my.telegram.org/apps and get `App api_id` and `App api_hash`. Next, create `.env` file based on `.env.example`:
```
cp .env.example .env
```
and fill the environmental variables with the credentials you have just acquired
```
TG_API_ID=[App api_id]
TG_API_HASH=[App api_hash]
```
You can start the app by running:
```
ruby main.rb
```
After the first launch TDLib will ask you to provide the account phone number, confirmation code, etc.
On the further launches it won't be needed. Session termination to be implemented in order to be able
to switch accounts, until then in order to signout you will need to `rm -rf` `tdlib-ruby` directory
(on Linux `/home/user/.tdlib-ruby`).

After providing correct credentials the app will show your groups list (includes only basic and
super groups - no channels, private or secret chats):
```
AVAILABLE_GROUPS
----------------
1. Group 1
2. Group 2
3. Group 3
```
and will ask to provide a group number.
```
Enter a number of a group where messages should be deleted: 1
```
After submitting a group number there will be shown a confirmation message including information
about the number of your messages that are going to be deleted:
```
Going to delete 345 messages in "Group 1". Are you sure? [Yn]:
```
Answering `Y` will trigger messages deletion (for all group members - that's what I created this thing for),
answering anything else will take you back to the groups list.

For now that is all that the app can do. Some improvements can be added in the future, or can be not.
Feel free to do whatever you want with the code as long as you comply with the
[license](https://github.com/trushkevich/telegram-delete-rb/blob/master/LICENSE).

Oh, and as for exiting the app - just hit `Ctrl+C` (or something similar if you are on Mac).
