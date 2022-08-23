library(sf)
library(raster)

inv <- read_sf("~/nfs_scratch/projekte/gAia/data/inventory/ktn/ereignisinventar_als_basiert/ALS_basiertes_Inventar_Ktn/Rutschungen_gesamt.shp")
segfiles <- Sys.glob("~/nfs_home/gAia/lsms_r50_s50_ms5000_subs1_*_FINAL.tif")
min_seg_size <- 500L

g <- list()
for (i in 1:length(segfiles)) {
    cat("read", segfiles[i], "\n")
    seg <- raster(segfiles[i])
    test <- extract(seg, inv)
    g <- c(g, test[!sapply(test, is.null)])
}

# only use segments > 500
seg_inv_all <- unique(unlist(g))
tt <- table(unlist(g))
segs_inv <- as.integer(attr(tt, "dimnames")[[1]])[which(tt > min_seg_size)]

# extract
s <- brick("~/nfs_home/gAia/scaled/dtm_carinthia_Oberkaernten_scaled_stack_subset1.tif")
res <- as.data.frame(cbind(data.frame(seg = segs_inv), matrix(NA_real_, nr=length(segs_inv), nc=nlayers(s)*2)))
res_neg <- as.data.frame(cbind(data.frame(seg = integer(0)), matrix(NA_real_, nr=0, nc=nlayers(s)*2)))
set.seed(100)
for (i in 1:length(segfiles)) {
    seg <- raster(segfiles[i])
    iseg <- which(segs_inv %in% seg[])
    if (length(iseg) > 0) {
        cat("extracting", segfiles[i], "\n")
        s2 <- crop(s, seg)
        for (j in 1:length(iseg)) {
            #browser()
            icell <- Which(seg == segs_inv[iseg[j]], cells=TRUE)
            v <- s2[icell]
            res[which(res$seg == segs_inv[iseg[j]]), 2:ncol(res)] <- as.vector(apply(v, 2, function(x) c(mean(x, na.rm=TRUE), sd(x, na.rm=TRUE))))
        }
        #break
        seg_uniq <- unique(getValues(seg))
        seg_neg <- seg_uniq[!seg_uniq %in% seg_inv_all]
        tt_seg <- freq(seg)
        seg_neg_lg <- tt_seg[tt_seg[,1] %in% seg_neg & tt_seg[,2] > min_seg_size,1]
        # pick negative segments randomly
        nsample <- min(length(iseg)*5, length(seg_neg_lg))
        iseg_neg <- sample(seg_neg_lg, nsample)
        seg_msk <- subs(seg, data.frame(iseg_neg, iseg_neg), subsWithNA=TRUE)
        res_neg <- rbind(res_neg, zonal(s2, seg_msk, fun=function(x, ...) c(c(mean(x, ...), sd(x, ...)))))
    }
    removeTmpFiles(0)
}
names(res_neg) <- names(res)

dat <- rbind(cbind(res, class=1L), cbind(res_neg, class=0L))
dat$class <- factor(dat$class)
save(dat, file="~/nfs_home/Git/gaia/dat/interim/segments/segments_ktn_subset1.RData")
