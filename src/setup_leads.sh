#!/bin/bash
set -o nounset
set -o errexit
set +x

download(){
    local url=$1
    echo -n "    "
    wget -N -c --progress=dot $url 2>&1 | grep --line-buffered "%" | \
        sed -u -e "s,\.,,g" | awk '{printf("\b\b\b\b%4s", $2)}'
    
    echo "Done"
}

download_swift(){
    swift \
      --os-auth-url=${OS_AUTH_URL} \
      --os-username=${OS_USERNAME} \
      --os-password=${OS_PASSWORD} \
      --os-tenant-name=${OS_TENANT_NAME} \
      download ${LEADS_QUERY_ENGINE_CONTAINER_NAME} $1 --skip-identical
    echo "Done"
}

vertx_version=vert.x-2.1.5
path_to_install_vertx=~/bin/
container_name=query_engine



download_domain=http://www.softnet.tuc.gr/~leads/

cd ~
echo "***********************"
echo 'Downloading vertx'
download  https://bintray.com/artifact/download/vertx/downloads/${vertx_version}.tar.gz
echo "***********************"
echo 'Extracting vertx'


mkdir -p ${path_to_install_vertx}
tar -zxvf ${vertx_version}.tar.gz -C ${path_to_install_vertx}


echo "***********************"
echo 'Setting up vertx into bash profile'
SearchTerm=${vertx_version}/bin/
File=~/.profile
if grep -q $SearchTerm $File; then
   echo "$SearchTerm found OK"
else
   echo 'export PATH=$PATH'":${path_to_install_vertx}/${vertx_version}/bin/" >> ${File}
   echo "$SearchTerm inserted into file ${File}"
fi

mkdir -p  ~/.vertx_mods/
export VERTX_MODS=~/.vertx_mods
SearchTerm=${VERTX_MODS}
File=~/.bashrc

if grep -q $SearchTerm $File; then
   echo "$SearchTerm found OK"
else
   echo "export VERTX_MODS=~/.vertx_mods" >> ${File}
    echo "$SearchTerm inserted"
fi

echo "***********************"
echo 'Downloading files list'
echo "***********************"
download_swift files.list

echo "***********************"
echo 'Getting bootStrapper and config'
echo "***********************"
download_swift bootstrap.zip 
unzip -o bootstrap.zip
mkdir -p ~/tmp/
cp -R conf/boot-conf ~/tmp/


mkdir -p zips 
cd zips

echo "***********************"
echo 'Downloading modules'
echo "***********************"

cat ../files.list | xargs -I {} -P 6    swift \
      --os-auth-url=${OS_AUTH_URL} \
      --os-username=${OS_USERNAME} \
      --os-password=${OS_PASSWORD} \
      --os-tenant-name=${OS_TENANT_NAME} \
      download ${LEADS_QUERY_ENGINE_CONTAINER_NAME} {} --skip-identical

#for next in `cat ../files.list`
#do
#    echo "Getting $next from container" 
#    download_swift $next
#done

echo "***********************"
echo 'Decompressing modules'
echo "***********************"


# Find files which has .zip
for file in `ls *.zip`

do
	echo "Found file: ${file} "
	 
	var=${file%*-1*}
	#echo $var 
	dirname="gr.tuc.softnet~${var}~1.0-SNAPSHOT"
	echo -n "Deleting old directory ~/.vertx_mods/$dirname"
	sleep 0.1
	# Create the directory
	rm -rf ~/.vertx_mods/$dirname
	echo -n " Recreating directory, "
	mkdir -p ~/.vertx_mods/$dirname

	sleep 0.1
	# Unzip the zip file from newly created directory
	echo " Unzip files"
	unzip  -q ${file} -d ~/.vertx_mods/${dirname} 
done

cd ..
while true; do
    read -p "Do you wish to run the engine? " yn
    case $yn in
        [Yy]* ) sh ./start_engine.sh;
		break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done



