library("mlr3fairness")

rmdfile = report_modelcard()
rmarkdown::render(rmdfile)
