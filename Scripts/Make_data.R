suppressPackageStartupMessages(library(INLA, quietly=TRUE))

library(data.table)
library(tidyverse)
library(lubridate)
library(raster)
library(rgdal)

# setwd('/Users/philism/OneDrive - NTNU/PhD/Joris_work/Scripts')
setwd('/Users/joriswiethase/Google Drive (jhw538@york.ac.uk)/Work/PhD_York/Chapter3/TZ_inla_spatial_temporal/source')
sapply(list.files(pattern="*.R"),source,.GlobalEnv)

# Import and prepare data-----------------------------------------------------------------------------------

# setwd('/Users/philism/OneDrive - NTNU/PhD/Joris_work/Philip_data')
setwd('/Users/joriswiethase/Google Drive (jhw538@york.ac.uk)/Work/PhD_York/Chapter3/TZ_INLA/data')

# Set Region of Interest
# setwd('~/Documents/TZ_inla_spatial_temporal/Data/New_files_INLA')
TZ_outline <- readOGR('TZ_simpler.shp')
TZ_buffered <- readOGR('TZ_simpler_buffered.shp')
TZ_no_lakes <- readOGR("TZ_no_lakes.shp")
NTRI <- readOGR("NTRI_outline.shp")  # A small subset 
ROI <- TZ_buffered

# setwd('/Users/philism/OneDrive - NTNU/PhD/Joris_work/Philip_data')
# Import bird data, initial filtering
ebird_full <- fread("ebd_TZ_relMay-2021.txt") %>% 
      mutate(date = ymd(get("OBSERVATION DATE"))) %>%
      filter(!is.na(`DURATION MINUTES`), !is.na(`EFFORT DISTANCE KM`))

atlas_full <- fread("TZ_bird_atlas_data.csv") %>%
      filter(!is.na(effort))

atlas_full$Scientific[atlas_full$Scientific == 'Nectarinia olivacea'] <- 'Cyanomitra olivacea'
atlas_full$Scientific[atlas_full$Scientific == 'Andropadus virens'] <- 'Eurillas virens'
atlas_full$Scientific[atlas_full$Scientific == 'Gyps rueppellii'] <- 'Gyps africanus'
atlas_full$Scientific[atlas_full$Scientific == 'Otis kori'] <- 'Ardeotis kori'
atlas_full$Scientific[atlas_full$Scientific == 'Eupodotis ruficristata'] <- 'Eupodotis gindiana'
atlas_full$Scientific[atlas_full$Scientific == 'Eupodotis senegalensis'] <- 'Lissotis melanogaster'
atlas_full$Scientific[atlas_full$Scientific == 'Eupodotis hartlaubii'] <- 'Lissotis hartlaubii'
atlas_full$Scientific[atlas_full$Scientific == 'Rhinoptilus africanus'] <- 'Smutsornis africanus'
atlas_full$Scientific[atlas_full$Scientific == 'Coracias naevia'] <- 'Coracias naevius'
atlas_full$Scientific[atlas_full$Scientific == 'Phoeniculus minor'] <- 'Rhinopomastus minor'
atlas_full$Scientific[atlas_full$Scientific == 'Tockus erythrorhyncus'] <- 'Tockus erythrorhynchus'
atlas_full$Scientific[atlas_full$Scientific == 'Lybius diadematus'] <- 'Tricholaema diademata'
atlas_full$Scientific[atlas_full$Scientific == 'Lybius melanocephalus'] <- 'Tricholaema melanocephala'
atlas_full$Scientific[atlas_full$Scientific == 'Mirafra poecilosterna'] <- 'Calendulauda poecilosterna'
atlas_full$Scientific[atlas_full$Scientific == 'Hippolais pallida'] <- 'Iduna pallida'
atlas_full$Scientific[atlas_full$Scientific == 'Parisoma boehmi'] <- 'Sylvia boehmi'
atlas_full$Scientific[atlas_full$Scientific == 'Cisticola aridula'] <- 'Cisticola aridulus'
atlas_full$Scientific[atlas_full$Scientific == 'Cisticola robusta'] <- 'Cisticola robustus'
atlas_full$Scientific[atlas_full$Scientific == 'Cisticola cinereola'] <- 'Cisticola cinereolus'
atlas_full$Scientific[atlas_full$Scientific == 'Calamonastes simplex"'] <- 'Calamonastes simplex'
atlas_full$Scientific[atlas_full$Scientific == 'Empidornis semipartitus'] <- 'Melaenornis semipartitus'
atlas_full$Scientific[atlas_full$Scientific == 'Turdoides rubiginosus'] <- 'Turdoides hypoleuca'
atlas_full$Scientific[atlas_full$Scientific == 'Parus fringillinus'] <- 'Melaniparus fringillinus'
atlas_full$Scientific[atlas_full$Scientific == 'Nectarinia ectarinioides'] <- 'Cinnyris nectarinioides'
atlas_full$Scientific[atlas_full$Scientific == 'Nectarinia pulchella'] <- 'Cinnyris pulchellus'
atlas_full$Scientific[atlas_full$Scientific == 'Eurocephalus rueppelli'] <- 'Eurocephalus ruppelli'
atlas_full$Scientific[atlas_full$Scientific == 'Spreo superbus'] <- 'Lamprotornis superbus'
atlas_full$Scientific[atlas_full$Scientific == 'Spreo hildebrandti'] <- 'Lamprotornis hildebrandti'
atlas_full$Scientific[atlas_full$Scientific == 'Spreo fischeri'] <- 'Lamprotornis fischeri'
atlas_full$Scientific[atlas_full$Scientific == 'Cosmopsarus unicolor'] <- 'Lamprotornis unicolor'
atlas_full$Scientific[atlas_full$Scientific == 'Passer motitentis'] <- 'Passer rufocinctus'
atlas_full$Scientific[atlas_full$Scientific == 'Petronia pyrgita'] <- 'Gymnoris pyrgita'

proj <- CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

# Import and prepare the temporally varying covariates
#setwd('/Users/philism/OneDrive - NTNU/PhD/Joris_work/Temporal_variables')
# setwd('/Users/philism/OneDrive - NTNU/PhD/Joris_work/Joris_tif_files/Philip_additional_files')
# setwd('~/Documents/TZ_inla_spatial_temporal/Data/New_files_INLA')
# TZ_annual_median_rain_80_00 <- raster('TZ_annual_median_rain_80_00.tif') %>% mask(., ROI) 
# TZ_annual_median_rain_00_20 <- raster('TZ_annual_median_rain_00_20.tif') %>% mask(., ROI) %>% projectRaster(., TZ_annual_median_rain_80_00)
# TZ_ERA5_coldest_80_00 <- raster('TZ_ERA5_coldest_temperature_1980_2000.tif') %>% mask(., ROI) %>% projectRaster(., TZ_annual_median_rain_80_00)
# TZ_ERA5_coldest_00_20 <- raster('TZ_ERA5_coldest_temperature_2000_2020.tif') %>% mask(., ROI) %>% projectRaster(., TZ_annual_median_rain_80_00)
# TZ_ERA5_hottest_80_00 <- raster('TZ_ERA5_hottest_temperature_1980_2000.tif') %>% mask(., ROI) %>% projectRaster(., TZ_annual_median_rain_80_00)
# TZ_ERA5_hottest_00_20 <- raster('TZ_ERA5_hottest_temperature_2000_2020.tif') %>% mask(., ROI) %>% projectRaster(., TZ_annual_median_rain_80_00)
# 
# setwd('~/Documents/TZ_inla_spatial_temporal/Data/New_files_INLA')
# 
# setwd('/Users/philism/OneDrive - NTNU/PhD/Joris_work/Temporal_variables')

# Import and process covariate data
TZ_annual_median_rain_80_00 <- raster('TZbuff_annual_median_rain_1981_1999.tif') %>% mask(., ROI)
TZ_annual_median_rain_80_00[is.nan(TZ_annual_median_rain_80_00)] <- NA
TZ_annual_median_rain_00_20 <- raster('TZbuff_annual_median_rain_2000_2020.tif') %>% mask(., ROI) %>% projectRaster(., TZ_annual_median_rain_80_00)
TZ_annual_median_rain_00_20[is.nan(TZ_annual_median_rain_00_20)] <- NA
TZ_ERA5_hottest_80_00 <- raster('TZbuff_ERA5_hottest_temperature_1981_1999.tif') %>% mask(., ROI) %>% projectRaster(., TZ_annual_median_rain_80_00)
TZ_ERA5_hottest_80_00[is.nan(TZ_ERA5_hottest_80_00)] <- NA
TZ_ERA5_hottest_00_20 <- raster('TZbuff_ERA5_hottest_temperature_2000_2020.tif') %>% mask(., ROI) %>% projectRaster(., TZ_annual_median_rain_80_00)
TZ_ERA5_hottest_00_20[is.nan(TZ_ERA5_hottest_00_20)] <- NA
TZ_dryspell_80_00 <- raster('TZbuff_median_annual_dryspell_length_1981_1999.tif') %>% projectRaster(., TZ_annual_median_rain_80_00)
TZ_dryspell_80_00[is.nan(TZ_dryspell_80_00)] <- NA
TZ_dryspell_00_20 <- raster('TZbuff_median_annual_dryspell_length_2000_2020.tif') %>% projectRaster(., TZ_annual_median_rain_80_00)
TZ_dryspell_00_20[is.nan(TZ_dryspell_00_20)] <- NA
TZ_BG_90_99 <- raster('BG_1990_1999_1000m.tif') %>% mask(., ROI) %>% projectRaster(., TZ_annual_median_rain_80_00)
TZ_BG_90_99[is.nan(TZ_BG_90_99)] <- NA
TZ_BG_10_19 <- raster('BG_2010_2019_1000m.tif') %>% mask(., ROI) %>% projectRaster(., TZ_annual_median_rain_80_00)
TZ_BG_10_19[is.nan(TZ_BG_10_19)] <- NA
TZ_HFP_93 <- raster('HFP1993.tif') %>% mask(., ROI) %>% projectRaster(., TZ_annual_median_rain_80_00)
TZ_HFP_93[is.nan(TZ_HFP_93)] <- NA
TZ_HFP_09 <- raster('HFP2009.tif') %>% mask(., ROI) %>% projectRaster(., TZ_annual_median_rain_80_00)
TZ_HFP_09[is.nan(TZ_HFP_09)] <- NA

# BG layer has large gaps in data, this needs to be accounted for. Manually create indicator layer and BG interaction layer,
# to make sure model ignores areas with NA BG
# Make indicator layer where 0 is NA in BG, and 1 is value in BG
indicator_90s <- TZ_BG_90_99
values(indicator_90s)[!is.na(values(indicator_90s))] <- 1
values(indicator_90s)[is.na(values(indicator_90s))] <- 0

indicator_2010s <- TZ_BG_10_19
values(indicator_2010s)[!is.na(values(indicator_2010s))] <- 1
values(indicator_2010s)[is.na(values(indicator_2010s))] <- 0

# Stack all covariate layers
temporal_variables <- stack(TZ_annual_median_rain_80_00, TZ_annual_median_rain_00_20, 
                            TZ_ERA5_hottest_80_00, TZ_ERA5_hottest_00_20,
                            TZ_dryspell_80_00, TZ_dryspell_00_20,
                            TZ_BG_90_99, TZ_BG_10_19, indicator_90s, indicator_2010s,
                            TZ_HFP_93, TZ_HFP_09)

names(temporal_variables) <- c('TZ_ann_rain_1980s', 'TZ_ann_rain_2000s', 
                               'TZ_max_temp_1980s', 'TZ_max_temp_2000s',
                               'TZ_dryspell_1980s', 'TZ_dryspell_2000s',
                               'TZ_BG_90_99', 'TZ_BG_10_19', 'indicator_90s', 'indicator_2010s',
                               'TZ_HFP_1993', 'TZ_HFP_2009')

temporal_variables <- as(temporal_variables, 'SpatialPointsDataFrame')

TZ_ann_rain <- c(temporal_variables@data[["TZ_ann_rain_1980s"]], temporal_variables@data[["TZ_ann_rain_2000s"]])
TZ_max_temp <- c(temporal_variables@data[["TZ_max_temp_1980s"]], temporal_variables@data[["TZ_max_temp_2000s"]])
TZ_dryspell <- c(temporal_variables@data[["TZ_dryspell_1980s"]], temporal_variables@data[["TZ_dryspell_2000s"]])
TZ_BG <- c(temporal_variables@data[["TZ_BG_90_99"]], temporal_variables@data[["TZ_BG_10_19"]])
TZ_HFP <- c(temporal_variables@data[["TZ_HFP_1993"]], temporal_variables@data[["TZ_HFP_2009"]])

# Prepare remaining data for a GAM model
temporal_variables <- prepare_GAM(temporal_variables, TZ_ann_rain)
temporal_variables <- prepare_GAM(temporal_variables, TZ_max_temp)
temporal_variables <- prepare_GAM(temporal_variables, TZ_dryspell)
temporal_variables <- prepare_GAM(temporal_variables, TZ_BG)
temporal_variables <- prepare_GAM(temporal_variables, TZ_HFP)

# Combine the unscaled prediction vectors
all.seq <- mget(ls(pattern = "TZ_.*.seq"))

# Should get rid of NAs, but not the ones caused by data gaps in the BG layer. Those are now 
# index using teh indicator layer, should be able to just replace them with any number, 
# since they will be ignored by the model.
temporal_variables@data[grepl("BG", names(temporal_variables))][is.na(temporal_variables@data[grepl("BG", names(temporal_variables))])] <- 0
temporal_variables <- temporal_variables[!is.na(rowSums(temporal_variables@data)),]

# Make linear combinations, needed to make effect plots. Variable names have to match model term names
# Effect plot scaled according to eBird observations, if only eBird intercept included
# Covars for two time periods have to be transformed together. 
# Make seq min to max for all covars values, two time periods combined, add time 1 and time 2 data after that (var.s step)

TZ_max_temp_lc <- inla.make.lincombs(ebird_intercept = rep(1, 100),  
                                     hottest_temp_1 = TZ_max_temp_1.s,   
                                     hottest_temp_2 = TZ_max_temp_2.s); names(TZ_max_temp_lc) <- paste0("TZ_max_temp_lc", 1:100)
TZ_ann_rain_lc <- inla.make.lincombs(ebird_intercept = rep(1, 100),  
                                     annual_rain_1 = TZ_ann_rain_1.s,   
                                     annual_rain_2 = TZ_ann_rain_2.s); names(TZ_ann_rain_lc) <- paste0("TZ_ann_rain_lc", 1:100)
TZ_dryspell_lc <- inla.make.lincombs(ebird_intercept = rep(1, 100),
                                     max_dryspell_1 = TZ_dryspell_1.s,   
                                     max_dryspell_2 = TZ_dryspell_2.s); names(TZ_dryspell_lc) <- paste0("TZ_dryspell_lc", 1:100)
TZ_BG_lc       <- inla.make.lincombs(ebird_intercept = rep(1, 100),
                                     BG_1 = TZ_BG_1.s,
                                     BG_2 = TZ_BG_2.s); names(TZ_BG_lc) <- paste0("TZ_BG_lc", 1:100)
TZ_HFP_lc       <- inla.make.lincombs(ebird_intercept = rep(1, 100),
                                     HFP_1 = TZ_HFP_1.s,
                                     HFP_2 = TZ_HFP_2.s); names(TZ_HFP_lc) <- paste0("TZ_HFP_lc", 1:100)

# Combine all linear combinations, to include in the final model.
all_lc <- c(TZ_max_temp_lc, TZ_ann_rain_lc, TZ_dryspell_lc, TZ_BG_lc, TZ_HFP_lc)

# setwd('/Users/philism/OneDrive - NTNU/PhD/Joris_work/Philip_data')
setwd('/Users/joriswiethase/Google Drive (jhw538@york.ac.uk)/Work/PhD_York/Chapter3/TZ_inla_spatial_temporal/model_data')

save(proj, ROI, ebird_full, atlas_full, temporal_variables, TZ_outline, TZ_no_lakes, all_lc, all.seq, file = "TZ_INLA_model_file_temporal.RData")
