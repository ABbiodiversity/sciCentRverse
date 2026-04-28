# Add Alberta flag to a site data frame using precise boundaries

Uses rnaturalearth and sf to determine if each site is in Alberta.

## Usage

``` r
add_alberta_flag(dat, lat_col = "latitude", lon_col = "longitude")
```

## Arguments

- dat:

  Data frame with latitude and longitude columns

- lat_col:

  Name of latitude column (default: "latitude")

- lon_col:

  Name of longitude column (default: "longitude")

## Value

Data frame with in_alberta column (TRUE/FALSE logical)
