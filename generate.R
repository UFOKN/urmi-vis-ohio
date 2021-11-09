library(stars)
library(dplyr)
library(sf)

d  = dir('/Users/mjohnson/Downloads/39', full.names = TRUE)

for(i in 1:length(d)){
  
  f = list.files(d[[i]], full.names = TRUE)
  out = paste0("temp/39", basename(d[[i]]), '.tif')
  unlink(out)
  
  rr = arrow::open_dataset(f) %>% 
    select(X, Y) %>% 
    collect() %>% 
    st_as_sf(coords = c("X", "Y"), crs = 4326) %>% 
    st_transform(5070) %>% 
    mutate(count = 1)
  
  ss = sf::st_bbox(rr) %>% 
    stars::st_as_stars(values = 0, 
                       dx = 100, 
                       dy = 100)
  
  s = stars::st_rasterize(rr[, "count"], ss, options = "MERGE_ALG=ADD")
  s$count = ifelse(s$count == 0, NA, s$count)
  
  stars::write_stars(s, out, "count")
  message(i)
}

merge_rasters <- function(input_rasters,
                          output_raster = tempfile(fileext = ".tif"),
                          options = character(0)) {
  
  unlink(output_raster)
  sf::gdal_utils(
    util = "warp",
    source = as.character(input_rasters),
    destination = output_raster,
    options = options
  )
}


mx = 100


rbind(c(0, 0, 0, 0),
      cbind(1:100, t(col2rgb(rev((pals::brewer.ylorbr(100))
      ))))) %>%
  write.table("col.txt", row.names = FALSE, col.names = FALSE)

files = list.files('/Users/mjohnson/Downloads/test/', full.names = TRUE)


merge_rasters(files, 
              output_raster = '/Users/mjohnson/Downloads/test2/ohio.tif',
              c('-srcnodata', 'nan',
                '-dstnodata', 0,
                "-s_srs", "EPSG:5070",
                "-t_srs", "EPSG:4326",
                '-r', "near"))

system('gdal_translate -of GTiff -ot byte /Users/mjohnson/Downloads/test2/ohio.tif /Users/mjohnson/Downloads/test2/ohio8.tif -scale 0 518')
system('gdaldem color-relief /Users/mjohnson/Downloads/test2/ohio8.tif /Users/mjohnson/github/urmi-vis-ohio/col.txt /Users/mjohnson/github/urmi-vis-ohio/ohio8_col.tif')
system('gdal2tiles.py --zoom=4-7 /Users/mjohnson/github/urmi-vis-ohio/ohio8_col.tif tiles')
