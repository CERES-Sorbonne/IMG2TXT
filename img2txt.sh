#!/bin/sh
# Prérequis :
# pdftoppm
# python3
# virtualenv

inType=$1 # -p (PDF) -j (JPG) -P (PNG) -t (TIF)
outType=$2 # -t (TXT) -h (HTML)
engine=$3 # -k (KRAKEN), -t (TESSERACT)
dir_path=$4


# 1. Environnement virtuel
if [ $engine = "-k" ]; then
	if [ ! -d "./venv_kraken/" ]; then
		echo "Création de l'environnment virtuel pour accueillir Kraken."
		mkdir ./venv_kraken/
		python3 -m venv ./venv_kraken/
		. ./venv_kraken/bin/activate
		echo "Environnement virtuel venv_kraken créé.\n\nTéléchargement de Kraken."
		pip3 install kraken
	else
		. ./venv_kraken/bin/activate
	fi
elif [ $engine = "-t" ]; then
	if [ ! -d "./venv_tesseract/" ]; then
		echo "Création de l'environnment virtuel pour accueillir Tesseract."
		mkdir ./venv_tesseract/
		virtualenv -p python3 venv_tesseract
		. ./venv_tesseract/bin/activate
		echo "Environnement virtuel venv_tesseract créé.\n\nTéléchargement de Tesseract."
		pip3 install pytesseract opencv-python
	else
		. ./venv_tesseract/bin/activate
	fi
fi

# 3. Segmentation des pages
if [ $inType = "-p" ]; then
    find $dir_path -name "*.pdf" -exec pdftoppm -png {} {} \;
fi

# 4. Binarisation des images pour Kraken
if [ $engine = "-k" ]; then
    if [ $inType = "-p" ]; then
        find $dir_path -name "*.png" -exec timeout 600 kraken -i {} {}"_bin.png" binarize \;
    elif [ $inType = "-P" ]; then
        find $dir_path -name "*.png" -exec timeout 600 kraken -i {} {}"_bin.png" binarize \;
    elif [ $inType = "-j" ]; then
        find $dir_path -name "*.jpg" -exec timeout 600 kraken -i {} {}"_bin.png" binarize \;
    elif [ $inType = "-t" ]; then
        find $dir_path -name "*.tif" -exec timeout 600 kraken -i {} {}"_bin.png" binarize \;
    fi
fi

# 5. Segmentation et OCR
if [ $engine = "-k" ]; then
    if [ $outType = "-t" ]; then
        find $dir_path -name "*_bin.png" -exec timeout 600 kraken -i {} {}".txt" segment ocr -m ./CORPUS17.mlmodel \;
    else
        find $dir_path -name "*_bin.png" -exec timeout 600 kraken -h -i {} {}".html" segment ocr -m ./CORPUS17.mlmodel \;
    fi
elif [ $engine = "-t" ]; then
	# code pour lancer tesseract avec un fichier de config
	# ici html ça sera un fichier alto
    if [ $inType = "-p" ]; then
        find $dir_path -name "*.png" -exec python3 tesseract_ocr.py {} $outType \;
    elif [ $inType = "-P" ]; then
        find $dir_path -name "*.png" -exec python3 tesseract_ocr.py {} $outType \;
    elif [ $inType = "-j" ]; then
        find $dir_path -name "*.jpg" -exec python3 tesseract_ocr.py {} $outType \;
    elif [ $inType = "-t" ]; then
        find $dir_path -name "*.tif" -exec python3 tesseract_ocr.py {} $outType \;
    fi
fi
