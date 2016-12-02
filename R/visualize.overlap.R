#' visualize.overlap, Makes a contour map of suitability of habitat in environment space for two models
#'
#' @param model.1 An enmtools.model object
#' @param model.2 An enmtools.model object
#' @param env A set of environmental layers
#' @param nbins The number of bins per layer to use for drawing environment space
#' @param layers A vector of layer names to use for drawing environment space
#' @param plot.points Logical determining whether presence points should be plotted on suitability plot
#'
#' @return overlap.plot A two dimensional plot of an ENM
#'
#' @keywords niche plot sdm enm overlap
#'
#' @export visualize.overlap
#'
#' @examples
#' visualize.enm(1, .001, .001)

visualize.overlap <- function(model.1, model.2, env, nbins = 100, layers, plot.points = TRUE){

  if(!inherits(model.1, "enmtools.model")){
    stop("This function requires two enmtools.model objects!")
  }

  if(!inherits(model.2, "enmtools.model")){
    stop("This function requires two enmtools.model objects!")
  }

  if(length(layers) != 2){
    stop("Layers argument must be a character vector specifying two environmental layers to use for plotting!")
  }

  if(!all(layers %in% names(env))){
    stop("Layer names provided do not match environmental rasters!")
  }

  # Grab points
  if(inherits(model.1, c("enmtools.bc", "enmtools.dm"))){
    points.1 <- model.1$analysis.df
  } else {
    points.1 <- model.1$analysis.df[model.1$analysis.df$presence == 1,1:2]
  }
  if(inherits(model.2, c("enmtools.bc", "enmtools.dm"))){
    points.2 <- model.2$analysis.df
  } else {
    points.2 <- model.2$analysis.df[model.2$analysis.df$presence == 1,1:2]
  }


  layer1.min <- min(getValues(env[[layers[1]]]), na.rm=TRUE)
  layer2.min <- min(getValues(env[[layers[2]]]), na.rm=TRUE)
  layer1.max <- max(getValues(env[[layers[1]]]), na.rm=TRUE)
  layer2.max <- max(getValues(env[[layers[2]]]), na.rm=TRUE)

  # Build plot df
  plot.df <- cbind(rep(seq(layer1.min, layer1.max, length = nbins), nbins),
                   rep(seq(layer2.min, layer2.max, length = nbins), each = nbins))

  # Create a vector of names in the right order for plot.df
  names <- layers

  # Set value to mean for all non-target vars
  for(i in names(env)){
    if(!(i %in% layers)){
      layer.values <- extract(env[[i]], rbind(points.1, points.2))
      plot.df <- cbind(plot.df, rep(mean(layer.values, na.rm=TRUE), nrow(plot.df)))
      names <- c(names, i)
    }
  }

  pointdata.1 <- as.data.frame(extract(env[[layers]], points.1))
  pointdata.2 <- as.data.frame(extract(env[[layers]], points.2))

  colnames(plot.df) <- names

  plot.df <- data.frame(plot.df)

  pred.1 <- predict(model.1$model, plot.df, type = "response")
  pred.2 <- predict(model.2$model, plot.df, type = "response")

  plot.df <- cbind(plot.df[,1:2], pred.1, pred.2)

  #This is where I'm going to need to look up how to overlap two contours!
  overlap.plot <- ggplot(data = plot.df, aes_string(y = names[2], x = names[1])) +
    geom_contour(aes(z = pred.1)) + geom_contour(aes(z = pred.2)) +
    scale_fill_viridis(option = "B", guide = guide_colourbar(title = "Suitability")) +
    theme_classic() +
    ggtitle(label = "Predicted suitability in environment space")

  # if(plot.points == TRUE){
  #   suit.plot <- suit.plot  + geom_point(data = pointdata, aes_string(y = names[2], x = names[1]),
  #                                        pch = 21, fill = "white", color = "black", size = 3)
  # }

  output <- overlap.plot


  return(output)
}