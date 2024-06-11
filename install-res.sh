#/usr/bin/env sh

# The rom version we are dealing with
VERSION="us"  # at the moment only US is supported and has been tested in Portmaster

# Path to game directory
ROOT_PATH="${PWD}/.."

# TOOLBOX PATHS
RESTOOL_ROOT="${PWD}"
RESTOOL_BIN="bin"
RESTOOL_LIB="lib"

# Main sources for building and assembling the ressources
MAIN_ZIP="main.zip"
MAIN_DIR="main"

# This is were the ressources will be built and assembled
BUILD_DIR="${RESTOOL_ROOT}/${MAIN_DIR}/build/us_pc"

# Where we put build log
BUILD_LOG="${RESTOOL_ROOT}/build.log"

# Path to compressed ackages (zip / mp3)
PACKAGES_DIR="packages"

# Ressources stuffs
BASEZIP="base.zip"
DEMOS_DIR="demos"
TEXTS_DIR="texts"
RESSOURCES_LST="${BASEZIP} ${DEMOS_DIR} ${TEXTS_DIR}"

# This is the ressource folder name
RES_DIR="res"

# Dynos stuffs
DYNOS_DIR="dynos"
PACKS_DIR="packs"

# Create res folder
echo "$0: (EXEC) mkdir -p \"${ROOT_PATH}/${RES_DIR}\""
mkdir -p "${ROOT_PATH}/${RES_DIR}"

# Create dynos folders
echo "$0: (EXEC) mkdir -p \"${ROOT_PATH}/${DYNOS_DIR}\""
mkdir -p "${ROOT_PATH}/${DYNOS_DIR}"
echo "$0: (EXEC) mkdir -p \"${ROOT_PATH}/${DYNOS_DIR}/${PACKS_DIR}\""
mkdir -p "${ROOT_PATH}/${DYNOS_DIR}/${PACKS_DIR}"

# Setup bin and library paths
export PATH="${RESTOOL_ROOT}/${RESTOOL_BIN}:$PATH"
export LD_LIBRARY_PATH="${RESTOOL_ROOT}/${RESTOOL_LIB}:${LD_LIBRARY_PATH}"

# Check if a rom file is present
if [ ! -f $ROOT_PATH/baserom.$VERSION.z64 ]
then
  echo "$0: No baserom.${VERSION}.z64 file is present. No installation of ressources will be performed"

  echo "$0: Will stop here"
  exit 0
fi

echo "$0: Okey dokey! baserom.${VERSION}.z64 file is present. Installation of ressources will start"

echo "$0: Here we go!"

if [ ! -d ${MAIN_DIR} ]
then

  echo "$0: Inflating main sources"
  echo "$0: (EXEC) unzip ${MAIN_ZIP}"

  # unzip main sources
  unzip ${MAIN_ZIP}

  if [ ! $? -eq 0 ]
  then
    echo "$0: An error occured while extracting main sources from ${MAIN_ZIP}"

    echo "$0: Will stop here"
    rm -rf ${MAIN_DIR}
    exit 0
  fi

fi

echo "$0: Let clean the workspace just in case"

echo "$0: (EXEC) make distclean"

date >> ${BUILD_LOG}

cd "${MAIN_DIR}"

make distclean >> ${BUILD_LOG}

echo "$0: (EXEC) mv \"${ROOT_PATH}/baserom.${VERSION}.z64\" ."
mv "${ROOT_PATH}/baserom.${VERSION}.z64" .

# We run manually the asset extraction script (Makefile can do it) because we 
# want to watch the result of this step before going any further
echo "$0: (EXEC) ./extract_assets.py us"
./extract_assets.py us 2>&1 >> ${BUILD_LOG}

if [ ! $? -eq 0 ]
then
  echo "$0: Oh, no! Extraction of the assets from the rom has failed"
  echo -n "$0: check that sha1 of baserom.us.z64 is"
  cat sm64.us.sha1 | cut -d' ' -f1

  # We rename the file to indicate there is an issue and we don't want to run the extraction process
  echo "$0: (EXEC) mv \"baserom.${VERSION}.z64\" \"${ROOT_PATH}/baserom.${VERSION}.z64.NOK\""
  mv "baserom.$VERSION.z64" "${ROOT_PATH}/baserom.$VERSION.z64.NOK"

  echo "$0: Game over! Will stop here"
  exit 1
fi

# We put back the rom but we rename it because we don't want to extract it again
echo "$0: (EXEC) mv \"baserom.$VERSION.z64\" \"${ROOT_PATH}/baserom.$VERSION.z64.EXTRACTED\""
mv "baserom.$VERSION.z64" "${ROOT_PATH}/baserom.$VERSION.z64.EXTRACTED"

echo "$0: Yahoo! Assets have been extracted from the rom, let's build and assemble the ressources"
echo "$0: (EXEC) make res"

make res  >> ${BUILD_LOG}

if [ ! $? -eq 0 ]
then
  echo "$0: Oh, no! An error occured while building and assembling the ressources"

  echo "$0: Game over! Will stop here"
  exit 1
fi

echo "$0: ressources are ready, let's install them"

cd "${RESTOOL_ROOT}"

TS=$(date +%s)

for ressource in ${RESSOURCES_LST}
do

  if [ -f "$ROOT_PATH/$RES_DIR/$ressource" ] || [ -d "$ROOT_PATH/$RES_DIR/$ressource" ]
  then
    echo "$0: ressource ${ressource} is already present, let's backup it first";
    echo "$0: (EXEC) mv \"${ROOT_PATH}/${RES_DIR}/${ressource}\" \"${ROOT_PATH}/${RES_DIR}/${ressource}-backup-${TS}\"";
    mv "${ROOT_PATH}/${RES_DIR}/${ressource}" "${ROOT_PATH}/${RES_DIR}/${ressource}-backup-${TS}"
  fi

  echo "$0: (EXEC) mv \"${BUILD_DIR}/${RES_DIR}/${ressource}\" \"${ROOT_PATH}/${RES_DIR}/\""
  mv "${BUILD_DIR}/${RES_DIR}/${ressource}" "${ROOT_PATH}/${RES_DIR}/"

  if [ ! $? -eq 0 ]
  then
    echo "$0: Oh, no! An error occured while installing ${ressource}"

    echo "$0: Game over! Will stop here"
    exit 1
  fi

done

echo "$0: let's see if we have zip or mp3 packages to install"

for respack in ${PACKAGES_DIR}/${RES_DIR}/*.zip
do
  ressource="$(basename ${respack} .zip)"

  if [ -f "$ROOT_PATH/$RES_DIR/$ressource" ] || [ -d "$ROOT_PATH/$RES_DIR/$ressource" ]
  then
    echo "$0: ressource ${ressource} is already present, let's backup it first";
    echo "$0: (EXEC) mv \"${ROOT_PATH}/${RES_DIR}/${ressource}\" \"${ROOT_PATH}/${RES_DIR}/${ressource}-backup-${TS}\"";
    mv "${ROOT_PATH}/${RES_DIR}/${ressource}" "${ROOT_PATH}/${RES_DIR}/${ressource}-backup-${TS}"
  fi

  echo "$0: (EXEC) unzip \"${PACKAGES_DIR}/${RES_DIR}/${ressource}.zip\" -d \"${ROOT_PATH}/${RES_DIR}/\""
  unzip "${PACKAGES_DIR}/${RES_DIR}/${ressource}.zip" -d  "${ROOT_PATH}/${RES_DIR}/"

  if [ ! $? -eq 0 ]
  then
    echo "$0: Oh, no! An error occured while unpacking ${ressource}.zip"

    echo "$0: Game over! Will stop here"
    exit 1
  fi
done

for dynospack in ${PACKAGES_DIR}/${DYNOS_DIR}/*
do
  zip=`[[ "$dynospack" =~ ".zip" ]] && echo 1 || echo 0`
  mp3=`[[ "$dynospack" =~ ".mp3" ]] && echo 1 || echo 0`
  audio=`[[ "$dynospack" =~ "audio" ]] && echo 1 || echo 0`

  if [ $audio -eq 1 ]
  then
    dynospack="$(basename ${dynospack} .mp3)"
    if [ -d "$ROOT_PATH/$DYNOS_DIR/$dynospack" ]
    then
      echo "$0: Dynos pack $dynospack is already present, let's backup it first";
      echo "$0: (EXEC) mv \"${ROOT_PATH}/${DYNOS_DIR}/${dynospack}\" \"${ROOT_PATH}/${DYNOS_DIR}/${dynospack}-backup-${TS}\"";
      mv "${ROOT_PATH}/${DYNOS_DIR}/${dynospack}" "${ROOT_PATH}/${DYNOS_DIR}/${dynospack}-backup-${TS}"
    fi

    if [ $mp3 -eq 1 ]
    then

      mkdir -p "${ROOT_PATH}/${DYNOS_DIR}/${dynospack}"
      cd "${PACKAGES_DIR}/${DYNOS_DIR}/${dynospack}.mp3"
      rm -f mp3.nok
      find . -iname '*.txt' -exec cp {} "${ROOT_PATH}/${DYNOS_DIR}/${dynospack}/{}" \;
      find . -type d -exec mkdir -p "${ROOT_PATH}/${DYNOS_DIR}/${dynospack}/{}" \;
      find . -iname '*.mp3' -exec sh -c 'mpg123 -q -w "$2/${1%.*}.wav" "$1" || touch mp3.nok' sh {} "${ROOT_PATH}/${DYNOS_DIR}/${dynospack}" \; 2>&1 > mpg123.log
      
      if [ -f "mp3.nok" ]
      then
        rm -f mp3.nok
        echo "$0: Oh, no! An error occured while unpacking ${dynospack}.mp3"

        echo "$0: Game over! Will stop here"
        exit 1
      fi

      cd ${RESTOOL_ROOT}

    else

      echo "$0: (EXEC) cp -R \"${PACKAGES_DIR}/${dynospack}\" \"${ROOT_PATH}/${DYNOS_DIR}/\""
      cp -R "${PACKAGES_DIR}/${dynospack}" "${ROOT_PATH}/${DYNOS_DIR}/"

      if [ ! $? -eq 1 ]
      then
        echo "$0: Oh, no! An error occured while installing ${dynospack}"

        echo "$0: Game over! Will stop here"
        exit 1
      fi

    fi

  else

    if [ $zip -eq 1 ]
    then
      dynospack="$(basename ${dynospack} .zip)"

      if [ -d "$ROOT_PATH/$DYNOS_DIR/$PACKS_DIR/$dynospack" ]
      then
        echo "$0: Dynos pack $dynospack is already present, let's backup it first";
        echo "$0: (EXEC) mv \"${ROOT_PATH}/${DYNOS_DIR}/${PACK_DIR}/${dynospack}\" \"${ROOT_PATH}/${DYNOS_DIR}/${PACK_DIR}/${dynospack}-backup-${TS}\"";
        mv "${ROOT_PATH}/${DYNOS_DIR}/${PACK_DIR}/${dynospack}" "${ROOT_PATH}/${DYNOS_DIR}/${PACK_DIR}/${dynospack}-backup-${TS}"
      fi

      echo "$0: (EXEC) unzip \"${PACKAGES_DIR}/${DYNOS_DIR}/${dynospack}.zip\" -d \"${ROOT_PATH}/${DYNOS_DIR}/${PACKS_DIR}/\""
      unzip "${PACKAGES_DIR}/${DYNOS_DIR}/${dynospack}.zip" -d  "${ROOT_PATH}/${DYNOS_DIR}/${PACKS_DIR}/"

      if [ ! $? -eq 0 ]
      then
        echo "$0: Oh, no! An error occured while unpacking ${pack}.zip"

        echo "$0: Game over! Will stop here"
        exit 1
      fi
    fi
  
  fi

done

echo "$0: Yahoo! The ressources and packs have been installed."