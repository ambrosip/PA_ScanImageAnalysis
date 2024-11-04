clear all
close all

%% USER INPUT
figFile='/Users/priscilla/Documents/Local - Moss Lab/Jedi2P_pilot/MAX_m0027_00001_mcor.tif - C=0.tif';
ezcaFile='/Users/priscilla/Documents/Local - Moss Lab/Jedi2P_pilot/m0027_00002_mcor.mat';
timingFile='/Users/priscilla/Documents/Local - Moss Lab/Jedi2P_pilot/2024_10_29_m0027_00001.h5';

sampleRate=h5readatt(timingFile,'/','samplerate');
imagingWindow=h5read('/Users/priscilla/Documents/Local - Moss Lab/Jedi2P_pilot/2024_10_29_m0027_00001.h5','/ImagingWindow');
odorDelivery=h5read('/Users/priscilla/Documents/Local - Moss Lab/Jedi2P_pilot/2024_10_29_m0027_00001.h5','/OdorDelivery');

xmin = -inf;
xmax = +inf;
ymin = -0.5;
ymax = +1.0;

plotAll = 1;


%% GATHER DATA
figData=imread(figFile);
ezcaData=load(ezcaFile);
refinedROIx=ezcaData.ROI_center_refined(:,1);
refinedROIy=ezcaData.ROI_center_refined(:,2);
totalROIs = length(refinedROIx);

% ASSUMPTION: all imaging windows are the same duration
% this code works for a TTL pulse from 0 to 5 V
imagingStart=find(diff(imagingWindow>1)>0);
imagingEnd=find(diff(imagingWindow<1)>0);   
imagingDurInPts=imagingEnd(1)-imagingStart(1);  % in data points
imagingDurInSec=imagingDurInPts/sampleRate;     % in seconds

% ASSUMPTION: all odor deliveries are the same duration
% this code works for a TTL pulse on steroids, from 0 to 20 V, with slow
% decay. To accomodate these weird parameters, I had to (1) filter the
% data and (2) set a higher threshold for finding the pulse, 8/10 of the range
% smooth data with moving average filter
odorDeliverySmoothed = smooth(odorDelivery,10);
odorPulseThreshold=(max(odorDeliverySmoothed)-min(odorDeliverySmoothed))*8/10;
odorStart=find(diff(odorDeliverySmoothed>odorPulseThreshold)>0);
odorEnd=find(diff(odorDeliverySmoothed<odorPulseThreshold)>0);  
odorDurInPts=odorEnd(1)-odorStart(1);          % in data points
odorDurInSec=odorDurInPts/sampleRate;          % in seconds

imagingTotalDataPts=length(ezcaData.F_raw_refined(1,:));
imagingSampleRate=imagingTotalDataPts/imagingDurInSec;
xAxisInSec=linspace(0,imagingDurInSec,imagingTotalDataPts);


%% PLAY

% for i=1:totalROIs
% 
% end


%% PLOTS

if plotAll == 1

    color = hsv(totalROIs);

    % %% PLOT 0 - Timing
    % % figures for quality control and troubleshooting
    % figure
    % plot(imagingWindow)
    % hold on
    % xline(imagingStart)
    % xline(imagingEnd,'r')
    % hold off
    % 
    % figure
    % plot(odorDelivery)
    % hold on
    % plot(odorDeliverySmoothed,'g')
    % % plot(diff(odorDelivery),'g')
    % xline(odorStart)
    % xline(odorEnd,'r')
    % hold off
       
    %% PLOT 1 - ROI location (not colorful)
    fig1=figure;
    ax1 = axes('Parent',fig1);
    imshow(figData,'Parent',ax1)
    hold on;
    plot(refinedROIx,refinedROIy,'o','Color','white','Parent',ax1)
    hold off;

    %% PLOT 2 - ROI location (colorful)
    fig2=figure;
    ax2=axes('Parent',fig2);
    imshow(figData,'Parent',ax2)
    hold on; 
    allROIs=(1:totalROIs)';   
    textscatter(ax2,refinedROIx,refinedROIy,string(allROIs))
    % for roi=1:totalROIs
    %     % num2str(roi);
    %     % scatter(refinedROIx(roi),refinedROIy(roi),[],color(roi,:))
    %     textscatter(ax2,refinedROIx(roi),refinedROIy(roi),string(roi))
    % end
    hold off;
    
    
    %% PLOT 3 - time-series data of specific ROIs
    % for roi=1:1
    %     figure
    %     plot(xAxisInSec,ezcaData.F_raw_refined(roi,:),'Color',color(roi,:))
    %     axis([xmin xmax ymin ymax])
    %     ylabel('F (neg is depol)');
    %     xlabel('Time (s)');
    %     title(strcat("ROI: ", num2str(roi)));
    % end
    
    
    %% PLOT 4 - time-series data of all ROIs (colorful)
    % tileRows = round(totalROIs/2);
    % 
    % figure
    % t = tiledlayout(tileRows, 2);
    % 
    % % plotting niceplots 
    % for roi = 1:totalROIs
    %     nexttile
    %     hold on;
    %     plot(xAxisInSec,ezcaData.F_raw_refined(roi,:),'Color',color(roi,:))
    %     axis([xmin xmax ymin ymax])
    % 
    %     % remove x and y labels from all ROIs
    %     xticklabels([]);
    %     yticklabels([]);
    % 
    %     % add scale bar to last plot
    %     if roi == totalROIs
    %         if tileRows*2 > totalROIs
    %             set(gca,'Visible','off');
    %             nexttile
    %             % repeated data as a placeholder
    %             plot(xAxisInSec,ezcaData.F_raw_refined(roi,:),'k')
    %             axis([xmin xmax ymin ymax])
    %         end
    %         xmaxScale = round(imagingDurInSec,1);
    %         xminScale = 0;
    %         line([xmaxScale-(xmaxScale-xminScale)/xmaxScale,xmaxScale],[ymin,ymin],'Color','k')
    %         line([xmaxScale,xmaxScale],[ymin,ymin+((ymax-ymin)/3)],'Color','k')
    %         text(xmaxScale-(xmaxScale-xminScale)/xmaxScale,ymin+((ymax-ymin)/12),strcat(num2str((xmaxScale-xminScale)/xmaxScale)," s"))
    %         text(xmaxScale-(xmaxScale-xminScale)/xmaxScale,ymin+((ymax-ymin)/3),strcat(num2str((ymax-ymin)/3)," F"))
    %     end
    % 
    %     hold off;    
    %     set(gca,'Visible','off');
    % 
    % end
    % 
    % t.TileSpacing = 'compact';
    % t.Padding = 'compact';
    
    
    %% PLOT 4 - time-series data of all ROIs (not colorful)
    tileRows = round(totalROIs/2);
    
    figure
    t = tiledlayout(tileRows, 2);
    
    % plotting niceplots 
    for roi = 1:totalROIs
        nexttile
        hold on;
        plot(xAxisInSec,ezcaData.F_raw_refined(roi,:),'k')
        axis([xmin xmax ymin ymax])
    
        % remove x and y labels from all ROIs
        xticklabels([]);
        yticklabels([]);
        % ylabel(string(roi),'Rotation',0)
        
        % add scale bar to last plot
        if roi == totalROIs
            if tileRows*2 > totalROIs
                set(gca,'Visible','off');
                nexttile
                % repeated data as a placeholder
                plot(xAxisInSec,ezcaData.F_raw_refined(roi,:),'r')
                axis([xmin xmax ymin ymax])
            end
            xmaxScale = round(imagingDurInSec,1);
            xminScale = 0;
            line([xmaxScale-(xmaxScale-xminScale)/xmaxScale,xmaxScale],[ymin,ymin],'Color','k')
            line([xmaxScale,xmaxScale],[ymin,ymin+((ymax-ymin)/3)],'Color','k')
            text(xmaxScale-(xmaxScale-xminScale)/xmaxScale,ymin+((ymax-ymin)/12),strcat(num2str((xmaxScale-xminScale)/xmaxScale)," s"))
            text(xmaxScale-(xmaxScale-xminScale)/xmaxScale,ymin+((ymax-ymin)/3),strcat(num2str((ymax-ymin)/3)," F"))
        end
        
        hold off;    
        set(gca,'Visible','off');
    
    end
    
    t.TileSpacing = 'compact';
    t.Padding = 'compact';

end