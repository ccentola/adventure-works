# LOAD PACKAGES -----------------------------------------------------------

# load packages
pacman::p_load(tidyverse, GGally, gridExtra, caret, grid, knitr, kableExtra)

# CUSTOM PLOT -------------------------------------------------------------

# base color
base <- '#DD4747'

# create a universal custom theme
custom_theme <- function(base_size = 12) {
  bg_color = 'white'
  bg_rect = element_rect(fill = bg_color, color = bg_color)
  gridlines = element_blank()
  
  theme_classic(base_size) +
    theme(
      text = element_text(family = 'Roboto'),
      plot.title = element_text(family = 'Roboto', 
                                face = 'bold',
                                size = 24),
      plot.subtitle = element_text(size = rel(1), lineheight = 1),
      plot.caption = element_text(size = rel(0.75), 
                                  margin = unit(c(1, 0, 0, 0), 'lines'), 
                                  lineheight = 1.1, 
                                  color = '#555555'),
      plot.background = bg_rect,
      axis.ticks = element_blank(),
      axis.text.x = element_text(size = rel(1)),
      axis.title.x = element_text(size = rel(1), 
                                  margin = margin(1, 0, 0, 0, unit = 'lines')),
      axis.text.y = element_text(size = rel(1)),
      axis.title.y = element_text(size = rel(1)),
      panel.background = bg_rect,
      panel.border = element_blank(),
      panel.grid.major = gridlines,
      panel.grid.minor = gridlines,
      panel.spacing = unit(1.25, 'lines'),
      legend.background = bg_rect,
      legend.key.width = unit(1.5, 'line'),
      legend.key = element_blank(),
      strip.background = element_blank()
    )
}



# LOAD DATA ---------------------------------------------------------------


# customer data
customers <- read_csv('AWCustomers.csv', col_types = cols(
  CustomerID = col_integer(),
  Title = col_character(),
  FirstName = col_character(),
  MiddleName = col_character(),
  LastName = col_character(),
  Suffix = col_character(),
  AddressLine1 = col_character(),
  AddressLine2 = col_character(),
  City = col_character(),
  StateProvinceName = col_character(),
  CountryRegionName = col_character(),
  PostalCode = col_character(),
  PhoneNumber = col_character(),
  BirthDate = col_date(format = ""),
  Education = col_character(),
  Occupation = col_factor(levels = c('Skilled Manual','Manual', 'Clerical',
                                     'Management','Professional')),
  Gender = col_factor(levels = c('M','F')),
  MaritalStatus = col_factor(levels = c('M','S')),
  HomeOwnerFlag = col_integer(),
  NumberCarsOwned = col_integer(),
  NumberChildrenAtHome = col_integer(),
  TotalChildren = col_integer(),
  YearlyIncome = col_integer(),
  LastUpdated = col_date(format = "")
))

# sales data
sales <- read_csv('AWSales.csv', col_types = cols(
  CustomerID = col_integer(),
  BikeBuyer = col_integer(),
  AvgMonthSpend = col_double()
))


# classification training data
class.test <- read_csv('AWTest-Classification.csv', col_types = cols(
  CustomerID = col_integer(),
  Title = col_character(),
  FirstName = col_character(),
  MiddleName = col_character(),
  LastName = col_character(),
  Suffix = col_character(),
  AddressLine1 = col_character(),
  AddressLine2 = col_character(),
  City = col_character(),
  StateProvinceName = col_character(),
  CountryRegionName = col_character(),
  PostalCode = col_character(),
  PhoneNumber = col_character(),
  BirthDate = col_date(format = ""),
  Education = col_character(),
  Occupation = col_factor(levels = c('Skilled Manual','Manual', 'Clerical',
                                     'Management','Professional')),
  Gender = col_factor(levels = c('M','F')),
  MaritalStatus = col_factor(levels = c('M','S')),
  HomeOwnerFlag = col_integer(),
  NumberCarsOwned = col_integer(),
  NumberChildrenAtHome = col_integer(),
  TotalChildren = col_integer(),
  YearlyIncome = col_integer(),
  LastUpdated = col_date(format = "")
))

# regression training data
reg.test <- read_csv('AWTest-Regression.csv', col_types = cols(
  CustomerID = col_integer(),
  Title = col_character(),
  FirstName = col_character(),
  MiddleName = col_character(),
  LastName = col_character(),
  Suffix = col_character(),
  AddressLine1 = col_character(),
  AddressLine2 = col_character(),
  City = col_character(),
  StateProvinceName = col_character(),
  CountryRegionName = col_character(),
  PostalCode = col_character(),
  PhoneNumber = col_character(),
  BirthDate = col_date(format = ""),
  Education = col_character(),
  Occupation = col_factor(levels = c('Skilled Manual','Manual', 'Clerical',
                                     'Management','Professional')),
  Gender = col_factor(levels = c('M','F')),
  MaritalStatus = col_factor(levels = c('M','S')),
  HomeOwnerFlag = col_integer(),
  NumberCarsOwned = col_integer(),
  NumberChildrenAtHome = col_integer(),
  TotalChildren = col_integer(),
  YearlyIncome = col_integer(),
  LastUpdated = col_date(format = "")
))


# STRUCTURE ---------------------------------------------------------------

str(customers, give.attr=F)
str(sales)

# DATA CLEANING -----------------------------------------------------------

# remove duplicates
customers %>% group_by(CustomerID) %>% filter(n() > 1)
sales %>% group_by(CustomerID) %>% filter(n() > 1)

# remove duplicate customers
customers <- customers %>% dplyr::distinct(CustomerID, .keep_all = TRUE)
dim(customers)

# join sales data
df <- left_join(customers, sales, by = "CustomerID")
head(df)

# check for na values
sapply(df, function(x) sum(is.na(x)))


# DESCRIPTIVE STATISTICS --------------------------------------------------

# select numeric columns
num <- df %>% 
  dplyr::select_if(is.numeric) %>% 
  dplyr::select(-1)

# summarize numeric data
summary(num)

# correlation of numeric data
cor(num)

# correlation matrix
a <- ggcorr(num, hjust = 0.75, size = 5, layout.exp = 1, label = TRUE, label_size = 3, label_color = "white")

a

# convery BikeBuyer to factor
df$BikeBuyer <- as.factor(df$BikeBuyer)

# calculate age  
df$Age <- as.numeric(floor(difftime(df$LastUpdated,
                                    df$BirthDate, 
                                    units = "weeks")/52))

# age bins
df$Age_Bin_Under_18 <- ifelse(df$Age <= 18, 1, 0)
df$Age_Bin_19_to_25 <- ifelse(df$Age >= 19 & df$Age <= 25, 1, 0)
df$Age_Bin_26_to_29 <- ifelse(df$Age >= 26 & df$Age <= 29, 1, 0)
df$Age_Bin_30_to_50 <- ifelse(df$Age >= 30 & df$Age <= 50, 1, 0)
df$Age_Bin_Over_50 <- ifelse(df$Age >= 51, 1, 0)



# single age bin
df$Age_Bin <- as.factor(ifelse(df$Age_Bin_Under_18 == 1, 'Under 18',
                               ifelse(df$Age_Bin_19_to_25 == 1, '19 to 25',
                                      ifelse(df$Age_Bin_26_to_29 == 1, '26 to 29',
                                             ifelse(df$Age_Bin_30_to_50 == 1, '30 to 50',
                                                    ifelse(df$Age_Bin_Over_50 == 1, 'Over 50',0))))))

# car bins
df$Car_Bins <- as.factor(ifelse(df$NumberCarsOwned == 0, "0", "+1"))

# child bins
df$Child_Bins <- as.factor(ifelse(df$NumberChildrenAtHome == 0, "0", "+1"))

df %>%
  group_by(MaritalStatus, BikeBuyer) %>%
  summarise(n = n())

min(df$YearlyIncome)
max(df$YearlyIncome)

# VISUALIZATION -----------------------------------------------------------

# bar chart of bike buyers
b <- ggplot(df, aes(BikeBuyer, fill = BikeBuyer)) +
  geom_bar() +
  labs(title="Bike Buyers", 
       subtitle="Customers who purchased a bicycle vs those who did not",
       x="BikeBuyer",
       y="Count") +
  scale_x_discrete(labels = c('No','Yes')) +
  scale_fill_manual('BikeBuyer', 
                    values = c('#E41A1C','#377EB8'),
                    labels = c('No','Yes'),
                    guide = F)

b + custom_theme()

# histogram of AvgMonthSpend
c <- ggplot(df, aes(AvgMonthSpend)) + 
  geom_histogram(breaks = seq(40,70, by = 2),
                 color = 'black',
                 fill = 'grey') + 
  geom_vline(aes(xintercept=mean(AvgMonthSpend, na.rm=T)),
             color='red', linetype='dashed', size=1) +
  labs(title="Average Monthly Spend", 
       subtitle="Distribution of Adventure Works customer average monthly spend") +
  theme(plot.title = element_text(size = rel(2)))

c + custom_theme()


# AVG MONTH SPEND GRID ----------------------------------------------------

# AvgMonthSpend by MaritalStatus
d <- ggplot(df, aes(Age_Bin, AvgMonthSpend, fill = Age_Bin)) +
  geom_boxplot() +
  scale_fill_brewer(palette = "Set1") +
  coord_flip()
d

# AvgMonthSpend by MaritalStatus
d <- ggplot(df, aes(MaritalStatus, AvgMonthSpend, fill = MaritalStatus)) +
  geom_boxplot() +
  scale_fill_manual('BikeBuyer', 
                    values = c('#E41A1C','#377EB8'),
                    labels = c('No','Yes'),
                    guide = F) +
  coord_flip()
d

# AvgMonthSpend by NumberCarsOwned
e <- ggplot(df, aes(Car_Bins, AvgMonthSpend, fill = Car_Bins)) +
  geom_boxplot() +
  labs(title="Number of Cars Owned", 
       subtitle="Impact of car ownership on spending habits",
       x = "Number of Cars Owned") +
  scale_fill_manual('BikeBuyer', 
                    values = c('#E41A1C','#377EB8'),
                    labels = c('No','Yes'),
                    guide = F) +
  custom_theme()

# AvgMonthSpend by Gender
f <- ggplot(df, aes(Gender, AvgMonthSpend, fill = Gender)) +
  geom_boxplot() +
  labs(title= "Gender", 
       subtitle="Impact of gender on customer spending habits") +
  scale_fill_manual('BikeBuyer', 
                    values = c('#E41A1C','#377EB8'),
                    labels = c('No','Yes'),
                    guide = F) +
  custom_theme()

# AvgMonthSpend by NumberChildrenAtHome
g <- ggplot(df, aes(Child_Bins, AvgMonthSpend, fill = Child_Bins)) +
  geom_boxplot() +
  labs(title= "Number of Children at Home", 
       subtitle="Impact of children at home on customer spending habits",
       x = "Children at Home") +
  scale_fill_manual('BikeBuyer', 
                    values = c('#E41A1C','#377EB8'),
                    labels = c('No','Yes'),
                    guide = F) +
  custom_theme()

# AvgMonthSpend grid
grid.arrange(d,e,f,g, ncol = 2, nrow = 2, 
             top=textGrob("Average Monthly Spend Plots \n", 
                          gp=gpar(fontsize=24,
                                  fontfamily='Roboto',
                                  fontface = 'bold')))


# BIKE BUYER GRID ---------------------------------------------------------

# number of cars owned by bike buyers
h <- ggplot(df, aes(Car_Bins, fill = factor(BikeBuyer))) +
  geom_bar(position = 'dodge') +
  labs(title = "Number of Cars Owned", 
       subtitle = "Families with 2 cars are more likely to purchase bicycles",
       x = "Number of Cars Owned",
       y = "Count") +
  scale_fill_manual('BikeBuyer', 
                    values = c('#E41A1C','#377EB8'),
                    labels = c('No','Yes'),
                    guide = F) +
  custom_theme()

# occupation by bike buyers
i <- ggplot(df, aes(reorder(Occupation,Occupation, function(x)-length(x)), fill = factor(BikeBuyer))) +
  geom_bar(position = 'dodge') +
  labs(title = "Occupation", 
       subtitle = "Manual labor positions are less likely to purchase bicycles",
       x = "Occupation",
       y = "Count") +
  scale_fill_manual('BikeBuyer', 
                    values = c('#E41A1C','#377EB8'),
                    labels = c('No','Yes'),
                    guide = F) +
  custom_theme()

# gender by bike buyers
j <- ggplot(df, aes(Gender, fill = factor(BikeBuyer))) +
  geom_bar(position = 'dodge') +
  labs(title = "Gender", 
       subtitle = "Males are more likely to purchase bicycles",
       x = "Gender",
       y = "Count") +
  scale_fill_manual('BikeBuyer', 
                    values = c('#E41A1C','#377EB8'),
                    labels = c('No','Yes'),
                    guide = F) +
  custom_theme()

# marital status by bike buyers
k <- ggplot(df, aes(MaritalStatus, fill = factor(BikeBuyer))) +
  geom_bar(position = 'dodge') +
  labs(title = "Marital Status", 
       subtitle = "Customers who are married are more lilely to purchase bicycles",
       x = "Marital Status",
       y = "Count") +
  scale_fill_manual('BikeBuyer', 
                    values = c('#E41A1C','#377EB8'),
                    labels = c('No','Yes'),
                    guide = F) +
  custom_theme()

# BikeBuyer grid
grid.arrange(h,i,j,k, ncol = 2, nrow = 2, 
             top=textGrob("Bike Buyer Plots \n", 
                          gp=gpar(fontsize=24,
                                  fontfamily='Roboto',
                                  fontface = 'bold')))



# ADDITIONAL PLOTS --------------------------------------------------------


# adjust order of Age_Bin factor
df$Age_Bin <- factor(df$Age_Bin, levels = c('Under 18',
                                            '19 to 25',
                                            '26 to 29',
                                            '30 to 50',
                                            'Over 50'))

# boxplots of Average Monthly Spend by age and gender
k <- ggplot(df, aes(YearlyIncome, AvgMonthSpend, color = Gender)) + 
  geom_point() +
  labs(title="Average Spend by Income and Gender", 
       subtitle="There is a subset of males bewteen the ages of 30 and 50 who spend more on average each month as yearly income increases",
       x = "Yearly Income",
       y = "Average Monthly Spend") +
  scale_color_manual('Gender', 
                     values = c('#3A86FF','#FF006E'),
                     labels = c('M','F')) +
  custom_theme()


# binned by age group
k + facet_grid(. ~ Age_Bin)



# MODELING ----------------------------------------------------------------

# libraries for modeling
pacman::p_load(caret, randomForest, formattable, ROCR)

# TRAIN/TEST SPLIT --------------------------------------------------------

# select columns of interest
df <- df %>%
  select(BikeBuyer, AvgMonthSpend, Gender, Age_Bin, YearlyIncome, Occupation,
         MaritalStatus, NumberCarsOwned, Age, NumberChildrenAtHome, TotalChildren)


# split index
set.seed(123)
index <- createDataPartition(df$BikeBuyer, p = .8, 
                             list = FALSE, 
                             times = 1)

# split data into training and testing sets
train <- df[index,]
test <- df[-index,]

# CLASSIFICATION ----------------------------------------------------------

# create model
rf.model <- randomForest(BikeBuyer ~ Gender + Age_Bin + YearlyIncome + 
                           Occupation + MaritalStatus + NumberCarsOwned + Age + 
                           NumberChildrenAtHome + TotalChildren,
                         data = train,
                         importance = T,
                         ntree = 1000,
                         mtry = 3)

# make predictions using test data
rf.predict <- predict(rf.model, newdata = test, type = 'response')



# append to test df
formattable(head(data.frame(test, rf.predict)), 
            list(rf.predict = formatter("span",
                                        style = x ~ style(color = ifelse( x == 1, "green", "gray")))))



#  RF FEATURE IMPORTANCE --------------------------------------------------


# extract importance to data frame  
importance <- as.data.frame(rf.model$importance)
importance <- rownames_to_column(importance, var = 'Feature')

# MeanDecreaseAccuracy
mda <- ggplot(importance, 
              aes(reorder(Feature,MeanDecreaseAccuracy), MeanDecreaseAccuracy)) +
  geom_point(stat = 'identity') +
  geom_point(col="tomato2", size=3) +   # Draw points
  geom_segment(aes(x=Feature, 
                   xend=Feature, 
                   y=min(MeanDecreaseAccuracy), 
                   yend=max(MeanDecreaseAccuracy)), 
               linetype="dashed", 
               size=0.1) +
  labs(x='Feature',
       y='Mean Decrease in Accuracy') +
  coord_flip() +
  theme_classic(base_family = 'Roboto Condensed', base_size = 12)

# MeanDecreaseGini
mdg <- ggplot(importance, 
              aes(reorder(Feature,MeanDecreaseGini), MeanDecreaseGini)) +
  geom_point(stat = 'identity') +
  geom_point(col="tomato2", size=3) +   # Draw points
  geom_segment(aes(x=Feature, 
                   xend=Feature, 
                   y=min(MeanDecreaseGini), 
                   yend=max(MeanDecreaseGini)), 
               linetype="dashed", 
               size=0.1) +
  coord_flip() +
  labs(x='Feature',
       y='Mean Decrease in Gini') +
  theme_classic(base_family = 'Roboto Condensed', base_size = 12)

# create plot grid
grid.arrange(mda,mdg,ncol=2, 
             top=textGrob("Feature Importance \n", 
                          gp=gpar(fontsize=24,
                                  fontfamily='Roboto', 
                                  fontface='bold')))

# RF EVALUATION -----------------------------------------------------------

# calculate misclassification error
misClasificError <- mean(rf.predict != test$BikeBuyer)
print(paste('Accuracy:',percent(1-misClasificError, 2)))

#confusion matrix
cm <- table(test$BikeBuyer, rf.predict == 1)
formattable(as.data.frame.matrix(cm))

kable(cm, "html") %>%
  kable_styling(bootstrap_options = "striped", full_width = F)

# 
library(formattable)
mtcars[1:5, 1:4] %>%
  mutate(
    car = row.names(.),
    mpg = color_tile("white", "orange")(mpg),
    cyl = cell_spec(cyl, "html", angle = (1:5)*60, 
                    background = "red", color = "white", align = "center"),
    disp = ifelse(disp > 200,
                  cell_spec(disp, "html", color = "red", bold = T),
                  cell_spec(disp, "html", color = "green", italic = T)),
    hp = color_bar("lightgreen")(hp)
  ) %>%
  select(car, everything()) %>%
  kable("html", escape = F) %>%
  kable_styling("hover", full_width = F) %>%
  column_spec(5, width = "3cm") %>%
  add_header_above(c(" ", "Hello" = 2, "World" = 2))


# custom plot -- OVERRIDES MARGIN ISSUE
custom <- list(
  theme(plot.title=element_text(size=24,
                                face='bold',
                                family='Roboto Condensed Bold',
                                lineheight=1,
                                hjust=0),
        plot.subtitle = element_text(size=12,
                                     family='Roboto Condensed',
                                     hjust=0),
        plot.caption = element_text(size=8,
                                    face='italic',
                                    hjust=1))
)


# RF ROC CURVE ------------------------------------------------------------


# assess model performance
predict <- predict(rf.model, newdata=test, type='prob')[,2]
predictions <- as.vector(predict)
pred <- prediction(predictions, test$BikeBuyer)
perf <- performance(pred, measure = 'tpr', x.measure = 'fpr')

# extract auc
auc <- performance(pred, measure = 'auc')
auc <- auc@y.values[[1]]

# create a dataframe of roc data
roc.data.rf <- data.frame(fpr=unlist(perf@x.values),
                          tpr=unlist(perf@y.values),
                          model='Random Forest')

# roc curve
rf.roc <- ggplot(roc.data.rf, aes(x=fpr, ymin=0, ymax=tpr)) +
  geom_ribbon(alpha=0.2) +
  geom_line(aes(y=tpr)) +
  geom_abline(intercept = 0, slope = 1, linetype = 'dashed', alpha = 0.5) +
  labs(title = paste0('ROC Curve w/ AUC = ', percent(auc,2)), 
       x = 'False Positive Rate (1-Specificity)', 
       y = 'True Positive Rate (Sensitivity)') +
  theme_classic(base_family = 'Roboto Condensed', base_size = 12)

rf.roc + custom


# REGRESSION --------------------------------------------------------------

### Regression - Linear Regression


# linear regression
lm.model <- lm(AvgMonthSpend ~ Occupation + Gender + MaritalStatus + 
                 NumberChildrenAtHome + TotalChildren + YearlyIncome + Age + 
                 Age_Bin,
               data = train)

# summarize lm model
summary(lm.model)


pred.lm.model <- predict(lm.model, test)

# RMSE
RMSE.lm.model <- sqrt(mean((pred.lm.model - test$AvgMonthSpend)^2))

# MAE
MAE.lm.model <- mean(abs(pred.lm.model - test$AvgMonthSpend))

test$scored_labels <- predict(lm.model, test)

df %>%
  group_by(BikeBuyer) %>%
  summarise(sum = n())
