library(caret)    

titanic_train <- read.csv("./titanic/train.csv")

titanic_train$Pclass <- ordered(titanic_train$Pclass,     # Convert to ordered factor
                                levels=c("3","2","1"))  

impute <- preProcess(titanic_train[,c(6:8,10)],  # Impute missing ages
                     method=c("knnImpute"))

titanic_train_imp <- predict(impute, titanic_train[,c(6:8,10)])

titanic_train <- cbind(titanic_train[,-c(6:8,10)], titanic_train_imp)

# -----------------------------------------

library(rpart)
library(rpart.plot)

# options basically modify how rstudio displays certain stuff
options(repr.plot.width = 6, repr.plot.height = 5)

gender_tree <- rpart(Survived ~ Sex,              # Predict survival based on gender
                     data = titanic_train)        # Use the titanic training data

prp(gender_tree,      # Plot the decision tree
    space=4,          # (Formatting options chosen for notebook)
    split.cex = 1.5,
    nn.border.col=0)

# ----------------------------------------- More than one feature

class_tree <- rpart(Survived ~ Sex + Pclass,    # Predict survival based on gender
                    data = titanic_train)       # Use the titanic training data

prp(class_tree,      # Plot the decision tree
    space=4,          # (Formatting options chosen for notebook)
    split.cex = 1.2,
    nn.border.col=0)

# ----------------------------------------- More features!

complex_tree <- rpart(Survived ~ Sex + Pclass + Age + SibSp + Fare + Embarked,
                      cp = 0.001,                 # Set complexity parameter*
                      data = titanic_train)       # Use the titanic training data

options(repr.plot.width = 8, repr.plot.height = 8)

prp(complex_tree, 
    type = 1,
    nn.border.col=0, 
    border.col=1, 
    cex=0.4)

# ----------------------------------------- Limited complexity

limited_complexity_tree <- rpart(Survived ~ Sex + Pclass + Age + SibSp +Fare+Embarked,
                                 cp = 0.001,              # Set complexity parameter
                                 maxdepth = 5,            # Set maximum tree depth
                                 minbucket = 5,           # Set min number of obs in leaf nodes
                                 method = "class",        # Return classifications instead of probs
                                 data = titanic_train)    # Use the titanic training data

options(repr.plot.width = 6, repr.plot.height = 6)

prp(limited_complexity_tree,
    space=4,          
    split.cex = 1.2,
    nn.border.col=0)

# ----------------------------------------- Predicting on test data
titanic_test <- read.csv("./titanic/test.csv")

titanic_test$Pclass <- ordered(titanic_test$Pclass,     # Convert to ordered factor
                               levels=c("3","2","1"))  

# Impute missing test set ages using the previously constructed imputation model
titanic_test_imp <- predict(impute, titanic_test[,c(5:7,9)])

titanic_test <- cbind(titanic_test[,-c(5:7,9)], titanic_test_imp)

test_preds <- predict(limited_complexity_tree,              
                      newdata=titanic_test,      
                      type="class") 
prediction_sub <- data.frame(PassengerId=titanic_test$PassengerId, Gender=titanic_test$Sex, Pclass=titanic_test$Pclass, Survived=test_preds)
prediction_sub_sorted <- prediction_sub[order(prediction_sub$Pclass, decreasing=TRUE), ]
head(prediction_sub)
head(prediction_sub_sorted)

# ----------------------------------------- Splitting data set into validation set (Holdout validation and Cross validation)
# AKA Holdout validation
set.seed(12)
split_model <- createDataPartition(y=titanic_train$Survived,    # Split on survived
                                   list = FALSE,      # Return indexes as a vector
                                   p=0.75,            # 75% of data in the training set
                                   times=1)           # Make 1 split
training_set <- titanic_train[split_model,]     # Get the new training set
validation_set <- titanic_train[-split_model,]  # Get the validation set

nrow(training_set)/nrow(titanic_train)      # Check proportion in each partition
nrow(validation_set)/nrow(titanic_train)

holdout_limited_complexity_tree <- rpart(Survived ~ Sex + Pclass + Age + SibSp +Fare+Embarked,
                                 cp = 0.001,              # Set complexity parameter
                                 maxdepth = 5,            # Set maximum tree depth
                                 minbucket = 5,           # Set min number of obs in leaf nodes
                                 method = "class",        # Return classifications instead of probs
                                 data = training_set)    # Use the titanic training data

options(repr.plot.width = 6, repr.plot.height = 6)

prp(holdout_limited_complexity_tree,
    space=4,          
    split.cex = 1.2,
    nn.border.col=0)

validation_preds <- predict(holdout_limited_complexity_tree, newdata=validation_set, type="class")
accuracy <- sum(validation_preds == validation_set$Survived) / nrow(validation_set) * 100
cat("Dtree Accuracy:", round(accuracy, 2), "%\n")
validation_preds == validation_set$Survived
