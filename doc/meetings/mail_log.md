> From: Schlögl Matthias  
> Sent: Saturday, 24 February 2024 22:57  
> To: Lampert Jasmin; Rudolf Mayer; Ostermann, Marc; Avian Michael; Jung Martin  
> Cc: Andrea Siposova; Kozlowska Anna; Christina Rechberger; Waltersdorfer, Laura; Susanna Wernhart; Naghibzadeh-Jalali Anahid  
> Subject: Re: [gAia] Update landslide susceptibility model

Good evening,

I have now re-trained the RF model v3.0 as explained on Friday.

I have uploaded the first diagnostic plots as usual to https://edrop.zamg.ac.at/owncloud/index.php/s/n8qYBMc2gM2RfBY.
For a quick first look, I have attached the importance plot, and also added the full correlation matrix and the subset for the actually used features to aid interpretation.

Results tend to look more reasonable now, and some of the PDP plots (e.g.: slope) are eventually plausible imho.
The geological map still does carry very little explanatory power, I suspect that this will lead to discussions.
Even though the classes were summarized, there is very little variation between the different classes (see pdp plots).

Now I still need to implement the relevant masks for predictive purposes as well, run the predictions, and create an updated GeoTiff.
If I have enough time tomorrow I can provide the results by Monday morning.
However, I won't modify the climate precursor data. SPARTACUS / WINFORE pixels might still overlay the image (with SPEI being rather important).
We could smooth the borders between the pixels of the weather data purely for cosmetic purposes during prediction, but that will have to wait until after the workshop.

Best,  
Matthias

---

> Von: Schlögl Matthias  
> Gesendet: Freitag, 23. Februar 2024 13:55  
> An: Lampert Jasmin; Rudolf Mayer; Ostermann, Marc; Avian Michael; Jung Martin  
> Cc: Andrea Siposova; Kozlowska Anna; Christina Rechberger; Waltersdorfer, Laura; Susanna Wernhart; Naghibzadeh-Jalali Anahid  
> Betreff: Re: [gAia] Update landslide susceptibility model

And I did dig up some explanation on the importance of aspect – citing from <https://doi.org/10.1016/j.geomorph.2006.10.032>:

> Slope aspect is frequently used as a predisposing factor in landslide susceptibility assessments (e.g., Salter et al., 1983; van Westen et al., 2008; Galli et al., 2008; Ruff and Czurda, 2008). It has been suggested that contrasting microclimate between slopes of different aspect can produce asymmetric valley morphology through control of slope weathering and erosional and depositional processes (Burnett et al., 2008). The direction of incoming weather events may also create a ‘shadow effect’, impacting some slopes more than others (Liu and Shih, 2013). Crozier et al. (1980) undertook statistical analyses of the distribution of landslides triggered in the winter of 1977 in the Wairarapa and found a strong preference for northerly aspects (61.6% of slips on N, NW, and NE octants). Similarly, another Wairarapa-based study (Gao and Maro, 2010) reports a preference for northerly aspects, which they suggest is a product of deeper weathering from increased solar radiation and wetting and drying cycles experienced by north-facing (southern hemisphere) slopes. Wetting and drying cycles also initiate cracking, resulting in reduced soil cohesion (He et al., 2020) and allowing water to penetrate down to the less permeable bedrock which acts as the surface of rupture (Brooks et al., 2002). The effect of aspect can also be related to structural geology (e.g., dip direction and dip angle of bedding planes; Ruff and Czurda, 2008). Crozier et al. (1980) suggested that preference of landsliding on a particular slope aspect can be temporally dynamic. They found weakest conditions at the bedrock/regolith interface on southerly slopes, and north to west-facing slopes were less disturbed. They therefore postulate that following removal of the original forest cover for pastoral farming, mass movement processes may have initially favoured southern slopes, providing a more extensive, weaker, and undisturbed regolith on north-facing slopes – which was more severely affected in recent times.

The formulation of aspect I used (actan2, based on cosine and sine of the original aspect to account for the circular nature of the variable) is highly correlated with diurnal anisotropic heat (which quantifies the combined characteristics of temperature and topographic solar radiation).

Best,  
Matthias

---

> Von: Schlögl Matthias  
> Gesendet: Freitag, 23. Februar 2024 13:36  
> An: Lampert Jasmin; Rudolf Mayer; Ostermann, Marc; Avian Michael; Jung Martin  
> Cc: Andrea Siposova; Kozlowska Anna; Christina Rechberger; Waltersdorfer, Laura; Susanna Wernhart; Naghibzadeh-Jalali Anahid  
> Betreff: Re: [gAia] Update landslide susceptibility model

Dear all,

I have just pushed another update of the modelling setup to GitHub (tagged as “v3.0”):

In essence, it is (1) a sparser model that employs (2) more intelligent subsampling of negative instances.

Changelog:
-	summarized geological classes in 1:200k map
-	summarized herbaceous permanent land cover classes
-	improved masking by removing the following areas for sampling:
    - anthropogenic deposits
    - swamps/marshes
    - lakes
    - deltas
    - glaciers
    - areas above the 0.99 elevation quantile of observed slides (1900 m a.s.l.)
-	implemented PPS sampling according to <https://doi.org/10.1016/j.scitotenv.2021.145935>
-	removed highly correlated features (mainly related to geomorphometry and precipitation)

This should improve inference without having an overly detrimental effect on model performance.
Also, not sampling outside the convex hull of the feature space of the true instances should be beneficial.

I will submit the job later today, if all goes well I can provide an updated map on Monday.

Best,  
Matthias

---

> Von: Schlögl Matthias  
> Gesendet: Montag, 19. Februar 2024 09:36  
> An: Rudolf Mayer; Lampert Jasmin; Ostermann, Marc; Avian Michael; Jung Martin  
> Cc: Andrea Siposova; Kozlowska Anna; Christina Rechberger; Waltersdorfer, Laura; Susanna Wernhart  
> Betreff: Re: [gAia] Update landslide susceptibility model

Dear all,

I have now uploaded an updated version of the partial dependence and ICE plots for the v2.0 RF model.

I now do plot factor variables as boxplots, which makes much more sense than lineplots.

As expected, some features show seemingly unintuitive effects. For instance, the landslide probability is indirect proportional to the amount of rainfall.
These effects can be explained more or less easily depending on the feature, but since I am no expert on landslide mechanics I can only make guesses about some effects to some limited extent.

I have uploaded the new plots to the owncloud share in case you want to have a brief look: https://edrop.zamg.ac.at/owncloud/index.php/s/n8qYBMc2gM2RfBY
Please keep in mind that no decision has been made in terms of the final model, so the feature importance and single feature effects might still change depending on the model formulation.

Best,  
Matthias

---

> Von: Schlögl Matthias  
> Gesendet: Montag, 19. Februar 2024 09:36  
> An: Rudolf Mayer; Lampert Jasmin; Ostermann, Marc; Avian Michael; Jung Martin  
> Cc: Andrea Siposova; Kozlowska Anna; Christina Rechberger; Waltersdorfer, Laura  
> Betreff: Re: [gAia] Update landslide susceptibility model

Moin,

thanks for your response Rudi.

"stratification" is indeed an unclear term - I was referring to the definition of the classes when discretizing the result. How many do we use, and how do we select the thresholds? If we do that, I think this should be grounded in some conceptual basis. Since it's a binary classification problem, a threshold of 0.5 seems reasonable. There are other approaches in literature, I have used the quite straightforward one by Spiekermann who used the empirical cumulative distribution function of the susceptibility values of all positive instances to derive thresholds. Other approaches include an assessment of ROC or similar metrics.

I did compute another model over the weekend. Again a random forest, but I dropped several highly correlated features and removed features which could reflect mapping bias (distance to roads, features highly correlated to elevation).
The classification error increases substantially from 0.21 to 0.31 in the outer CV.
I am currently running the predictions across the chunks. Since the models get more complicated when the most influential features are removed all steps now take slightly longer. I will send you an update once the map is done, as this won't be finished before our meeting.
Prediction now lasts almost exactly 30 minutes per chunk (I have 20 chunks). After prediction, these chunks need to be combined into a single dataframe and cast into a raster. Results should be available tomorrow.

Best,  
Matthias

P.S.: I just thought about adding a git tag to keep better track of the model runs. I did so with this version (v2.0).

---

> From: Rudolf Mayer <rmayer@sba-research.org>  
> Sent: Sunday, 18 February 2024 20:49:40  
> To: Schlögl Matthias; Lampert Jasmin; Ostermann, Marc; Avian Michael; Jung Martin  
> Cc: Andrea Siposova; Kozlowska Anna; Christina Rechberger; Waltersdorfer, Laura  
> Subject: Re: [gAia] Update landslide susceptibility model

Dear Matthias,

thanks once again for the great work you did with preparing the model, and for your meticulous summary and documentation you provide alongside!
That's really useful to have!


I can't provide too much technical feedback, but let me comment on a few questions.

> Discretizing results: Yes or no?

I personally generally favour to not discretize, because it might lead to unwanted edge cases where a seemingly arbitrary value will change the outcome.
Maybe this is a question to ask the experts as well, what they would prefer.

> If yes, how do we stratify the classes (my first used the approach by Spiekermann et al. (2023)[^1])

I am no 100% sure I understand what you mean with stratification here, because I only know the term for sampling; but I guess you mean that the sizes of the resulting output categories should be somehow decided (i.e. you perform the discretisation / binning not on given threshold values, but rather you select the values to achieve certain bin sizes?)

> If I were a stakeholder I would expect that these questions are answered by a project of this scope and size. The proper approach would be to adjust and re-train the model given the new findings, especially w.r.t feature selection and definition. Since we don't really have time for that anymore I think it will be crucial to have a solid line of communication during the workshop.

I do agree that some of these questions indeed could at least be provided with more evidence from the project itself, by maybe having tried a few more runs with various configurations. And true, we also do have expertise within the consortium to at least discuss some of these questions internally.

But I do also think it is legitimate to go to the stakeholders with (some of) these questions, and ask them for their unbiased opinions.
Maybe retraining the model after the feedback and insights from the workshop might be an option, though then there's no more feedback loop possible.

kind regards  
Rudi

---

> Von: Schlögl Matthias  
> Gesendet: Freitag, 16. Februar 2024 16:29  
> An: Lampert Jasmin; Ostermann, Marc; Avian Michael; Jung Martin  
> Cc: Andrea Siposova; Rudolf Mayer; Kozlowska Anna; Christina Rechberger; Waltersdorfer, Laura  
> Betreff: Re: [gAia] Update landslide susceptibility model

Dear all,

following today's meeting I'd like to share some points that I noted for further discussion after my first look at the current results:

- Model comparison (MARS, Random Forest) - which model should be presented as final model? Multiple models might be confusing.
- Added value of versus problems caused by the inclusion of the effectively surveyed area?
- Discretizing results
    - Yes or no?
    - If yes, how do we stratify the classes (my first used the approach by Spiekermann et al. (2023)[^1])
- Feature Selection & Definition
    - This should have happened before training the models, but due to limited feedback I just went with what I had and I'm just empirically learning stuff afterwards.
    - Hint: Look at correlations between features
- Feature Importance:
    - Is feature importance plausible?
    - If no: why not, and where do these implausible effects come from?
    - Do we still have some inventory bias due to high correlation of the most important features with elevation?
    - What about forest roads? Are these effects caused by distance to roads or some other feature?
    - What about the aspect-bias (higher susc on southern slopes)?
    - Why is slope not relevant?
    - Why is geology not relevant?
        - Is there even any added value in using higher resolution geological maps? 1:50k vs 1:200k vs 1:500k? In my view, 1:50k is not necessarily more detailed as 1:200k or 1:500k.
        - Number, extent/size and type of classes. We might have needed some feature engineering here?
- IML:
    - Are effects of features plausible (ALE/PDP + ICE plots)
- Model performance:
    - Is the approach sound? (balanced bagging w/ nested spatial CV)
    - Are the chosen models feasible?
    - Which metrics do we want to look at?
    - Check distributions of predictors per class?

[^1]: Spiekermann, R.I., Van Zadelhoff, F., Schindler, J., Smith, H., Phillips, C., Schwarz, M., 2023. Comparing physical and statistical landslide susceptibility models at the scale of individual trees. Geomorphology 440, 108870. https://doi.org/10.1016/j.geomorph.2023.108870.

Again some literature as basis for discussion:

- Counteracting flawed landslide data in statistically based landslide susceptibility modelling for very large areas:  
  https://doi.org/10.1007/s10346-021-01693-7
- Choice of modelling approaches:  
  https://doi.org/10.1016/j.cageo.2015.04.007
- Potential underestimation of landslide impact areas:  
  https://doi.org/10.1016/j.geomorph.2023.108638
- Discrepancies between quantitative validation results and the geomorphic plausibility of statistical landslide susceptibility maps:  
  https://doi.org/10.1016/j.geomorph.2016.03.015

If I were a stakeholder I would expect that these questions are answered by a project of this scope and size. The proper approach would be to adjust and re-train the model given the new findings, especially w.r.t feature selection and definition. Since we don't really have time for that anymore I think it will be crucial to have a solid line of communication during the workshop.

Best,\
Matthias

P.S. @Michael: c/p from https://gitlab.geosphere.at/klifofo-kleo/forschungsprojekte/gaia/-/issues/55#note_58157. 

---

> From: Schlögl Matthias  
> Sent: Friday, 9 February 2024 15:39:29  
> To: Lampert Jasmin; Ostermann, Marc; Avian Michael; Jung Martin; Waltersdorfer, Laura  
> Cc: Andrea Siposova; Rudolf Mayer; Kozlowska Anna; Christina Rechberger  
> Subject: Re: [gAia] Update landslide susceptibility model

Dear all,

all three models (random forest, MARS with and without ESA) are now trained/fitted, and I have just completed the prediction for the last model.

All trained models, the resulting susceptibility maps (mean + sd), as well as predictions (as dataframes) are available on kronos at

```bash
/newstorage2/gaia/wp5/susceptibility_modelling/carinthia/
.
├── aoi_input
│   ├── carinthia_10m.arrow
│   ├── carinthia_10m.parquet
│   ├── gaia_aoi_ktn_3416.gpkg
│   └── gaia_ktn_balanced_iters.qs
├── ls_output
│   ├── maps_geotiff
│   │   ├── mars_with_esa
│   │   │   ├── susceptibility_mean_earth_esa.tif
│   │   │   └── susceptibility_sd_earth_esa.tif
│   │   ├── mars_without_esa
│   │   │   ├── susceptibility_mean_earth.tif
│   │   │   └── susceptibility_sd_earth.tif
│   │   ├── random_forest
│   │   │   ├── susceptibility_mean_random_forest.tif
│   │   │   └── susceptibility_sd_random_forest.tif
│   │   └── random_forest.old
│   │       ├── susceptibility_mean.tif
│   │       └── susceptibility_sd.tif
│   └── predictions
│       ├── earth_esa_prediction_mean_sd_sf.qs
│       ├── earth_prediction_mean_sd_sf.qs
│       ├── gaia_ktn_balanced_iters.qs
│       ├── gaia_ktn_balanced_iters_spatialfolds.qs
│       ├── random_forest_prediction_mean_sd_sf.old.qs
│       └── random_forest_prediction_mean_sd_sf.qs
└── models
    ├── mars_with_esa
    │   └── earth_mbo_esa.rds
    ├── mars_without_esa
    │   └── earth_mbo.rds
    └── random_forest
        ├── ranger_mbo.rds
        └── ranger_nested_resampling.rds

12 directories, 22 files
```

A quick visualization in QGIS and some diagnostic plots are available at https://edrop.zamg.ac.at/owncloud/index.php/s/n8qYBMc2gM2RfBY.

- (1) I have created one plot with a continuous color scale and
- (2) I made one attempt at classifying the results into three classes. I followed the approach by Spiekermann et al. (2023) [^1]. I have uploaded the relevant figure from the paper and my own quick implementation of the decreasing rank order plot. The classification is rather simple, but should be quite straightforward communicate to stakeholder. I used thresholds the same thresholds as used in the paper (0.8 and 0.95).
- (3) I have also uploaded letter-value plots of the susceptibility values across the whole raster of the AOI, given the observed labels.
- (4) I have also added the feature importance plots.
- (5) In order to aid interpretation I have added a plot of the correlation matrix for all numeric features.

Performance metrics will follow, the nested resampling for the MARS model should be finished after the weekend.

I think it would be great if you could have a look at the results to have an informed basis for discussion for our internal meeting before the stakeholder workshop.

Best,  
Matthias

[^1]: Spiekermann, R.I., Van Zadelhoff, F., Schindler, J., Smith, H., Phillips, C., Schwarz, M., 2023. Comparing physical and statistical landslide susceptibility models at the scale of individual trees. Geomorphology 440, 108870. https://doi.org/10.1016/j.geomorph.2023.108870.

---

> Von: Schlögl Matthias  
> Gesendet: Mittwoch, 14. Februar 2024 15:56  
> An: Lampert Jasmin; Ostermann, Marc; Avian Michael; Jung Martin; Waltersdorfer, Laura  
> Cc: Andrea Siposova; Rudolf Mayer; Kozlowska Anna; Christina Rechberger  
> Betreff: Re: [gAia] Update landslide susceptibility model
 
Hi,

here are the quantiles of elevation for all slides in Carinthia:

| Quantile | elevation [m] |
|---------:| -------------:|
|      90% |          1329 |
|      91% |          1360 |
|      92% |          1383 |
|      93% |          1416 |
|      94% |          1457 |
|      95% |          1483 |
|      96% |          1560 |
|      97% |          1657 |
|      98% |          1755 |
|      99% |          1908 |
|     100% |          3166 |

Best,  
Matthias

---

> From: Lampert Jasmin <Jasmin.Lampert@ait.ac.at>  
> Sent: Friday, 9 February 2024 10:15:58  
> To: Schlögl Matthias; Ostermann, Marc; Avian Michael; Jung Martin; Waltersdorfer, Laura  
> Cc: Andrea Siposova; Rudolf Mayer; Kozlowska Anna; Christina Rechberger  
> Subject: AW: [gAia] Update landslide susceptibility model

Dear Matthias,

thanks and that's great news! I The feature importance plots look quite different to our last version. That's something we definitively need to discuss. Let's cross fingers that our XAI analysis provides reasonable results as well. This could help with the interpretation of your results.

Best wishes  
Jasmin

---

> From: Lampert Jasmin  
> Sent: Friday, 9 February 2024 10:15  
> To: Schlögl Matthias; Ostermann, Marc; Avian Michael; Jung Martin; Waltersdorfer, Laura  
> Cc: Andrea Siposova; Rudolf Mayer; Kozlowska Anna; Christina Rechberger  
> Subject: AW: [gAia] Update landslide susceptibility model

Dear Matthias,

thanks and that's great news! I The feature importance plots look quite different to our last version. That's something we definitively need to discuss. Let's cross fingers that our XAI analysis provides reasonable results as well. This could help with the interpretation of your results.

Best wishes  
Jasmin

---

> Von: Schlögl Matthias <Matthias.Schloegl@geosphere.at>  
> Gesendet: Donnerstag, 8. Februar 2024 09:42  
> An: Ostermann, Marc; Lampert Jasmin; Avian Michael; Jung Martin; Waltersdorfer, Laura  
> Cc: Andrea Siposova; Rudolf Mayer; Kozlowska Anna; Christina Rechberger  
> Betreff: Re: [gAia] Update landslide susceptibility model

Dear all,

another status update from my side.

I am currently computing three models in parallel:

(1) Training and prediction of the random forest model is completed. I am now creating the final geotiffs for mean + standard deviation.
(2) Training of the MARS model w/ the effectively surveyed area is completed. Prediction is running.
(3) Training of the MARS model w/o the effectively surveyed area is running.

If all goes as planned I can provide the maps for random forest and earth by tomorrow or at least by Monday.

**Model performance**  
Results of the nested resampling suggest a classification error of around 0.2 (mean over the ensemble, outer CV loop).
Nested CV for the two MARS models is still outstanding, I will submit these jobs after all predictions are available.
Further investigations of model performance will follow.

**Feature importance**  
I have attached the feature importance plots of the RF model and the MARS model w/ ESA.
It turns out that both slope and lithological class, which have been identified as important in the workshop, are not that important at all.
Only the lithological class "Schwemmkegel / Schwemmfächer" (i.e., alluvial fans) survives the regularization in the MARS model, and slope is dropped completely.
I suspect that slope is covered implicitly by other DTM features such as wind exposition index, maximum height or something similar - I still need to check the correlations and distributions there.

**Model cards**  
@Laura: I haven't forgotten about the model cards, these were just no priority until now.
I will create model cards once the models have been trained. I plan to use https://mlr3fairness.mlr-org.com/ for that.
All my predictions are based on ensembles of 10 models each, so this will result in 10*3 model cards altogether.
I'll have a look at the package and try that out for the random forest model. I'll get back to you if I have any questions.

Best,  
Matthias

---

> From: Schlögl Matthias  
> Sent: Tuesday, 6 February 2024 16:54:29  
> To: Ostermann, Marc; Lampert Jasmin; Avian Michael; Jung Martin  
> Cc: Andrea Siposova; Rudolf Mayer; Anna Kozlowska  
> Subject: Re: [gAia] Update landslide susceptibility model

Hi,

just a quick update / changelog tomorrow - I have implemented the following updates w.r.t. the dummy model:

- af9d4c84 | use of the consolidated inventory
- 68d42ef3 | update of the feature "lithology" (now 1:200k)
- 7a36bf40 | inclusion of the newly computed feature "tree height" (from nDSM)
- 2290a235 | computation of the "effectively surveyed area"
- b50c6784 | absence instance sampling: bugfix in st_difference, use of 300 m buffer (instead of 1000 m)
- 21e57389 | dropped elevation, flow path length, flow width and sca from the model
- 5acfcd21 | implemented MARS model in addition to random forest (to test effect of ESA)

The use of features that reflect sampling bias (effectively surveyed area, elevation) in any tree-based model is problematic imho. Elevation could work (as it is numeric), but ESA (a binary feature) is somewhat nonsensical. The feature is extremely important (see attachment) and almost performs complete separation. Therefore, setting this feature to 0 (this is what we would do when using classical statistical model, as this would change only the intercept of this effect) essentially means that the branches of the trees for presence instances are completely ignored, which is clearly not what we want. We could include elevation and replace it with its median for the prediction, but I haven't really thought about the implications yet and I am quite hesitant to do this. I will however try to fit a GAM or MARS model to investigate the effect of including the effectively surveyed area.

I also realized that we could treat the whole problem as a semi-supervised learning problem, but I'm not sure how we could approach this ad hoc, or if this would even work.
Labels for the positive class are obvious, but setting up the negative class would require some tinkering.
See https://cran.r-project.org/web/packages/RSSL/ or https://scikit-learn.org/stable/modules/semi_supervised.html.

Best,
Matthias

---

> From: Ostermann, Marc  
> Sent: Tuesday, 6 February 2024 15:23:01  
> To: Lampert Jasmin; Avian Michael; Jung Martin  
> Cc: Schlögl Matthias; Andrea Siposova; Rudolf Mayer  
> Subject: AW: [gAia] Update landslide susceptibility model

Dear Jasmin,

As feedback, it seems to me that the modelling approach is plausible.
I am abroad until 16 February and cannot take part in the JF.

All the Best  
Marc

---

> Von: Lampert Jasmin  
> Gesendet: Dienstag, 6. Februar 2024 14:38  
> An: Avian Michael; Ostermann, Marc; Jung Martin  
> Cc: Schlögl Matthias; Andrea Siposova; Rudolf Mayer  
> Betreff: AW: [gAia] Update landslide susceptibility model  
> Priorität: Hoch  

Dear Michael, Marc and Martin,

so far, I only received an out-of-office reply as response to my email last week 😞. Since Matthias and me require your feedback, when would you be available for a discussion?

Best wishes  
Jasmin

---

> Von: Lampert Jasmin  
> Gesendet: Mittwoch, 31. Januar 2024 16:03  
> An: Avian Michael; Ostermann, Marc; Jung Martin  
> Cc: Schlögl Matthias; Andrea Siposova; Rudolf Mayer  
> Betreff: [gAia] Update landslide susceptibility model

Dear Michael, Marc and Martin,

we are in a critical face of our project and in order to provide convincing results at the stakeholder feedback meeting, we would require your feedback. In particular the geomorphic plausibility of Matthias' approach would be important to discuss with you. I suggest that we make use of our regular JF on Feburary, 6th. Would this work for you?

Best wishes and thanks  
Jasmin

---

> Von: Schlögl Matthias  
> Gesendet: Montag, 29. Januar 2024 11:16  
> An: Rudolf Mayer; Andrea Siposova; Lampert Jasmin; Avian Michael  
> Cc: Ostermann, Marc; Jung Martin  
> Betreff: [gAia] Update landslide susceptibility model

Dear all,

I'd like to provide a short update on my LS modelling efforts, including changes I have implemented or plan to implement in contrast to my initial first draft model.

Maybe we can use this as a basis for a discussion during our weekly on Wednesday or during the next consortium jour fixe.

- (1) I now have a final consolidated inventory to start from. The final dataset is an important basis, as considerations w.r.t. conditional distributions of features in both classes need to be explored when using a parametric model. Exploratory data analysis would be important as well. I will skip this step due to time constraints and use a non-parametric model anyways.
- (2.1) Features: The features are primarily based on the ones I used in previous studies on debris flows. I made some changes as the process types of torrential flooding and landslides are inherently different from a geomorphologic perspective. Personally, I have a better understanding of the underlying cause-effect relationships in terms of triggering rainfall and available mobilizable sediment for torrential flooding (e.g. https://doi.org/10.1002/esp.5533) than for landslides. My original selection of features can be found at https://github.com/gAia-KIRAS/wp2-geobia/blob/main/doc/data_description/ls_model_feature_description.md.
- (2.2) I will drop elevation as feature, as this merely reflects a certain inventory bias. I missed to exclude this feature in the initial model, as I just included all DTM features to perform a technical test run.
- (2.3) I will swap the geological map from 1:500k with the 1:200k one. As far as I can judge that as a layman I think that the 1:50k one is too inconsistent.
- (2.4) The discussion on feature definition and selection has been somewhat limited, I will just go with the features and changes summarized above, unless there are any additional comments.
- (3) In addition, I propose to mask out the prediction for elevation ranges outside the observed feature space of events.
- (4) I have started computing the effectively surveyed area by adopting the method of https://doi.org/10.5194/nhess-18-2455-2018. This has been running over the weekend and should be completed today in the night. Even though the inclusion of this feature (1) has the potential to conflate different issues, (2) introduces further uncertainty by relying on certain assumptions and (3) may not really solve the underlying problem of spatially inhomogeneous inventories, I think that controlling for the effectively surveyed area in the model is beneficial in reducing the mapping bias (in particular, the master's thesis was only focused on the north-western parts of the AOI).
- (5) As for the modelling approach, I will stick to an ensemble of random forest using balanced bagging (https://doi.org/10.1016/j.aap.2019.105398), tuned/validated and tested using nested spatial cross validation (following https://doi.org/10.1016/j.ecolmodel.2019.06.002; albeit the arguments in https://doi.org/10.1016/j.geomorph.2016.03.015 would be interesting to explore further) and Bayesian Model-Based Optimization for hyperparameter tuning (https://arxiv.org/abs/1703.03373). I do sample the absence points at a certain distance from the existing points, based on the maximum area of the mapped polygons.

That being said, we should be aware that several limitations will remain for obvious reasons. There are some considerations that I would have liked to include, explore and discuss, most notably related to tackling biases in the model (target variable), a comparison of different modelling approaches (smooth prediction surfaces vs spatial artifacts caused by splits in features) and of course the assessment of geomorphic plausibility. Some quick references:

- Counteracting flawed landslide data in statistically based landslide susceptibility modelling for very large areas:  
  https://doi.org/10.1007/s10346-021-01693-7
- Choice of modelling approaches:  
  https://doi.org/10.1016/j.cageo.2015.04.007
- Potential underestimation of landslide impact areas:  
  https://doi.org/10.1016/j.geomorph.2023.108638
- Discrepancies between quantitative validation results and the geomorphic plausibility of statistical landslide susceptibility maps:  
  https://doi.org/10.1016/j.geomorph.2016.03.015

Since the stakeholder workshop is approaching fast I think that we should also think about how we will communicate the results.

Once we have the final modelling results this might be easier, but there might be little time left to discuss that properly.

My current take is this: Just given the very limited amount of time that is available for conducting the modelling with the actual final data set, the result will fall short of what could have been possible within the original timeline. I would like to avoid that this is (1) attributed to inabilities on our (i.e., my) end to conduct proper modelling using state-of-the art methods, or (2) reinforce existing skepticism towards using statistical learning approaches for creating landslide susceptibility map.

I think we should openly discuss potential discrepancies between the results of the model and the geomorphic plausibility, mention the reasons why we had to cut corners, and also mention how certain issues might manifest themselves in the output.

Internally, I will try to discuss the results with my colleagues Stefan Steger and Raphael Spiekermann (who have proven expertise in landslide susceptibility modelling) over a coffee.

If you have any comments or further suggestions (either on the modelling approach or on the communication of the outcome) - any feedback would be appreciated.

Best,  
Matthias

---
