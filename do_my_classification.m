function [acc, feat_weights, feat_weights_corrected] = do_my_classification(vectors_train, labels_train, vectors_test, labels_test, cfg)
%
% Performs multivariate pattern classification/regression using input
% vectors of training/test data and condition labels. Feature weights from
% the SVM training dataset are also extracted if requested by the user.
%
% This function is called by prepare_my_vectors_erp
%
% This script interacts with either LIBSVM toolbox (Chang & Lin) or 
% LIBLINEAR (Fan et al.) to do the classfication / regression
%
% for LIBSVM see: https://www.csie.ntu.edu.tw/~cjlin/libsvm/
% Chang CC, Lin CJ (2011). LIBSVM : a library for support vector machines. ACM TIST, 2(3):27,
%
% for LIBLINEAR see: https://www.csie.ntu.edu.tw/~cjlin/liblinear/
% R.-E. Fan, K.-W. Chang, C.-J. Hsieh, X.-R. Wang, and C.-J. Lin. 
% LIBLINEAR: A library for large linear classification. 
% Journal of Machine Learning Research 9(2008), 1871--1874.
% 
% Feature weights extraction:
% Both corrected and uncorrected feature weights are extracted and stored.
% Uncorrected feature weights are directly obtained from the SVM training
% functions. Corrected feature weights undergo an additional transformation
% as described in Haufe et al. (2014). Please cite their paper when using
% corrected feature weights in your analyses.
% 
% Haufe, S., Meinecke, F., Gorgen, K., Dahne, S., Haynes, J-D., Blankertz,
% B., & Bieﬂmann, F. (2014). On the interpretation of weight vectors in
% linear models in multivariate neuroimaging. Neuroimage (87), 96-110.
%
% 
% Inputs:
%
%   vectors_train   data vectors that make up the training dataset
%
%   labels_train    condition labels for the training dataset
%
%   vectors_test    data vectors that make up the test dataset
%
%   labels_test     condition labels for the test dataset
%
%   cfg           structure containing multivariate classification/regression settings
% 
%
% Outputs:
%
%   acc             classifier accuracy for classification of the test data
%
%   feat_weights    feature weights from the classifier
%
%   feat_weights_corrected      feature weights corrected according to the
%                               method in Haufe et al. (2014).
%
%
% Copyright (c) 2013-2019: DDTBOX has been developed by Stefan Bode 
% and Daniel Feuerriegel with contributions from Daniel Bennett and 
% Phillip M. Alday. 
%
% This file is part of DDTBOX and has been written by Stefan Bode
%
% DDTBOX is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

%% Define Samples and Labels For Training

Samples = vectors_train;
Labels = labels_train;


%% Training the SVMs

if sum(cfg.analysis_mode == [1 3 4]) %  libsvm
    
    model = svmtrain(Labels, Samples, cfg.backend_flags.all_flags);
    
elseif sum(cfg.analysis_mode == [2]) %  liblinear
    
   model = train(Labels, sparse(Samples), cfg.backend_flags.all_flags);
   
end % of if sum
%__________________________________________________________________________    


%% Define Samples and Labels for Testing
Samples = vectors_test;
Labels = labels_test;


%% Prediction (Test the Classifier)

if sum(cfg.analysis_mode == [1, 3]) % libsvm
    
    [predicted_label, accuracy, decision_values] = svmpredict(Labels, Samples, model);
    
elseif sum(cfg.analysis_mode == [2]) % liblinear
    
    [predicted_label, accuracy, decision_values] = predict(Labels, sparse(Samples), model); 
    
end % of if sum

%% Calculate Decoding Performance and Extract Feature Weights

if cfg.analysis_mode == 1 % SVM classification with LIBSVM
    
    % calculating feature weights
    w = model.SVs' * model.sv_coef;
    b = -model.rho;

    feat_weights = zeros(size(w,1), 3);
    feat_weights_corrected = zeros(size(w,1), 3);
    
    if cfg.feat_weights_mode == 1 % If extracting feature weights
        
        % uncorrected feature weights
        feat_weights(:,1) = 1:(size(w, 1));
        feat_weights(:,2) = w;
        feat_weights(:,3) = abs(w);
        
        % corrected feature weights according to Haufe et al. (2014) method
        feat_weights_corrected(:,1) = 1:(size(w, 1));
        vectors_train_temp = (vectors_train - repmat(mean(vectors_train), size(vectors_train, 1), 1)) ./ sqrt(size(vectors_train, 1) - 1);
        feat_weights_corrected(:,2) = vectors_train_temp' * (vectors_train_temp * feat_weights(:,2));
        clear vectors_train_temp;
        feat_weights_corrected(:,3) = abs(feat_weights_corrected(:,2));
        
    end % of if cfg.feat_weights_mode
    

    % calculate classification accuracy for 2-classes 
    if cfg.nconds == 2

        acc = accuracy(1);

    % extracting accuracy for N-classes
    elseif cfg.nconds > 2

        % Generate all pairs of conditions
        classes = 1:cfg.nconds;
        pairs = nchoosek(classes, 2);

        for cl = classes
            
            wt(:,cl) = (pairs(:,1) == cl) - (pairs(:,2) == cl);
            
        end % of for cl

        % Calculate the winning class out of all classes
        votes = decision_values * wt;
        [maxvote, winvote] = max(votes');
        
        % Accuracy defined as the proportion of test labels that equal the
        % winning class
        classcorrectness = (labels_test == winvote') * 100;
        acc = mean(classcorrectness);

    end % of if cfg.nconds
    
elseif cfg.analysis_mode == 2 % SVM classification with LIBLINEAR
    
    % calculating feature weights
    w = model.w';

    feat_weights = zeros(size(w,1), 3);
    feat_weights_corrected = zeros(size(w,1), 3);
    
    if cfg.feat_weights_mode == 1 % If extracting feature weights
        
        % uncorrected feature weights
        feat_weights(:,1) = 1:(size(w,1));
        feat_weights(:,2) = w;
        feat_weights(:,3) = abs(w);
        
        % corrected feature weights according to Haufe et al. (2014) method
        feat_weights_corrected(:,1) = 1:(size(w,1));
        vectors_train_temp = (vectors_train - repmat(mean(vectors_train), size(vectors_train, 1), 1)) ./ sqrt(size(vectors_train, 1) - 1);
        feat_weights_corrected(:,2) = vectors_train_temp' * (vectors_train_temp * feat_weights(:,2));
        clear vectors_train_temp;
        feat_weights_corrected(:,3) = abs(feat_weights_corrected(:,2));
    
    end % of if cfg.feat_weights_mode

    % extracting accuracy for 2-classes 
    if cfg.nconds == 2

        acc = accuracy(1);
    
    % extracting accuracy for N-classes
    elseif cfg.nconds > 2

        classes = 1:cfg.nconds;
        pairs = nchoosek(classes, 2);

        for cl = classes
            wt(:,cl) = (pairs(:,1) == cl) - (pairs(:,2) == cl);
        end % of for cl

        votes = decision_values * wt;
        [maxvote, winvote] = max(votes');
        classcorrectness = (classes == winvote) * 100;

        acc = mean(classcorrectness);

    end % of if cfg.nconds
       
elseif cfg.analysis_mode == 3 % SVR
    
    % correlating the predicted label with the test labels
    c_sample = corrcoef(predicted_label, Labels);
    avecorrectness = c_sample(1,2);
    
    % convert into Fisher-Z
    correctness_z = 1/2 * log((1 + avecorrectness) ./ (1 - avecorrectness));
    avecorrectness = mean(correctness_z);
    
    % optional: transform back
    % avecorrectness = (exp(2 * avecorrectness) - 1) ./ (exp(2 * avecorrectness) + 1);
    
    acc = avecorrectness;
    
    % calculating feature weights
    w = model.SVs' * model.sv_coef;
    feat_weights = zeros(size(w,1), 3);  
    feat_weights_corrected = zeros(size(w,1), 3);
    
    if cfg.feat_weights_mode == 1 % If extracting feature weights
        
        % uncorrected feature weights
        feat_weights(:,1) = 1:(size(w,1));
        feat_weights(:,2) = w;
        feat_weights(:,3) = abs(w);
        
        % corrected feature weights according to Haufe et al. (2014) method
        feat_weights_corrected(:,1) = 1:(size(w,1));
        vectors_train_temp = (vectors_train - repmat(mean(vectors_train), size(vectors_train, 1), 1)) ./ sqrt(size(vectors_train, 1) - 1);
        feat_weights_corrected(:,2) = vectors_train_temp' * (vectors_train_temp * feat_weights(:,2));
        clear vectors_train_temp;
        feat_weights_corrected(:,3) = abs(feat_weights_corrected(:,2));
        
    end % of if cfg.feat_weights_mode
    
end % if cfg.analysis_mode
