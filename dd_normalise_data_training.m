function [output_data, feature_min_vals, feature_max_vals] = dd_normalise_data_training(input_data)
%
% Normalises values within the 0-1 range for each feature. Data are
% normalised for each feature separately, and are normalised across
% instances/epochs. Minimum and maximum values computed during this
% normalisation are then saved for each feature, as these values must also
% be used to when normalising the test data. Normalisation helps run SVMs
% much faster, and SVM classification using normalised values can also be
% more accurate. See the documentation for LIBSVM for further information.
%
%
% Inputs:
%
%   input_data  This is a feature x epoch matrix used for training/test
%               the classifier or regression model. 
%
%
%
%		
% Outputs:
%
%  output_data  Normalised data produced by the function, for subsequent
%               classification or regression with SVMs
%
%  feature_min_vals     Calculated minimum values for each feature, used
%                       when consequently calculating the maximum values
%                       and normalising the data. This exact value should also
%                       be used when normalising the test dataset.
%
%
%  feature_max_vals     Calculated maximum values for each feature, used
%                       when normalising the data. This exact value should also
%                       be used when normalising the test dataset.
%
%
% Usage: [output_data, feature_min_vals, feature_max_vals] = dd_normalise_data(input_data)
%
%
% Copyright (c) 2013-2019: DDTBOX has been developed by Stefan Bode 
% and Daniel Feuerriegel with contributions from Daniel Bennett and 
% Phillip M. Alday. 
%
% This file is part of DDTBOX and has been written by Daniel Feuerriegel
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


%% Normalise the Input Data

% Normalise the data to be between 0 and 1 (results in faster SVMs with
% better performance)

% Normalise within features (across instances), and not across
% instances/trials! We will also need to save the values calculated
% during normalisation, so that they can be used to normalise the
% test set data in exactly the same way.

% Get minimum values (minimum across instances/epochs) for each feature
min_by_feature_input_data = min(input_data, [], 1);

% Subtract the minimum values from the data for each feature
% Here, bsxfun tends to be faster than repmat or a loop over features
norm_input_data = bsxfun(@minus, input_data, min_by_feature_input_data);    

% Get maximum values (maximum across instances/epochs) for each feature,
% after subtracting the minimum values for each feature
max_by_feature_input_data = max(norm_input_data, [], 1);

% Divide by the maximum values for each feature
norm_input_data = bsxfun(@rdivide, norm_input_data, max_by_feature_input_data);



%% Prepare Outputs

% Allocate normalised data to output_data matrix
output_data = norm_input_data;

% Save minimum and maximum values for normalising subsequent data matrices in
% exactly the same way
feature_min_vals = min_by_feature_input_data;
feature_max_vals = max_by_feature_input_data;


