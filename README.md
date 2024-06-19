# R96ex-restool

This is a tool for [render96ex](https://github.com/cdeletre/Render96ex) (see note) that:
- extract assets from a rom (`baserom.us.z64`)
- build/assemble ressources (audio, gfx, demos, texts)
- install ressources and extra packages to a Render96ex installation folder

Note: this [render96ex](https://github.com/cdeletre/Render96ex) fork uses demos files instead of having them hardcoded in the binary blob.

Only arm64 configuration has been tested yet.

The script to be called is `install-res.sh`

# How does it work ?

Important note: after a full installation has been performed the game folder will be approximatly 1.5GB. However if you are satisfied with the installion and you game is running fine you can delete the `restool` folder which will save about 800 MB.

The main steps are:

1. check for presence of `baserom.us.z64`
1. extract asssets from the rom
1. build and assemble the ressources (audio, data, demos, texts). If it already exists a backup is created.
1. install the audio, data, demos and texts ressources in `res`
1. look for extra packages and install them in `res` or `dynos`. If it already exists a backup is created.

At any step, if anything goes wrong it stops.

If the installation process ends well `baserom.us.z64` is renamed to `baserom.us.z64_INSTALLED`.

To restart the installation process (ressources and/or packages) on next launch just rename again the rom to `baserom.us.z64`.

Please have in mind to check `res` and `dynos` for presence of unwanted backup after each attempt to install the ressource otherwisse you could end up with a 100% filled storage.

# Project sourced here

The content of `main` is a partial copy of [render96ex](https://github.com/Render96/Render96ex)
Minor change have been done, especialy in Makefile so that it can be ran on a CFW such as [rocknix](https://rocknix.org/).

For smaller distribution package it can be zipped as `main.zip`.

# bin and lib

The binaries and libraries in `bin` and `lib` come from an ubuntu 20.04 arm64 docker image.

# packages

Extra (optionnal) packs and ressources are present in `packages` :

- `res/gfx.zip` is a 25% resized version of [RENDER96-HD-TEXTURE-PACK](https://github.com/pokeheadroom/RENDER96-HD-TEXTURE-PACK/releases)
- `dynos/audio.mp3` is a 22050 Hz resampled version of the original dynos audio pack. The pack is in mp3 format to have smaller distribution package. Render96ex **DOES NOT** support mp3 format. The mp3 are converted back to wav during installation. You can still manually install the orinal wav file from [render96ex](https://github.com/Render96/Render96ex) if you want to avoid potential audio quality loss due to mp3. 
- `dynos/Render96-Alpha-3.1-modelpack-lowmem.zip` is a 25% resized version of [Render96-Alpha-3.1 modelpack](https://github.com/Render96/ModelPack/).
