# RTM data pipeline segment

This repositiory provides a segment of the pipeline detailed in PAPER and informing the modelling of the real-time Imperial College COVID-19 response team. We provide a segment to illustrate the process from publicly available data source to processing. 

## orderly

This is an [`orderly`](https://github.com/vimc/orderly) project.  The directories are:

* `src`: create new reports here
* `archive`: versioed results of running your report
* `data`: copies of data used in the reports

## Getting started

To run reports in this repository you will need to download the R package orderly, see the section below. If you would only like to view the code- this can all be found as separate report folders in the `src` directory. If you would only like to look at the output- this can all be found in separate report folders in the `archive` folder. 

### Installation

Install `orderly` from CRAN with

```r
install.packages("orderly")
```

To install our internally released version (which might be ahead of CRAN) via drat, use

```r
# install.packages("drat")
drat:::add("vimc")
install.packages("orderly")
```
