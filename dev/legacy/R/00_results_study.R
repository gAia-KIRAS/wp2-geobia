# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# RESULTS OF STUDY
#
# Raphael Knevels
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DESCRIPTION:
# Main results of study are presented.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# CONTENT -----------------------------------------------------------------
# 1 PACKAGES, FUNCTIONS & DATA
# 2 PRESENTATION OF DATA
# 3 VISUALISATION OF RESULTS





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1 PACKAGES, FUNCTIONS & DATA ------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


if("source.R" %in% list.files(file.path(here::here(), "R"))){
  source(file.path(here::here(), "R", "source.R"))
  source(file.path(here::here(), "R", "helper.R"))
} else {
  stop("Please set your working directory to the project path!")
}

# load main study results
results_study <- readRDS(file = file.path(path_result, "results_study.rds"))




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 2 PRESENTATION OF DATA --------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

names(results_study)
# [1] "inventory"       inventoried landslides and inventoried landslide parts    
# [2] "classif_mlr"     all around the tuned trainings SVM model   
# [3] "classif_varImp"  variable importance of model
# [4] "classif_Lslide"  classification results: predictions and post-processings
# [5] "classif_acc"     accuracies of classification  
# [6] "optim_HPFT"      result of optimization procedure for `mask` step
# [7] "optim_SegmScrp"  result of optimization procedure for `segment` step: Scarps (GRASS GIS)
# [8] "optim_SegmBdy"   result of optimization procedure for `segment` step: Body (SAGA GIS)


# [1] Inventory of study:
# Inventory consists of complete polygons (results_study$inventory$inv) and of 
# landslide parts (scarp and body, results_study$inventory$inv_prts)
names(results_study$inventory) # "inv"      "inv_prts"
plot(main = "inventory of validation area", 
     results_study$inventory$inv_prts %>% dplyr::filter(TEST == 1) %>% sf::st_geometry(.))



# [2] MLR tuned SVM on trainings data:
# MLR results contains trainings data, tuning results, tuned SVM learner, the tuned model, predictions and performance results
names(results_study$classif_mlr) # "task"          "tune_result"   "tuned_learner" "model"         "pred"          "perf"   
results_study$classif_mlr


# [3] Variable importance of model:
results_study$classif_varImp$res %>% .[order(.)]


# [4] Classification results in validation area
# Consisting of predictions (results_study$classif_Lslide$pred) and post-processings (results_study$classif_Lslide$postpros)
# ... plot TRUE predictions (blue)
plot(main = "Overview Classification \nin Validation Area", 
     results_study$classif_Lslide$pred %>% dplyr::filter(response != 0) %>% sf::st_geometry(.), col = "blue", border = "blue")

# ... add post-processed landslides (red border)
plot(results_study$classif_Lslide$postpros %>% sf::st_geometry(.), border = "red", add = TRUE)

# ... add inventoried landslides (yellow border)
plot(results_study$inventory$inv_prts %>% dplyr::filter(TEST == 1) %>% sf::st_geometry(.), add = TRUE, border = "yellow")


# [5] accuracies of classification  
results_study$classif_acc
#         Type       TN     FN      FP     TP       Kappa     Acc_Obj
# 1 Post-processed 54911628 497334 1461213 946588 0.4751255 66.12022
# 2    Predictions 54401283 478336 1971558 965586 0.4214253 68.85246


# [6] optimization procedure for `mask` step
results_study$optim_HPFT %>% .[order(.$fscore_3, decreasing = T),] %>% head(.)
#         scale threshold  fscore_3       
# 1195    16       5.5     0.1528987 


# [7] optimization procedure for `segment` step: Scarps (GRASS GIS)
results_study$optim_SegmScrp %>% .[order(.$Objective.Function, decreasing = T),] %>% head(.) 
# X Scale.Parameter Minsize Intrasegment.Variance Normalized.Intrasegment.Variance  Morans.I Normalized.Morans.I Objective.Function   Plateau
# 4   4           0.095      50              24.45047                        0.2142225 0.4158452          0.80030297           1.014525 0.9852926
# 6   6           0.085      50              23.07829                        0.3588192 0.4516607          0.65483522           1.013654 0.9852926
# 8   8           0.075      50              21.67575                        0.5066144 0.4881634          0.50657627           1.013191 0.9852926


# [8] optimization procedure for `segment` step: Body (SAGA GIS)
results_study$optim_SegmBdy %>% .[order(.$Objective.Function, decreasing = T),] %>% .[1:10,] 
# X Scale.Parameter Intrasegment.Variance Normalized.Intrasegment.Variance  Morans.I Normalized.Morans.I Objective.Function  Plateau
# 23 23            2.50              5.097085                        0.8743561 0.5662416           0.5623435           1.436700 1.268395
# 22 22            2.75              5.198469                        0.8302675 0.5519057           0.6036153           1.433883 1.268395
# 20 20            3.25              5.412814                        0.7370559 0.5209286           0.6927954           1.429851 1.268395
# 21 21            3.00              5.296182                        0.7877752 0.5407650           0.6356883           1.423463 1.268395
# 24 24            2.25              4.991356                        0.9203342 0.5884183           0.4984988           1.418833 1.268395
# 25 25            2.00              4.899685                        0.9601991 0.6053497           0.4497549           1.409954 1.268395
# 19 19            3.50              5.530573                        0.6858461 0.5122013           0.7179204           1.403767 1.268395
# 18 18            3.75              5.632899                        0.6413479 0.4995996           0.7541995           1.395547 1.268395
# 17 17            4.00              5.736171                        0.5964384 0.4907868           0.7795707           1.376009 1.268395
# 16 16            4.25              5.827289                        0.5568138 0.4841982           0.7985389           1.355353 1.268395





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 3 VISUALISATION OF RESULTS ----------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# ... Plot of optimization procedure for `mask` step
breaks.contour <- c(0.05, 0.10, 0.13, 0.15)
f_score.selection <- results_study$optim_HPFT %>% .[order(.$fscore_3, decreasing = T),] %>% .[1,]

ggplot(results_study$optim_HPFT, aes(x = scale, y = threshold, z = fscore_3)) +
  geom_tile(aes(fill = fscore_3), color = "white") +
  scale_fill_gradient(low = "white", high = "steelblue", na.value = "white") +
  geom_contour(breaks = breaks.contour, binwidth = 0.005, colour = "black", na.rm = TRUE, show.legend = FALSE) + 
  directlabels::geom_dl(aes(label=..level..), stat="contour", 
                        method = list("top.pieces", cex=0.7, colour = "black", fontfamily="Arial"), breaks = breaks.contour) + # top.pieces
  geom_point(aes(x = f_score.selection$scale, y = f_score.selection$threshold, shape = "shape scale"), color = "gold", size = 1.2, stroke = 1.2) + 
  scale_shape_manual(name = "", labels = "selected optimum", values = c(`shape scale` = 19)) +
  ylab("threshold [°]") +
  xlab("scale factor") +
  theme_bw() +
  labs(fill = "F-score, beta = 3") +
  theme(legend.title = element_text(size = 11, face = "bold"),
        legend.text = element_text(size = 11, face = "bold"),
        plot.title = element_text(size=13),
        axis.title = element_text(size=11,face="bold"),
        axis.text.x = element_text(hjust = 1, margin = margin(t = 10)),
        axis.text =  element_text(size=11),
        axis.title.y = element_text(face = "bold", size = 11, margin = margin(r = 10)), 
        plot.caption = element_text(hjust=0.5, size = 13, face = "bold"),
        legend.margin = margin(t = -10, r = 0, b = -5, l = 0, unit = "pt"),
        text = element_text(family="Arial")) + 
  guides(fill = guide_colourbar(order = 1),
         colour = guide_legend(order = 2),
         shape = guide_legend(order = 3))



# ... Plot of optimization procedure for `segment` step: Scarps (GRASS GIS)
Lslide::plotObjectiveFunction(results_study$optim_SegmScrp, selected.Scale = 0.075, selected.Scale.size = 4, selected.Scale.label = "selected local optimum", 
                              y.axis.label.left = "objective function values", y.axis.label.right = "normalized values") + 
  ggplot2::xlab("Threshold") + 
  scale_x_continuous() + 
  theme(axis.text = element_text(size = 11), text = element_text(family="Arial"))



# ... Plot of optimization procedure for `segment` step: Body (SAGA GIS)
Lslide::plotObjectiveFunction(results_study$optim_SegmBdy, selected.Scale = 3.25, selected.Scale.size = 4, selected.Scale.label = "selected local optimum", 
                              y.axis.label.left = "objective function values", y.axis.label.right = "normalized values") + 
  ggplot2::xlab("Level of Generalisation") + 
  scale_x_continuous() + 
  theme(axis.text = element_text(size = 11), text = element_text(family="Arial"))




# ... Plot of Variable Importance

varTable <- data.frame(
  Variable = c("Comp", "Conv", 
               "CvMi7", "CvMi7_nF", "CvMi7_nQ", "CvMx7", "CvMx7_nF", "CvMx7_nQ", "CvPlan7", "CvPlan7_nF",
               "CvPlan7_nQ", "CvProf7", "CvProf7_nF", "CvProf7_nQ", "FlAccL", "FlAccL_nF", "FlAccL_nQ", "LeWiRat", "MnToFlDir", "Mx_Dist", 
               "normH", "normH_nF", "normH_nQ", "Open", "Open_nF", "Open_nQ", "P_A", "RI15", "RI15_nF", "RI15_nQ", 
               "Sh_Ind", "Slp", "Slp_nF", "Slp_nQ", "SVF", "SVF_nF", "SVF_nQ", 
               "TFD_Ent", "TFD_Ent_nF", "TFD_Ent_nQ", "TFD_SD", "TFD_SD_nF", "TFD_SD_nQ"),
  Name_full = c("compactness", "convexity", "curvature, minimum", "curvature, minimum, flow contiguity", "curvature, minimum, Queen's contiguity",
                "curvature, maximum", "curvature, maximum, flow contiguity", "curvature, maximum, Queen's contiguity",
                "curvature, plan", "curvature, plan, flow contiguity", "curvature, plan, Queen's contiguity",
                "curvature, profile", "curvature, profile, flow contiguity", "curvature, profile, Queen's contiguity",
                "flow accumulation", "flow accumulation, flow contiguity", "flow accumulation, Queen's contiguity",
                "length-width ratio", "object orientation to flow direction", "maximum distance between polygon's vertices", 
                "normalized height", "normalized height, flow contiguity", "normalized height, Queen's contiguity",
                "openness", "openness, flow contiguity", "openness, Queen's contiguity", "interior edge ratio",
                "roughness index", "roughness index, flow contiguity", "roughness index, Queen's contiguity", "shape index",
                "slope", "slope, flow contiguity", "slope, Queen's contiguity",
                "sky-view factor", "sky-view factor, flow contiguity", "sky-view factor, Queen's contiguity",
                "texture entropy", "texture entropy, flow contiguity", "texture entropy, Queen's contiguity",
                "texture standard deviation", "texture standard deviation, flow contiguity", "texture standard deviation, \nQueen's contiguity"),
  Name = c("compactness", "convexity", "curvature, minimum", "curvature, minimum, \nflow contiguity", "curvature, minimum, \nQueen's contiguity",
           "curvature, maximum", "curvature, maximum, \nflow contiguity", "curvature, maximum, \nQueen's contiguity",
           "curvature, plan", "curvature, plan, \nflow contiguity", "curvature, plan, \nQueen's contiguity",
           "curvature, profile", "curvature, profile, \nflow contiguity", "curvature, profile, \nQueen's contiguity",
           "flow accumulation", "flow accumulation, \nflow contiguity", "flow accumulation, \nQueen's contiguity",
           "length-to-width ratio", "object orientation \nto flow direction", "maximum distance \nbetween polygon's vertices", 
           "normalized height", "normalized height, \nflow contiguity", "normalized height, \nQueen's contiguity",
           "openness", "openness, \nflow contiguity", "openness, \nQueen's contiguity", "interior edge ratio",
           "roughness index", "roughness index, \nflow contiguity", "roughness index, \nQueen's contiguity", "shape index",
           "slope", "slope, \nflow contiguity", "slope, \nQueen's contiguity",
           "sky-view factor", "sky-view factor, \nflow contiguity", "sky-view factor, \nQueen's contiguity",
           "texture entropy", "texture entropy, \nflow contiguity", "texture entropy, \nQueen's contiguity",
           "texture standard deviation", "texture standard deviation, \nflow contiguity", "texture standard deviation, \nQueen's contiguity"),
  Type = c("SM", "SM", rep("LSP", 15),  "SM", "SM", "SM", rep("LSP", 6), "SM", rep("LSP", 3), "SM", rep("LSP", 6), rep("T", 6)),
  stringsAsFactors = FALSE)

varImp.top <- 10

df_varImp <- varTable %>% merge(x = ., by = "Variable", all.x = TRUE,
                                      y = results_study$classif_varImp$res %>% t(.) %>% as.data.frame(.) %>% dplyr::mutate(Variable = rownames(.))) %>%
                                dplyr::mutate(., Kappa = kappa * (-1), Rank = rank(kappa)) %>%
                          .[order(.$Kappa, decreasing = TRUE), ] %>% .[1:varImp.top, ] %>%
                          .[order(.$Kappa, decreasing = FALSE), ] %>%
                          dplyr::mutate(Name = factor(x = Name, levels = Name))


ggplot2::ggplot(df_varImp , ggplot2::aes(x = Name, y = Kappa, fill = Type), colour = NA) + 
  ggplot2::geom_bar(stat="identity") +
  ggplot2::labs(x = "Variable", y = "Mean decrease in κ") +
  ggplot2::scale_y_continuous(breaks = seq(0, 1, 0.1), limits = c(0, 0.5)) +
  ggplot2::coord_flip() + 
  ggplot2::theme_bw() +
  scale_fill_manual(name = "", label = c("land-surface variables", "shape metrics", "topographically-guided textural features"), values = c("#6959cd", "#CD4F39", "#8b8989")) + # adapt here
  theme_bw() +
  theme(legend.position = "bottom", text = element_text(size = 10, face = "bold", family="Arial"),
        axis.title.y = element_text(margin = margin(t = 0, r = 20, b = 0, l = 0)),
        axis.title.x = element_text(margin = margin(t = 10)),
        axis.text.y = element_text(vjust = 0.5, size = 8),
        axis.text.x = element_text(size = 8))
