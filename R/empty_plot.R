#' empty_pot
#'
#' @param label Text that should be returned in the center of the plot
#'
#' @return ggplot2 plot with labeled text
#' @export
empty_plot <- function(label = "No valid data to generate a plot") {
  ggplot() +
    theme_void() +
    geom_text(aes(0, 0, label = label)) +
    xlab(NULL) # optional, but safer in case another theme is applied later
}
