# Demo: theme_science_map

library(ggplot2)
library(sciCentRverse)
library(sf)
library(rnaturalearth)

# Alberta boundary from Natural Earth
alberta <- rnaturalearth::ne_states(
  country = "canada",
  returnclass = "sf"
) |>
  dplyr::filter(name_en == "Alberta")

# Grid clipped to Alberta
grid <- sf::st_make_grid(alberta, cellsize = c(0.2, 0.2), square = TRUE)
grid_sf <- sf::st_sf(geometry = grid)
grid_ab <- sf::st_intersection(grid_sf, sf::st_geometry(alberta))
grid_ab$z <- seq_len(nrow(grid_ab))

base_plot <- ggplot() +
  geom_sf(data = grid_ab, aes(fill = z), color = NA) +
  geom_sf(data = alberta, fill = NA, color = "black", linewidth = 0.4) +
  coord_sf() +
  scale_fill_viridis_c(option = "C") +
  labs(
    title = "Alberta Grid",
    subtitle = "Demo of theme_science_map()",
    x = "Longitude",
    y = "Latitude",
    fill = "Value",
    caption = "Natural Earth boundary"
  )

print(base_plot)
print(base_plot + theme_science_map())
