#/usr/bin/env sh

# Get the CFW name (should be passed as 1st argument when calling this installion script)
# We need to detect muOS to warn the user about the limitation with this CFW
CFW_NAME=${1:-default}

# The rom version we are dealing with
VERSION="us"  # at the moment only US is supported and has been tested in Portmaster

# Path to game directory
ROOT_PATH="${PWD}/.."

# TOOLBOX PATHS
RESTOOL_ROOT="${PWD}"
RESTOOL_BIN="bin"
RESTOOL_LIBS="libs"

# Main sources for building and assembling the ressources
MAIN_DIR="main"

# This is were the ressources will be built and assembled
BUILD_DIR="${RESTOOL_ROOT}/${MAIN_DIR}/build/us_pc"

# Where we put build log
BUILD_LOG="${ROOT_PATH}/restool-build.log"

# Where we put mpg123 log
MPG123_LOG="${ROOT_PATH}/mpg123.log"

# Path to compressed packages (zip / mp3)
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
export LD_LIBRARY_PATH="${RESTOOL_ROOT}/${RESTOOL_LIBS}:${LD_LIBRARY_PATH}"

# Check if a rom file is present
if [ ! -f $ROOT_PATH/baserom.$VERSION.z64 ]
then
  echo "$0: No baserom.${VERSION}.z64 file is present. No installation of ressources will be performed"

  echo "$0: Will stop here"
  exit 0
fi

echo "$0: Okey dokey! baserom.${VERSION}.z64 file is present. Installation of ressources will start"

echo "$0: Here we go!"

echo "$0: Let clean the workspace just in case"

echo "$0: (EXEC) make distclean"

date >> ${BUILD_LOG}

cd "${MAIN_DIR}"

make distclean 2>&1 >> ${BUILD_LOG}

# We make a copy of the ROM
echo "$0: (EXEC) cp \"${ROOT_PATH}/baserom.${VERSION}.z64\" ."
cp "${ROOT_PATH}/baserom.${VERSION}.z64" .

# We run manually the asset extraction script (Makefile can do it) because we 
# want to watch the result of this step before going any further
echo "$0: (EXEC) ./extract_assets.py us"
./extract_assets.py us 2>&1 >> ${BUILD_LOG}

if [ ! $? -eq 0 ]
then

  # Extracting assets from the ROM has failed. The installation script will exit.
  echo "$0: Oh, no! Extraction of the assets from the rom has failed"
  romsha1=`cat sm64.us.sha1 | cut -d' ' -f1`
  echo -n "$0: check that sha1 of baserom.us.z64 is ${romsha1}"

  echo "$0: Game over! Will stop here"

  text_viewer -e -f 25 -w -t "Error" -m "Oh, no! Asset extraction from baserom.${VERSION}.z64 has failed. Please check that SHA1 of baserom.${VERSION}.z64 is ${romsha1} and see log for details."
  exit 1
fi

echo "$0: Yahoo! Assets have been extracted from the rom, let's build and assemble the ressources"
echo "$0: (EXEC) make res"

make res  2>&1 >> ${BUILD_LOG}

if [ ! $? -eq 0 ]
then

  # Something went wrong during the building of the ressources. The installation script will exit.

  echo "$0: Oh, no! An error occured while building and assembling the ressources"

  echo "$0: Game over! Will stop here"
  text_viewer -e -f 25 -w -t "Error" -m "Oh, no! The build of the ressources has failed. Please see log for details."
  exit 1
fi

# The ressources have been built.
echo "$0: ressources are ready, let's install them"

cd "${RESTOOL_ROOT}"

# suffix that will be added to the backup names
TS=$(date +%s)

for ressource in ${RESSOURCES_LST}
do

  if [ -f "$ROOT_PATH/$RES_DIR/$ressource" ] || [ -d "$ROOT_PATH/$RES_DIR/$ressource" ]
  then

    # The ressource is already present so we backup before we install it
    echo "$0: ressource ${ressource} is already present, let's backup it first";
    echo "$0: (EXEC) mv \"${ROOT_PATH}/${RES_DIR}/${ressource}\" \"${ROOT_PATH}/${RES_DIR}/${ressource}-backup-${TS}\"";
    mv "${ROOT_PATH}/${RES_DIR}/${ressource}" "${ROOT_PATH}/${RES_DIR}/${ressource}-backup-${TS}"
  fi

  # The ressource is copied into res folder
  echo "$0: (EXEC) mv \"${BUILD_DIR}/${RES_DIR}/${ressource}\" \"${ROOT_PATH}/${RES_DIR}/\""
  mv "${BUILD_DIR}/${RES_DIR}/${ressource}" "${ROOT_PATH}/${RES_DIR}/"

  if [ ! $? -eq 0 ]
  then
    echo "$0: Oh, no! An error occured while installing ${ressource}"

    echo "$0: Game over! Will stop here"

    text_viewer -e -f 25 -w -t "Error" -m "Oh, no! An error occured while installing the ressource ${ressource}. Please see log for details."
    exit 1
  fi

done

# We put back the rom but we rename it because we don't want to extract and install the ressouces again
echo "$0: (EXEC) \"${ROOT_PATH}/baserom.$VERSION.z64\" \"${ROOT_PATH}/baserom.$VERSION.z64.INSTALLED\""
mv "${ROOT_PATH}/baserom.$VERSION.z64" "${ROOT_PATH}/baserom.$VERSION.z64.INSTALLED"

echo "$0: let's see if we have zip ressource packages to install"

for respack in ${PACKAGES_DIR}/${RES_DIR}/*.zip
do
  text_viewer -y -f 25 -w -t "${respack}" -m "Do you want to install the optional ressource ${respack} ?"

  if [ $? -eq 0 ]
  then
    # we skip this ressource
    continue
  fi

  ressource="$(basename ${respack} .zip)"

  if [ -f "$ROOT_PATH/$RES_DIR/$ressource" ] || [ -d "$ROOT_PATH/$RES_DIR/$ressource" ]
  then

    # the pack is already present so we make a backup before we install it

    echo "$0: ressource ${ressource} is already present, let's backup it first";
    echo "$0: (EXEC) mv \"${ROOT_PATH}/${RES_DIR}/${ressource}\" \"${ROOT_PATH}/${RES_DIR}/${ressource}-backup-${TS}\"";
    mv "${ROOT_PATH}/${RES_DIR}/${ressource}" "${ROOT_PATH}/${RES_DIR}/${ressource}-backup-${TS}"
  fi

  # The pack is extracted in the res folder

  echo "$0: (EXEC) unzip \"${PACKAGES_DIR}/${RES_DIR}/${ressource}.zip\" -d \"${ROOT_PATH}/${RES_DIR}/\""
  unzip "${PACKAGES_DIR}/${RES_DIR}/${ressource}.zip" -d  "${ROOT_PATH}/${RES_DIR}/"

  if [ ! $? -eq 0 ]
  then
    echo "$0: Oh, no! An error occured while unpacking ${respack}"
    echo "$0: Game over! Will stop here"

    text_viewer -e -f 25 -w -t "Error" -m "Oh, no! An error occured while installing the optional ressource ${respack}. Please see log for details."
  fi
done

echo "$0: let's see if we have zip or mp3 dynos packages to install"

for dynospack in ${PACKAGES_DIR}/${DYNOS_DIR}/*
do

  zip=`[[ "$dynospack" =~ ".zip" ]] && echo 1 || echo 0`
  mp3=`[[ "$dynospack" =~ ".mp3" ]] && echo 1 || echo 0`
  audio=`[[ "$dynospack" =~ "audio" ]] && echo 1 || echo 0`

  text_viewer -y -f 25 -w -t "${dynospack}" -m "Do you want to install the optional dynos pack ${dynospack} ?"

  if [ $? -eq 0 ]
  then
    # user answer was "no"
    # we skip this pack
    continue
  fi

  if [ $audio -eq 1 ]
  then
    # This is a dynos audio pack

    dynospack="$(basename ${dynospack} .mp3)"
    disable=""
    if [[ "$CFW_NAME" =~ "muOS" ]]
    then
      # At the moment (20240625) muOS version doesn't support dynos audio pack
      # see https://discord.com/channels/1122861252088172575/1248351720464191590/1255230149213946000
      #
      warning_msg="WARNING: It seems that you are running muOS. At the date of porting Render96ex, the last version of muOS is 2405.1 REFRIED and doesn't support this pack. The pack will be installed but disabled."
      text_viewer -f 25 -w -t "${dynospack}" -m "${warning_msg}"
      disable=".disable"
    fi

    if [ -d "$ROOT_PATH/$DYNOS_DIR/$dynospack" ]
    then

      # the pack is already present so we make a backup before we install it

      echo "$0: Dynos pack $dynospack is already present, let's backup it first";
      echo "$0: (EXEC) mv \"${ROOT_PATH}/${DYNOS_DIR}/${dynospack}\" \"${ROOT_PATH}/${DYNOS_DIR}/${dynospack}-backup-${TS}\"";
      mv "${ROOT_PATH}/${DYNOS_DIR}/${dynospack}" "${ROOT_PATH}/${DYNOS_DIR}/${dynospack}-backup-${TS}"
    fi

    if [ $mp3 -eq 1 ]
    then

      # The pack comes in mp3 format we need to convert the file to wav format into the dynos folder

      mkdir -p "${ROOT_PATH}/${DYNOS_DIR}/${dynospack}${disable}"
      cd "${PACKAGES_DIR}/${DYNOS_DIR}/${dynospack}.mp3"
      rm -f mp3.nok
      find . -iname '*.txt' -exec cp {} "${ROOT_PATH}/${DYNOS_DIR}/${dynospack}${disable}/{}" \;
      find . -type d -exec mkdir -p "${ROOT_PATH}/${DYNOS_DIR}/${dynospack}${disable}/{}" \;
      find . -iname '*.mp3' -exec sh -c 'mpg123 -q -w "$2/${1%.*}.wav" "$1" || touch mp3.nok' sh {} "${ROOT_PATH}/${DYNOS_DIR}/${dynospack}${disable}" \; 2>&1 > ${MPG123_LOG}
      
      if [ -f "mp3.nok" ]
      then
        rm -f mp3.nok
        echo "$0: Oh, no! An error occured while unpacking ${dynospack}.mp3"
        text_viewer -e -f 25 -w -t "Error" -m "Oh, no! An error occured while unpacking ${dynospack}.mp3. Please see log for details."
      fi

      cd ${RESTOOL_ROOT}

    else
      
      # The pack comes in wav format so we just copy the folder into the dynos folder

      echo "$0: (EXEC) cp -R \"${PACKAGES_DIR}/${dynospack}\" \"${ROOT_PATH}/${DYNOS_DIR}/${dynospack}${disable}\""
      cp -R "${PACKAGES_DIR}/${dynospack}" "${ROOT_PATH}/${DYNOS_DIR}/${dynospack}${disable}"

      if [ ! $? -eq 1 ]
      then
        echo "$0: Oh, no! An error occured while installing ${dynospack}"
        text_viewer -e -f 25 -w -t "Error" -m "Oh, no! An error occured while installing ${dynospack}. Please see log for details."
      fi

    fi

  else

    if [ $zip -eq 1 ]
    then

      # The pack is packed in a zip file

      dynospack="$(basename ${dynospack} .zip)"

      if [ -d "$ROOT_PATH/$DYNOS_DIR/$PACKS_DIR/$dynospack" ]
      then

        # The pack is already present so we make a backup before we install it

        echo "$0: Dynos pack $dynospack is already present, let's backup it first";
        echo "$0: (EXEC) mv \"${ROOT_PATH}/${DYNOS_DIR}/${PACK_DIR}/${dynospack}\" \"${ROOT_PATH}/${DYNOS_DIR}/${PACK_DIR}/${dynospack}-backup-${TS}\"";
        mv "${ROOT_PATH}/${DYNOS_DIR}/${PACK_DIR}/${dynospack}" "${ROOT_PATH}/${DYNOS_DIR}/${PACK_DIR}/${dynospack}-backup-${TS}"
      fi

      # The pack is extracted in the dynos folder
      echo "$0: (EXEC) unzip \"${PACKAGES_DIR}/${DYNOS_DIR}/${dynospack}.zip\" -d \"${ROOT_PATH}/${DYNOS_DIR}/${PACKS_DIR}/\""
      unzip "${PACKAGES_DIR}/${DYNOS_DIR}/${dynospack}.zip" -d  "${ROOT_PATH}/${DYNOS_DIR}/${PACKS_DIR}/"

      if [ ! $? -eq 0 ]
      then
        echo "$0: Oh, no! An error occured while unpacking ${pack}.zip"
        text_viewer -e -f 25 -w -t "Error" -m "Oh, no! An error occured while unpacking ${dynospack}.zip. Please see log for details."
      fi
    fi
  
  fi

done

echo "$0: Yahoo! The ressources and packs have been installed. Let's-a go!"
text_viewer -f 25 -w -t "Ressources installed" -m "Yahoo! The ressources and packs have been installed. Let's-a go!"