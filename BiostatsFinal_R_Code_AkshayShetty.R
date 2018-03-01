#Get random distribution of gender
gender_createset <- function(n=100){
  
  bin_sample = rbinom(n , size = 1, prob = 0.5)
  gender <- vector()
  
  for(i in bin_sample){
    if(i == 0){
      gender <- c(gender, 'Male')
    }
    else
      gender <- c(gender, 'Female')
  }
  
  gender    
}

#Function to create sdq subsets 
sdq_createset <- function(gender, male_mean, male_sd, female_mean, female_sd, mult_fact = c(0.65,0.80,1.05)){
  
  i = 1;
  j = 1;
  
  # We have 4 enteries per person 
  Totalcount_of_males = sum(gender == "Male")/4
  Totalcount_of_females = sum(gender == "Female")/4
  
  
  male_dist <- rnorm(n = Totalcount_of_males, mean = male_mean, sd = male_sd)
  female_dist <- rnorm(n  = Totalcount_of_females, mean = female_mean, sd = female_sd)
  
  
  sdq = c()
  
  Totalcount_of_subjects = Totalcount_of_females + Totalcount_of_males
  
  for(k in 1:Totalcount_of_subjects){
    index <- (k-1)*4 + 1
    
    if(gender[index] == "Female"){
      sdq_base <- female_dist[j]
      sdq_exit <- rnorm(n=1, mean = (sdq_base*mult_fact[1]), sd = female_sd)
      sdq_f1 <- rnorm(n=1, mean = (sdq_exit*mult_fact[2]), sd = female_sd)
      sdq_f2 <- rnorm(n=1, mean = (sdq_f1*mult_fact[3]), sd = female_sd)
      sdq <- c(sdq, sdq_base, sdq_exit, sdq_f1, sdq_f2)
      j <- j+1
    }
    else if(gender[index] == "Male"){
      sdq_base <- male_dist[i]
      sdq_exit <- rnorm(n=1, mean = (sdq_base*mult_fact[1]), sd = male_sd)
      sdq_f1 <- rnorm(n=1, mean = (sdq_exit*mult_fact[2]), sd = male_sd)
      sdq_f2 <- rnorm(n=1, mean = (sdq_f1*mult_fact[3]), sd = male_sd)
      sdq <- c(sdq, sdq_base, sdq_exit, sdq_f1, sdq_f2)
      i <- i+1
    }
    
  }
  sdq
}

missing_10 <- function(survey_table, n, p){
  sample_set <- c()
  
  for(i in 1:n){
    index <- ((i-1)*4 + 2):(i*4)
    sample_set <- c(sample_set, index)
  }
  sample_na <- sample(sample_set, (3*n*p))
  
  for(j in sample_na){
    survey_table[j,][5:9] = NA
  }
  survey_table
}

last_missing_assessment <- function(survey_table, n, assessmentProb){
  
  assessment <- c('baseline','exit','followup1','followup2')
  sample_assess <- sample(assessment, n, replace=TRUE, prob=assessmentProb)
  
  for(i in 1:n){
    sampled_visit <- sample_assess[i]
    
    if(sampled_visit == 'baseline'){
      survey_table[survey_table$SubjNum == i,][survey_table[survey_table$SubjNum == i,]$visit == 'exit',][5:9] = NA
      survey_table[survey_table$SubjNum == i,][survey_table[survey_table$SubjNum == i,]$visit == 'followup1',][5:9] = NA
      survey_table[survey_table$SubjNum == i,][survey_table[survey_table$SubjNum == i,]$visit == 'followup2',][5:9] = NA
    }
    else if(sampled_visit == 'exit'){
      survey_table[survey_table$SubjNum == i,][survey_table[survey_table$SubjNum == i,]$visit == 'followup1',][5:9] = NA
      survey_table[survey_table$SubjNum == i,][survey_table[survey_table$SubjNum == i,]$visit == 'followup2',][5:9] = NA
    }
    else if(sampled_visit == 'followup1'){
      survey_table[survey_table$SubjNum == i,][survey_table[survey_table$SubjNum == i,]$visit == 'followup2',][5:9] = NA
    }
  }
  survey_table
}

formattingSDQ <-function(x){
  
  output <- x
  
  if(is.na(x))
    output <- x
  else if(x < 0)
    output <- 0
  else if(x > 10)
    output <- 10
  else 
    output <- round(x)
  
  output
}


Dataset_simulation <- function(n=100, p1=0.10, pvec=c(0.10, 0.17, 0.18, 0.55)){
  
  #Construct the subject numbers, subject gender and subject age
  SubjNum <- 1:n
  SubjGender <- gender_createset(n)
  SubjAge <- round(runif(n, min=4, max=17))
  
  #Create dataset 
  #Survey table 
  survey_table <- data.frame(SubjNum, SubjGender, SubjAge)
  
  #Add Baseline, Followup1, Followup2, Exit values to each child
  survey_table <- survey_table[rep(seq_len(nrow(survey_table)), each=4),]
  survey_table$visit <- rep(c('baseline', 'exit', 'followup1', 'followup2'), n)
  
  #Define the subscale factors
  
  #ESS,CPS,IHA,PPS
  f1 <- c(0.65, 0.80, 1.05)
  
  #PSB - Prosocial 
  f2 <- c(1.35, 1.20, 0.95)
  
  #f1
  # Using the means and sd calculated using SAS 
  survey_table$sdq_ess <- sdq_createset(survey_table$SubjGender, 3.33, 2.23, 3.69, 2.32, f1)
  survey_table$sdq_cps <- sdq_createset(survey_table$SubjGender, 2.72, 2.13, 2.42, 1.90, f1)
  survey_table$sdq_iha <- sdq_createset(survey_table$SubjGender, 5.02, 2.54, 4.05, 2.64, f1)
  survey_table$sdq_pps <- sdq_createset(survey_table$SubjGender, 2.27, 1.89, 2.07, 1.87, f1)
  
  #f2
  #Using means and sd calculated using SAS
  survey_table$sdq_psb <- sdq_createset(survey_table$SubjGender, 6.44, 2.09, 7.23, 1.76, f2)
  
  #Simulate 10% missing on other times other than baseline
  if(p1 != 0)
  survey_table <- missing_10( survey_table, n, p1)
  
  #select a last completed assessment time point and set all 
  #subscales equal to NA for subsequent assessment time points
  survey_table <- last_missing_assessment( survey_table, n, pvec)
  
  #Format subscale values
  survey_table$sdq_ess <- unlist(lapply(survey_table$sdq_ess, formattingSDQ))
  survey_table$sdq_cps <- unlist(lapply(survey_table$sdq_cps, formattingSDQ))
  survey_table$sdq_iha <- unlist(lapply(survey_table$sdq_iha, formattingSDQ))
  survey_table$sdq_pps <- unlist(lapply(survey_table$sdq_pps, formattingSDQ))
  survey_table$sdq_psb <- unlist(lapply(survey_table$sdq_psb, formattingSDQ))
  
  survey_table;
  
}


T_test_stats <- function(survey_table, n){
  
  xsamples <- c()
  ysamples <- c()
  
  for(i in 1:n){
    subject_rows <- survey_table[survey_table$SubjNum == i,]
    
    #Get Followup2 row 
    subject_f2 <- subject_rows[subject_rows$visit == 'followup2',]
    
    #Get Followup1 row
    subject_f1 <- subject_rows[subject_rows$visit == 'followup1',]
    
    #Get Exit row
    subject_exit <- subject_rows[subject_rows$visit == 'exit',]
    
    #Get Base row 
    subject_base <- subject_rows[subject_rows$visit == 'baseline',]
    
    if(!is.na(subject_f2$sdq_cps)){
      ysamples <- c(ysamples, subject_f2$sdq_cps)
      xsamples <- c(xsamples, subject_base$sdq_cps)
    }
    else if(!is.na(subject_f1$sdq_cps)){
      ysamples <- c(ysamples, subject_f1$sdq_cps)
      xsamples <- c(xsamples, subject_base$sdq_cps)
      #  print("f1")
    }
    else if(!is.na(subject_exit$sdq_cps)){
      ysamples <- c(ysamples, subject_exit$sdq_cps)
      xsamples <- c(xsamples, subject_base$sdq_cps)
    }
  }
  

  result <- t.test(xsamples, ysamples)$p.value 
  
  result
}

Create_and_Ttest <- function(n=100, p1=0.10, pvec=c(0.10, 0.17, 0.18, 0.55)){
  
  count = 0;
  for(i in 1:500){
    survey_table <- Dataset_simulation(n, p1, pvec)
    p <- T_test_stats(survey_table, n)
    if(p < 0.05)
      count = count + 1
  }
  
  count/500
}


SampleSizeEffecPlot <- function(){
  x_values <- c( 10, 20, 30, 40, 50, 60, 70, 80, 90, 100)
  y_values <- c()
  for(x in x_values){
    y_values <- c(y_values, Create_and_Ttest(n=x))
  }
  plot(x_values, y_values,
       type = "l",
       main = "Sample size effect on Significant treatment effect", 
       xlab = "Sample Size", 
       ylab = "Percentage of significant treatment effect",
       col  = "green")
}

MissingdataeffectPlot <- function(){
  x_values <- c(0, 0.01, 0.02, 0.05, 0.075, 0.1, 0.25, 0.4, 0.5,0.9)
  y_values <- c()
  for(x in x_values){
    y_values <- c(y_values, Create_and_Ttest(p1=x))
  }
  plot(x_values, y_values,
       type="l",
       main= "First missing percentage effect on significant treatment",
       xlab="First missing percentage",
       ylab="Percentage of significant treatment effect",
       col = "blue")
}

#Main execution 1: Plot significant effect percentage vs Sample size
SampleSizeEffecPlot()

#Main execution 1: Plot significant effect percentage vs Missing data probability
MissingdataeffectPlot()
