# RTM data pipeline segment

This repositiory provides a segment of the pipeline detailed in PAPER and informing the modelling of the real-time Imperial College COVID-19 response team. We provide a segment to illustrate the process from publicly available data source to processing. 

## orderly

This is an [`orderly`](https://github.com/vimc/orderly) project.  The directories are:

* `src`: create new reports here
* `archive`: versioned results of running your report
* `draft`: test runs of your report- can be commit to `archive` when finalised

## Getting started

To run reports similar to those in this repository you will need to download the R package orderly, see the section below. If you would only like to view the code- this can all be found as separate report folders in the `src` directory. If you would only like to look at the output- this can all be found in separate report folders in the `archive` folder. 

Note, the reports here require access to upload and save the data to. If you would like to adapt these reports for your own use, please update the file paths in the `upload` section of the `rtm_incoming_preflight`.

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

### Running the reports

The reports would need to be run in the following order: rtm_incoming_preflight (which pulls the data from the COVID-19 dashboard), rtm_incoming_dashboard (which cleans the downloaded data), and rtm_collate_data (which tidies the data into its final format). To a run a report you would use the following:

```r
id <- orderly::orderly_run("rtm_incoming_preflight", root = path)
```
This would create a folder in the `draft` directory with the name `id`. You can commit this to the `archive` directory using `orderly::orderly_commit(id)`. You can see previously run versions in the archive folder.
