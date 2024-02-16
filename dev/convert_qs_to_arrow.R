#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library("sf")
  library("qs")
  library("arrow")
  library("glue")
})

ncores <- 16L
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  stop("Please supply at least one input file!")
}

# TODO: handle multiple input files

infile <- args[1]
outfile <- gsub(pattern = "qs$", "arrow", infile)
print(glue("{format(Sys.time())} » Processing input file {infile}"))

qread(infile, nthreads = ncores) |>
  write_ipc_file(sink = outfile, compression = "lz4")

print(glue("{format(Sys.time())} » Output written to {outfile}"))
