rm -rf /opt/ANDRAX/binwalk

python3 -m venv /opt/ANDRAX/binwalk

apt update

if [ $? -eq 0 ]
then
  # Result is OK! Just continue...
  echo "Apt update... PASS!"
else
  # houston we have a problem
  exit 1
fi

apt install -y 7zip zstd srecord tar unzip sleuthkit cabextract curl wget git lz4 lzop unrar unyaffs build-essential clang liblzo2-dev libucl-dev liblz4-dev libbz2-dev zlib1g-dev libfontconfig1-dev liblzma-dev libssl-dev cpio device-tree-compiler

if [ $? -eq 0 ]
then
  # Result is OK! Just continue...
  echo "Apt install required packages... PASS!"
else
  # houston we have a problem
  exit 1
fi

DEFAULTDIR=$(pwd)

source /opt/ANDRAX/binwalk/bin/activate

/opt/ANDRAX/binwalk/bin/pip3 install uefi_firmware jefferson ubi-reader
/opt/ANDRAX/binwalk/bin/pip3 install --upgrade lz4 zstandard git+https://github.com/clubby789/python-lzo@b4e39df
/opt/ANDRAX/binwalk/bin/pip3 install --upgrade git+https://github.com/marin-m/vmlinux-to-elf

if [ $? -eq 0 ]
then
  # Result is OK! Just continue...
  echo "Pip3 install requirements... PASS!"
else
  # houston we have a problem
  exit 1
fi

curl -L -o sasquatch_1.0.deb "https://github.com/onekey-sec/sasquatch/releases/download/sasquatch-v4.5.1-4/sasquatch_1.0_$(dpkg --print-architecture).deb"
dpkg -i sasquatch_1.0.deb

if [ $? -eq 0 ]
then
  # Result is OK! Just continue...
  echo "Sasquatch install... PASS!"
else
  # houston we have a problem
  exit 1
fi

rm sasquatch_1.0.deb

TIME=`date +%s`
INSTALL_LOCATION=/usr/local/bin

git clone --quiet --depth 1 --branch "master" https://github.com/npitre/cramfs-tools
(cd cramfs-tools && make && install mkcramfs $INSTALL_LOCATION && install cramfsck $INSTALL_LOCATION)

if [ $? -eq 0 ]
then
  # Result is OK! Just continue...
  echo "Cramfs-tools install... PASS!"
else
  # houston we have a problem
  exit 1
fi

cd $DEFAULTDIR

mkdir tmp-build

cd tmp-build

git clone https://github.com/askac/dumpifs.git
cd dumpifs
make dumpifs
cp ./dumpifs /usr/local/bin/dumpifs

if [ $? -eq 0 ]
then
  # Result is OK! Just continue...
  echo "Install dumpifs... PASS!"
else
  # houston we have a problem
  exit 1
fi

cd ..

git clone https://github.com/lzfse/lzfse.git
cd lzfse
make install

if [ $? -eq 0 ]
then
  # Result is OK! Just continue...
  echo "Install lzfse... PASS!"
else
  # houston we have a problem
  exit 1
fi

cd ..

git clone https://github.com/Lekensteyn/dmg2img.git
cd dmg2img
make dmg2img HAVE_LZFSE=1
make install

if [ $? -eq 0 ]
then
  # Result is OK! Just continue...
  echo "Install dmg2img... PASS!"
else
  # houston we have a problem
  exit 1
fi

cd ..

if [ $(uname -m | grep 'x86_64') ]; then
   wget https://www.7-zip.org/a/7z2409-linux-x64.tar.xz
   tar -xf 7z2409-linux-x64.tar.xz
   if [ $? -eq 0 ]
   then
     # Result is OK! Just continue...
     echo "Download 7-zip static... PASS!"
   else
     # houston we have a problem
     exit 1
   fi
else
   wget https://www.7-zip.org/a/7z2409-linux-arm64.tar.xz
   tar -xf 7z2409-linux-arm64.tar.xz
   if [ $? -eq 0 ]
   then
     # Result is OK! Just continue...
     echo "Download 7-zip static... PASS!"
   else
     # houston we have a problem
     exit 1
   fi
fi

cp 7zzs /usr/local/bin/

cd $DEFAULTDIR

rm -rf tmp-build

cargo build --release

if [ $? -eq 0 ]
then
  # Result is OK! Just continue...
  echo "Cargo build... PASS!"
else
  # houston we have a problem
  exit 1
fi

mkdir /opt/ANDRAX/binwalk/package
cp -Rf target/release/binwalk /opt/ANDRAX/binwalk/package

if [ $? -eq 0 ]
then
  # Result is OK! Just continue...
  echo "Copy binwalk... PASS!"
else
  # houston we have a problem
  exit 1
fi

cp -Rf andraxbin/* /opt/ANDRAX/bin
