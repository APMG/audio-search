American Public Media audio search
=====================================

To use this software, read the [wiki](https://github.com/APMG/audio-search/wiki).

This project is a [prototype funded by the Knight Foundation](http://www.knightfoundation.org/grants/201343246/).

The goal of the project is to determine whether it is possible to provide full-text search of audio files, using open source software to automate the creation of text transcriptions of APM digital audio. We are not aiming for 100% accurate, publish-able transcriptions. We are aiming for good-enough keyword recognition to improve the find-ability of our audio.

APM partnered with [Cantab Research Limited](http://www.cantabresearch.com/) to create the ASR (automatic speech recognition) models required, and then built a web service application to process and manage automatic transcriptions.

## Requirements

On CentOS 5 systems, the following RPMs are required to compile Kaldi:

 atlas blas blas-devel lapack lapack-devel

In addition, the SoX program is required. The TQ software has been tested with SoX v14.4.1.

