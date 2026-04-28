# Select a Specific Species Column

This function selects a specific species column from a dataset while
retaining key site and location information.

## Usage

``` r
select_species(data, species_name)
```

## Arguments

- data:

  A data frame containing species data in wide format.

- species_name:

  A character string representing the scientific name of the species.

## Value

A data frame with the selected species column and key metadata columns
(`site`, `year`, `obs_date`, `latitude`, `longitude`).

## Examples

``` r
if (FALSE) { # \dontrun{
# Example dataset
invsp_wide <- data.frame(
    site = c("1001", "1002"),
    year = c(2020, 2021),
    obs_date = as.Date(c("2020-06-15", "2021-07-20")),
    latitude = c(54.12, 54.45),
    longitude = c(-113.5, -114.2),
    ranunculus_acris = c(1, 0)
)

# Selecting a species
selected_species_df <- select_species(invsp_wide, "Ranunculus acris")

# View result
print(selected_species_df)
} # }
```
