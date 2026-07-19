################
# Analysis of schema build-up performance:
# Object (item) recognition accuracy across sessions and conditions -> Fig. S1b
#
# written by L.Bastian, Nov 2025
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

###################### load & prepare data ###########################
dat <- read.csv(paste0(baseDir,"/Performance_Logs/SelectiveLog/s1-s5/built-up_dfs/object_accuracy.csv"))

# standardise column names (raw file uses lowercase plural headers)
dat <- dat %>%
  rename(ID = IDs, Condition = conditions, Session = sessions)
dat <- dat %>% mutate(ID = toupper(ID))

# merge in participant Gender from the clean gender table (columns: ID, Gender).
gender_df <- read_excel(file.path(dataDir, "gender.xlsx"), sheet = "Gender")
dat <- dat %>% left_join(gender_df, by = "ID")

###################### plot accuracy across sessions (Fig. S1b) ###########################
# per-ID mean accuracy for each condition x session
id_means <- dat %>%
  group_by(ID, Condition, Session) %>%
  summarise(acc_id_mean = mean(obj_accuracy, na.rm = TRUE), .groups = "drop")

# group summary across IDs: mean and SE (SE across IDs)
summary_by_group <- id_means %>%
  group_by(Condition, Session) %>%
  summarise(
    mean_acc = mean(acc_id_mean, na.rm = TRUE),
    se_acc   = sd(acc_id_mean, na.rm = TRUE) / sqrt(dplyr::n()),
    n_ids    = dplyr::n(),
    .groups  = "drop"
  )

p_sess <- plot_line_se(
  data = summary_by_group,
  x_var = "Session",
  y_var = "mean_acc",
  se_var = "se_acc",
  group_var = "Condition",
  facet_var = NULL,
  y_label = "Accuracy (%)",
  hline = 50,
  y_limits = c(45, 100),
  save_path = saveDir,
  filename = "object_accuracy_by_session.pdf",
  width = 6,
  height = 4.5
)

print(p_sess)

########## Fig. S1b: test recognition differences across sessions & conditions ###########
# Session is a within-subject factor; Condition and Gender are between-subject.
dat$Session <- factor(dat$Session)
model_obj <- aov(obj_accuracy ~ Condition*Session + Gender + Error(ID/Session),
                 data = dat)
summary(model_obj)   # stratified omnibus F-tests

## ----- Effect sizes with confidence intervals -----
eta_squared(model_obj, partial = TRUE, ci = 0.90, alternative = "two.sided")

## ----- Significant effect (Session): pairwise follow-ups with 95% CIs -----
emm_session <- emmeans(model_obj, ~ Session)
pairs(emm_session, infer = TRUE)
eff_size(emm_session, sigma = sd(dat$obj_accuracy), edf = 228)

## ----- Equivalence tests for the null effects (TOST) -----
sesoi_pp <- 5   # smallest effect of interest, in accuracy percentage points

# Condition (Sleep / Wake / Short-delay): omnibus F2,56 = 0.11, P = .899
test(pairs(emmeans(model_obj, ~ Condition)),
     delta = sesoi_pp, side = "equivalence")

# Gender: omnibus F1,56 = 1.29, P = .261
test(pairs(emmeans(model_obj, ~ Gender)),
     delta = sesoi_pp, side = "equivalence")
