﻿# HackZurich2021 rECOmmender

This is the repository for the rECOmmender project at HackZurich2021.

## Goal

Guide the user to make him/her aware for sustainable alternatives to a product.

## Data

We used the data provided by MIGROS about the sustainability of their products

## Technical setup

There are 2 components:

1. The recommender. It consists of:
   * `0_data_flattening.py` script to generate flat data from the individual JSON files
     per product provided in the challenge.
   * `3_train_recommender_basic.py` script to train a recommender and make sustainable
   suggestions, where it is possible. The recommender algorithm is very basic and it
   relies all products in the one-but-last hierarchy level (Thema) being similar.
   The script written in a modular way to allow simple replacement of the algorithm
   to generate lists of similar products.
2. The Android application.
   * see [flutter_app/README.md](flutter_app/README.md) for more details.

## Team

@Lacrima26, @mlisovyi, @stefan-zemljic
