################
#Analysis of schema build-up category recall performance:
#1. Differences between conditions (control, sleep, wake) in accuracy across sessions -> Fig. 2a
#2. Differences between conditions in accuracy  across categories -> Fig. S1a
#
#written by L.Bastian, Nov 2025
###############

#load packages
library("dplyr")
library('ggplot2')
library('readr')
library('forcats')
library('emmeans')
library(gghalves)
library('readxl')
library('effectsize')

#DEFINE
baseDir =  "/Volumes/T7/01_SchemAcS/05_Analysis"
dataDir =  file.path(dirname(baseDir), "04_Data")   # .../01_SchemAcS/04_Data
saveDir =  file.path(dirname(baseDir), "05_Analysis/Performance_Logs/SelectiveLog/s1-s5/plots")
source(paste0(baseDir,"/Performance_Logs/SelectiveLog/s1-s5/scripts/function_lib.R"))

##################### plot the accuracy across sessions and conditions ########################
#load data
# NB: the data frame is deliberately NOT called `df`: emmeans re-fits models
# below and the bare name `df` clashes with the base function df().
dat <- read.csv(paste0(baseDir,"/Performance_Logs/SelectiveLog/s1-s5/built-up_dfs/category_accuracy.csv"))

# standardise column names (raw file uses lowercase plural headers)
dat <- dat %>%
  rename(ID = IDs, Condition = conditions, Phase = phases,
         Session = sessions, Category = categories)

# merge in participant Gender from the clean gender table (columns: ID, Gender).
gender_df <- read_excel(file.path(dataDir, "gender.xlsx"), sheet = "Gender")
dat <- dat %>% left_join(gender_df, by = "ID")

# 1) collapse across categories at the participant level:
#    compute, for each ID x phase x condition x session, the mean accuracy
id_means_sess <- dat %>%
  group_by(ID, Phase, Condition, Session) %>%
  summarise(acc_id_mean = mean(cat_accuracy, na.rm = TRUE), .groups = "drop")

# 2) group summary across IDs: mean and SE (SE across IDs)
summary_by_group <- id_means_sess %>%
  group_by(Phase, Condition, Session) %>%
  summarise(
    mean_acc = mean(acc_id_mean, na.rm = TRUE),
    se_acc   = sd(acc_id_mean, na.rm = TRUE) / sqrt(dplyr::n()),
    n_ids    = dplyr::n(),
    .groups  = "drop"
  )

summary_by_group_retrieve <- summary_by_group[summary_by_group$Phase == 'retrieve', ]


#Fig. 2a
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
  save_path = saveDir,
  filename = "category_accuracy_by_session_condition_retrieve.pdf"
)

print(p_sess_retrieve)


##################### plot accuracy across conditions for each object category ##########################

# per-ID mean accuracy collapsed over sessions
id_means_cat <- dat %>%
  group_by(ID, Phase, Condition, Category) %>%
  summarise(acc_id_mean = mean(cat_accuracy, na.rm = TRUE), .groups = "drop")
id_means_cat_retrieve <- id_means_cat[id_means_cat$Phase == 'retrieve', ]


# group summary (mean + SE)
sum_cat <- id_means_cat %>%
  group_by(Phase, Condition, Category) %>%
  summarise(
    mean_acc = mean(acc_id_mean, na.rm = TRUE),
    se_acc   = sd(acc_id_mean, na.rm = TRUE) / sqrt(dplyr::n()),
    .groups = "drop"
  )
sum_cat_retrieve = sum_cat[sum_cat$Phase == 'retrieve', ]

cond_cols <- c(
  "control" = "#707071",
  "sleep"   = "#313f99",
  "wake"    = "#dc1e32"
)

#Fig. S1a
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
                             save_path = saveDir,
                             filename = "accuracy_by_category_condition_retrieve.pdf",
                             width = 6.5,
                             height = 4.5) 

print(p_cat_retrieve)



##########test recall differences across conditions, cateogries & sessions ###########
dat_retrieve = dat[dat$Phase == 'retrieve', ]

# treat Session as categorical so it enters the model as a 4-df factor
dat_retrieve$Session <- factor(dat_retrieve$Session)

model_base_cat_retrieve <- aov(cat_accuracy ~ Condition*Session*Category+Gender,
                               data = dat_retrieve)
summary(model_base_cat_retrieve) # omnibus F-tests

## ----- Effect sizes with confidence intervals -----
eta_squared(model_base_cat_retrieve, partial = TRUE,
            ci = 0.90, alternative = "two.sided")

## ----- Significant effect (Session): pairwise follow-ups with 95% CIs -----
emm_session <- emmeans(model_base_cat_retrieve, ~ Session)
pairs(emm_session, infer = TRUE)
eff_size(emm_session,
         sigma = sigma(model_base_cat_retrieve),
         edf   = df.residual(model_base_cat_retrieve))

## ----- Equivalence tests for the null effects (TOST) -----
sesoi_pp <- 5   # smallest effect of interest, in accuracy percentage points

# Condition (Sleep / Wake / Short-delay): omnibus F2,569 = 0.35, P = .703
test(pairs(emmeans(model_base_cat_retrieve, ~ Condition)),
     delta = sesoi_pp, side = "equivalence")

# Object category (household / toy): omnibus F1,569 = 2.46, P = .117
test(pairs(emmeans(model_base_cat_retrieve, ~ Category)),
     delta = sesoi_pp, side = "equivalence")

# Gender: omnibus F1,569 < 0.01, P = .989
test(pairs(emmeans(model_base_cat_retrieve, ~ Gender)),
     delta = sesoi_pp, side = "equivalence")