# Merge segments in parallel
library(raster)
library(foreach)
library(doSNOW)

setwd("~/nfs_home/gAia/03_merged")
minsize <- 500L

segfiles <- Sys.glob("lsms_r50_s50_ms5000_subs1_*_FINAL_mrg500.tif")
b <- brick("scaled/dtm_carinthia_Oberkaernten_scaled_stack_subset1.tif")

# setup SNOW
# cl <- makeCluster(4)
# registerDoSNOW(cl)
registerDoSEQ()
pb <- txtProgressBar(max = length(segfiles), style = 3)
progress <- function(n) setTxtProgressBar(pb, n)
opts <- list(progress = progress)

mrg <- foreach(
  i = 1:length(segfiles), .export = c("b", "minsize", "segfiles"),
  .packages = "raster", .options.snow = opts
) %dopar% {
  cat("\nProcessing tile", i, "of", length(segfiles), "...\n")
  r <- raster(segfiles[i])
  vals <- unique(r)

  if (length(vals) > 1) {
    outfile <- file.path("03_merged", paste0(extension(basename(segfiles[i]), value = ""), "_mrg", minsize, ".tif"))
    tmpfile <- paste0("03_merged/tmp", i, ".tif")

    if (!file.exists(outfile)) {
      b2 <- crop(b, r, filename = tmpfile)

      # run OTB
      arglist <- c(
        paste("-inseg ", segfiles[i]),
        paste("-in", tmpfile),
        paste("-out", outfile),
        paste("-minsize", minsize),
        "-progress true"
      )
      res <- system2("otbcli_LSMSSmallRegionsMerging", arglist)
    } else {
      cat("File", basename(outfile), "already exists.\n")
    }
    if (file.exists(outfile)) {
      r2 <- raster(outfile)
    }
    # cleanup
    file.remove(tmpfile)
  } else {
    r2 <- NULL
  }
  r2
}
