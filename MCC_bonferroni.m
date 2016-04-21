function [bonferroni_corrected_h] = MCC_bonferroni(p_values, alpha_level)

%__________________________________________________________________________
% Multiple comparisons correction function written by Daniel Feuerriegel 21/04/2016 
% to complement DDTBOX scripts written by Stefan Bode 01/03/2013.
%
% The toolbox was written with contributions from:
% Daniel Bennett, Jutta Stahl, Daniel Feuerriegel, Phillip Alday
%
% The author (Stefan Bode) further acknowledges helpful conceptual input/work from: 
% Simon Lilburn, Philip L. Smith, Elaine Corbett, Carsten Murawski, 
% Carsten Bogler, John-Dylan Haynes
%__________________________________________________________________________
%
% This script receives a vector of p-values and outputs
% Bonferroni-corrected null hypothesis test results. The number of tests is
% determined by the length of the vector of p-values.
%
%
% requires:
% - p_values (vector of p-values from the hypothesis tests of interest)
% - alpha_level (uncorrected alpha level for statistical significance)
%
%
% outputs:
% bonferroni_corrected_h (vector of Bonferroni-corrected hypothesis tests 
% derived from comparing p-values to Bonferroni adjusted critical alpha level. 
% 1 = statistically significant, 0 = not statistically significant)
%__________________________________________________________________________
%
% Variable naming convention: STRUCTURE_NAME.example_variable

n_total_comparisons = length(p_values); % Get the number of comparisons
bonferroni_corrected_alpha = alpha_level / n_total_comparisons; % Calculate bonferroni-corrected alpha

bonferroni_corrected_h = zeros(1, length(p_values)); % preallocate

bonferroni_corrected_h(p_values < bonferroni_corrected_alpha) = 1; % Compare each p-value to the corrected threshold.
