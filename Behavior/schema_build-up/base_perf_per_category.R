#load packages
library("dplyr")
library('ggplot2')
library('readr')
library('forcats')
library('emmeans')
library(gghalves)

#DEFINE
baseDir =  "/Volumes/T7/01_SchemAcS/05_Analysis"

source(paste0(baseDir,"/Performance_Logs/SelectiveLog/s1-s5/scripts/function_lib.R"))



##################### plot the accuracy across sessions ########################
#load data
df <- read.csv.csv(paste0(baseDir,"/Performance_Logs/SelectiveLog/built-up_dfs/base_cat_acc.csv"))

# 1) collapse across categories at the participant level:
#    compute, for each ID x phase x condition x session, the mean accuracy
id_means <- df %>%
  group_by(ID, Phase, Condition, Session) %>%
  summarise(acc_id_mean = mean(cat_accuracy, na.rm = TRUE), .groups = "drop")

# 2) group summary across IDs: mean and SE (SE across IDs)
summary_by_group <- id_means %>%
  group_by(Phase, Condition, Session) %>%
  summarise(
    mean_acc = mean(acc_id_mean, na.rm = TRUE),
    se_acc   = sd(acc_id_mean, na.rm = TRUE) / sqrt(dplyr::n()),
    n_ids    = dplyr::n(),
    .groups  = "drop"
  )

summary_by_group_learn <- summary_by_group[summary_by_group$Phase == 'learn', ]
summary_by_group_retrieve <- summary_by_group[summary_by_group$Phase == 'retrieve', ]

#learning sessions
p_sess_learn <- plot_line_se(
  data = summary_by_group_learn,
  x_var = "Session",
  y_var = "mean_acc",
  se_var = "se_acc",
  group_var = "Condition",
  facet_var = "Phase",        # if you want separate panels
  y_label = "Accuracy (%)",
  hline = 50,
  y_limits = c(95, 100),
  save_path = paste0(baseDir,'/Performance_Logs/SelectiveLog/s1-s5/plots'),
  filename = "category_accuracy_by_session_condition_learn.pdf"
)

print(p_sess_learn)

#rerieval sessions 
p_sess_retrieve <- plot_line_se(
  data = summary_by_group_retrieve,
  x_var = "Session",
  y_var = "mean_acc",
  se_var = "se_acc",
  group_var = "Condition",
  facet_var = "Phase",        # if you want separate panels
  y_label = "Accuracy (%)",
  hline = 50,
  y_limits = c(40, 100),
  save_path = paste0(baseDir,'/Performance_Logs/SelectiveLog/s1-s5/plots'),
  filename = "category_accuracy_by_session_condition_retrieve.pdf"
)

print(p_sess_retrieve)


##################### plot accuracy across categories ##########################

# per-ID mean accuracy collapsed over sessions
id_means_cat <- df %>%
  group_by(ID, Phase, Condition, Category) %>%
  summarise(acc_id_mean = mean(cat_accuracy, na.rm = TRUE), .groups = "drop")
id_means_cat_learn <- id_means_cat[id_means_cat$Phase == 'learn', ]
id_means_cat_retrieve <- id_means_cat[id_means_cat$Phase == 'retrieve', ]


# group summary (mean + SE)
sum_cat <- id_means_cat %>%
  group_by(Phase, Condition, Category) %>%
  summarise(
    mean_acc = mean(acc_id_mean, na.rm = TRUE),
    se_acc   = sd(acc_id_mean, na.rm = TRUE) / sqrt(dplyr::n()),
    .groups = "drop"
  )
sum_cat_learn = sum_cat[sum_cat$Phase == 'learn', ]
sum_cat_retrieve = sum_cat[sum_cat$Phase == 'retrieve', ]

cond_cols <- c(
  "control" = "#707071",
  "sleep"   = "#313f99",
  "wake"    = "#dc1e32"
)


#plot for learning session category accuracy
p_cat_learn <- plot_half_violin(id_means_cat_learn,
                                   "acc_id_mean",                 # dependent variable column (string)
                                   sum_cat_learn,           # summary dataframe
                                   "mean_acc",           # mean column in summary df (string)
                                   "se_acc",             # SE column in summary df (string)
                                   y_label = "Accuracy (%)",
                                   x_label = "Condition",
                                   hline = 50,
                                   y_limits = c(90, 100),
                                   facet_rows = "Phase", 
                                   facet_cols = "Category", 
                                   colors = cond_cols,
                                   save_path = paste0(baseDir,'/Performance_Logs/SelectiveLog/s1-s5/plots'),
                                   filename = "accuracy_by_category_condition_learn.pdf",
                                   width = 4,
                                   height = 3) 

print(p_cat_learn)

#plot for learning session category accuracy
p_cat_retrieve <- plot_half_violin(id_means_cat_retrieve,
                             "acc_id_mean",                 # dependent variable column (string)
                             sum_cat_retrieve,           # summary dataframe
                             "mean_acc",           # mean column in summary df (string)
                             "se_acc",             # SE column in summary df (string)
                             y_label = "Accuracy (%)",
                             x_label = "Condition",
                             hline = 50,
                             y_limits = c(45, 100),
                             facet_rows = "Phase", 
                             facet_cols = "Category", 
                             colors = cond_cols,
                             save_path = paste0(baseDir,'/Performance_Logs/SelectiveLog/s1-s5/plots'),
                             filename = "accuracy_by_category_condition_retrieve.pdf",
                             width = 6.5,
                             height = 4.5) 

print(p_cat_retrieve)



########## test differences across conditions, cateogries & sessions ###########

df_learn = df_merged[df_merged$phases == 'learn', ]
df_retrieve = df_merged[df_merged$phases == 'retrieve', ]

#learning
model_base_cat_learn <- aov(cat_accuracy ~ conditions*sessions*categories+Gender+Error(IDs/sessions), data = df_learn) 
summary(model_base_cat_learn) # interaction effect: conditions*categories: people in wake were particularly bad for household items
pairs(emmeans(model_base_cat_learn, ~'conditions*categories',pairs = TRUE), infer = TRUE) #wake < control & wake < sleep at p < 0.01

#retrieval
model_base_cat_retrieve <- aov(cat_accuracy ~ conditions*sessions*categories+Gender, data = df_retrieve) 
eta_squared(model_base_cat_retrieve, partial = TRUE)
summary(model_base_cat_retrieve) # effect of sessions: participants improve over time 
pairs(emmeans(model_base_cat_retrieve, ~'sessions'), infer = TRUE) #s1 & 4: p = 0.04; s1 & 5: p = 0.07







