# gAIa

## Project description
tbd

## Overview 

The general structure is as follows:
- `dat`: data sets
- `dev`: development (scripts)
- `doc`: documentation (e.g. reports, dissemination)
- `gis`: (Q)GIS-projects
- `org`: organizational stuff (e.g. contract, accounting)
- `plt`: plots / figures

Specifically, the data folder `dat` is structured as follows:

```sh
dat
├── interim    » Intermediate data that has been transformed.
├── processed  » Canonical output data sets.
├── raw        » The original, immutable data dump.
└── reporting  » Final data sets for delivery/reporting.
```

## Conventions

### Coding style
**Python**
- Use [`black`](https://github.com/psf/black) as autoformatter
- Recommended editor: [VSCode](https://code.visualstudio.com/docs/python/python-tutorial)

**R**
- [tidyverse style guide](https://style.tidyverse.org/)
- Use `tidyverse`
- Use `sf` for vector data and `stars` for raster data.
- Recommended editor:
    - [RStudio](https://www.rstudio.com/)
    - [VScode](https://marketplace.visualstudio.com/items?itemName=Ikuyadeu.r) w/ [radian](https://github.com/randy3k/radian)


### Visualization
- Use of colors: For color coding data visualizations it is crucial to choose a palette that appropriately captures the underlying information. Please refer to color palettes as provided in the [HCL Wizard](https://hclwizard.org/) and use the respective `colorspace`  packages for [R](http://colorspace.r-forge.r-project.org/) and [Python](https://python-colorspace.readthedocs.io/en/latest/).
- Color advice for maps is available at the [Color Brewer](https://colorbrewer2.org/).
- Check out [Question-based visualizations](https://graphicsprinciples.github.io/qbv.html) for help on visualizing the underlying scientific questions of interest clearly and explicitly.


### Commit messages
- Commit messages should be clear and unambiguous.
- Please use imperative present tense for commit messages and avoid dots at the end.
- Please use consistent prefixes for commit messages (see [Numpy developement workflow](http://docs.scipy.org/doc/numpy/dev/gitwash/development_workflow.html#writing-the-commit-message)):

Please use the following prefixes for commit messages:

- `API:` an (incompatible) API change
- `BUG:` bug fix
- `DEP:` deprecate something, or remove a deprecated object
- `DEV:` development (tool or utility)
- `DOC:` documentation
- `MNT:` maintenance (e.g. renaming files)
- `REF:` code refactoring
- `REV:` revert an earlier commit
- `STY:` style changes / formatting
- `TST:` addition or modification of tests
