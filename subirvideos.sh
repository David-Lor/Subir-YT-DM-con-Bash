#!/bin/bash
DIR=~/prueba-bash-video
CLIENT_SECRETS=~/youtube-upload-master/client_id.json

f_videoSelection ()
{
    foundFilesLoopCount=0
    echo "#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#"
    echo "Selecciona un vídeo de la lista:"
    echo "[0] Terminar Selección"
    until [ $foundFilesLoopCount -eq $foundFilesCount ]
    do
        index=$((foundFilesLoopCount+1))
        echo "[$index] ${foundFilesArray[$foundFilesLoopCount]}"
        foundFilesLoopCount=$((foundFilesLoopCount+1))
    done
    echo "[t] Seleccionar Todos"
    read -n 1 KEY
    if [ $KEY = '0' ]
    then #Terminar selección de vídeos (pasar al siguiente paso)
        echo "Terminada selección de vídeos con $selectedVideosCount vídeos seleccionados."
        f_upload
    elif [ $KEY = 't' ]
    then #Seleccionar TODOS los vídeos
        selectedVideosArray=("${foundFilesArray[@]}")
        selectedVideosCount=${#selectedVideosArray[*]}
        echo "Seleccionados todos los vídeos. Total: $selectedVideosCount"
        f_allVideosDestSelection
    else
        KEY=$((KEY-1))
        if [ $KEY -lt $foundFilesCount ]
        then
            selectedVideoNow=${foundFilesArray[$KEY]}
            selectedVideosArray[$selectedVideosCount]=$selectedVideoNow #selectedVideosCount actúa como index
            #selectedVideosCount=$((selectedVideosCount+1))
            selectedVideosCount=${#selectedVideosArray[*]}
            echo "Seleccionado el vídeo $selectedVideoNow. Vídeos totales: $selectedVideosCount"
            f_videoDestSelection
        else
            echo "Selección incorrecta, inténtalo de nuevo."
            f_videoSelection
        fi
    fi
}

f_videoDestSelection()
{
    vidIndex=$((selectedVideosCount-1))
    echo "Selecciona adónde se subirá $selectedVideoNow:"
    echo "[y] Youtube"
    echo "[d] Dailymotion"
    echo "[a] Youtube y Dailymotion"
    read -n 1 KEY
    if [[ $KEY = "y" ]] #YT=1 (DestArray)
    then
        selectedVideosDestArray[$vidIndex]=1
        echo "El vídeo se subirá a Youtube"
        f_videoSelection
    elif [[ $KEY = "d" ]] #DM=2 (DestArray)
    then
        selectedVideosDestArray[$vidIndex]=2
        echo "El vídeo se subirá a Dailymotion"
        f_videoSelection
    elif [[ $KEY = "a" ]] #Ambos=3 (DestArray)
    then
        selectedVideosDestArray[$vidIndex]=3
        echo "El vídeo se subirá a Youtube y Dailymotion"
        f_videoSelection
    else
        echo "Destino seleccionado no válido, inténtalo de nuevo"
        f_videoDestSelection
    fi
}

f_allVideosDestSelection()
{
    echo "Selecciona adónde se subirán todos los vídeos del directorio:"
    echo "[y] Youtube"
    echo "[d] Dailymotion"
    echo "[a] Youtube y Dailymotion"
    read -n 1 KEY
    if [[ $KEY = "y" ]] #YT=1 (DestArray)
    then
        echo "Los $selectedVideosCount vídeos serán subidos a Youtube"
        allDest=1
        #f_upload
    elif [[ $KEY = "d" ]] #DM=2 (DestArray)
    then
        echo "Los $selectedVideosCount vídeos serán subidos a Dailymotion"
        allDest=2
        #f_upload
    elif [[ $KEY = "a" ]] #Ambos=3 (DestArray)
    then
        echo "Los $selectedVideosCount vídeos serán subidos a Youtube y Dailymotion"
        allDest=3
        #f_upload
    else
        echo "Destino seleccionado no válido, inténtalo de nuevo"
        f_allVideosDestSelection
    fi
    allVidsDestCount=0
    until [ $allVidsDestCount -eq $selectedVideosCount ]
    do
        selectedVideosDestArray[$allVidsDestCount]=$allDest
        allVidsDestCount=$((allVidsDestCount+1))
    done
    f_upload
}

f_upload ()
{
    echo "Resumen de la operación:"
    selectedVideosReviewCount=0
    until [ $selectedVideosReviewCount -eq $selectedVideosCount ]
    do
        dest=${selectedVideosDestArray[$selectedVideosReviewCount]}
        if [[ $dest -eq 1 ]]
        then
            destStr="YT"
        elif [[ $dest -eq 2 ]]
        then
            destStr="DM"
        elif [[ $dest -eq 3 ]]
        then
            destStr="YT+DM"
        fi
        actualVideoRealCount=$((selectedVideosReviewCount+1))
        echo "$actualVideoRealCount - ${selectedVideosArray[$selectedVideosReviewCount]} >> $destStr"
        selectedVideosReviewCount=$((selectedVideosReviewCount+1))
    done
    echo "Se subirán los vídeos con estas configuraciones en 5 segundos. Pulsa [q] para cancelar."
    read -n 1 -t 5 KEYB
    if [[ $KEYB = "q" ]]
    then
        echo "Subidas canceladas. La aplicación se cerrará."
        exit 0
    fi
    echo "Iniciando todas las subidas..."
    uploadedVideos=0 #actúa como index
    until [ $uploadedVideos -gt $selectedVideosCount ]
    do
        uploadingVideo=${selectedVideosArray[$uploadedVideos]}
        uploadingVideoDest=${selectedVideosDestArray[$uploadedVideos]}
        if [[ $uploadingVideoDest -eq 1 ]] || [[ $uploadingVideoDest -eq 3 ]]
        then #YOUTUBE
            echo "Iniciada la subida de $uploadingVideo a Youtube"
            youtube-upload "$uploadingVideo" --privacy unlisted --client-secrets=$CLIENT_SECRETS --title="$uploadingVideo"
            echo "Finalizada la subida de $uploadingVideo a Youtube"
        fi
        if [[ $uploadingVideoDest -eq 2 ]] || [[ $uploadingVideoDest -eq 3 ]]
        then #DAILYMOTION
            echo "Iniciada la subida de $uploadingVideo a Dailymotion"

            echo "Finalizada la subida de $uploadingVideo a Dailymotion"
        fi
        uploadedVideos=$((uploadedVideos+1))
    done
    echo "Todas las subidas han finalizado"
    exit 0
}

echo "HERRAMIENTA PARA SUBIR VÍDEOS A YOUTUBE Y DAILYMOTION"
echo "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*"
cd $DIR
#foundFilesArray=($(ls -1))
foundFilesArray=(*)
foundFilesCount=${#foundFilesArray[*]}
selectedVideosArray=()
selectedVideosDestArray=()
selectedVideosCount=0
echo "Encontrados $foundFilesCount archivos en $DIR"
f_videoSelection
exit 0
