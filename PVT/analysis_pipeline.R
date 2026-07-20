library(dplyr)
library(tidyr)
library(ggplot2)
library(emmeans)
library(effectsize)   # effect sizes (partial eta^2, Cohen's d) with CIs
library(BayesFactor)  # Bayes factors for the null (no condition difference)

#DEFINE
rootDir = '/Volumes/T7/01_SchemAcS/05_Analysis/PVT' 

#functions
se <- function(x){sd(x, na.rm = TRUE)/sqrt(length(!is.na(x)))}

#load data
PVT_df_sleep   <- read.csv(paste0(rootDir,"/results/PVT_df_sleep.csv"))
PVT_df_control <- read.csv(paste0(rootDir,"/results/PVT_df_Kontrolle.csv"))
PVT_df_wake <- read.csv(paste0(rootDir,"/results/PVT_df_wake.csv"))


########################### TEST DIFFERENCES IN RT #############################

#are the two groups different cross the sessions? 
PVT_df <- rbind(PVT_df_sleep,PVT_df_control,PVT_df_wake)
PVT_df$condition <- c(rep("sleep",nrow(PVT_df_sleep)),rep("control",nrow(PVT_df_control)),rep("wake",nrow(PVT_df_wake)))
PVT_df$condition <- factor(PVT_df$condition)
PVT_df$session   <- factor(PVT_df$session)
PVT_df$sess_cond <- c(paste0(PVT_df$session,"_",PVT_df$condition))

# Omnibus mixed ANOVA on average reaction time.
# Reported in Suppl. (Fig. S2): Condition x Session interaction.
model_PVT <- aov(avg_rt ~ condition*session, data = PVT_df)
summary(model_PVT)

## ---- Effect sizes for the omnibus ANOVA (partial eta^2, 90% CI) ------------
eta_PVT <- eta_squared(model_PVT, partial = TRUE, ci = .90,
                       alternative = "two.sided")
print(eta_PVT)

## ---- Pairwise condition contrasts (95% CI) + Cohen's d --------------------
emm_cond <- emmeans(model_PVT, ~ condition)
pairs(emm_cond, infer = TRUE)                       # differences (ms) + 95% CI
eff_size(emm_cond, sigma = sigma(model_PVT),        # standardised effect (d)
         edf = df.residual(model_PVT))


################## BAYES FACTOR: EVIDENCE FOR NO DIFFERENCE ####################
# A non-significant ANOVA is only absence of evidence. To quantify evidence FOR
# the null (PVT reaction time does not differ between retention conditions) we
# compute Bayes factors. Condition is BETWEEN subjects, so we collapse the 7
# repeated sessions into one mean per participant (avoids pseudo-replication)
# and compare each pair of conditions with a two-sample JZS Bayes factor.
# H0: delta = 0 ; H1: delta ~ Cauchy(0, r).  BF01 > 1 favours the null.

PVT_subj <- PVT_df %>%
  group_by(subID, condition) %>%
  summarise(rt = mean(avg_rt, na.rm = TRUE), .groups = "drop")

cond_pairs <- list(c("sleep","control"), c("sleep","wake"), c("control","wake"))

## ---- Bayes factor at the default 'medium' JZS prior (r = 0.707) -----------
bf_PVT <- lapply(cond_pairs, function(pc){
  x <- PVT_subj$rt[PVT_subj$condition == pc[1]]
  y <- PVT_subj$rt[PVT_subj$condition == pc[2]]
  bf10 <- extractBF(ttestBF(x = x, y = y, rscale = "medium"))$bf
  # observed standardised effect (Cohen's d, pooled SD) for context
  d_obs <- (mean(x) - mean(y)) /
    sqrt(((length(x)-1)*var(x) + (length(y)-1)*var(y)) / (length(x)+length(y)-2))
  cat(sprintf("\n#### BF: %s vs %s ####  d = %+.3f | BF10 = %.2f | BF01 = %.2f\n",
              pc[1], pc[2], d_obs, bf10, 1/bf10))
  data.frame(pair = paste(pc, collapse = "_vs_"), d_obs = d_obs,
             BF10 = bf10, BF01 = 1/bf10)
})
bf_PVT <- do.call(rbind, bf_PVT)

## ---- Prior robustness: BF01 across Cauchy prior scales r ------------------
# Evidence direction should be stable; strength grows with prior width.
r_grid <- c(0.2, 0.354, 0.5, 0.707, 1.0, 1.414)   # narrow ... ultrawide
bf_robust <- lapply(cond_pairs, function(pc){
  x <- PVT_subj$rt[PVT_subj$condition == pc[1]]
  y <- PVT_subj$rt[PVT_subj$condition == pc[2]]
  bf01 <- sapply(r_grid, function(r) 1/extractBF(ttestBF(x = x, y = y, rscale = r))$bf)
  data.frame(pair = paste(pc, collapse = "_vs_"), t(setNames(bf01, paste0("r=", r_grid))),
             check.names = FALSE)
})
bf_robust <- do.call(rbind, bf_robust)
cat("\n#### BF01 prior-robustness (rows = pairs, columns = prior scale r) ####\n")
print(bf_robust, row.names = FALSE)


################################## PLOTS #######################################

#plot REACTION TIMES as shown in Fig. S2d
sum_rt        <- summarise(group_by(PVT_df, sess_cond), my_mean=mean(avg_rt, na.rm = TRUE),my_se=se(avg_rt))
sum_rt$session   <- sapply(strsplit(sum_rt$sess_cond, "_"), `[`, 1)
sum_rt$condition <- sapply(strsplit(sum_rt$sess_cond, "_"), `[`, 2)

rt_plot <- ggplot(sum_rt,
            aes(x=session, y=my_mean, group=condition, color=condition)) +
  geom_line(position = position_dodge(width = 0.2), linewidth = 0.8) +
  geom_point(position = position_dodge(width = 0.2), size = 3) +
  geom_errorbar(
    aes(ymin = my_mean - my_se, ymax = my_mean + my_se),
    width = 0.15,
    position = position_dodge(width = 0.2),
    linewidth = 0.6
  ) +
  ylim(260,340)+
  scale_color_manual(
    values = c(
      "control" = "darkgrey",
      "sleep"   = "#1f78b4",
      "wake"    = "#e31a1c"
    )
  ) +
  labs(
    x = "Session",
    y = "Reaction time (ms)",
    color = "Condition"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "top"
  )

print(rt_plot)

ggsave(paste0(rootDir,"/plots/rt_plot.pdf"), plot = rt_plot, width = 6, height = 4)


#plot WAIT TIMES
sum_wait        <- summarise(group_by(PVT_df, sess_cond), my_mean=mean(avg_wait, na.rm = TRUE),my_se=se(avg_wait))
sum_wait$session   <- sapply(strsplit(sum_wait$sess_cond, "_"), `[`, 1)
sum_wait$condition <- sapply(strsplit(sum_wait$sess_cond, "_"), `[`, 2)


wait_plot <- ggplot(sum_wait, aes(x=session, y=my_mean, group=condition, color=condition)) + 
  geom_line(size = 1,
            position = position_dodge(width = 0.3))+
  geom_pointrange(aes(ymin=my_mean-my_se, ymax=my_mean+my_se), 
                  size = 1, 
                  linewidth = 1,
                  position = position_dodge(width = 0.3)) +
  labs(x = "Session", y = "Wait time [ms]") +
  ggtitle("PVT Wait Times") +
  theme_classic()+
  theme(axis.text.x = element_text(angle = 0, size = 10, colour = 'black'), 
        axis.text.y = element_text(size = 10, colour = 'black'),
        plot.title = element_text(size=13)) +
  scale_color_manual(values=c('darkgrey','#1f78b4','#e31a1c'))

ggsave(paste0(rootDir,"/plots/wait_plot.pdf"), plot = wait_plot, width = 6, height = 4)



