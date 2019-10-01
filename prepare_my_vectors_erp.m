function [RESULTS] =  prepare_my_vectors_erp(training_set, test_set, cfg)
%
% This function gets input from decoding_erp.m and organises the data stored in 
% training_set and test_set for classification. The data is extracted and handed 
% over to do_my_classification.m as data vectors and labels. 
% The output is handed back to decoding_erp.
%
% Inputs:
%   
%   training_set    data used for training the classifier
%
%   test_set        data used to test classifier performance
%
%   cfg             structure containing analysis parameters
%
% Outputs:
%
%   RESULTS         structure containing the decoding results
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


%% Define Number of Steps / Analysis Time Windows
% Default = all possible steps)
% only needs to be changed for de-bugging!

allsteps = 1; % (1=all possible steps; 0=pre-defined number of steps) 
% defined_steps=6;

% number of rounds: will be 1 if no permutation test;
nr_rounds = 1 + cfg.perm_test;


%% Establish Number of Analyses / Classes
% number analyses depends whether analysis is performed for each channel
% separately or for spatial configuration
if cfg.stmode ~= 2 % Spatial or spatiotemporal decoding
    
    no_analyses = 1;
    
elseif cfg.stmode == 2 % Temporal decoding
    
    no_analyses = size(training_set{1,1,1,1}, 2);
    
end % of if cfg.stmode


%% Load In Regression Labels (For SVR)

if cfg.analysis_mode == 3 % If performing SVR
    
    training_labels = cfg.training_labels;
    test_labels = cfg.test_labels;
    
end % of if cfg.analysis_mode


%% Prepare Results Matrices and Define Analysis Repetitions

RESULTS.prediction_accuracy = [];
RESULTS.feature_weights = [];
RESULTS.perm_prediction_accuracy = [];

% Set up matrix with repetition information 
repetition_data_steps = repmat([1:size(test_set,3)], 1, cfg.permut_rep);

crossval_repetitions(1, 1) = size(test_set, 4); % repetition of cross_validation cycle for real decoding

if cfg.avmode ~= 2 % repetition of cross_validation cycle for permutation test
    
    crossval_repetitions(2, 1) = cfg.permut_rep; 
    
elseif cfg.avmode == 2
    
   crossval_repetitions(2, 1) = crossval_repetitions(1, 1);
   
end % of if cfg.avmode


%% Perform Vector Preparation and Hand Over to Classification Script

for main_analysis = 1:nr_rounds % 1=real decoding, 2=permutation test

    trial_length = size(training_set{1,1,1,1}, 1); % use first one to determine trial length - all identical
        
    if allsteps == 1 % Analyse all steps
        
        nsteps = floor((trial_length - (cfg.window_width - cfg.step_width)) / cfg.step_width);   
        
    elseif allsteps == 0 % Analyse a predefined number of steps 
        
        nsteps = defined_steps;
        
    end % of if allsteps
                
    for rep = 1:crossval_repetitions(main_analysis, 1) % repetition of cross_validation cycle    
            
        for cv = 1:size(test_set, 3) % cross-validation step
        
            for ch = 1:no_analyses % repetition for each channel (if required)
                              
                for s = 1:nsteps
                
                    vectors_train = [];
                    vectors_test = [];
                    labels_train = [];
                    labels_test = [];
               
                    for con = 1:size(test_set, 2) % condition 
                    
                        % get correct data position from matrix
                        ncv = repetition_data_steps(rep);
                        
                        if cfg.cross == 0 % regular: train on A, predict left-out from A
                        
                            % extract training and test data for current step for time window
                            data_training = double(training_set{1,con,cv,ncv}( (1 + ( (s - 1) * cfg.step_width)):( (s * cfg.window_width) - ( (s - 1) * (cfg.window_width-cfg.step_width) ) ),:,:));
                            data_test = double(test_set{1,con,cv,ncv}((1 + ( (s - 1) * cfg.step_width) ):( (s * cfg.window_width) - ( (s - 1) * (cfg.window_width-cfg.step_width) ) ),:,:));
                                                
                        elseif cfg.cross == 1 % train on A, predict left-out from B
                            
                         % extract training and test data for current step for time window
                            data_training = double(training_set{1,con,cv,ncv}((1 + ( (s - 1) * cfg.step_width) ):( (s * cfg.window_width) - ( (s - 1) * (cfg.window_width-cfg.step_width) ) ),:,:));
                            data_test = double(test_set{2,con,cv,ncv}((1 + ( (s - 1) * cfg.step_width) ):( (s * cfg.window_width) - ( (s - 1) * (cfg.window_width-cfg.step_width) ) ),:,:));
                        
                        end % of if cfg.cross
                        
                        % spatial decoding: vectors consist of average data within time-window
                        % calculate number of steps with given step width and window width one data point per channel
                        if cfg.stmode == 1
         
                            % Training data vectors
                            mean_data_training = mean(data_training, 1);
                            mean_data_test = mean(data_test, 1);
                        
                            temp(:,:) = mean_data_training(1,:,:);
                            vectors_train = [vectors_train, temp];     
                            
                            %________________________________________________________________________________
                            if cfg.analysis_mode == 3 % if SVR
                                    
                                for trl = 1:size(temp, 2)
                                    labels_train = [labels_train, training_labels{1,con,cv,ncv}(trl)];
                                end
                            
                            else % if not SVR
                                
                                for ntrls = 1:(size(temp, 2))
                                    labels_train = [labels_train, con];
                                end
                                
                            end % of if cfg.analysis_mode
                            
                            clear temp;
                            %________________________________________________________________________________
                            
                            % permutation test data
                            if main_analysis == 2
                                
                                % generate new labels from old labels!!!!!!
                                perm_order = randperm(size(labels_train, 2));
                                for no = 1:size(labels_train, 2)
                                    new_labels_train(1, no) = labels_train(1, perm_order(no));
                                end % of for no
                                clear labels_train;
                                labels_train = new_labels_train;
                                clear new_labels_train;
                                
                            end % of if main_analysis
                            
                            %_________________________________________________________________________________
                        
                            % Test data vectors
                            temp(:,:) = mean_data_test(1,:,:);
                            vectors_test = [vectors_test, temp];     
                            
                            %________________________________________________________________________________
                            if cfg.analysis_mode == 3 % if SVR
                                    
                                for trl = 1:size(temp, 2)
                                    labels_test = [labels_test, test_labels{1,con,cv,ncv}(trl)];
                                end % of for trl
                                
                            else % if not SVR
                                
                                for ntrls = 1:(size(temp, 2))
                                    
                                    labels_test = [labels_test, con];
                                    
                                end % of for ntrls 
                                                          
                            end % of if cfg.analysis_mode
                            
                            clear temp;
                            %________________________________________________________________________________
                        
                        % temporal decoding: vectors consist of single data-points within time
                        % window, one analysis per channel
                        elseif cfg.stmode == 2

                            % Training data vectors
                            for exmpl = 1:size(data_training, 3)  
                                
                                temp = data_training(:, ch, exmpl);
                                vectors_train = [vectors_train, temp];
                                
                                %________________________________________________________________________________
                                if cfg.analysis_mode == 3 % if SVR
                                        
                                    labels_train = [labels_train, training_labels{1,con,cv,ncv}(exmpl)];
                                      
                                else % if not SVR
                                    
                                    labels_train = [labels_train, con];
                                    
                                end % of if cfg.analysis_mode
                                
                                clear temp;
                                %________________________________________________________________________________
                                
                            end % of for exmpl
                            
                            % permutation test data
                            %_________________________________________________________________________________
                            if main_analysis == 2
                                
                                % generate new labels from old labels
                                perm_order = randperm(size(labels_train, 2));
                                
                                for no = 1:size(labels_train, 2)
                                    
                                    new_labels_train(1, no) = labels_train(1, perm_order(no));
                                    
                                end % of for no
                                
                                clear labels_train;
                                labels_train = new_labels_train;
                                clear new_labels_train;
                                
                            end % of if main_analysis
                            %_________________________________________________________________________________
       
                            % Test data vectors
                            for exmpl = 1:size(data_test, 3)
                                
                                temp = data_test(:, ch, exmpl);
                                vectors_test = [vectors_test, temp];
                                
                                %________________________________________________________________________________
                                if cfg.analysis_mode == 3 % if SVR
                                        
                                    for ntrls = 1:size(temp, 2)
                                        
                                        labels_test = [labels_test, test_labels{1,con,cv,ncv}(exmpl)];
                                        
                                    end % of for ntrls
                                      
                                else % if not SVR
                                    
                                    labels_test = [labels_test, con];
                                    
                                end % of if cfg.analysis_mode
                                
                                clear temp;
                                %________________________________________________________________________________
                                
                            end % of for exmpl 
    
                        % spatio-temporal decoding: vectors consist of all data points within time
                        % window across channels
                        elseif cfg.stmode == 3  
            
                            % channels used within each step / only one analysis!
                            
                            % Training data vectors
                            for exmpl = 1:size(data_training, 3) 
                                
                                temp = [];
                                
                                for chann = 1:size(data_training, 2)  
                                    
                                    scrap = data_training(:, chann, exmpl);
                                    temp = cat(1, temp, scrap);
                                    clear scrap;               
                                    
                                end % of for chann
                                
                                vectors_train = [vectors_train, temp];
                                clear temp;
                                
                                %________________________________________________________________________________
                                if cfg.analysis_mode == 3 % if SVR
                                        
                                    labels_train = [labels_train, training_labels{1,con,cv,ncv}(exmpl)];
                                  
                                else % if not SVR
                                    
                                    labels_train = [labels_train con];
                                    
                                end % of if cfg.analysis_mode
                                %________________________________________________________________________________
                                
                            end % of for exmpl
                            
                            % permutation test data
                            %_________________________________________________________________________________
                            
                            if main_analysis == 2
                                
                                % generate new labels from old labels
                                perm_order = randperm(size(labels_train, 2));
                                
                                for no = 1:size(labels_train, 2)
                                    
                                    new_labels_train(1, no) = labels_train(1, perm_order(no));
                                    
                                end % of for no
                                
                                clear labels_train;
                                labels_train = new_labels_train;
                                clear new_labels_train;
                                
                            end % of if main_analysis
                            %_________________________________________________________________________________
       
                            % Test data vectors
                            for exmpl = 1:size(data_test, 3)
                                
                                temp = [];
                                
                                for chann = 1:size(data_test, 2)
                                    
                                    scrap = data_test(:, chann, exmpl);
                                    temp = cat(1,temp, scrap);
                                    clear scrap
                                    
                                end % of for chann
                                
                                vectors_test = [vectors_test, temp];
                                clear temp;
                                
                                %________________________________________________________________________________
                                if cfg.analysis_mode == 3 % if SVR
                                        
                                    labels_test = [labels_test, test_labels{1,con,cv,ncv}(exmpl)];
                                      
                                else % if not SVR
                                    
                                    labels_test = [labels_test, con];
                                    
                                    
                                end % of if cfg.analysis_mode
                                %________________________________________________________________________________
                                
                            end % of for exmpl 
                                                            
                        end % of if stmode
  
                    end % of for con
                    
                    %_________________________________________________________________________________
                    % Z-score the training and test sets (optional)
                                        
                    if cfg.zscore_convert == 1
                        
                        switch cfg.stmode
                            
                            case 1 % spatial decoding
                                % Organisation of vectors:
                                % vectors_train(channel, epoch)
                                % vectors_test(channel, epoch)
                                
                                vectors_train = zscore(vectors_train);
                                vectors_test = zscore(vectors_test);
                               
                            case 2 % temporal decoding
                                % Organisation of vectors:
                                % vectors_train(timepoint, epoch)
                                % vectors_test(timepoint, epoch)
                                
                                vectors_train = zscore(vectors_train);
                                vectors_test = zscore(vectors_test);
                            
                            case 3 % spatio-temporal decoding
                                % Organisation of vectors:
                                % vectors_train(channel/timept combination, epoch)
                                % vectors_test(channel/timept combination, epoch)
                                
                                % Training Vectors
                                tmp = zscore( reshape(vectors_train, ...
                                    size(data_training, 1), size(data_training, 2), size(vectors_train, 2)) );
                                vectors_train = reshape(tmp, size(data_training, 1) * size(data_training,2), size(vectors_train, 2));

                                % Test Vectors
                                tmp = zscore( reshape(vectors_test, ...
                                    size(data_test, 1), size(data_test, 2), size(vectors_test, 2)) );
                                vectors_test = reshape(tmp, size(data_test, 1) * size(data_test,2), size(vectors_test, 2));

                        end % of if cfg.stmode
                    end % of if cfg.zscore_convert

                    
                    % Pass data on to the classifier
                    %
                    % Data is sorted into vectors_test, vectors_train, labels_test, labels_train. Based on analysis_mode,
                    % the appropriate classifier is chosen for the pattern analysis
                    % 
                    % each analysis-step will fill the results matrices: 
                    % *** prediction_accuracy{analysis}(time-step, crossvalidation-step, repetition-step)
                    % *** perm_prediction_accuracy{analysis}(time-step, crossvalidation-step, repetition-step)
                    % *** feature_weights{analysis}(time-step, crossvalidation-step, repetition-step)
                    %______________________________________________________
                    
                    vectors_train = vectors_train';
                    vectors_test = vectors_test';
                    labels_train = labels_train';
                    labels_test = labels_test';
                
                    if main_analysis == 1 % Actual decoding analyses
                        
                        fprintf('Classifying step %d of %d steps, cross-validation step %d in cycle %d: \n', s, nsteps, cv, rep);
                        
                    elseif main_analysis == 2 % Permuted labels decoding analyses
                        
                        fprintf('Permutation test step %d of %d steps, cross-validation step %d in cycle %d: \n', s, nsteps, cv, rep);
                        
                    end % of if main_analysis
                    
                    % Train and test the classifier
                    [acc,feat_weights, feat_weights_corrected] = do_my_classification(vectors_train, labels_train, vectors_test, labels_test, cfg);
                
                    % Store decoding results
                    if main_analysis == 1
                        
                        RESULTS.prediction_accuracy{ch}(s, cv, rep) = acc;
                        RESULTS.feature_weights{ch}{s, cv, rep} = feat_weights;
                        RESULTS.feature_weights_corrected{ch}{s , cv, rep} = feat_weights_corrected;
                        
                    elseif main_analysis == 2
                        
                        RESULTS.perm_prediction_accuracy{ch}(s, cv, repetition_data_steps(rep)) = acc; 
                        
                    end % of if main_analysis
                        
                    clear acc;
                    clear feat_weights;
                    clear feat_weights_corrected;
                    
                end % of for s (steps / analysis time windows)
                    
            end % of for ch (number analyses / channels)
                
        end % of for cv (cross-validation step)
            
    end % repetition of cross_validation rounds
    fprintf('\nFinished classification. \n');  
    
end % of for main_analysis (real decoding vs permutation test data)   