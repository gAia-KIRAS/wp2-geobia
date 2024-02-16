#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library("sf")
  library("dplyr")
  library("qs")
  library("arrow")
  library("glue")
})

source("dev/utils.R")

ncores <- 16L
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  stop("Please supply at least one input file!")
}

for (infile in args) {
  outfile <- gsub(pattern = "qs$", "arrow", infile)
  print(glue("{format(Sys.time())} » Processing input file {infile}"))
  tmp <- qread(infile, nthreads = ncores)
  if ("geometry" %in% colnames(tmp)) {
    tmp <- tmp |>
      sfc_as_cols() |>
      st_drop_geometry() |>
      mutate(x = as.integer(x), y = as.integer(y))
  }
  write_ipc_file(tmp, sink = outfile, compression = "lz4")
  print(glue("{format(Sys.time())} » Output written to {outfile}"))
}
