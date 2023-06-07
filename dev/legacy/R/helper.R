#' Function transforming the main direction to an orthogonal scale
#'
#' @param x vector defining the main direction
#' @return
#' vector
#'
MainDirTrans <- function(x) {
  tmp <- ifelse(x == 360, 0, x) # 360, 1 up to 90 should stay the same
  tmp <- ifelse(tmp > 90 & tmp < 180, tmp - 180, tmp) # 91 up to 179 should be -89 up to 0
  tmp <- ifelse(tmp >= 180 & tmp <= 270, tmp - 180, tmp) # 180 up to 270 should be 0 up to 90
  tmp <- ifelse(tmp > 270 & tmp < 360, tmp - 360, tmp) # 271 up to 359 should be -89 up to -1

  return(tmp)
}






#' Function calculates the difference between main direction and flow direction
#'
#' @param main vector defining the main direction
#' @param mainInv vector defining the inversed main direction
#' @param flow vector defining the flow direction
#' @return
#' vector
#'
calcMnFlowDif <- function(main, mainInv, flow) {
  sapply(X = 1:length(flow), FUN = function(x, m, mInv, fl) {
    # browser()
    # print(fl[x])
    if (is.na(fl[x])) {
      return(NA)
    }

    if (fl[x] <= 180) {
      dif <- abs(m[x] - fl[x])
      dif <- ifelse(dif > 90, 180 - dif, dif)
    } else {
      dif <- abs(mInv[x] - fl[x])
      dif <- ifelse(dif > 90, 180 - dif, dif)
    }
  }, m = main, mInv = mainInv, fl = flow)
}






#' Function calculates main direction/object orientation and length-to-width ratio
#'
#'
#' @param seg.sp input of class "spatial"
#' @param flowDir vector defining the flow direction
#' @param cores number of cores
#' @return
#' list
#'
getMoreMetrics <- function(seg.sp, flowDir, cores = 1) {
  ## Calculate Main Direction
  seg.MainDir <- Lslide::mainDirection(spdf = seg.sp, cores = cores, quiet = FALSE)
  seg.MnDirTrans <- MainDirTrans(seg.MainDir$angle)


  ## Calculate Length Width Ratio
  seg.LeWiRat <- Lslide::lengthWidthRatio(spdf = seg.sp, cores = cores, quiet = FALSE)$ratio


  ## Calculate Main Direction to Flow Direction
  seg.MnFl_minDf <- calcMnFlowDif(main = seg.MainDir$angle, mainInv = seg.MainDir$angle_inv, flow = flowDir)

  ## Adding to data.frame
  df.result <- data.frame(ID = seg.sp@data$ID, MnDir = seg.MnDirTrans, LeWiRat = seg.LeWiRat, MnToFlDir = seg.MnFl_minDf)

  return(df.result)
}






#' Function calculates Queen's and flow contiguity
#'
#' @param seg.sp input of class "spatial"
#' @param seg.sf input of class "sf"
#' @param col.name.conv name of column containing information on cenvexity. Default: "Conv"
#' @param col.name.fl name of column containing information on flow direction. Default: "Flow"
#' @param conv.thresh convexity threshold for bounding boxes. Default: 0.5
#' @param tol tolerance for angle shift defining a neighbor in flow direction. Default: 75 degree
#' @param cores number of cores
#' @return
#' list with contiguities
#'
extractNeighborhoods <- function(seg.sp, seg.sf, col.name.conv = "Conv", col.name.fl = "Flow",
                                 conv.thresh = 0.5, tol = 75, cores = 20) {
  # calculate neighborhood
  nb_speed_up <- rgeos::gUnarySTRtreeQuery(seg.sp) # speed up function for poly2nb
  nb <- spdep::poly2nb(seg.sp, queen = TRUE, foundInBox = nb_speed_up) # neighborhood based on queen continuity
  nb.queen <- nb


  # ... create bounding boxes for possible scarp segments -------------
  # ... ... bounding box in flow direction ---------------------------------
  # calculation of bounding box in flow and inverse flow direction
  seg.bb.flow.Conv <- Lslide::getBoundingBox(
    spdf = subset(seg.sp, seg.sp[[col.name.conv]] < conv.thresh & !is.na(seg.sp[[col.name.fl]])), scale.factor = c(1.5, 1.3), cores = cores,
    k.centroid = 3, set.centroid = "inverse", scale.side = "long", centroid = FALSE, col.name = col.name.fl, quiet = FALSE
  )

  row.names(seg.bb.flow.Conv) <- row.names(subset(seg.sp, seg.sp[[col.name.conv]] < conv.thresh & !is.na(seg.sp[[col.name.fl]])))



  seg.bb.flow.Centr <- Lslide::getBoundingBox(
    spdf = subset(seg.sp, seg.sp[[col.name.conv]] >= conv.thresh & !is.na(seg.sp[[col.name.fl]])), scale.factor = c(2, 1.3),
    k = 2, scale.side = "long", centroid = TRUE, col.name = col.name.fl, cores = cores, quiet = FALSE
  )

  row.names(seg.bb.flow.Centr) <- row.names(subset(seg.sp, seg.sp[[col.name.conv]] >= conv.thresh & !is.na(seg.sp[[col.name.fl]])))


  # merge both bounding boxes
  seg.bb.flow <- rbind(seg.bb.flow.Conv, seg.bb.flow.Centr)

  # order bounding box to fit ID classes order
  seg.bb.flow <- seg.bb.flow[order(seg.bb.flow@data$ID), ]
  seg.bb.flow.sf <- sf::st_as_sf(seg.bb.flow)


  # get neighbor in flow direction
  seg.nbFlow <- sf::st_intersects(seg.bb.flow.sf, seg.sf) # 30384 length, neighbor in flow direction of scarp candidate by bounding box
  names(seg.nbFlow) <- row.names(seg.bb.flow.sf)


  # assign flow neighbor to overall neighbor hood
  nb.addOn <- lapply(seq_along(seg.nbFlow), FUN = function(i, seg.nbFlow, nb) {
    index <- as.numeric(names(seg.nbFlow[i]))
    nbs <- unique(c(nb[[index]], seg.nbFlow[[i]]))

    if (length(nbs) == 0) {
      return(NA)
    } else {
      nbs <- nbs[!nbs %in% index]
      return(nbs)
    }
  }, seg.nbFlow = seg.nbFlow, nb = nb)
  names(nb.addOn) <- row.names(seg.bb.flow.sf)

  # nb is overwritten!
  nb[as.numeric(names(nb.addOn))] <- nb.addOn



  # ... calculate neighbor in flow direction with tolerance ---------------------
  seg.nbFlowDirTol <- Lslide::neighborDirection(
    spdf = seg.sp, col.name = col.name.fl, modus = "nb",
    nb = nb, tol = tol, cores = cores, quiet = FALSE
  )


  # ... ... transver to neighbor indices
  nb.flow <- lapply(seg.nbFlowDirTol, FUN = function(x, nb) {
    if (length(x$NeighborDirection) == 1 && (is.na(x$NeighborDirection) || x$NeighborDirection == 0)) {
      return(NA)
    } else {
      if ("y" %in% names(x$NeighborDirection)) # because of "y" bug in function
        {
          return(nb[[x$Object]])
        }

      return(names(x$NeighborDirection))
    }
  }, nb = nb)


  result <- list(nb_queen = nb.queen, nb_flow = nb.flow)


  return(result)
} # end of function extractNeighborhoods







#' Function calculates object statistics on Queen's and flow contiguity
#'
#' @param nb list defining contiguity
#' @param col.names column names on which statistics are calculated
#' @param col.area column name defining the area of polygons
#' @param in.seg segmentation input of class "sf"
#' @param suffix suffix for column naming. Default "_"
#' @return
#' data.frame with object statistics under consideration of contiguities
#'
nbStat <- function(nb, col.names, col.area, in.seg, suffix = "_") {
  if (nrow(in.seg) != length(nb)) {
    warnings("Neighborhood and segmentation do not match!")
  }

  result.list <- lapply(X = col.names, FUN = function(i, nb, in.seg, col.name, col.area) {
    sapply(X = nb, FUN = function(j, in.seg, col.name, col.area) {
      if (length(j) == 1 && is.na(j)) {
        return(NA)
      } else {
        j <- as.numeric(j)

        if (length(unique(in.seg[[col.name]][c(j)])) == 1 && is.na(unique(in.seg[[col.name]][c(j)]))) {
          return(NA)
        } else {
          return(weighted.mean(x = in.seg[[col.name]][c(j)], w = in.seg[[col.area]][c(j)], na.rm = TRUE))
        }
      }
    }, in.seg = in.seg, col.name = i, col.area = col.area)
  }, nb = nb, in.seg = in.seg, col.name = i, col.area = col.area)

  result.df <- as.data.frame(rlist::list.cbind(append(list(in.seg$ID), result.list)))
  names(result.df) <- c("ID", paste0(col.names, suffix))

  return(result.df)
} # end of function nbStat




#' Clean contiguity data
#'
#' It may happen that objects do not have a neighbor in flow direction. Then NA is
#' returned. To avoid skipping those objects, the Queen's value is taken.
#'
#' @param in.seg segmentation input of class "sf"
#' @param pattern.flow pattern of flow contiguity. Must be similar to suffixes of feature names
#' @param pattern.queens pattern of Queen's contiguity. Must be similar to suffixes of feature names
#' @return
#' data.frame with object statistics under consideration of contiguities
#'
finCleaning <- function(in.seg, pattern.flow = "nF", pattern.queens = "nQ") {
  names.nF <- names(in.seg)[grep(pattern = pattern.flow, x = names(in.seg))]
  names.nQ <- gsub(pattern = paste0("_", pattern.flow), replacement = paste0("_", pattern.queens), x = names.nF)

  for (i in 1:length(names.nF))
  {
    nF.i <- names.nF[i]
    nQ.i <- names.nQ[i]

    na.pos <- which(is.na(in.seg[, nF.i]))

    in.seg[[nF.i]][na.pos] <- in.seg[[nQ.i]][na.pos]
  }

  return(in.seg)
} # end of finCleaning





#' Creation of finalized data.frame
#'
#' It may happen that objects do not have a neighbor in flow direction. Then NA is
#' returned. To avoid skipping those objects, the Queen's value is taken.
#'
#' @param df data.frame
#' @param do.sample if a random sample should be perfromed. Default: TRUE
#' @param col name of column on which the sampling based on
#' @param ratio ratio of sampling for categorical variable. Default: 1
#' @param v.F vector defining FALSE items. Default: c(0)
#' @param v.F vector defining TRUE items. Default: c(1)
#' @param col.fit column name defining classes. Default: NULL
#' @param v.fit vector with classes of col.fit. Default: NULL
#' @param seed seed number. Default: 1234
#' @return
#' data.frame with object statistics under consideration of contiguities
#'
finalDF <- function(df, do.sample = TRUE, col = "Lslide", ratio = 1,
                    v.F = c(0), v.T = c(1), col.fit = NULL, v.fit = NULL, seed = 1234) {
  # complete cases
  df <- df[complete.cases(df), ]

  # assign factor variable
  if ("Lslide" %in% names(df)) {
    df$Lslide <- factor(as.character(df$Lslide), levels = sort(unique(df$Lslide)))
  }

  if ("LS_Part" %in% names(df) | "LS_PART" %in% names(df)) {
    pos.LSPART <- grep(pattern = "LS_Part|LS_PART", x = names(df))
    df[, pos.LSPART] <- factor(df[, pos.LSPART], levels = sort(unique(df$LS_PART)))
  }


  # sub-sample data
  if (do.sample) {
    mySampling <- function(ID.T, ID.F, df, seed, ratio) {
      set.seed(seed)

      num.T <- length(ID.T)
      num.F <- length(ID.F)

      if (num.T > num.F) {
        num.sample <- num.T - (num.T - num.F)
        sel <- sample(x = ID.T, size = num.sample)
        # sel.inter <- intersect(ID.T, sel)
        # sel.inter.pos <- match(sel.inter, df$ID)
        sel.remove <- setdiff(ID.T, sel)
        sel.remove.pos <- match(sel.remove, df$ID)
      }

      if (num.F > num.T) {
        num.sample <- num.F - (num.F - num.T)
        sel <- sample(x = ID.F, size = num.sample * ratio)
        # sel.inter <- intersect(ID.F, sel)
        # sel.inter.pos <- match(sel.inter, df$ID)
        sel.remove <- setdiff(ID.F, sel)
        sel.remove.pos <- match(sel.remove, df$ID)
      }

      return(sel.remove.pos)
      # return(sel.inter.pos)
    }


    if (!is.null(col.fit) & !is.null(v.fit)) {
      if (length(v.fit) != length(v.T)) {
        stop("Length of TRUE items and TRUE sample items differ! \n")
      }

      sel.remove.pos <- lapply(X = 1:length(v.fit), FUN = function(i, v.fit, v.T, v.F, seed, mySampling, col, col.fit, df, ratio) {
        ID.T.i <- df$ID[which(df[, col] %in% v.T[i])]
        ID.F.i <- df$ID[which((df[, col] %in% v.F) & (df[, col.fit] %in% v.fit[i]))]

        sample.i <- mySampling(ID.T = ID.T.i, ID.F = ID.F.i, df = df, seed = seed, ratio = ratio)
        return(sample.i)
      }, v.fit = v.fit, v.T = v.T, v.F = v.F, seed = seed, mySampling = mySampling, col = col, col.fit = col.fit, df = df, ratio) %>%
        unlist(.) %>%
        unique(.)
    } else {
      ID.T <- df$ID[which(df[, col] %in% v.T)]
      ID.F <- df$ID[which(df[, col] %in% v.F)]

      sel.remove.pos <- mySampling(ID.T = ID.T, ID.F = ID.F, df = df, seed = seed, ratio = ratio)
      # sel.inter.pos <- mySampling(ID.T = ID.T, ID.F = ID.F, seed = seed)
    }

    df <- df[-sel.remove.pos, ]
    # df <- df[sel.inter.pos,]
  }

  return(df)
} # end of function finalDF









#' Get Growing Classes for Predicted Landslide Scarps
#'
#' It may happen that objects do not have a neighbor in flow direction. Then NA is
#' returned. To avoid skipping those objects, the Queen's value is taken.
#'
#' @param grownInput data.frame containing gorwing information
#' @param nb contiguity defining the neighbors for growing
#' @param orig_d important! data.frame which was used for the creation of the nb-input!
#' @param thresh threshold defining the corresponding response
#' @param col.prob.body column name, which contains the probability of the landslide body. Default: "Body_Prb1"
#' @param out.col1 output name for gorwing classes. Default: "NeighborGrowing"
#' @param out.unique unique classes. Default:TRUE
#' @return
#' data.frame with growing classes
#'
getGrowingClass <- function(grownInput, nb, orig_d, thresh, col.prob.body = "Body_Prb1", out.col1 = "NeighborGrowing", out.unique = TRUE) {
  # get body to each scarp
  out <- lapply(1:length(unique(grownInput$NeighborGrowing)), function(x, grownInput, nb, orig_d, thresh) {
    id.grownInput <- grownInput[which(grownInput$NeighborGrowing == x), ]$ID

    id.pos <- which(orig_d$ID %in% id.grownInput)

    # get body neighbors of grownInput
    nb.tmp <- as.numeric(unique(unlist(nb[id.pos])))
    nb.tmp <- nb.tmp[!nb.tmp %in% id.pos] # potential grownInputs neighbors

    # check probabilities
    nb.tmp <- nb.tmp[which(orig_d[nb.tmp, ][col.prob.body] >= thresh)]
    if (length(nb.tmp) == 0) {
      return(data.frame(Scarp_ID = id.grownInput, Body_ID = NA, NeighborGrowing = x))
    }

    # call recursive all further neighbors
    nb.tmp.start <- nb.tmp

    repeat{
      nb.tmp.i <- as.numeric(unique(unlist(nb[nb.tmp.start])))
      nb.tmp.i <- nb.tmp.i[!nb.tmp.i %in% nb.tmp.start]

      nb.tmp.i <- nb.tmp.i[which(orig_d[nb.tmp.i, ][col.prob.body] >= thresh)]
      nb.tmp.end <- c(nb.tmp.start, nb.tmp.i) %>% unique(.)

      if (length(nb.tmp.start) == length(nb.tmp.end)) {
        nb.tmp <- nb.tmp.end
        break
      }

      nb.tmp.start <- nb.tmp.end
    }

    # get IDs of neighbors
    nb.id <- orig_d[nb.tmp, ]$ID

    df <- data.frame(Scarp_ID = rep(id.grownInput, length(nb.id)), Body_ID = nb.id, NeighborGrowing = x)

    # return relevant body neighbors
    return(df)
  }, grownInput = grownInput, nb = nb, orig_d = orig_d, thresh = thresh)


  names(out) <- unique(grownInput$NeighborGrowing) # name list
  out <- do.call(rbind, out) # bind dataframes of list
  out <- out[complete.cases(out), ] # remove NA's
  out <- unique(melt(out, "NeighborGrowing")) # melt data frame

  names(out) <- c(out.col1, "type", "ID")

  # union IDs belonging to same landslide (but are assigned to different)
  if (out.unique) {
    freqTable <- as.data.frame(table(out[, "ID"]), stringsAsFactors = FALSE)
    id.tmp <- as.numeric(freqTable$Var1[which(freqTable$Freq > 1)])

    id.checked <- c()

    for (i in id.tmp)
    {
      if (i %in% id.checked) {
        next
      }

      sel.tmp <- unique(out[which(out$ID == i), ][[out.col1]]) # get growing class of ID
      sel.id.tmp <- unique(out$ID[out[[out.col1]] %in% sel.tmp]) # get all IDs of growing classes

      # deep search for new growing classes and new IDs
      repeat{
        l.tmp <- length(sel.id.tmp)
        sel.tmp <- unique(out[out$ID %in% sel.id.tmp, ][[out.col1]]) # get growing class of ID
        sel.id.tmp <- unique(out$ID[out[[out.col1]] %in% sel.tmp]) # get all IDs of growing classes

        if (length(sel.id.tmp) == l.tmp) {
          break
        } # break out when all is found
      }

      out[[out.col1]][out$ID %in% sel.id.tmp] <- min(sel.tmp)

      id.checked <- unique(c(id.checked, unique(c(i, sel.id.tmp))))
    }

    out <- unique(out) # remove duplicates
  }

  return(out)
} # end of function





#' Get Intersectiond and Summary of Classification and Inventory
#'
#' It may happen that objects do not have a neighbor in flow direction. Then NA is
#' returned. To avoid skipping those objects, the Queen's value is taken.
#'
#' @param inventory inventory input of class sf
#' @param Lslide classification of class sf
#' @param Lslide.col name of column specifying the prediction. Default: "UNNAMED"
#' @param thresh percentage threshold defining if a inventoried landslide is correctly classified
#' @return
#' data.frame with object-level accuracy
#'
getIntersectSummary <- function(inventory, Lslide, Lslide.col = "UNNAMED", thresh = 50) {
  inter.tmp <- sf::st_intersection(x = Lslide, y = inventory)
  inter.tmp$A_inter <- as.numeric(sf::st_area(inter.tmp))
  inter.tmp <- data.table::as.data.table(sf::st_set_geometry(inter.tmp, NULL))

  if (Lslide.col != "UNNAMED") {
    inter.tmp.sum <- inter.tmp[, list(A = mean(A_m_sq), A_inter = sum(A_inter), TMP = list(unique(get(Lslide.col)))), by = list(Id)]
  } else {
    inter.tmp.sum <- inter.tmp[, list(A = mean(A_m_sq), A_inter = sum(A_inter), TMP = NA), by = list(Id)]
  }

  inter.tmp.sum$A_Q <- inter.tmp.sum$A_inter / inter.tmp.sum$A * 100
  inter.tmp.sum$A_GTEQ_TRSH <- ifelse(inter.tmp.sum$A_Q >= thresh, 1, 0)

  colnames(inter.tmp.sum)[6] <- paste0("A_GTEQ_", thresh)
  colnames(inter.tmp.sum)[4] <- Lslide.col

  df.out <- merge(x = inventory[, c("Id", "geometry")], y = inter.tmp.sum, by = "Id", all.x = TRUE)

  return(df.out)
}





#' Polygon Rasterization using SAGA GIS
#'
#' @param x.sf input of class sf
#' @param r.path path of template raster
#' @param field column name for rasterization
#' @param out.grid path of output raster
#' @param env.rsaga SAGA GIS environment
#' @param NAFlag Value for NoData cells. Default: -99999
#' @param show.output.on.console show SAGA GIS processing output on console. Default: FALSE
#' @return
#' data.frame with object-level accuracy
#'
rsaga.quickRasterization <- function(x.sf, r.path, field, out.grid, env.rsaga, NAFlag = -99999, show.output.on.console = FALSE) {
  sf.tmp.path <- file.path(tempdir(), "sf_tmp.shp")
  sf::st_write(obj = x.sf, dsn = sf.tmp.path, delete_layer = TRUE, quiet = TRUE)


  if (tools::file_ext(out.grid) != ".sgrd" | tools::file_ext(out.grid) != ".sdat") {
    out.grid.tmp <- file.path(tempdir(), "quickRaster.sgrd")
  } else {
    out.grid.tmp <- out.grid
  }

  # RSAGA::rsaga.get.usage(lib = "grid_gridding", module = 0, env = env.rsaga)
  # MULTIPLE: [1] last | POLY_TYPE [0] node
  RSAGA::rsaga.geoprocessor(lib = "grid_gridding", module = 0, env = env.rsaga, show.output.on.console = show.output.on.console, param = list(
    INPUT = sf.tmp.path, FIELD = field, MULTIPLE = "1", TARGET_DEFINITION = "1", TARGET_TEMPLATE = r.path, GRID = out.grid.tmp, POLY_TYPE = "0"
  ))

  if (tools::file_ext(out.grid) != ".sgrd" | tools::file_ext(out.grid) != ".sdat") {
    r.tmp <- raster::raster(x = paste0(tools::file_path_sans_ext(out.grid.tmp), ".sdat"))
    raster::writeRaster(x = r.tmp, filename = out.grid, overwrite = TRUE, NAFlag = NAFlag)
    r.tmp <- raster::raster(x = out.grid)
  } else {
    r.tmp <- raster::raster(paste0(tools::file_path_sans_ext(out.grid.tmp), ".sdat"))
  }

  return(r.tmp)
}







#' Calculation of Pixel-Level Accuracy using SAGA GIS
#'
#' @param r raster of classification
#' @param inventory raster of inventory
#' @param env.rsaga SAGA GIS environment. Default: NULL
#' @param show.output.on.console show SAGA GIS processing output on console. Default: FALSE
#' @return
#' data.frame with pixel-level accuracy
#'
rsaga.calcAccPixelBased <- function(r, inventory, env.rsaga = NULL, show.output.on.console = FALSE) {
  tryCatch(
    {
      if (!raster::compareRaster(r, inventory, stopiffalse = FALSE)) {
        cat("Extent and Crop raster \n")

        r <- raster::extend(x = r, y = inventory)
        r <- raster::crop(x = r, y = inventory)

        if (!raster::compareRaster(r, inventory)) {
          stop("Rasters mismatch in their attributes (resolution, crs, etc ...)")
        }
      }

      # check classified image
      cat("Check values \n")
      r.val <- unique(raster::values(r))

      if (length(r.val) == 1 && is.na(r.val)) {
        stop("Raster contains only NAs")
      }


      if (!is.null(env.rsaga)) {
        cat("Processing using SAGA GIS \n")
        tmp.inventory <- file.path(tempdir(), "tmp_inventory.tif")
        tmp.r <- file.path(tempdir(), "tmp_raster.tif")
        tmp.output <- file.path(tempdir(), "tmp_result.sgrd")

        cat("... writing raster \n")
        raster::writeRaster(x = inventory, filename = tmp.inventory, overwrite = TRUE, NAflag = -99999)
        raster::writeRaster(x = r, filename = tmp.r, overwrite = TRUE, NAflag = -99999)

        cat("... start calculation \n")
        # RSAGA::rsaga.get.usage(lib = "grid_calculus", module =  1, env = env.rsaga)
        RSAGA::rsaga.geoprocessor(lib = "grid_calculus", module = 1, env = env.rsaga, show.output.on.console = show.output.on.console, param = list(
          GRIDS = tmp.r, RESULT = tmp.output, FORMULA = "ifelse(a = 0, 0, 2)", FNAME = "1"
        ))

        RSAGA::rsaga.geoprocessor(lib = "grid_calculus", module = 1, env = env.rsaga, show.output.on.console = show.output.on.console, param = list(
          GRIDS = paste0(c(tmp.inventory, tmp.output), collapse = ";"), RESULT = tmp.output, FORMULA = "a+b", FNAME = "1"
        ))

        result <- raster::raster(x = paste0(tools::file_path_sans_ext(tmp.output), ".sdat"))
      } else {
        cat("Processing using R-raster \n")
        # resetNull data
        # r <- raster::calc(x = r, fun = function(x){ifelse(is.na(x) || x == 0, 0, 2)})
        r <- raster::calc(x = r, fun = function(x) {
          ifelse(x == 0, 0, 2)
        })
        raster::plot(r, col = topo.colors(20))

        # overlay data
        result <- raster::overlay(x = r, y = inventory, fun = sum, na.rm = TRUE)
      }


      # get statistics
      cat("Get Statistics \n")
      # ... create data frame
      stat <- table(raster::values(result))
      df.stat <- data.frame(matrix(ncol = length(stat), nrow = 1))
      colnames(df.stat) <- names(stat)
      df.stat[1, ] <- stat

      # ... # 0: TRUE NEGATIVES (TN), 3: TRUE POSITIVES (TP), 1: FALSE NEGATIVES, 2: FALSE POSITIVES
      pos.TN <- grep(pattern = "0", x = colnames(df.stat))
      pos.FN <- grep(pattern = "1", x = colnames(df.stat))
      pos.FP <- grep(pattern = "2", x = colnames(df.stat))
      pos.TP <- grep(pattern = "3", x = colnames(df.stat))

      if (length(pos.TN) > 0) {
        colnames(df.stat)[pos.TN] <- "TN"
      } else {
        df.stat$TN <- 0
      }

      if (length(pos.FN) > 0) {
        colnames(df.stat)[pos.FN] <- "FN"
      } else {
        df.stat$FN <- 0
      }

      if (length(pos.FP) > 0) {
        colnames(df.stat)[pos.FP] <- "FP"
      } else {
        df.stat$FP <- 0
      }

      if (length(pos.TP) > 0) {
        colnames(df.stat)[pos.TP] <- "TP"
      } else {
        df.stat$TP <- 0
      }

      # ... confusion matrix error measurements
      df.stat$TPR <- tryCatch(
        {
          df.stat$TP / (df.stat$TP + df.stat$FN)
        },
        error = function(e) {
          return(NA)
        }
      ) # sensitivity, recall, hit rate, or true positive rate (TPR)
      df.stat$TNR <- tryCatch(
        {
          df.stat$TN / (df.stat$TN + df.stat$FP)
        },
        error = function(e) {
          return(NA)
        }
      ) # specificity or true negative rate (TNR)
      df.stat$FNR <- tryCatch(
        {
          df.stat$FN / (df.stat$FN + df.stat$TP)
        },
        error = function(e) {
          return(NA)
        }
      ) # miss rate or false negative rate (FNR)
      df.stat$FPR <- tryCatch(
        {
          df.stat$FP / (df.stat$FP + df.stat$TN)
        },
        error = function(e) {
          return(NA)
        }
      ) # miss rate or false negative rate (FPR)
      df.stat$acc <- tryCatch(
        {
          (df.stat$TP + df.stat$TN) / (df.stat$TP + df.stat$TN + df.stat$FP + df.stat$FN)
        },
        error = function(e) {
          return(NA)
        }
      ) # accuracy (ACC)

      # ... hard-coded data.frame numbers here!
      df.stat$rndm_acc <- tryCatch(
        {
          ((as.numeric(df.stat$TN + df.stat$FP) * as.numeric(df.stat$TN + df.stat$FN)) + (as.numeric(df.stat$FN + df.stat$TP) * as.numeric(df.stat$FP + df.stat$TP))) / (as.numeric(sum(df.stat[1, 1:4])) * as.numeric(sum(df.stat[1, 1:4])))
        },
        error = function(e) {
          return(NA)
        }
      )
      df.stat$f1score <- tryCatch(
        {
          (2 * df.stat$TP) / ((2 * df.stat$TP) + df.stat$FP + df.stat$FN)
        },
        error = function(e) {
          return(NA)
        }
      ) # F1 score is the harmonic mean of precision and sensitivity

      df.stat$quality <- tryCatch(
        {
          (df.stat$TP) / (df.stat$TP + df.stat$FP + df.stat$FN)
        },
        error = function(e) {
          return(NA)
        }
      ) # Tarolli et al. 2012:77, Heipke et al. (1997)


      # J. Richard Landis and Gary G. Koch - The Measurement of Observer Agreement for Categorical Data, Biometrics, Vol. 33, No. 1 (Mar., 1977), pp. 159-174.
      # http://standardwisdom.com/softwarejournal/2011/12/confusion-matrix-another-single-value-metric-kappa-statistic/
      df.stat$Kappa <- tryCatch(
        {
          (df.stat$acc - df.stat$rndm_acc) / (1 - df.stat$rndm_acc)
        },
        error = function(e) {
          return(NA)
        }
      )

      return(df.stat)
    },
    error = function(e) {
      df.stat <- data.frame(matrix(ncol = 13, nrow = 1))
      colnames(df.stat) <- c("TN", "FN", "FP", "TP", "TPR", "TNR", "FNR", "FPR", "acc", "rndm_acc", "f1score", "quality", "Kappa")
      df.stat[1, ] <- NA

      return(df.stat)
    }
  )
}
