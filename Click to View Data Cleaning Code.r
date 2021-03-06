### This is the R script written by Sam Ashcroft to import, merge, clean and
### prepare for analysis the results of a Python-based computer experiment used in Sam's PhD

# As background, around 80 participants have taken part in a computer experiment
# The experiment requires participants to be trained and tested on relationships between stimuli
# This is quite similar to some kinds of modern brain-training
# The output from the experiments are absolutely awful in terms of structure and tidiness
# Hence this script to clean the data in preparation for analysis

# This script runs around 370 lines of code

# Sam Ashcroft
# sam.ashcroft@hotmail.co.uk
# LinkedIn: www.linkedin.com/in/samashcroft
# GitHub: https://github.com/S-Ashcroft
# RPubs: http://rpubs.com/Ashcroft

# import packages to be used
library(dplyr) # excellent for data cleaning and manipulation. Uses five key verbs
library(beepr) # this can be used to alert you when analyses are complete
library(tidyr) # necessary for cleaning data
library(ez) # can calculate generalised-eta-squared for anovas
library(ggplot2) # for creating graphs and figures
library(car) # contains some data analysis functions
library(psych) # contains useful functions for quickly describing and exploring data
library(Publish) # useful exploratory analysis package

## Importing the data

# first I want to set the working directory to a folder containing my raw data
setwd("~/Documents/PhD Resources/R/Experiment One R Analysis/Experiment One R Analysis/Experiment One Raw Data")

# list all the files ending with '.csv' in the data folder
df_name <- list.files(pattern = "\\.csv$")
# quickly check whether all these files have been listed
df_name

# make a list containing the raw data of all the csvs
df_list <- lapply(df_name,
                  read.csv
)

# bind all the csvs to make one big csv containing the data of all participants
df <- data.table::rbindlist(df_list,
                            use.names = TRUE,
                            idcol = TRUE,
                            fill = TRUE)

## Cleaning the Data

# making all blank cells into NA so they fall under na.rm arguments
# na.rm arguments are arguments in functions that tell teh function to ignore any "NA"s
df[df==""] <- NA

# also changing None to NA, since some blank cells come up as None
df[df=="None"] <- NA

# Data Cleaning
# set the working directory to the output file so that any output from my data cleaning or
# analysis will end up there, rather than filling up and confusing the raw data folder
setwd("~/Documents/PhD Resources/R/Experiment One R Analysis/Experiment One R Analysis/R Output")

# look at the column names so I know what I variables I'm working with
names(df)

# get all the columns I want by deleting those I don't need
df_trim <- df %>%
  select(-wholeFrames.thisRepN,
         -wholeFrames.thisTrialN,
         -responseTrain.keys,
         -responseTrain.corr,
         -responseTrain.rt,
         -affectRating.rt,
         -arousalRating.rt,
         -senseMakingRating.rt,
         -frameRate,
         -session,
         -RPS.SONA.ID.Code,
         -i.e..23.,
         -X
  )

# look at the columns remaining (to get them in the console to work with more easily)
names(df_trim)

# now I will group by block and count the number of attempts on each block of the experiment
# this will create a new dataframe for the number of attempts
# I will then join this dataframe to the original dataframe
sum_correct <- df_trim %>%
  group_by(participant, block) %>%
  summarise(block_attempts_minus_one = max(ifNotOver80.thisRepN, na.rm = TRUE)) %>%
  mutate(block_attempts_this_block = block_attempts_minus_one + 1) %>%
  select(-block_attempts_minus_one) %>%
  ungroup()

# joining both dataframes
# if you want, you can first make an excel sheet to see what it looks like pre-join
# write.csv(df_trim, "Pre_Join_Excel.csv") # unhash the code on this line if needed

# join the two dfs
df_join <- full_join(df_trim, sum_correct, by = c("participant", "block"))

# make an excel sheet to see what it looks like post-join
# write.csv(df_join, "Post_Join_Excel.csv") # unhas the code on this line if needed

# now I will make individual dataframes for each rating at the end of each block of the experiment
# these dataframes will then be merged to the main body of data.
# this is much easier to write, understand and debug/edit than doing all 
# data cleaning within the original dataframe itself

# creating a dataframe for the affect rating of each participant at the end of each block
block_affect_rating_df <- df_join %>% 
  group_by(participant, block) %>%
  summarise(block_affect_rating = 
              sum(as.numeric(as.character(affectRating.response)), na.rm = TRUE)) %>%
  ungroup()

# creating a dataframe for the arousal rating of each participant at the end of each block
block_arousal_rating_df <- df_join %>% 
  group_by(participant, block) %>%
  summarise(block_arousal_rating = 
              sum(as.numeric(as.character(arousalRating.response)), na.rm = TRUE)) %>%
  ungroup()

# creating a dataframe for the sense-making rating of each participant at the end of each block
block_sense_making_rating_df <- df_join %>% 
  group_by(participant, block) %>%
  summarise(block_sense_making_rating = 
              sum(as.numeric(as.character(senseMakingRating.response)), na.rm = TRUE)) %>%
  ungroup()

# now to join all these dfs to the main dataframe (mother_df) in one go
mother_df <- df_join %>%
  full_join(block_affect_rating_df, by = c("participant", "block")) %>%
  full_join(block_arousal_rating_df, by = c("participant", "block")) %>%
  full_join(block_sense_making_rating_df, by = c("participant", "block"))

# delete the now redundant rows that are by-products of way the output from the Python...
# experiment was formatted.
# to do this, I find a column that contains NAs on certain rows and will delete them

# First, count the NAs in this column. False is what should remain (cells with values in)
# TRUE is what should be deleted (cells with NAs)
table(is.na(mother_df$trials.thisRepN))
# then delete all rows with NAs
mother_df_2 <- subset(mother_df, !is.na(trials.thisRepN)) 
# this has deleted a vast number of now redundant rows.

# turn the block order number (from Python, 0:5) to normal numbers 1-6
mother_df_4 <- mother_df_2 %>% 
  mutate(block_order_number = wholeFrames.thisN + 1) %>%
  select(-wholeFrames.thisN)

# create a block_code variable so I know which of the six blocks I am dealing with
# the code is: (AmbA = 1, CohA = 4). There are three 'amb's and three 'coh's, 1-6
mother_df_5 <- mother_df_4 %>% 
  mutate(block_code = wholeFrames.thisIndex + 1) %>%
  select(-wholeFrames.thisIndex)

# look at the columns we have left so that we know what we want to delete
names(mother_df_5)

# delete redundant columns
mother_df_6 <- select(mother_df_5,
                      -ifNotOver80.thisRepN,
                      -ifNotOver80.thisTrialN,
                      -ifNotOver80.thisN,
                      -ifNotOver80.thisIndex,
                      -trainingLoops.thisRepN,
                      -trainingLoops.thisTrialN,
                      -trainingLoops.thisN,
                      -trainingLoops.thisIndex,
                      -affectRating.response,
                      -arousalRating.response,
                      -senseMakingRating.response,
                      ifNotOver80.thisTrial
)

# turn gender from M/F into 0/1 for analysis
mother_df_7 <- mother_df_6 %>% mutate(Gender_0F_1M = 
                                        ifelse(Gender..e.g..M.or.F. == "M", 1, 0)) %>%
  select(-Gender..e.g..M.or.F.)

# rename and reorder all variables in one fell swoop using dplyr::select
mother_df_8 <- mother_df_7 %>%
  select(participant,
         age = Age..Number,
         Gender_0F_1M,
         expName,
         block,
         block_code,
         block_order_number,
         block_attempts_this_block,
         stimR,
         picRel,
         stimL,
         stimL,
         corrAns,
         realRel,
         trials.thisRepN,
         trials.thisTrialN,
         trials.thisN,
         trials.thisIndex,
         test_response_keys = responseTest.keys,
         test_response_rt = responseTest.rt,
         block_affect_rating,
         block_arousal_rating,
         block_sense_making_rating
  )

# making a column for correct = 1 and incorrect = 0 for each trial
# notice that in the df, corrAns has "none" for amb blocks. 
# This is because there is no correct answer, so...
# accordingly, this will become a 0 in the new column
mother_df_999 <- mother_df_8 %>% mutate(Correct1_Incorrect0 = 
                                          ifelse(as.character(corrAns) == as.character(test_response_keys), 1, 0))
# the silly numbered dataframe label is used to indicate that it is an intermediate df not to be used

# arrange the df by participant
mother_df_9 <- mother_df_999 %>% arrange(participant)

# data cleaning is largely complete, and this is a 'good place to save'
# further cleaning involves a few manipulations I might do to refine the dataset -
# and also prepare numerous dataframes for different kinds of analysis.
# Additionally, I will do a few checks before doing any further manipulations
# Usually I would run a bunch of checks as I go along to look at how the cleaning is going.
# So, write the current clean, tidy data file to a csv
write.csv(mother_df_9, "Cleaned Experiment One Data.csv")

# create a quick dataframe to glance at the correctness of participants on blocks
correct_output_df <- mother_df_9 %>% group_by(participant, block) %>%
  summarise(correct_sum = sum(Correct1_Incorrect0))

# getting the mean across each block for participant to then graph
mean_corr_df <- correct_output_df %>% group_by(participant) %>%
  summarise(mean_corr = mean(correct_sum, na.rm = TRUE))
# make a histogram of the correctness
hist(mean_corr_df$mean_corr, breaks = 25)

# convert mean_corr_df to percents
percent_corr_df <- mean_corr_df %>% group_by(participant) %>%
  mutate(percent_corr = 100*(mean_corr/48))
# make a histogram
hist(percent_corr_df$percent_corr, breaks = 25)

# adding new variable to mother_df_9 which is 'what button the participant pressed'
mother_df_10 <- mother_df_9 %>% 
  mutate(button_press_Z1_M0 = 
           ifelse(test_response_keys == "z", 1, 0))

# adding new variable to mother_df_10 which is 'what stimulus the participant chose'
## NOTE this only works for ambiguous blocks. Coherent blocks all revert to 0
mother_df_11 <- mother_df_10 %>% 
  mutate(stim_chosen_0_1 = 
           ifelse(stimR %in% c("CDO", "LDF", "KYW") & test_response_keys == "m", 1, 0))

# adding new variable to mother_df_11 which is whether the participant chose A>C or A<C
# CAUTION this is only for amb blocks, which is why coh blocks all come up 0
mother_df_12 <- mother_df_11 %>% 
  mutate(compound_AbiggerC1_AsmallerC0 = 
           ifelse(
             # stim A plus BIGGER plus CHOSEN
             # stim A
             stimR %in% c("CDO", "LDF", "KYW") &
               # symbols indicating 'bigger'
               picRel %in% c("####", "????", "\"") &
               # if that response was chosen
               test_response_keys == "m" |
               
               # stim B plus SMALLER plus CHOSEN 
               stimR %in% c("ZKR", "RSQ", "YNM") &
               picRel %in% c("****", "%%%%", "[[[[") &
               test_response_keys == "m" |
               
               # stim A plus SMALLER plus NOT CHOSEN
               stimR %in% c("CDO", "LDF", "KYW") &
               picRel %in% c("****", "%%%%", "[[[[") &
               test_response_keys == "z"  |
               
               # stim B plus BIGGER plus NOT CHOSEN 
               stimR %in% c("ZKR", "RSQ", "YNM") &
               picRel %in% c("####", "????", "\"") &
               test_response_keys == "z" 
             
             # if any of the above true, then 1, else 0 
             , 1, 0))

# just checking the final mutation worked correctly
checking <- mother_df_12 %>% filter(block_code == 1:3) %>%
  select(block_code, stimR, picRel, test_response_keys, compound_AbiggerC1_AsmallerC0)

## Here I make a few other dataframes in preparation for other checks, graphs and analyses
# df_2 will have the means for each block (more variables than flattened_df)
# use mother_df_12 if you are after raw individual trial information
# test_response_rt is not in here because you should not average it twice
# test_response_correct also should not be averaged twice so it was removed

# flatten (average or sum) the main dataframe by participant and block
flattened_df <- mother_df_12 %>% group_by(participant, block) %>%
  summarise(age = mean(age), 
            gender = mean(Gender_0F_1M), 
            block_code = mean(block_code),
            block_order_number = mean(block_order_number),
            block_attempts_this_block = mean(block_attempts_this_block),
            sum_test_correct = sum(Correct1_Incorrect0),
            block_affect_rating = mean(block_affect_rating),
            block_arousal_rating = mean(block_arousal_rating),
            block_sense_making_rating = mean(block_sense_making_rating),
            sum_button_pressed = sum(button_press_Z1_M0),
            sum_stim_picked = sum(stim_chosen_0_1),
            sum_compound_responding = sum(compound_AbiggerC1_AsmallerC0)
  )

# make a new variable for block type
df_1 <- flattened_df %>% mutate(block_type_0A_1C = ifelse(block_code == 1:3, 0, 1))

# df_2 is primary df for next few steps
df_2 <- df_1

# note - df_2 is flattened_df but with more variables. 
# df_2 contains all participant data, and usually you would remove some outliers etc
# use the later df_limits for all stats where outliers should be removed

## this is where I will remove participants that reached the 10 loop attempts limit
# first make a df of all 10 loop attempters
limit_reached_df <- df_2 %>% filter(block_attempts_this_block == 10)

# these are all the 10 loop attempters
unique(limit_reached_df$participant)

# using a hist you can see that most people reached the limit of attempts on block 1
hist(limit_reached_df$block_order_number)

# remove all participants that went to 10 loop limit attempts
df_limits_removed <- df_2 %>%
  subset(subset = !(participant %in% limit_reached_df$participant))

# count how many participants are left
# I know there are 53 participants left, but this could be recoded to be more flexible
# I have simply copied and pasted what I wrote in the console on the fly
n_distinct(df_limits_removed$participant)
gender_count <- df_limits_removed %>% group_by(participant) %>% 
  summarise(gender_ss = mean(gender),
            age_ss = mean(age))
nrow(gender_count)
# count how many males
males <- sum(gender_count$gender_ss)
# count how many females
females <- 53 - males
# get descriptive statistics
mean_age <- mean(gender_count$age_ss)
sd_age <- sd(gender_count$age_ss)
range(gender_count$age_ss)
mean_age
sd_age

# create dataframe for average of all outcomes by using group_by
# correct_percent deleted from here because it was being averaged twice
average_outcomes_df <- df_limits_removed %>% group_by(participant, block_type_0A_1C) %>% 
  summarise(age = mean(age),
            gender_0F_1M = max(gender),
            average_block_attempts_this_block = mean(block_attempts_this_block),
            average_sum_correct = mean(sum_test_correct),
            average_sum_button = mean(sum_button_pressed),
            average_sum_stim_chosen = mean(sum_stim_picked),
            average_block_affect_rating = mean(block_affect_rating),
            average_block_arousal_rating = mean(block_arousal_rating),
            average_block_sense_making_rating = mean(block_sense_making_rating),
            average_sum_compound = mean(sum_compound_responding)
  )

### Data Cleaning and Manipulating Complete

# write the very clean, tidy data file to a csv
write.csv(df_2, "Cleaned Average Data for Experiment One (INSERT DATE).csv")
# be informed that the analysis is complete by the computer speaking this message
system("say -v Daniel Hey sam your data has been cleaned and tidied")
# run a sound to make you feel happy inside regarding your coding abilities
beep(3)

# data cleaning is done, and what I would do next is to start ..
# checking the df for anomalies both by viewing the excel sheet, 
# and using commands such as the following
str(df_2) # to view the structure (variable type etc)
summary(df_2) # to get a summary of results (descriptive stats of all variables)

### End of Code

# Sam Ashcroft
# sam.ashcroft@hotmail.co.uk
# LinkedIn: www.linkedin.com/in/samashcroft
# GitHub: https://github.com/S-Ashcroft
# RPubs: http://rpubs.com/Ashcroft
