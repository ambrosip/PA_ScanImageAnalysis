
nColumns = 4;

xmaxScale = xmax - photobleachingWindowInSec;
xminScale = 0;
ymaxScale = ymax/2;
xmin = xminScale;
ymin = -ymaxScale;

% create figure & name it
fig=figure('name', strcat(matFileName, '_niceplot'));
set(gca,'FontName','Arial');
set(gcf,'OuterPosition',[100 100 600 900]);
set(gca,'LineWidth', 0.75);
t = tiledlayout(ceil((size(rois,2))/(nColumns-1)), nColumns);

% plot ROIs
nexttile([ceil((size(rois,2))/(nColumns-1)) 1])
imshow(imadjust(lastMaxIntProj,[0.5 0.65]))
hold on
thetas = linspace(0,2*pi,200);
for roiNumber=1:length(rois)
    ellipseR1 = (rois{roiNumber}.vnRectBounds(4) - rois{roiNumber}.vnRectBounds(2))/2;
    ellipseR2 = (rois{roiNumber}.vnRectBounds(3) - rois{roiNumber}.vnRectBounds(1))/2;
    ellipseA = (rois{roiNumber}.vnRectBounds(4) + rois{roiNumber}.vnRectBounds(2))/2;
    ellipseB = (rois{roiNumber}.vnRectBounds(3) + rois{roiNumber}.vnRectBounds(1))/2;
    ellipseX = ellipseR1*cos(thetas)+ellipseA;
    ellipseY = ellipseR2*sin(thetas)+ellipseB; 
    plot(ellipseX,ellipseY,'Color','y');
    text(ellipseA,ellipseB,num2str(roiNumber),'Color','y');
end
hold off

% plotting niceplots of z-score
for roi=1:totalNumberOfRois
    nexttile
    hold on;
    for file=firstFig:lastFig
        plot(xAxisInSec',s_zS.(fns{file})(:,roi), 'Color',[0, 0, 0, 0.25]);
    end
    plot(xAxisInSec',mean_zS_PerROI(:,roi),'Color','k')
    
    % add odor stim window 
    if analyzeOdorPulse == 1
        xline(adjustedBaselineInSec);
        xline(adjustedBaselineInSec+odor_dur_in_s);
    end
    text(xmaxScale,0,num2str(roi))
    axis([xmin xmax ymin ymax])
    % xlabel('Time (s)')
    % ylabel('z-score')
    % ylabel(num2str(roi))
        
    % remove x and y labels from all ROIs
    xticklabels([]);
    yticklabels([]);
    
    % % add odor stim window to first row only
    % if roi>=1 && roi<=nColumns
    %     if analyzeOdorPulse == 1
    %         xline(adjustedBaselineInSec);
    %         xline(adjustedBaselineInSec+odor_dur_in_s);
    %     end
    % end

    % add scale bar to last plot
    if roi == size(rois,2)
        line([xmaxScale-(xmaxScale-xminScale)/xmaxScale,xmaxScale],[ymin,ymin],'Color','k')
        line([xmaxScale,xmaxScale],[ymin,ymin+(ymaxScale-ymin)/2],'Color','k')
        text(xmaxScale-(xmaxScale-xminScale),ymin+((ymaxScale-ymin)/xmaxScale),strcat(num2str((xmaxScale-xminScale)/xmaxScale)," s"))
        text(xmaxScale-(xmaxScale-xminScale),ymin+((ymaxScale-ymin)/2),strcat(num2str((ymaxScale-ymin)/2)," z-score"))
    end
    
    set(findall(gcf,'-property','FontSize'),'FontSize',9)
    hold off;    
    set(gca,'Visible','off');
end

title(t,matFileName,'Interpreter', 'none');
t.TileSpacing = 'compact';
t.Padding = 'compact';