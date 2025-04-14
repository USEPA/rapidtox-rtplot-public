#' RT plot
#'
#' @param dat dataframe with plotting parameters
#' @param exposure_route "oral" or "inhalation"
#' @param predicted_exposure predicted BER exposure
#' @param title plot title
#' @param xaxis_label String with default "Exposure Duration Class" can be changed to change the xaxis
#'
#' @return RT plot
#' @export
#'
#' @import ggplot2
#' @import dplyr
#' @import stringr
#' @import scales

RTplot <- function(dat, exposure_route, predicted_exposure, title, xaxis_label = "Exposure Duration Class") {

  #reclassify exposure route based on excel sheet provided by Jason Lambert
  dat <- dat |> mutate(Modified_exposureRoute = ifelse(toxvalType %in% unlist(RTplot::superRoute),ifelse(toxvalType %in% RTplot::superRoute$oral,"oral","inhalation"),exposureRoute))


  if (exposure_route == "oral") {
    dat <- dat |> dplyr::filter(Modified_exposureRoute == exposure_route & toxvalUnits %in% c("mg/kg","mg/kg-day"))
    ylabel <- "Oral mg/kg-day"
  } else if (exposure_route == "inhalation") {
    dat <- dat |> dplyr::filter(Modified_exposureRoute == exposure_route & toxvalUnits == "mg/m3")
    ylabel <- "Inhalation mg/m3"
  }
  if(nrow(dat)==0){
    return(NULL)
  }

  dat <- dat |> mutate(studyType = stringr::str_to_title(studyType))
  level_order <- stringr::str_to_title(c(
    "acute",
    "short-term",
    "subchronic",
    "chronic",
    "repeat dose other",
    "developmental",
    "reproduction developmental",
    "Acute Exposure Guidelines",
    "Media Exposure Guidelines",
    "Toxicity Value"
  ))

  #filter out all study types not defined in the ordering list.
  dat <- dat |> filter(studyType %in% level_order)

  # setup colors and shapes based on supercategory name
  supercat <- c("Acute Exposure Guidelines", "Dose Response Summary Value", "Toxicity Value", "Media Exposure Guidelines", "Mortality Response Summary Value")
  supercat_color <- c("#E69F00", "purple", "#E69F00", "#E69F00", "#E69F00")
  supercat_shape <- rep("circle", length(supercat))

  # add custom and converted supercategories
  custom_supercat <- paste0("Custom ", supercat)
  custom_supercat_color <- supercat_color
  custom_supercat_shape <- rep("square", length(custom_supercat))
  converted_supercat <- paste0("Converted ", supercat)
  converted_supercat_color <- supercat_color
  converted_supercat_shape <- rep("triangle", length(converted_supercat))

  # create a dataframe of all supercategories and their colors/shapes
  # to be used in scale_color_manual and scale_shape_manual
  color_shape <- data.frame(superCategory = c(supercat, custom_supercat, converted_supercat),
                            col = c(supercat_color,custom_supercat_color,converted_supercat_color),
                            sha = c(supercat_shape,custom_supercat_shape,converted_supercat_shape))

  gg <- ggplot(dat, aes(x = factor(studyType, level = level_order), y = toxvalNumeric, tooltip = toxvalSubtype)) +
    geom_point(aes(shape = superCategory, color = superCategory),position = "jitter", size = 3) +
    scale_y_continuous(transform = "log10", labels = scales::label_comma()) +
    scale_x_discrete(labels = scales::label_wrap(10)) +

    ggtitle(title) +
    xlab(xaxis_label) +
    ylab(ylabel) +
    theme(
      legend.title = element_blank(),
      plot.title = element_text(face = "bold", hjust = 0.5, size = 14),
      axis.title.x = element_text(face = "bold", size = 12),
      axis.title.y = element_text(face = "bold", size = 12),
      legend.position="bottom",
      legend.box = "horizontal"
    ) +
    scale_shape_manual(labels = scales::label_wrap(10),values =with(color_shape, setNames(sha, superCategory)))+
    scale_color_manual(labels = scales::label_wrap(10),values =with(color_shape, setNames(col, superCategory)))


  if (predicted_exposure > 0) {
    gg <- gg + geom_hline(aes(yintercept = predicted_exposure), color = "blue") +
      annotate("text",
        x = (length(unique(dat$studyType)) + 1) / 2,
        y = predicted_exposure, label = "Predicted BER Exposure",
        hjust = "middle", vjust = -0.5
      )
  }

  gg
}
