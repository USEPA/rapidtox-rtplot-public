#* @apiTitle Visualization tool for ToxVal data
#* @apiDescription The goal of this API is to productionize the plotting of scientific endpoints. This should allow development to rapidly adapt to changes in the science without the need to replicate processes in the UI.
#*


#* @filter checkParams
function(req, exposure_route = "oral", predicted_exposure = 0, title = "Scatter Plot", res){
  if (!is.character(exposure_route)) {
    res$status <- 400
    return(list(error="Exposure Route must be of type string."))
  } else if (!is.character(title)) {
    res$status <- 400
    return(list(error="Title must be of type string."))
  } else if (is.na(as.numeric(predicted_exposure))) {
    res$status <- 400
    return(list(error="Predicted exposure must be a number."))
  } else if (!exposure_route %in% c("oral", "inhalation")) {
    res$status <- 400
    return(list(error="Exposure Route must be either 'oral' or 'inhalation'."))
  } else {
    plumber::forward()
  }
}

#' In Vivo Toxicity Scatter Plot by exposure route
#' @name plot
#' @param exposure_route "oral" or "inhalation"
#' @param predicted_exposure predicted BER exposure
#' @param title plot title
#' @importFrom BrailleR VI
#' @import dplyr
#' @import stringr
#' @importFrom gridExtra arrangeGrob
#* @serializer png list(width = 1000, height = 500)
#* @post /plot
function(req, exposure_route = "oral", predicted_exposure = 0, title = "Scatter Plot", res) {
  p1 <- p2 <- dtp1 <- dtp2 <- NULL

  if (length(req$body) == 0) {
    dat <- RTplot::loadExampleData()
  }
  else {
    dat <- req$body
    dat$toxvalNumeric <- as.numeric(dat$toxvalNumeric)
  }

  #split plots into 2 plots depending on super category
  # Summary Values on the left plot
  # Everything else on the right plot
  dat_drsv <- dat |> dplyr::filter(grepl("Summary Value",dat$superCategory))
  dat_other <- dat |> dplyr::filter(!grepl("Summary Value",dat$superCategory))


  #only call RT plot if there is data to be plotted
  if(nrow(dat_drsv)>0){
  p1 <- RTplot::RTplot(dat_drsv, exposure_route, as.numeric(predicted_exposure), title = "Dose Response Summary Values Plot")
  }
  if(nrow(dat_other)>0){
  p2 <- RTplot::RTplot(dat_other, exposure_route, as.numeric(predicted_exposure), title = "Toxicity Values Plot", xaxis_label = "Toxicity Value Type")
  }

  # if there is data plotted we can capture generate the descriptive text.
  if(!is.null(p1)){
    dtp1 <- paste0("Description of Left Chart: ",paste0(capture.output(cat(BrailleR::VI(p1)$text)), collapse = " "))
  }
  if(!is.null(p2)){
    dtp2 <- paste0("Description of Right Chart: ",paste0(capture.output(cat(BrailleR::VI(p2)$text)), collapse = " "))
  }

  # if there is no data to be plotted we need to generate a blank plot and a corresponding description
  if(is.null(p1)){
    empty_plot_text <- stringr::str_to_title(paste0("No Valid ",exposure_route," Dose Response\n Summary Values To Plot"))
    p1 <- RTplot::empty_plot(empty_plot_text)
    dtp1 <- paste0("On the left side of the image is an untitled chart with no subtitle or caption. The chart is a text graph with the text: ",empty_plot_text)
  }

  if(is.null(p2)){
    empty_plot_text <- stringr::str_to_title(paste0("No Valid ",exposure_route," Toxicity\n Values To Plot"))
    p2 <- RTplot::empty_plot(empty_plot_text)
    dtp2 <- paste0("On the right side of the image is an untitled chart with no subtitle or caption. The chart is a text graph with the text: ",empty_plot_text)
  }

  # Combine the descriptive text for both plots into one
  dt <- paste0("There are two charts in this image. ",dtp1,dtp2, collapse = " ")

  # Combine both plots into a single plot with 2 columns
  plot_grob <- gridExtra::arrangeGrob(p1, p2, ncol = 2)
  # Store descriptive text
  res$headers <- list('descriptive_text' = dt)
  # Return the plot
  res$body <- plot(plot_grob)
  res
}


#' In Vivo Toxicity Scatter Plot by exposure route
#' @name plot_interactive
#' @param exposure_route "oral" or "inhalation"
#' @param predicted_exposure predicted BER exposure
#' @param title plot title
#' @importFrom BrailleR VI
#' @import dplyr
#' @import stringr
#' @importFrom gridExtra arrangeGrob
#' @importFrom manipulateWidget combineWidgets
#' @import ggiraph
#* @serializer htmlwidget
#* @post /plot_interactive
function(req, exposure_route = "oral", predicted_exposure = 0, title = "Scatter Plot", res) {
  p1 <- p2 <- dtp1 <- dtp2 <- NULL

  if (length(req$body) == 0) {
    dat <- RTplot::loadExampleData()
  }
  else {
    dat <- req$body
    dat$toxvalNumeric <- as.numeric(dat$toxvalNumeric)
  }

  #split plots into 2 plots depending on super category
  # Summary Values on the left plot
  # Everything else on the right plot
  dat_drsv <- dat |> dplyr::filter(grepl("Summary Value",dat$superCategory))
  dat_other <- dat |> dplyr::filter(!grepl("Summary Value",dat$superCategory))


  #only call RT plot if there is data to be plotted
  if(nrow(dat_drsv)>0){
    p1 <- RTplot::RTplot(dat_drsv, exposure_route, as.numeric(predicted_exposure), title = "Dose Response Summary Values Plot")
  }
  if(nrow(dat_other)>0){
    p2 <- RTplot::RTplot(dat_other, exposure_route, as.numeric(predicted_exposure), title = "Toxicity Values Plot", xaxis_label = "Toxicity Value Type")
  }

  # if there is data plotted we can capture generate the descriptive text.
  if(!is.null(p1)){
    dtp1 <- paste0("Description of Left Chart: ",paste0(capture.output(cat(BrailleR::VI(p1)$text)), collapse = " "))
  }
  if(!is.null(p2)){
    dtp2 <- paste0("Description of Right Chart: ",paste0(capture.output(cat(BrailleR::VI(p2)$text)), collapse = " "))
  }

  # if there is no data to be plotted we need to generate a blank plot and a corresponding description
  if(is.null(p1)){
    empty_plot_text <- stringr::str_to_title(paste0("No Valid ",exposure_route," Dose Response\n Summary Values To Plot"))
    p1 <- RTplot::empty_plot(empty_plot_text)
    dtp1 <- paste0("On the left side of the image is an untitled chart with no subtitle or caption. The chart is a text graph with the text: ",empty_plot_text)
  }

  if(is.null(p2)){
    empty_plot_text <- stringr::str_to_title(paste0("No Valid ",exposure_route," Toxicity\n Values To Plot"))
    p2 <- RTplot::empty_plot(empty_plot_text)
    dtp2 <- paste0("On the right side of the image is an untitled chart with no subtitle or caption. The chart is a text graph with the text: ",empty_plot_text)
  }

  # Combine the descriptive text for both plots into one
  dt <- paste0("There are two charts in this image. ",dtp1,dtp2, collapse = " ")

  # add interativity
  p1 <- p1 + ggiraph::geom_point_interactive()
  p2 <- p2 + ggiraph::geom_point_interactive()
  y <- manipulateWidget::combineWidgets(ggiraph::girafe(ggobj = p1),ggiraph::girafe(ggobj = p2), ncol = 2)
}

