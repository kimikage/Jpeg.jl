# LowLevelJPEG
[![Build Status](https://travis-ci.com/kimikage/LowLevelJPEG.jl.svg?branch=master)](https://travis-ci.com/kimikage/LowLevelJPEG.jl)
[![Codecov](https://codecov.io/gh/kimikage/LowLevelJPEG.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/kimikage/LowLevelJPEG.jl)

a library for low-level manipulation of JPEG images

## Introduction
LowLevelJPEG.jl is designed to manipulate the internal structures used in JPEG
File Interchange Format (JFIF) such as quantize tables, Huffman tables, etc.
If you just want to simply save or load JPEG images in Julia, do **not** use
LowLevelJPEG.jl because of security risks.
