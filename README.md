# daru Lite - Data Analysis in RUby Lite

Simple, straightforward DataFrames for Ruby

[![Build Status](https://github.com/pollandroll/daru_lite/actions/workflows/build.yml/badge.svg)](https://github.com/pollandroll/daru_lite/actions)
[![Gem Version](https://img.shields.io/gem/v/daru_lite.svg)](https://rubygems.org/gems/daru_lite)

## Introduction

daru Lite is a library for data analysis and manipulation in Ruby.

This project started as fork of [Daru](https://github.com/SciRuby/daru) with the objective to provide :
- a simple and yet powerfull interface to manipulate data using DataFrames
- a API consistent with the one historically provided by daru
- a focus on the core features around data manipulation, droped several cumbersome daru dependencies and the associated features : notably N-Matrix, GSL, R, imagemagick and all plotting libraries. The current project has no major dependencies
- build a future-proof library that can safely be used in production

## Installation

```console
$ gem install daru_lite
```

or add daru Lite to your Gemfile:
```console
$ bundle add daru_lite
```

## Basic Usage

daru Lite exposes two major data structures: `DataFrame` and `Vector`. The Vector is a basic 1-D structure corresponding to a labelled Array, while the `DataFrame` - daru's primary data structure - is 2-D spreadsheet-like structure for manipulating and storing data sets.

Basic DataFrame intitialization.

``` ruby
data_frame = DaruLite::DataFrame.new(
  {
    'Beer' => ['Kingfisher', 'Snow', 'Bud Light', 'Tiger Beer', 'Budweiser'],
    'Gallons sold' => [500, 400, 450, 200, 250]
  },
  index: ['India', 'China', 'USA', 'Malaysia', 'Canada']
)
data_frame
```
![init0](images/init0.png)


Load data from CSV files.
``` ruby
df = DaruLite::DataFrame.from_csv('TradeoffData.csv')
```
![init1](images/init1.png)

*Basic Data Manipulation*

Selecting rows.
``` ruby
data_frame.row['USA']
```
![man0](images/man0.png)

Selecting columns.
``` ruby
data_frame['Beer']
```
![man1](images/man1.png)

A range of rows.
``` ruby
data_frame.row['India'..'USA']
```
![man2](images/man2.png)

The first 2 rows.
``` ruby
data_frame.first(2)
```
![man3](images/man3.png)

The last 2 rows.
``` ruby
data_frame.last(2)
```
![man4](images/man4.png)

Adding a new column.
``` ruby
data_frame['Gallons produced'] = [550, 500, 600, 210, 240]
```
![man5](images/man5.png)

Creating a new column based on data in other columns.
``` ruby
data_frame['Demand supply gap'] = data_frame['Gallons produced'] - data_frame['Gallons sold']
```
![man6](images/man6.png)

*Condition based selection*

Selecting countries based on the number of gallons sold in each. We use a syntax similar to that defined by [Arel](https://github.com/rails/arel), i.e. by using the `where` clause.
``` ruby
data_frame.where(data_frame['Gallons sold'].lt(300))
```
![con0](images/con0.png)

You can pass a combination of boolean operations into the `#where` method and it should work fine:
``` ruby
data_frame.where(
  data_frame['Beer']
  .in(['Snow', 'Kingfisher','Tiger Beer'])
  .and(
    data_frame['Gallons produced'].gt(520).or(data_frame['Gallons produced'].lt(250))
  )
)
```
![con1](images/con1.png)

## Documentation

Docs can be found [here](http://www.rubydoc.info/gems/daru_lite).
