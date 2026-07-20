#imports
library('nlme')
library('emmeans')
library(ggplot2)
library(dplyr)
library(readr)
library(dplyr)
library(gghalves)

se <- function(x){sd(x, na.rm = TRUE)/sqrt(length(!is.na(x)))}

rootDir = '/Volumes/T7/01_SchemAcS/05_Analysis/'
source(paste0(rootDir,"/Performance_Logs/SelectiveLog/s1-s5/scripts/function_lib.R"))

cond_cols = c(
  "sleep" = "#3c5488",
  "wake" = "#e54c35")

################################################################################
############################ df preparation ####################################
################################################################################


df = read.csv(paste0(rootDir,'Performance_Logs/SelectiveLog/Py_Analysis_s6/data/graph_metrics/summary_similarity_df_max_dist_other_node_norm.csv'))
df = df[df$Condition != 'control',]
df = df[df$extend %in% c('0_1','0_2'),],
df$Condition = as.factor(df$Condition)
df$extend = as.factor(df$extend)
df$ID = as.factor(df$ID)
#colnames(df)[7] <- 'NLED'
df = summarize(group_by(df,ID,Condition,extend),mean_acc_s1_s5 = mean(cat_accuracy,na.rm = TRUE), NLED = mean(NormLaplacianEigenDist, na.rm = TRUE))
df$SMI = 1-df$NLED
# Compute mean and standard error per Condition and extend
df_summary <- summarize(group_by(df,Condition, extend), mean_NLED = mean(SMI, na.rm = TRUE),se_NLED = se(SMI))

# Ensure proper order on the x-axis
df_summary$extend <- factor(df_summary$extend,
                            levels = c("0_1","0_2"))



################################################################################
############################# run LME stats ####################################
################################################################################

#compute a linear mixed effects model
sim_model = lme(NLED ~ Condition*extend, random = ~ 1 | ID, data = df, na.action = na.omit)
summary(sim_model)
anova(sim_model)
emms <- emmeans(sim_model, ~ Condition * extend)
pairs(emms,by = "extend",infer= TRUE)
pairs(emms,by = "Condition",infer= TRUE)

write.csv(df, paste0(rootDir,'df_Fig2b.csv'))
################################################################################
########################### plot the results ###################################
################################################################################

# condition * extend 
cond_ext <- ggplot(df_summary, aes(x = extend,
                       y = mean_NLED,
                       color = Condition,
                       group = Condition)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  geom_errorbar(aes(ymin = mean_NLED - se_NLED,
                    ymax = mean_NLED + se_NLED),
                width = 0.15, size = 0.8) +
  scale_color_manual(values = cond_cols) +
  theme_classic(base_size = 14) +
  labs(x = "Extend",
       y = "Average NormLaplacianEigenDist ± SE",
       color = "Condition") +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        legend.position = "top")
cond_ext

ggsave(
  filename = "NLED_cond_ext.pdf",  # output filename
  plot =  cond_ext,                                      # the ggplot object
  path = paste0(rootDir,'/Performance_Logs/SelectiveLog/Py_Analysis_s6/plots/graphs'),                                # optional: choose a directory
  width = 7,                                     # width in inches
  height = 5,                                    # height in inches
  units = "in",                                  # specify units (in, cm, or mm)
  dpi = 300,                                     # resolution (useful if exporting to raster formats)
)


#violin plots 
p_01_02<- plot_half_violin(df,
                                   "SMI",                 # dependent variable column (string)
                                   df_summary,           # summary dataframe
                                   "mean_NLED",           # mean column in summary df (string)
                                   "se_NLED",             # SE column in summary df (string)
                                   y_label = "Normalized Laplacian Distance",
                                   x_label = "Degree",
                                   hline = NULL,
                                   y_limits = c(0.9958, 0.999),
                                   facet_rows = NULL, 
                                   facet_cols = "extend", 
                                   colors = cond_cols,
                                   save_path = paste0(rootDir,'/Performance_Logs/SelectiveLog/Py_Analysis_s6/plots/graphs'),
                                   filename = "violin_SMI_0_1.pdf",
                                   width = 6.5,
                                   height = 4.5) 

print(p_01_02)


#condition for extend: 0_1
sum_0_1 = df_summary[df_summary$extend == '0_1',]
df_0_1 = df[df$extend == '0_1',]

# define color palettes
cond_cols <- c(
  wake    = "#e54c35",
  sleep   = "#3c5488"
)

cond_0_1 = ggplot(df_0_1, aes(x = Condition, y = SMI, color = Condition, fill = Condition)) +
  geom_half_violin(side = "r", trim = FALSE, width = 1, alpha = 0.6) +
  geom_jitter(width = 0.15, size = 3,alpha = 0.6) +
  # SE error bars, override inheritance
  geom_errorbar(data = sum_0_1,
                mapping = aes(x = Condition,
                              ymin = mean_NLED - se_NLED,
                              ymax = mean_NLED + se_NLED),
                inherit.aes = FALSE,
                width = 0.2, color = 'black', size = 0.5) +
  # mean dot with filled color and thick border, override inheritance
  geom_point(data = sum_0_1,
             mapping = aes(x = Condition, y = mean_NLED, fill = Condition),
             inherit.aes = FALSE,
             shape = 21, size = 5, color = 'black', stroke = 0.5) +
  theme_classic(base_size = 14) +
  theme(
    axis.title = element_text(size = 18),
    axis.text  = element_text(size = 16, color = 'black'),
    legend.position = 'top',
    legend.title    = element_blank()
  ) +
  scale_fill_manual(values = cond_cols, name = "Condition") +
  scale_color_manual(values = cond_cols, name = 'Condition')

cond_0_1

ggsave(
  filename = "violin_SMI_0_1.pdf",  # output filename
  plot =  cond_0_1,                                      # the ggplot object
  path = paste0(rootDir,'/Performance_Logs/SelectiveLog/Py_Analysis_s6/plots/graphs'),                                # optional: choose a directory
  width = 3,                                     # width in inches
  height = 5,                                    # height in inches
  units = "in",                                  # specify units (in, cm, or mm)
  dpi = 300,                                     # resolution (useful if exporting to raster formats)
)

#condition for extend: 0_2
sum_0_1 = df_summary[df_summary$extend == '0_2',]
df_0_1 = df[df$extend == '0_2',]

# define color palettes
cond_cols <- c(
  wake    = "#e54c35",
  sleep   = "#3c5488"
)

cond_0_1 = ggplot(df_0_1, aes(x = Condition, y = SMI, color = Condition, fill = Condition)) +
  geom_half_violin(side = "r", trim = FALSE, width = 1, alpha = 0.6) +
  geom_jitter(width = 0.15, size = 3,alpha = 0.6) +
  # SE error bars, override inheritance
  geom_errorbar(data = sum_0_1,
                mapping = aes(x = Condition,
                              ymin = mean_NLED - se_NLED,
                              ymax = mean_NLED + se_NLED),
                inherit.aes = FALSE,
                width = 0.2, color = 'black', size = 0.5) +
  # mean dot with filled color and thick border, override inheritance
  geom_point(data = sum_0_1,
             mapping = aes(x = Condition, y = mean_NLED, fill = Condition),
             inherit.aes = FALSE,
             shape = 21, size = 5, color = 'black', stroke = 0.5) +
  theme_classic(base_size = 14) +
  theme(
    axis.title = element_text(size = 18),
    axis.text  = element_text(size = 16, color = 'black'),
    legend.position = 'top',
    legend.title    = element_blank()
  ) +
  scale_fill_manual(values = cond_cols, name = "Condition") +
  scale_color_manual(values = cond_cols, name = 'Condition')

cond_0_1

ggsave(
  filename = "violin_SMI_0_2.pdf",  # output filename
  plot =  cond_0_1,                                      # the ggplot object
  path = paste0(rootDir,'/Performance_Logs/SelectiveLog/Py_Analysis_s6/plots/graphs'),                                # optional: choose a directory
  width = 3,                                     # width in inches
  height = 5,                                    # height in inches
  units = "in",                                  # specify units (in, cm, or mm)
  dpi = 300,                                     # resolution (useful if exporting to raster formats)
)

