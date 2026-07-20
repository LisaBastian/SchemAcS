#%%
library('nlme')
library('emmeans')
library('ggplot2')
library(tidyr)
library(dplyr)
library(rstatix)
library(effectsize)

rootDir = '/Volumes/T7/01_SchemAcS/05_Analysis/'
data = read.csv(paste0(rootDir,'Performance_Logs/SelectiveLog/Py_Analysis_s6/data/full_dfs/accuracy_old_new_s6.csv'))
data$Condition = as.factor(data$Condition)
data$ID = as.factor(data$ID)
data$Gender = as.factor(data$Gender)
se <- function(x){sd(x, na.rm = TRUE)/sqrt(length(!is.na(x)))}

data_long <- data %>%
  pivot_longer(
    cols = c(mean_acc_old, mean_acc_new),          # columns to combine
    names_to = "boxtype",        # new column indicating old/new
    values_to = "value"          # new column with the values
  )

cond_cols <- c(
  "control" = "#707071",
  "sleep"   = "#313f99",
  "wake"    = "#dc1e32"
)



## performance above chance level?
## chance level = 1/6 = 0.16667 (six possible category ratios)
chance <- 1/6

# helper: one-sample t-test reporting t, df, p, 95% CI of the mean,
# and Cohen's d with its 95% CI (noncentral-t based, via effectsize)
above_chance <- function(x, label){
  x  <- x[!is.na(x)]
  tt <- t.test(x, mu = chance)
  d  <- effectsize::cohens_d(x - chance, mu = 0, ci = 0.95)
  cat(sprintf("%-18s n=%d  mean=%.3f  t(%d)=%.2f  p=%s  95%% CI mean[%.3f, %.3f]  d=%.2f [%.2f, %.2f]\n",
              label, length(x), mean(x), tt$parameter, tt$statistic,
              format.pval(tt$p.value, digits = 3),
              tt$conf.int[1], tt$conf.int[2], d$Cohens_d, d$CI_low, d$CI_high))
}

for (cond in c('sleep','control','wake'))
  above_chance(data$mean_acc_new[data$Condition == cond], paste0('new - ', cond))
for (cond in c('sleep','control','wake'))
  above_chance(data$mean_acc_old[data$Condition == cond], paste0('old - ', cond))

################################################################################
########## do accuracies for old/new boxes differ between conditions? ##########
################################################################################
# -> without controlling for s1-s5 performance

data_long$boxtype = as.factor(data_long$boxtype)
#lme_oldnew = lme(value ~ boxtype*Condition+Gender, random = ~ boxtype | ID, data = data_long)
#summary(lme_oldnew)
#anova(lme_oldnew)

aov_old_new <- aov(value ~ Condition*boxtype+Gender + Error(ID/boxtype), data = data_long)
summary(aov_old_new)
# partial eta^2 with 95% CI as effect size for each term
eta_squared(aov_old_new, partial = TRUE, ci = 0.95)



################################################################################
###################### plot results for old boxes ##############################
################################################################################

# group summary (mean + SE)
sum_cond <- data %>%
  group_by(Condition) %>%
  summarise(
    mean_acc = mean(mean_acc_old, na.rm = TRUE),
    se_acc   = se(mean_acc_old),
  )


p_old <- plot_half_violin(data,
                          "mean_acc_old",                 # dependent variable column (string)
                          sum_cond,           # summary dataframe
                          "mean_acc_old",           # mean column in summary df (string)
                          "se_acc",             # SE column in summary df (string)
                          y_label = "Accuracy (%)",
                          x_label = "Condition",
                          hline = 50,
                          y_limits = c(0.05, 0.75),
                          facet_rows = NULL, 
                          facet_cols = NULL, 
                          colors = cond_cols,
                          save_path = paste0(rootDir,'Performance_Logs/SelectiveLog/Py_Analysis_s6/plots/accuracies'),
                          filename = "accuracy_old_boxes.pdf",
                          width = 4,
                          height = 3) 

print(p_old)


################################################################################
###################### plot results for new boxes  #############################
################################################################################

# group summary (mean + SE)
sum_cond <- data %>%
  group_by(Condition) %>%
  summarise(
    mean_acc = mean(mean_acc_new, na.rm = TRUE),
    se_acc   = se(mean_acc_new),
  )


p_new <- plot_half_violin(data,
                                "mean_acc_new",                 # dependent variable column (string)
                                sum_cond,           # summary dataframe
                                "mean_acc_new",           # mean column in summary df (string)
                                "se_acc",             # SE column in summary df (string)
                                y_label = "Accuracy (%)",
                                x_label = "Condition",
                                hline = 50,
                                y_limits = c(0.05, 0.75),
                                facet_rows = NULL, 
                                facet_cols = NULL, 
                                colors = cond_cols,
                                save_path = paste0(rootDir,'Performance_Logs/SelectiveLog/Py_Analysis_s6/plots/accuracies'),
                                filename = "accuracy_new_boxes.pdf",
                                width = 4,
                                height = 3) 

print(p_new)


################################################################################
######### does accuracy for old boxes predict accuracy for new boxes? ##########
################################################################################

model_new_old <- aov(mean_acc_new ~ mean_acc_old*Condition+Gender, data = data, na.action = na.omit)
summary(model_new_old)
# partial eta^2 with 95% CI (effect size for the interaction = Fig. 2b asterisks)
eta_squared(model_new_old, partial = TRUE, ci = 0.95)
emtr <- emtrends(model_new_old, ~ Condition, var = "mean_acc_old")
pairs(emtr, adjust = 'none')
# per-condition slopes (b) with 95% CI -> values plotted / reported in Fig. 2b
summary(emtr, infer = TRUE)


# Plot
p <- ggplot(data, aes(x = mean_acc_old, y = mean_acc_new)) +
  # Regression lines with grey error shading, one per condition
  geom_smooth(
    aes(group = Condition, color = Condition),
    method = "lm", se = TRUE,
    fill = "grey70", alpha = 0.25, size = 2
  ) +
  # Points for each ID, colored by condition
  geom_point(aes(color = Condition), size = 3, alpha = 0.6) +
  # If you want labels for IDs instead of (or in addition to) points, uncomment:
  # ggrepel::geom_text_repel(aes(label = ID, color = condition), size = 3, show.legend = FALSE) +
  labs(
    x = "Accuracy old boxes (%)",
    y = "Accuracy new boxes (%)",
    color = "Condition"
  ) +
  scale_color_manual(
    values = cond_cols
  )+
  theme_classic(base_size = 16) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "right"
  )

p

#save the plot
ggsave(
  filename = "accuracy_old_new_boxes.pdf",  # output filename
  plot = p,                                      # the ggplot object
  path = paste0(rootDir,'Performance_Logs/SelectiveLog/Py_Analysis_s6/plots/accuracies'), 
  width = 3,                                     # width in inches
  height = 4,                                    # height in inches
  units = "in",                                  # specify units (in, cm, or mm)
  dpi = 300,                                     # resolution (useful if exporting to raster formats)
)








