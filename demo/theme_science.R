# Demo: theme_science
# Apply the theme_science() to a simple scatter plot of mtcars data.

library(ggplot2)
library(sciCentRverse)

base_plot <- ggplot(mtcars, aes(x = wt, y = mpg)) +
  geom_point(color = "steelblue", size = 2) +
  geom_smooth(method = "lm", se = FALSE, color = "gray40") +
  labs(
    title = "Fuel Efficiency vs Weight",
    subtitle = "Demo of theme_science",
    x = "Weight (1000 lbs)",
    y = "Miles per gallon",
    caption = "Data: mtcars"
  )

print(base_plot)
print(base_plot + theme_science())

# End of demo