function display_group_results_erp(ANALYSIS, PLOT)
%
% This function plots results of group-level analyses of 
% classification/regression performance.  
%
% This function is called by analyse_decoding_erp, but can also be called
% by custom plotting scripts such as EXAMPLE_plot_group_results.
%
%
% Inputs:
%
%   ANALYSIS        structure containing analysis settings and data
% 
%   PLOT            structure containing decoding performance plotting
%                   settings. For a list of settings see the documentation
%                   or see the function dd_set_plotting_defaults
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



%% Plot the Results
% plots the results depending on s/t-mode (information time-courses for
% spatial/spatio-temporal decoding; heat maps for temporal decoding)

if ANALYSIS.stmode == 1 || ANALYSIS.stmode == 3 % Spatial and spatiotemporal decoding
    
    % Plot the information time-course for each analysis
    for ana = 1:size(ANALYSIS.RES.mean_subj_acc, 1)
        
        fighandle = figure('Position', PLOT.FigPos);
        
        % get results to plot        
        if ANALYSIS.plot_robust == 0 % If plotting the arithmetic mean
            
            temp_data(1,:) = ANALYSIS.RES.mean_subj_acc(ana,:);
            temp_se(1,:) = ANALYSIS.RES.se_subj_acc(ana,:);
            fprintf('\nArithmetic mean used for plotting group average accuracy\nError bars represent standard errors\n\n');
        
        elseif ANALYSIS.plot_robust == 1 % If plotting trimmed means 
        
            temp_data(1,:) = ANALYSIS.RES.trimmean_subj_acc(ana,:);
            temp_se = ANALYSIS.RES.se_subj_acc(ana,:); % Still plotting non-robust SE
            fprintf('\n%i percent trimmed mean used for plotting group average accuracy\nError bars represent standard errors\n\n', ANALYSIS.plot_robust_trimming);

        elseif ANALYSIS.plot_robust == 2 % If plotting medians
            
            temp_data(1,:) = ANALYSIS.RES.median_subj_acc(ana,:);
            temp_se = ANALYSIS.RES.se_subj_acc(ana,:); % Still plotting non-robust SE
            fprintf('\nMedian used for plotting group average accuracy\nError bars represent standard errors\n\n');

        end % of if ANALYSIS.plot_robust
            
        % get permutation results to plot
        if ANALYSIS.permstats == 1 % If testing against theoretical chance
            
            temp_perm_data(1, 1:size(ANALYSIS.RES.mean_subj_acc(ana,:), 2)) = ANALYSIS.chancelevel;
            temp_perm_se(1, 1:size(ANALYSIS.RES.mean_subj_acc(ana,:), 2)) = zeros;
            
        elseif ANALYSIS.permstats == 2
            
            if ANALYSIS.plot_robust == 0 % If plotting the arithmetic mean
                
                temp_perm_data(1,:) = ANALYSIS.RES.mean_subj_perm_acc(ana,:);
                temp_perm_se(1,:) = ANALYSIS.RES.se_subj_perm_acc(ana,:);
                
            elseif ANALYSIS.plot_robust == 1 % If plotting trimmed means 

                temp_perm_data(1,:) = ANALYSIS.RES.trimmean_subj_perm_acc(ana,:);
                temp_perm_se(1,:) = ANALYSIS.RES.se_subj_perm_acc(ana,:); % Still plotting non-robust SE
                
            elseif ANALYSIS.plot_robust == 2 % If plotting medians
                
                temp_perm_data(1,:) = ANALYSIS.RES.median_subj_perm_acc(ana,:);
                temp_perm_se(1,:) = ANALYSIS.RES.se_subj_perm_acc(ana,:); % Still plotting non-robust SE
                
            end % of if ANALYSIS.plot_robust
            
        end % of if ANALYSIS.permstats
        
        % Mark statistically significant points        
        if ANALYSIS.disp.sign == 1
            
            for step = 1:size(temp_data, 2)
                
                % plot if found significant...
                if ANALYSIS.RES.h(ana, step) == 1
                    
                        line([step, step], PLOT.Sign.LinePos,'Color', PLOT.Sign.LineColor, 'LineWidth', PLOT.Sign.LineWidth);
                        hold on;
                    
                end % of if ANALYSIS.RES.h
            end % of for step
        end % of if ANALYSIS.disp.sign
        
        % plot main results
        plot(temp_data, PLOT.Res.Line, 'LineWidth', PLOT.Res.LineWidth, ...
            'MarkerEdgeColor', PLOT.Res.MarkerEdgeColor,...
            'MarkerFaceColor', PLOT.Res.MarkerFaceColor, ...
            'MarkerSize', PLOT.Res.MarkerSize);
        hold on;      
        
        % plot error bars
        errorbar(temp_data, temp_se, PLOT.Res.Error, ...
            'linestyle', PLOT.Res.ErrorLine, ...
            'linewidth', PLOT.Res.ErrorLineWidth);
        hold on;
        
        
        
        %% Plot Permutation / Chance Results

        if ANALYSIS.permdisp == 1 % If select to plot permutation decoding results
            
            plot(temp_perm_data, PLOT.PermRes.Line, ...
                'LineWidth', PLOT.PermRes.LineWidth, ...
                'MarkerEdgeColor', PLOT.PermRes.MarkerEdgeColor,...
                'MarkerFaceColor', PLOT.PermRes.MarkerFaceColor, ...
                'MarkerSize', PLOT.PermRes.MarkerSize);
            hold on;      

            errorbar(temp_perm_data, temp_perm_se, PLOT.PermRes.Error, ...
                'linestyle', PLOT.PermRes.ErrorLine,...
                'linewidth', PLOT.PermRes.ErrorLineWidth);
            hold on;
            
        end % of if ANALYSIS.permdisp
        
        
        
        %% Define Axis Labels, Point Zero, Title
              
        % Axis limits
        axis([1, ANALYSIS.laststep, PLOT.Y_min, PLOT.Y_max]);
        
        % Axis Labels
        xlabel(PLOT.xlabel.Text, 'FontSize', PLOT.xlabel.FontSize, 'FontWeight', PLOT.xlabel.FontWeight);
        ylabel(PLOT.ylabel.Text, 'FontSize', PLOT.ylabel.FontSize, 'FontWeight', PLOT.ylabel.FontWeight);
        
        % Title
        if size(ANALYSIS.DCG,1) == 1 % If did not perform cross-decoding
                
            title([PLOT.TitleString, ANALYSIS.DCG, ' N=',  num2str(ANALYSIS.nsbj)],...
                'FontSize', PLOT.TitleFontSize, 'FontWeight', PLOT.TitleFontWeight);
           
        elseif size(ANALYSIS.DCG,1) == 2 % If performed cross-decoding
                
            title([PLOT.TitleString, ANALYSIS.DCG{1}, 'to', ANALYSIS.DCG{2}, ' N=',  num2str(ANALYSIS.nsbj)],...
                'FontSize', PLOT.TitleFontSize, 'FontWeight', PLOT.TitleFontWeight);
           
        end % of if size

        % mark point zero (data was time-locked to this event)
        line([PLOT.PointZero.Point, PLOT.PointZero.Point], [PLOT.Y_max, PLOT.Y_min], ...
            'Color', PLOT.PointZero.Color,...
            'LineWidth', PLOT.PointZero.LineWidth);
        
        
        
        %% Define Ticks and Axis Labels
        
        set(gca,'Ytick', PLOT.Ytick, 'Xtick', PLOT.Xtick);
        set(gca, 'XTickLabel', PLOT.XtickLabel);

        % clear temp-data
        clear temp_data;   
        clear temp_se; 
    
        
    end % of for ana (looping across channels)
    
elseif ANALYSIS.stmode == 2 % If using temporal decoding
    
    
    
    %% (Temporal Decoding) Load channel information (locations and labels)
    channel_file = [ANALYSIS.channellocs, ANALYSIS.channel_names_file];
    load(channel_file);
    
    % Copy to FW_ANALYSIS structure
    FW_ANALYSIS.chaninfo = chaninfo;
    FW_ANALYSIS.chanlocs = chanlocs;
    
    clear temp_data;
    clear temp_perm_data;
    
    
    
    %% (Temporal Decoding) Plot Results
    
    % Estimate of location for actual decoding results (depends on plotting preferences)
    if ANALYSIS.plot_robust == 0 % If plotting the arithmetic mean
        
        temp_data = ANALYSIS.RES.mean_subj_acc(:,1);
        fprintf('\nArithmetic mean used for plotting group average accuracy\n\n');

    elseif ANALYSIS.plot_robust == 1 % If plotting trimmed means 

        temp_data = ANALYSIS.RES.trimmean_subj_acc(:, 1);
        fprintf('\n%i percent trimmed mean used for plotting group average accuracy\n\n', ANALYSIS.plot_robust_trimming);

    elseif ANALYSIS.plot_robust == 2 % If plotting medians

        temp_data = ANALYSIS.RES.median_subj_acc(:, 1);
        fprintf('\nMedian used for plotting group average accuracy\nError bars represent standard errors\n\n');

    end % of if ANALYSIS.plot_robust
    
    % Estimate of location for permutation decoding results (depends on plotting preferences)
    if ANALYSIS.permstats == 1 % If testing against theoretical chance
        
        temp_perm_data(1:size(ANALYSIS.RES.mean_subj_acc, 1)) = ANALYSIS.chancelevel;
        
    elseif ANALYSIS.permstats == 2 % If testing against permutation results

        if ANALYSIS.plot_robust == 0 % If plotting the arithmetic mean

            temp_perm_data = ANALYSIS.RES.mean_subj_perm_acc(:, 1);

        elseif ANALYSIS.plot_robust == 1 % If plotting trimmed means 

            temp_perm_data = ANALYSIS.RES.trimmean_subj_perm_acc(:, 1);

        elseif ANALYSIS.plot_robust == 2 % If plotting medians
            
            temp_perm_data = ANALYSIS.RES.median_subj_perm_acc(:, 1);
            
        end % of if ANALYSIS.plot_robust
    end % of if ANALYSIS.permstats

    % Plot estimate of group decoding accuracy (mean/median/trimmed mean)
    figure;
    
    topoplot_decoding(temp_data, FW_ANALYSIS.chanlocs, ...
        'style', 'both', ...
        'electrodes', 'labelpoint', ...
        'maplimits', 'minmax', ...
        'chaninfo', FW_ANALYSIS.chaninfo, ...
        'colormap', ANALYSIS.disp.temporal_decoding_colormap);
    hold on;
    
    % Title
    title([PLOT.TitleString, ANALYSIS.DCG, ' N=',  num2str(ANALYSIS.nsbj)], ...
                'FontSize', PLOT.TitleFontSize, ...
                'FontWeight', PLOT.TitleFontWeight);
        
    % Plot estimate of group decoding accuracy relative to chance or permutation
    % decoding accuracy (actual - chance | actual - permutation)
    figure;
    
    topoplot_decoding(temp_data - temp_perm_data, FW_ANALYSIS.chanlocs, ...
        'style', 'both', ...
        'electrodes', 'ptslabels', ...
        'maplimits', 'minmax', ...
        'chaninfo', FW_ANALYSIS.chaninfo, ...
        'colormap', ANALYSIS.disp.temporal_decoding_colormap);
    hold on;
    
    % Title
    title([PLOT.TitleString, ANALYSIS.DCG, ' Decoding Results Minus Chance, N=',  num2str(ANALYSIS.nsbj)], ...
                'FontSize', PLOT.TitleFontSize, ...
                'FontWeight', PLOT.TitleFontWeight);
        
            
    % Plot statistically significant channels (corrected for multiple
    % comparisons)
    sig_locations = ANALYSIS.RES.h; % Mask based on statistical significance
    
    figure;
    
    topoplot_decoding(sig_locations, FW_ANALYSIS.chanlocs, ...
        'style', 'fill', ...
        'electrodes', 'ptslabels', ...
        'numcontour', 1, ...
        'conv', 'off', ...
        'maplimits', [0 2], ...
        'ccolor', [0 0 0], ...
        'ecolor', [1 1 1], ...
        'chaninfo', FW_ANALYSIS.chaninfo, ...
        'colormap', ANALYSIS.disp.temporal_decoding_colormap);
    hold on;
    
    % Title
    title([PLOT.TitleString, ANALYSIS.DCG, ' Masked by stat. sig., N=',  num2str(ANALYSIS.nsbj)], ...
                'FontSize', PLOT.TitleFontSize, ...
                'FontWeight', PLOT.TitleFontWeight);
            
end % of if ANALYSIS.stmode