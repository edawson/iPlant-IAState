bwa=$1

cd ../src/${bwa}
make
rm ../../bin/bwa
cp bwa ../../bin/
