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
  echo "Downloading $1";
  swift \
    --os-auth-url=${OS_AUTH_URL} \
    --os-username=${OS_USERNAME} \
    --os-password=${OS_PASSWORD} \
    --os-tenant-name=${OS_TENANT_NAME} \
    download ${LEADS_QUERY_ENGINE_CONTAINER_NAME} $1 --skip-identical
  echo "Done"
}

#Search if a searchTerm exists in a file, if not, append a string
set_env_(){ #1: searchTerm #2: file #3 inserted string
  echo "***********************"
  echo "Setting up $1 into $2 file"
  SearchTerm=$1
  File=$2
  if grep -q $SearchTerm $File; then
    echo "$SearchTerm found, no changes"
  else
    echo "$3" >> ${File}
    echo "$3 inserted into file ${File}"
  fi
}
#Check if env variable already exists
: ${LEADS_QUERY_ENGINE_CONTAINER_NAME:='query_engine'}

vertx_version=vert.x-2.1.5
path_to_install_vertx=~/bin

cd ~
echo "***********************"
echo 'Downloading vertx'
download  https://bintray.com/artifact/download/vertx/downloads/${vertx_version}.tar.gz

echo "***********************"
echo 'Extracting vertx'
mkdir -p ${path_to_install_vertx}
tar -zxvf ${vertx_version}.tar.gz -C ${path_to_install_vertx}

# echo "***********************"
# echo 'Setting up LEADS_CURRENT_CLUSTER variable '
# command_string="export LEADS_CURRENT_CLUSTER=\`cat ~/micro_cloud.txt\`"
# search_term="LEADS_CURRENT_CLUSTER"
# file=~/.bashrc
# set_env_ "${search_term}" "${file}" "${command_string}"

echo "***********************"
echo 'Setting up vertx variables'
search_term=${vertx_version}/bin/
file=~/.profile
command_string='export PATH=$PATH'":${path_to_install_vertx}/${vertx_version}/bin/"
set_env_  "${search_term}" "${file}" "${command_string}"

mkdir -p  ~/.vertx_mods/
export VERTX_MODS=~/.vertx_mods

search_term="VERTX_MODS=~/.vertx_mods"
file=~/.bashrc
command_string="export VERTX_MODS=~/.vertx_mods"
set_env_  "${search_term}" "${file}" "${command_string}"

search_term="dont_care"
file=~/.bashrc
command_string="export LEADS_QUERY_ENGINE_CONTAINER_NAME=$LEADS_QUERY_ENGINE_CONTAINER_NAME"

if [ -z ${LEADS_QUERY_ENGINE_CONTAINER_NAME+x} ]; then 
  set_env_  "${search_term}" "${file}" "${command_string}";
fi

command_string="export LEADS_QUERY_ENGINE_HADOOP_FS=$LEADS_QUERY_ENGINE_HADOOP_FS"
if [ -z ${LEADS_QUERY_ENGINE_HADOOP_FS+x} ]; then 
  set_env_  "${search_term}" "${file}" "${command_string}"
fi

command_string="export LEADS_QUERY_ENGINE_UCLOUD_NAME=$LEADS_QUERY_ENGINE_UCLOUD_NAME"
if [ -z ${LEADS_QUERY_ENGINE_UCLOUD_NAME+x} ]; then 
  set_env_  "${search_term}" "${file}" "${command_string}"
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
#mkdir -p ~/tmp/
#cp -R bootstrap/* ~/
cp -R conf/boot-conf /tmp/

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
echo "Downloading  Completed"

echo "***********************"
echo 'Decompressing modules'
echo "***********************"

# Find files which has .zip
for file in `ls *.zip` do
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
  # Unzip the zip file from newly created directory
  echo " Unzip files"
  unzip  -q ${file} -d ~/.vertx_mods/${dirname} 
done

cd ..
while true; do
  yn=${LEADS_QUERY_ENGINE_START}
  case $yn in
    [Yy]* ) sh ./start_engine.sh;
      break;;
    [Nn]* ) exit;;
    * ) echo "Please answer yes or no.";;
  esac
done
