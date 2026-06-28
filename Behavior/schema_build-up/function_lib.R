
################################## load data ###################################
detect_sep <- function(file) {
  first_line <- readLines(file, n = 1)
  if (grepl(",", first_line)) return(",")
  if (grepl(";", first_line)) return(";")
  if (grepl(":", first_line)) return(":")
  if (grepl("\t", first_line)) return("\t")
  return(",")  # default
}

read_flexible_csv <- function(file) {
  sep <- detect_sep(file)
  read.csv(file, sep = sep)
}

load_SLdata<- function(data_path,session){
  stopifnot(is.character(data_path))
  stopifnot(is.character(session))
  
  data <- read_flexible_csv(data_path)
  
  if(ncol(data) == 26){
    data[ ,1] <- NULL
    colnames(data) <- c("StartTime","StartFrame","StartLocation_X","StartLocation_Y","StartLocation_Z",
                        "StartRotation_P","StartRotation_R","StartRotation_Y","MovementOnset","BoxCounter",
                        "BoxName","BoxReached","BoxOpened","ObjectName","ObjectCategory","ObjectStart","ObjectStop",
                        "ObjectLocation_X","ObjectLocation_Y","ObjectLocation_Z","DistributionCategory",
                        "ObjectResponse","TrialEnd","TrialNo","Session")
  }else if (ncol(data) == 25){
    data = data[,c(1:24)]
    colnames(data) <- c("TrialNo","StartTime","StartFrame","StartLocation_X","StartLocation_Y","StartLocation_Z",
                        "StartRotation_P","StartRotation_R","StartRotation_Y","MovementOnset","BoxCounter",
                        "BoxName","BoxReached","BoxOpened","ObjectName","ObjectCategory","ObjectStart","ObjectStop",
                        "ObjectLocation_X","ObjectLocation_Y","ObjectLocation_Z","DistributionCategory",
                        "ObjectResponse","TrialEnd")
    data$Session <- rep(session,nrow(data))
    if(ncol(data) != 25){
      stop("Insufficient number of DF columns!")
    }
  }else if (ncol(data) == 24){
    data = data[,c(1:23)]
    colnames(data) <- c("StartTime","StartFrame","StartLocation_X","StartLocation_Y","StartLocation_Z",
                        "StartRotation_P","StartRotation_R","StartRotation_Y","MovementOnset","BoxCounter",
                        "BoxName","BoxReached","BoxOpened","ObjectName","ObjectCategory","ObjectStart","ObjectStop",
                        "ObjectLocation_X","ObjectLocation_Y","ObjectLocation_Z","DistributionCategory",
                        "ObjectResponse","TrialEnd")
    data$TrialNo <- c(1:nrow(data))
    data$Session <- rep(session,nrow(data))
    if(ncol(data) != 25){
      stop("Insufficient number of DF columns!")
    }
  }else if (ncol(data) == 22){
    colnames(data) <- c("StartFrame","StartLocation_X","StartLocation_Y","StartLocation_Z",
                        "StartRotation_P","StartRotation_R","StartRotation_Y","MovementOnset","BoxCounter",
                        "BoxName","BoxReached","BoxOpened","ObjectName","ObjectCategory","ObjectStart","ObjectStop",
                        "ObjectLocation_X","ObjectLocation_Y","ObjectLocation_Z","DistributionCategory",
                        "ObjectResponse","TrialEnd")
    data = data[,c(1:22)]
    data$TrialNo <- c(1:nrow(data))
    data$Session <- rep(session,nrow(data))
    if(ncol(data) != 25){
      stop("Insufficient number of DF columns!")
    }
  }else{
    stop(sprintf("Number of columns do not match with conditionals for preprocessing: %f", ncol(data)))
  }
  return(data)
}

load_SRdata<- function(data_path,session){
  stopifnot(is.character(data_path))
  stopifnot(is.character(session))
  
  data <- read.csv(data_path)
  data$TrialEnd <- NULL
  colnames(data) <- c("StartTime","StartFrame","StartLocation_X","StartLocation_Y","StartLocation_Z",
                      "StartRotation_P","StartRotation_R","StartRotation_Y","BoxReached","BoxName",
                      "CategorySelected","CategorySelection","CorrectCategory","BoxOpened","LeftObject",
                      "LeftCategory","RightObject","RightCatgory","AnswerTime","ObjectAnswer","CorrectObject","TrialEnd")
  data$TrialNo <- c(1:nrow(data))
  data$Session <- rep(session,nrow(data))
  return(data)
}

load_S6data <- function(data_path){
  data <- read.csv(data_path)
  data$TrialEnd <- NULL
  colnames(data) <- c("StartTime","StartFrame","StartLocation_X","StartLocation_Y","StartLocation_Z",
                      "StartRotation_P","StartRotation_R","StartRotation_Y","MovementOnset","BoxName",
                      "BoxReached","NewOld","ChoiceTime","CategoryRatio","AnswerTime","TrialEnd")
  data$TrialNo <- c(1:nrow(data))
  return(data)
  
  
}


################################ boxplots ######################################

library(ggplot2)
library(gghalves)
library(dplyr)
library(rlang)

library(ggplot2)
library(gghalves)
library(dplyr)
library(rlang)

plot_half_violin <- function(data,
                             dv,
                             sum_data,
                             mean_col,
                             se_col,
                             y_label = "Accuracy (%)",
                             x_label = "Condition",
                             hline = NULL,
                             y_limits = NULL,
                             facet_rows = NULL,   # e.g., "phases"
                             facet_cols = NULL,   # e.g., "categories"
                             colors = c("control" = "#707071",
                                        "sleep"   = "#313f99",
                                        "wake"    = "#dc1e32"),
                             save_path = NULL,
                             filename = NULL,
                             width = 2.5,
                             height = 4) {
  
  dv_sym   <- sym(dv)
  mean_sym <- sym(mean_col)
  se_sym   <- sym(se_col)
  
  p <- ggplot(data, aes(x = Condition, y = !!dv_sym)) +
    
    # Half violins
    gghalves::geom_half_violin(
      aes(fill = Condition),
      side = "r", trim = TRUE,
      width = 0.9, alpha = 0.4,
      color = NA
    ) +
    
    # Optional horizontal line
    {if (!is.null(hline))
      geom_hline(yintercept = hline,
                 linetype = "dashed",
                 color = "black",
                 linewidth = 0.8)
    } +
    
    # Individual datapoints
    geom_point(
      aes(color = Condition, fill = Condition),
      position = position_jitter(width = 0.1, height = 0),
      size = 2, alpha = 1
    ) +
    
    # SEM error bars
    geom_errorbar(
      data = sum_data,
      mapping = aes(x = Condition,
                    ymin = !!mean_sym - !!se_sym,
                    ymax = !!mean_sym + !!se_sym),
      width = 0.15,
      color = "black",
      linewidth = 0.5,
      inherit.aes = FALSE
    ) +
    
    # Mean markers
    geom_point(
      data = sum_data,
      mapping = aes(x = Condition,
                    y = !!mean_sym,
                    fill = Condition),
      color = "black",
      shape = 21,
      size = 4,
      stroke = 0.5,
      inherit.aes = FALSE
    ) +
    
    scale_fill_manual(values = colors) +
    scale_color_manual(values = colors) +
    
    labs(
      x = x_label,
      y = y_label,
      fill = "Condition"
    ) +
    
    theme_classic(base_size = 14) +
    theme(
      panel.grid.minor = element_blank(),
      legend.position = "top",
      axis.text.x = element_text(color = "black", size = 13),
      axis.text.y = element_text(color = "black", size = 13),
      axis.line = element_line(linewidth = 0.4)
    )
  
  # Optional y-limits
  if (!is.null(y_limits)) {
    p <- p + coord_cartesian(ylim = y_limits)
  }
  
  # Optional faceting
  if (!is.null(facet_rows) | !is.null(facet_cols)) {
    
    facet_formula <- as.formula(
      paste(
        ifelse(is.null(facet_rows), ".", facet_rows),
        "~",
        ifelse(is.null(facet_cols), ".", facet_cols)
      )
    )
    
    p <- p + facet_grid(facet_formula)
  }
  
  print(p)
  
  # Optional saving
  if (!is.null(save_path) & !is.null(filename)) {
    ggsave(
      filename = filename,
      plot = p,
      path = save_path,
      width = width,
      height = height,
      units = "in",
      dpi = 300
    )
  }
  
  return(p)
}


################################ lineplots #####################################

library(ggplot2)
library(rlang)
library(dplyr)

plot_line_se <- function(data,
                         x_var,          # e.g., "sessions"
                         y_var,          # e.g., "mean_acc"
                         se_var,         # e.g., "se_acc"
                         group_var,      # e.g., "Condition"
                         facet_var = NULL,   # e.g., "Phase"
                         x_label = "Session",
                         y_label = "Accuracy (%)",
                         hline = NULL,
                         y_limits = NULL,
                         dodge_width = 0.2,
                         colors = c("control" = "#707071",
                                    "sleep"   = "#313f99",
                                    "wake"    = "#dc1e32"),
                         save_path = NULL,
                         filename = NULL,
                         width = 3,
                         height = 3) {
  
  x_sym     <- sym(x_var)
  y_sym     <- sym(y_var)
  se_sym    <- sym(se_var)
  group_sym <- sym(group_var)
  
  data_clean <- data %>%
    filter(is.finite(!!y_sym), is.finite(!!se_sym)) %>%
    droplevels()
  
  p <- ggplot(data_clean,
              aes(x = !!x_sym,
                  y = !!y_sym,
                  color = !!group_sym,
                  group = !!group_sym)) +
    
    geom_line(position = position_dodge(width = dodge_width),
              linewidth = 0.8) +
    
    geom_point(position = position_dodge(width = dodge_width),
               size = 3) +
    
    geom_errorbar(
      aes(ymin = !!y_sym - !!se_sym,
          ymax = !!y_sym + !!se_sym),
      width = 0.2,
      position = position_dodge(width = dodge_width),
      linewidth = 0.4
    ) +
    
    {if (!is.null(hline))
      geom_hline(yintercept = hline,
                 linetype = "dashed",
                 color = "black",
                 linewidth = 0.6)
    } +
    
    scale_color_manual(values = colors) +
    
    labs(x = x_label,
         y = y_label,
         color = "Condition") +
    
    theme_classic(base_size = 14) +
    theme(
      axis.title = element_text(size = 12),
      axis.text  = element_text(size = 12, color = "black"),
      legend.position = "top",
      legend.title = element_blank(),
      axis.line = element_line(linewidth = 0.4)
    )
  
  if (!is.null(y_limits)) {
    p <- p + coord_cartesian(ylim = y_limits)
  }
  
  if (!is.null(facet_var)) {
    p <- p + facet_wrap(as.formula(paste("~", facet_var)))
  }
  
  print(p)
  
  if (!is.null(save_path) & !is.null(filename)) {
    ggsave(
      filename = filename,
      plot = p,
      path = save_path,
      width = width,
      height = height,
      units = "in",
      dpi = 300
    )
  }
  
  return(p)
}

