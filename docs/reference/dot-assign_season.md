# Assign season labels to a vector of Julian days

Assign season labels to a vector of Julian days

## Usage

``` r
.assign_season(yday_vec, cuts, labs)
```

## Arguments

- yday_vec:

  Integer or numeric vector of Julian days (1–366).

- cuts:

  Sorted integer vector of season-start Julian days (one per season).

- labs:

  Character vector of season labels, same length and order as `cuts`.

## Value

An ordered factor of season labels with `levels = labs`.

## Details

Classification is **left-closed**: a day equal to a cutoff is assigned
to that season (e.g., Julian day 143 is the *first* day of summer when
`cuts = c(99, 143, 288)`). Days that fall before the first cutoff wrap
to the **last** season, allowing year-crossing seasons (e.g., winter
spanning late-year to early-year).

## Examples

``` r
cuts <- c(99L, 143L, 288L)
labs <- c("spring", "summer", "winter")
sciCentRverse:::.assign_season(c(98, 99, 142, 143, 287, 288, 365), cuts, labs)
#> Error: object '.assign_season' not found
```
