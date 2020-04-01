function [h_yuen, p, CI, t_yuen, diff, se, tcrit, df] = yuend_ttest(cond_1_data, cond_2_data, varargin)
%
% Computes t_yuen (Yuen's T statistic) to compare the trimmed means of two
% dependent samples. Each sample needs the same number of data points.
%
% Yuen's t test was first described in Yuen, K.K. (1974). The two-sample
% trimmed t for unequal population variances. Biometrika, 61, 165-170.
%
% See also Wilcox (2012), Introduction to Robust Estimation and Hypothesis 
% Testing (3rd Edition), page 195-198 for a description of the Yuen
% procedure for dependent groups.
%
% This funciton was modified from the limo_yuend_ttest function in the LIMO Toolbox:
% Pernet, C.R., Chauveau, N., Gaspar, C. & Rousselet, G.A. 
% LIMO EEG: a toolbox for hierarchical LInear Modeling of EletroEncephaloGraphic data.
% Computational Intelligence and Neuroscience, Volume 2011 (2011), Article ID 831409, 
% 11 pages, doi:10.1155/2011/831409
% Original version copyright (C) LIMO Team 2010 under a GNU Lesser General Public License (LGPL)
% Code for this function in the LIMO toolbox can be found at: 
% https://github.com/LIMO-EEG-Toolbox/limo_eeg
%
%
% Inputs:
%
%   cond_1_data             vector of observations in group/condition 1
%
%   cond_2_data             vector of observations in group/condition 2
%
%
% Optional Keyword Inputs:
%
%   percent                 percent to trim for the trimmed mean, must be 
%                           between 0 and 50. Default = 20                          
%
%   alpha                   nominal alpha level. Default = 0.05
%
%   tail                    choices for one- or two-tailed testing. Default
%                           is two-tailed.
%                           'both' = two-tailed
%                           'right' = one-tailed test for positive differences
%                           'left' = one-tailed test for negative differences
%
%
% Outputs:
%
%   h_yuen                  Null hypothesis test result. 
%                           1 = reject / 0 = don't reject
%
%   p                       p-value
%
%   CI                      confidence interval around the difference
%
%   t_yuen.tstat            Yuen T statistic. t_yuen is distributed approximately
%                           as Student's t with estimated degrees of freedom, df.
%   diff                    difference between trimmed means of cond_1_data 
%                           and cond_2_data.
%
%   se                      standard error
%
%   tcrit                   1 - alpha / 2 quantile of the Student's t distribution 
%                           with adjusted degrees of freedom        
%
%   df                      degrees of freedom
%
%
% Example:  [h_yuen, p, CI, t_yuen, diff, se, tcrit, df] = yuend_ttest(cond_1_data, cond_2_data, 'alpha', 0.05, 'percent', 20, 'tail', 'both')
%
%
% Copyright (c) 2013-2020: DDTBOX has been developed by Stefan Bode 
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
%
%
% original version: GAR, University of Glasgow, Dec 2007
% 3D, standalone version: GAR, University of Glasgow, June 2010
% GAR fixed bug for covariance / se
%


%% Handling Variadic Inputs

% Define defaults at the beginning
options = struct(...
    'alpha', 0.05, ...
    'percent', 20, ...
    'tail', 'both');

% Read the acceptable names
option_names = fieldnames(options);

% Count arguments
n_args = length(varargin);

if round(n_args / 2) ~= n_args / 2
    
   error([mfilename ' needs property name/property value pairs'])
   
end

for pair = reshape(varargin, 2, []) % pair is {propName;propValue}
    
   inp_name = lower(pair{1}); % make case insensitive

   % Overwrite default options
   if any(strcmp(inp_name, option_names))
       
      options.(inp_name) = pair{2};
      
   else
       
      error('%s is not a recognized parameter name', inp_name)
      
   end % of if any
end % of for pair

clear pair
clear inp_name

% Renaming variables for use below:
alpha = options.alpha;
percent = options.percent;
ttest_tail = options.tail;
clear options;



%% Yuen's Paired-Samples T Test

% Initial checks to see if the data is formatted properly
if isempty(cond_1_data) || isempty(cond_2_data) % If one dataset is empty
    
    error('yuend_ttest:InvalidInput', 'data vectors cannot have length = 0');
    
end % of if isempty

if (percent >= 100) || (percent < 0) % If incorrect trimming parameter chosen
    
    error('yuend_ttest:InvalidPercent', 'PERCENT must be between 0 and 50.');
    
end % of if isempty

if percent >= 50 % If trimming percent set to 50 percent or higher
    
    error('yuend_ttest:InvalidPercent', 'PERCENT cannot be 50 or higher, use a method for medians instead.');
    
end % of if percent

% number of trials
n_cond_1 = length(cond_1_data);
n_cond_2 = length(cond_2_data);

if n_cond_1 ~= n_cond_2 % If number of conditions is not equal across datasets
    
    error('yuend_ttest:InvalidInput', 'input data vectors must be the same size.');
    
else
    
    n = n_cond_1;
    
end % of if n_cond_1

g = floor((percent / 100) * n); % number of items to winsorize and trim
n_trimmed = n - 2 .* g; % effective sample size after trimming

% winsorise cond_1_data (the first dataset)
cond_1_sorted = sort(cond_1_data);
loval = cond_1_sorted(g + 1);
hival = cond_1_sorted(n - g);
winsorized_cond_1 = cond_1_data;
winsorized_cond_1(winsorized_cond_1 <= loval) = loval;
winsorized_cond_1(winsorized_cond_1 >= hival) = hival;

winsorized_var_cond_1 = var(winsorized_cond_1, 0); % Calculate the winsorized variance

% winsorise cond_2_data (the second dataset)
cond_2_sorted = sort(cond_2_data);
loval = cond_2_sorted(g + 1);
hival = cond_2_sorted(n - g);
winsorized_cond_2 = cond_2_data;
winsorized_cond_2(winsorized_cond_2 <= loval) = loval;
winsorized_cond_2(winsorized_cond_2 >= hival) = hival;

winsorized_var_cond_2 = var(winsorized_cond_2, 0); % Calculate the winsorized variance

% yuen's estimate of standard errors for cond_1_data and cond_2_data
d_cond_1 = (n - 1) .* winsorized_var_cond_1;
d_cond_2 = (n - 1) .* winsorized_var_cond_2;

% covariance of winsorized samples
tmp = cov(winsorized_cond_1, winsorized_cond_2);
winsorized_covariance = tmp(1, 2);

winsorized_cov_cond_1_2 = (n - 1) .* winsorized_covariance;

% trimmed means
mean_cond_1 = mean(cond_1_sorted(g + 1 : n - g));
mean_cond_2 = mean(cond_2_sorted(g + 1 : n - g));

diff = mean_cond_1 - mean_cond_2; % Calculate difference in trimmed means

df = n_trimmed - 1; % Calculate degrees of freedom
se = sqrt( (d_cond_1 + d_cond_2 - 2 .* winsorized_cov_cond_1_2) ./ (n_trimmed .* (n_trimmed - 1)) ); % Calculate standard error

t_yuen = diff ./ se; % Calculate yuen's t

% Calculate p-value depending on whether calculating one- or two-tailed
% testing

if strcmp(ttest_tail, 'both') == 1 % 2-tailed probability
    
    p = 2 * (1 - tcdf(abs(t_yuen), df)); 
    tcrit = tinv(1 - alpha ./ 2, df); % 1-alpha./2 quantile of Student's distribution with df degrees of freedom
    % Two-tailed CI
    CI(1) = diff - tcrit .* se; 
    CI(2)= diff + tcrit .* se;
    
elseif strcmp(ttest_tail, 'right') == 1 % 1-tailed testing (test for positive differences)
    
    p = 1 - tcdf(t_yuen, df);
    tcrit = tinv(1 - alpha, df);
    % One-tailed CI
    CI(1) = diff - tcrit .* se;
    CI(2) = Inf;
        
elseif strcmp(ttest_tail, 'left') == 1 % 1-tailed (test for negative differences)
    
    p = tcdf(t_yuen, df);
    tcrit = tinv(1 - alpha, df);
    CI(1) = -Inf;
    CI(2) = diff + tcrit .* se;
    
end % of if strcmp
    
% Determine statistical significance
if p < alpha;
    
    h_yuen = 1; % Statistically significant
    
else
    
    h_yuen = 0; % Not statistically significant
    
end % of if p < alpha